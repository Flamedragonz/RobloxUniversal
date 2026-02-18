--[[
    ╔══════════════════════════════════════╗
    ║  MODULE: utils.lua                   ║
    ║  Утилиты: анимации, tween, визуал    ║
    ║                                      ║
    ║  Зависимости: НЕТ                    ║
    ║                                      ║
    ║  RAW ссылка → loader.lua →           ║
    ║  loadModule("utils")                 ║
    ╚══════════════════════════════════════╝
]]

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Utils = {}

-- ========== UI CREATION HELPERS ==========

function Utils.CreateCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

function Utils.CreateStroke(parent, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(50, 50, 60)
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0.5
    stroke.Parent = parent
    return stroke
end

function Utils.CreatePadding(parent, top, bottom, left, right)
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, top or 0)
    padding.PaddingBottom = UDim.new(0, bottom or 0)
    padding.PaddingLeft = UDim.new(0, left or 0)
    padding.PaddingRight = UDim.new(0, right or 0)
    padding.Parent = parent
    return padding
end

function Utils.CreateGradient(parent, color1, color2, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(color1, color2)
    gradient.Rotation = rotation or 45
    gradient.Parent = parent
    return gradient
end

function Utils.CreateListLayout(parent, direction, padding, sortOrder)
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = direction or Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0, padding or 8)
    layout.SortOrder = sortOrder or Enum.SortOrder.LayoutOrder
    layout.Parent = parent
    return layout
end

-- ========== SHADOW ==========
function Utils.CreateShadow(parent)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Image = "rbxassetid://6015897843"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.Parent = parent
    return shadow
end

-- ========== ANIMATION ==========

function Utils.Tween(object, properties, duration, easingStyle, easingDirection)
    local info = TweenInfo.new(
        duration or 0.2,
        easingStyle or Enum.EasingStyle.Quad,
        easingDirection or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(object, info, properties)
    tween:Play()
    return tween
end

function Utils.AnimateClick(button)
    local original = button.Size
    Utils.Tween(button, {
        Size = UDim2.new(
            original.X.Scale, original.X.Offset - 4,
            original.Y.Scale, original.Y.Offset - 2
        )
    }, 0.06)
    task.delay(0.06, function()
        Utils.Tween(button, {Size = original}, 0.08)
    end)
end

function Utils.Ripple(button, mouseX, mouseY)
    local ripple = Instance.new("Frame")
    ripple.BackgroundColor3 = Color3.new(1, 1, 1)
    ripple.BackgroundTransparency = 0.7
    ripple.BorderSizePixel = 0
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.Position = UDim2.new(
        0, mouseX - button.AbsolutePosition.X,
        0, mouseY - button.AbsolutePosition.Y
    )
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.ZIndex = button.ZIndex + 1
    ripple.Parent = button
    Utils.CreateCorner(ripple, 100)

    local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.5
    Utils.Tween(ripple, {
        Size = UDim2.new(0, maxSize, 0, maxSize),
        BackgroundTransparency = 1
    }, 0.5)
    task.delay(0.5, function()
        ripple:Destroy()
    end)
end

-- ========== HOVER EFFECT ==========

function Utils.AddHover(button, hoverTransparency, normalTransparency)
    hoverTransparency = hoverTransparency or 0.1
    normalTransparency = normalTransparency or 0.3

    button.MouseEnter:Connect(function()
        Utils.Tween(button, {BackgroundTransparency = hoverTransparency}, 0.15)
    end)
    button.MouseLeave:Connect(function()
        Utils.Tween(button, {BackgroundTransparency = normalTransparency}, 0.15)
    end)
end

return Utils
