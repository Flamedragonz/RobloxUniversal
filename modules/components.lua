--[[
    ╔══════════════════════════════════════╗
    ║  MODULE: components.lua              ║
    ║  UI компоненты: toggle, input, etc.  ║
    ║                                      ║
    ║  ОБНОВЛЕНИЕ:                         ║
    ║  • Input: жёлтый текст если не       ║
    ║    подтверждён Enter-ом              ║
    ║  • Визуальный индикатор "pending"    ║
    ║                                      ║
    ║  Зависимости: utils, config, state   ║
    ╚══════════════════════════════════════╝
]]

local TCP = shared.TCP
if not TCP or not TCP.Modules then
    warn("❌ [components] shared.TCP not found!")
    return nil
end

local Config = TCP.Modules.Config
local State  = TCP.Modules.State
local Utils  = TCP.Modules.Utils

if not Config then warn("❌ [components] Missing: Config"); return nil end
if not State  then warn("❌ [components] Missing: State");  return nil end
if not Utils  then warn("❌ [components] Missing: Utils");  return nil end

local C = Config.Colors
local Components = {}

-- ========== ЦВЕТА ДЛЯ ИНПУТОВ ==========
local INPUT_COLORS = {
    Confirmed   = C.TextPrimary,                    -- Белый — подтверждено
    Pending     = Color3.fromRGB(255, 230, 50),     -- Жёлтый — не подтверждено
    StrokeIdle  = Color3.fromRGB(50, 50, 60),       -- Обычная обводка
    StrokeFocus = C.Accent,                          -- Фокус
    StrokePending = Color3.fromRGB(200, 180, 40),   -- Жёлтая обводка когда pending
}

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

    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 44, 0, 22)
    toggleBg.Position = UDim2.new(1, -54, 0.5, -11)
    toggleBg.BackgroundColor3 = value and C.Accent or Color3.fromRGB(55, 55, 65)
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = frame
    Utils.CreateCorner(toggleBg, 11)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = value
        and UDim2.new(1, -20, 0.5, -9)
        or UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.Parent = toggleBg
    Utils.CreateCorner(knob, 9)

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

-- ========== TEXT INPUT (с жёлтой подсветкой) ==========
function Components.CreateInput(parent, name, placeholder, default, callback, order)
    local confirmedValue = tostring(default or "")

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
    local stroke = Utils.CreateStroke(inputBg, INPUT_COLORS.StrokeIdle, 1, 0.5)

    -- Иконка статуса (точка справа)
    local statusDot = Instance.new("Frame")
    statusDot.Size = UDim2.new(0, 8, 0, 8)
    statusDot.Position = UDim2.new(1, -14, 0.5, -4)
    statusDot.BackgroundColor3 = C.Success
    statusDot.BackgroundTransparency = 1 -- Скрыта по умолчанию
    statusDot.BorderSizePixel = 0
    statusDot.ZIndex = 3
    statusDot.Parent = inputBg
    Utils.CreateCorner(statusDot, 4)

    -- Подсказка "Enter ↵" справа
    local enterHint = Instance.new("TextLabel")
    enterHint.Size = UDim2.new(0, 45, 1, 0)
    enterHint.Position = UDim2.new(1, -50, 0, 0)
    enterHint.BackgroundTransparency = 1
    enterHint.Text = ""
    enterHint.TextColor3 = INPUT_COLORS.Pending
    enterHint.Font = Enum.Font.GothamMedium
    enterHint.TextSize = 10
    enterHint.TextXAlignment = Enum.TextXAlignment.Right
    enterHint.TextTransparency = 1
    enterHint.ZIndex = 3
    enterHint.Parent = inputBg

    -- TextBox
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -20, 1, 0)
    input.Position = UDim2.new(0, 8, 0, 0)
    input.BackgroundTransparency = 1
    input.Text = confirmedValue
    input.PlaceholderText = placeholder or ""
    input.PlaceholderColor3 = Color3.fromRGB(80, 80, 90)
    input.TextColor3 = INPUT_COLORS.Confirmed
    input.Font = Enum.Font.GothamMedium
    input.TextSize = 14
    input.TextXAlignment = Enum.TextXAlignment.Left
    input.ClearTextOnFocus = false
    input.Parent = inputBg

    -- ===== ОТСЛЕЖИВАНИЕ ИЗМЕНЕНИЙ =====
    local isPending = false

    local function updatePendingVisuals(pending)
        isPending = pending
        if pending then
            -- Жёлтый текст + подсказка Enter
            Utils.Tween(input, {TextColor3 = INPUT_COLORS.Pending}, 0.15)
            enterHint.Text = "Enter ↵"
            Utils.Tween(enterHint, {TextTransparency = 0}, 0.15)
            Utils.Tween(statusDot, {
                BackgroundColor3 = INPUT_COLORS.Pending,
                BackgroundTransparency = 0
            }, 0.15)
            -- Жёлтая обводка
            if not input:IsFocused() then
                Utils.Tween(stroke, {
                    Color = INPUT_COLORS.StrokePending,
                    Transparency = 0.3
                }, 0.15)
            end
        else
            -- Белый текст + скрыть подсказку
            Utils.Tween(input, {TextColor3 = INPUT_COLORS.Confirmed}, 0.15)
            Utils.Tween(enterHint, {TextTransparency = 1}, 0.15)
            -- Зелёная точка "подтверждено" (мигнёт и исчезнет)
            Utils.Tween(statusDot, {
                BackgroundColor3 = C.Success,
                BackgroundTransparency = 0
            }, 0.15)
            task.delay(1, function()
                if not isPending and statusDot and statusDot.Parent then
                    Utils.Tween(statusDot, {BackgroundTransparency = 1}, 0.3)
                end
            end)
            -- Обычная обводка
            if not input:IsFocused() then
                Utils.Tween(stroke, {
                    Color = INPUT_COLORS.StrokeIdle,
                    Transparency = 0.5
                }, 0.15)
            end
        end
    end

    -- Отслеживать каждое изменение текста
    input:GetPropertyChangedSignal("Text"):Connect(function()
        if input.Text ~= confirmedValue then
            updatePendingVisuals(true)
        else
            updatePendingVisuals(false)
        end
    end)

    -- Анимация фокуса
    input.Focused:Connect(function()
        Utils.Tween(stroke, {
            Color = isPending and INPUT_COLORS.Pending or C.Accent,
            Transparency = 0
        }, 0.2)
    end)

    -- При потере фокуса
    input.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            -- ✅ Подтверждено Enter-ом
            confirmedValue = input.Text
            updatePendingVisuals(false)
            Utils.Tween(stroke, {
                Color = INPUT_COLORS.StrokeIdle,
                Transparency = 0.5
            }, 0.2)
            if callback then
                callback(input.Text, input)
            end
        else
            -- ❌ Не подтверждено — оставить жёлтым если изменено
            if input.Text ~= confirmedValue then
                updatePendingVisuals(true)
            end
            Utils.Tween(stroke, {
                Color = isPending and INPUT_COLORS.StrokePending or INPUT_COLORS.StrokeIdle,
                Transparency = isPending and 0.3 or 0.5
            }, 0.2)
        end
    end)

    return {
        Frame = frame,
        Input = input,
        SetText = function(t)
            confirmedValue = tostring(t)
            input.Text = confirmedValue
            updatePendingVisuals(false)
        end,
        GetText = function() return input.Text end,
        GetConfirmed = function() return confirmedValue end,
        IsPending = function() return isPending end,
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

    return val
end

-- ========== HOTKEY ROW (новый компонент) ==========
function Components.CreateHotkeyRow(parent, key, description, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = order or 0
    frame.Parent = parent

    -- Бейдж клавиши
    local keyBadge = Instance.new("Frame")
    keyBadge.Size = UDim2.new(0, 32, 0, 24)
    keyBadge.Position = UDim2.new(0, 0, 0.5, -12)
    keyBadge.BackgroundColor3 = C.SurfaceLight
    keyBadge.BorderSizePixel = 0
    keyBadge.Parent = frame
    Utils.CreateCorner(keyBadge, 6)
    Utils.CreateStroke(keyBadge, C.Accent, 1, 0.5)

    local keyLabel = Instance.new("TextLabel")
    keyLabel.Size = UDim2.new(1, 0, 1, 0)
    keyLabel.BackgroundTransparency = 1
    keyLabel.Text = key
    keyLabel.TextColor3 = C.Accent
    keyLabel.Font = Enum.Font.GothamBlack
    keyLabel.TextSize = 13
    keyLabel.Parent = keyBadge

    -- Описание
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -44, 1, 0)
    descLabel.Position = UDim2.new(0, 42, 0, 0)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = description
    descLabel.TextColor3 = C.TextSecondary
    descLabel.Font = Enum.Font.GothamMedium
    descLabel.TextSize = 13
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = frame

    return frame
end

-- ========== OFFSET INPUTS (X, Y, Z) с жёлтой подсветкой ==========
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
    local confirmedValues = {}
    local labels = {"X", "Y", "Z"}
    local defaults = {offset.X, offset.Y, offset.Z}

    for i = 1, 3 do
        confirmedValues[i] = tostring(defaults[i])

        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(0.31, 0, 0, 34)
        bg.Position = UDim2.new((i - 1) * 0.345, 0, 0, 22)
        bg.BackgroundColor3 = C.Surface
        bg.BorderSizePixel = 0
        bg.Parent = frame
        Utils.CreateCorner(bg, 8)
        local stroke = Utils.CreateStroke(bg, INPUT_COLORS.StrokeIdle, 1, 0.5)

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
        inp.Text = confirmedValues[i]
        inp.TextColor3 = INPUT_COLORS.Confirmed
        inp.Font = Enum.Font.GothamMedium
        inp.TextSize = 14
        inp.ClearTextOnFocus = false
        inp.Parent = bg

        -- Жёлтая подсветка для offset инпутов
        local idx = i
        inp:GetPropertyChangedSignal("Text"):Connect(function()
            if inp.Text ~= confirmedValues[idx] then
                Utils.Tween(inp, {TextColor3 = INPUT_COLORS.Pending}, 0.15)
                Utils.Tween(stroke, {Color = INPUT_COLORS.StrokePending, Transparency = 0.3}, 0.15)
            else
                Utils.Tween(inp, {TextColor3 = INPUT_COLORS.Confirmed}, 0.15)
                Utils.Tween(stroke, {Color = INPUT_COLORS.StrokeIdle, Transparency = 0.5}, 0.15)
            end
        end)

        inp.Focused:Connect(function()
            Utils.Tween(stroke, {Color = C.Accent, Transparency = 0}, 0.2)
        end)

        inp.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                confirmedValues[idx] = inp.Text
                Utils.Tween(inp, {TextColor3 = INPUT_COLORS.Confirmed}, 0.15)
                Utils.Tween(stroke, {Color = INPUT_COLORS.StrokeIdle, Transparency = 0.5}, 0.2)
                if callback then callback() end
            else
                if inp.Text ~= confirmedValues[idx] then
                    Utils.Tween(stroke, {Color = INPUT_COLORS.StrokePending, Transparency = 0.3}, 0.2)
                else
                    Utils.Tween(stroke, {Color = INPUT_COLORS.StrokeIdle, Transparency = 0.5}, 0.2)
                end
            end
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
