--[[
    ╔══════════════════════════════════════╗
    ║  MODULE: engine.lua                  ║
    ║  Движок: поиск, подготовка и         ║
    ║  отпускание партов                   ║
    ║                                      ║
    ║  Зависимости: config, state          ║
    ║                                      ║
    ║  RAW ссылка → loader.lua →           ║
    ║  loadModule("engine")                ║
    ╚══════════════════════════════════════╝
]]

local Players = game:GetService("Players")

local TCP = shared.TCP
local Config = TCP.Modules.Config
local State = TCP.Modules.State

local Engine = {}

-- ========== FOLDER NAVIGATION ==========

function Engine.GetFolderByPath(path)
    if not path or path == "" or path == "Workspace" then
        return workspace
    end
    local current = workspace
    for segment in string.gmatch(path, "[^/]+") do
        current = current:FindFirstChild(segment)
        if not current then return nil end
    end
    return current
end

function Engine.FindFoldersByNameGlobal(folderName)
    if not folderName or folderName == "" then
        return {workspace}
    end
    local found = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Folder") and obj.Name == folderName then
            table.insert(found, obj)
        end
    end
    return found
end

-- ========== PART DETECTION ==========

function Engine.IsPlayerPart(part)
    local ancestor = part.Parent
    while ancestor do
        if ancestor:IsA("Model") and Players:GetPlayerFromCharacter(ancestor) then
            return true
        end
        ancestor = ancestor.Parent
    end
    return false
end

function Engine.GetAllParts(container)
    local parts = {}
    local items = (container == workspace)
        and container:GetChildren()
        or container:GetDescendants()

    for _, desc in pairs(items) do
        if desc:IsA("BasePart") and not Engine.IsPlayerPart(desc) then
            table.insert(parts, desc)
        end
    end
    return parts
end

function Engine.FindPartsByName(container, partName)
    local parts = {}
    local items = (container == workspace)
        and container:GetChildren()
        or container:GetDescendants()

    for _, desc in pairs(items) do
        if desc:IsA("BasePart")
            and desc.Name == partName
            and not Engine.IsPlayerPart(desc) then
            table.insert(parts, desc)
        end
    end
    return parts
end

-- ========== PART PREPARATION ==========

function Engine.PreparePart(part)
    if part:GetAttribute("_TCP_Prepared") then return end

    pcall(function()
        part.Anchored = false
        part.CanCollide = false

        -- Убрать физику
        for _, child in pairs(part:GetChildren()) do
            if child:IsA("BodyMover") or child:IsA("Constraint") then
                child:Destroy()
            end
        end

        -- Если включён Smooth — добавить BodyVelocity/BodyGyro
        if Config.SmoothTeleport then
            local bv = Instance.new("BodyVelocity")
            bv.Name = "_TCP_BodyVelocity"
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.Velocity = Vector3.zero
            bv.Parent = part

            local bg = Instance.new("BodyGyro")
            bg.Name = "_TCP_BodyGyro"
            bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bg.P = 10000
            bg.D = 500
            bg.Parent = part
        end

        part:SetAttribute("_TCP_Prepared", true)
    end)
end

-- ========== RELEASE ==========

function Engine.ReleasePart(part)
    if not part or not part.Parent then return end
    pcall(function()
        part:SetAttribute("_TCP_Prepared", nil)

        local bv = part:FindFirstChild("_TCP_BodyVelocity")
        local bg = part:FindFirstChild("_TCP_BodyGyro")
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end

        part.AssemblyLinearVelocity = Vector3.zero
        part.AssemblyAngularVelocity = Vector3.zero
        part.Anchored = Config.AnchorOnFinish
        part.CanCollide = true
    end)
end

function Engine.ReleaseAll()
    for _, part in pairs(State.PartsToTeleport) do
        Engine.ReleasePart(part)
    end
    State.PartsToTeleport = {}
end

-- ========== COLLECTION ==========

function Engine.CollectParts()
    if not State.IsActive then return 0 end
    if #State.PartsToTeleport >= Config.MaxParts then return 0 end

    -- Найти папки
    local folders = {}
    local exact = Engine.GetFolderByPath(Config.FolderPath)

    if exact then
        table.insert(folders, exact)
    else
        local folderName = Config.FolderPath:match("[^/]+$")
        if folderName then
            for _, f in pairs(Engine.FindFoldersByNameGlobal(folderName)) do
                table.insert(folders, f)
            end
        end
    end

    if #folders == 0 then return 0 end

    local added = 0
    for _, folder in pairs(folders) do
        if #State.PartsToTeleport >= Config.MaxParts then break end

        local candidates
        if Config.PartName and Config.PartName ~= "" then
            candidates = Engine.FindPartsByName(folder, Config.PartName)
        else
            candidates = Engine.GetAllParts(folder)
        end

        for _, part in pairs(candidates) do
            if #State.PartsToTeleport >= Config.MaxParts then break end
            if not table.find(State.PartsToTeleport, part)
                and part ~= State.CustomTargetPart then
                Engine.PreparePart(part)
                table.insert(State.PartsToTeleport, part)
                added = added + 1
            end
        end
    end
    return added
end

-- ========== RE-PREPARE ==========

function Engine.ReprepareParts()
    for _, part in pairs(State.PartsToTeleport) do
        if part and part.Parent then
            part:SetAttribute("_TCP_Prepared", nil)
            Engine.PreparePart(part)
        end
    end
end

-- ========== TARGET ==========

function Engine.FindCustomTarget()
    if Config.TargetPartName == "" then return nil end
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name == Config.TargetPartName then
            return v
        end
    end
    return nil
end

function Engine.GetTargetPosition()
    local pos = Vector3.zero
    local cf = CFrame.new()

    if Config.TargetMode == "Mouse" then
        pos = State.Mouse.Hit.Position
        cf = CFrame.new(pos)

    elseif Config.TargetMode == "CustomPart" then
        local t = State.CustomTargetPart
        if not t or not t.Parent then
            t = Engine.FindCustomTarget()
        end
        if t then
            pos = t.Position
            cf = t.CFrame
        elseif State.HumanoidRootPart then
            pos = State.HumanoidRootPart.Position
            cf = State.HumanoidRootPart.CFrame
        end

    else -- "Player"
        if State.HumanoidRootPart then
            pos = State.HumanoidRootPart.Position
            cf = State.HumanoidRootPart.CFrame
        end
    end

    return pos + Config.Offset, cf
end

-- ========== SELECTION BOX ==========

function Engine.UpdateSelectionBox(target)
    if not State.SelectionBox then
        State.SelectionBox = Instance.new("SelectionBox")
        State.SelectionBox.Color3 = Config.Colors.Accent
        State.SelectionBox.SurfaceColor3 = Config.Colors.Accent
        State.SelectionBox.LineThickness = 0.04
        State.SelectionBox.SurfaceTransparency = 0.85
        State.SelectionBox.Parent = State.Player.PlayerGui
    end
    State.SelectionBox.Adornee = target
end

return Engine
