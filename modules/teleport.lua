--[[
    ╔══════════════════════════════════════╗
    ║  MODULE: teleport.lua                ║
    ║  Heartbeat цикл телепортации         ║
    ║                                      ║
    ║  Зависимости: config, state, engine  ║
    ║                                      ║
    ║  RAW ссылка → loader.lua →           ║
    ║  loadModule("teleport")              ║
    ╚══════════════════════════════════════╝
]]

local RunService = game:GetService("RunService")

local TCP = shared.TCP
local Config = TCP.Modules.Config
local State = TCP.Modules.State
local Engine = TCP.Modules.Engine

local Teleport = {}

-- Главный цикл: перемещает парты каждый кадр
function Teleport.StartHeartbeat()
    State.Connections["TeleportHeartbeat"] = RunService.Heartbeat:Connect(function()
        if not State.IsRunning or not State.IsActive then return end
        if Config.LoopMode and not State.LoopActive then return end

        pcall(function()
            local targetPos, targetCF = Engine.GetTargetPosition()

            for i = #State.PartsToTeleport, 1, -1 do
                local part = State.PartsToTeleport[i]

                if not part or not part.Parent then
                    table.remove(State.PartsToTeleport, i)
                    State.Stats.CollectedParts = State.Stats.CollectedParts + 1
                else
                    pcall(function()
                        local destPos
                        if Config.StackMode then
                            destPos = targetPos
                        else
                            destPos = targetPos + Vector3.new(
                                (i - 1) * Config.Spacing, 0, 0
                            )
                        end

                        if Config.SmoothTeleport then
                            local bv = part:FindFirstChild("_TCP_BodyVelocity")
                            if not bv then
                                Engine.PreparePart(part)
                                return
                            end

                            local direction = destPos - part.Position
                            local dist = direction.Magnitude

                            if dist > 0.5 then
                                local speed = math.min(
                                    dist * Config.SmoothSpeed / 10,
                                    Config.SmoothSpeed
                                )
                                bv.Velocity = direction.Unit * speed
                            else
                                bv.Velocity = Vector3.zero
                            end

                            local bg = part:FindFirstChild("_TCP_BodyGyro")
                            if bg then bg.CFrame = targetCF end
                        else
                            part.CFrame = CFrame.new(destPos)
                            part.AssemblyLinearVelocity = Vector3.zero
                            part.AssemblyAngularVelocity = Vector3.zero
                        end
                    end)
                end
            end
        end)
    end)
end

-- Цикл сбора: периодически подбирает новые парты
function Teleport.StartCollectionLoop()
    task.spawn(function()
        while State.IsRunning do
            if State.IsActive and Config.LoopMode and State.LoopActive then
                Engine.CollectParts()
            end
            task.wait(Config.LoopInterval)
        end
    end)
end

return Teleport
