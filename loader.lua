--[[
    ╔══════════════════════════════════════════════════╗
    ║        TELEPORT CONTROL PANEL v2.0               ║
    ║        LOADER — FINAL FIX                        ║
    ╚══════════════════════════════════════════════════╝
]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end
task.wait(2)

-- ============================================
-- NAMESPACE — используем shared (работает ВЕЗДЕ)
-- ============================================
shared.TCP = {
    Version = "2.0",
    Modules = {},
}

-- ============================================
-- ОПРЕДЕЛЕНИЕ URL
-- ============================================
local REPO = "Flamedragonz/RobloxUniversal"
local URL_FORMATS = {
    "https://raw.githubusercontent.com/" .. REPO .. "/main/modules/",
    "https://raw.githubusercontent.com/" .. REPO .. "/refs/heads/main/modules/",
}

local BASE_URL = nil

print("═══════════════════════════════════════")
print("  Teleport Control Panel v2.0")
print("  Detecting URL...")
print("═══════════════════════════════════════")

for _, url in pairs(URL_FORMATS) do
    local ok, result = pcall(function()
        return game:HttpGet(url .. "config.lua")
    end)
    if ok and result and #result > 50 and not result:find("404") then
        BASE_URL = url
        print("✅ URL: " .. url)
        break
    end
    task.wait(1)
end

if not BASE_URL then
    warn("❌ No working URL found!")
    return
end

shared.TCP.BaseURL = BASE_URL

-- ============================================
-- ЗАГРУЗЧИК С RETRY
-- ============================================
local MAX_RETRIES = 3
local DELAY_BETWEEN = 1.5
local RETRY_DELAY = 2

local function loadModule(name)
    local url = BASE_URL .. name .. ".lua"

    for attempt = 1, MAX_RETRIES do
        local httpOk, source = pcall(function()
            return game:HttpGet(url)
        end)

        if not httpOk or not source or #source < 10 then
            if attempt < MAX_RETRIES then
                warn("  ⚠️ Attempt " .. attempt .. " failed for " .. name .. ", retry...")
                task.wait(RETRY_DELAY)
            else
                warn("  ❌ HTTP failed: " .. name)
                return nil
            end
        else
            if source:find("404") or source:find("Not Found") then
                warn("  ❌ 404: " .. name .. ".lua not found in repo!")
                return nil
            end

            local compiled, compErr = loadstring(source, name)
            if not compiled then
                warn("  ❌ Syntax error in " .. name .. ": " .. tostring(compErr))
                return nil
            end

            local execOk, result = pcall(compiled)
            if not execOk then
                warn("  ❌ Runtime error in " .. name .. ": " .. tostring(result))
                return nil
            end

            -- ПРОВЕРКА: модуль должен вернуть таблицу
            if result == nil then
                warn("  ❌ " .. name .. ".lua returned nil!")
                warn("     Missing 'return' at end of file?")
                return nil
            end

            print("  ✅ " .. name .. " (" .. #source .. " bytes)")
            return result
        end
    end
    return nil
end

-- ============================================
-- ЗАГРУЗКА ПО ПОРЯДКУ
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

print("")
print("Loading " .. #modules .. " modules...")
print("─────────────────────────────────────────")

local allOk = true

for i, mod in ipairs(modules) do
    local fileName, key = mod[1], mod[2]
    print(string.format("[%02d/%02d] %s", i, #modules, fileName))

    local result = loadModule(fileName)

    if result ~= nil then
        shared.TCP.Modules[key] = result

        -- ВЕРИФИКАЦИЯ: сразу проверяем что записалось
        if shared.TCP.Modules[key] == nil then
            warn("  ❌ VERIFY FAILED: " .. key .. " is nil after assignment!")
            allOk = false
            break
        end
    else
        warn("")
        warn("═════════════════════════════════════════════")
        warn("  ❌ FATAL: " .. fileName .. " failed!")
        warn("  Check: " .. BASE_URL .. fileName .. ".lua")
        warn("═════════════════════════════════════════════")
        allOk = false
        break
    end

    if i < #modules then
        task.wait(DELAY_BETWEEN)
    end
end

print("─────────────────────────────────────────")
if allOk then
    print("✅ All " .. #modules .. " modules loaded!")
    
    -- Финальная проверка
    print("")
    print("Module verification:")
    for _, mod in ipairs(modules) do
        local key = mod[2]
        local status = shared.TCP.Modules[key] ~= nil and "✅" or "❌"
        print("  " .. status .. " " .. key)
    end
else
    warn("❌ Loading incomplete.")
end
