--[[
    ╔══════════════════════════════════════╗
    ║  MODULE: components.lua              ║
    ║  UI компоненты: toggle, input, etc.  ║
    ║                                      ║
    ║  Зависимости: utils, config          ║
    ║                                      ║
    ║  RAW ссылка → loader.lua →           ║
    ║  loadModule("components")            ║
    ║                                      ║
    ║  Каждая функция возвращает таблицу   ║
    ║  с методами SetValue, GetValue и     ║
    ║  ссылками на Frame/Input             ║
    ╚══════════════════════════════════════╝
]]

local TCP = getgenv().TCP
local Config = TCP.Modules.Config
local State = TCP.Modules.State
local Utils = TCP.Modules.Utils

local C = Config.Colors -- shorthand
local Components = {}

-- ========== SECTION DIVIDER ==========
function Components.CreateSection(parent, title, order)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 28)
    section.BackgroundTransparency = 1
    section.LayoutOrder = order or 0
    section.Parent = parent

    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 0.5, 0)
    line.BackgroundColor3 = C.SurfaceLight
    line.BackgroundTransparency = 0.5
    line.BorderSizePixel = 0
    line.Parent = section

    local label = Instance.new("TextLabel")
    label.AutomaticSize = Enum.AutomaticSize.X
    label.Size = UDim2.new(0, 0, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundColor3 = C.Background
    label.Text = "  " .. title .. "  "
    label.TextColor3 = C.Accent
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.Parent = section
    Utils.CreateCorner(label, 4)

    return section
end

-- ========== TOGGLE SWITCH ==========
function Components.CreateToggle(parent, name, default, callback, order)
    local value = default

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 38)
    frame.BackgroundColor3 = C.Surface
    frame.BackgroundTransparency = 0.3
    frame.LayoutOrder = order or 0
    frame.Parent = parent
    Utils.CreateCorner(frame, 8)

    -- Название
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -65, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = C.TextPrimary
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    -- Фон переключателя
    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 44, 0, 22)
    toggleBg.Position = UDim2.new(1, -54, 0.5, -11)
    toggleBg.BackgroundColor3 = value and C.Accent or Color3.fromRGB(55, 55, 65)
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = frame
    Utils.CreateCorner(toggleBg, 11)

    -- Кнобка
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = value
        and UDim2.new(1, -20, 0.5, -9)
        or UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.Parent = toggleBg
    Utils.CreateCorner(knob, 9)

    -- Кликабельная область
    local clickArea = Instance.new("TextButton")
    clickArea.Size = UDim2.new(1, 0, 1, 0)
    clickArea.BackgroundTransparency = 1
    clickArea.Text = ""
    clickArea.Parent = frame

    clickArea.MouseButton1Click:Connect(function()
        value = not value
        Utils.Tween(toggleBg, {
            BackgroundColor3 = value and C.Accent or Color3.fromRGB(55, 55, 65)
        }, 0.2)
        Utils.Tween(knob, {
            Position = value
                and UDim2.new(1, -20, 0.5, -9)
                or UDim2.new(0, 2, 0.5, -9)
        }, 0.2)
        if callback then callback(value) end
    end)

    Utils.AddHover(frame, 0.1, 0.3)

    return {
        Frame = frame,
        SetValue = function(v)
            value = v
            Utils.Tween(toggleBg, {
                BackgroundColor3 = v and C.Accent or Color3.fromRGB(55, 55, 65)
            }, 0.2)
            Utils.Tween(knob, {
                Position = v
                    and UDim2.new(1, -20, 0.5, -9)
                    or UDim2.new(0, 2, 0.5, -9)
            }, 0.2)
        end,
        GetValue = function() return value end,
    }
end

-- ========== TEXT INPUT ==========
function Components.CreateInput(parent, name, placeholder, default, callback, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 58)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = order or 0
    frame.Parent = parent

    -- Лейбл
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = C.TextSecondary
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    -- Фон инпута
    local inputBg = Instance.new("Frame")
    inputBg.Size = UDim2.new(1, 0, 0, 34)
    inputBg.Position = UDim2.new(0, 0, 0, 22)
    inputBg.BackgroundColor3 = C.Surface
    inputBg.BorderSizePixel = 0
    inputBg.Parent = frame
    Utils.CreateCorner(inputBg, 8)
    local stroke = Utils.CreateStroke(inputBg, Color3.fromRGB(50, 50, 60), 1, 0.5)

    -- TextBox
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -16, 1, 0)
    input.Position = UDim2.new(0, 8, 0, 0)
    input.BackgroundTransparency = 1
    input.Text = tostring(default or "")
    input.PlaceholderText = placeholder or ""
    input.PlaceholderColor3 = Color3.fromRGB(80, 80, 90)
    input.TextColor3 = C.TextPrimary
    input.Font = Enum.Font.GothamMedium
    input.TextSize = 14
    input.TextXAlignment = Enum.TextXAlignment.Left
    input.ClearTextOnFocus = false
    input.Parent = inputBg

    -- Анимация фокуса
    input.Focused:Connect(function()
        Utils.Tween(stroke, {Color = C.Accent, Transparency = 0}, 0.2)
    end)
    input.FocusLost:Connect(function(enterPressed)
        Utils.Tween(stroke, {Color = Color3.fromRGB(50, 50, 60), Transparency = 0.5}, 0.2)
        if enterPressed and callback then
            callback(input.Text, input)
        end
    end)

    return {
        Frame = frame,
        Input = input,
        SetText = function(t) input.Text = tostring(t) end,
        GetText = function() return input.Text end,
    }
end

-- ========== BUTTON ==========
function Components.CreateButton(parent, text, color, callback, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = color or C.Accent
    btn.Text = text
    btn.TextColor3 = C.TextPrimary
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.AutoButtonColor = false
    btn.LayoutOrder = order or 0
    btn.ClipsDescendants = true
    btn.Parent = parent
    Utils.CreateCorner(btn, 8)

    Utils.AddHover(btn, 0.15, 0)

    btn.MouseButton1Click:Connect(function()
        Utils.AnimateClick(btn)
        Utils.Ripple(btn, State.Mouse.X, State.Mouse.Y)
        if callback then callback(btn) end
    end)

    return btn
end

-- ========== INFO ROW ==========
function Components.CreateInfoRow(parent, icon, label, value, color, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 26)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = order or 0
    frame.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = icon .. " " .. label
    lbl.TextColor3 = C.TextSecondary
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local val = Instance.new("TextLabel")
    val.Name = "Value"
    val.Size = UDim2.new(0.5, -10, 1, 0)
    val.Position = UDim2.new(0.5, 0, 0, 0)
    val.BackgroundTransparency = 1
    val.Text = tostring(value)
    val.TextColor3 = color or C.TextPrimary
    val.Font = Enum.Font.GothamBold
    val.TextSize = 13
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.Parent = frame

    return val -- Возвращает TextLabel значения для обновления
end

-- ========== OFFSET INPUTS (X, Y, Z) ==========
function Components.CreateOffsetInputs(parent, offset, callback, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 58)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = order or 0
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.Text = "📏 Offset (X, Y, Z)"
    label.TextColor3 = C.TextSecondary
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local inputs = {}
    local labels = {"X", "Y", "Z"}
    local defaults = {offset.X, offset.Y, offset.Z}

    for i = 1, 3 do
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(0.31, 0, 0, 34)
        bg.Position = UDim2.new((i - 1) * 0.345, 0, 0, 22)
        bg.BackgroundColor3 = C.Surface
        bg.BorderSizePixel = 0
        bg.Parent = frame
        Utils.CreateCorner(bg, 8)
        Utils.CreateStroke(bg, Color3.fromRGB(50, 50, 60), 1, 0.5)

        local axisLabel = Instance.new("TextLabel")
        axisLabel.Size = UDim2.new(0, 20, 1, 0)
        axisLabel.Position = UDim2.new(0, 4, 0, 0)
        axisLabel.BackgroundTransparency = 1
        axisLabel.Text = labels[i]
        axisLabel.TextColor3 = C.Accent
        axisLabel.Font = Enum.Font.GothamBold
        axisLabel.TextSize = 12
        axisLabel.Parent = bg

        local inp = Instance.new("TextBox")
        inp.Size = UDim2.new(1, -28, 1, 0)
        inp.Position = UDim2.new(0, 24, 0, 0)
        inp.BackgroundTransparency = 1
        inp.Text = tostring(defaults[i])
        inp.TextColor3 = C.TextPrimary
        inp.Font = Enum.Font.GothamMedium
        inp.TextSize = 14
        inp.ClearTextOnFocus = false
        inp.Parent = bg

        inp.FocusLost:Connect(function()
            if callback then callback() end
        end)

        inputs[i] = inp
    end

    return {
        Frame = frame,
        GetOffset = function()
            return Vector3.new(
                tonumber(inputs[1].Text) or 0,
                tonumber(inputs[2].Text) or 0,
                tonumber(inputs[3].Text) or 0
            )
        end,
        Inputs = inputs,
    }
end

return Components
