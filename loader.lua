--[[
    TCP MINIMAL LOADER — для отладки
    Без Loading Screen, только текст в консоли
    Максимально подробные ошибки
]]

if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(1)

-- Очистка
shared.TCP = nil
shared._TCP_LOADING = nil
pcall(function()
    local CG = game:GetService("CoreGui")
    local g1 = CG:FindFirstChild("TCP_VapeStyle"); if g1 then g1:Destroy() end
    local g2 = CG:FindFirstChild("TCP_LoadingScreen"); if g2 then g2:Destroy() end
end)
task.wait(0.5)

print("═══════════════════════════════════════")
print("  TCP MINIMAL LOADER (debug mode)")
print("═══════════════════════════════════════")

-- Namespace
shared.TCP = {Version = "2.1", Modules = {}, Loaded = false}

-- URL
local BASE = "https://raw.githubusercontent.com/Flamedragonz/RobloxUniversal/main/modules/"

-- Тест URL
print("\n[1/3] Testing connection...")
local testOk, testResult = pcall(function()
    return game:HttpGet(BASE .. "config.lua")
end)

if not testOk or not testResult or #testResult < 50 then
    -- Попробовать второй формат
    BASE = "https://raw.githubusercontent.com/Flamedragonz/RobloxUniversal/refs/heads/main/modules/"
    testOk, testResult = pcall(function()
        return game:HttpGet(BASE .. "config.lua")
    end)
    if not testOk or not testResult or #testResult < 50 then
        warn("❌ Cannot connect to GitHub!")
        warn("   Error: " .. tostring(testResult))
        return
    end
end
print("  ✅ Connected: " .. BASE)

-- Загрузка одного модуля
local function loadMod(name)
    local url = BASE .. name .. ".lua"
    print("\n  Loading: " .. name)
    print("  URL: " .. url)
    
    -- HTTP
    local httpOk, source
    for attempt = 1, 3 do
        httpOk, source = pcall(function()
            return game:HttpGet(url)
        end)
        if httpOk and source and #source > 10 then
            break
        end
        if attempt < 3 then
            print("    ⚠️ Attempt " .. attempt .. " failed, retrying...")
            task.wait(2)
        end
    end
    
    if not httpOk then
        warn("    ❌ HTTP FAILED: " .. tostring(source))
        return nil
    end
    
    if not source or #source < 10 then
        warn("    ❌ EMPTY RESPONSE")
        return nil
    end
    
    if source:find("404") or source:find("Not Found") then
        warn("    ❌ 404 — FILE NOT FOUND IN REPO!")
        return nil
    end
    
    print("    Downloaded: " .. #source .. " bytes")
    
    -- Compile
    local compiled, compErr = loadstring(source, name)
    if not compiled then
        warn("    ❌ SYNTAX ERROR:")
        warn("    " .. tostring(compErr))
        -- Показать строку с ошибкой
        local lineNum = tostring(compErr):match(":(%d+):")
        if lineNum then
            local n = tonumber(lineNum)
            local currentLine = 0
            for line in source:gmatch("[^\n]+") do
                currentLine = currentLine + 1
                if currentLine >= n - 2 and currentLine <= n + 2 then
                    local marker = currentLine == n and " >>> " or "     "
                    print("    " .. marker .. currentLine .. ": " .. line)
                end
            end
        end
        return nil
    end
    
    -- Execute
    local execOk, result = pcall(compiled)
    if not execOk then
        warn("    ❌ RUNTIME ERROR:")
        warn("    " .. tostring(result))
        return nil
    end
    
    -- Check return
    if result == nil then
        warn("    ❌ MODULE RETURNED NIL!")
        warn("    Check: does " .. name .. ".lua end with 'return Something'?")
        
        -- Дополнительная проверка
        if not source:find("return ") then
            warn("    → NO 'return' STATEMENT FOUND IN FILE!")
        else
            warn("    → 'return' exists but returned nil")
            warn("    → Probably a dependency check failed (missing module)")
            
            -- Показать какие модули он проверяет
            for line in source:gmatch("[^\n]+") do
                if line:find("Missing") or line:find("not found") then
                    print("    Found check: " .. line:match("^%s*(.-)%s*$"))
                end
            end
        end
        return nil
    end
    
    print("    ✅ OK! (type: " .. type(result) .. ")")
    return result
end

-- ===== ЗАГРУЗКА 14 МОДУЛЕЙ =====
print("\n[2/3] Loading modules...")
print("─────────────────────────────────────────")

local modules = {
    {"config",     "Config"},
    {"state",      "State"},
    {"utils",      "Utils"},
    {"notify",     "Notify"},
    {"components", "Components"},
    {"engine",     "Engine"},
    {"scanner",    "Scanner"},
    {"presets",    "Presets"},
    {"ui",         "UI"},
    {"status",     "Status"},
    {"teleport",   "Teleport"},
    {"input",      "Input"},
    {"respawn",    "Respawn"},
    {"init",       "Init"},
}

local allOk = true

for i, mod in ipairs(modules) do
    local name, key = mod[1], mod[2]
    
    print(string.format("\n[%02d/%02d] %s", i, #modules, name))
    
    local result = loadMod(name)
    
    if result ~= nil then
        shared.TCP.Modules[key] = result
        
        -- Верификация
        if shared.TCP.Modules[key] == nil then
            warn("  ❌ VERIFY FAILED: wrote to shared.TCP.Modules." .. key .. " but it's nil!")
            warn("  This means shared is broken in this exploit")
            allOk = false
            break
        end
    else
        warn("\n═══════════════════════════════════════")
        warn("  ❌ STOPPED AT: " .. name)
        warn("")
        warn("  All loaded modules so far:")
        for k, v in pairs(shared.TCP.Modules) do
            print("    ✅ " .. k .. " (" .. type(v) .. ")")
        end
        warn("")
        warn("  Missing modules that " .. name .. " might need:")
        
        -- Показать зависимости
        local deps = {
            state = {"Config"},
            notify = {"Config", "Utils"},
            components = {"Config", "State", "Utils"},
            engine = {"Config", "State"},
            scanner = {"Config", "State"},
            presets = {"Config", "Notify"},
            ui = {"Config", "State", "Utils", "Notify", "Components", "Engine"},
            status = {"Config", "State", "Utils", "Engine"},
            teleport = {"Config", "State", "Engine", "Notify"},
            input = {"Config", "State", "Engine", "Notify", "Utils"},
            respawn = {"Config", "State"},
            init = {"Config", "Notify", "Engine", "UI", "Status", "Teleport", "Input", "Respawn"},
        }
        
        local modDeps = deps[name]
        if modDeps then
            for _, dep in pairs(modDeps) do
                local status = shared.TCP.Modules[dep] ~= nil and "✅" or "❌ MISSING!"
                print("    " .. status .. " " .. dep)
            end
        end
        
        allOk = false
        break
    end
    
    -- Пауза между модулями
    task.wait(1.5)
end

-- ===== РЕЗУЛЬТАТ =====
print("\n═══════════════════════════════════════")
if allOk then
    shared.TCP.Loaded = true
    print("  ✅ ALL " .. #modules .. " MODULES LOADED!")
    print("")
    print("  Modules in shared.TCP.Modules:")
    for k, v in pairs(shared.TCP.Modules) do
        print("    " .. k .. " = " .. type(v))
    end
    print("")
    print("  TCP is ready!")
else
    print("  ❌ LOADING FAILED")
    print("  Fix the error above and try again")
    print("")
    print("  Quick clean before retry:")
    print("  shared.TCP = nil; shared._TCP_LOADING = nil")
end
print("═══════════════════════════════════════\n")
