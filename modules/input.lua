--[[
    ╔══════════════════════════════════════╗
    ║  MODULE: input.lua                   ║
    ║  Обработка клавиш и мыши             ║
    ║                                      ║
    ║  Зависимости: config, state, engine, ║
    ║               notify, utils, ui      ║
    ║                                      ║
    ║  RAW ссылка → loader.lua →           ║
    ║  loadModule("input")                 ║
    ║                                      ║
    ║  Hotkeys:                            ║
    ║  K — Toggle loop / Pull once         ║
    ║  P — Hide/Show UI                    ║
    ║  L — Release all parts               ║
    ║  J — Quick Active toggle             ║
    ╚══════════════════════════════════════╝
]]

local UserInputService = game:GetService("UserInputService")

local TCP = getgenv().TCP
local Config = TCP.Modules.Config
local State = TCP.Modules.State
local Engine = TCP.Modules.Engine
local Notify = TCP.Modules.Notify
local Utils = TCP.Modules.Utils

local C = Config.Colors
local Keys = Config.Hotkeys
local Input = {}

function Input.Setup()
    -- ===== KEYBOARD =====
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        -- K — Toggle loop / Pull once
        if input.KeyCode == Keys.Toggle then
            if not State.IsActive then return end

            if Config.LoopMode then
                State.LoopActive = not State.LoopActive
                Notify.Send(
                    State.LoopActive and "🔄 Loop started" or "⏹️ Loop stopped",
                    State.LoopActive and C.Success or C.Warning
                )
            else
                local added = Engine.CollectParts()
                Notify.Send("Pulled " .. added .. " parts", C.Info)
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
                        -- Восстановить дочерние элементы
                        for _, child in pairs(mf:GetDescendants()) do
                            if child:IsA("GuiObject") and child.Name ~= "Shadow" then
                                -- Visibility уже управляется parent
                            end
                        end
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
                State.UIVisible and "👁️ UI Shown" or "🙈 UI Hidden (P to show)",
                C.Info
            )
        end

        -- L — Release all
        if input.KeyCode == Keys.Release then
            local count = #State.PartsToTeleport
            Engine.ReleaseAll()
            Notify.Send("Released " .. count .. " parts", C.Warning)
        end

        -- J — Quick toggle
        if input.KeyCode == Keys.QuickPause then
            State.IsActive = not State.IsActive
            if not State.IsActive then
                State.LoopActive = false
            end
            Notify.Send(
                State.IsActive and "▶️ Activated" or "⏸️ Paused",
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

        -- Обновить UI элементы
        if State.UIElements.SelectBtn then
            State.UIElements.SelectBtn.Text = "👆 Click to Select Target"
            Utils.Tween(State.UIElements.SelectBtn, {
                BackgroundColor3 = Color3.fromRGB(50, 80, 140)
            }, 0.2)
        end

        if State.UIElements.CustomTargetInput then
            State.UIElements.CustomTargetInput.Input.Text = target.Name
        end

        Notify.Send("🎯 Target: " .. target.Name, C.Success)
    end)
end

return Input
