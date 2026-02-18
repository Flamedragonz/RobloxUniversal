--[[
    MODULE: presets.lua
    Сохранение/загрузка настроек
    Зависимости: config, notify
]]

local TCP = shared.TCP
if not TCP or not TCP.Modules then return nil end
local Config = TCP.Modules.Config
local Notify = TCP.Modules.Notify
if not Config then return nil end

local HttpService = game:GetService("HttpService")
local hasFS = (writefile ~= nil and readfile ~= nil and isfile ~= nil)
local SAVE_PATH = "TCP_Presets.json"
local C = Config.Colors

local Presets = {}
Presets.List = {}

function Presets.GetCurrent()
    return {
        FolderPath=Config.FolderPath, PartName=Config.PartName,
        MaxParts=Config.MaxParts, TargetMode=Config.TargetMode,
        TargetPartName=Config.TargetPartName, StackMode=Config.StackMode,
        Spacing=Config.Spacing, Offset={Config.Offset.X,Config.Offset.Y,Config.Offset.Z},
        SmoothTeleport=Config.SmoothTeleport, SmoothSpeed=Config.SmoothSpeed,
        LoopMode=Config.LoopMode, LoopInterval=Config.LoopInterval,
        AnchorOnFinish=Config.AnchorOnFinish, CurrentTheme=Config.CurrentTheme,
    }
end

function Presets.Apply(data)
    if not data then return end
    Config.FolderPath = data.FolderPath or Config.FolderPath
    Config.PartName = data.PartName or ""
    Config.MaxParts = data.MaxParts or 50
    Config.TargetMode = data.TargetMode or "Player"
    Config.TargetPartName = data.TargetPartName or ""
    Config.StackMode = data.StackMode ~= nil and data.StackMode or true
    Config.Spacing = data.Spacing or 2
    Config.SmoothTeleport = data.SmoothTeleport or false
    Config.SmoothSpeed = data.SmoothSpeed or 25
    Config.LoopMode = data.LoopMode ~= nil and data.LoopMode or true
    Config.LoopInterval = data.LoopInterval or 1
    Config.AnchorOnFinish = data.AnchorOnFinish or false
    if data.Offset and type(data.Offset)=="table" then
        Config.Offset = Vector3.new(data.Offset[1] or 0, data.Offset[2] or 0, data.Offset[3] or 0)
    end
    if data.CurrentTheme then Config.ApplyTheme(data.CurrentTheme) end
end

function Presets.SaveToFile()
    if hasFS then pcall(function() writefile(SAVE_PATH, HttpService:JSONEncode(Presets.List)) end) end
end

function Presets.Save(name)
    if not name or name=="" then return false end
    Presets.List[name] = {name=name, data=Presets.GetCurrent(), timestamp=os.time(), gameId=game.PlaceId}
    Presets.SaveToFile()
    if Notify then Notify.Send("💾 Saved: "..name, C.Success) end
    return true
end

function Presets.Load(name)
    local p = Presets.List[name]
    if not p then if Notify then Notify.Send("❌ Not found: "..name, C.Danger) end; return false end
    Presets.Apply(p.data)
    if Notify then Notify.Send("📂 Loaded: "..name, C.Success) end
    return true
end

function Presets.Delete(name)
    if Presets.List[name] then Presets.List[name]=nil; Presets.SaveToFile()
        if Notify then Notify.Send("🗑️ Deleted: "..name, C.Warning) end; return true end
    return false
end

function Presets.GetNames()
    local n={}; for k in pairs(Presets.List) do table.insert(n,k) end; table.sort(n); return n
end

function Presets.AutoSave()
    local an = "_auto_"..tostring(game.PlaceId)
    Presets.List[an] = {name=an, data=Presets.GetCurrent(), timestamp=os.time(), gameId=game.PlaceId}
    Presets.SaveToFile()
end

function Presets.Init()
    if hasFS then pcall(function()
        if isfile(SAVE_PATH) then Presets.List = HttpService:JSONDecode(readfile(SAVE_PATH)) end
    end) end
    local an = "_auto_"..tostring(game.PlaceId)
    if Presets.List[an] then Presets.Apply(Presets.List[an].data) end
end

return Presets
