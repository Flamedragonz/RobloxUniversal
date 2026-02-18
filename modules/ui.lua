--[[
    ╔══════════════════════════════════════╗
    ║  MODULE: ui.lua                      ║
    ║  Главный UI builder                  ║
    ║                                      ║
    ║  Зависимости: ВСЕ предыдущие         ║
    ║  config, state, utils, notify,       ║
    ║  components, engine                  ║
    ║                                      ║
    ║  RAW ссылка → loader.lua →           ║
    ║  loadModule("ui")                    ║
    ║                                      ║
    ║  Возвращает таблицу с методами:      ║
    ║  UI.Create()  — построить окно       ║
    ║  UI.Destroy() — удалить окно         ║
    ╚══════════════════════════════════════╝
]]

local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local TCP = getgenv().TCP
local Config    = TCP.Modules.Config
local State     = TCP.Modules.State
local Utils     = TCP.Modules.Utils
local Notify    = TCP.Modules.Notify
local Comp      = TCP.Modules.Components
local Engine    = TCP.Modules.Engine

local C = Config.Colors
local UI = {}

function UI.Destroy()
    if State.GUI then
        State.GUI:Destroy()
        State.GUI = nil
    end
end

function UI.Create()
    UI.Destroy()

    -- ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TCP_VapeStyle"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999

    local ok = pcall(function() screenGui.Parent = CoreGui end)
    if not ok then screenGui.Parent = State.Player.PlayerGui end

    State.GUI = screenGui
    Notify.Init(screenGui)

    -- ===== MAIN FRAME =====
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 440, 0, 560)
    mainFrame.Position = UDim2.new(0.5, -220, 0.5, -280)
    mainFrame.BackgroundColor3 = C.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    Utils.CreateCorner(mainFrame, 12)
    Utils.CreateStroke(mainFrame, Color3.fromRGB(45, 45, 55), 1, 0.3)
    Utils.CreateShadow(mainFrame)

    -- Intro animation
    mainFrame.BackgroundTransparency = 1
    mainFrame.Size = UDim2.new(0, 440, 0, 0)
    Utils.Tween(mainFrame, {
        BackgroundTransparency = 0,
        Size = UDim2.new(0, 440, 0, 560)
    }, 0.4, Enum.EasingStyle.Back)

    -- ===== HEADER =====
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 52)
    header.BackgroundColor3 = C.Surface
    header.BackgroundTransparency = 0.3
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    Utils.CreateCorner(header, 12)

    -- Accent line
    local headerAccent = Instance.new("Frame")
    headerAccent.Size = UDim2.new(1, -20, 0, 2)
    headerAccent.Position = UDim2.new(0, 10, 1, -1)
    headerAccent.BorderSizePixel = 0
    headerAccent.Parent = header
    Utils.CreateCorner(headerAccent, 1)
    Utils.CreateGradient(headerAccent, C.Accent, C.AccentGlow, 0)

    -- Logo
    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(0, 30, 0, 30)
    logo.Position = UDim2.new(0, 14, 0.5, -15)
    logo.BackgroundColor3 = C.Accent
    logo.Text = "T"
    logo.TextColor3 = Color3.new(1, 1, 1)
    logo.Font = Enum.Font.GothamBlack
    logo.TextSize = 16
    logo.Parent = header
    Utils.CreateCorner(logo, 8)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.new(0, 52, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Teleport Control"
    title.TextColor3 = C.TextPrimary
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local ver = Instance.new("TextLabel")
    ver.Size = UDim2.new(0, 50, 1, 0)
    ver.Position = UDim2.new(1, -60, 0, 0)
    ver.BackgroundTransparency = 1
    ver.Text = "v2.0"
    ver.TextColor3 = C.TextSecondary
    ver.Font = Enum.Font.GothamMedium
    ver.TextSize = 12
    ver.Parent = header

    -- ===== TAB BAR =====
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -20, 0, 36)
    tabBar.Position = UDim2.new(0, 10, 0, 60)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = mainFrame
    Utils.CreateListLayout(tabBar, Enum.FillDirection.Horizontal, 6)

    -- ===== PAGE CONTAINER =====
    local pageContainer = Instance.new("Frame")
    pageContainer.Size = UDim2.new(1, -20, 1, -200)
    pageContainer.Position = UDim2.new(0, 10, 0, 104)
    pageContainer.BackgroundTransparency = 1
    pageContainer.ClipsDescendants = true
    pageContainer.Parent = mainFrame

    -- ===== STATUS PAGE =====
    local statusPage = Instance.new("ScrollingFrame")
    statusPage.Name = "StatusPage"
    statusPage.Size = UDim2.new(1, 0, 1, 0)
    statusPage.BackgroundTransparency = 1
    statusPage.ScrollBarThickness = 3
    statusPage.ScrollBarImageColor3 = C.Accent
    statusPage.BorderSizePixel = 0
    statusPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
    statusPage.Visible = true
    statusPage.Parent = pageContainer
    Utils.CreateListLayout(statusPage, nil, 8)
    Utils.CreatePadding(statusPage, 0, 40, 0, 0)

    -- Status Card
    local statusCard = Instance.new("Frame")
    statusCard.Size = UDim2.new(1, 0, 0, 60)
    statusCard.BackgroundColor3 = C.Surface
    statusCard.LayoutOrder = 1
    statusCard.Parent = statusPage
    Utils.CreateCorner(statusCard, 10)
    local statusStroke = Utils.CreateStroke(statusCard, C.Success, 1, 0.6)

    local statusDot = Instance.new("Frame")
    statusDot.Size = UDim2.new(0, 12, 0, 12)
    statusDot.Position = UDim2.new(0, 16, 0.5, -6)
    statusDot.BackgroundColor3 = C.Success
    statusDot.BorderSizePixel = 0
    statusDot.Parent = statusCard
    Utils.CreateCorner(statusDot, 6)

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0.5, -40, 1, 0)
    statusLabel.Position = UDim2.new(0, 36, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "ACTIVE"
    statusLabel.TextColor3 = C.Success
    statusLabel.Font = Enum.Font.GothamBlack
    statusLabel.TextSize = 20
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = statusCard

    local statusSub = Instance.new("TextLabel")
    statusSub.Size = UDim2.new(0.5, -14, 1, 0)
    statusSub.Position = UDim2.new(0.5, 0, 0, 0)
    statusSub.BackgroundTransparency = 1
    statusSub.Text = "Press K to start"
    statusSub.TextColor3 = C.TextSecondary
    statusSub.Font = Enum.Font.GothamMedium
    statusSub.TextSize = 12
    statusSub.TextXAlignment = Enum.TextXAlignment.Right
    statusSub.Parent = statusCard

    State.UIElements.StatusCard = statusCard
    State.UIElements.StatusStroke = statusStroke
    State.UIElements.StatusDot = statusDot
    State.UIElements.StatusLabel = statusLabel
    State.UIElements.StatusSub = statusSub

    -- Statistics
    Comp.CreateSection(statusPage, "STATISTICS", 2)
    State.UIElements.Ping      = Comp.CreateInfoRow(statusPage, "📡", "Ping", "...", C.Danger, 3)
    State.UIElements.Collected = Comp.CreateInfoRow(statusPage, "📦", "Collected", "0", C.Warning, 4)
    State.UIElements.Active    = Comp.CreateInfoRow(statusPage, "⚡", "Active Parts", "0 / 50", C.Info, 5)

    -- Current Config
    Comp.CreateSection(statusPage, "CURRENT CONFIG", 6)
    State.UIElements.Mode    = Comp.CreateInfoRow(statusPage, "🔄", "Mode", "Loop", C.AccentGlow, 7)
    State.UIElements.Target  = Comp.CreateInfoRow(statusPage, "🎯", "Target", "Player", C.AccentGlow, 8)
    State.UIElements.TPType  = Comp.CreateInfoRow(statusPage, "💫", "Teleport", "Instant", C.AccentGlow, 9)
    State.UIElements.Folder  = Comp.CreateInfoRow(statusPage, "📂", "Folder",
        Config.FolderPath == "" and "Workspace" or Config.FolderPath, C.TextSecondary, 10)
    State.UIElements.Filter  = Comp.CreateInfoRow(statusPage, "🔍", "Filter",
        Config.PartName == "" and "ALL" or Config.PartName, C.TextSecondary, 11)
    State.UIElements.KeyHint = Comp.CreateInfoRow(statusPage, "⌨️", "Key K", "Start Loop", C.Success, 12)

    -- ===== SETTINGS PAGE =====
    local settingsPage = Instance.new("ScrollingFrame")
    settingsPage.Name = "SettingsPage"
    settingsPage.Size = UDim2.new(1, 0, 1, 0)
    settingsPage.BackgroundTransparency = 1
    settingsPage.ScrollBarThickness = 3
    settingsPage.ScrollBarImageColor3 = C.Accent
    settingsPage.BorderSizePixel = 0
    settingsPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
    settingsPage.Visible = false
    settingsPage.Parent = pageContainer
    Utils.CreateListLayout(settingsPage, nil, 8)
    Utils.CreatePadding(settingsPage, 0, 60, 0, 0)

    -- Source Section
    Comp.CreateSection(settingsPage, "SOURCE", 1)

    Comp.CreateInput(settingsPage, "📂 Folder Path", "e.g. ItemDebris (empty = Workspace)",
        Config.FolderPath, function(txt)
            Config.FolderPath = txt
            State.UIElements.Folder.Text = txt == "" and "Workspace" or txt
        end, 2)

    Comp.CreateInput(settingsPage, "🔍 Part Name Filter", "e.g. Gold (empty = ALL)",
        Config.PartName, function(txt)
            Config.PartName = txt
            State.UIElements.Filter.Text = txt == "" and "ALL" or txt
        end, 3)

    Comp.CreateInput(settingsPage, "📊 Max Active Parts", "Anti-lag limit",
        tostring(Config.MaxParts), function(txt)
            local n = tonumber(txt)
            if n and n > 0 then Config.MaxParts = math.floor(n) end
        end, 4)

    -- Target Section
    Comp.CreateSection(settingsPage, "TARGET", 5)

    local customTargetGroup = Instance.new("Frame")
    customTargetGroup.Size = UDim2.new(1, 0, 0, 0)
    customTargetGroup.AutomaticSize = Enum.AutomaticSize.Y
    customTargetGroup.BackgroundTransparency = 1
    customTargetGroup.Visible = Config.TargetMode ~= "Mouse"
    customTargetGroup.LayoutOrder = 7
    customTargetGroup.Parent = settingsPage
    Utils.CreateListLayout(customTargetGroup, nil, 8)
    State.UIElements.CustomTargetGroup = customTargetGroup

    Comp.CreateToggle(settingsPage, "🖱️ Mouse Target", Config.TargetMode == "Mouse",
        function(val)
            Config.TargetMode = val and "Mouse" or "CustomPart"
            customTargetGroup.Visible = not val
            State.UIElements.Target.Text = val and "Mouse" or
                (State.CustomTargetPart and State.CustomTargetPart.Name or
                (Config.TargetPartName == "" and "Player" or Config.TargetPartName))
        end, 6)

    local ctInput = Comp.CreateInput(customTargetGroup, "📍 Custom Target Part Name",
        "Part name to target", Config.TargetPartName, function(txt)
            Config.TargetPartName = txt
            if txt ~= "" then
                State.CustomTargetPart = nil
                Engine.UpdateSelectionBox(nil)
            end
            State.UIElements.Target.Text = txt == "" and "Player" or txt
        end)
    State.UIElements.CustomTargetInput = ctInput

    local selectBtn = Comp.CreateButton(customTargetGroup,
        "👆 Click to Select Target", Color3.fromRGB(50, 80, 140),
        function(btn)
            if State.IsSelectingTarget then
                State.IsSelectingTarget = false
                btn.Text = "👆 Click to Select Target"
                Utils.Tween(btn, {BackgroundColor3 = Color3.fromRGB(50, 80, 140)}, 0.2)
            else
                State.IsSelectingTarget = true
                btn.Text = "🔴 CLICK ANY PART..."
                Utils.Tween(btn, {BackgroundColor3 = C.Danger}, 0.2)
            end
        end)
    State.UIElements.SelectBtn = selectBtn

    -- Teleport Behavior
    Comp.CreateSection(settingsPage, "TELEPORT BEHAVIOR", 8)

    Comp.CreateToggle(settingsPage, "🥞 Stack Mode", Config.StackMode,
        function(val) Config.StackMode = val end, 9)

    Comp.CreateInput(settingsPage, "⛓️ Spacing", "2",
        tostring(Config.Spacing), function(txt)
            Config.Spacing = tonumber(txt) or 2
        end, 10)

    local offsetInputs = Comp.CreateOffsetInputs(settingsPage, Config.Offset, nil, 11)

    Comp.CreateToggle(settingsPage, "⚓ Anchor on Release", Config.AnchorOnFinish,
        function(val) Config.AnchorOnFinish = val end, 12)

    -- Smooth Teleport
    Comp.CreateSection(settingsPage, "SMOOTH TELEPORT", 13)

    Comp.CreateToggle(settingsPage, "💫 Smooth Teleport", Config.SmoothTeleport,
        function(val)
            Config.SmoothTeleport = val
            State.UIElements.TPType.Text = val and "Smooth" or "Instant"
            Engine.ReprepareParts()
        end, 14)

    Comp.CreateInput(settingsPage, "💨 Smooth Speed", "25",
        tostring(Config.SmoothSpeed), function(txt)
            Config.SmoothSpeed = tonumber(txt) or 25
        end, 15)

    -- Offset updater
    State.Connections["OffsetUpdate"] = RunService.Heartbeat:Connect(function()
        if offsetInputs then
            Config.Offset = offsetInputs.GetOffset()
        end
    end)

    -- ===== TAB BUTTONS =====
    local pagesList = {statusPage, settingsPage}
    local tabNames = {"📊 Status", "⚙️ Settings"}
    local tabBtns = {}

    for i, name in ipairs(tabNames) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.5, -3, 1, 0)
        btn.BackgroundColor3 = i == 1 and C.Accent or C.SurfaceLight
        btn.BackgroundTransparency = i == 1 and 0 or 0.5
        btn.Text = name
        btn.TextColor3 = i == 1 and C.TextPrimary or C.TextSecondary
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.AutoButtonColor = false
        btn.Parent = tabBar
        Utils.CreateCorner(btn, 8)
        tabBtns[i] = btn

        btn.MouseButton1Click:Connect(function()
            for j, page in ipairs(pagesList) do
                page.Visible = (j == i)
                Utils.Tween(tabBtns[j], {
                    BackgroundColor3 = (j == i) and C.Accent or C.SurfaceLight,
                    BackgroundTransparency = (j == i) and 0 or 0.5,
                    TextColor3 = (j == i) and C.TextPrimary or C.TextSecondary,
                }, 0.2)
            end
        end)
    end

    -- ===== FOOTER =====
    local footer = Instance.new("Frame")
    footer.Size = UDim2.new(1, -20, 0, 88)
    footer.Position = UDim2.new(0, 10, 1, -96)
    footer.BackgroundTransparency = 1
    footer.Parent = mainFrame

    -- Main Toggle
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, 0, 0, 42)
    toggleBtn.BackgroundColor3 = C.Warning
    toggleBtn.Text = "⏸️  DEACTIVATE"
    toggleBtn.TextColor3 = Color3.fromRGB(30, 30, 30)
    toggleBtn.Font = Enum.Font.GothamBlack
    toggleBtn.TextSize = 16
    toggleBtn.AutoButtonColor = false
    toggleBtn.ClipsDescendants = true
    toggleBtn.Parent = footer
    Utils.CreateCorner(toggleBtn, 10)

    toggleBtn.MouseButton1Click:Connect(function()
        Utils.AnimateClick(toggleBtn)
        Utils.Ripple(toggleBtn, State.Mouse.X, State.Mouse.Y)

        State.IsActive = not State.IsActive
        if State.IsActive then
            toggleBtn.Text = "⏸️  DEACTIVATE"
            Utils.Tween(toggleBtn, {BackgroundColor3 = C.Warning}, 0.2)
            Notify.Send("▶️ Activated", C.Success)
        else
            toggleBtn.Text = "▶️  ACTIVATE"
            Utils.Tween(toggleBtn, {BackgroundColor3 = C.Success}, 0.2)
            State.LoopActive = false
            Notify.Send("⏸️ Paused", C.Warning)
        end
    end)

    -- Sub buttons
    local subRow = Instance.new("Frame")
    subRow.Size = UDim2.new(1, 0, 0, 38)
    subRow.Position = UDim2.new(0, 0, 0, 50)
    subRow.BackgroundTransparency = 1
    subRow.Parent = footer
    Utils.CreateListLayout(subRow, Enum.FillDirection.Horizontal, 6)

    local function createFooterBtn(text, color, size, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(size, -4, 1, 0)
        btn.BackgroundColor3 = color
        btn.Text = text
        btn.TextColor3 = C.TextPrimary
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.AutoButtonColor = false
        btn.ClipsDescendants = true
        btn.Parent = subRow
        Utils.CreateCorner(btn, 8)
        Utils.AddHover(btn, 0.15, 0)
        btn.MouseButton1Click:Connect(function()
            Utils.AnimateClick(btn)
            callback(btn)
        end)
        return btn
    end

    createFooterBtn("🔄 Loop", C.AccentDark, 0.32, function()
        Config.LoopMode = not Config.LoopMode
        State.LoopActive = false
        State.UIElements.Mode.Text = Config.LoopMode and "Loop" or "Single"
        Notify.Send("Mode: " .. (Config.LoopMode and "Loop" or "Single Pull"), C.Info)
    end)

    createFooterBtn("🔓 Release", Color3.fromRGB(160, 110, 30), 0.34, function()
        local count = #State.PartsToTeleport
        Engine.ReleaseAll()
        Notify.Send("Released " .. count .. " parts", C.Warning)
    end)

    createFooterBtn("✕ Close", C.Danger, 0.34, function()
        State.IsRunning = false
        State.IsActive = false
        Engine.ReleaseAll()
        if State.SelectionBox then State.SelectionBox:Destroy() end

        Utils.Tween(mainFrame, {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 440, 0, 0)
        }, 0.3)
        task.delay(0.35, function()
            screenGui:Destroy()
        end)
    end)

    return screenGui
end

return UI
