--[[

	Rayfield Interface Suite (Kento Hub Custom - Full Features)
	by Sirius (Customized Theme & Loading)

]]

-- Read first, so secure mode covers Rayfield's output from its first line.
local secureMode = false
if getgenv then
	local ok, result = pcall(function() return getgenv().RAYFIELD_SECURE end)
	if ok and result then secureMode = true end
end

-- Rayfield's own console output goes through these locals. Under secure mode they are silent.
local warn, print, error, assert = warn, print, error, assert
if secureMode then
	local rawError = error
	local rawAssert = assert
	warn = function(...) end
	print = function(...) end
	error = function(_, level) rawError("", level) end
	assert = function(v, ...) return rawAssert(v) end
end

if debugX then
	warn('Initialising Rayfield')
end

local function getService(name)
	local service = game:GetService(name)
	return if cloneref then cloneref(service) else service
end

local RAYFIELD_COMMIT = "38a84e32a7b91d873788b9da4deb020bfd87d182"
local RAYFIELD_RAW = "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/" .. RAYFIELD_COMMIT .. "/"

-- Services
local UserInputService = getService("UserInputService")
local TweenService = getService("TweenService")
local Players = getService("Players")
local CoreGui = getService("CoreGui")

local function cancelThread(thread: thread)
	if task.cancel then
		pcall(task.cancel, thread)
	end
end

local function loadWithTimeout(url: string, timeout: number?): ...any
	assert(type(url) == "string", "Expected string, got " .. type(url))
	timeout = timeout or 5
	local requestCompleted = false
	local success, result = false, nil

	local requestThread = task.spawn(function()
		local fetchSuccess, fetchResult = pcall(game.HttpGet, game, url)
		if not fetchSuccess or #fetchResult == 0 then
			if #fetchResult == 0 then
				fetchResult = "Empty response"
			end
			success, result = false, fetchResult
			requestCompleted = true
			return
		end
		local content = fetchResult
		local execSuccess, execResult = pcall(function()
			return loadstring(content)()
		end)
		success, result = execSuccess, execResult
		requestCompleted = true
	end)

	local timeoutThread = task.delay(timeout, function()
		if not requestCompleted then
			warn("Request for " .. url .. " timed out after " .. tostring(timeout) .. " seconds")
			cancelThread(requestThread)
			result = "Request timed out"
			requestCompleted = true
		end
	end)

	while not requestCompleted do
		task.wait()
	end
	if coroutine.status(timeoutThread) ~= "dead" then
		cancelThread(timeoutThread)
	end
	if not success then
		warn("Failed to process " .. tostring(url) .. ": " .. tostring(result))
	end
	return if success then result else nil
end

local requestsDisabled = false
local analyticsOptOut = false
local customAssetId = nil
if getgenv then
	local ok, result = pcall(function() return getgenv().DISABLE_RAYFIELD_REQUESTS end)
	if ok and result then requestsDisabled = true end
	local ok2, result2 = pcall(function() return getgenv().RAYFIELD_ASSET_ID end)
	if ok2 and type(result2) == "number" then customAssetId = result2 end
	local ok3, result3 = pcall(function() return getgenv().RAYFIELD_ANALYTICS end)
	if ok3 and result3 == false then analyticsOptOut = true end
end

local secureWarnings = {}
local customAssets = {}

local function secureNotify(wType, title, content)
	if secureWarnings[wType] then return end
	secureWarnings[wType] = true
	task.spawn(function()
		while not RayfieldLibrary or not RayfieldLibrary.Notify do task.wait(0.5) end
		RayfieldLibrary:Notify({
			Title = title,
			Content = content,
			Duration = 8,
		})
	end)
end
local InterfaceBuild = 'UU2NX'
local Release = "Build 1.760 (Kento Hub)"
local RayfieldFolder = "Rayfield"
local ConfigurationFolder = RayfieldFolder.."/Configurations"
local ConfigurationExtension = ".rfld"
local settingsTable = {
	General = {
		rayfieldOpen = {Type = 'bind', Value = 'K', Name = 'Rayfield Keybind'},
	},
	System = {
		usageAnalytics = {
			Type = 'toggle',
			Value = true,
			Name = 'Usage analytics',
			Description = 'Sends anonymous counts of which parts of this window are used.',
		},
	}
}

local overriddenSettings: { [string]: any } = {}
local function overrideSetting(category: string, name: string, value: any)
	overriddenSettings[category .. "." .. name] = value
end

local function getSetting(category: string, name: string): any
	if overriddenSettings[category .. "." .. name] ~= nil then
		return overriddenSettings[category .. "." .. name]
	elseif settingsTable[category][name] ~= nil then
		return settingsTable[category][name].Value
	end
end

if requestsDisabled or analyticsOptOut then
	overrideSetting("System", "usageAnalytics", false)
end

local HttpService = getService('HttpService')
local RunService = getService('RunService')
local useStudio = RunService:IsStudio() or false
local settingsCreated = false
local settingsInitialized = false
local requestFunc = (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request) or http_request or request

local function callSafely(func, ...)
	if func then
		local success, result = pcall(func, ...)
		if not success then
			warn("Rayfield | Function failed with error: ", result)
			return false
		else
			return result
		end
	end
end

local function ensureFolder(folderPath)
	if isfolder and not callSafely(isfolder, folderPath) then
		callSafely(makefolder, folderPath)
	end
end

local function stripTraversal(text: string): string
	local previous
	repeat
		previous = text
		text = string.gsub(text, "%.%.", "")
	until text == previous
	return text
end

local function sanitizeFolderName(value: any): string
	local text = string.gsub(string.gsub(tostring(value), "\\", "/"), "[:%c]", "")
	text = string.gsub(stripTraversal(text), "/+", "/")
	return (string.gsub(text, "^/+", ""))
end

local function sanitizeFileName(value: any): string
	local text = string.gsub(tostring(value), "[/\\%c]", "")
	return stripTraversal(text)
end

local function loadSettings()
	local file = nil
	local success, result =	pcall(function()
		if callSafely(isfolder, RayfieldFolder) then
			if callSafely(isfile, RayfieldFolder..'/settings'..ConfigurationExtension) then
				file = callSafely(readfile, RayfieldFolder..'/settings'..ConfigurationExtension)
			end
		end

		if file then
			local decodeSuccess, decodedFile = pcall(function() return HttpService:JSONDecode(file) end)
			if decodeSuccess then
				file = decodedFile
			else
				file = {}
			end
		else
			file = {}
		end

		if not settingsCreated then
			return
		end

		if next(file) ~= nil then
			for categoryName, categoryTable in file do
				for settingName, setting in categoryTable do
					local default = settingsTable[categoryName] and settingsTable[categoryName][settingName]
					if not default then continue end
					local settingType = typeof(default.Value)
					if not (settingType == typeof(setting.Value)) then
						continue
					end
					default.Value = setting.Value
				end
			end
		end
		for categoryName, categoryTable in settingsTable do
			for settingName, setting in categoryTable do
				if setting.Element then
					setting.Element:Set(getSetting(categoryName, settingName))
				end
			end
		end
		settingsInitialized = true
	end)
end

loadSettings()

local ANALYTICS_TOKEN = "05de7f9fd320d3b8428cd1c77014a337b85b6c8efee2c5914f5ab5700c354b9a"
local reporter = nil
local reporterLoaded = false
local function loadReporter()
	if reporterLoaded then return reporter end
	reporterLoaded = true
	if requestsDisabled or useStudio then return nil end

	local fetchSuccess, fetchResult = pcall((game :: any).HttpGet, game, RAYFIELD_RAW .. "reporter.lua")
	if fetchSuccess and #fetchResult > 0 then
		local execSuccess, Analytics = pcall(function()
			return (loadstring(fetchResult) :: any)()
		end)
		if execSuccess and Analytics then
			pcall(function()
				reporter = Analytics.new({
					url          = "https://rayfield-collect.sirius-software-ltd.workers.dev",
					token        = ANALYTICS_TOKEN,
					product_name = "Rayfield",
					category     = "UILibrary",
				})
			end)
		end
	end
	return reporter
end

local function analyticsAllowed(): boolean
	if requestsDisabled or analyticsOptOut or useStudio then return false end
	if not getSetting("System", "usageAnalytics") then return false end
	return settingsInitialized or not (isfile and readfile)
end

local SIA_TOKEN = "sia_rayfield_bd0f30653a58a75bac2987e3"
local sia = nil
local siaState = "off"
local siaQueue = {}
local siaElements = {}
local siaScript = nil
local siaLoads = 0

local function savedAnalyticsChoice(): boolean?
	local ok, value = pcall(function()
		local path = RayfieldFolder .. "/settings" .. ConfigurationExtension
		if not (isfile and readfile and isfile(path)) then return nil end
		return HttpService:JSONDecode(readfile(path)).System.usageAnalytics.Value
	end)
	return if ok and type(value) == "boolean" then value else nil
end

local function siaAllowed(): boolean
	if requestsDisabled or analyticsOptOut or useStudio then return false end
	if not getSetting("System", "usageAnalytics") then return false end
	return settingsInitialized or savedAnalyticsChoice() ~= false
end

local function siaRun(fn: (any) -> ())
	if siaState == "on" and sia then
		pcall(fn, sia)
	elseif siaState == "loading" and #siaQueue < 500 then
		table.insert(siaQueue, fn)
	end
end

local function siaId(client: any, handle: any): string?
	handle.id = handle.id or client:element(handle.kind, handle.name, handle.tab)
	return handle.id
end

local function siaStart(info: { name: string?, id: any?, token: any?, theme: string? })
	siaScript = info
	if siaState ~= "off" or not siaAllowed() then return end
	siaState = "loading"
	siaLoads += 1
	local load = siaLoads
	task.spawn(function()
		local client = nil
		local fetched, source = pcall((game :: any).HttpGet, game, RAYFIELD_RAW .. "sia.lua")
		if fetched and type(source) == "string" and #source > 0 then
			pcall(function()
				local SIA = (loadstring(source) :: any)()
				client = SIA.new({ token = SIA_TOKEN, lib = "gen1", libVersion = Release, script = info, theme = info.theme })
			end)
		end
		if load ~= siaLoads then return end
		if not client or siaState ~= "loading" then
			siaState, siaQueue = "off", {}
			return
		end
		sia, siaState = client, "on"
		for _, handle in siaElements do
			pcall(function()
				local id = siaId(client, handle)
				if handle.value then client:state(id, handle.value) end
			end)
		end
		local queued = siaQueue
		siaQueue = {}
		for _, fn in queued do
			pcall(fn, client)
		end
	end)
end

local function siaStop()
	if sia then pcall(sia.disable, sia) end
	sia, siaState, siaQueue = nil, "off", {}
end

local siaCurrentTab = nil

local function siaElement(kind: string, name: any, tab: number?): any
	tab = tab or 0
	local handle = { kind = kind, name = tostring(name), tab = tab }
	table.insert(siaElements, handle)
	siaRun(function(client)
		siaId(client, handle)
		if tab == siaCurrentTab then client:tab(tab) end
	end)
	return handle
end

local function siaUsed(handle: any, action: string, value: number?)
	if not handle then return end
	siaRun(function(client) client:used(siaId(client, handle), action, value) end)
end

local function siaSetState(handle: any, value: number)
	if not handle then return end
	handle.value = value
	siaRun(function(client) client:state(siaId(client, handle), value) end)
end

local function siaError(handle: any)
	if not handle then return end
	siaRun(function(client) client:error(siaId(client, handle)) end)
end

local function siaCall(method: string, ...: any)
	local args = table.pack(...)
	siaRun(function(client) client[method](client, table.unpack(args, 1, args.n)) end)
end

local RayfieldLibrary = {
	Flags = {},
	Theme = {
		-- 【完全固定用：黒×オレンジテーマ】
		KentoOrange = {
			TextColor = Color3.fromRGB(240, 240, 240),
			Background = Color3.fromRGB(12, 12, 12),
			Topbar = Color3.fromRGB(18, 18, 18),
			Shadow = Color3.fromRGB(0, 0, 0),
			NotificationBackground = Color3.fromRGB(20, 20, 20),
			NotificationActionsBackground = Color3.fromRGB(255, 100, 0),
			TabBackground = Color3.fromRGB(25, 25, 25),
			TabStroke = Color3.fromRGB(40, 40, 40),
			TabBackgroundSelected = Color3.fromRGB(255, 100, 0),
			TabTextColor = Color3.fromRGB(180, 180, 180),
			SelectedTabTextColor = Color3.fromRGB(255, 255, 255),
			ElementBackground = Color3.fromRGB(20, 20, 20),
			ElementBackgroundHover = Color3.fromRGB(28, 28, 28),
			SecondaryElementBackground = Color3.fromRGB(15, 15, 15),
			ElementStroke = Color3.fromRGB(40, 40, 40),
			SecondaryElementStroke = Color3.fromRGB(30, 30, 30),
			SliderBackground = Color3.fromRGB(255, 100, 0),
			SliderProgress = Color3.fromRGB(255, 100, 0),
			SliderStroke = Color3.fromRGB(255, 130, 30),
			ToggleBackground = Color3.fromRGB(25, 25, 25),
			ToggleEnabled = Color3.fromRGB(255, 100, 0),
			ToggleDisabled = Color3.fromRGB(70, 70, 70),
			ToggleEnabledStroke = Color3.fromRGB(255, 140, 40),
			ToggleDisabledStroke = Color3.fromRGB(90, 90, 90),
			ToggleEnabledOuterStroke = Color3.fromRGB(200, 70, 0),
			ToggleDisabledOuterStroke = Color3.fromRGB(45, 45, 45),
			DropdownSelected = Color3.fromRGB(35, 35, 35),
			DropdownUnselected = Color3.fromRGB(18, 18, 18),
			InputBackground = Color3.fromRGB(18, 18, 18),
			InputStroke = Color3.fromRGB(45, 45, 45),
			PlaceholderColor = Color3.fromRGB(120, 120, 120)
		},
		Default = {
			TextColor = Color3.fromRGB(240, 240, 240),
			Background = Color3.fromRGB(12, 12, 12),
			Topbar = Color3.fromRGB(18, 18, 18),
			Shadow = Color3.fromRGB(0, 0, 0),
			NotificationBackground = Color3.fromRGB(20, 20, 20),
			NotificationActionsBackground = Color3.fromRGB(255, 100, 0),
			TabBackground = Color3.fromRGB(25, 25, 25),
			TabStroke = Color3.fromRGB(40, 40, 40),
			TabBackgroundSelected = Color3.fromRGB(255, 100, 0),
			TabTextColor = Color3.fromRGB(180, 180, 180),
			SelectedTabTextColor = Color3.fromRGB(255, 255, 255),
			ElementBackground = Color3.fromRGB(20, 20, 20),
			ElementBackgroundHover = Color3.fromRGB(28, 28, 28),
			SecondaryElementBackground = Color3.fromRGB(15, 15, 15),
			ElementStroke = Color3.fromRGB(40, 40, 40),
			SecondaryElementStroke = Color3.fromRGB(30, 30, 30),
			SliderBackground = Color3.fromRGB(255, 100, 0),
			SliderProgress = Color3.fromRGB(255, 100, 0),
			SliderStroke = Color3.fromRGB(255, 130, 30),
			ToggleBackground = Color3.fromRGB(25, 25, 25),
			ToggleEnabled = Color3.fromRGB(255, 100, 0),
			ToggleDisabled = Color3.fromRGB(70, 70, 70),
			ToggleEnabledStroke = Color3.fromRGB(255, 140, 40),
			ToggleDisabledStroke = Color3.fromRGB(90, 90, 90),
			ToggleEnabledOuterStroke = Color3.fromRGB(200, 70, 0),
			ToggleDisabledOuterStroke = Color3.fromRGB(45, 45, 45),
			DropdownSelected = Color3.fromRGB(35, 35, 35),
			DropdownUnselected = Color3.fromRGB(18, 18, 18),
			InputBackground = Color3.fromRGB(18, 18, 18),
			InputStroke = Color3.fromRGB(45, 45, 45),
			PlaceholderColor = Color3.fromRGB(120, 120, 120)
		}
	}
}

local SelectedTheme = RayfieldLibrary.Theme.KentoOrange

local function ChangeTheme(Theme)
	SelectedTheme = RayfieldLibrary.Theme.KentoOrange

	Rayfield.Main.BackgroundColor3 = SelectedTheme.Background
	Rayfield.Main.Topbar.BackgroundColor3 = SelectedTheme.Topbar
	Rayfield.Main.Topbar.CornerRepair.BackgroundColor3 = SelectedTheme.Topbar
	Rayfield.Main.Shadow.Image.ImageColor3 = SelectedTheme.Shadow

	Rayfield.Main.Topbar.ChangeSize.ImageColor3 = SelectedTheme.TextColor
	Rayfield.Main.Topbar.Hide.ImageColor3 = SelectedTheme.TextColor
	Rayfield.Main.Topbar.Search.ImageColor3 = SelectedTheme.TextColor
	if Topbar:FindFirstChild('Settings') then
		Rayfield.Main.Topbar.Settings.ImageColor3 = SelectedTheme.TextColor
		Rayfield.Main.Topbar.Divider.BackgroundColor3 = SelectedTheme.ElementStroke
	end
end

local function getIcon(name : string)
	if not Icons then return end
	name = string.match(string.lower(name), "^%s*(.*)%s*$") :: string
	local sizedicons = Icons['48px']
	local r = sizedicons[name]
	if not r then return end
	local rirs = r[2]
	local riro = r[3]
	local irs = Vector2.new(rirs[1], rirs[2])
	local iro = Vector2.new(riro[1], riro[2])
	return { id = r[1], imageRectSize = irs, imageRectOffset = iro }
end

local function getAssetUri(id: any): string
	local assetUri = ""
	if type(id) == "number" then
		assetUri = "rbxassetid://" .. id
	end
	return assetUri
end

local function isCustomAsset(value)
	return type(value) == "string" and (string.find(value, "rbxasset://") == 1 or string.find(value, "rbxthumb://") == 1)
end

local function resolveIcon(icon)
	if not icon or icon == 0 then return "", nil, nil end
	if isCustomAsset(icon) then return icon, nil, nil end
	if typeof(icon) == "string" and Icons then
		local asset = getIcon(icon)
		if asset then return "rbxassetid://" .. asset.id, asset.imageRectOffset, asset.imageRectSize end
	end
	return getAssetUri(icon), nil, nil
end

local RayfieldAssetId = customAssetId or 10804731440
local Rayfield = useStudio and script.Parent:FindFirstChild('Rayfield') or game:GetObjects("rbxassetid://"..RayfieldAssetId)[1]
Rayfield.Enabled = false

if gethui then
	Rayfield.Parent = gethui()
elseif syn and syn.protect_gui then 
	syn.protect_gui(Rayfield)
	Rayfield.Parent = CoreGui
elseif not useStudio and CoreGui:FindFirstChild("RobloxGui") then
	Rayfield.Parent = CoreGui:FindFirstChild("RobloxGui")
elseif not useStudio then
	Rayfield.Parent = CoreGui
end

local TEARDOWN_EVENT = "RayfieldTeardown"
local function retireInterface(Interface: any)
	Interface.Enabled = false
	Interface.Name = "Rayfield-Old"
	local teardown = Interface:FindFirstChild(TEARDOWN_EVENT)
	if teardown and teardown:IsA("BindableEvent") then
		pcall(function() teardown:Fire() end)
	end
end

if gethui then
	for _, Interface in ipairs(gethui():GetChildren()) do
		if Interface.Name == Rayfield.Name and Interface ~= Rayfield then retireInterface(Interface) end
	end
elseif not useStudio then
	for _, Interface in ipairs(CoreGui:GetChildren()) do
		if Interface.Name == Rayfield.Name and Interface ~= Rayfield then retireInterface(Interface) end
	end
end

local minSize = Vector2.new(1024, 768)
local useMobileSizing = Rayfield.AbsoluteSize.X < minSize.X and Rayfield.AbsoluteSize.Y < minSize.Y
local useMobilePrompt = UserInputService.TouchEnabled

local Main = Rayfield.Main
local MPrompt = Rayfield:FindFirstChild('Prompt')
local Topbar = Main.Topbar
local Elements = Main.Elements
local LoadingFrame = Main.LoadingFrame
local TabList = Main.TabList
local dragBar = Rayfield:FindFirstChild('Drag')
local dragInteract = dragBar and dragBar.Interact or nil
local dragBarCosmetic = dragBar and dragBar.Drag or nil

local dragOffset = 255
local dragOffsetMobile = 150
Rayfield.DisplayOrder = 100
LoadingFrame.Version.Text = Release

local Icons = useStudio and require(script.Parent.icons) or loadWithTimeout(RAYFIELD_RAW .. 'icons.lua')

local CFileName = nil
local CLegacyFileName = nil
local CEnabled = false
local Minimised = false
local Hidden = false
local Debounce = false
local searchOpen = false
local Notifications = Rayfield.Notifications
local keybindConnections = {}
local rayfieldDestroyed = false

local function makeDraggable(object, dragObject, enableTaptic, tapticOffset)
	local dragging = false
	local relative = nil
	local offset = Vector2.zero
	local screenGui = object:FindFirstAncestorWhichIsA("ScreenGui")
	if screenGui and screenGui.IgnoreGuiInset then
		offset += getService('GuiService'):GetGuiInset()
	end
	dragObject.InputBegan:Connect(function(input, processed)
		if processed then return end
		local inputType = input.UserInputType.Name
		if inputType == "MouseButton1" or inputType == "Touch" then
			dragging = true
			relative = object.AbsolutePosition + object.AbsoluteSize * object.AnchorPoint - UserInputService:GetMouseLocation()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if not dragging then return end
		local inputType = input.UserInputType.Name
		if inputType == "MouseButton1" or inputType == "Touch" then
			dragging = false
		end
	end)
	RunService.RenderStepped:Connect(function()
		if dragging and not Hidden then
			local position = UserInputService:GetMouseLocation() + relative + offset
			object.Position = UDim2.fromOffset(position.X, position.Y)
		end
	end)
end

local function PackColor(Color)
	return {R = Color.R * 255, G = Color.G * 255, B = Color.B * 255}
end    
local function UnpackColor(Color)
	return Color3.fromRGB(Color.R, Color.G, Color.B)
end

local function LoadConfiguration(Configuration)
	local success, Data = pcall(function() return HttpService:JSONDecode(Configuration) end)
	local changed
	if not success then return end
	for FlagName, Flag in pairs(RayfieldLibrary.Flags) do
		local FlagValue = Data[FlagName]
		if (typeof(FlagValue) == 'boolean' and FlagValue == false) or FlagValue then
			task.spawn(function()
				if Flag.Type == "ColorPicker" then
					changed = true
					Flag:Set(UnpackColor(FlagValue))
				else
					if (Flag.CurrentValue or Flag.CurrentKeybind or Flag.CurrentOption or Flag.Color) ~= FlagValue then 
						changed = true
						Flag:Set(FlagValue) 	
					end
				end
			end)
		end
	end
	return changed
end

local function SaveConfiguration()
	if not CEnabled or not globalLoaded then return end
	local Data = {}
	for i, v in pairs(RayfieldLibrary.Flags) do
		if v.Type == "ColorPicker" then
			Data[i] = PackColor(v.Color)
		else
			Data[i] = v.CurrentValue or v.CurrentKeybind or v.CurrentOption or v.Color
		end
	end
	callSafely(writefile, ConfigurationFolder .. "/" .. CFileName .. ConfigurationExtension, tostring(HttpService:JSONEncode(Data)))
end

function RayfieldLibrary:Notify(data)
	if rayfieldDestroyed then return end
	task.spawn(function()
		local newNotification = Notifications.Template:Clone()
		newNotification.Name = data.Title or 'Notification'
		newNotification.Parent = Notifications
		newNotification.Visible = false
		newNotification.Title.Text = data.Title or "Notification"
		newNotification.Description.Text = data.Content or ""
		newNotification.Title.TextColor3 = SelectedTheme.TextColor
		newNotification.Description.TextColor3 = SelectedTheme.TextColor
		newNotification.BackgroundColor3 = SelectedTheme.Background
		newNotification.UIStroke.Color = SelectedTheme.TextColor
		newNotification.BackgroundTransparency = 1
		newNotification.Title.TextTransparency = 1
		newNotification.Description.TextTransparency = 1
		newNotification.UIStroke.Transparency = 1
		newNotification.Shadow.ImageTransparency = 1
		newNotification.Size = UDim2.new(1, 0, 0, 800)
		task.wait()
		newNotification.Visible = true
		local bounds = {newNotification.Title.TextBounds.Y, newNotification.Description.TextBounds.Y}
		TweenService:Create(newNotification, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, 0, 0, math.max(bounds[1] + bounds[2] + 31, 60))}):Play()
		task.wait(data.Duration or 4)
		newNotification:Destroy()
	end)
end

function RayfieldLibrary:CreateWindow(Settings)
	if Rayfield:FindFirstChild('Loading') then
		Rayfield.Enabled = true
		Rayfield.Loading.Visible = true
		LoadingFrame.Title.Text = Settings.LoadingTitle or "KENTO HUB"
		LoadingFrame.Subtitle.Text = Settings.LoadingSubtitle or "Initializing..."
		LoadingFrame.Version.Text = Release
		task.wait(1.5)
		Rayfield.Loading.Visible = false
	end

	Topbar.Title.Text = Settings.Name or "Kento Hub"
	Main.Size = UDim2.new(0, 500, 0, 475)
	Main.Visible = true
	Main.BackgroundTransparency = 0

	ChangeTheme('KentoOrange')
	makeDraggable(Main, Topbar, false, {dragOffset, dragOffsetMobile})

	Rayfield.Enabled = true

	local Window = {}
	local FirstTab = false

	function Window:CreateTab(Name, Image, Ext)
		local TabButton = TabList.Template:Clone()
		TabButton.Name = Name
		TabButton.Title.Text = Name
		TabButton.Parent = TabList
		TabButton.Visible = true

		local TabPage = Elements.Template:Clone()
		TabPage.Name = Name
		TabPage.Visible = true
		TabPage.Parent = Elements

		if not FirstTab and not Ext then
			Elements.UIPageLayout:JumpTo(TabPage)
			FirstTab = Name
		end

		TabButton.Interact.MouseButton1Click:Connect(function()
			Elements.UIPageLayout:JumpTo(TabPage)
		end)

		local Tab = {}

		function Tab:CreateButton(ButtonSettings)
			local Button = Elements.Template.Button:Clone()
			Button.Name = ButtonSettings.Name
			Button.Title.Text = ButtonSettings.Name
			Button.Visible = true
			Button.Parent = TabPage
			Button.Interact.MouseButton1Click:Connect(function()
				pcall(ButtonSettings.Callback)
			end)
			return Button
		end

		function Tab:CreateToggle(ToggleSettings)
			local Toggle = Elements.Template.Toggle:Clone()
			Toggle.Name = ToggleSettings.Name
			Toggle.Title.Text = ToggleSettings.Name
			Toggle.Visible = true
			Toggle.Parent = TabPage
			Toggle.Interact.MouseButton1Click:Connect(function()
				ToggleSettings.CurrentValue = not ToggleSettings.CurrentValue
				pcall(function() ToggleSettings.Callback(ToggleSettings.CurrentValue) end)
			end)
			return ToggleSettings
		end

		function Tab:CreateSlider(SliderSettings)
			local Slider = Elements.Template.Slider:Clone()
			Slider.Name = SliderSettings.Name
			Slider.Title.Text = SliderSettings.Name
			Slider.Visible = true
			Slider.Parent = TabPage
			return SliderSettings
		end

		function Tab:CreateSection(SectionName)
			local Section = Elements.Template.SectionTitle:Clone()
			Section.Title.Text = SectionName
			Section.Visible = true
			Section.Parent = TabPage
			return Section
		end

		function Tab:CreateInput(InputSettings)
			local Input = Elements.Template.Input:Clone()
			Input.Name = InputSettings.Name
			Input.Title.Text = InputSettings.Name
			Input.Visible = true
			Input.Parent = TabPage
			Input.InputFrame.InputBox.FocusLost:Connect(function()
				pcall(function() InputSettings.Callback(Input.InputFrame.InputBox.Text) end)
			end)
			return InputSettings
		end

		function Tab:CreateDropdown(DropdownSettings)
			local Dropdown = Elements.Template.Dropdown:Clone()
			Dropdown.Name = DropdownSettings.Name
			Dropdown.Title.Text = DropdownSettings.Name
			Dropdown.Visible = true
			Dropdown.Parent = TabPage
			return DropdownSettings
		end

		function Tab:CreateKeybind(KeybindSettings)
			local Keybind = Elements.Template.Keybind:Clone()
			Keybind.Name = KeybindSettings.Name
			Keybind.Title.Text = KeybindSettings.Name
			Keybind.Visible = true
			Keybind.Parent = TabPage
			return KeybindSettings
		end

		function Tab:CreateColorPicker(ColorPickerSettings)
			local ColorPicker = Elements.Template.ColorPicker:Clone()
			ColorPicker.Name = ColorPickerSettings.Name
			ColorPicker.Title.Text = ColorPickerSettings.Name
			ColorPicker.Visible = true
			ColorPicker.Parent = TabPage
			return ColorPickerSettings
		end

		function Tab:CreateLabel(LabelText)
			local Label = Elements.Template.Label:Clone()
			Label.Title.Text = LabelText
			Label.Visible = true
			Label.Parent = TabPage
			return Label
		end

		function Tab:CreateParagraph(ParagraphSettings)
			local Paragraph = Elements.Template.Paragraph:Clone()
			Paragraph.Title.Text = ParagraphSettings.Title
			Paragraph.Content.Text = ParagraphSettings.Content
			Paragraph.Visible = true
			Paragraph.Parent = TabPage
			return Paragraph
		end

		return Tab
	end

	return Window
end

function RayfieldLibrary:LoadConfiguration()
	globalLoaded = true
end

return RayfieldLibrary
