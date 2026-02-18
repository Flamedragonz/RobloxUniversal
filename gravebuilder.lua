-- ============================================================
-- GRAVE BUILDER + SYNC via jsonbin.io
-- Synapse X / Solara / Velocity / KRNL совместимый
-- ============================================================

-- Сначала все сервисы
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- НАСТРОЙКИ — ВСТАВЬ СЮДА
-- ============================================================
local API_KEY       = "$2a$10$MCM7FTbZMBt2ei7K2jwHI.vGnwQ0M3.l9u6.QEcjL5zuFPViZvA.2"
local BIN_ID        = "6995cf2c43b1c97be988c014"  -- ТОЛЬКО цифробуквенный ID
local SYNC_URL      = "https://api.jsonbin.io/v3/b/" .. BIN_ID
local POLL_INTERVAL = 5

-- ============================================================
-- ОПРЕДЕЛЯЕМ HTTP ФУНКЦИЮ (все исполнители)
-- ============================================================
local httpRequest = nil

-- Synapse X
if not httpRequest then
    local ok, fn = pcall(function() return syn.request end)
    if ok and fn then httpRequest = fn end
end

-- Solara / Delta / новые форки Synapse
if not httpRequest then
    local ok, fn = pcall(function() return request end)
    if ok and fn then httpRequest = fn end
end

-- KRNL
if not httpRequest then
    local ok, fn = pcall(function() return http.request end)
    if ok and fn then httpRequest = fn end
end

-- Velocity (использует fluxus-style)
if not httpRequest then
    local ok, fn = pcall(function() return fluxus.request end)
    if ok and fn then httpRequest = fn end
end

-- getgenv fallback
if not httpRequest then
    local ok, env = pcall(getgenv)
    if ok and env then
        httpRequest = env.syn and env.syn.request
            or env.request
            or env.http_request
            or env.http and env.http.request
    end
end

local syncEnabled = httpRequest ~= nil
print("[GraveSync] HTTP функция найдена: " .. tostring(syncEnabled))
if syncEnabled then
    print("[GraveSync] Используем: " .. tostring(httpRequest))
end

-- ============================================================
-- СОСТОЯНИЕ СИНХРОНИЗАЦИИ
-- ============================================================
local myClientId  = LocalPlayer.Name .. "_" .. tostring(math.random(100000,999999))
local lastVersion = -1
local builtModels = {}   -- {[id] = Model или true}
local localGraves = {}   -- {[id] = payload}
local polling     = false
local pollTimer   = 0

-- ============================================================
-- УТИЛИТЫ
-- ============================================================
local function addCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function addStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color     = color     or Color3.fromRGB(60,60,60)
    s.Thickness = thickness or 1
    s.Parent    = parent
    return s
end

local function makePart(model, name, size, cf, color, material, transparency)
    local p = Instance.new("Part")
    p.Name         = name
    p.Size         = size
    p.CFrame       = cf
    p.Anchored     = true
    p.CanCollide   = false
    p.Color        = color        or Color3.fromRGB(140,140,140)
    p.Material     = material     or Enum.Material.SmoothPlastic
    p.Transparency = transparency or 0
    p.CastShadow   = true
    p.Parent       = model
    return p
end

local function makeWedge(model, name, size, cf, color, material)
    local p = Instance.new("WedgePart")
    p.Name       = name
    p.Size       = size
    p.CFrame     = cf
    p.Anchored   = true
    p.CanCollide = false
    p.Color      = color    or Color3.fromRGB(140,140,140)
    p.Material   = material or Enum.Material.SmoothPlastic
    p.Parent     = model
    return p
end

local function v3t(v) return {x=v.X, y=v.Y, z=v.Z} end
local function tv3(t) return Vector3.new(t.x, t.y, t.z) end

local function generateId()
    return myClientId .. "_" .. tostring(math.floor(os.clock() * 1000))
        .. tostring(math.random(1000,9999))
end

-- Цвета
local stoneC    = Color3.fromRGB(150,145,135)
local darkC     = Color3.fromRGB(85,82,75)
local roofC     = Color3.fromRGB(75,58,45)
local stoneGray = Color3.fromRGB(140,140,140)
local darkGray  = Color3.fromRGB(80,80,80)

-- ============================================================
-- HTTP ЗАПРОСЫ
-- ============================================================
local function doRequest(options)
    if not syncEnabled then return nil end
    local ok, result = pcall(httpRequest, options)
    if not ok then
        warn("[GraveSync] request error: " .. tostring(result))
        return nil
    end
    return result
end

-- ============================================================
-- АВТОИНИЦИАЛИЗАЦИЯ BIN
-- ============================================================
local function initBin()
    -- Проверяем что bin существует и содержит нужную структуру
    local result = doRequest({
        Url    = SYNC_URL .. "/latest",
        Method = "GET",
        Headers = {
            ["X-Master-Key"] = API_KEY,
            ["X-Bin-Meta"]   = "false",
        },
    })

    if not result then
        warn("[GraveSync] initBin: нет ответа")
        return false
    end

    local body = result.Body or result.body or ""
    local code = result.StatusCode or result.status or 0

    -- Bin пустой или повреждён — записываем начальную структуру
    if code == 400 or code == 404 or body == "" or body == "null" or body == "{}" then
        print("[GraveSync] Bin пустой, инициализируем...")

        local initResult = doRequest({
            Url    = SYNC_URL,
            Method = "PUT",
            Headers = {
                ["Content-Type"] = "application/json",
                ["X-Master-Key"] = API_KEY,
            },
            Body = '{"graves":[],"removed":[]}',
        })

        if initResult then
            local ic = initResult.StatusCode or initResult.status or 0
            if ic == 200 then
                print("[GraveSync] ✓ Bin инициализирован!")
                return true
            else
                warn("[GraveSync] initBin PUT failed: " .. ic
                    .. " | " .. tostring(initResult.Body or ""):sub(1,100))
                return false
            end
        end
        return false
    end

    -- Bin есть — проверяем структуру данных
    local ok, parsed = pcall(HttpService.JSONDecode, HttpService, body)
    if ok then
        local data = parsed.record or parsed
        -- Если структура неправильная — чиним
        if type(data) ~= "table" or not data.graves then
            print("[GraveSync] Структура bin неверная, исправляем...")
            doRequest({
                Url    = SYNC_URL,
                Method = "PUT",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["X-Master-Key"] = API_KEY,
                },
                Body = '{"graves":[],"removed":[]}',
            })
        end
    end

    return true
end

-- ============================================================
-- ИСПРАВЛЕННЫЙ fetchGraves
-- ============================================================
local function fetchGraves()
    if not syncEnabled then return nil, nil end

    local result = doRequest({
        Url    = SYNC_URL .. "/latest",
        Method = "GET",
        Headers = {
            ["X-Master-Key"] = API_KEY,
            ["X-Bin-Meta"]   = "false",
        },
    })

    if not result then return nil, nil end

    local body = result.Body or result.body or ""
    local code = result.StatusCode or result.status or 0

    -- Bin пустой — инициализируем и возвращаем пустую структуру
    if code == 400 then
        warn("[GraveSync] fetch 400 — пробуем инициализировать bin...")
        initBin()
        return {graves={}, removed={}}, 0
    end

    if code ~= 200 then
        warn("[GraveSync] fetch HTTP " .. code .. " | " .. tostring(body):sub(1,120))
        return nil, nil
    end

    -- Пустое тело
    if body == "" or body == "null" then
        initBin()
        return {graves={}, removed={}}, 0
    end

    local ok, parsed = pcall(HttpService.JSONDecode, HttpService, body)
    if not ok then
        warn("[GraveSync] JSON decode error: " .. tostring(parsed))
        return nil, nil
    end

    local version = (parsed.metadata and parsed.metadata.version) or 0
    local data    = parsed.record or parsed

    -- Гарантируем структуру
    if type(data) ~= "table" then data = {} end
    data.graves  = data.graves  or {}
    data.removed = data.removed or {}

    return data, version
end

-- ============================================================
-- ИСПРАВЛЕННЫЙ pushGraves — защита от пустых данных
-- ============================================================
local function pushGraves(tbl)
    if not syncEnabled then return false end

    -- Гарантируем что отправляем валидную структуру
    local safeTbl = {
        graves  = tbl.graves  or {},
        removed = tbl.removed or {},
    }

    -- Удаляем дубликаты в removed
    local seen = {}
    local cleanRemoved = {}
    for _, id in ipairs(safeTbl.removed) do
        if not seen[id] then
            seen[id] = true
            table.insert(cleanRemoved, id)
        end
    end
    safeTbl.removed = cleanRemoved

    local ok, body = pcall(HttpService.JSONEncode, HttpService, safeTbl)
    if not ok then
        warn("[GraveSync] JSON encode error: " .. tostring(body))
        return false
    end

    -- Проверка что body не пустой
    if not body or body == "" or body == "null" then
        warn("[GraveSync] encoded body пустой!")
        return false
    end

    local result = doRequest({
        Url    = SYNC_URL,
        Method = "PUT",
        Headers = {
            ["Content-Type"] = "application/json",
            ["X-Master-Key"] = API_KEY,
        },
        Body = body,
    })

    if not result then return false end

    local code = result.StatusCode or result.status or 0
    if code ~= 200 then
        warn("[GraveSync] push HTTP " .. code .. " | "
            .. tostring(result.Body or result.body or ""):sub(1,120))
        return false
    end

    return true
end

-- ============================================================
-- АВАТАР
-- ============================================================
local function cloneAvatarParts(targetPlayer, parentModel)
    local char = targetPlayer and targetPlayer.Character
    if not char then return nil, nil, nil end

    local folder = Instance.new("Model")
    folder.Name  = "AvatarCopy"
    folder.Parent = parentModel

    local bodyNames = {
        "Head","UpperTorso","LowerTorso",
        "LeftUpperArm","LeftLowerArm","LeftHand",
        "RightUpperArm","RightLowerArm","RightHand",
        "LeftUpperLeg","LeftLowerLeg","LeftFoot",
        "RightUpperLeg","RightLowerLeg","RightFoot",
        "Torso","Left Arm","Right Arm","Left Leg","Right Leg",
    }

    local cloned = {}
    for _, nm in ipairs(bodyNames) do
        local p = char:FindFirstChild(nm)
        if p and p:IsA("BasePart") then
            local cl = p:Clone()
            for _, v in ipairs(cl:GetDescendants()) do
                if v:IsA("Script") or v:IsA("LocalScript") or
                   v:IsA("Motor6D") or v:IsA("Weld") or
                   v:IsA("WeldConstraint") or v:IsA("BodyMover") then
                    v:Destroy()
                end
            end
            cl.Anchored   = true
            cl.CanCollide = false
            cl.Parent     = folder
            cloned[nm]    = cl
        end
    end

    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Accessory") then
            local cl = child:Clone()
            local h  = cl:FindFirstChild("Handle")
            if h then
                h.Anchored   = true
                h.CanCollide = false
                for _, v in ipairs(h:GetDescendants()) do
                    if v:IsA("Weld") or v:IsA("WeldConstraint") or
                       v:IsA("Script") or v:IsA("LocalScript") then
                        v:Destroy()
                    end
                end
            end
            cl.Parent = folder
        elseif child:IsA("Shirt") or child:IsA("Pants") or child:IsA("BodyColors") then
            child:Clone().Parent = folder
        end
    end

    return folder, cloned, char
end

local function positionAvatarLying(folder, cloned, originalChar, centerCF)
    local hrp = originalChar:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for partName, cl in pairs(cloned) do
        local orig = originalChar:FindFirstChild(partName)
        if orig then
            cl.CFrame = centerCF * hrp.CFrame:ToObjectSpace(orig.CFrame)
        end
    end
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Accessory") then
            local handle = child:FindFirstChild("Handle")
            local origAcc = nil
            for _, oc in ipairs(originalChar:GetChildren()) do
                if oc:IsA("Accessory") and oc.Name == child.Name then
                    origAcc = oc; break
                end
            end
            if handle and origAcc then
                local oh = origAcc:FindFirstChild("Handle")
                if oh then
                    handle.CFrame = centerCF * hrp.CFrame:ToObjectSpace(oh.CFrame)
                end
            end
        end
    end
end

local function positionHeadAboveGrave(targetPlayer, parentModel, headPos)
    local char = targetPlayer and targetPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end

    local cl = head:Clone()
    for _, v in ipairs(cl:GetDescendants()) do
        if v:IsA("Script") or v:IsA("LocalScript") or
           v:IsA("Motor6D") or v:IsA("Weld") or v:IsA("WeldConstraint") then
            v:Destroy()
        end
    end
    cl.Anchored   = true
    cl.CanCollide = false
    cl.CFrame     = CFrame.new(headPos) * CFrame.Angles(0, math.rad(180), 0)
    cl.Parent     = parentModel

    for _, acc in ipairs(char:GetChildren()) do
        if acc:IsA("Accessory") then
            local oh = acc:FindFirstChild("Handle")
            if oh then
                local accCl = acc:Clone()
                local clH   = accCl:FindFirstChild("Handle")
                if clH then
                    for _, v in ipairs(clH:GetDescendants()) do
                        if v:IsA("Weld") or v:IsA("WeldConstraint") or
                           v:IsA("Script") or v:IsA("LocalScript") then
                            v:Destroy()
                        end
                    end
                    clH.Anchored   = true
                    clH.CanCollide = false
                    clH.CFrame     = cl.CFrame * head.CFrame:ToObjectSpace(oh.CFrame)
                end
                accCl.Parent = parentModel
            end
        end
    end
end

-- ============================================================
-- СТРОИТЕЛИ
-- ============================================================
local function buildGraveModel(origin, style, playerName, targetPlayer)
    local model   = Instance.new("Model")
    model.Name    = "Grave_" .. playerName

    local slab = makePart(model,"Slab", Vector3.new(4,0.25,7),
        CFrame.new(origin+Vector3.new(0,0.125,0)), Color3.fromRGB(75,65,55))

    makePart(model,"Mound", Vector3.new(3.5,0.18,6.5),
        CFrame.new(origin+Vector3.new(0,0.27,0)),
        Color3.fromRGB(65,50,35), Enum.Material.Grass)

    local stoneZ = origin.Z - 2.8

    if style == "rip" then
        local stone = makePart(model,"Gravestone", Vector3.new(2.4,3.2,0.45),
            CFrame.new(Vector3.new(origin.X,origin.Y+1.9,stoneZ)), stoneGray)

        local cap = makePart(model,"Cap", Vector3.new(2.4,0.45,0.45),
            CFrame.new(Vector3.new(origin.X,origin.Y+3.7,stoneZ))
                * CFrame.Angles(0,0,math.rad(90)), stoneGray)
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.Cylinder
        mesh.Parent   = cap

        local sg = Instance.new("SurfaceGui")
        sg.Face          = Enum.NormalId.Back
        sg.SizingMode    = Enum.SurfaceGuiSizingMode.PixelsPerStud
        sg.PixelsPerStud = 60
        sg.Parent        = stone

        local lbl = Instance.new("TextLabel")
        lbl.Size               = UDim2.new(1,0,1,0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3         = Color3.fromRGB(30,30,30)
        lbl.Text               = "R.I.P\n" .. playerName
        lbl.Font               = Enum.Font.GothamBold
        lbl.TextScaled         = true
        lbl.Parent             = sg

    elseif style == "cross" then
        makePart(model,"CrossV", Vector3.new(0.35,4.2,0.35),
            CFrame.new(Vector3.new(origin.X,origin.Y+2.4,stoneZ)), darkGray)
        makePart(model,"CrossH", Vector3.new(2.2,0.35,0.35),
            CFrame.new(Vector3.new(origin.X,origin.Y+3.4,stoneZ)), darkGray)
        makePart(model,"CrossBase", Vector3.new(1.0,0.25,0.6),
            CFrame.new(Vector3.new(origin.X,origin.Y+0.38,stoneZ)), darkGray)
    end

    if targetPlayer then
        positionHeadAboveGrave(targetPlayer, model,
            Vector3.new(origin.X, origin.Y+1.6, origin.Z+1.0))
    end

    model.PrimaryPart = slab
    model.Parent      = workspace
    return model
end

local function buildCrypt(origin, playerName, targetPlayer)
    local model = Instance.new("Model")
    model.Name  = "Crypt_" .. playerName
    local w,d,h = 9,13,6

    makePart(model,"Floor",     Vector3.new(w,0.3,d),
        CFrame.new(origin+Vector3.new(0,0.15,0)), stoneC)
    makePart(model,"WallBack",  Vector3.new(w,h,0.5),
        CFrame.new(origin+Vector3.new(0,h/2,-d/2)), stoneC)
    makePart(model,"WallLeft",  Vector3.new(0.5,h,d),
        CFrame.new(origin+Vector3.new(-w/2,h/2,0)), stoneC)
    makePart(model,"WallRight", Vector3.new(0.5,h,d),
        CFrame.new(origin+Vector3.new(w/2,h/2,0)), stoneC)
    makePart(model,"WallFrontL",Vector3.new(2.8,h,0.5),
        CFrame.new(origin+Vector3.new(-(w/2)+1.4,h/2,d/2)), stoneC)
    makePart(model,"WallFrontR",Vector3.new(2.8,h,0.5),
        CFrame.new(origin+Vector3.new((w/2)-1.4,h/2,d/2)), stoneC)
    makePart(model,"DoorLintel",Vector3.new(3.4,1.5,0.5),
        CFrame.new(origin+Vector3.new(0,h-0.75,d/2)), stoneC)
    makePart(model,"Roof",      Vector3.new(w+0.8,0.4,d+0.8),
        CFrame.new(origin+Vector3.new(0,h+0.2,0)), darkC)

    local pedH = 1.6
    local ped  = makeWedge(model,"Pediment", Vector3.new(w+0.8,pedH,2.5),
        CFrame.new(origin+Vector3.new(0,h+pedH/2+0.4,d/2+1.25))
            * CFrame.Angles(0,math.rad(180),0), stoneC)

    local sg = Instance.new("SurfaceGui")
    sg.Face          = Enum.NormalId.Front
    sg.SizingMode    = Enum.SurfaceGuiSizingMode.PixelsPerStud
    sg.PixelsPerStud = 35
    sg.Parent        = ped

    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3         = Color3.fromRGB(20,20,20)
    lbl.Text               = playerName
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextScaled         = true
    lbl.Parent             = sg

    makePart(model,"RoofCrossV",Vector3.new(0.3,2.5,0.3),
        CFrame.new(origin+Vector3.new(0,h+1.65,0)), darkGray)
    makePart(model,"RoofCrossH",Vector3.new(1.4,0.3,0.3),
        CFrame.new(origin+Vector3.new(0,h+2.5,0)), darkGray)

    for _, xOff in ipairs({-1.4, 1.4}) do
        makePart(model,"Column",Vector3.new(0.5,h,0.5),
            CFrame.new(origin+Vector3.new(xOff,h/2,d/2)), stoneC)
    end

    local sarcZ = -d/2 + 4.5
    makePart(model,"SarcBase",Vector3.new(2.6,0.7,6),
        CFrame.new(origin+Vector3.new(0,0.65,sarcZ)),
        Color3.fromRGB(160,155,145))
    makePart(model,"SarcLid", Vector3.new(2.4,0.28,5.8),
        CFrame.new(origin+Vector3.new(0,1.04,sarcZ)),
        Color3.fromRGB(175,170,160))

    if targetPlayer and targetPlayer.Character then
        local folder, cloned, origChar = cloneAvatarParts(targetPlayer, model)
        if folder and cloned then
            local centerCF = CFrame.new(origin+Vector3.new(0,1.4,sarcZ))
                * CFrame.Angles(math.rad(-90), math.rad(180), 0)
            positionAvatarLying(folder, cloned, origChar, centerCF)
        end
    end

    model.PrimaryPart = model:FindFirstChild("Floor")
    model.Parent      = workspace
    return model
end

local function buildChapel(origin)
    local model = Instance.new("Model")
    model.Name  = "Chapel"
    local w,d,h = 11,16,8

    makePart(model,"Foundation",Vector3.new(w+1.5,0.6,d+1.5),
        CFrame.new(origin+Vector3.new(0,0.3,0)), Color3.fromRGB(100,95,85))
    makePart(model,"WallBack",  Vector3.new(w,h,0.55),
        CFrame.new(origin+Vector3.new(0,h/2,-d/2)), stoneC)
    makePart(model,"WallLeft",  Vector3.new(0.55,h,d),
        CFrame.new(origin+Vector3.new(-w/2,h/2,0)), stoneC)
    makePart(model,"WallRight", Vector3.new(0.55,h,d),
        CFrame.new(origin+Vector3.new(w/2,h/2,0)), stoneC)

    local doorW = 3.5
    local sideW = (w-doorW)/2
    makePart(model,"WallFrontL",Vector3.new(sideW,h,0.55),
        CFrame.new(origin+Vector3.new(-(doorW/2+sideW/2),h/2,d/2)), stoneC)
    makePart(model,"WallFrontR",Vector3.new(sideW,h,0.55),
        CFrame.new(origin+Vector3.new( (doorW/2+sideW/2),h/2,d/2)), stoneC)
    makePart(model,"DoorLintel",Vector3.new(doorW,h-5.5,0.55),
        CFrame.new(origin+Vector3.new(0,5.5+(h-5.5)/2,d/2)), stoneC)

    local rH = 3.5
    makeWedge(model,"RoofBack", Vector3.new(w+1,rH,d/2+0.5),
        CFrame.new(origin+Vector3.new(0,h+rH/2,-d/4))
            * CFrame.Angles(0,math.rad(180),0), roofC)
    makeWedge(model,"RoofFront",Vector3.new(w+1,rH,d/2+0.5),
        CFrame.new(origin+Vector3.new(0,h+rH/2,d/4)), roofC)

    local tW     = 4; local tH = 13
    local towerX = origin.X + w/2 + tW/2 + 0.2
    local towerZ = origin.Z + d/2 - tW/2 - 1

    makePart(model,"TowerBase", Vector3.new(tW,tH,tW),
        CFrame.new(Vector3.new(towerX,origin.Y+tH/2,towerZ)), stoneC)
    makePart(model,"BellFloor", Vector3.new(tW,0.3,tW),
        CFrame.new(Vector3.new(towerX,origin.Y+tH+0.15,towerZ)), stoneC)

    local spireH = 4
    makeWedge(model,"SpireF",Vector3.new(tW,spireH,tW/2),
        CFrame.new(Vector3.new(towerX,origin.Y+tH+spireH/2,towerZ-tW/4)), roofC)
    makeWedge(model,"SpireB",Vector3.new(tW,spireH,tW/2),
        CFrame.new(Vector3.new(towerX,origin.Y+tH+spireH/2,towerZ+tW/4))
            * CFrame.Angles(0,math.rad(180),0), roofC)

    makePart(model,"TowerCrossV",Vector3.new(0.3,2.8,0.3),
        CFrame.new(Vector3.new(towerX,origin.Y+tH+spireH+1.6,towerZ)), darkGray)
    makePart(model,"TowerCrossH",Vector3.new(1.6,0.3,0.3),
        CFrame.new(Vector3.new(towerX,origin.Y+tH+spireH+2.4,towerZ)), darkGray)

    local fW=w+10; local fD=d+10; local fH=1.3
    local fC=Color3.fromRGB(55,48,40)
    makePart(model,"FenceBack",  Vector3.new(fW,fH,0.2), CFrame.new(origin+Vector3.new(0,fH/2,-fD/2)), fC)
    makePart(model,"FenceFront", Vector3.new(fW,fH,0.2), CFrame.new(origin+Vector3.new(0,fH/2, fD/2)), fC)
    makePart(model,"FenceLeft",  Vector3.new(0.2,fH,fD), CFrame.new(origin+Vector3.new(-fW/2,fH/2,0)), fC)
    makePart(model,"FenceRight", Vector3.new(0.2,fH,fD), CFrame.new(origin+Vector3.new( fW/2,fH/2,0)), fC)
    for i=0,9 do
        local xp = -fW/2 + (i/9)*fW
        makePart(model,"SpikeF"..i,Vector3.new(0.14,0.45,0.14),
            CFrame.new(origin+Vector3.new(xp,fH+0.22, fD/2)), darkGray)
        makePart(model,"SpikeB"..i,Vector3.new(0.14,0.45,0.14),
            CFrame.new(origin+Vector3.new(xp,fH+0.22,-fD/2)), darkGray)
    end

    model.Parent = workspace
    return model
end

local function buildCemetery(origin, playersList)
    local offsets = {
        Vector3.new(-6,0,-5), Vector3.new(0,0,-5), Vector3.new(6,0,-5),
        Vector3.new(-6,0, 3), Vector3.new(0,0, 3), Vector3.new(6,0, 3),
    }
    local gStyles = {"rip","cross","rip","cross","rip","cross"}
    for i, offset in ipairs(offsets) do
        local tp    = playersList[i]
        local pName = tp and tp.Name or ("Soul_"..i)
        buildGraveModel(origin+offset, gStyles[i], pName, tp)
    end
    buildChapel(origin+Vector3.new(0,0,-22))
end

local function removeExistingGraves()
    for _, v in ipairs(workspace:GetChildren()) do
        if v:IsA("Model") and (
            v.Name:sub(1,6)=="Grave_" or
            v.Name:sub(1,6)=="Crypt_" or
            v.Name=="Chapel" or v.Name=="Cemetery"
        ) then v:Destroy() end
    end
end

-- ============================================================
-- BUILD FROM PAYLOAD (от других клиентов)
-- !! Объявлена ДО polling и GUI !!
-- ============================================================
local function buildFromPayload(payload)
    if not payload or not payload.id then return end
    if builtModels[payload.id] then return end

    local origin = tv3(payload.origin)
    local pName  = payload.playerName or "Unknown"
    local style  = payload.style      or "rip"
    local tp     = Players:FindFirstChild(pName)
    local model  = nil

    if payload.graveType == "grave" then
        model = buildGraveModel(origin, style, pName, tp)
    elseif payload.graveType == "crypt" then
        model = buildCrypt(origin, pName, tp)
    elseif payload.graveType == "cemetery" then
        local list = {}
        for _, nm in ipairs(payload.playerNames or {}) do
            local p = Players:FindFirstChild(nm)
            table.insert(list, p or {Name=nm, Character=nil})
        end
        buildCemetery(origin, list)
        builtModels[payload.id] = true
        return
    end

    if model then
        builtModels[payload.id] = model
        print("[GraveSync] Построено от " .. tostring(payload.owner) .. ": " .. pName)
    end
end

-- ============================================================
-- SYNC ФУНКЦИИ
-- ============================================================
local function syncBuild(payload)
    if not syncEnabled then return end
    payload.owner = myClientId
    task.spawn(function()
        local data = fetchGraves()
        if not data then data = {graves={},removed={}} end
        data.graves  = data.graves  or {}
        data.removed = data.removed or {}
        table.insert(data.graves, payload)
        localGraves[payload.id] = payload
        local ok = pushGraves(data)
        if ok then
            print("[GraveSync] ✓ Отправлено: " .. payload.playerName)
        end
    end)
end

local function syncRemoveAll()
    if not syncEnabled then return end
    task.spawn(function()
        local data = fetchGraves()
        if not data then return end
        data.graves  = data.graves  or {}
        data.removed = data.removed or {}
        local myIds  = {}
        for id,_ in pairs(localGraves) do myIds[id]=true end
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

-- ============================================================
-- POLLING
-- ============================================================
RunService.Heartbeat:Connect(function(dt)
    if not syncEnabled then return end
    pollTimer = pollTimer + dt
    if pollTimer < POLL_INTERVAL then return end
    if polling then return end
    pollTimer = 0
    polling   = true

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

-- Стартовая синхронизация
task.delay(3, function()
    if not syncEnabled then
        warn("[GraveSync] HTTP недоступен")
        return
    end

    -- Сначала инициализируем bin
    print("[GraveSync] Инициализация bin...")
    initBin()

    task.wait(1)  -- ждём пока запись применится

    local data, version = fetchGraves()
    if not data then
        warn("[GraveSync] Не удалось получить данные при старте")
        return
    end

    lastVersion = version or -1
    local count = 0

    for _, payload in ipairs(data.graves or {}) do
        if payload.owner ~= myClientId then
            local ok, err = pcall(buildFromPayload, payload)
            if not ok then
                warn("[GraveSync] buildFromPayload error: " .. tostring(err))
            else
                count = count + 1
            end
        end
    end

    print("[GraveSync] ✓ Старт синхронизация: " .. count .. " могил загружено")
end)

-- ============================================================
-- GUI
-- ============================================================
-- Удаляем старый GUI если есть
local oldGui = LocalPlayer.PlayerGui:FindFirstChild("GraveBuilder")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "GraveBuilder"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = LocalPlayer.PlayerGui

local frame = Instance.new("Frame")
frame.Size             = UDim2.new(0,380,0,620)
frame.Position         = UDim2.new(0.5,-190,0.5,-310)
frame.BackgroundColor3 = Color3.fromRGB(22,22,22)
frame.BorderSizePixel  = 0
frame.Parent           = screenGui
addCorner(frame,12)
addStroke(frame, Color3.fromRGB(55,55,55), 1.5)

-- Drag
local dragging,dragStart,startPos = false,nil,nil
frame.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging=true; dragStart=inp.Position; startPos=frame.Position
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
titleBar.Size             = UDim2.new(1,0,0,44)
titleBar.BackgroundColor3 = Color3.fromRGB(15,15,15)
titleBar.BorderSizePixel  = 0
titleBar.Parent           = frame
addCorner(titleBar,12)

local titleLbl = Instance.new("TextLabel")
titleLbl.Size                 = UDim2.new(1,-90,1,0)
titleLbl.Position             = UDim2.new(0,10,0,0)
titleLbl.BackgroundTransparency = 1
titleLbl.TextColor3           = Color3.fromRGB(220,220,220)
titleLbl.Text                 = "⚰️  Grave Builder"
titleLbl.Font                 = Enum.Font.GothamBold
titleLbl.TextSize             = 18
titleLbl.TextXAlignment       = Enum.TextXAlignment.Left
titleLbl.Parent               = titleBar

-- Индикатор синхронизации
local syncDot = Instance.new("TextLabel")
syncDot.Size                 = UDim2.new(0,80,0,16)
syncDot.Position             = UDim2.new(1,-86,0,14)
syncDot.BackgroundTransparency = 1
syncDot.TextColor3           = syncEnabled
    and Color3.fromRGB(100,220,100)
    or  Color3.fromRGB(220,80,80)
syncDot.Text                 = syncEnabled and "● SYNC ON" or "● NO HTTP"
syncDot.Font                 = Enum.Font.GothamBold
syncDot.TextSize             = 9
syncDot.TextXAlignment       = Enum.TextXAlignment.Right
syncDot.Parent               = titleBar

if syncEnabled then
    local dt2 = 0
    RunService.Heartbeat:Connect(function(dt)
        dt2 = dt2 + dt
        if dt2 > 1 then dt2 = 0 end
        if syncDot and syncDot.Parent then
            syncDot.TextTransparency = (dt2 > 0.5) and 0.5 or 0
        end
    end)
end

-- Scroll
local scroll = Instance.new("ScrollingFrame")
scroll.Size                  = UDim2.new(1,0,1,-44)
scroll.Position              = UDim2.new(0,0,0,44)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel        = 0
scroll.ScrollBarThickness     = 4
scroll.ScrollBarImageColor3   = Color3.fromRGB(90,90,90)
scroll.CanvasSize             = UDim2.new(0,0,0,0)
scroll.Parent                 = frame

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
    l.Size                  = UDim2.new(1,0,0,20)
    l.BackgroundTransparency = 1
    l.TextColor3            = Color3.fromRGB(140,140,140)
    l.Text                  = txt
    l.Font                  = Enum.Font.GothamBold
    l.TextSize              = 11
    l.TextXAlignment        = Enum.TextXAlignment.Left
    l.Parent                = scroll
    return l
end

local function makeBtn(text, bgColor, textColor)
    local orig = bgColor or Color3.fromRGB(55,55,55)
    local btn  = Instance.new("TextButton")
    btn.Size             = UDim2.new(1,0,0,34)
    btn.BackgroundColor3 = orig
    btn.TextColor3       = textColor or Color3.fromRGB(220,220,220)
    btn.Text             = text
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 13
    btn.AutoButtonColor  = false
    btn.Parent           = scroll
    addCorner(btn,6)
    addStroke(btn, Color3.fromRGB(70,70,70))
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = orig:Lerp(Color3.fromRGB(255,255,255),0.1)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = orig
    end)
    return btn
end

-- ── Список игроков ─────────────────────────────
makeSection("👥  Игроки на сервере:")

local playerScroll = Instance.new("ScrollingFrame")
playerScroll.Size                  = UDim2.new(1,0,0,110)
playerScroll.BackgroundColor3      = Color3.fromRGB(30,30,30)
playerScroll.BorderSizePixel       = 0
playerScroll.ScrollBarThickness    = 3
playerScroll.ScrollBarImageColor3  = Color3.fromRGB(80,80,80)
playerScroll.CanvasSize            = UDim2.new(0,0,0,0)
playerScroll.Parent                = scroll
addCorner(playerScroll,6)

local plLayout = Instance.new("UIListLayout")
plLayout.Padding = UDim.new(0,3)
plLayout.Parent  = playerScroll

local plPad = Instance.new("UIPadding")
plPad.PaddingTop   = UDim.new(0,4)
plPad.PaddingLeft  = UDim.new(0,4)
plPad.PaddingRight = UDim.new(0,4)
plPad.Parent       = playerScroll

local selectedPlayers = {}
local playerBtns      = {}

local multiLabel = Instance.new("TextLabel")
multiLabel.Size                  = UDim2.new(1,0,0,18)
multiLabel.BackgroundTransparency = 1
multiLabel.TextColor3            = Color3.fromRGB(120,200,120)
multiLabel.Text                  = "Выбрано: никого"
multiLabel.Font                  = Enum.Font.Gotham
multiLabel.TextSize              = 11
multiLabel.TextXAlignment        = Enum.TextXAlignment.Left
multiLabel.Parent                = scroll

local function updateMultiLabel()
    local names = {}
    for key, val in pairs(selectedPlayers) do
        if type(key) == "userdata" then
            table.insert(names, key.Name)
        elseif type(key) == "string" and key:sub(1,10) == "__offline__" then
            table.insert(names, val.Name .. "✍")
        end
    end
    multiLabel.Text = #names == 0
        and "Выбрано: никого"
        or  "Выбрано (" .. #names .. "): " .. table.concat(names, ", ")
end

local function refreshPlayerList()
    for _, b in ipairs(playerBtns) do
        if b and b.Parent then b:Destroy() end
    end
    playerBtns = {}

    for _, plr in ipairs(Players:GetPlayers()) do
        local btn = Instance.new("TextButton")
        btn.Size             = UDim2.new(1,-8,0,24)
        btn.BackgroundColor3 = selectedPlayers[plr]
            and Color3.fromRGB(55,95,55) or Color3.fromRGB(45,45,48)
        btn.TextColor3       = Color3.fromRGB(200,200,200)
        btn.Text             = "  " .. plr.Name
        btn.Font             = Enum.Font.Gotham
        btn.TextSize         = 12
        btn.TextXAlignment   = Enum.TextXAlignment.Left
        btn.AutoButtonColor  = false
        btn.Parent           = playerScroll
        addCorner(btn,4)

        btn.MouseButton1Click:Connect(function()
            if selectedPlayers[plr] then
                selectedPlayers[plr] = nil
                btn.BackgroundColor3 = Color3.fromRGB(45,45,48)
            else
                selectedPlayers[plr] = true
                btn.BackgroundColor3 = Color3.fromRGB(55,95,55)
            end
            updateMultiLabel()
        end)
        table.insert(playerBtns, btn)
    end

    playerScroll.CanvasSize = UDim2.new(0,0,0, plLayout.AbsoluteContentSize.Y+8)
end

refreshPlayerList()
plLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    playerScroll.CanvasSize = UDim2.new(0,0,0, plLayout.AbsoluteContentSize.Y+8)
end)

local refreshBtn = makeBtn("🔄  Обновить список", Color3.fromRGB(40,40,60))
refreshBtn.MouseButton1Click:Connect(function()
    selectedPlayers = {}
    refreshPlayerList()
    updateMultiLabel()
end)

-- ── Ввод вручную ───────────────────────────────
makeSection("✍️  Имя вручную (офлайн):")

local manualInput = Instance.new("TextBox")
manualInput.Size              = UDim2.new(1,0,0,32)
manualInput.BackgroundColor3  = Color3.fromRGB(38,38,38)
manualInput.TextColor3        = Color3.fromRGB(255,255,255)
manualInput.PlaceholderText   = "Имя игрока..."
manualInput.PlaceholderColor3 = Color3.fromRGB(90,90,90)
manualInput.Text              = ""
manualInput.Font              = Enum.Font.Gotham
manualInput.TextSize          = 13
manualInput.ClearTextOnFocus  = false
manualInput.Parent            = scroll
addCorner(manualInput,6)
addStroke(manualInput, Color3.fromRGB(60,60,70))

local addManualBtn = makeBtn("➕  Добавить в выбор", Color3.fromRGB(40,60,80))
addManualBtn.MouseButton1Click:Connect(function()
    local name = (manualInput.Text or ""):match("^%s*(.-)%s*$")
    if not name or name == "" then return end

    local online = Players:FindFirstChild(name)
    if online then
        selectedPlayers[online] = true
        refreshPlayerList()
    else
        local key = "__offline__" .. name
        if not selectedPlayers[key] then
            selectedPlayers[key] = {Name=name, Character=nil}
            local lbl2 = Instance.new("TextLabel")
            lbl2.Size             = UDim2.new(1,-8,0,24)
            lbl2.BackgroundColor3 = Color3.fromRGB(60,50,30)
            lbl2.TextColor3       = Color3.fromRGB(220,200,150)
            lbl2.Text             = "  ✍ " .. name .. " (офлайн)"
            lbl2.Font             = Enum.Font.Gotham
            lbl2.TextSize         = 12
            lbl2.TextXAlignment   = Enum.TextXAlignment.Left
            lbl2.Parent           = playerScroll
            addCorner(lbl2,4)
            table.insert(playerBtns, lbl2)
            playerScroll.CanvasSize = UDim2.new(0,0,0, plLayout.AbsoluteContentSize.Y+8)
        end
    end
    updateMultiLabel()
    manualInput.Text = ""
end)

-- ── Тип могилы ─────────────────────────────────
makeSection("🪦  Тип могилы:")

local styles      = {"RIP камень","Крест","Склеп"}
local styleColors = {
    Color3.fromRGB(55,55,85),
    Color3.fromRGB(75,45,45),
    Color3.fromRGB(45,65,45),
}
local currentStyleIndex = 1

local styleBtn = makeBtn("▶  " .. styles[1], styleColors[1])
styleBtn.MouseButton1Click:Connect(function()
    currentStyleIndex = (currentStyleIndex % #styles) + 1
    styleBtn.Text             = "▶  " .. styles[currentStyleIndex]
    styleBtn.BackgroundColor3 = styleColors[currentStyleIndex]
end)

-- ── Режим размещения ───────────────────────────
makeSection("♻️  Режим размещения:")

local replaceMode    = false
local replaceModeBtn = makeBtn("▶  Добавить рядом", Color3.fromRGB(50,50,50))
replaceModeBtn.MouseButton1Click:Connect(function()
    replaceMode = not replaceMode
    replaceModeBtn.Text             = replaceMode
        and "▶  Заменить существующие"
        or  "▶  Добавить рядом"
    replaceModeBtn.BackgroundColor3 = replaceMode
        and Color3.fromRGB(90,50,20)
        or  Color3.fromRGB(50,50,50)
end)

-- ── Действия ───────────────────────────────────
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

local function doCleanup()
    screenGui:Destroy()
    pcall(function() script:Destroy() end)
end

-- Одиночная могила
local buildSingleBtn = makeBtn("⚰️  Построить могилу", Color3.fromRGB(55,130,55))
buildSingleBtn.MouseButton1Click:Connect(function()
    if replaceMode then removeExistingGraves(); syncRemoveAll(); builtModels={} end

    local footPos  = getFootPos()
    local styleKey = ({"rip","cross","crypt"})[currentStyleIndex]
    local list     = getPlayersList()
    local tp       = list[1]
    local pName    = tp and tp.Name or LocalPlayer.Name

    local payload = {
        id        = generateId(),
        graveType = (styleKey=="crypt") and "crypt" or "grave",
        origin    = v3t(footPos),
        playerName = pName,
        style     = styleKey,
        owner     = myClientId,
        timestamp = os.time(),
    }

    local model
    if styleKey == "crypt" then
        model = buildCrypt(footPos, pName, tp)
    else
        model = buildGraveModel(footPos, styleKey, pName, tp)
    end
    builtModels[payload.id] = model
    syncBuild(payload)
    doCleanup()
end)

-- Кладбище + часовня
local buildCemeteryBtn = makeBtn("🏚️  Кладбище + Часовня", Color3.fromRGB(100,65,30))
buildCemeteryBtn.MouseButton1Click:Connect(function()
    if replaceMode then removeExistingGraves(); syncRemoveAll(); builtModels={} end

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
    doCleanup()
end)

-- Склеп
local buildCryptBtn = makeBtn("🏛️  Построить склеп", Color3.fromRGB(40,60,80))
buildCryptBtn.MouseButton1Click:Connect(function()
    if replaceMode then removeExistingGraves(); syncRemoveAll(); builtModels={} end

    local footPos = getFootPos()
    local list    = getPlayersList()
    local tp      = list[1]
    local pName   = tp and tp.Name or LocalPlayer.Name

    local payload = {
        id        = generateId(),
        graveType = "crypt",
        origin    = v3t(footPos),
        playerName = pName,
        style     = "crypt",
        owner     = myClientId,
        timestamp = os.time(),
    }
    local model = buildCrypt(footPos, pName, tp)
    builtModels[payload.id] = model
    syncBuild(payload)
    doCleanup()
end)

-- Удалить всё
local clearBtn = makeBtn("🗑️  Удалить все могилы", Color3.fromRGB(80,25,25))
clearBtn.MouseButton1Click:Connect(function()
    removeExistingGraves()
    syncRemoveAll()
    builtModels = {}
end)

-- Закрыть
local closeBtn = makeBtn("✖  Закрыть", Color3.fromRGB(40,40,40), Color3.fromRGB(180,180,180))
closeBtn.MouseButton1Click:Connect(function()
    doCleanup()
end)

autoCanvas()
print("[GraveBuilder] ✓ Готов. ClientId: " .. myClientId)
print("[GraveBuilder] Synapse X: syn.request = " .. tostring(syncEnabled))
