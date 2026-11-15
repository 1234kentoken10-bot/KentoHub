--[[

	Rayfield Interface Suite - Kento Hub Custom (Fixed Theme)
	by Sirius (Customized for Kento Hub)

]]

-- 簡易セキュリティ・環境チェック
local secureMode = false
if getgenv then
	local ok, result = pcall(function() return getgenv().RAYFIELD_SECURE end)
	if ok and result then secureMode = true end
end

local function getService(name)
	local service = game:GetService(name)
	return if cloneref then cloneref(service) else service
end

local UserInputService = getService("UserInputService")
local TweenService = getService("TweenService")
local Players = getService("Players")
local CoreGui = getService("CoreGui")
local HttpService = getService("HttpService")
local RunService = getService("RunService")

local RayfieldFolder = "Rayfield"
local ConfigurationFolder = RayfieldFolder.."/Configurations"
local ConfigurationExtension = ".rfld"

local function callSafely(func, ...)
	if func then
		local success, result = pcall(func, ...)
		if not success then return false else return result end
	end
end

local function ensureFolder(folderPath)
	if isfolder and not callSafely(isfolder, folderPath) then
		callSafely(makefolder, folderPath)
	end
end

-- =====================================================================
-- 【完全固定カスタムテーマ】漆黒ブラック × ネオンオレンジ
-- =====================================================================
local KentoOrangeTheme = {
	TextColor = Color3.fromRGB(240, 240, 240),
	Background = Color3.fromRGB(12, 12, 12),          -- 真っ黒な背景
	Topbar = Color3.fromRGB(18, 18, 18),            -- トップバー
	Shadow = Color3.fromRGB(0, 0, 0),

	NotificationBackground = Color3.fromRGB(20, 20, 20),
	NotificationActionsBackground = Color3.fromRGB(255, 100, 0),

	TabBackground = Color3.fromRGB(25, 25, 25),
	TabStroke = Color3.fromRGB(40, 40, 40),
	TabBackgroundSelected = Color3.fromRGB(255, 100, 0), -- 選択時は鮮やかなオレンジ
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

-- 既存のRayfield GUIオブジェクトをロード（またはフォールバック生成）
local RayfieldAssetId = 10804731440
local Rayfield = game:GetObjects("rbxassetid://"..RayfieldAssetId)[1]
Rayfield.Enabled = false

if gethui then
	Rayfield.Parent = gethui()
elseif syn and syn.protect_gui then 
	syn.protect_gui(Rayfield)
	Rayfield.Parent = CoreGui
else
	Rayfield.Parent = CoreGui
end

local Main = Rayfield.Main
local Topbar = Main.Topbar
local Elements = Main.Elements
local LoadingFrame = Main.LoadingFrame
local TabList = Main.TabList

Rayfield.DisplayOrder = 100

local RayfieldLibrary = {
	Flags = {},
	Theme = { Default = KentoOrangeTheme }
}

-- テーマをオレンジ黒に強制適用する関数
local function ApplyKentoTheme()
	Rayfield.Main.BackgroundColor3 = KentoOrangeTheme.Background
	Rayfield.Main.Topbar.BackgroundColor3 = KentoOrangeTheme.Topbar
	Rayfield.Main.Topbar.CornerRepair.BackgroundColor3 = KentoOrangeTheme.Topbar
	Rayfield.Main.Shadow.Image.ImageColor3 = KentoOrangeTheme.Shadow

	Rayfield.Main.Topbar.ChangeSize.ImageColor3 = KentoOrangeTheme.TextColor
	Rayfield.Main.Topbar.Hide.ImageColor3 = KentoOrangeTheme.TextColor
	Rayfield.Main.Topbar.Search.ImageColor3 = KentoOrangeTheme.TextColor
	if Topbar:FindFirstChild('Settings') then
		Rayfield.Main.Topbar.Settings.ImageColor3 = KentoOrangeTheme.TextColor
		Rayfield.Main.Topbar.Divider.BackgroundColor3 = KentoOrangeTheme.ElementStroke
	end
end

-- ドラッグ移動の実装
local function makeDraggable(object, dragObject)
	local dragging = false
	local relative = nil
	dragObject.InputBegan:Connect(function(input)
		if input.UserInputType.Name == "MouseButton1" or input.UserInputType.Name == "Touch" then
			dragging = true
			relative = object.AbsolutePosition + object.AbsoluteSize * object.AnchorPoint - UserInputService:GetMouseLocation()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType.Name == "MouseButton1" or input.UserInputType.Name == "Touch" then
			dragging = false
		end
	end)
	RunService.RenderStepped:Connect(function()
		if dragging then
			local position = UserInputService:GetMouseLocation() + relative
			object.Position = UDim2.fromOffset(position.X, position.Y)
		end
	end)
end

function RayfieldLibrary:Notify(data)
	print("[Kento Hub Notify] " .. tostring(data.Title) .. " : " .. tostring(data.Content))
end

function RayfieldLibrary:CreateWindow(Settings)
	-- 【起動ローディング画面】
	if Rayfield:FindFirstChild('Loading') then
		Rayfield.Enabled = true
		Rayfield.Loading.Visible = true

		LoadingFrame.Title.Text = Settings.LoadingTitle or "KENTO HUB"
		LoadingFrame.Subtitle.Text = Settings.LoadingSubtitle or "Loading System..."
		LoadingFrame.Version.Text = "Build 1.760 (Custom)"

		task.wait(1.5)
		Rayfield.Loading.Visible = false
	end

	Topbar.Title.Text = Settings.Name or "Kento Hub"
	Main.Size = UDim2.new(0, 500, 0, 475)
	Main.Visible = true
	Main.BackgroundTransparency = 0

	ApplyKentoTheme()
	makeDraggable(Main, Topbar)

	Rayfield.Enabled = true

	local Window = {}
	local FirstTab = false

	function Window:CreateTab(Name, Image)
		local TabButton = TabList.Template:Clone()
		TabButton.Name = Name
		TabButton.Title.Text = Name
		TabButton.Parent = TabList
		TabButton.Visible = true

		local TabPage = Elements.Template:Clone()
		TabPage.Name = Name
		TabPage.Visible = true
		TabPage.Parent = Elements

		if not FirstTab then
			Elements.UIPageLayout:JumpTo(TabPage)
			FirstTab = true
		end

		TabButton.MouseButton1Click = TabButton:FindFirstChild("Interact") and TabButton.Interact.MouseButton1Click or TabButton.MouseButton1Click
		if TabButton:FindFirstChild("Interact") then
			TabButton.Interact.MouseButton1Click:Connect(function()
				Elements.UIPageLayout:JumpTo(TabPage)
			end)
		end

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
		end

		function Tab:CreateSlider(SliderSettings)
			local Slider = Elements.Template.Slider:Clone()
			Slider.Name = SliderSettings.Name
			Slider.Title.Text = SliderSettings.Name
			Slider.Visible = true
			Slider.Parent = TabPage
		end

		function Tab:CreateSection(SectionName)
			local Section = Elements.Template.SectionTitle:Clone()
			Section.Title.Text = SectionName
			Section.Visible = true
			Section.Parent = TabPage
		end

		return Tab
	end

	return Window
end

return RayfieldLibrary
