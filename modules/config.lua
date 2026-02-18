--[[
    ╔══════════════════════════════════════╗
    ║  MODULE: config.lua                  ║
    ║  Настройки и цветовая палитра        ║
    ║                                      ║
    ║  Зависимости: НЕТ (загружается 1-м)  ║
    ║                                      ║
    ║  RAW ссылка этого файла вставляется  ║
    ║  в loader.lua → loadModule("config") ║
    ╚══════════════════════════════════════╝
]]

local Config = {}

-- ========== ФУНКЦИОНАЛЬНЫЕ НАСТРОЙКИ ==========
Config.FolderPath        = "ItemDebris"   -- Путь к папке с партами
Config.PartName          = ""             -- Фильтр по имени (пусто = все)
Config.TargetMode        = "Player"       -- "Player" | "Mouse" | "CustomPart"
Config.TargetPartName    = ""             -- Имя кастомной цели

Config.StackMode         = true           -- Складывать в одну точку
Config.Offset            = Vector3.new(0, 0, 0)
Config.Spacing           = 2              -- Расстояние между партами
Config.SmoothTeleport    = false          -- Плавная телепортация
Config.SmoothSpeed       = 25             -- Скорость плавной телепортации
Config.MaxParts          = 50             -- Лимит активных партов

Config.LoopMode          = true           -- Режим петли
Config.LoopInterval      = 1              -- Интервал сбора (секунды)

Config.RespawnProtection = true           -- Защита от смерти
Config.AnchorOnFinish    = false          -- Заякорить при отпускании

-- ========== ЦВЕТОВАЯ ПАЛИТРА (Vape Style) ==========
Config.Colors = {
    -- Акценты
    Accent       = Color3.fromRGB(90, 80, 220),
    AccentDark   = Color3.fromRGB(60, 50, 160),
    AccentGlow   = Color3.fromRGB(130, 120, 255),
    
    -- Фоны
    Background   = Color3.fromRGB(18, 18, 22),
    Surface      = Color3.fromRGB(28, 28, 34),
    SurfaceLight = Color3.fromRGB(38, 38, 46),
    
    -- Текст
    TextPrimary   = Color3.fromRGB(240, 240, 245),
    TextSecondary = Color3.fromRGB(140, 140, 155),
    
    -- Семантические
    Success = Color3.fromRGB(80, 200, 120),
    Warning = Color3.fromRGB(240, 180, 60),
    Danger  = Color3.fromRGB(220, 70, 70),
    Info    = Color3.fromRGB(80, 170, 240),
}

-- ========== HOTKEYS ==========
Config.Hotkeys = {
    Toggle    = Enum.KeyCode.K,    -- Start/Stop loop / Pull once
    HideUI    = Enum.KeyCode.P,    -- Скрыть/показать UI
    Release   = Enum.KeyCode.L,    -- Отпустить все парты
    QuickPause = Enum.KeyCode.J,   -- Быстрая пауза
}

return Config
