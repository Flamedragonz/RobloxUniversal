-- ============================================================
-- GRAVE BUILDER + SYNC via jsonbin.io
-- LocalScript
-- ============================================================

-- ============================================================
-- СИНХРОНИЗАЦИЯ ЧЕРЕЗ JSONBIN.IO
-- Использует HTTP API эксплойт-клиента (request/syn.request/http.request)
-- ============================================================
local RunService  = game:GetService("RunService")
local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- !! ВСТАВЬ СВОИ ДАННЫЕ !!
local API_KEY       = "$2a$10$MCM7FTbZMBt2ei7K2jwHI.vGnwQ0M3.l9u6.QEcjL5zuFPViZvA.2"
local BIN_ID        = "6995cf2c43b1c97be988c014"
local SYNC_URL      = "https://api.jsonbin.io/v3/b/" .. BIN_ID
local POLL_INTERVAL = 4

-- Определяем доступную HTTP функцию клиента
local httpRequest = (function()
    -- Synapse X, Fluxus, Solara
    if syn and syn.request then
        return syn.request
    end
    -- KRNL, Electrons и др.
    if http and http.request then
        return http.request
    end
    -- Универсальный fallback
    if request then
        return request
    end
    -- Попытка через hookfunction окружения
    if (getgenv or getrenv) then
        local env = getgenv and getgenv() or getrenv()
        if env.request then return env.request end
        if env.syn and env.syn.request then return env.syn.request end
    end
    warn("[GraveSync] HTTP функция не найдена! Синхронизация отключена.")
    return nil
end)()

local syncEnabled = httpRequest ~= nil

local myClientId  = LocalPlayer.Name.."_"..tostring(math.random(100000,999999))
local lastVersion = -1
local builtModels = {}
local localGraves = {}

-- ── Утилиты сериализации ──────────────────────────────────
local function v3t(v) return {x=v.X, y=v.Y, z=v.Z} end
local function tv3(t) return Vector3.new(t.x, t.y, t.z) end

local function generateId()
    return myClientId.."_"..tostring(os.clock()):gsub("[%.,]","")
end

-- ── HTTP запросы через клиентский API ────────────────────

local function httpGet(url, headers)
    if not syncEnabled then return nil end
    local ok, result = pcall(function()
        return httpRequest({
            Url     = url,
            Method  = "GET",
            Headers = headers or {},
        })
    end)
    if not ok then
        warn("[GraveSync] GET error: "..tostring(result))
        return nil
    end
    return result
end

local function httpPut(url, headers, body)
    if not syncEnabled then return nil end
    local ok, result = pcall(function()
        return httpRequest({
            Url     = url,
            Method  = "PUT",
            Headers = headers or {},
            Body    = body or "",
        })
    end)
    if not ok then
        warn("[GraveSync] PUT error: "..tostring(result))
        return nil
    end
    return result
end

-- ── JSONbin чтение ────────────────────────────────────────

local function fetchGraves()
    if not syncEnabled then return nil, nil end

    local result = httpGet(SYNC_URL.."/latest", {
        ["X-Master-Key"] = API_KEY,
        ["X-Bin-Meta"]   = "false",
    })

    if not result then return nil, nil end

    -- Разные клиенты возвращают по-разному
    local body = result.Body or result.body or ""
    local code = result.StatusCode or result.status or 0

    if code ~= 200 then
        warn("[GraveSync] fetch HTTP "..tostring(code).." | "..tostring(body):sub(1,100))
        return nil, nil
    end

    local ok, parsed = pcall(function()
        return game:GetService("HttpService"):JSONDecode(body)
    end)

    if not ok then
        warn("[GraveSync] JSON parse error: "..tostring(parsed))
        return nil, nil
    end

    local version = parsed.metadata and parsed.metadata.version or 0
    local data    = parsed.record   or parsed
    return data, version
end

-- ── JSONbin запись ────────────────────────────────────────

local function pushGraves(tbl)
    if not syncEnabled then return false end

    local ok, body = pcall(function()
        return game:GetService("HttpService"):JSONEncode(tbl)
    end)
    if not ok then
        warn("[GraveSync] JSON encode error: "..tostring(body))
        return false
    end

    local result = httpPut(SYNC_URL, {
        ["Content-Type"] = "application/json",
        ["X-Master-Key"] = API_KEY,
    }, body)

    if not result then return false end

    local code = result.StatusCode or result.status or 0
    if code ~= 200 then
        local rb = result.Body or result.body or ""
        warn("[GraveSync] push HTTP "..tostring(code).." | "..tostring(rb):sub(1,100))
        return false
    end

    return true
end

-- ── Синхронизация: отправить постройку ───────────────────

local function syncBuild(payload)
    if not syncEnabled then return end
    payload.owner = myClientId

    task.spawn(function()  -- не блокируем основной поток
        local data, _ = fetchGraves()
        if not data then
            data = {graves={}, removed={}}
        end
        data.graves  = data.graves  or {}
        data.removed = data.removed or {}

        table.insert(data.graves, payload)
        localGraves[payload.id] = payload
        pushGraves(data)
        print("[GraveSync] Отправлено: "..payload.playerName)
    end)
end

-- ── Синхронизация: удалить свои ──────────────────────────

local function syncRemoveAll()
    if not syncEnabled then return end
    task.spawn(function()
        local data, _ = fetchGraves()
        if not data then return end
        data.graves  = data.graves  or {}
        data.removed = data.removed or {}

        local myIds = {}
        for id,_ in pairs(localGraves) do myIds[id] = true end

        local newG = {}
        for _, g in ipairs(data.graves) do
            if myIds[g.id] then
                table.insert(data.removed, g.id)
            else
                table.insert(newG, g)
            end
        end
        data.graves = newG
        pushGraves(data)
        localGraves = {}
    end)
end

-- ── Polling ───────────────────────────────────────────────
-- Выносим в отдельный поток чтобы не лагал UI
local pollTimer = 0
local polling   = false

RunService.Heartbeat:Connect(function(dt)
    if not syncEnabled then return end
    pollTimer = pollTimer + dt
    if pollTimer < POLL_INTERVAL then return end
    if polling then return end  -- пропускаем если предыдущий запрос ещё идёт
    pollTimer = 0

    polling = true
    task.spawn(function()
        local ok, err = pcall(function()
            local data, version = fetchGraves()
            if not data or not version then return end
            if version <= lastVersion  then return end
            lastVersion = version

            for _, id in ipairs(data.removed or {}) do
                local m = builtModels[id]
                if m and type(m) ~= "boolean" then
                    pcall(function() m:Destroy() end)
                end
                builtModels[id] = nil
            end

            for _, payload in ipairs(data.graves or {}) do
                if payload.owner ~= myClientId then
                    buildFromPayload(payload)
                end
            end
        end)
        if not ok then warn("[GraveSync] poll error: "..tostring(err)) end
        polling = false
    end)
end)

-- ── Стартовая синхронизация ───────────────────────────────
task.delay(2, function()
    if not syncEnabled then
        warn("[GraveSync] Синхронизация недоступна — HTTP API клиента не найден")
        return
    end
    local data, version = fetchGraves()
    if not data then
        warn("[GraveSync] Не удалось получить данные при старте")
        return
    end
    lastVersion = version or -1
    for _, payload in ipairs(data.graves or {}) do
        if payload.owner ~= myClientId then
            pcall(buildFromPayload, payload)
        end
    end
    print("[GraveSync] Стартовая синхронизация OK. Могил: "..#(data.graves or {}))
end)

print("[GraveSync] Запущен. ClientId: "..myClientId)
print("[GraveSync] HTTP доступен: "..tostring(syncEnabled))

-- ============================================================
-- GUI
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name          = "GraveBuilder"
screenGui.ResetOnSpawn  = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent        = LocalPlayer.PlayerGui

local frame = Instance.new("Frame")
frame.Size            = UDim2.new(0,380,0,620)
frame.Position        = UDim2.new(0.5,-190,0.5,-310)
frame.BackgroundColor3 = Color3.fromRGB(22,22,22)
frame.BorderSizePixel = 0
frame.Parent          = screenGui
addCorner(frame,12)
addStroke(frame, Color3.fromRGB(55,55,55), 1.5)

-- Drag
local dragging, dragStart, startPos = false,nil,nil
frame.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = inp.Position
        startPos  = frame.Position
    end
end)
frame.InputChanged:Connect(function(inp)
    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local d = inp.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset+d.X,
            startPos.Y.Scale, startPos.Y.Offset+d.Y)
    end
end)
frame.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end
end)

-- Заголовок
local titleBar = Instance.new("Frame")
titleBar.Size            = UDim2.new(1,0,0,44)
titleBar.BackgroundColor3 = Color3.fromRGB(15,15,15)
titleBar.BorderSizePixel = 0
titleBar.Parent          = frame
addCorner(titleBar,12)

local titleLbl = Instance.new("TextLabel")
titleLbl.Size              = UDim2.new(1,-10,1,0)
titleLbl.Position          = UDim2.new(0,10,0,0)
titleLbl.BackgroundTransparency = 1
titleLbl.TextColor3        = Color3.fromRGB(220,220,220)
titleLbl.Text              = "⚰️  Grave Builder"
titleLbl.Font              = Enum.Font.GothamBold
titleLbl.TextSize          = 18
titleLbl.TextXAlignment    = Enum.TextXAlignment.Left
titleLbl.Parent            = titleBar

-- Индикатор синхронизации
local syncDot = Instance.new("TextLabel")
syncDot.Size              = UDim2.new(0,80,0,16)
syncDot.Position          = UDim2.new(1,-88,0,14)
syncDot.BackgroundTransparency = 1
syncDot.TextColor3        = Color3.fromRGB(100,200,100)
syncDot.Text              = "● SYNC"
syncDot.Font              = Enum.Font.GothamBold
syncDot.TextSize          = 10
syncDot.TextXAlignment    = Enum.TextXAlignment.Right
syncDot.Parent            = titleBar

-- Мигание индикатора при polling
local _dotTimer = 0
RunService.Heartbeat:Connect(function(dt)
    _dotTimer = _dotTimer + dt
    if _dotTimer > 1 then _dotTimer = 0 end
    syncDot.TextTransparency = (_dotTimer > 0.5) and 0.6 or 0
end)

-- Scroll
local scroll = Instance.new("ScrollingFrame")
scroll.Size              = UDim2.new(1,0,1,-44)
scroll.Position          = UDim2.new(0,0,0,44)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel   = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(90,90,90)
scroll.CanvasSize        = UDim2.new(0,0,0,0)
scroll.Parent            = frame

local scrollLayout = Instance.new("UIListLayout")
scrollLayout.Padding = UDim.new(0,8)
scrollLayout.Parent  = scroll

local scrollPad = Instance.new("UIPadding")
scrollPad.PaddingTop    = UDim.new(0,10)
scrollPad.PaddingLeft   = UDim.new(0,10)
scrollPad.PaddingRight  = UDim.new(0,10)
scrollPad.PaddingBottom = UDim.new(0,10)
scrollPad.Parent        = scroll

local function autoCanvas()
    scroll.CanvasSize = UDim2.new(0,0,0, scrollLayout.AbsoluteContentSize.Y+20)
end
scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(autoCanvas)

local function makeSection(txt)
    local l = Instance.new("TextLabel")
    l.Size              = UDim2.new(1,0,0,20)
    l.BackgroundTransparency = 1
    l.TextColor3        = Color3.fromRGB(140,140,140)
    l.Text              = txt
    l.Font              = Enum.Font.GothamBold
    l.TextSize          = 11
    l.TextXAlignment    = Enum.TextXAlignment.Left
    l.Parent            = scroll
    return l
end

local function makeBtn(text, bgColor, textColor)
    local btn = Instance.new("TextButton")
    btn.Size            = UDim2.new(1,0,0,34)
    btn.BackgroundColor3 = bgColor   or Color3.fromRGB(55,55,55)
    btn.TextColor3      = textColor  or Color3.fromRGB(220,220,220)
    btn.Text            = text
    btn.Font            = Enum.Font.GothamBold
    btn.TextSize        = 13
    btn.AutoButtonColor = false
    btn.Parent          = scroll
    addCorner(btn,6)
    addStroke(btn, Color3.fromRGB(70,70,70))
    local orig = bgColor or Color3.fromRGB(55,55,55)
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = orig:Lerp(Color3.fromRGB(255,255,255),0.1)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = orig
    end)
    return btn
end

-- ── Список игроков ─────────────────────────────────────────
makeSection("👥  Игроки на сервере (клик = выбрать):")

local playerScroll = Instance.new("ScrollingFrame")
playerScroll.Size            = UDim2.new(1,0,0,110)
playerScroll.BackgroundColor3 = Color3.fromRGB(30,30,30)
playerScroll.BorderSizePixel = 0
playerScroll.ScrollBarThickness = 3
playerScroll.ScrollBarImageColor3 = Color3.fromRGB(80,80,80)
playerScroll.CanvasSize      = UDim2.new(0,0,0,0)
playerScroll.Parent          = scroll
addCorner(playerScroll,6)

local plLayout = Instance.new("UIListLayout")
plLayout.Padding = UDim.new(0,3)
plLayout.Parent  = playerScroll

local plPad = Instance.new("UIPadding")
plPad.PaddingTop   = UDim.new(0,4)
plPad.PaddingLeft  = UDim.new(0,4)
plPad.PaddingRight = UDim.new(0,4)
plPad.Parent       = playerScroll

local selectedPlayers = {}  -- {[Player|"__offline__X"] = Player|{Name,Character=nil}}
local playerBtns      = {}

local multiLabel = Instance.new("TextLabel")
multiLabel.Size              = UDim2.new(1,0,0,18)
multiLabel.BackgroundTransparency = 1
multiLabel.TextColor3        = Color3.fromRGB(120,200,120)
multiLabel.Text              = "Выбрано: никого"
multiLabel.Font              = Enum.Font.Gotham
multiLabel.TextSize          = 11
multiLabel.TextXAlignment    = Enum.TextXAlignment.Left
multiLabel.Parent            = scroll

local function updateMultiLabel()
    local names = {}
    for key, val in pairs(selectedPlayers) do
        if type(key) == "userdata" then
            table.insert(names, key.Name)
        elseif type(key) == "string" and key:sub(1,10) == "__offline__" then
            table.insert(names, val.Name.."✍")
        end
    end
    multiLabel.Text = #names==0
        and "Выбрано: никого"
        or  "Выбрано ("..#names.."): "..table.concat(names,", ")
end

local function refreshPlayerList()
    for _, b in ipairs(playerBtns) do b:Destroy() end
    playerBtns = {}

    for _, plr in ipairs(Players:GetPlayers()) do
        local btn = Instance.new("TextButton")
        btn.Size            = UDim2.new(1,-8,0,24)
        btn.BackgroundColor3 = selectedPlayers[plr]
            and Color3.fromRGB(55,95,55) or Color3.fromRGB(45,45,48)
        btn.TextColor3      = Color3.fromRGB(200,200,200)
        btn.Text            = "  "..plr.Name
        btn.Font            = Enum.Font.Gotham
        btn.TextSize        = 12
        btn.TextXAlignment  = Enum.TextXAlignment.Left
        btn.AutoButtonColor = false
        btn.Parent          = playerScroll
        addCorner(btn,4)

        btn.MouseButton1Click:Connect(function()
            if selectedPlayers[plr] then
                selectedPlayers[plr]   = nil
                btn.BackgroundColor3   = Color3.fromRGB(45,45,48)
            else
                selectedPlayers[plr]   = true
                btn.BackgroundColor3   = Color3.fromRGB(55,95,55)
            end
            updateMultiLabel()
        end)
        table.insert(playerBtns, btn)
    end

    plLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        playerScroll.CanvasSize = UDim2.new(0,0,0, plLayout.AbsoluteContentSize.Y+8)
    end)
    playerScroll.CanvasSize = UDim2.new(0,0,0, plLayout.AbsoluteContentSize.Y+8)
end
refreshPlayerList()

local refreshBtn = makeBtn("🔄  Обновить список", Color3.fromRGB(40,40,60))
refreshBtn.MouseButton1Click:Connect(function()
    selectedPlayers = {}
    refreshPlayerList()
    updateMultiLabel()
end)

-- ── Ввод вручную ───────────────────────────────────────────
makeSection("✍️  Или введи имя вручную (офлайн тоже работает):")

local manualInput = Instance.new("TextBox")
manualInput.Size            = UDim2.new(1,0,0,32)
manualInput.BackgroundColor3 = Color3.fromRGB(38,38,38)
manualInput.TextColor3      = Color3.fromRGB(255,255,255)
manualInput.PlaceholderText = "Имя игрока..."
manualInput.PlaceholderColor3 = Color3.fromRGB(90,90,90)
manualInput.Text            = ""
manualInput.Font            = Enum.Font.Gotham
manualInput.TextSize        = 13
manualInput.ClearTextOnFocus = false
manualInput.Parent          = scroll
addCorner(manualInput,6)
addStroke(manualInput, Color3.fromRGB(60,60,70))

local addManualBtn = makeBtn("➕  Добавить в выбор", Color3.fromRGB(40,60,80))
addManualBtn.MouseButton1Click:Connect(function()
    local name = manualInput.Text:match("^%s*(.-)%s*$")
    if name == "" then return end

    local online = Players:FindFirstChild(name)
    if online then
        selectedPlayers[online] = true
        refreshPlayerList()
    else
        local key = "__offline__"..name
        if not selectedPlayers[key] then
            selectedPlayers[key] = {Name=name, Character=nil}

            -- Добавляем плашку в список
            local lbl2 = Instance.new("TextLabel")
            lbl2.Size            = UDim2.new(1,-8,0,24)
            lbl2.BackgroundColor3 = Color3.fromRGB(60,50,30)
            lbl2.TextColor3      = Color3.fromRGB(220,200,150)
            lbl2.Text            = "  ✍ "..name.." (офлайн)"
            lbl2.Font            = Enum.Font.Gotham
            lbl2.TextSize        = 12
            lbl2.TextXAlignment  = Enum.TextXAlignment.Left
            lbl2.Parent          = playerScroll
            addCorner(lbl2,4)
            table.insert(playerBtns, lbl2)
            playerScroll.CanvasSize = UDim2.new(0,0,0, plLayout.AbsoluteContentSize.Y+8)
        end
    end
    updateMultiLabel()
    manualInput.Text = ""
end)

-- ── Тип могилы ─────────────────────────────────────────────
makeSection("🪦  Тип могилы:")

local styles      = {"RIP камень","Крест","Склеп"}
local styleColors = {
    Color3.fromRGB(55,55,85),
    Color3.fromRGB(75,45,45),
    Color3.fromRGB(45,65,45),
}
local currentStyleIndex = 1

local styleBtn = makeBtn("▶  "..styles[1], styleColors[1])
styleBtn.MouseButton1Click:Connect(function()
    currentStyleIndex = (currentStyleIndex % #styles) + 1
    styleBtn.Text            = "▶  "..styles[currentStyleIndex]
    styleBtn.BackgroundColor3 = styleColors[currentStyleIndex]
end)

-- ── Режим размещения ───────────────────────────────────────
makeSection("♻️  Режим размещения:")

local replaceMode    = false
local replaceModeBtn = makeBtn("▶  Добавить рядом с существующими", Color3.fromRGB(50,50,50))
replaceModeBtn.MouseButton1Click:Connect(function()
    replaceMode = not replaceMode
    if replaceMode then
        replaceModeBtn.Text             = "▶  Заменить существующие могилы"
        replaceModeBtn.BackgroundColor3  = Color3.fromRGB(90,50,20)
    else
        replaceModeBtn.Text             = "▶  Добавить рядом с существующими"
        replaceModeBtn.BackgroundColor3  = Color3.fromRGB(50,50,50)
    end
end)

-- ── Действия ───────────────────────────────────────────────
makeSection("⚙️  Действия:")

local function getPlayersList()
    local list = {}
    for key, val in pairs(selectedPlayers) do
        if type(key) == "userdata" then
            table.insert(list, key)
        elseif type(key) == "string" and key:sub(1,10) == "__offline__" then
            table.insert(list, val)
        end
    end
    if #list == 0 then table.insert(list, LocalPlayer) end
    return list
end

local function getFootPos()
    local char = LocalPlayer.Character
    if not char then return Vector3.new(0,0,0) end
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return Vector3.new(0,0,0) end
    return Vector3.new(hrp.Position.X, hrp.Position.Y-3, hrp.Position.Z)
end

-- Кнопка: одиночная могила
local buildSingleBtn = makeBtn("⚰️  Построить могилу", Color3.fromRGB(55,130,55))
buildSingleBtn.MouseButton1Click:Connect(function()
    if replaceMode then
        removeExistingGraves()
        syncRemoveAll()
        builtModels = {}
    end

    local footPos  = getFootPos()
    local styleKey = ({"rip","cross","crypt"})[currentStyleIndex]
    local list     = getPlayersList()
    local tp       = list[1]
    local pName    = tp and tp.Name or LocalPlayer.Name

    local payload = {
        id         = generateId(),
        graveType  = (styleKey=="crypt") and "crypt" or "grave",
        origin     = v3t(footPos),
        playerName = pName,
        style      = styleKey,
        owner      = myClientId,
        timestamp  = os.time(),
    }

    local model
    if styleKey == "crypt" then
        model = buildCrypt(footPos, pName, tp)
    else
        model = buildGraveModel(footPos, styleKey, pName, tp)
    end
    builtModels[payload.id] = model

    syncBuild(payload)

    screenGui:Destroy()
    script:Destroy()
end)

-- Кнопка: кладбище + часовня
local buildCemeteryBtn = makeBtn("🏚️  Кладбище + Часовня", Color3.fromRGB(100,65,30))
buildCemeteryBtn.MouseButton1Click:Connect(function()
    if replaceMode then
        removeExistingGraves()
        syncRemoveAll()
        builtModels = {}
    end

    local footPos = getFootPos()
    local list    = getPlayersList()
    local names   = {}
    for _, p in ipairs(list) do table.insert(names, p.Name) end

    buildCemetery(footPos, list)

    local payload = {
        id          = generateId(),
        graveType   = "cemetery",
        origin      = v3t(footPos),
        playerName  = LocalPlayer.Name,
        playerNames = names,
        owner       = myClientId,
        timestamp   = os.time(),
    }
    builtModels[payload.id] = true
    syncBuild(payload)

    screenGui:Destroy()
    script:Destroy()
end)

-- Кнопка: только склеп
local buildCryptBtn = makeBtn("🏛️  Построить склеп", Color3.fromRGB(40,60,80))
buildCryptBtn.MouseButton1Click:Connect(function()
    if replaceMode then
        removeExistingGraves()
        syncRemoveAll()
        builtModels = {}
    end

    local footPos = getFootPos()
    local list    = getPlayersList()
    local tp      = list[1]
    local pName   = tp and tp.Name or LocalPlayer.Name

    local payload = {
        id         = generateId(),
        graveType  = "crypt",
        origin     = v3t(footPos),
        playerName = pName,
        style      = "crypt",
        owner      = myClientId,
        timestamp  = os.time(),
    }

    local model = buildCrypt(footPos, pName, tp)
    builtModels[payload.id] = model
    syncBuild(payload)

    screenGui:Destroy()
    script:Destroy()
end)

-- Кнопка: удалить все могилы
local clearBtn = makeBtn("🗑️  Удалить все могилы/склепы", Color3.fromRGB(80,25,25))
clearBtn.MouseButton1Click:Connect(function()
    removeExistingGraves()
    syncRemoveAll()
    builtModels = {}
end)

-- Кнопка: закрыть
local closeBtn = makeBtn("✖  Закрыть", Color3.fromRGB(40,40,40), Color3.fromRGB(180,180,180))
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    script:Destroy()
end)

autoCanvas()
print("[GraveBuilder] Готов. ClientId: "..myClientId)
