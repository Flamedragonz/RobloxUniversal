--[[
    MODULE: input.lua v2.1
    + Mini mode hotkey (M), improved notifications
]]

local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local TCP = shared.TCP
if not TCP or not TCP.Modules then return nil end
local Config=TCP.Modules.Config; local State=TCP.Modules.State
local Engine=TCP.Modules.Engine; local Notify=TCP.Modules.Notify; local Utils=TCP.Modules.Utils
if not Config or not State or not Engine or not Notify or not Utils then return nil end
local C=Config.Colors; local Keys=Config.Hotkeys

local function playSound(id,vol)
    if not Config.SoundEnabled then return end
    pcall(function() local s=Instance.new("Sound"); s.SoundId="rbxassetid://"..tostring(id)
        s.Volume=vol or 0.2; s.PlayOnRemove=true; s.Parent=SoundService; s:Destroy() end)
end

local Input = {}

function Input.Setup()
    UserInputService.InputBegan:Connect(function(input,gp)
        if gp then return end

        -- K
        if input.KeyCode==Keys.Toggle then
            if not State.IsActive then Notify.Send("⚠️ Paused. Press J",C.Warning); return end
            if Config.LoopMode then
                State.LoopActive=not State.LoopActive
                playSound(Config.Sounds.Toggle,0.15)
                Notify.Send(State.LoopActive and "🔄 Loop started" or "⏹️ Loop stopped",
                    State.LoopActive and C.Success or C.Warning)
            else
                local added=Engine.CollectParts()
                playSound(Config.Sounds.Collect,0.15)
                if added>0 then Notify.Send("📦 +"..added.." parts (active: "..#State.PartsToTeleport.."/"..Config.MaxParts..")",C.Info)
                elseif #State.PartsToTeleport>=Config.MaxParts then Notify.Send("⚠️ Max parts limit",C.Warning)
                else Notify.Send("🔍 No parts found",C.TextSecondary) end
            end
        end

        -- P
        if input.KeyCode==Keys.HideUI then
            State.UIVisible=not State.UIVisible
            if State.GUI then
                local mf=State.GUI:FindFirstChild("MainFrame")
                if mf then
                    if State.UIVisible then mf.Visible=true; Utils.Tween(mf,{BackgroundTransparency=0},0.2)
                    else Utils.Tween(mf,{BackgroundTransparency=1},0.2)
                        task.delay(0.2,function() if not State.UIVisible and mf then mf.Visible=false end end) end
                end
                -- Mini panel follows
                local mp = State.GUI:FindFirstChild("MiniPanel")
                if mp then mp.Visible = not State.UIVisible and Config.MiniMode end
            end
            Notify.Send(State.UIVisible and "👁️ UI shown" or "🙈 Hidden (P)",C.Info)
        end

        -- L
        if input.KeyCode==Keys.Release then
            local c=#State.PartsToTeleport
            if c>0 then Engine.ReleaseAll(); playSound(Config.Sounds.Release,0.2)
                Notify.Send("🔓 Released "..c.." parts"..(Config.AnchorOnFinish and " (anchored)" or ""),C.Warning)
            else Notify.Send("🔓 Nothing to release",C.TextSecondary) end
        end

        -- J
        if input.KeyCode==Keys.QuickPause then
            State.IsActive=not State.IsActive
            if not State.IsActive then State.LoopActive=false end
            playSound(Config.Sounds.Toggle,0.15)
            Notify.Send(State.IsActive and "▶️ Activated" or "⏸️ Paused",
                State.IsActive and C.Success or C.Warning)
        end

        -- M — Mini mode
        if input.KeyCode==Keys.MiniMode then
            Config.MiniMode = not Config.MiniMode
            if State.GUI then
                local mf = State.GUI:FindFirstChild("MainFrame")
                local mp = State.GUI:FindFirstChild("MiniPanel")
                if Config.MiniMode then
                    if mf then mf.Visible=false end
                    if mp then mp.Visible=true end
                    State.UIVisible=false
                else
                    if mp then mp.Visible=false end
                    if mf then mf.Visible=true end
                    State.UIVisible=true
                end
            end
            Notify.Send(Config.MiniMode and "📌 Mini mode (M to expand)" or "📊 Full panel",C.Info)
        end
    end)

    State.Mouse.Button1Down:Connect(function()
        if not State.IsSelectingTarget then return end
        local target=State.Mouse.Target; if not target then return end
        State.CustomTargetPart=target; Config.TargetPartName=target.Name; Config.TargetMode="CustomPart"
        Engine.UpdateSelectionBox(target); State.IsSelectingTarget=false
        if State.UIElements.SelectBtn then
            State.UIElements.SelectBtn.Text="👆 Click to Select"
            Utils.Tween(State.UIElements.SelectBtn,{BackgroundColor3=Color3.fromRGB(50,80,140)},0.2)
        end
        if State.UIElements.CustomTargetInput then State.UIElements.CustomTargetInput.SetText(target.Name) end
        Notify.Send("🎯 Target: "..target.Name,C.Success)
    end)
end

return Input
