-- TCP UI Module (Full Rewrite, Safe Version)

local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local TCP = shared.TCP
if not TCP or not TCP.Modules then
    warn("[UI] TCP not initialized")
    return nil
end

local Config   = TCP.Modules.Config
local State    = TCP.Modules.State
local Utils    = TCP.Modules.Utils
local Notify   = TCP.Modules.Notify
local Comp     = TCP.Modules.Components
local Engine   = TCP.Modules.Engine
local Scanner  = TCP.Modules.Scanner
local Presets  = TCP.Modules.Presets

if not Config or not State or not Utils or not Notify or not Comp or not Engine then
    warn("[UI] Missing core modules")
    return nil
end

local UI = {}

-- =========================
-- Internal helpers
-- =========================

local function SafeMount(gui)
    local ok = pcall(function()
        gui.Parent = CoreGui
    end)

    if not ok then
        pcall(function()
            local plr = Players.LocalPlayer
            if plr then
                gui.Parent = plr:WaitForChild("PlayerGui")
            end
        end)
    end
end

local function Cleanup()
    if State.Connections then
        for _, c in pairs(State.Connections) do
            if typeof(c) == "RBXScriptConnection" then
                pcall(function()
                    c:Disconnect()
                end)
            end
        end
    end

    State.Connections = {}
    State.UIElements = {}
end

-- =========================
-- Create UI
-- =========================

function UI.Create()
    -- State init
    State.UIElements = State.UIElements or {}
    State.Connections = State.Connections or {}
    State.IsRunning = true

    -- Cleanup old UI
    Cleanup()

    if State.GUI then
        pcall(function()
            State.GUI:Destroy()
        end)
        State.GUI = nil
    end

    -- Root GUI
    local gui = Instance.new("ScreenGui")
    gui.Name = "TCP_UI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true

    SafeMount(gui)
    State.GUI = gui

    -- Main Frame
    local main = Comp.CreateWindow(gui, "TCP Control Panel", UDim2.fromScale(0.4, 0.45))
    State.UIElements.Main = main

    -- =========================
    -- Tabs
    -- =========================

    local tabs = Comp.CreateTabs(main, {
        "Main",
        "Teleport",
        "Scanner",
        "Presets",
        "Status"
    })

    -- =========================
    -- MAIN TAB
    -- =========================

    local mainTab = tabs["Main"]

    Comp.CreateToggle(
        mainTab,
        "⚡ Enable System",
        Config.Enabled,
        function(v)
            Config.Enabled = v
            if v then
                Engine.Start()
            else
                Engine.Stop()
            end
        end,
        1
    )

    Comp.CreateButton(
        mainTab,
        "🧹 Release All",
        function()
            Engine.ReleaseAll()
        end,
        2
    )

    -- =========================
    -- TELEPORT TAB
    -- =========================

    local tpTab = tabs["Teleport"]

    Comp.CreateToggle(
        tpTab,
        "🌀 Smooth Teleport",
        Config.SmoothTeleport,
        function(v)
            Config.SmoothTeleport = v
        end,
        1
    )

    Comp.CreateInput(
        tpTab,
        "📊 Max Parts",
        "50",
        tostring(Config.MaxParts),
        function(t)
            local n = tonumber(t)
            if n and n > 0 then
                Config.MaxParts = math.floor(n)
            end
        end,
        2
    )

    -- =========================
    -- SCANNER TAB
    -- =========================

    local scTab = tabs["Scanner"]

    Comp.CreateButton(
        scTab,
        "🔍 Scan Workspace",
        function()
            if not Scanner then
                Notify.Send("❌ Scanner not available", "danger")
                return
            end

            local stats = Scanner.GetWorkspaceStats()
            if stats then
                Notify.Send("Found parts: " .. tostring(stats.Total), "info")
            end
        end,
        1
    )

    -- =========================
    -- PRESETS TAB
    -- =========================

    local prTab = tabs["Presets"]

    Comp.CreateButton(
        prTab,
        "💾 Save Preset",
        function()
            if Presets then
                Presets.Save()
                Notify.Send("Preset saved", "success")
            end
        end,
        1
    )

    Comp.CreateButton(
        prTab,
        "📂 Load Preset",
        function()
            if Presets then
                Presets.Load()
                Notify.Send("Preset loaded", "success")
            end
        end,
        2
    )

    -- =========================
    -- STATUS TAB
    -- =========================

    local stTab = tabs["Status"]

    local statusLabel = Comp.CreateLabel(stTab, "Status: Idle", 1)
    State.UIElements.Status = statusLabel

    -- =========================
    -- Heartbeat Loop
    -- =========================

    if State.Connections.Heartbeat then
        State.Connections.Heartbeat:Disconnect()
    end

    State.Connections.Heartbeat = RunService.Heartbeat:Connect(function()
        if not State.IsRunning then return end
        if not State.GUI then return end

        if Config.Enabled then
            statusLabel.Text = "Status: Active"
        else
            statusLabel.Text = "Status: Idle"
        end
    end)
end

-- =========================
-- Destroy UI
-- =========================

function UI.Destroy()
    State.IsRunning = false

    Cleanup()

    if State.GUI then
        pcall(function()
            State.GUI:Destroy()
        end)
        State.GUI = nil
    end
end

-- =========================
-- Reload UI
-- =========================

function UI.Reload()
    UI.Destroy()
    task.wait(0.1)
    UI.Create()
end

return UI
