--[[
    ╔══════════════════════════════════════╗
    ║  MODULE: state.lua                   ║
    ║  Общее состояние приложения          ║
    ║                                      ║
    ║  Зависимости: config                 ║
    ║                                      ║
    ║  RAW ссылка → loader.lua →           ║
    ║  loadModule("state")                 ║
    ║                                      ║
    ║  ВСЕ модули читают/пишут State       ║
    ║  через getgenv().TCP.Modules.State   ║
    ╚══════════════════════════════════════╝
]]

local Players = game:GetService("Players")

local State = {}

-- Игрок
State.Player = Players.LocalPlayer
State.Character = State.Player.Character or State.Player.CharacterAdded:Wait()
State.HumanoidRootPart = State.Character:WaitForChild("HumanoidRootPart")
State.Humanoid = State.Character:WaitForChild("Humanoid")
State.Mouse = State.Player:GetMouse()

-- Флаги
State.IsRunning = true           -- Скрипт работает
State.IsActive = true            -- Телепортация активна
State.LoopActive = false         -- Петля запущена
State.IsSelectingTarget = false  -- Режим выбора цели кликом
State.UIVisible = true           -- UI видимый

-- Данные
State.PartsToTeleport = {}       -- Активные парты
State.CustomTargetPart = nil     -- Выбранная кастомная цель
State.SelectionBox = nil         -- SelectionBox инстанс

-- Подключения (для очистки)
State.Connections = {}

-- UI элементы (ссылки для обновления)
State.UIElements = {}

-- GUI ScreenGui
State.GUI = nil

-- Статистика
State.Stats = {
    CollectedParts = 0,
    StartTime = tick(),
}

-- Метод обновления персонажа
function State.RefreshCharacter(character)
    State.Character = character
    State.HumanoidRootPart = character:WaitForChild("HumanoidRootPart")
    State.Humanoid = character:WaitForChild("Humanoid")
end

-- Метод безопасного отключения connection
function State.SafeDisconnect(name)
    if State.Connections[name] then
        State.Connections[name]:Disconnect()
        State.Connections[name] = nil
    end
end

return State
