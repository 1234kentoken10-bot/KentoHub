--[[
	Rayfield  ->  Orange x Black restyle patch
	3か所を差し替え/追加するだけ。元のファイルの他の部分は触らなくてOK。
]]

--------------------------------------------------------------------------------
-- PATCH 1:  RayfieldLibrary.Theme の中( Default = {...}, の直前 )に追加
--------------------------------------------------------------------------------
		Orange = {
			TextColor = Color3.fromRGB(245, 240, 235),

			Background = Color3.fromRGB(12, 12, 12),
			Topbar = Color3.fromRGB(18, 18, 18),
			Shadow = Color3.fromRGB(255, 110, 0),

			NotificationBackground = Color3.fromRGB(14, 14, 14),
			NotificationActionsBackground = Color3.fromRGB(255, 140, 40),

			TabBackground = Color3.fromRGB(26, 26, 26),
			TabStroke = Color3.fromRGB(60, 38, 20),
			TabBackgroundSelected = Color3.fromRGB(255, 120, 0),
			TabTextColor = Color3.fromRGB(200, 190, 180),
			SelectedTabTextColor = Color3.fromRGB(10, 10, 10),

			ElementBackground = Color3.fromRGB(22, 22, 22),
			ElementBackgroundHover = Color3.fromRGB(32, 28, 24),
			SecondaryElementBackground = Color3.fromRGB(17, 17, 17),
			ElementStroke = Color3.fromRGB(52, 40, 30),
			SecondaryElementStroke = Color3.fromRGB(40, 32, 26),

			SliderBackground = Color3.fromRGB(130, 62, 0),
			SliderProgress = Color3.fromRGB(255, 120, 0),
			SliderStroke = Color3.fromRGB(255, 160, 60),

			ToggleBackground = Color3.fromRGB(20, 20, 20),
			ToggleEnabled = Color3.fromRGB(255, 120, 0),
			ToggleDisabled = Color3.fromRGB(85, 85, 85),
			ToggleEnabledStroke = Color3.fromRGB(255, 160, 60),
			ToggleDisabledStroke = Color3.fromRGB(115, 115, 115),
			ToggleEnabledOuterStroke = Color3.fromRGB(120, 60, 10),
			ToggleDisabledOuterStroke = Color3.fromRGB(50, 50, 50),

			DropdownSelected = Color3.fromRGB(60, 34, 12),
			DropdownUnselected = Color3.fromRGB(24, 24, 24),

			InputBackground = Color3.fromRGB(18, 18, 18),
			InputStroke = Color3.fromRGB(75, 48, 26),
			PlaceholderColor = Color3.fromRGB(150, 135, 120)
		},

--------------------------------------------------------------------------------
-- PATCH 2:  デフォルトテーマをOrangeにする（2行）
--------------------------------------------------------------------------------
-- 変更前:  local SelectedTheme = RayfieldLibrary.Theme.Default
local SelectedTheme = RayfieldLibrary.Theme.Orange

-- CreateWindow 内、 `if Settings.Theme then` の直前に1行追加:
Settings.Theme = Settings.Theme or "Orange"

--------------------------------------------------------------------------------
-- PATCH 3:  新しいローディング画面 + ウィンドウ装飾
-- (A) 関数定義: `local function fadeOutKeyUI(KeyMain)` の直前に貼る
--------------------------------------------------------------------------------
local ACCENT = Color3.fromRGB(255, 120, 0)
local ACCENT_LIGHT = Color3.fromRGB(255, 176, 80)

local function addCorner(obj, radius)
	local c = obj:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = obj
end

local function styleWindow()
	pcall(function()
		-- 背景に黒→ごく薄いオレンジの斜めグラデ
		local g = Main:FindFirstChild("RFGradient") or Instance.new("UIGradient")
		g.Name = "RFGradient"
		g.Rotation = 135
		g.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.6, Color3.fromRGB(235, 232, 230)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 222, 200)),
		})
		g.Parent = Main

		-- 外枠のオレンジグロー
		local s = Main:FindFirstChild("RFStroke") or Instance.new("UIStroke")
		s.Name = "RFStroke"
		s.Thickness = 1.2
		s.Color = ACCENT
		s.Transparency = 0.55
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = Main
		local sg = Instance.new("UIGradient")
		sg.Rotation = 90
		sg.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 0.85),
		})
		sg.Parent = s
	end)

	pcall(function()
		Topbar.Divider.BackgroundColor3 = ACCENT
		Topbar.Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	end)
end

-- ローディング画面：オレンジのタイトル + 細いプログレスバー + 流れる光
local function playLoadingFX(duration)
	task.spawn(function()
		pcall(function()
			LoadingFrame.Title.TextColor3 = ACCENT
			LoadingFrame.Subtitle.TextColor3 = Color3.fromRGB(170, 160, 150)
			LoadingFrame.Version.TextColor3 = ACCENT_LIGHT

			local track = Instance.new("Frame")
			track.Name = "RFTrack"
			track.AnchorPoint = Vector2.new(0.5, 1)
			track.Position = UDim2.new(0.5, 0, 1, -12)
			track.Size = UDim2.new(0.62, 0, 0, 3)
			track.BackgroundColor3 = Color3.fromRGB(38, 30, 24)
			track.BorderSizePixel = 0
			track.BackgroundTransparency = 1
			track.ZIndex = 10
			track.Parent = LoadingFrame
			addCorner(track, 2)

			local fill = Instance.new("Frame")
			fill.Name = "Fill"
			fill.Size = UDim2.new(0, 0, 1, 0)
			fill.BackgroundColor3 = ACCENT
			fill.BorderSizePixel = 0
			fill.ZIndex = 11
			fill.Parent = track
			addCorner(fill, 2)

			local grad = Instance.new("UIGradient")
			grad.Color = ColorSequence.new(ACCENT, ACCENT_LIGHT)
			grad.Parent = fill

			-- バー先端の光
			local glow = Instance.new("Frame")
			glow.AnchorPoint = Vector2.new(0.5, 0.5)
			glow.Position = UDim2.new(1, 0, 0.5, 0)
			glow.Size = UDim2.new(0, 14, 0, 14)
			glow.BackgroundColor3 = ACCENT_LIGHT
			glow.BackgroundTransparency = 0.75
			glow.BorderSizePixel = 0
			glow.ZIndex = 12
			glow.Parent = fill
			addCorner(glow, 7)

			TweenService:Create(track, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {BackgroundTransparency = 0}):Play()
			TweenService:Create(fill, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {Size = UDim2.new(1, 0, 1, 0)}):Play()

			-- タイトルのゆっくりした明滅
			local pulse = TweenService:Create(LoadingFrame.Title, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {TextColor3 = ACCENT_LIGHT})
			pulse:Play()

			task.wait(duration + 0.1)
			pulse:Cancel()
			TweenService:Create(track, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
			TweenService:Create(fill, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
			TweenService:Create(glow, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
			task.wait(0.3)
			track:Destroy()
		end)
	end)
end

-- 初回だけ出る全画面スプラッシュ(Rayfield.Loading)も黒×オレンジに
local function styleSplash()
	pcall(function()
		local L = Rayfield:FindFirstChild("Loading")
		if not L then return end
		if L:IsA("GuiObject") then L.BackgroundColor3 = Color3.fromRGB(8, 8, 8) end
		if L:FindFirstChild("Banner") then L.Banner.ImageColor3 = ACCENT end
	end)
end

--------------------------------------------------------------------------------
-- (B) 呼び出し位置
--------------------------------------------------------------------------------
-- 1) CreateWindow の冒頭  `if Rayfield:FindFirstChild('Loading') then` の直前に:
styleSplash()

-- 2) CreateWindow 内、テーマ適用ブロック( `if Settings.Theme then ... end` )のすぐ後ろに:
styleWindow()

-- 3) CreateWindow 内、 `siaCall("window", "open")` の直後に:
playLoadingFX(1.5)

-- 4) 通知もオレンジに(RayfieldLibrary:Notify 内、
--    `newNotification.UIStroke.Color = SelectedTheme.TextColor` を次に置換):
newNotification.UIStroke.Color = Color3.fromRGB(255, 120, 0)
