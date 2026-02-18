--[[
    ╔══════════════════════════════════════╗
    ║  MODULE: notify.lua                  ║
    ║  Toast-уведомления (Vape style)      ║
    ║                                      ║
    ║  Зависимости: utils, config          ║
    ║                                      ║
    ║  RAW ссылка → loader.lua →           ║
    ║  loadModule("notify")                ║
    ║                                      ║
    ║  Использование:                      ║
    ║  TCP.Modules.Notify.Send("text",     ║
    ║      color, duration)                ║
    ╚══════════════════════════════════════╝
]]

local TCP = getgenv().TCP
local Config = TCP.Modules.Config
local Utils = TCP.Modules.Utils

local Notify = {}
Notify.Container = nil

function Notify.Init(parentGui)
    if Notify.Container then
        Notify.Container:Destroy()
    end

    Notify.Container = Instance.new("Frame")
    Notify.Container.Name = "TCP_Notifications"
    Notify.Container.Size = UDim2.new(0, 280, 1, -20)
    Notify.Container.Position = UDim2.new(1, -290, 0, 10)
    Notify.Container.BackgroundTransparency = 1
    Notify.Container.Parent = parentGui

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.Parent = Notify.Container
end

function Notify.Send(text, color, duration)
    if not Notify.Container then return end

    color = color or Config.Colors.Info
    duration = duration or 3

    -- Контейнер уведомления
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 38)
    frame.BackgroundColor3 = Config.Colors.Surface
    frame.BackgroundTransparency = 1
    frame.ClipsDescendants = true
    frame.Parent = Notify.Container
    Utils.CreateCorner(frame, 8)
    Utils.CreateStroke(frame, color, 1, 0.6)

    -- Цветная полоска слева
    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 1, -6)
    accent.Position = UDim2.new(0, 3, 0, 3)
    accent.BackgroundColor3 = color
    accent.BorderSizePixel = 0
    accent.Parent = frame
    Utils.CreateCorner(accent, 2)

    -- Текст
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -18, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Config.Colors.TextPrimary
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = frame

    -- Progress bar (снизу, показывает оставшееся время)
    local progress = Instance.new("Frame")
    progress.Size = UDim2.new(1, 0, 0, 2)
    progress.Position = UDim2.new(0, 0, 1, -2)
    progress.BackgroundColor3 = color
    progress.BorderSizePixel = 0
    progress.Parent = frame

    -- Анимация появления
    Utils.Tween(frame, {BackgroundTransparency = 0.05}, 0.3)

    -- Анимация прогресс-бара
    Utils.Tween(progress, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)

    -- Исчезновение
    task.delay(duration, function()
        Utils.Tween(frame, {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0)
        }, 0.3)
        task.delay(0.35, function()
            frame:Destroy()
        end)
    end)
end

return Notify
