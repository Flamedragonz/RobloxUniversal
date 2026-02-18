--[[
    MODULE: engine.lua v2.1
    + ESP highlights, multi-filter
]]

local Players = game:GetService("Players")
local TCP = shared.TCP
if not TCP or not TCP.Modules then return nil end
local Config = TCP.Modules.Config
local State  = TCP.Modules.State
if not Config or not State then return nil end
local C = Config.Colors

local Engine = {}
Engine.ESP = {Highlights = {}}

-- ===== FOLDER NAV =====
function Engine.GetFolderByPath(path)
    if not path or path=="" or path=="Workspace" then return workspace end
    local cur = workspace
    for seg in string.gmatch(path,"[^/]+") do cur=cur:FindFirstChild(seg); if not cur then return nil end end
    return cur
end

function Engine.FindFoldersByNameGlobal(name)
    if not name or name=="" then return {workspace} end
    local r={}; for _,o in pairs(workspace:GetDescendants()) do
        if o:IsA("Folder") and o.Name==name then table.insert(r,o) end
    end; return r
end

function Engine.IsPlayerPart(part)
    local a=part.Parent; while a do
        if a:IsA("Model") and Players:GetPlayerFromCharacter(a) then return true end; a=a.Parent
    end; return false
end

-- ===== MULTI-FILTER =====
function Engine.MatchesFilter(partName)
    -- Одиночный фильтр
    if Config.PartName and Config.PartName ~= "" then
        return partName == Config.PartName
    end
    -- Мульти-фильтр
    if #Config.PartNames == 0 then return true end
    local found = false
    for _,n in pairs(Config.PartNames) do
        if partName == n then found = true; break end
    end
    return Config.PartNameMode == "include" and found or not found
end

function Engine.GetAllParts(container)
    local p={}
    local items = (container==workspace) and container:GetChildren() or container:GetDescendants()
    for _,d in pairs(items) do
        if d:IsA("BasePart") and not Engine.IsPlayerPart(d) and Engine.MatchesFilter(d.Name) then
            table.insert(p,d)
        end
    end; return p
end

function Engine.FindPartsByName(container, name)
    local p={}
    local items = (container==workspace) and container:GetChildren() or container:GetDescendants()
    for _,d in pairs(items) do
        if d:IsA("BasePart") and d.Name==name and not Engine.IsPlayerPart(d) then table.insert(p,d) end
    end; return p
end

-- ===== PREPARE / RELEASE =====
function Engine.PreparePart(part)
    if part:GetAttribute("_TCP_Prepared") then return end
    pcall(function()
        part.Anchored=false; part.CanCollide=false
        for _,c in pairs(part:GetChildren()) do
            if c:IsA("BodyMover") or c:IsA("Constraint") then c:Destroy() end
        end
        if Config.SmoothTeleport then
            local bv=Instance.new("BodyVelocity"); bv.Name="_TCP_BodyVelocity"
            bv.MaxForce=Vector3.new(math.huge,math.huge,math.huge); bv.Velocity=Vector3.zero; bv.Parent=part
            local bg=Instance.new("BodyGyro"); bg.Name="_TCP_BodyGyro"
            bg.MaxTorque=Vector3.new(math.huge,math.huge,math.huge); bg.P=10000; bg.D=500; bg.Parent=part
        end
        part:SetAttribute("_TCP_Prepared",true)
    end)
end

function Engine.ReleasePart(part)
    if not part or not part.Parent then return end
    pcall(function()
        part:SetAttribute("_TCP_Prepared",nil)
        local bv=part:FindFirstChild("_TCP_BodyVelocity"); if bv then bv:Destroy() end
        local bg=part:FindFirstChild("_TCP_BodyGyro"); if bg then bg:Destroy() end
        part.AssemblyLinearVelocity=Vector3.zero; part.AssemblyAngularVelocity=Vector3.zero
        part.Anchored=Config.AnchorOnFinish; part.CanCollide=true
        -- Remove ESP
        Engine.ESP.RemoveHighlight(part)
    end)
end

function Engine.ReleaseAll()
    for _,p in pairs(State.PartsToTeleport) do Engine.ReleasePart(p) end
    State.PartsToTeleport = {}
end

function Engine.ReprepareParts()
    for _,p in pairs(State.PartsToTeleport) do
        if p and p.Parent then p:SetAttribute("_TCP_Prepared",nil); Engine.PreparePart(p) end
    end
end

-- ===== COLLECT =====
function Engine.CollectParts()
    if not State.IsActive then return 0 end
    if #State.PartsToTeleport >= Config.MaxParts then return 0 end
    local folders = {}
    local exact = Engine.GetFolderByPath(Config.FolderPath)
    if exact then table.insert(folders,exact)
    else
        local name = Config.FolderPath:match("[^/]+$")
        if name then for _,f in pairs(Engine.FindFoldersByNameGlobal(name)) do table.insert(folders,f) end end
    end
    if #folders==0 then return 0 end
    local added=0
    for _,folder in pairs(folders) do
        if #State.PartsToTeleport>=Config.MaxParts then break end
        local candidates
        if Config.PartName and Config.PartName~="" then
            candidates = Engine.FindPartsByName(folder,Config.PartName)
        else
            candidates = Engine.GetAllParts(folder)
        end
        for _,part in pairs(candidates) do
            if #State.PartsToTeleport>=Config.MaxParts then break end
            if not table.find(State.PartsToTeleport,part) and part~=State.CustomTargetPart then
                Engine.PreparePart(part)
                table.insert(State.PartsToTeleport,part)
                Engine.ESP.AddHighlight(part)
                added=added+1
            end
        end
    end
    return added
end

-- ===== TARGET =====
function Engine.FindCustomTarget()
    if Config.TargetPartName=="" then return nil end
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name==Config.TargetPartName then return v end
    end; return nil
end

function Engine.GetTargetPosition()
    local pos,cf = Vector3.zero, CFrame.new()
    if Config.TargetMode=="Mouse" then
        pos=State.Mouse.Hit.Position; cf=CFrame.new(pos)
    elseif Config.TargetMode=="CustomPart" then
        local t=State.CustomTargetPart; if not t or not t.Parent then t=Engine.FindCustomTarget() end
        if t then pos=t.Position; cf=t.CFrame
        elseif State.HumanoidRootPart then pos=State.HumanoidRootPart.Position; cf=State.HumanoidRootPart.CFrame end
    else
        if State.HumanoidRootPart then pos=State.HumanoidRootPart.Position; cf=State.HumanoidRootPart.CFrame end
    end
    return pos+Config.Offset, cf
end

function Engine.UpdateSelectionBox(target)
    if not State.SelectionBox then
        State.SelectionBox=Instance.new("SelectionBox")
        State.SelectionBox.Color3=C.Accent; State.SelectionBox.SurfaceColor3=C.Accent
        State.SelectionBox.LineThickness=0.04; State.SelectionBox.SurfaceTransparency=0.85
        State.SelectionBox.Parent=State.Player.PlayerGui
    end
    State.SelectionBox.Adornee=target
end

-- ===== ESP =====
function Engine.ESP.AddHighlight(part)
    if not Config.ESPEnabled then return end
    if not part or Engine.ESP.Highlights[part] then return end
    local h = Instance.new("Highlight")
    h.Name="_TCP_ESP"; h.FillColor=C.Accent; h.FillTransparency=0.8
    h.OutlineColor=C.AccentGlow; h.OutlineTransparency=0.3; h.Parent=part
    Engine.ESP.Highlights[part] = h
end

function Engine.ESP.RemoveHighlight(part)
    local h = Engine.ESP.Highlights[part]
    if h then pcall(function() h:Destroy() end); Engine.ESP.Highlights[part]=nil end
end

function Engine.ESP.Toggle(enabled)
    Config.ESPEnabled = enabled
    if enabled then
        for _,p in pairs(State.PartsToTeleport) do Engine.ESP.AddHighlight(p) end
    else
        for p,h in pairs(Engine.ESP.Highlights) do pcall(function() h:Destroy() end) end
        Engine.ESP.Highlights = {}
    end
end

function Engine.ESP.Refresh()
    if not Config.ESPEnabled then return end
    for p,h in pairs(Engine.ESP.Highlights) do
        if not p or not p.Parent or not table.find(State.PartsToTeleport,p) then
            pcall(function() h:Destroy() end); Engine.ESP.Highlights[p]=nil
        end
    end
end

return Engine
