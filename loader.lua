local BASE_URL = "https://raw.githubusercontent.com/ТВОЙ_ЮЗЕРНЕЙМ/ТВОЙ_РЕПО/main/modules/"

-- Ждём загрузку игры
if not game:IsLoaded() then
    game.Loaded:Wait()
end
task.wait(1)

-- ============================================
-- ФУНКЦИЯ ЗАГРУЗКИ МОДУЛЯ
-- ============================================
local function loadModule(name)
    local url = BASE_URL .. name .. ".lua"
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    
    if success then
        print("✅ [TCP] Loaded: " .. name)
        return result
    else
        warn("❌ [TCP] Failed to load: " .. name)
        warn("   URL: " .. url)
        warn("   Error: " .. tostring(result))
        return nil
    end
end

getgenv().TCP = {
    Version = "2.0",
    Modules = {},
}

print("═══════════════════════════════════════")
print("  Teleport Control Panel v2.0")
print("  Loading modules...")
print("═══════════════════════════════════════")

-- Шаг 1: Конфигурация (настройки + цвета)
TCP.Modules.Config    = loadModule("config")

-- Шаг 2: Shared State (общее состояние)
TCP.Modules.State     = loadModule("state")

-- Шаг 3: Утилиты (tween, анимации, helpers)
TCP.Modules.Utils     = loadModule("utils")

-- Шаг 4: Уведомления (toast notifications)
TCP.Modules.Notify    = loadModule("notify")

-- Шаг 5: UI Компоненты (toggle, input, button)
TCP.Modules.Components = loadModule("components")

-- Шаг 6: Движок телепортации (сбор и перемещение партов)
TCP.Modules.Engine    = loadModule("engine")

-- Шаг 7: Главный UI (окно, вкладки, страницы)
TCP.Modules.UI        = loadModule("ui")

-- Шаг 8: Обновление статистики (ping, счётчики)
TCP.Modules.Status    = loadModule("status")

-- Шаг 9: Цикл телепортации (Heartbeat)
TCP.Modules.Teleport  = loadModule("teleport")

-- Шаг 10: Обработка ввода (клавиши, мышь)
TCP.Modules.Input     = loadModule("input")

-- Шаг 11: Защита респауна
TCP.Modules.Respawn   = loadModule("respawn")

-- Шаг 12: Инициализация и запуск
TCP.Modules.Init      = loadModule("init")

print("═══════════════════════════════════════")
print("  ✅ All modules loaded!")
print("═══════════════════════════════════════")
