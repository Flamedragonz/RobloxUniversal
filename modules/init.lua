--[[
    MODULE: init.lua v2.1
    Initializes all systems including new modules
]]

local TCP = shared.TCP
if not TCP or not TCP.Modules then return nil end

local Config   = TCP.Modules.Config
local Notify   = TCP.Modules.Notify
local Engine   = TCP.Modules.Engine
local Scanner  = TCP.Modules.Scanner
local Presets  = TCP.Modules.Presets
local UI       = TCP.Modules.UI
local Status   = TCP.Modules.Status
local Teleport = TCP.Modules.Teleport
local Input    = TCP.Modules.Input
local Respawn  = TCP.Modules.Respawn
local State    = TCP.Modules.State

local C = Config.Colors

-- 1. Load presets (may auto-load game settings)
if Presets and Presets.Init then Presets.Init() end

-- 2. Build UI
UI.Create()

-- 3. Input
Input.Setup()

-- 4. Respawn
Respawn.Setup()

-- 5. Initial collect
Engine.CollectParts()

-- 6. Start teleport
Teleport.StartHeartbeat()
Teleport.StartCollectionLoop()

-- 7. Status
Status.Start()

-- 8. Auto-save on close
if State.Player then
    State.Player.AncestryChanged:Connect(function()
        if Presets then Presets.AutoSave() end
    end)
end

-- 9. Welcome
task.delay(0.5, function()
    Notify.Send("TCP v2.1 loaded", C.Accent, 4)
    task.wait(0.3)
    Notify.Send("K:Loop P:Hide L:Release J:Pause M:Mini", C.TextSecondary, 5)
end)

return true
