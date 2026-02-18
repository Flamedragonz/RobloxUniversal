--[[
    ╔══════════════════════════════════════╗
    ║  MODULE: status.lua                  ║
    ║  Обновление статистики в реалтайме   ║
    ║                                      ║
    ║  Зависимости: config, state, utils,  ║
    ║               engine                 ║
    ║                                      ║
    ║  RAW ссылка → loader.lua →           ║
    ║  loadModule("status")                ║
    ╚══════════════════════════════════════╝
]]

local Stats = game:GetService("Stats")

local TCP = getgenv().TCP
local Config = TCP.Modules.Config
local State = TCP.Modules.State
local Utils = TCP.Modules.Utils
local Engine = TCP.Modules.Engine

local C = Config.Colors
local Status = {}

function Status.Start()
    task.spawn(function()
        while State.IsRunning and State.GUI and State.GUI.Parent do
            pcall(function()
                local E = State.UIElements

                -- Ping
                if E.Ping then
                    local ok, ping = pcall(function()
                        return math.round(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
                    end)
                    if ok then
                        E.Ping.Text = ping .. " ms"
                        E.Ping.TextColor3 = ping < 100 and C.Success
                            or (ping < 200 and C.Warning or C.Danger)
                    end
                end

                -- Collected
                if E.Collected then
                    E.Collected.Text = tostring(State.Stats.CollectedParts)
                end

                -- Active
                if E.Active then
                    E.Active.Text = #State.PartsToTeleport .. " / " .. Config.MaxParts
                end

                -- Status card
                if E.StatusLabel then
                    local active = State.IsActive
                    E.StatusLabel.Text = active and "ACTIVE" or "PAUSED"
                    E.StatusLabel.TextColor3 = active and C.Success or C.Warning
                    Utils.Tween(E.StatusDot, {
                        BackgroundColor3 = active and C.Success or C.Warning
                    }, 0.3)
                    if E.StatusStroke then
                        Utils.Tween(E.StatusStroke, {
                            Color = active and C.Success or C.Warning
                        }, 0.3)
                    end
                end

                -- Sub label
                if E.StatusSub then
                    if Config.LoopMode then
                        E.StatusSub.Text = State.LoopActive
                            and "Loop running... (K to stop)"
                            or "Press K to start loop"
                    else
                        E.StatusSub.Text = "Press K to pull once"
                    end
                end

                -- Key hint
                if E.KeyHint then
                    if Config.LoopMode then
                        E.KeyHint.Text = State.LoopActive and "Stop Loop" or "Start Loop"
                    else
                        E.KeyHint.Text = "Pull Once"
                    end
                end

                -- Target
                if E.Target then
                    if Config.TargetMode == "Mouse" then
                        E.Target.Text = "Mouse"
                    else
                        local name = State.CustomTargetPart
                            and State.CustomTargetPart.Name
                            or Config.TargetPartName
                        E.Target.Text = (name == "" and "Player" or name)
                    end
                end

                -- Pulsing dot when loop active
                if State.IsActive and State.LoopActive then
                    local pulse = (math.sin(tick() * 4) + 1) / 2
                    if E.StatusDot then
                        E.StatusDot.BackgroundTransparency = pulse * 0.5
                    end
                else
                    if E.StatusDot then
                        E.StatusDot.BackgroundTransparency = 0
                    end
                end

                -- Selection box
                if Config.TargetMode == "CustomPart" then
                    local t = State.CustomTargetPart or Engine.FindCustomTarget()
                    if t then Engine.UpdateSelectionBox(t) end
                elseif Config.TargetMode == "Player" then
                    Engine.UpdateSelectionBox(nil)
                end
            end)

            task.wait(0.15)
        end
    end)
end

return Status
