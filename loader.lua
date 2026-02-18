--[[
    ╔══════════════════════════════════════════════════╗
    ║        TELEPORT CONTROL PANEL v2.0               ║
    ║        LOADER WITH LOADING SCREEN                ║
    ║        FINAL FIXED VERSION                       ║
    ╚══════════════════════════════════════════════════╝
]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end
task.wait(1)

-- ============================================
-- ЗАЩИТА ОТ ПОВТОРНОГО ЗАПУСКА
-- ============================================
--[[
    Логика:
    1. Если СЕЙЧАС идёт загрузка → заблокировать
    2. Если скрипт УЖЕ работает (GUI существует) → заблокировать
    3. Если был закрыт кнопкой Close → РАЗРЕШИТЬ перезапуск
]]

-- Блок: уже грузится прямо сейчас
if shared._TCP_LOADING == true then
    warn("⚠️ TCP is already loading! Please wait.")
    return
end

-- Блок: уже запущен и GUI существует
if shared.TCP and shared.TCP.Loaded == true then
    -- Проверяем РЕАЛЬНО ли GUI ещё жив
    local CoreGui = game:GetService("CoreGui")
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    
    local guiAlive = false
    
    -- Проверка в CoreGui
    if CoreGui:FindFirstChild("TCP_VapeStyle") then
        guiAlive = true
    end
    -- Проверка в PlayerGui
    if player and player:FindFirstChild("PlayerGui") then
        if player.PlayerGui:FindFirstChild("TCP_VapeStyle") then
            guiAlive = true
        end
    end
    
    if guiAlive then
        warn("⚠️ TCP is already running! Close it first (✕ button) to restart.")
        return
    else
        -- GUI мёртв → был закрыт → разрешаем перезапуск
        shared.TCP = nil
    end
end

-- Ставим флаг загрузки
shared._TCP_LOADING = true

-- ============================================
-- СЕРВИСЫ
-- ============================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- ============================================
-- КОНФИГ ЛОАДЕРА
-- ============================================
local REPO = "Flamedragonz/RobloxUniversal"
local MAX_RETRIES = 3
local DELAY_BETWEEN = 1.5
local RETRY_DELAY = 2

local ACCENT = Color3.fromRGB(90, 80, 220)
local ACCENT_GLOW = Color3.fromRGB(130, 120, 255)
local BG_DARK = Color3.fromRGB(12, 12, 16)
local BG_SURFACE = Color3.fromRGB(22, 22, 28)
local TEXT_PRIMARY = Color3.fromRGB(240, 240, 245)
local TEXT_SECONDARY = Color3.fromRGB(120, 120, 140)
local SUCCESS = Color3.fromRGB(80, 200, 120)
local DANGER = Color3.fromRGB(220, 70, 70)
local WARNING = Color3.fromRGB(240, 180, 60)

-- ============================================
-- ФУНКЦИЯ ПОЛНОЙ ОЧИСТКИ
-- ============================================
local function fullCleanup()
    shared._TCP_LOADING = nil
    
    if shared.TCP then
        -- Отключить все connections
        if shared.TCP.Modules and shared.TCP.Modules.State then
            local State = shared.TCP.Modules.State
            if State.Connections then
                for name, conn in pairs(State.Connections) do
                    pcall(function() conn:Disconnect() end)
                end
            end
            -- Убрать SelectionBox
            if State.SelectionBox then
                pcall(function() State.SelectionBox:Destroy() end)
            end
        end
        shared.TCP = nil
    end
    
    -- Убрать GUI
    pcall(function()
        local g = CoreGui:FindFirstChild("TCP_VapeStyle")
        if g then g:Destroy() end
    end)
    pcall(function()
        local g = CoreGui:FindFirstChild("TCP_LoadingScreen")
        if g then g:Destroy() end
    end)
    pcall(function()
        if player:FindFirstChild("PlayerGui") then
            local g = player.PlayerGui:FindFirstChild("TCP_VapeStyle")
            if g then g:Destroy() end
            local g2 = player.PlayerGui:FindFirstChild("TCP_LoadingScreen")
            if g2 then g2:Destroy() end
        end
    end)
end

-- ============================================
-- LOADING SCREEN UI
-- ============================================
local LoadingScreen = {}

function LoadingScreen.Create()
    -- Удалить старый если есть
    pcall(function()
        local old = CoreGui:FindFirstChild("TCP_LoadingScreen")
        if old then old:Destroy() end
    end)
    pcall(function()
        if player:FindFirstChild("PlayerGui") then
            local old = player.PlayerGui:FindFirstChild("TCP_LoadingScreen")
            if old then old:Destroy() end
        end
    end)

    local gui = Instance.new("ScreenGui")
    gui.Name = "TCP_LoadingScreen"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 9999
    
    -- ╔══════════════════════════════════════╗
    -- ║  FIX #1: IgnoreGuiInset = true       ║
    -- ║  Без этого overlay сдвигается вниз   ║
    -- ║  на 36px (высота TopBar) и сверху    ║
    -- ║  остаётся незакрытая полоска          ║
    -- ╚══════════════════════════════════════╝
    gui.IgnoreGuiInset = true
    
    local ok = pcall(function() gui.Parent = CoreGui end)
    if not ok then gui.Parent = player.PlayerGui end

    -- ===== ПОЛНОЭКРАННЫЙ ФОН =====
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.AnchorPoint = Vector2.new(0, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.4
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 1
    overlay.Parent = gui

    -- ===== ЦЕНТРАЛЬНАЯ КАРТОЧКА =====
    local card = Instance.new("Frame")
    card.Name = "Card"
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Size = UDim2.new(0, 380, 0, 320)
    card.Position = UDim2.new(0.5, 0, 0.5, 0)
    card.BackgroundColor3 = BG_DARK
    card.BorderSizePixel = 0
    card.ZIndex = 10
    card.Parent = gui

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 16)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = ACCENT
    cardStroke.Thickness = 1.5
    cardStroke.Transparency = 0.5
    cardStroke.Parent = card

    -- Тень
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0.5, 0, 0.5, 6)
    shadow.Size = UDim2.new(1, 50, 1, 50)
    shadow.ZIndex = 9
    shadow.Image = "rbxassetid://6015897843"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.3
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.Parent = card

    -- ===== ЛОГОТИП =====
    local logoContainer = Instance.new("Frame")
    logoContainer.AnchorPoint = Vector2.new(0.5, 0)
    logoContainer.Size = UDim2.new(0, 60, 0, 60)
    logoContainer.Position = UDim2.new(0.5, 0, 0, 30)
    logoContainer.BackgroundColor3 = ACCENT
    logoContainer.ZIndex = 11
    logoContainer.Parent = card

    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(0, 14)
    logoCorner.Parent = logoContainer

    local logoGradient = Instance.new("UIGradient")
    logoGradient.Color = ColorSequence.new(ACCENT, ACCENT_GLOW)
    logoGradient.Rotation = 45
    logoGradient.Parent = logoContainer

    local logoText = Instance.new("TextLabel")
    logoText.Size = UDim2.new(1, 0, 1, 0)
    logoText.BackgroundTransparency = 1
    logoText.Text = "T"
    logoText.TextColor3 = Color3.new(1, 1, 1)
    logoText.Font = Enum.Font.GothamBlack
    logoText.TextSize = 30
    logoText.ZIndex = 12
    logoText.Parent = logoContainer

    -- Пульсирующая обводка лого
    local glowRing = Instance.new("UIStroke")
    glowRing.Color = ACCENT_GLOW
    glowRing.Thickness = 2
    glowRing.Transparency = 0
    glowRing.Parent = logoContainer

    -- ===== ЗАГОЛОВОК =====
    local titleLabel = Instance.new("TextLabel")
    titleLabel.AnchorPoint = Vector2.new(0.5, 0)
    titleLabel.Size = UDim2.new(1, 0, 0, 24)
    titleLabel.Position = UDim2.new(0.5, 0, 0, 100)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Teleport Control Panel"
    titleLabel.TextColor3 = TEXT_PRIMARY
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextSize = 20
    titleLabel.ZIndex = 11
    titleLabel.Parent = card

    local versionLabel = Instance.new("TextLabel")
    versionLabel.AnchorPoint = Vector2.new(0.5, 0)
    versionLabel.Size = UDim2.new(1, 0, 0, 16)
    versionLabel.Position = UDim2.new(0.5, 0, 0, 126)
    versionLabel.BackgroundTransparency = 1
    versionLabel.Text = "v2.0 — Vape Style Edition"
    versionLabel.TextColor3 = TEXT_SECONDARY
    versionLabel.Font = Enum.Font.GothamMedium
    versionLabel.TextSize = 12
    versionLabel.ZIndex = 11
    versionLabel.Parent = card

    -- ===== PROGRESS BAR =====
    local progressBg = Instance.new("Frame")
    progressBg.AnchorPoint = Vector2.new(0.5, 0)
    progressBg.Size = UDim2.new(0.8, 0, 0, 8)
    progressBg.Position = UDim2.new(0.5, 0, 0, 165)
    progressBg.BackgroundColor3 = BG_SURFACE
    progressBg.BorderSizePixel = 0
    progressBg.ZIndex = 11
    progressBg.Parent = card

    local progressBgCorner = Instance.new("UICorner")
    progressBgCorner.CornerRadius = UDim.new(0, 4)
    progressBgCorner.Parent = progressBg

    local progressFill = Instance.new("Frame")
    progressFill.Name = "Fill"
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = ACCENT
    progressFill.BorderSizePixel = 0
    progressFill.ZIndex = 12
    progressFill.Parent = progressBg

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = progressFill

    local fillGradient = Instance.new("UIGradient")
    fillGradient.Color = ColorSequence.new(ACCENT, ACCENT_GLOW)
    fillGradient.Rotation = 0
    fillGradient.Parent = progressFill

    -- ===== ПРОЦЕНТ =====
    local percentLabel = Instance.new("TextLabel")
    percentLabel.AnchorPoint = Vector2.new(0.5, 0)
    percentLabel.Size = UDim2.new(1, 0, 0, 20)
    percentLabel.Position = UDim2.new(0.5, 0, 0, 178)
    percentLabel.BackgroundTransparency = 1
    percentLabel.Text = "0%"
    percentLabel.TextColor3 = ACCENT_GLOW
    percentLabel.Font = Enum.Font.GothamBold
    percentLabel.TextSize = 14
    percentLabel.ZIndex = 11
    percentLabel.Parent = card

    -- ===== СТАТУС =====
    local statusLabel = Instance.new("TextLabel")
    statusLabel.AnchorPoint = Vector2.new(0.5, 0)
    statusLabel.Size = UDim2.new(0.9, 0, 0, 18)
    statusLabel.Position = UDim2.new(0.5, 0, 0, 205)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Initializing..."
    statusLabel.TextColor3 = TEXT_SECONDARY
    statusLabel.Font = Enum.Font.GothamMedium
    statusLabel.TextSize = 13
    statusLabel.ZIndex = 11
    statusLabel.Parent = card

    -- ===== ЛОГ =====
    local logFrame = Instance.new("Frame")
    logFrame.AnchorPoint = Vector2.new(0.5, 0)
    logFrame.Size = UDim2.new(0.85, 0, 0, 70)
    logFrame.Position = UDim2.new(0.5, 0, 0, 232)
    logFrame.BackgroundColor3 = BG_SURFACE
    logFrame.BorderSizePixel = 0
    logFrame.ClipsDescendants = true
    logFrame.ZIndex = 11
    logFrame.Parent = card

    local logCorner = Instance.new("UICorner")
    logCorner.CornerRadius = UDim.new(0, 8)
    logCorner.Parent = logFrame

    local logLayout = Instance.new("UIListLayout")
    logLayout.SortOrder = Enum.SortOrder.LayoutOrder
    logLayout.Padding = UDim.new(0, 2)
    logLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    logLayout.Parent = logFrame

    local logPadding = Instance.new("UIPadding")
    logPadding.PaddingLeft = UDim.new(0, 8)
    logPadding.PaddingRight = UDim.new(0, 8)
    logPadding.PaddingBottom = UDim.new(0, 4)
    logPadding.Parent = logFrame

    -- ===== АНИМАЦИИ =====

    -- Появление
    card.BackgroundTransparency = 1
    card.Size = UDim2.new(0, 380, 0, 0)
    overlay.BackgroundTransparency = 1

    TweenService:Create(overlay, TweenInfo.new(0.5), {
        BackgroundTransparency = 0.4
    }):Play()

    TweenService:Create(card, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
        BackgroundTransparency = 0,
        Size = UDim2.new(0, 380, 0, 320)
    }):Play()

    -- Пульсация лого
    LoadingScreen._pulseAlive = true
    task.spawn(function()
        while LoadingScreen._pulseAlive do
            TweenService:Create(glowRing, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Transparency = 0.7
            }):Play()
            task.wait(1)
            if not LoadingScreen._pulseAlive then break end
            TweenService:Create(glowRing, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Transparency = 0
            }):Play()
            task.wait(1)
        end
    end)

    -- Градиент бежит по прогресс-бару
    LoadingScreen._gradientAlive = true
    task.spawn(function()
        while LoadingScreen._gradientAlive do
            fillGradient.Offset = Vector2.new(-1, 0)
            TweenService:Create(fillGradient, TweenInfo.new(2, Enum.EasingStyle.Linear), {
                Offset = Vector2.new(1, 0)
            }):Play()
            task.wait(2)
        end
    end)

    -- ===== ХРАНИЛИЩЕ =====
    LoadingScreen.GUI = gui
    LoadingScreen.Card = card
    LoadingScreen.Overlay = overlay
    LoadingScreen.ProgressFill = progressFill
    LoadingScreen.PercentLabel = percentLabel
    LoadingScreen.StatusLabel = statusLabel
    LoadingScreen.LogFrame = logFrame
    LoadingScreen.LogoContainer = logoContainer
    LoadingScreen.GlowRing = glowRing
    LoadingScreen.CardStroke = cardStroke
    LoadingScreen.LogCount = 0

    return gui
end

function LoadingScreen.SetProgress(current, total)
    if not LoadingScreen.ProgressFill then return end
    local fraction = current / total
    local percent = math.floor(fraction * 100)

    TweenService:Create(LoadingScreen.ProgressFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Size = UDim2.new(fraction, 0, 1, 0)
    }):Play()

    LoadingScreen.PercentLabel.Text = percent .. "%"
end

function LoadingScreen.SetStatus(text)
    if not LoadingScreen.StatusLabel then return end
    LoadingScreen.StatusLabel.Text = text
end

function LoadingScreen.AddLog(icon, text, color)
    if not LoadingScreen.LogFrame then return end
    LoadingScreen.LogCount = LoadingScreen.LogCount + 1

    -- Удалить старые
    local children = {}
    for _, child in pairs(LoadingScreen.LogFrame:GetChildren()) do
        if child:IsA("TextLabel") then
            table.insert(children, child)
        end
    end
    while #children > 4 do
        children[1]:Destroy()
        table.remove(children, 1)
    end

    local logEntry = Instance.new("TextLabel")
    logEntry.Size = UDim2.new(1, 0, 0, 14)
    logEntry.BackgroundTransparency = 1
    logEntry.Text = icon .. " " .. text
    logEntry.TextColor3 = color or TEXT_SECONDARY
    logEntry.Font = Enum.Font.Code
    logEntry.TextSize = 11
    logEntry.TextXAlignment = Enum.TextXAlignment.Left
    logEntry.TextTruncate = Enum.TextTruncate.AtEnd
    logEntry.LayoutOrder = LoadingScreen.LogCount
    logEntry.ZIndex = 12
    logEntry.Parent = LoadingScreen.LogFrame

    -- Fade in
    logEntry.TextTransparency = 1
    TweenService:Create(logEntry, TweenInfo.new(0.2), {
        TextTransparency = 0
    }):Play()
end

function LoadingScreen.SetRetrying(moduleName, attempt, maxAttempts)
    if not LoadingScreen.StatusLabel then return end
    LoadingScreen.StatusLabel.Text = "⏳ Retrying " .. moduleName .. " (" .. attempt .. "/" .. maxAttempts .. ")"
    LoadingScreen.StatusLabel.TextColor3 = WARNING
    LoadingScreen.AddLog("🔄", moduleName .. " retry " .. attempt .. "/" .. maxAttempts, WARNING)

    -- Мигание
    if LoadingScreen.ProgressFill then
        TweenService:Create(LoadingScreen.ProgressFill, TweenInfo.new(0.2), {
            BackgroundColor3 = WARNING
        }):Play()
        task.delay(0.3, function()
            if LoadingScreen.ProgressFill and LoadingScreen.ProgressFill.Parent then
                TweenService:Create(LoadingScreen.ProgressFill, TweenInfo.new(0.2), {
                    BackgroundColor3 = ACCENT
                }):Play()
            end
        end)
    end
end

function LoadingScreen.StopAnimations()
    LoadingScreen._pulseAlive = false
    LoadingScreen._gradientAlive = false
end

function LoadingScreen.Dismiss()
    LoadingScreen.StopAnimations()
    
    if not LoadingScreen.GUI or not LoadingScreen.GUI.Parent then return end

    TweenService:Create(LoadingScreen.Card, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 380, 0, 0),
        BackgroundTransparency = 1
    }):Play()
    TweenService:Create(LoadingScreen.Overlay, TweenInfo.new(0.5), {
        BackgroundTransparency = 1
    }):Play()
    task.delay(0.6, function()
        if LoadingScreen.GUI and LoadingScreen.GUI.Parent then
            LoadingScreen.GUI:Destroy()
            LoadingScreen.GUI = nil
        end
    end)
end

function LoadingScreen.ShowSuccess()
    if not LoadingScreen.Card then return end

    -- Зелёная обводка
    if LoadingScreen.CardStroke then
        TweenService:Create(LoadingScreen.CardStroke, TweenInfo.new(0.3), {
            Color = SUCCESS, Transparency = 0
        }):Play()
    end

    -- Прогресс бар зелёный
    if LoadingScreen.ProgressFill then
        TweenService:Create(LoadingScreen.ProgressFill, TweenInfo.new(0.3), {
            BackgroundColor3 = SUCCESS,
            Size = UDim2.new(1, 0, 1, 0)
        }):Play()
    end

    if LoadingScreen.PercentLabel then
        LoadingScreen.PercentLabel.Text = "100%"
        LoadingScreen.PercentLabel.TextColor3 = SUCCESS
    end
    if LoadingScreen.StatusLabel then
        LoadingScreen.StatusLabel.Text = "✅ Ready! Launching..."
        LoadingScreen.StatusLabel.TextColor3 = SUCCESS
    end

    -- Лого зелёный
    if LoadingScreen.LogoContainer then
        TweenService:Create(LoadingScreen.LogoContainer, TweenInfo.new(0.3), {
            BackgroundColor3 = SUCCESS
        }):Play()
    end
    if LoadingScreen.GlowRing then
        TweenService:Create(LoadingScreen.GlowRing, TweenInfo.new(0.3), {
            Color = SUCCESS
        }):Play()
    end

    LoadingScreen.AddLog("✅", "All modules loaded!", SUCCESS)

    -- Исчезновение через 2 секунды
    task.delay(2, function()
        LoadingScreen.Dismiss()
    end)
end

function LoadingScreen.ShowError(moduleName, errorMsg)
    if not LoadingScreen.Card then return end

    -- Красная обводка
    if LoadingScreen.CardStroke then
        TweenService:Create(LoadingScreen.CardStroke, TweenInfo.new(0.3), {
            Color = DANGER, Transparency = 0
        }):Play()
    end

    -- Прогресс бар красный
    if LoadingScreen.ProgressFill then
        TweenService:Create(LoadingScreen.ProgressFill, TweenInfo.new(0.3), {
            BackgroundColor3 = DANGER
        }):Play()
    end

    if LoadingScreen.PercentLabel then
        LoadingScreen.PercentLabel.TextColor3 = DANGER
    end
    if LoadingScreen.StatusLabel then
        LoadingScreen.StatusLabel.Text = "❌ Failed: " .. moduleName
        LoadingScreen.StatusLabel.TextColor3 = DANGER
    end

    -- Лого красный
    if LoadingScreen.LogoContainer then
        TweenService:Create(LoadingScreen.LogoContainer, TweenInfo.new(0.3), {
            BackgroundColor3 = DANGER
        }):Play()
    end
    if LoadingScreen.GlowRing then
        TweenService:Create(LoadingScreen.GlowRing, TweenInfo.new(0.3), {
            Color = DANGER
        }):Play()
    end

    LoadingScreen.AddLog("❌", moduleName .. ": " .. (errorMsg or "unknown"), DANGER)

    -- ===== КНОПКА RETRY =====
    local retryBtn = Instance.new("TextButton")
    retryBtn.AnchorPoint = Vector2.new(0.5, 1)
    retryBtn.Size = UDim2.new(0.4, 0, 0, 32)
    retryBtn.Position = UDim2.new(0.3, 0, 1, -12)
    retryBtn.BackgroundColor3 = ACCENT
    retryBtn.Text = "🔄 Retry"
    retryBtn.TextColor3 = Color3.new(1, 1, 1)
    retryBtn.Font = Enum.Font.GothamBold
    retryBtn.TextSize = 14
    retryBtn.AutoButtonColor = true
    retryBtn.ZIndex = 13
    retryBtn.Parent = LoadingScreen.Card

    local retryCorner = Instance.new("UICorner")
    retryCorner.CornerRadius = UDim.new(0, 8)
    retryCorner.Parent = retryBtn

    retryBtn.MouseButton1Click:Connect(function()
        LoadingScreen.StopAnimations()
        if LoadingScreen.GUI then
            LoadingScreen.GUI:Destroy()
            LoadingScreen.GUI = nil
        end
        -- Очистить для перезапуска
        shared._TCP_LOADING = nil
        shared.TCP = nil
        task.wait(0.5)
        -- Перезапуск
        pcall(function()
            loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/" .. REPO .. "/main/loader.lua"
            ))()
        end)
    end)

    -- ===== КНОПКА CANCEL =====
    local cancelBtn = Instance.new("TextButton")
    cancelBtn.AnchorPoint = Vector2.new(0.5, 1)
    cancelBtn.Size = UDim2.new(0.4, 0, 0, 32)
    cancelBtn.Position = UDim2.new(0.7, 0, 1, -12)
    cancelBtn.BackgroundColor3 = DANGER
    cancelBtn.BackgroundTransparency = 0.3
    cancelBtn.Text = "✕ Cancel"
    cancelBtn.TextColor3 = Color3.new(1, 1, 1)
    cancelBtn.Font = Enum.Font.GothamBold
    cancelBtn.TextSize = 14
    cancelBtn.AutoButtonColor = true
    cancelBtn.ZIndex = 13
    cancelBtn.Parent = LoadingScreen.Card

    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0, 8)
    cancelCorner.Parent = cancelBtn

    cancelBtn.MouseButton1Click:Connect(function()
        -- ╔══════════════════════════════════════╗
        -- ║  FIX #2: Очищаем ВСЕ флаги           ║
        -- ║  чтобы можно было перезапустить       ║
        -- ╚══════════════════════════════════════╝
        fullCleanup()
        LoadingScreen.StopAnimations()
        LoadingScreen.Dismiss()
    end)
end

-- ============================================
-- СОЗДАЁМ LOADING SCREEN
-- ============================================
LoadingScreen.Create()
task.wait(0.6) -- Дождаться анимации появления

-- ============================================
-- ОПРЕДЕЛЕНИЕ URL
-- ============================================
LoadingScreen.SetStatus("🔍 Detecting server...")
LoadingScreen.AddLog("🔍", "Searching for repository...", TEXT_SECONDARY)

local URL_FORMATS = {
    "https://raw.githubusercontent.com/" .. REPO .. "/main/modules/",
    "https://raw.githubusercontent.com/" .. REPO .. "/refs/heads/main/modules/",
}

local BASE_URL = nil

for _, url in pairs(URL_FORMATS) do
    local ok, result = pcall(function()
        return game:HttpGet(url .. "config.lua")
    end)
    if ok and result and #result > 50 
       and not result:find("404") 
       and not result:find("Not Found") then
        BASE_URL = url
        LoadingScreen.AddLog("✅", "Server connected", SUCCESS)
        break
    end
    task.wait(1)
end

if not BASE_URL then
    LoadingScreen.ShowError("Connection", "Cannot reach GitHub. Check internet.")
    shared._TCP_LOADING = nil
    return
end

-- ============================================
-- NAMESPACE
-- ============================================
shared.TCP = {
    Version = "2.0",
    Modules = {},
    BaseURL = BASE_URL,
    Loaded = false,
}

-- ============================================
-- ЗАГРУЗЧИК
-- ============================================
local function loadModule(name, index, total)
    local url = BASE_URL .. name .. ".lua"

    for attempt = 1, MAX_RETRIES do
        local httpOk, source = pcall(function()
            return game:HttpGet(url)
        end)

        if not httpOk or not source or #source < 10 then
            if attempt < MAX_RETRIES then
                LoadingScreen.SetRetrying(name, attempt, MAX_RETRIES)
                task.wait(RETRY_DELAY)
            else
                return nil, "HTTP failed after " .. MAX_RETRIES .. " tries"
            end
        else
            if source:find("404") or source:find("Not Found") then
                return nil, "File not found in repository (404)"
            end

            local compiled, compErr = loadstring(source, name)
            if not compiled then
                return nil, "Syntax error: " .. tostring(compErr)
            end

            local execOk, result = pcall(compiled)
            if not execOk then
                return nil, "Runtime error: " .. tostring(result)
            end

            if result == nil then
                return nil, "Module returned nil (missing 'return' statement)"
            end

            LoadingScreen.AddLog("✅", name .. " (" .. #source .. " bytes)", SUCCESS)
            LoadingScreen.SetProgress(index, total)
            return result, nil
        end
    end
    return nil, "Unknown error"
end

-- ============================================
-- ЗАГРУЗКА МОДУЛЕЙ
-- ============================================
local modules = {
    {"config",     "Config"},
    {"state",      "State"},
    {"utils",      "Utils"},
    {"notify",     "Notify"},
    {"components", "Components"},
    {"engine",     "Engine"},
    {"ui",         "UI"},
    {"status",     "Status"},
    {"teleport",   "Teleport"},
    {"input",      "Input"},
    {"respawn",    "Respawn"},
    {"init",       "Init"},
}

local total = #modules
local allOk = true

LoadingScreen.SetStatus("📦 Loading modules...")
task.wait(0.3)

for i, mod in ipairs(modules) do
    local fileName, key = mod[1], mod[2]

    LoadingScreen.SetStatus("📦 " .. fileName .. " (" .. i .. "/" .. total .. ")")

    local result, err = loadModule(fileName, i, total)

    if result ~= nil then
        shared.TCP.Modules[key] = result
        print("✅ [TCP] " .. fileName)
    else
        warn("❌ [TCP] " .. fileName .. ": " .. tostring(err))
        LoadingScreen.ShowError(fileName, err)
        allOk = false
        -- НЕ очищаем shared._TCP_LOADING здесь!
        -- ShowError покажет кнопки Retry/Cancel которые сами очистят
        return
    end

    if i < total then
        task.wait(DELAY_BETWEEN)
    end
end

-- ============================================
-- УСПЕХ
-- ============================================
if allOk then
    shared.TCP.Loaded = true
    shared._TCP_LOADING = nil
    LoadingScreen.ShowSuccess()
    print("═══════════════════════════════════════")
    print("  ✅ TCP v2.0 — All modules loaded!")
    print("═══════════════════════════════════════")
end
