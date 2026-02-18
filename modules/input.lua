--[[
    ╔══════════════════════════════════════╗
    ║  MODULE: input.lua                   ║
    ║  Обработка клавиш и мыши             ║
    ║                                      ║
    ║  ОБНОВЛЕНИЕ:                         ║
    ║  • Уведомление с количеством при     ║
    ║    single pull (K в Single Mode)     ║
    ║  • Улучшенные тексты нотификаций     ║
    ║                                      ║
    ║  Зависимости: config, state, engine, ║
    ║               notify, utils          ║
    ╚══════════════════════════════════════╝
]]

local UserInputService = game:GetService("UserInputService")

local TCP = shared.TCP
if not TCP or not TCP.Modules then
    warn("❌ [input] shared.TCP not found!")
    return nil
end

local Config = TCP.Modules.Config
local State  = TCP.Modules.State
local Engine = TCP.Modules.Engine
local Notify = TCP.Modules.Notify
local Utils  = TCP.Modules.Utils

if not Config then warn("❌ [input] Missing: Config"); return nil end
if not State  then warn("❌ [input] Missing: State");  return nil end
if not Engine then warn("❌ [input] Missing: Engine"); return nil end
if not Notify then warn("❌ [input] Missing: Notify"); return nil end
if not Utils  then warn("❌ [input] Missing: Utils");  return nil end

local C = Config.Colors
local Keys = Config.Hotkeys
local Input = {}

function Input.Setup()
    -- ===== KEYBOARD =====
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        -- K — Toggle loop / Pull once
        if input.KeyCode == Keys.Toggle then
            if not State.IsActive then
                Notify.Send("⚠️ Script is paused. Press J to activate", C.Warning)
                return
            end

            if Config.LoopMode then
                State.LoopActive = not State.LoopActive
                if State.LoopActive then
                    Notify.Send("🔄 Loop started — collecting every " .. Config.LoopInterval .. "s", C.Success)
                else
                    Notify.Send("⏹️ Loop stopped — " .. #State.PartsToTeleport .. " parts active", C.Warning)
                end
            else
                -- Single pull с уведомлением о количестве
                local before = #State.PartsToTeleport
                local added = Engine.CollectParts()
                local after = #State.PartsToTeleport

                if added > 0 then
                    Notify.Send(
                        "📦 Pulled " .. added .. " parts (active: " .. after .. "/" .. Config.MaxParts .. ")",
                        C.Info
                    )
                else
                    if after >= Config.MaxParts then
                        Notify.Send("⚠️ Max parts limit reached (" .. Config.MaxParts .. ")", C.Warning)
                    else
                        Notify.Send("🔍 No new parts found in folder", C.TextSecondary)
                    end
                end
            end
        end

        -- P — Hide/Show UI
        if input.KeyCode == Keys.HideUI then
            State.UIVisible = not State.UIVisible
            if State.GUI then
                local mf = State.GUI:FindFirstChild("MainFrame")
                if mf then
                    if State.UIVisible then
                        mf.Visible = true
                        Utils.Tween(mf, {BackgroundTransparency = 0}, 0.2)
                    else
                        Utils.Tween(mf, {BackgroundTransparency = 1}, 0.2)
                        task.delay(0.2, function()
                            if not State.UIVisible and mf then
                                mf.Visible = false
                            end
                        end)
                    end
                end
            end
            Notify.Send(
                State.UIVisible and "👁️ UI Shown (P to hide)" or "🙈 UI Hidden (P to show)",
                C.Info
            )
        end

        -- L — Release all
        if input.KeyCode == Keys.Release then
            local count = #State.PartsToTeleport
            if count > 0 then
                Engine.ReleaseAll()
                local anchorText = Config.AnchorOnFinish and " (anchored)" or ""
                Notify.Send("🔓 Released " .. count .. " parts" .. anchorText, C.Warning)
            else
                Notify.Send("🔓 No parts to release", C.TextSecondary)
            end
        end

        -- J — Quick toggle
        if input.KeyCode == Keys.QuickPause then
            State.IsActive = not State.IsActive
            if not State.IsActive then
                State.LoopActive = false
            end
            Notify.Send(
                State.IsActive
                    and "▶️ Activated — press K to start"
                    or "⏸️ Paused — " .. #State.PartsToTeleport .. " parts held",
                State.IsActive and C.Success or C.Warning
            )
        end
    end)

    -- ===== MOUSE CLICK (Target Selection) =====
    State.Mouse.Button1Down:Connect(function()
        if not State.IsSelectingTarget then return end

        local target = State.Mouse.Target
        if not target then return end

        State.CustomTargetPart = target
        Config.TargetPartName = target.Name
        Config.TargetMode = "CustomPart"

        Engine.UpdateSelectionBox(target)
        State.IsSelectingTarget = false

        if State.UIElements.SelectBtn then
            State.UIElements.SelectBtn.Text = "👆 Click to Select Target"
            Utils.Tween(State.UIElements.SelectBtn, {
                BackgroundColor3 = Color3.fromRGB(50, 80, 140)
            }, 0.2)
        end

        if State.UIElements.CustomTargetInput then
            State.UIElements.CustomTargetInput.SetText(target.Name)
        end

        Notify.Send("🎯 Target set: " .. target.Name, C.Success)
    end)
end

return Input
