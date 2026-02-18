--[[
    MODULE: status.lua v2.1
    + Uptime, Rate, ESP refresh
]]

local Stats = game:GetService("Stats")
local TCP = shared.TCP
if not TCP or not TCP.Modules then return nil end
local Config=TCP.Modules.Config; local State=TCP.Modules.State
local Utils=TCP.Modules.Utils; local Engine=TCP.Modules.Engine
if not Config or not State or not Utils or not Engine then return nil end
local C = Config.Colors

local Status = {}

function Status.Start()
    task.spawn(function()
        while State.IsRunning and State.GUI and State.GUI.Parent do
            pcall(function()
                local E = State.UIElements

                -- Ping
                if E.Ping then
                    local ok,p = pcall(function() return math.round(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
                    if ok then E.Ping.Text=p.." ms"
                        E.Ping.TextColor3 = p<100 and C.Success or (p<200 and C.Warning or C.Danger)
                    end
                end

                if E.Collected then E.Collected.Text=tostring(State.Stats.CollectedParts) end
                if E.Active then E.Active.Text=#State.PartsToTeleport.." / "..Config.MaxParts end

                -- Uptime
                if E.Uptime then
                    local el = tick()-State.Stats.StartTime
                    E.Uptime.Text = string.format("%02d:%02d",math.floor(el/60),math.floor(el%60))
                end

                -- Rate
                if E.Rate then
                    local el = tick()-State.Stats.StartTime
                    if el>10 then E.Rate.Text = string.format("~%.1f/min",State.Stats.CollectedParts/(el/60))
                    else E.Rate.Text = "..." end
                end

                -- Status card
                if E.StatusLabel then
                    local a=State.IsActive
                    E.StatusLabel.Text = a and "ACTIVE" or "PAUSED"
                    E.StatusLabel.TextColor3 = a and C.Success or C.Warning
                    if E.StatusDot then Utils.Tween(E.StatusDot,{BackgroundColor3=a and C.Success or C.Warning},0.3) end
                    if E.StatusStroke then Utils.Tween(E.StatusStroke,{Color=a and C.Success or C.Warning},0.3) end
                end

                -- Pinned status
                if E.PinnedDot then
                    E.PinnedDot.BackgroundColor3 = State.IsActive and C.Success or C.Warning
                end
                if E.PinnedText then
                    if State.IsActive then
                        E.PinnedText.Text = State.LoopActive
                            and ("🔄 " .. #State.PartsToTeleport .. "/" .. Config.MaxParts)
                            or ("● " .. #State.PartsToTeleport .. "/" .. Config.MaxParts)
                    else
                        E.PinnedText.Text = "⏸ PAUSED"
                    end
                end

                if E.StatusSub then
                    if Config.LoopMode then
                        E.StatusSub.Text = State.LoopActive and "K to stop" or "K to start"
                    else E.StatusSub.Text = "K to pull" end
                end

                if E.KeyHint then
                    if Config.LoopMode then E.KeyHint.Text=State.LoopActive and "Stop" or "Start"
                    else E.KeyHint.Text="Pull" end
                end

                if E.Target then
                    if Config.TargetMode=="Mouse" then E.Target.Text="Mouse"
                    else
                        local n=State.CustomTargetPart and State.CustomTargetPart.Name or Config.TargetPartName
                        E.Target.Text=(n=="" and "Player" or n)
                    end
                end

                -- Pulse
                if State.IsActive and State.LoopActive and E.StatusDot then
                    E.StatusDot.BackgroundTransparency = (math.sin(tick()*4)+1)/2*0.5
                elseif E.StatusDot then E.StatusDot.BackgroundTransparency=0 end

                -- Selection box
                if Config.TargetMode=="CustomPart" then
                    local t=State.CustomTargetPart or Engine.FindCustomTarget()
                    if t then Engine.UpdateSelectionBox(t) end
                elseif Config.TargetMode=="Player" then Engine.UpdateSelectionBox(nil) end

                -- ESP refresh
                Engine.ESP.Refresh()
            end)
            task.wait(0.15)
        end
    end)
end

return Status
