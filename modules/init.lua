--[[
    ╔══════════════════════════════════════╗
    ║  MODULE: init.lua                    ║
    ║  Инициализация — запускает ВСЁ       ║
    ║                                      ║
    ║  Зависимости: ВСЕ модули             ║
    ║                                      ║
    ║  RAW ссылка → loader.lua →           ║
    ║  loadModule("init")                  ║
    ║                                      ║
    ║  Это ПОСЛЕДНИЙ загружаемый модуль.   ║
    ║  Он вызывает .Start() / .Setup()     ║
    ║  у всех остальных модулей.           ║
    ╚══════════════════════════════════════╝
]]

local TCP = shared.TCP
local Config   = TCP.Modules.Config
local State    = TCP.Modules.State
local Notify   = TCP.Modules.Notify
local Engine   = TCP.Modules.Engine
local UI       = TCP.Modules.UI
local Status   = TCP.Modules.Status
local Teleport = TCP.Modules.Teleport
local Input    = TCP.Modules.Input
local Respawn  = TCP.Modules.Respawn

local C = Config.Colors

-- ============================================
-- ПОРЯДОК ЗАПУСКА
-- ============================================

-- 1. Построить UI
UI.Create()

-- 2. Настроить обработку ввода
Input.Setup()

-- 3. Настроить защиту респауна
Respawn.Setup()

-- 4. Первоначальный сбор партов
Engine.CollectParts()

-- 5. Запустить Heartbeat (телепортация каждый кадр)
Teleport.StartHeartbeat()

-- 6. Запустить цикл сбора
Teleport.StartCollectionLoop()

-- 7. Запустить обновление статистики
Status.Start()

-- 8. Приветственные уведомления
task.delay(0.5, function()
    Notify.Send("Teleport Control v2.0 loaded", C.Accent, 4)
    task.wait(0.3)
    Notify.Send("K: Loop | P: Hide | L: Release | J: Toggle", C.TextSecondary, 5)
end)

print("✅ [TCP] Initialization complete!")

return true
