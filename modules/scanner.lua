--[[
    MODULE: scanner.lua
    Сканирование workspace
    Зависимости: config, state
]]

local Players = game:GetService("Players")

local TCP = shared.TCP
if not TCP or not TCP.Modules then return nil end
local Config = TCP.Modules.Config
local State  = TCP.Modules.State
if not Config or not State then return nil end

local Scanner = {}

function Scanner.IsPlayerPart(part)
    local a = part.Parent
    while a do
        if a:IsA("Model") and Players:GetPlayerFromCharacter(a) then return true end
        a = a.Parent
    end
    return false
end

function Scanner.FindFoldersWithParts(maxDepth)
    maxDepth = maxDepth or 4
    local results = {}

    local function scan(parent, depth, path)
        if depth > maxDepth then return end
        for _, child in pairs(parent:GetChildren()) do
            if child:IsA("Folder") or (child:IsA("Model") and not Players:GetPlayerFromCharacter(child)) then
                local count = 0
                local names = {}
                for _, d in pairs(child:GetDescendants()) do
                    if d:IsA("BasePart") and not Scanner.IsPlayerPart(d) then
                        count = count + 1
                        names[d.Name] = (names[d.Name] or 0) + 1
                    end
                end
                if count > 0 then
                    local cp = path == "" and child.Name or (path.."/"..child.Name)
                    table.insert(results, {
                        name = child.Name, path = cp, partCount = count,
                        uniqueNames = names, depth = depth,
                    })
                end
                scan(child, depth + 1, path == "" and child.Name or (path.."/"..child.Name))
            end
        end
    end

    scan(workspace, 1, "")
    table.sort(results, function(a,b) return a.partCount > b.partCount end)
    return results
end

function Scanner.GetUniquePartNames(folderPath)
    folderPath = folderPath or Config.FolderPath
    local current = workspace
    if folderPath and folderPath ~= "" then
        for seg in string.gmatch(folderPath, "[^/]+") do
            current = current:FindFirstChild(seg)
            if not current then return {} end
        end
    end

    local names = {}
    local items = (current == workspace) and current:GetChildren() or current:GetDescendants()
    for _, d in pairs(items) do
        if d:IsA("BasePart") and not Scanner.IsPlayerPart(d) then
            names[d.Name] = (names[d.Name] or 0) + 1
        end
    end
    return names
end

function Scanner.GetWorkspaceStats()
    local p,m,f = 0,0,0
    for _, d in pairs(workspace:GetDescendants()) do
        if d:IsA("BasePart") then p=p+1
        elseif d:IsA("Model") then m=m+1
        elseif d:IsA("Folder") then f=f+1 end
    end
    return {parts=p, models=m, folders=f}
end

return Scanner
