local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local SETTINGS = {
    FolderPath = "ItemDebris", 
    PartName = "", 
    StackMode = true,
    Offset = Vector3.new(0, 0, 0),
    Spacing = 2,
    LoopMode = true,
    LoopInterval = 1,
    RespawnProtection = true,
    SmoothTeleport = false,
    SmoothSpeed = 25,
    TargetMode = "Player", 
    TargetPartName = "",   
    MaxParts = 50          
}

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local stats = {
    collectedParts = 0,
    startTime = tick()
}

local partsToTeleport = {}
local connections = {}
local gui
local isRunning = true
local isActive = true
local loopActive = false 
local uiElements = {} 

local isSelectingTarget = false
local customTargetPart = nil 
local selectionBox = nil

local function createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

local function animateClick(btn)
    local originalSize = btn.Size
    local tweenInfo = TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
    local tween = TweenService:Create(btn, tweenInfo, {Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset - 2, originalSize.Y.Scale, originalSize.Y.Offset - 2)})
    tween:Play()
end

local function setupInputVisuals(inputBox, getCurrentValueFunc)
    inputBox:GetPropertyChangedSignal("Text"):Connect(function()
        local currentVal = tostring(getCurrentValueFunc())
        if inputBox.Text ~= currentVal then
            inputBox.TextColor3 = Color3.fromRGB(255, 255, 0) -- Желтый
        else
            inputBox.TextColor3 = Color3.fromRGB(255, 255, 255) -- Белый
        end
    end)
end

local function getFolderByPath(path)
    if not path or path == "" or path == "Workspace" then return workspace end
    local current = workspace
    for part in string.gmatch(path, "[^/]+") do
        current = current:FindFirstChild(part)
        if not current then return nil end
    end
    return current
end

local function findAllFoldersByNameGlobal(folderName)
    if not folderName or folderName == "" then return {workspace} end
    local found = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Folder") and obj.Name == folderName then
            table.insert(found, obj)
        end
    end
    return found
end

local function getAllParts(container)
    local parts = {}
    local items = (container == workspace) and container:GetChildren() or container:GetDescendants()
    for _, descendant in pairs(items) do
        if descendant:IsA("BasePart") then
            local isPlayerPart = false
            local ancestor = descendant.Parent
            while ancestor do
                if ancestor:IsA("Model") and Players:GetPlayerFromCharacter(ancestor) then
                    isPlayerPart = true
                    break
                end
                ancestor = ancestor.Parent
            end
            if not isPlayerPart then table.insert(parts, descendant) end
        end
    end
    return parts
end

local function findAllPartsByName(container, partName)
    local foundParts = {}
    local items = (container == workspace) and container:GetChildren() or container:GetDescendants()
    for _, descendant in pairs(items) do
        if descendant:IsA("BasePart") and descendant.Name == partName then
            local isPlayerPart = false
            local ancestor = descendant.Parent
            while ancestor do
                if ancestor:IsA("Model") and Players:GetPlayerFromCharacter(ancestor) then
                    isPlayerPart = true
                    break
                end
                ancestor = ancestor.Parent
            end
            if not isPlayerPart then table.insert(foundParts, descendant) end
        end
    end
    return foundParts
end

local function preparePart(part)
    if not part:GetAttribute("TeleportPrepared") then
        pcall(function()
            part.Anchored = false
            part.CanCollide = false
            for _, child in pairs(part:GetChildren()) do
                if child:IsA("BodyMover") or child:IsA("Constraint") then child:Destroy() end
            end
            if part:FindFirstChild("TeleportBodyVelocity") then part.TeleportBodyVelocity:Destroy() end
            if part:FindFirstChild("TeleportBodyGyro") then part.TeleportBodyGyro:Destroy() end

            if SETTINGS.SmoothTeleport then
                local bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.Name = "TeleportBodyVelocity"
                bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                bodyVelocity.Parent = part
                
                local bodyGyro = Instance.new("BodyGyro")
                bodyGyro.Name = "TeleportBodyGyro"
                bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                bodyGyro.P = 10000
                bodyGyro.D = 500
                bodyGyro.Parent = part
            end
            part:SetAttribute("TeleportPrepared", true)
        end)
    end
end

local function releaseAllParts()
    for _, part in pairs(partsToTeleport) do
        if part and part.Parent then
            pcall(function()
                part:SetAttribute("TeleportPrepared", nil)
                if part:FindFirstChild("TeleportBodyVelocity") then part.TeleportBodyVelocity:Destroy() end
                if part:FindFirstChild("TeleportBodyGyro") then part.TeleportBodyGyro:Destroy() end
            end)
        end
    end
    partsToTeleport = {}
end

local function collectParts()
    if not isActive then return false end
    if #partsToTeleport >= SETTINGS.MaxParts then return end
    
    local folders = {}
    local exactFolder = getFolderByPath(SETTINGS.FolderPath)
    
    if exactFolder then
        table.insert(folders, exactFolder)
    else
        local folderName = SETTINGS.FolderPath:match("[^/]+$")
        if folderName then
            local foundFolders = findAllFoldersByNameGlobal(folderName)
            for _, f in pairs(foundFolders) do table.insert(folders, f) end
        end
    end

    if #folders == 0 then return false end
    
    local addedCount = 0
    for _, folder in pairs(folders) do
        if #partsToTeleport >= SETTINGS.MaxParts then break end
        
        local candidates = {}
        if SETTINGS.PartName and SETTINGS.PartName ~= "" then
            candidates = findAllPartsByName(folder, SETTINGS.PartName)
        else
            candidates = getAllParts(folder)
        end
        
        for _, part in pairs(candidates) do
            if #partsToTeleport >= SETTINGS.MaxParts then break end
            
            if not table.find(partsToTeleport, part) and part ~= customTargetPart then
                preparePart(part)
                table.insert(partsToTeleport, part)
                addedCount = addedCount + 1
            end
        end
    end
    return addedCount > 0
end

local function updateTargetLogic()
    for _, part in pairs(partsToTeleport) do
        if part and part.Parent then
            part:SetAttribute("TeleportPrepared", nil)
            preparePart(part)
        end
    end
end

local function updateSelectionBox(target)
    if not selectionBox then
        selectionBox = Instance.new("SelectionBox")
        selectionBox.Color3 = Color3.fromRGB(255, 0, 0) 
        selectionBox.LineThickness = 0.05
        selectionBox.Adornee = nil
        selectionBox.Parent = player.PlayerGui
    end
    selectionBox.Adornee = target
end

local function findCustomTargetByName()
    if SETTINGS.TargetPartName == "" then return nil end
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name == SETTINGS.TargetPartName then
            return v
        end
    end
    return nil
end

local function startTeleportation()
    local teleportConnection = RunService.Heartbeat:Connect(function()
        if not isRunning or not isActive then return end
        if SETTINGS.LoopMode and not loopActive then return end
        
        pcall(function()
            local targetBasePos = Vector3.new(0,0,0)
            local targetCFrame = CFrame.new()

            if SETTINGS.TargetMode == "Mouse" then
                targetBasePos = mouse.Hit.Position
                targetCFrame = CFrame.new(targetBasePos)
            elseif SETTINGS.TargetMode == "CustomPart" then
                local tPart = customTargetPart
                if not tPart or not tPart.Parent then
                   tPart = findCustomTargetByName()
                end
                
                if tPart then
                    targetBasePos = tPart.Position
                    targetCFrame = tPart.CFrame
                    updateSelectionBox(tPart)
                else
                     if character and character:FindFirstChild("HumanoidRootPart") then
                         targetBasePos = character.HumanoidRootPart.Position
                         targetCFrame = character.HumanoidRootPart.CFrame
                     end
                end
            else
                if character and character:FindFirstChild("HumanoidRootPart") then
                    targetBasePos = character.HumanoidRootPart.Position
                    targetCFrame = character.HumanoidRootPart.CFrame
                end
                updateSelectionBox(nil)
            end
            
            local finalTarget = targetBasePos + SETTINGS.Offset
            
            for i = #partsToTeleport, 1, -1 do
                local part = partsToTeleport[i]
                if not part or not part.Parent then
                    table.remove(partsToTeleport, i)
                    stats.collectedParts = stats.collectedParts + 1
                else
                    pcall(function()
                        local destPos
                        if SETTINGS.StackMode then
                            destPos = finalTarget
                        else
                            local spacingOffset = Vector3.new((i - 1) * SETTINGS.Spacing, 0, 0)
                            destPos = finalTarget + spacingOffset
                        end
                        
                        if SETTINGS.SmoothTeleport then
                            local bodyVel = part:FindFirstChild("TeleportBodyVelocity")
                            if not bodyVel then preparePart(part) return end
                            if bodyVel then
                                local direction = (destPos - part.Position).Unit
                                local distance = (destPos - part.Position).Magnitude
                                local speed = math.min(distance * SETTINGS.SmoothSpeed / 10, SETTINGS.SmoothSpeed)
                                bodyVel.Velocity = direction * speed
                            end
                            local bodyGyro = part:FindFirstChild("TeleportBodyGyro")
                            if bodyGyro then bodyGyro.CFrame = targetCFrame end
                        else
                            part.CFrame = CFrame.new(destPos)
                            part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                        end
                    end)
                end
            end
        end)
    end)
    table.insert(connections, teleportConnection)
end


local function createGUI()
    local oldGui = player.PlayerGui:FindFirstChild("TeleportControlGUI")
    if oldGui then oldGui:Destroy() end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TeleportControlGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = player.PlayerGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 420, 0, 580) 
    mainFrame.Position = UDim2.new(0.5, -210, 0.5, -290)
    mainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 24)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    createCorner(mainFrame, 14)

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 45)
    header.BackgroundColor3 = Color3.fromRGB(30, 30, 32)
    header.Parent = mainFrame
    createCorner(header, 14)
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 1, 0)
    titleLabel.Position = UDim2.new(0, 20, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Teleport Control Panel"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 18
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = header

    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, -20, 0, 36)
    tabContainer.Position = UDim2.new(0, 10, 0, 55)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = mainFrame
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 10)
    tabLayout.Parent = tabContainer

    local pages = Instance.new("Frame")
    pages.Size = UDim2.new(1, -20, 1, -190) 
    pages.Position = UDim2.new(0, 10, 0, 100)
    pages.BackgroundTransparency = 1
    pages.ClipsDescendants = true
    pages.Parent = mainFrame

    local function createTab(text, pageFrame)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.5, -5, 1, 0)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(150, 150, 160)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 16
        btn.Parent = tabContainer
        createCorner(btn, 10)
        
        btn.MouseButton1Click:Connect(function()
            for _, child in pairs(tabContainer:GetChildren()) do
                if child:IsA("TextButton") then
                    child.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                    child.TextColor3 = Color3.fromRGB(150, 150, 160)
                end
            end
            for _, child in pairs(pages:GetChildren()) do
                if child:IsA("GuiObject") and not child:IsA("UIListLayout") then child.Visible = false end
            end
            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 200)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            pageFrame.Visible = true
        end)
        return btn
    end

    local statusPage = Instance.new("Frame")
    statusPage.Name = "StatusPage"
    statusPage.Size = UDim2.new(1, 0, 1, 0)
    statusPage.BackgroundTransparency = 1
    statusPage.Visible = true
    statusPage.Parent = pages

    local statusLayout = Instance.new("UIListLayout")
    statusLayout.SortOrder = Enum.SortOrder.LayoutOrder
    statusLayout.Padding = UDim.new(0, 12)
    statusLayout.Parent = statusPage

    local statusBar = Instance.new("Frame")
    statusBar.Size = UDim2.new(1, 0, 0, 50)
    statusBar.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    statusBar.LayoutOrder = 1
    statusBar.Parent = statusPage
    createCorner(statusBar, 10)
    
    local statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(1, 0, 1, 0)
    statusText.BackgroundTransparency = 1
    statusText.Text = "✅ ACTIVE"
    statusText.TextColor3 = Color3.fromRGB(100, 255, 100)
    statusText.Font = Enum.Font.GothamBlack
    statusText.TextSize = 22
    statusText.Parent = statusBar
    uiElements.statusText = statusText
    uiElements.statusBar = statusBar

    local infoGrid = Instance.new("Frame")
    infoGrid.Size = UDim2.new(1, 0, 0, 220)
    infoGrid.BackgroundTransparency = 1
    infoGrid.LayoutOrder = 2
    infoGrid.Parent = statusPage

    local col1 = Instance.new("Frame"); col1.Size = UDim2.new(0.5, -5, 1, 0); col1.BackgroundTransparency = 1; col1.Parent = infoGrid
    local col2 = Instance.new("Frame"); col2.Size = UDim2.new(0.5, -5, 1, 0); col2.Position = UDim2.new(0.5, 5, 0, 0); col2.BackgroundTransparency = 1; col2.Parent = infoGrid
    local list1 = Instance.new("UIListLayout"); list1.Padding = UDim.new(0, 6); list1.Parent = col1
    local list2 = Instance.new("UIListLayout"); list2.Padding = UDim.new(0, 6); list2.Parent = col2

    local function createInfoLabel(parent, text, color)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, 26)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = color
        l.Font = Enum.Font.GothamBold
        l.TextSize = 14
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = parent
        return l
    end

    uiElements.ping = createInfoLabel(col1, "Ping: ...", Color3.fromRGB(255, 100, 100))
    uiElements.collected = createInfoLabel(col1, "Collected: 0", Color3.fromRGB(255, 200, 100))
    uiElements.active = createInfoLabel(col1, "Active: 0", Color3.fromRGB(100, 200, 255))
    uiElements.mode = createInfoLabel(col1, "Mode: Loop", Color3.fromRGB(150, 150, 255))
    uiElements.kStatus = createInfoLabel(col1, "Key K: ...", Color3.fromRGB(150, 255, 150))
    
    uiElements.folder = createInfoLabel(col2, "Folder: " .. (SETTINGS.FolderPath == "" and "Workspace" or SETTINGS.FolderPath), Color3.fromRGB(180, 180, 180))
    uiElements.partName = createInfoLabel(col2, "Filter: " .. (SETTINGS.PartName == "" and "ALL" or SETTINGS.PartName), Color3.fromRGB(255, 220, 100))
    uiElements.target = createInfoLabel(col2, "Target: Player", Color3.fromRGB(180, 180, 180))
    uiElements.tpType = createInfoLabel(col2, "TP: Instant", Color3.fromRGB(180, 180, 180))

    local settingsPage = Instance.new("ScrollingFrame")
    settingsPage.Name = "SettingsPage"
    settingsPage.Size = UDim2.new(1, 0, 1, 0)
    settingsPage.BackgroundTransparency = 1
    settingsPage.Visible = false
    settingsPage.ScrollBarThickness = 6
    settingsPage.BorderSizePixel = 0
    settingsPage.AutomaticCanvasSize = Enum.AutomaticSize.Y 
    settingsPage.CanvasSize = UDim2.new(0, 0, 0, 0) 
    settingsPage.Parent = pages
    
    local settingsLayout = Instance.new("UIListLayout")
    settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    settingsLayout.Padding = UDim.new(0, 12)
    settingsLayout.Parent = settingsPage

    local padding = Instance.new("UIPadding")
    padding.PaddingBottom = UDim.new(0, 60)
    padding.Parent = settingsPage

    local function createSettingInput(name, placeholder, value, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 55)
        frame.BackgroundTransparency = 1
        frame.Parent = settingsPage
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 20)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.fromRGB(200, 200, 200)
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 15
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame
        
        local input = Instance.new("TextBox")
        input.Size = UDim2.new(1, 0, 0, 32)
        input.Position = UDim2.new(0, 0, 0, 23)
        input.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        input.Text = tostring(value)
        input.PlaceholderText = placeholder
        input.TextColor3 = Color3.fromRGB(255, 255, 255)
        input.Font = Enum.Font.GothamBold
        input.TextSize = 16
        input.ClearTextOnFocus = false 
        input.Parent = frame
        createCorner(input, 8)
        
        setupInputVisuals(input, function() return value end)
        
        input.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                callback(input.Text, input)
                input.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        end)
        return input
    end
    
    local function createSettingToggle(name, value, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 36)
        frame.BackgroundTransparency = 1
        frame.Parent = settingsPage
        local label = Instance.new("TextLabel"); label.Size = UDim2.new(0.7, 0, 1, 0); label.BackgroundTransparency = 1; label.Text = name; label.TextColor3 = Color3.fromRGB(220, 220, 220); label.Font = Enum.Font.GothamMedium; label.TextSize = 16; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = frame
        local btn = Instance.new("TextButton"); btn.Size = UDim2.new(0.25, 0, 1, 0); btn.Position = UDim2.new(0.75, 0, 0, 0); btn.BackgroundColor3 = value and Color3.fromRGB(60, 160, 60) or Color3.fromRGB(160, 60, 60); btn.Text = value and "ON" or "OFF"; btn.TextColor3 = Color3.new(1,1,1); btn.TextSize = 14; btn.Font = Enum.Font.GothamBold; btn.Parent = frame; createCorner(btn, 8)
        btn.MouseButton1Click:Connect(function()
            value = not value
            btn.Text = value and "ON" or "OFF"
            btn.BackgroundColor3 = value and Color3.fromRGB(60, 160, 60) or Color3.fromRGB(160, 60, 60)
            callback(value, btn)
        end)
        return btn
    end

    createSettingInput("📂 Folder Path (Empty = Workspace)", "e.g. ItemDebris", SETTINGS.FolderPath, function(txt, inputObj)
        SETTINGS.FolderPath = txt 
        uiElements.folder.Text = "Folder: " .. (txt == "" and "Workspace" or txt)
    end)
    
    createSettingInput("🧱 Max Active Parts (Anti-Lag Limit)", "50", SETTINGS.MaxParts, function(txt)
        local num = tonumber(txt)
        if num and num > 0 then SETTINGS.MaxParts = num end
    end)
    
    createSettingInput("🧩 Filter Part Name (Empty = ALL)", "e.g. Gold", SETTINGS.PartName, function(txt, inputObj)
        SETTINGS.PartName = txt
        uiElements.partName.Text = "Filter: " .. (txt == "" and "ALL" or txt)
    end)
    
    local targetContainer = Instance.new("Frame")
    targetContainer.BackgroundTransparency = 1
    targetContainer.AutomaticSize = Enum.AutomaticSize.Y 
    targetContainer.Size = UDim2.new(1, -10, 0, 0)
    targetContainer.Parent = settingsPage
    
    local targetLayout = Instance.new("UIListLayout")
    targetLayout.SortOrder = Enum.SortOrder.LayoutOrder
    targetLayout.Padding = UDim.new(0, 10)
    targetLayout.Parent = targetContainer
    
    local customTargetGroup = Instance.new("Frame")
    customTargetGroup.BackgroundTransparency = 1
    customTargetGroup.Size = UDim2.new(1, 0, 0, 90)
    customTargetGroup.Visible = false 
    customTargetGroup.LayoutOrder = 2
    customTargetGroup.Parent = targetContainer

    local mouseToggleBtn 
    local customTargetInput
    local selectClickBtn
    
    local function updateTargetUI()
        if SETTINGS.TargetMode == "Mouse" then
            customTargetGroup.Visible = false
            uiElements.target.Text = "Target: Mouse"
        else
            customTargetGroup.Visible = true
            uiElements.target.Text = "Target: " .. (customTargetPart and customTargetPart.Name or (SETTINGS.TargetPartName == "" and "Player" or SETTINGS.TargetPartName))
        end
    end

    local tgFrame = Instance.new("Frame")
    tgFrame.Size = UDim2.new(1, 0, 0, 36)
    tgFrame.BackgroundTransparency = 1
    tgFrame.LayoutOrder = 1
    tgFrame.Parent = targetContainer
    
    local tgLabel = Instance.new("TextLabel"); tgLabel.Size = UDim2.new(0.7, 0, 1, 0); tgLabel.BackgroundTransparency = 1; tgLabel.Text = "🎯 Mouse Target"; tgLabel.TextColor3 = Color3.fromRGB(220, 220, 220); tgLabel.Font = Enum.Font.GothamMedium; tgLabel.TextSize = 16; tgLabel.TextXAlignment = Enum.TextXAlignment.Left; tgLabel.Parent = tgFrame
    local tgBtn = Instance.new("TextButton"); tgBtn.Size = UDim2.new(0.25, 0, 1, 0); tgBtn.Position = UDim2.new(0.75, 0, 0, 0); 
    tgBtn.BackgroundColor3 = (SETTINGS.TargetMode == "Mouse") and Color3.fromRGB(60, 160, 60) or Color3.fromRGB(160, 60, 60); 
    tgBtn.Text = (SETTINGS.TargetMode == "Mouse") and "ON" or "OFF"; tgBtn.TextColor3 = Color3.new(1,1,1); tgBtn.TextSize = 14; tgBtn.Font = Enum.Font.GothamBold; tgBtn.Parent = tgFrame; createCorner(tgBtn, 8)
    
    tgBtn.MouseButton1Click:Connect(function()
        local isMouse = (SETTINGS.TargetMode == "Mouse")
        isMouse = not isMouse
        SETTINGS.TargetMode = isMouse and "Mouse" or "CustomPart"
        tgBtn.Text = isMouse and "ON" or "OFF"
        tgBtn.BackgroundColor3 = isMouse and Color3.fromRGB(60, 160, 60) or Color3.fromRGB(160, 60, 60)
        updateTargetUI()
    end)
    
    local ctFrame = Instance.new("Frame")
    ctFrame.Size = UDim2.new(1, 0, 0, 55)
    ctFrame.BackgroundTransparency = 1
    ctFrame.Parent = customTargetGroup
    
    local ctLabel = Instance.new("TextLabel"); ctLabel.Size = UDim2.new(1, 0, 0, 20); ctLabel.BackgroundTransparency = 1; ctLabel.Text = "📍 Custom Target Name"; ctLabel.TextColor3 = Color3.fromRGB(200, 200, 200); ctLabel.Font = Enum.Font.GothamMedium; ctLabel.TextSize = 15; ctLabel.TextXAlignment = Enum.TextXAlignment.Left; ctLabel.Parent = ctFrame
    customTargetInput = Instance.new("TextBox"); customTargetInput.Size = UDim2.new(1, 0, 0, 32); customTargetInput.Position = UDim2.new(0, 0, 0, 23); customTargetInput.BackgroundColor3 = Color3.fromRGB(45, 45, 50); customTargetInput.Text = SETTINGS.TargetPartName; customTargetInput.PlaceholderText = "Part Name"; customTargetInput.TextColor3 = Color3.fromRGB(255, 255, 255); customTargetInput.Font = Enum.Font.GothamBold; customTargetInput.TextSize = 16; customTargetInput.ClearTextOnFocus = false; customTargetInput.Parent = ctFrame; createCorner(customTargetInput, 8)
    
    setupInputVisuals(customTargetInput, function() return SETTINGS.TargetPartName end)
    customTargetInput.FocusLost:Connect(function(enter)
        if enter then
            SETTINGS.TargetPartName = customTargetInput.Text
            if customTargetInput.Text ~= "" then customTargetPart = nil; updateSelectionBox(nil) end
            updateTargetUI()
            customTargetInput.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end)
    
    selectClickBtn = Instance.new("TextButton")
    selectClickBtn.Size = UDim2.new(1, 0, 0, 30)
    selectClickBtn.Position = UDim2.new(0, 0, 0, 60) 
    selectClickBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
    selectClickBtn.Text = "👆 Select w/ Click (Target)"
    selectClickBtn.TextColor3 = Color3.new(1,1,1)
    selectClickBtn.Font = Enum.Font.GothamBold
    selectClickBtn.TextSize = 14
    selectClickBtn.Parent = customTargetGroup
    createCorner(selectClickBtn, 6)
    
    selectClickBtn.MouseButton1Click:Connect(function()
        if isSelectingTarget then
            isSelectingTarget = false
            selectClickBtn.Text = "👆 Select w/ Click (Target)"
            selectClickBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
        else
            isSelectingTarget = true
            selectClickBtn.Text = "🔴 CLICK ANY PART NOW..."
            selectClickBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        end
    end)
    
    updateTargetUI()

    local offsetFrame = Instance.new("Frame")
    offsetFrame.Size = UDim2.new(1, -10, 0, 60); offsetFrame.BackgroundTransparency = 1; offsetFrame.Parent = settingsPage
    local offLabel = Instance.new("TextLabel"); offLabel.Text = "📏 Offset (X, Y, Z)"; offLabel.Size = UDim2.new(1,0,0,20); offLabel.BackgroundTransparency=1; offLabel.TextColor3=Color3.fromRGB(200,200,200); offLabel.Font=Enum.Font.GothamMedium; offLabel.TextSize=15; offLabel.TextXAlignment=Enum.TextXAlignment.Left; offLabel.Parent=offsetFrame
    local offX = Instance.new("TextBox"); offX.Size = UDim2.new(0.3,0,0,32); offX.Position = UDim2.new(0,0,0,25); offX.Text=SETTINGS.Offset.X; offX.BackgroundColor3=Color3.fromRGB(45,45,50); offX.TextColor3=Color3.new(1,1,1); offX.Font=Enum.Font.GothamBold; offX.TextSize=16; offX.ClearTextOnFocus=false; offX.Parent=offsetFrame; createCorner(offX,8)
    local offY = Instance.new("TextBox"); offY.Size = UDim2.new(0.3,0,0,32); offY.Position = UDim2.new(0.35,0,0,25); offY.Text=SETTINGS.Offset.Y; offY.BackgroundColor3=Color3.fromRGB(45,45,50); offY.TextColor3=Color3.new(1,1,1); offY.Font=Enum.Font.GothamBold; offY.TextSize=16; offY.ClearTextOnFocus=false; offY.Parent=offsetFrame; createCorner(offY,8)
    local offZ = Instance.new("TextBox"); offZ.Size = UDim2.new(0.3,0,0,32); offZ.Position = UDim2.new(0.7,0,0,25); offZ.Text=SETTINGS.Offset.Z; offZ.BackgroundColor3=Color3.fromRGB(45,45,50); offZ.TextColor3=Color3.new(1,1,1); offZ.Font=Enum.Font.GothamBold; offZ.TextSize=16; offZ.ClearTextOnFocus=false; offZ.Parent=offsetFrame; createCorner(offZ,8)
    
    local function updateOffset() SETTINGS.Offset = Vector3.new(tonumber(offX.Text) or 0, tonumber(offY.Text) or 0, tonumber(offZ.Text) or 0) end
    offX.FocusLost:Connect(updateOffset); offY.FocusLost:Connect(updateOffset); offZ.FocusLost:Connect(updateOffset)
    
    createSettingToggle("🥞 Stack Mode", SETTINGS.StackMode, function(val) SETTINGS.StackMode = val end)
    createSettingInput("⛓️ Spacing", "2", SETTINGS.Spacing, function(txt) SETTINGS.Spacing = tonumber(txt) or 2 end)
    createSettingToggle("⚡ Smooth Teleport", SETTINGS.SmoothTeleport, function(val) SETTINGS.SmoothTeleport = val; uiElements.tpType.Text = "TP: " .. (val and "Smooth" or "Instant"); updateTargetLogic() end)
    createSettingInput("💨 Smooth Speed", "25", SETTINGS.SmoothSpeed, function(txt) SETTINGS.SmoothSpeed = tonumber(txt) or 25 end)

    local footer = Instance.new("Frame"); footer.Size = UDim2.new(1, -20, 0, 90); footer.Position = UDim2.new(0, 10, 1, -110); footer.BackgroundTransparency = 1; footer.Parent = mainFrame
    local toggleBtn = Instance.new("TextButton"); toggleBtn.Size = UDim2.new(1, 0, 0, 44); toggleBtn.BackgroundColor3 = Color3.fromRGB(160, 100, 40); toggleBtn.Text = "⏸️ DEACTIVATE"; toggleBtn.TextColor3 = Color3.new(1,1,1); toggleBtn.Font = Enum.Font.GothamBold; toggleBtn.TextSize = 20; toggleBtn.Parent = footer; createCorner(toggleBtn, 10)
    toggleBtn.MouseButton1Click:Connect(function()
        animateClick(toggleBtn); isActive = not isActive
        if isActive then toggleBtn.Text = "⏸️ DEACTIVATE"; toggleBtn.BackgroundColor3 = Color3.fromRGB(160, 100, 40)
        else toggleBtn.Text = "▶️ ACTIVATE"; toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 160, 50); loopActive = false end
    end)
    
    local subContainer = Instance.new("Frame"); subContainer.Size = UDim2.new(1, 0, 0, 36); subContainer.Position = UDim2.new(0, 0, 0, 54); subContainer.BackgroundTransparency = 1; subContainer.Parent = footer

    local subLayout = Instance.new("UIListLayout"); subLayout.FillDirection = Enum.FillDirection.Horizontal; subLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; subLayout.Padding = UDim.new(0, 5); subLayout.Parent = subContainer
    
    local function createSubBtn(text, color, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.32, 0, 1, 0) 
        btn.BackgroundColor3 = color
        btn.Text = text
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.Parent = subContainer
        createCorner(btn, 8)
        btn.MouseButton1Click:Connect(function() animateClick(btn); callback() end)
        return btn
    end

    createSubBtn("🔁 Loop", Color3.fromRGB(50, 50, 140), function() SETTINGS.LoopMode = not SETTINGS.LoopMode; loopActive = false; uiElements.mode.Text = "Mode: " .. (SETTINGS.LoopMode and "Loop" or "Single") end)
    createSubBtn("🔓 Release", Color3.fromRGB(180, 120, 40), function() releaseAllParts() end) 
    createSubBtn("🗑️ Close", Color3.fromRGB(140, 50, 50), function() isRunning = false; isActive = false; screenGui:Destroy(); if selectionBox then selectionBox:Destroy() end; script:Destroy() end)
    
    local t1 = createTab("📊 Status", statusPage); local t2 = createTab("⚙️ Settings", settingsPage)
    t1.BackgroundColor3 = Color3.fromRGB(60, 60, 200); t1.TextColor3 = Color3.fromRGB(255, 255, 255)
    return screenGui, selectClickBtn, customTargetInput
end


local function updateStats()
    task.spawn(function()
        while isRunning and gui and gui.Parent do
            if uiElements.ping then local s, p = pcall(function() return math.round(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end); if s then uiElements.ping.Text = "Ping: " .. p .. " ms" end end
            if uiElements.collected then uiElements.collected.Text = "Collected: " .. stats.collectedParts end
            if uiElements.active then uiElements.active.Text = "Active: " .. #partsToTeleport .. " / " .. SETTINGS.MaxParts end
            if uiElements.statusText then
                if isActive then uiElements.statusText.Text = "✅ ACTIVE"; uiElements.statusText.TextColor3 = Color3.fromRGB(100, 255, 100); uiElements.statusBar.BackgroundColor3 = Color3.fromRGB(35, 45, 35)
                else uiElements.statusText.Text = "⏸️ PAUSED"; uiElements.statusText.TextColor3 = Color3.fromRGB(255, 200, 100); uiElements.statusBar.BackgroundColor3 = Color3.fromRGB(45, 40, 30) end
            end
            
            if uiElements.kStatus then
                if SETTINGS.LoopMode then
                    uiElements.kStatus.Text = "Key K: " .. (loopActive and "LOOP STOP" or "LOOP START")
                else
                    uiElements.kStatus.Text = "Key K: PULL ONCE"
                end
            end
            
            if uiElements.target then
                if SETTINGS.TargetMode == "Mouse" then uiElements.target.Text = "Target: Mouse"
                else uiElements.target.Text = "Target: " .. (customTargetPart and customTargetPart.Name or (SETTINGS.TargetPartName == "" and "Player" or SETTINGS.TargetPartName)) end
            end
            
            task.wait(0.2)
        end
    end)
end

local function setupInput()
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.K then
            if not isActive then return end
            if SETTINGS.LoopMode then loopActive = not loopActive
            else collectParts() end
        end
    end)
    
    mouse.Button1Down:Connect(function()
        if isSelectingTarget then
            local target = mouse.Target
            if target then
                customTargetPart = target
                SETTINGS.TargetPartName = target.Name
                SETTINGS.TargetMode = "CustomPart"
                
                updateSelectionBox(target)
                isSelectingTarget = false
                
                if gui then
                    local frame = gui.MainFrame.Pages.SettingsPage
                    for _, v in pairs(frame:GetDescendants()) do
                        if v:IsA("TextButton") and v.Text == "🔴 CLICK ANY PART NOW..." then
                            v.Text = "👆 Select w/ Click (Target)"
                            v.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
                            break
                        end
                    end
                    for _, v in pairs(frame:GetDescendants()) do
                        if v:IsA("TextBox") and v.Parent:FindFirstChild("TextLabel") and v.Parent.TextLabel.Text == "📍 Custom Target Name" then
                            v.Text = target.Name
                            v.TextColor3 = Color3.fromRGB(255, 255, 255)
                            break
                        end
                    end
                end
            end
        end
    end)
end

local function startLoop()
    task.spawn(function()
        while isRunning do
            if isActive and SETTINGS.LoopMode and loopActive then collectParts() end
            task.wait(SETTINGS.LoopInterval)
        end
    end)
end

local function setupRespawn()
    if SETTINGS.RespawnProtection and humanoid then
        humanoid.Died:Connect(function() if SETTINGS.RespawnProtection then pcall(function() humanoid.Health = humanoid.MaxHealth end) end end)
    end
end

gui = createGUI()
setupInput()
setupRespawn()
collectParts()
startTeleportation()
startLoop()
updateStats()

player.CharacterAdded:Connect(function(c)
    character = c
    humanoidRootPart = c:WaitForChild("HumanoidRootPart")
    humanoid = c:WaitForChild("Humanoid")
    setupRespawn()
end)
