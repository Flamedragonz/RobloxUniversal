--[[
    MODULE: config.lua v2.1
    Настройки, цвета, темы, хоткеи, звуки
]]

local Config = {}

-- ========== ФУНКЦИОНАЛЬНЫЕ ==========
Config.FolderPath        = "ItemDebris"
Config.PartName          = ""
Config.PartNames         = {}           -- Мульти-фильтр {"Gold","Silver"}
Config.PartNameMode      = "include"    -- "include" | "exclude"
Config.TargetMode        = "Player"
Config.TargetPartName    = ""
Config.StackMode         = true
Config.Offset            = Vector3.new(0, 0, 0)
Config.Spacing           = 2
Config.SmoothTeleport    = false
Config.SmoothSpeed       = 25
Config.MaxParts          = 50
Config.LoopMode          = true
Config.LoopInterval      = 1
Config.RespawnProtection = true
Config.AnchorOnFinish    = false

-- ========== ВИЗУАЛ ==========
Config.ESPEnabled        = false
Config.SoundEnabled      = true
Config.MiniMode          = false
Config.CurrentTheme      = "Vape"

-- ========== ТЕМЫ ==========
Config.Themes = {
    Vape = {
        Accent       = Color3.fromRGB(90, 80, 220),
        AccentDark   = Color3.fromRGB(60, 50, 160),
        AccentGlow   = Color3.fromRGB(130, 120, 255),
        Background   = Color3.fromRGB(18, 18, 22),
        Surface      = Color3.fromRGB(28, 28, 34),
        SurfaceLight = Color3.fromRGB(38, 38, 46),
    },
    Ocean = {
        Accent       = Color3.fromRGB(30, 144, 255),
        AccentDark   = Color3.fromRGB(20, 100, 180),
        AccentGlow   = Color3.fromRGB(80, 180, 255),
        Background   = Color3.fromRGB(12, 18, 28),
        Surface      = Color3.fromRGB(20, 30, 45),
        SurfaceLight = Color3.fromRGB(30, 42, 58),
    },
    Crimson = {
        Accent       = Color3.fromRGB(200, 40, 60),
        AccentDark   = Color3.fromRGB(150, 30, 45),
        AccentGlow   = Color3.fromRGB(255, 80, 100),
        Background   = Color3.fromRGB(22, 14, 16),
        Surface      = Color3.fromRGB(35, 22, 25),
        SurfaceLight = Color3.fromRGB(48, 30, 34),
    },
    Emerald = {
        Accent       = Color3.fromRGB(40, 180, 90),
        AccentDark   = Color3.fromRGB(30, 130, 65),
        AccentGlow   = Color3.fromRGB(80, 220, 130),
        Background   = Color3.fromRGB(14, 22, 16),
        Surface      = Color3.fromRGB(22, 34, 26),
        SurfaceLight = Color3.fromRGB(30, 46, 36),
    },
    Gold = {
        Accent       = Color3.fromRGB(220, 180, 40),
        AccentDark   = Color3.fromRGB(170, 140, 30),
        AccentGlow   = Color3.fromRGB(255, 220, 80),
        Background   = Color3.fromRGB(22, 20, 14),
        Surface      = Color3.fromRGB(34, 32, 22),
        SurfaceLight = Color3.fromRGB(46, 44, 32),
    },
}

-- ========== ПРИМЕНИТЬ ТЕМУ ==========
local function applyTheme(name)
    local theme = Config.Themes[name]
    if not theme then return end
    Config.CurrentTheme = name
    for key, value in pairs(theme) do
        Config.Colors[key] = value
    end
end

-- ========== ЦВЕТА (инициализация из Vape) ==========
Config.Colors = {
    Accent       = Color3.fromRGB(90, 80, 220),
    AccentDark   = Color3.fromRGB(60, 50, 160),
    AccentGlow   = Color3.fromRGB(130, 120, 255),
    Background   = Color3.fromRGB(18, 18, 22),
    Surface      = Color3.fromRGB(28, 28, 34),
    SurfaceLight = Color3.fromRGB(38, 38, 46),
    TextPrimary   = Color3.fromRGB(240, 240, 245),
    TextSecondary = Color3.fromRGB(140, 140, 155),
    Success = Color3.fromRGB(80, 200, 120),
    Warning = Color3.fromRGB(240, 180, 60),
    Danger  = Color3.fromRGB(220, 70, 70),
    Info    = Color3.fromRGB(80, 170, 240),
}

Config.ApplyTheme = applyTheme

-- ========== ХОТКЕИ ==========
Config.Hotkeys = {
    Toggle     = Enum.KeyCode.K,
    HideUI     = Enum.KeyCode.P,
    Release    = Enum.KeyCode.L,
    QuickPause = Enum.KeyCode.J,
    MiniMode   = Enum.KeyCode.M,
}

-- ========== ЗВУКИ ==========
Config.Sounds = {
    Collect  = 6042053626,
    Release  = 5853855281,
    Error    = 6042054617,
    Toggle   = 9119713951,
}

return Config
