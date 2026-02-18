--[[
    ╔══════════════════════════════════════════════════╗
    ║        TELEPORT CONTROL PANEL v2.0               ║
    ║        LOADER — точка входа                      ║
    ║                                                  ║
    ║  loadstring(game:HttpGet("https://raw.github    ║
    ║  usercontent.com/Flamedragonz/RobloxUniversal   ║
    ║  /refs/heads/main/loader.lua"))()                ║
    ╚══════════════════════════════════════════════════╝
]]

-- Ждём загрузку игры
if not game:IsLoaded() then
    game.Loaded:Wait()
end
task.wait(1)

-- ============================================
-- АВТООПРЕДЕЛЕНИЕ РАБОЧЕГО URL
-- ============================================
local REPO = "Flamedragonz/RobloxUniversal"

local URL_FORMATS = {
    "https://raw.githubusercontent.com/" .. REPO .. "/main/modules/",
    "https://raw.githubusercontent.com/" .. REPO .. "/refs/heads/main/modules/",
    "https://raw.githubusercontent.com/" .. REPO .. "/master/modules/",
}

local BASE_URL = nil

print("═══════════════════════════════════════")
print("  Teleport Control Panel v2.0")
print("  Detecting correct URL format...")
print("═══════════════════════════════════════")

for _, url in pairs(URL_FORMATS) do
    local testUrl = url .. "config.lua"
    local ok, result = pcall(function()
        return game:HttpGet(testUrl)
    end)
    
    if ok and result and #result > 50 and not result:find("404") and not result:find("Not Found") then
        BASE_URL = url
        print("✅ Working URL format found: " .. url)
        break
    else
        print("❌ Not working: " .. url)
    end
end

if not BASE_URL then
    warn("══════════════════════════════════════════════════")
    warn("  ❌ FATAL: Could not find working URL!")
    warn("")
    warn("  Checklist:")
    warn("  1. Does folder 'modules/' exist in your repo?")
    warn("  2. Are all .lua files inside modules/ folder?")
    warn("  3. Is the repo public (not private)?")
    warn("  4. Did you commit and push the files?")
    warn("")
    warn("  Your repo: github.com/" .. REPO)
    warn("══════════════════════════════════════════════════")
    return
end

-- ============================================
-- ФУНКЦИЯ ЗАГРУЗКИ МОДУЛЯ
-- ============================================
local function loadModule(name)
    local url = BASE_URL .. name .. ".lua"
    
    -- Шаг 1: скачать
    local httpOk, source = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not httpOk then
        warn("❌ [TCP] HTTP failed for: " .. name)
        warn("   URL: " .. url)
        warn("   Error: " .. tostring(source))
        return nil
    end
    
    if not source or #source < 10 then
        warn("❌ [TCP] Empty response for: " .. name)
        warn("   URL: " .. url)
        return nil
    end
    
    if source:find("404") or source:find("Not Found") then
        warn("❌ [TCP] 404 Not Found: " .. name)
        warn("   URL: " .. url)
        warn("   File does not exist in repository!")
        return nil
    end
    
    -- Шаг 2: скомпилировать
    local compileOk, compiled = pcall(loadstring, source)
    
    if not compileOk or not compiled then
        warn("❌ [TCP] Syntax error in: " .. name)
        warn("   Error: " .. tostring(compiled))
        warn("   First 200 chars of source:")
        warn("   " .. string.sub(source, 1, 200))
        return nil
    end
    
    -- Шаг 3: выполнить
    local execOk, result = pcall(compiled)
    
    if not execOk then
        warn("❌ [TCP] Runtime error in: " .. name)
        warn("   Error: " .. tostring(result))
        return nil
    end
    
    print("✅ [TCP] Loaded: " .. name)
    return result
end

-- ============================================
-- ГЛОБАЛЬНЫЙ NAMESPACE
-- ============================================
getgenv().TCP = {
    Version = "2.0",
    Modules = {},
    BaseURL = BASE_URL,
}

-- ============================================
-- ЗАГРУЗКА В ПРАВИЛЬНОМ ПОРЯДКЕ
-- ============================================
--[[
    Порядок критически важен!
    Если модуль N не загрузился, все модули после него
    которые от него зависят — тоже не загрузятся.
    
    Цепочка:
    config [1] → state [2] → utils [3] → notify [4] →
    components [5] → engine [6] → ui [7] → status [8] →
    teleport [9] → input [10] → respawn [11] → init [12]
]]

local loadOrder = {
    {name = "config",     required = true,  desc = "Settings & colors"},
    {name = "state",      required = true,  desc = "Shared state"},
    {name = "utils",      required = true,  desc = "Utilities & animations"},
    {name = "notify",     required = true,  desc = "Notification system"},
    {name = "components", required = true,  desc = "UI components"},
    {name = "engine",     required = true,  desc = "Parts engine"},
    {name = "ui",         required = true,  desc = "Main UI builder"},
    {name = "status",     required = true,  desc = "Status updater"},
    {name = "teleport",   required = true,  desc = "Teleport loop"},
    {name = "input",      required = true,  desc = "Input handler"},
    {name = "respawn",    required = true,  desc = "Respawn protection"},
    {name = "init",       required = true,  desc = "Initialization"},
}

print("")
print("Loading " .. #loadOrder .. " modules...")
print("─────────────────────────────────────────")

local allLoaded = true

for i, moduleInfo in ipairs(loadOrder) do
    local stepLabel = string.format("[%02d/%02d]", i, #loadOrder)
    print(stepLabel .. " Loading: " .. moduleInfo.name .. " (" .. moduleInfo.desc .. ")")
    
    local result = loadModule(moduleInfo.name)
    
    if result ~= nil then
        -- Capitalize first letter for module key
        local key = moduleInfo.name:sub(1,1):upper() .. moduleInfo.name:sub(2)
        TCP.Modules[key] = result
    else
        if moduleInfo.required then
            warn("")
            warn("═══════════════════════════════════════════")
            warn("  ❌ FATAL: Required module failed: " .. moduleInfo.name)
            warn("")
            warn("  Cannot continue loading.")
            warn("  Fix this module first, then retry.")
            warn("")
            warn("  Common fixes:")
            warn("  • Check the file exists in modules/ folder")
            warn("  • Check for Lua syntax errors")
            warn("  • Check that previous modules loaded OK")
            warn("═══════════════════════════════════════════")
            allLoaded = false
            break
        else
            warn("⚠️ Optional module skipped: " .. moduleInfo.name)
        end
    end
    
    task.wait(0.05) -- Небольшая пауза между загрузками
end

print("─────────────────────────────────────────")

if allLoaded then
    print("═══════════════════════════════════════")
    print("  ✅ All modules loaded successfully!")
    print("  Teleport Control Panel v2.0 ready")
    print("═══════════════════════════════════════")
else
    warn("═══════════════════════════════════════")
    warn("  ❌ Loading failed. See errors above.")
    warn("═══════════════════════════════════════")
end
