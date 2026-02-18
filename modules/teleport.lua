--[[
    MODULE: teleport.lua v2.1
    + Sound effects, collection notifications
]]

local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local TCP = shared.TCP
if not TCP or not TCP.Modules then return nil end
local Config=TCP.Modules.Config; local State=TCP.Modules.State
local Engine=TCP.Modules.Engine; local Notify=TCP.Modules.Notify
if not Config or not State or not Engine or not Notify then return nil end
local C = Config.Colors

local Teleport = {}

local disappearedCount = 0
local lastNotify = 0

local function playSound(id, vol)
    if not Config.SoundEnabled then return end
    pcall(function()
        local s = Instance.new("Sound"); s.SoundId="rbxassetid://"..tostring(id)
        s.Volume=vol or 0.3; s.PlayOnRemove=true; s.Parent=SoundService; s:Destroy()
    end)
end

function Teleport.StartHeartbeat()
    State.Connections["TeleportHeartbeat"] = RunService.Heartbeat:Connect(function()
        if not State.IsRunning or not State.IsActive then return end
        if Config.LoopMode and not State.LoopActive then return end
        pcall(function()
            local tp,tcf = Engine.GetTargetPosition()
            for i=#State.PartsToTeleport,1,-1 do
                local part=State.PartsToTeleport[i]
                if not part or not part.Parent then
                    table.remove(State.PartsToTeleport,i)
                    State.Stats.CollectedParts=State.Stats.CollectedParts+1
                    disappearedCount=disappearedCount+1
                else
                    pcall(function()
                        local dp = Config.StackMode and tp or (tp+Vector3.new((i-1)*Config.Spacing,0,0))
                        if Config.SmoothTeleport then
                            local bv=part:FindFirstChild("_TCP_BodyVelocity")
                            if not bv then Engine.PreparePart(part); return end
                            local dir=dp-part.Position; local dist=dir.Magnitude
                            bv.Velocity = dist>0.5 and dir.Unit*math.min(dist*Config.SmoothSpeed/10,Config.SmoothSpeed) or Vector3.zero
                            local bg=part:FindFirstChild("_TCP_BodyGyro"); if bg then bg.CFrame=tcf end
                        else
                            part.CFrame=CFrame.new(dp)
                            part.AssemblyLinearVelocity=Vector3.zero
                            part.AssemblyAngularVelocity=Vector3.zero
                        end
                    end)
                end
            end
            if disappearedCount>0 and (tick()-lastNotify)>3 then
                Notify.Send("📦 +"..disappearedCount.." collected (total: "..State.Stats.CollectedParts..")",C.Success,2.5)
                playSound(Config.Sounds.Collect, 0.15)
                disappearedCount=0; lastNotify=tick()
            end
        end)
    end)
end

function Teleport.StartCollectionLoop()
    task.spawn(function()
        while State.IsRunning do
            if State.IsActive and Config.LoopMode and State.LoopActive then
                local added = Engine.CollectParts()
                if added>0 then
                    Notify.Send("🔄 +"..added.." grabbed (active: "..#State.PartsToTeleport.."/"..Config.MaxParts..")",C.Info,2)
                    playSound(Config.Sounds.Collect, 0.1)
                end
            end
            task.wait(Config.LoopInterval)
        end
    end)
end

return Teleport
