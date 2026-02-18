--[[
    MODULE: components.lua v2.1
    + CollapsibleSection, HotkeyRow, ThemePicker, Dropdown
    + Жёлтая подсветка pending инпутов
]]

local TCP = shared.TCP
if not TCP or not TCP.Modules then return nil end
local Config = TCP.Modules.Config
local State  = TCP.Modules.State
local Utils  = TCP.Modules.Utils
if not Config or not State or not Utils then return nil end

local C = Config.Colors
local Components = {}

local PENDING = Color3.fromRGB(255, 230, 50)
local PENDING_STROKE = Color3.fromRGB(200, 180, 40)
local IDLE_STROKE = Color3.fromRGB(50, 50, 60)

-- ========== SECTION ==========
function Components.CreateSection(parent, title, order)
    local s = Instance.new("Frame"); s.Size=UDim2.new(1,0,0,28); s.BackgroundTransparency=1
    s.LayoutOrder=order or 0; s.Parent=parent
    local l = Instance.new("Frame"); l.Size=UDim2.new(1,0,0,1); l.Position=UDim2.new(0,0,0.5,0)
    l.BackgroundColor3=C.SurfaceLight; l.BackgroundTransparency=0.5; l.BorderSizePixel=0; l.Parent=s
    local t = Instance.new("TextLabel"); t.AutomaticSize=Enum.AutomaticSize.X; t.Size=UDim2.new(0,0,1,0)
    t.Position=UDim2.new(0,8,0,0); t.BackgroundColor3=C.Background; t.Text="  "..title.."  "
    t.TextColor3=C.Accent; t.Font=Enum.Font.GothamBold; t.TextSize=11; t.Parent=s
    Utils.CreateCorner(t,4)
    return s
end

-- ========== COLLAPSIBLE SECTION ==========
function Components.CreateCollapsibleSection(parent, title, defaultOpen, order)
    local isOpen = defaultOpen ~= false

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundTransparency = 1
    container.LayoutOrder = order or 0
    container.Parent = parent

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = container

    -- Header (кликабельный)
    local header = Instance.new("TextButton")
    header.Size = UDim2.new(1, 0, 0, 32)
    header.BackgroundColor3 = C.Surface
    header.BackgroundTransparency = 0.5
    header.Text = ""
    header.AutoButtonColor = false
    header.LayoutOrder = 0
    header.Parent = container
    Utils.CreateCorner(header, 8)

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(0, 10, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = isOpen and "▼" or "▶"
    arrow.TextColor3 = C.Accent
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 12
    arrow.Parent = header

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -40, 1, 0)
    titleLabel.Position = UDim2.new(0, 32, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = C.TextPrimary
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = header

    -- Content container
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, 0, 0, 0)
    content.AutomaticSize = Enum.AutomaticSize.Y
    content.BackgroundTransparency = 1
    content.Visible = isOpen
    content.LayoutOrder = 1
    content.ClipsDescendants = true
    content.Parent = container

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.Parent = content

    -- Toggle
    header.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        arrow.Text = isOpen and "▼" or "▶"
        content.Visible = isOpen
        Utils.Tween(header, {BackgroundTransparency = isOpen and 0.5 or 0.3}, 0.2)
    end)

    header.MouseEnter:Connect(function() Utils.Tween(header, {BackgroundTransparency = 0.3}, 0.15) end)
    header.MouseLeave:Connect(function() Utils.Tween(header, {BackgroundTransparency = 0.5}, 0.15) end)

    return {Container = container, Content = content, Header = header}
end

-- ========== TOGGLE ==========
function Components.CreateToggle(parent, name, default, callback, order)
    local value = default
    local f = Instance.new("Frame"); f.Size=UDim2.new(1,0,0,38); f.BackgroundColor3=C.Surface
    f.BackgroundTransparency=0.3; f.LayoutOrder=order or 0; f.Parent=parent; Utils.CreateCorner(f,8)

    local l = Instance.new("TextLabel"); l.Size=UDim2.new(1,-65,1,0); l.Position=UDim2.new(0,14,0,0)
    l.BackgroundTransparency=1; l.Text=name; l.TextColor3=C.TextPrimary; l.Font=Enum.Font.GothamMedium
    l.TextSize=14; l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=f

    local bg = Instance.new("Frame"); bg.Size=UDim2.new(0,44,0,22); bg.Position=UDim2.new(1,-54,0.5,-11)
    bg.BackgroundColor3=value and C.Accent or Color3.fromRGB(55,55,65); bg.BorderSizePixel=0; bg.Parent=f
    Utils.CreateCorner(bg,11)

    local k = Instance.new("Frame"); k.Size=UDim2.new(0,18,0,18)
    k.Position=value and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
    k.BackgroundColor3=Color3.new(1,1,1); k.BorderSizePixel=0; k.Parent=bg; Utils.CreateCorner(k,9)

    local btn = Instance.new("TextButton"); btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1
    btn.Text=""; btn.Parent=f
    btn.MouseButton1Click:Connect(function()
        value=not value
        Utils.Tween(bg,{BackgroundColor3=value and C.Accent or Color3.fromRGB(55,55,65)},0.2)
        Utils.Tween(k,{Position=value and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)},0.2)
        if callback then callback(value) end
    end)
    Utils.AddHover(f,0.1,0.3)

    return {Frame=f, SetValue=function(v) value=v
        Utils.Tween(bg,{BackgroundColor3=v and C.Accent or Color3.fromRGB(55,55,65)},0.2)
        Utils.Tween(k,{Position=v and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)},0.2)
    end, GetValue=function() return value end}
end

-- ========== INPUT (жёлтая подсветка) ==========
function Components.CreateInput(parent, name, placeholder, default, callback, order)
    local confirmed = tostring(default or "")
    local f = Instance.new("Frame"); f.Size=UDim2.new(1,0,0,58); f.BackgroundTransparency=1
    f.LayoutOrder=order or 0; f.Parent=parent

    local lbl = Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,0,18); lbl.BackgroundTransparency=1
    lbl.Text=name; lbl.TextColor3=C.TextSecondary; lbl.Font=Enum.Font.GothamMedium; lbl.TextSize=12
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=f

    local bg = Instance.new("Frame"); bg.Size=UDim2.new(1,0,0,34); bg.Position=UDim2.new(0,0,0,22)
    bg.BackgroundColor3=C.Surface; bg.BorderSizePixel=0; bg.Parent=f; Utils.CreateCorner(bg,8)
    local stroke = Utils.CreateStroke(bg,IDLE_STROKE,1,0.5)

    local hint = Instance.new("TextLabel"); hint.Size=UDim2.new(0,50,1,0); hint.Position=UDim2.new(1,-55,0,0)
    hint.BackgroundTransparency=1; hint.Text=""; hint.TextColor3=PENDING; hint.Font=Enum.Font.GothamMedium
    hint.TextSize=10; hint.TextXAlignment=Enum.TextXAlignment.Right; hint.TextTransparency=1; hint.ZIndex=3
    hint.Parent=bg

    local inp = Instance.new("TextBox"); inp.Size=UDim2.new(1,-20,1,0); inp.Position=UDim2.new(0,8,0,0)
    inp.BackgroundTransparency=1; inp.Text=confirmed; inp.PlaceholderText=placeholder or ""
    inp.PlaceholderColor3=Color3.fromRGB(80,80,90); inp.TextColor3=C.TextPrimary
    inp.Font=Enum.Font.GothamMedium; inp.TextSize=14; inp.TextXAlignment=Enum.TextXAlignment.Left
    inp.ClearTextOnFocus=false; inp.Parent=bg

    local pending = false
    local function setPending(v)
        pending = v
        if v then
            Utils.Tween(inp,{TextColor3=PENDING},0.15)
            hint.Text="Enter ↵"; Utils.Tween(hint,{TextTransparency=0},0.15)
            if not inp:IsFocused() then Utils.Tween(stroke,{Color=PENDING_STROKE,Transparency=0.3},0.15) end
        else
            Utils.Tween(inp,{TextColor3=C.TextPrimary},0.15)
            Utils.Tween(hint,{TextTransparency=1},0.15)
            if not inp:IsFocused() then Utils.Tween(stroke,{Color=IDLE_STROKE,Transparency=0.5},0.15) end
        end
    end

    inp:GetPropertyChangedSignal("Text"):Connect(function()
        setPending(inp.Text ~= confirmed)
    end)
    inp.Focused:Connect(function()
        Utils.Tween(stroke,{Color=pending and PENDING or C.Accent,Transparency=0},0.2)
    end)
    inp.FocusLost:Connect(function(enter)
        if enter then
            confirmed=inp.Text; setPending(false)
            Utils.Tween(stroke,{Color=IDLE_STROKE,Transparency=0.5},0.2)
            if callback then callback(inp.Text,inp) end
        else
            Utils.Tween(stroke,{Color=pending and PENDING_STROKE or IDLE_STROKE,Transparency=pending and 0.3 or 0.5},0.2)
        end
    end)

    return {Frame=f, Input=inp, SetText=function(t) confirmed=tostring(t); inp.Text=confirmed; setPending(false) end,
        GetText=function() return inp.Text end}
end

-- ========== BUTTON ==========
function Components.CreateButton(parent, text, color, callback, order)
    local btn = Instance.new("TextButton"); btn.Size=UDim2.new(1,0,0,38); btn.BackgroundColor3=color or C.Accent
    btn.Text=text; btn.TextColor3=C.TextPrimary; btn.Font=Enum.Font.GothamBold; btn.TextSize=14
    btn.AutoButtonColor=false; btn.LayoutOrder=order or 0; btn.ClipsDescendants=true; btn.Parent=parent
    Utils.CreateCorner(btn,8); Utils.AddHover(btn,0.15,0)
    btn.MouseButton1Click:Connect(function()
        Utils.AnimateClick(btn); Utils.Ripple(btn,State.Mouse.X,State.Mouse.Y)
        if callback then callback(btn) end
    end)
    return btn
end

-- ========== INFO ROW ==========
function Components.CreateInfoRow(parent, icon, label, value, color, order)
    local f = Instance.new("Frame"); f.Size=UDim2.new(1,0,0,26); f.BackgroundTransparency=1
    f.LayoutOrder=order or 0; f.Parent=parent
    local l = Instance.new("TextLabel"); l.Size=UDim2.new(0.5,0,1,0); l.BackgroundTransparency=1
    l.Text=icon.." "..label; l.TextColor3=C.TextSecondary; l.Font=Enum.Font.GothamMedium; l.TextSize=13
    l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=f
    local v = Instance.new("TextLabel"); v.Name="Value"; v.Size=UDim2.new(0.5,-10,1,0)
    v.Position=UDim2.new(0.5,0,0,0); v.BackgroundTransparency=1; v.Text=tostring(value)
    v.TextColor3=color or C.TextPrimary; v.Font=Enum.Font.GothamBold; v.TextSize=13
    v.TextXAlignment=Enum.TextXAlignment.Right; v.Parent=f
    return v
end

-- ========== HOTKEY ROW ==========
function Components.CreateHotkeyRow(parent, key, desc, order)
    local f = Instance.new("Frame"); f.Size=UDim2.new(1,0,0,30); f.BackgroundTransparency=1
    f.LayoutOrder=order or 0; f.Parent=parent
    local badge = Instance.new("Frame"); badge.Size=UDim2.new(0,32,0,24); badge.Position=UDim2.new(0,0,0.5,-12)
    badge.BackgroundColor3=C.SurfaceLight; badge.BorderSizePixel=0; badge.Parent=f
    Utils.CreateCorner(badge,6); Utils.CreateStroke(badge,C.Accent,1,0.5)
    local kl = Instance.new("TextLabel"); kl.Size=UDim2.new(1,0,1,0); kl.BackgroundTransparency=1
    kl.Text=key; kl.TextColor3=C.Accent; kl.Font=Enum.Font.GothamBlack; kl.TextSize=13; kl.Parent=badge
    local dl = Instance.new("TextLabel"); dl.Size=UDim2.new(1,-44,1,0); dl.Position=UDim2.new(0,42,0,0)
    dl.BackgroundTransparency=1; dl.Text=desc; dl.TextColor3=C.TextSecondary; dl.Font=Enum.Font.GothamMedium
    dl.TextSize=13; dl.TextXAlignment=Enum.TextXAlignment.Left; dl.Parent=f
    return f
end

-- ========== THEME PICKER ==========
function Components.CreateThemePicker(parent, callback, order)
    local f = Instance.new("Frame"); f.Size=UDim2.new(1,0,0,40); f.BackgroundTransparency=1
    f.LayoutOrder=order or 0; f.Parent=parent
    local layout = Instance.new("UIListLayout"); layout.FillDirection=Enum.FillDirection.Horizontal
    layout.Padding=UDim.new(0,8); layout.HorizontalAlignment=Enum.HorizontalAlignment.Center; layout.Parent=f

    local themeNames = {"Vape","Ocean","Crimson","Emerald","Gold"}
    local icons = {"🟣","🔵","🔴","🟢","🟡"}
    local buttons = {}

    for i, name in ipairs(themeNames) do
        local theme = Config.Themes[name]
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 60, 0, 34)
        btn.BackgroundColor3 = theme.Accent
        btn.BackgroundTransparency = Config.CurrentTheme == name and 0 or 0.5
        btn.Text = icons[i]
        btn.TextSize = 16
        btn.Font = Enum.Font.GothamBold
        btn.AutoButtonColor = false
        btn.Parent = f
        Utils.CreateCorner(btn, 8)

        local stroke = Utils.CreateStroke(btn,
            Config.CurrentTheme == name and Color3.new(1,1,1) or theme.Accent, 
            Config.CurrentTheme == name and 2 or 1, 
            Config.CurrentTheme == name and 0 or 0.5
        )

        buttons[name] = {btn = btn, stroke = stroke}

        btn.MouseButton1Click:Connect(function()
            for n, b in pairs(buttons) do
                Utils.Tween(b.btn, {BackgroundTransparency = n==name and 0 or 0.5}, 0.2)
                Utils.Tween(b.stroke, {
                    Color = n==name and Color3.new(1,1,1) or Config.Themes[n].Accent,
                    Thickness = n==name and 2 or 1,
                    Transparency = n==name and 0 or 0.5
                }, 0.2)
            end
            if callback then callback(name) end
        end)
    end

    return f
end

-- ========== OFFSET INPUTS ==========
function Components.CreateOffsetInputs(parent, offset, callback, order)
    local f = Instance.new("Frame"); f.Size=UDim2.new(1,0,0,58); f.BackgroundTransparency=1
    f.LayoutOrder=order or 0; f.Parent=parent
    local lbl = Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,0,18); lbl.BackgroundTransparency=1
    lbl.Text="📏 Offset (X, Y, Z)"; lbl.TextColor3=C.TextSecondary; lbl.Font=Enum.Font.GothamMedium
    lbl.TextSize=12; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=f

    local inputs = {}
    local confirmed = {}
    local labels = {"X","Y","Z"}
    local defaults = {offset.X, offset.Y, offset.Z}

    for i=1,3 do
        confirmed[i] = tostring(defaults[i])
        local bg = Instance.new("Frame"); bg.Size=UDim2.new(0.31,0,0,34)
        bg.Position=UDim2.new((i-1)*0.345,0,0,22); bg.BackgroundColor3=C.Surface; bg.BorderSizePixel=0
        bg.Parent=f; Utils.CreateCorner(bg,8)
        local st = Utils.CreateStroke(bg,IDLE_STROKE,1,0.5)

        local al = Instance.new("TextLabel"); al.Size=UDim2.new(0,20,1,0); al.Position=UDim2.new(0,4,0,0)
        al.BackgroundTransparency=1; al.Text=labels[i]; al.TextColor3=C.Accent; al.Font=Enum.Font.GothamBold
        al.TextSize=12; al.Parent=bg

        local inp = Instance.new("TextBox"); inp.Size=UDim2.new(1,-28,1,0); inp.Position=UDim2.new(0,24,0,0)
        inp.BackgroundTransparency=1; inp.Text=confirmed[i]; inp.TextColor3=C.TextPrimary
        inp.Font=Enum.Font.GothamMedium; inp.TextSize=14; inp.ClearTextOnFocus=false; inp.Parent=bg

        local idx=i
        inp:GetPropertyChangedSignal("Text"):Connect(function()
            if inp.Text~=confirmed[idx] then
                Utils.Tween(inp,{TextColor3=PENDING},0.15)
                Utils.Tween(st,{Color=PENDING_STROKE,Transparency=0.3},0.15)
            else
                Utils.Tween(inp,{TextColor3=C.TextPrimary},0.15)
                Utils.Tween(st,{Color=IDLE_STROKE,Transparency=0.5},0.15)
            end
        end)
        inp.Focused:Connect(function() Utils.Tween(st,{Color=C.Accent,Transparency=0},0.2) end)
        inp.FocusLost:Connect(function(enter)
            if enter then confirmed[idx]=inp.Text; Utils.Tween(inp,{TextColor3=C.TextPrimary},0.15)
                Utils.Tween(st,{Color=IDLE_STROKE,Transparency=0.5},0.2)
                if callback then callback() end
            else
                local p = inp.Text~=confirmed[idx]
                Utils.Tween(st,{Color=p and PENDING_STROKE or IDLE_STROKE,Transparency=p and 0.3 or 0.5},0.2)
            end
        end)
        inputs[i] = inp
    end

    return {Frame=f, GetOffset=function()
        return Vector3.new(tonumber(inputs[1].Text) or 0, tonumber(inputs[2].Text) or 0, tonumber(inputs[3].Text) or 0)
    end, Inputs=inputs}
end

return Components
