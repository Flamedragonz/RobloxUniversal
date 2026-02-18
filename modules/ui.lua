--[[
    MODULE: ui.lua v2.1
    3 tabs: Status, Settings, Explorer
    + Pinned status bar
    + Mini panel
    + Collapsible advanced settings
    + Theme picker
    + Presets UI
    + Scanner results
]]

local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local TCP = shared.TCP
if not TCP or not TCP.Modules then return nil end
local Config=TCP.Modules.Config; local State=TCP.Modules.State; local Utils=TCP.Modules.Utils
local Notify=TCP.Modules.Notify; local Comp=TCP.Modules.Components; local Engine=TCP.Modules.Engine
local Scanner=TCP.Modules.Scanner; local Presets=TCP.Modules.Presets
if not Config or not State or not Utils or not Notify or not Comp or not Engine then return nil end

local C = Config.Colors
local UI = {}

function UI.Destroy()
    if State.GUI then State.GUI:Destroy(); State.GUI=nil end
end

function UI.Create()
    UI.Destroy()
    local gui = Instance.new("ScreenGui"); gui.Name="TCP_VapeStyle"; gui.ResetOnSpawn=false
    gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.DisplayOrder=999; gui.IgnoreGuiInset=true
    pcall(function() gui.Parent=CoreGui end) or 
    pcall(function() gui.Parent=State.Player.PlayerGui end)
    State.GUI=gui; Notify.Init(gui)

    -- ===== MAIN FRAME =====
    local mf = Instance.new("Frame"); mf.Name="MainFrame"; mf.Size=UDim2.new(0,440,0,620)
    mf.Position=UDim2.new(0.5,-220,0.5,-310); mf.BackgroundColor3=C.Background; mf.BorderSizePixel=0
    mf.Active=true; mf.Draggable=true; mf.ClipsDescendants=true; mf.Parent=gui
    Utils.CreateCorner(mf,12); Utils.CreateStroke(mf,Color3.fromRGB(45,45,55),1,0.3); Utils.CreateShadow(mf)
    mf.BackgroundTransparency=1; mf.Size=UDim2.new(0,440,0,0)
    Utils.Tween(mf,{BackgroundTransparency=0,Size=UDim2.new(0,440,0,620)},0.4,Enum.EasingStyle.Back)

    -- ===== HEADER =====
    local hdr = Instance.new("Frame"); hdr.Size=UDim2.new(1,0,0,48); hdr.BackgroundColor3=C.Surface
    hdr.BackgroundTransparency=0.3; hdr.BorderSizePixel=0; hdr.Parent=mf; Utils.CreateCorner(hdr,12)
    local ha = Instance.new("Frame"); ha.Size=UDim2.new(1,-20,0,2); ha.Position=UDim2.new(0,10,1,-1)
    ha.BorderSizePixel=0; ha.Parent=hdr; Utils.CreateCorner(ha,1); Utils.CreateGradient(ha,C.Accent,C.AccentGlow,0)
    local logo = Instance.new("TextLabel"); logo.Size=UDim2.new(0,28,0,28); logo.Position=UDim2.new(0,12,0.5,-14)
    logo.BackgroundColor3=C.Accent; logo.Text="T"; logo.TextColor3=Color3.new(1,1,1); logo.Font=Enum.Font.GothamBlack
    logo.TextSize=14; logo.Parent=hdr; Utils.CreateCorner(logo,7)
    local ttl = Instance.new("TextLabel"); ttl.Size=UDim2.new(1,-60,1,0); ttl.Position=UDim2.new(0,48,0,0)
    ttl.BackgroundTransparency=1; ttl.Text="Teleport Control"; ttl.TextColor3=C.TextPrimary
    ttl.Font=Enum.Font.GothamBlack; ttl.TextSize=17; ttl.TextXAlignment=Enum.TextXAlignment.Left; ttl.Parent=hdr

    -- ===== PINNED STATUS BAR =====
    local pinned = Instance.new("Frame"); pinned.Size=UDim2.new(1,-20,0,28)
    pinned.Position=UDim2.new(0,10,0,52); pinned.BackgroundColor3=C.Surface; pinned.BackgroundTransparency=0.5
    pinned.BorderSizePixel=0; pinned.Parent=mf; Utils.CreateCorner(pinned,6)
    local pdot = Instance.new("Frame"); pdot.Size=UDim2.new(0,8,0,8); pdot.Position=UDim2.new(0,10,0.5,-4)
    pdot.BackgroundColor3=C.Success; pdot.BorderSizePixel=0; pdot.Parent=pinned; Utils.CreateCorner(pdot,4)
    local ptxt = Instance.new("TextLabel"); ptxt.Size=UDim2.new(1,-26,1,0); ptxt.Position=UDim2.new(0,24,0,0)
    ptxt.BackgroundTransparency=1; ptxt.Text="● 0/50"; ptxt.TextColor3=C.TextPrimary
    ptxt.Font=Enum.Font.GothamBold; ptxt.TextSize=12; ptxt.TextXAlignment=Enum.TextXAlignment.Left; ptxt.Parent=pinned
    State.UIElements.PinnedDot=pdot; State.UIElements.PinnedText=ptxt

    -- ===== TAB BAR =====
    local tabBar = Instance.new("Frame"); tabBar.Size=UDim2.new(1,-20,0,32)
    tabBar.Position=UDim2.new(0,10,0,84); tabBar.BackgroundTransparency=1; tabBar.Parent=mf
    Utils.CreateListLayout(tabBar,Enum.FillDirection.Horizontal,4)

    -- ===== PAGES =====
    local pages = Instance.new("Frame"); pages.Size=UDim2.new(1,-20,1,-220)
    pages.Position=UDim2.new(0,10,0,122); pages.BackgroundTransparency=1; pages.ClipsDescendants=true; pages.Parent=mf

    -- Helper for scrolling pages
    local function makePage(name, visible)
        local p = Instance.new("ScrollingFrame"); p.Name=name; p.Size=UDim2.new(1,0,1,0)
        p.BackgroundTransparency=1; p.ScrollBarThickness=3; p.ScrollBarImageColor3=C.Accent
        p.BorderSizePixel=0; p.AutomaticCanvasSize=Enum.AutomaticSize.Y; p.Visible=visible; p.Parent=pages
        Utils.CreateListLayout(p,nil,8); Utils.CreatePadding(p,0,40,0,0)
        return p
    end

    -- ═══════════════════════════════
    --         STATUS PAGE
    -- ═══════════════════════════════
    local sp = makePage("Status",true)

    -- Status Card
    local sc = Instance.new("Frame"); sc.Size=UDim2.new(1,0,0,56); sc.BackgroundColor3=C.Surface
    sc.LayoutOrder=1; sc.Parent=sp; Utils.CreateCorner(sc,10)
    local ss = Utils.CreateStroke(sc,C.Success,1,0.6)
    local sd = Instance.new("Frame"); sd.Size=UDim2.new(0,10,0,10); sd.Position=UDim2.new(0,14,0.5,-5)
    sd.BackgroundColor3=C.Success; sd.BorderSizePixel=0; sd.Parent=sc; Utils.CreateCorner(sd,5)
    local sl = Instance.new("TextLabel"); sl.Size=UDim2.new(0.5,-30,1,0); sl.Position=UDim2.new(0,32,0,0)
    sl.BackgroundTransparency=1; sl.Text="ACTIVE"; sl.TextColor3=C.Success; sl.Font=Enum.Font.GothamBlack
    sl.TextSize=18; sl.TextXAlignment=Enum.TextXAlignment.Left; sl.Parent=sc
    local ssub = Instance.new("TextLabel"); ssub.Size=UDim2.new(0.5,-14,1,0); ssub.Position=UDim2.new(0.5,0,0,0)
    ssub.BackgroundTransparency=1; ssub.Text="K to start"; ssub.TextColor3=C.TextSecondary
    ssub.Font=Enum.Font.GothamMedium; ssub.TextSize=11; ssub.TextXAlignment=Enum.TextXAlignment.Right; ssub.Parent=sc
    State.UIElements.StatusCard=sc; State.UIElements.StatusStroke=ss; State.UIElements.StatusDot=sd
    State.UIElements.StatusLabel=sl; State.UIElements.StatusSub=ssub

    Comp.CreateSection(sp,"STATISTICS",2)
    State.UIElements.Ping      = Comp.CreateInfoRow(sp,"📡","Ping","...",C.Danger,3)
    State.UIElements.Collected = Comp.CreateInfoRow(sp,"📦","Collected","0",C.Warning,4)
    State.UIElements.Active    = Comp.CreateInfoRow(sp,"⚡","Active","0/50",C.Info,5)
    State.UIElements.Uptime    = Comp.CreateInfoRow(sp,"⏱️","Uptime","00:00",C.AccentGlow,6)
    State.UIElements.Rate      = Comp.CreateInfoRow(sp,"📈","Rate","...",C.AccentGlow,7)

    Comp.CreateSection(sp,"CONFIG",8)
    State.UIElements.Mode    = Comp.CreateInfoRow(sp,"🔄","Mode","Loop",C.AccentGlow,9)
    State.UIElements.Target  = Comp.CreateInfoRow(sp,"🎯","Target","Player",C.AccentGlow,10)
    State.UIElements.TPType  = Comp.CreateInfoRow(sp,"💫","Teleport","Instant",C.AccentGlow,11)
    State.UIElements.Folder  = Comp.CreateInfoRow(sp,"📂","Folder",Config.FolderPath=="" and "Workspace" or Config.FolderPath,C.TextSecondary,12)
    State.UIElements.Filter  = Comp.CreateInfoRow(sp,"🔍","Filter",Config.PartName=="" and "ALL" or Config.PartName,C.TextSecondary,13)
    State.UIElements.KeyHint = Comp.CreateInfoRow(sp,"⌨️","Key K","Start",C.Success,14)

    Comp.CreateSection(sp,"HOTKEYS",15)
    Comp.CreateHotkeyRow(sp,"K","Start/Stop loop · Single pull",16)
    Comp.CreateHotkeyRow(sp,"P","Hide/Show panel",17)
    Comp.CreateHotkeyRow(sp,"L","Release all parts",18)
    Comp.CreateHotkeyRow(sp,"J","Quick pause/activate",19)
    Comp.CreateHotkeyRow(sp,"M","Toggle mini mode",20)

    local ih = Instance.new("Frame"); ih.Size=UDim2.new(1,0,0,30); ih.BackgroundColor3=C.Surface
    ih.BackgroundTransparency=0.5; ih.LayoutOrder=21; ih.Parent=sp; Utils.CreateCorner(ih,8)
    local iht = Instance.new("TextLabel"); iht.Size=UDim2.new(1,-12,1,0); iht.Position=UDim2.new(0,6,0,0)
    iht.BackgroundTransparency=1; iht.RichText=true
    iht.Text='💡 <font color="#FFE632">Yellow</font> = not confirmed. Press <font color="#5A50DC">Enter ↵</font>'
    iht.TextColor3=C.TextSecondary; iht.Font=Enum.Font.GothamMedium; iht.TextSize=11
    iht.TextXAlignment=Enum.TextXAlignment.Left; iht.Parent=ih

    -- ═══════════════════════════════
    --        SETTINGS PAGE
    -- ═══════════════════════════════
    local stp = makePage("Settings",false)

    -- === BASIC (always open) ===
    Comp.CreateSection(stp,"SOURCE",1)
    Comp.CreateInput(stp,"📂 Folder Path","e.g. ItemDebris",Config.FolderPath,function(t)
        Config.FolderPath=t; State.UIElements.Folder.Text=t=="" and "Workspace" or t end,2)

    -- Auto-detect button
    Comp.CreateButton(stp,"🔍 Auto-detect Folders",C.AccentDark,function()
        if not Scanner then Notify.Send("❌ Scanner N/A",C.Danger); return end
        local folders = Scanner.FindFoldersWithParts(3)
        if #folders==0 then Notify.Send("🔍 No folders found",C.TextSecondary); return end
        for i=1,math.min(3,#folders) do
            Notify.Send("📂 "..folders[i].path.." ("..folders[i].partCount..")",C.Info,4) end
        Config.FolderPath=folders[1].path
        State.UIElements.Folder.Text=folders[1].path
        Notify.Send("✅ Selected: "..folders[1].path,C.Success,3)
    end,3)

    Comp.CreateInput(stp,"🔍 Part Filter","e.g. Gold (empty=ALL)",Config.PartName,function(t)
        Config.PartName=t; State.UIElements.Filter.Text=t=="" and "ALL" or t
        -- Parse multi-filter
        Config.PartNames={}
        if t:find(",") then
            for name in t:gmatch("[^,]+") do
                local trimmed = name:match("^%s*(.-)%s*$")
                if trimmed~="" then table.insert(Config.PartNames,trimmed) end
            end
            Config.PartName="" -- Use multi-filter mode
        end
    end,4)

    Comp.CreateInput(stp,"📊 Max Parts","50",tostring(Config.MaxParts),function(t)
        local n=tonumber(t); if n and n>0 then Config.MaxParts=math.floor(n) end end,5)

    -- === TARGET ===
    Comp.CreateSection(stp,"TARGET",6)
    local ctg = Instance.new("Frame"); ctg.Size=UDim2.new(1,0,0,0); ctg.AutomaticSize=Enum.AutomaticSize.Y
    ctg.BackgroundTransparency=1; ctg.Visible=Config.TargetMode~="Mouse"; ctg.LayoutOrder=8; ctg.Parent=stp
    Utils.CreateListLayout(ctg,nil,8); State.UIElements.CustomTargetGroup=ctg

    Comp.CreateToggle(stp,"🖱️ Mouse Target",Config.TargetMode=="Mouse",function(v)
        Config.TargetMode=v and "Mouse" or "CustomPart"; ctg.Visible=not v
        State.UIElements.Target.Text=v and "Mouse" or "Player"
    end,7)

    local cti = Comp.CreateInput(ctg,"📍 Target Name","Part name",Config.TargetPartName,function(t)
        Config.TargetPartName=t; if t~="" then State.CustomTargetPart=nil; Engine.UpdateSelectionBox(nil) end
        State.UIElements.Target.Text=t=="" and "Player" or t end)
    State.UIElements.CustomTargetInput=cti

    local selBtn = Comp.CreateButton(ctg,"👆 Click to Select",Color3.fromRGB(50,80,140),function(btn)
        State.IsSelectingTarget=not State.IsSelectingTarget
        btn.Text=State.IsSelectingTarget and "🔴 CLICK A PART..." or "👆 Click to Select"
        Utils.Tween(btn,{BackgroundColor3=State.IsSelectingTarget and C.Danger or Color3.fromRGB(50,80,140)},0.2)
    end)
    State.UIElements.SelectBtn=selBtn

    -- === ADVANCED (collapsible) ===
    local adv = Comp.CreateCollapsibleSection(stp,"⚙️ ADVANCED SETTINGS",false,9)
    local advC = adv.Content

    Comp.CreateToggle(advC,"🥞 Stack Mode",Config.StackMode,function(v) Config.StackMode=v end,1)
    Comp.CreateInput(advC,"⛓️ Spacing","2",tostring(Config.Spacing),function(t) Config.Spacing=tonumber(t) or 2 end,2)
    local ofi = Comp.CreateOffsetInputs(advC,Config.Offset,nil,3)
    Comp.CreateToggle(advC,"⚓ Anchor on Release",Config.AnchorOnFinish,function(v) Config.AnchorOnFinish=v end,4)

    -- Smooth
    Comp.CreateSection(advC,"SMOOTH TELEPORT",5)
    Comp.CreateToggle(advC,"💫 Smooth Teleport",Config.SmoothTeleport,function(v)
        Config.SmoothTeleport=v; State.UIElements.TPType.Text=v and "Smooth" or "Instant"
        Engine.ReprepareParts() end,6)
    Comp.CreateInput(advC,"💨 Speed","25",tostring(Config.SmoothSpeed),function(t)
        Config.SmoothSpeed=tonumber(t) or 25 end,7)

    -- Visuals
    Comp.CreateSection(advC,"VISUALS",8)
    Comp.CreateToggle(advC,"✨ ESP Highlight",Config.ESPEnabled,function(v) Engine.ESP.Toggle(v) end,9)
    Comp.CreateToggle(advC,"🔊 Sound Effects",Config.SoundEnabled,function(v) Config.SoundEnabled=v end,10)

    -- Theme
    Comp.CreateSection(advC,"THEME",11)
    Comp.CreateThemePicker(advC,function(name)
        Config.ApplyTheme(name)
        Notify.Send("🎨 Theme: "..name.." (reopen to apply fully)",C.Info,3)
    end,12)

    -- Presets
    if Presets then
        Comp.CreateSection(advC,"PRESETS",13)
        local presetInput = Comp.CreateInput(advC,"💾 Preset Name","My preset","",nil,14)
        Comp.CreateButton(advC,"💾 Save Current Settings",C.AccentDark,function()
            local name = presetInput.GetText()
            if name and name~="" then Presets.Save(name) else Notify.Send("⚠️ Enter name first",C.Warning) end
        end,15)
        Comp.CreateButton(advC,"📂 Load Preset",Color3.fromRGB(50,100,80),function()
            local name = presetInput.GetText()
            if name and name~="" then Presets.Load(name) else
                local names = Presets.GetNames()
                if #names>0 then
                    for _,n in ipairs(names) do Notify.Send("📂 "..n,C.Info,3) end
                else Notify.Send("No saved presets",C.TextSecondary) end
            end
        end,16)
    end

    -- Offset updater
    State.Connections["OffsetUpdate"] = RunService.Heartbeat:Connect(function()
        if ofi then Config.Offset=ofi.GetOffset() end
    end)

    -- ═══════════════════════════════
    --       EXPLORER PAGE
    -- ═══════════════════════════════
    local ep = makePage("Explorer",false)

    Comp.CreateSection(ep,"WORKSPACE SCANNER",1)

    -- Scan button
    Comp.CreateButton(ep,"🔍 Scan Workspace",C.Accent,function()
        if not Scanner then return end
        -- Clear old results
        for _,c in pairs(ep:GetChildren()) do
            if c:IsA("Frame") and c.LayoutOrder>=10 then c:Destroy() end
        end
        -- Stats
        local stats = Scanner.GetWorkspaceStats()
        Comp.CreateInfoRow(ep,"🧱","Total BaseParts",tostring(stats.parts),C.Info,10)
        Comp.CreateInfoRow(ep,"📁","Total Folders",tostring(stats.folders),C.Info,11)
        Comp.CreateInfoRow(ep,"📦","Total Models",tostring(stats.models),C.Info,12)

        Comp.CreateSection(ep,"FOLDERS WITH PARTS",13)

        local folders = Scanner.FindFoldersWithParts(3)
        for i,f in ipairs(folders) do
            if i>15 then break end
            local row = Instance.new("Frame"); row.Size=UDim2.new(1,0,0,36); row.BackgroundColor3=C.Surface
            row.BackgroundTransparency=0.3; row.LayoutOrder=13+i; row.Parent=ep; Utils.CreateCorner(row,8)

            local depth = string.rep("  ",f.depth-1)
            local name = Instance.new("TextLabel"); name.Size=UDim2.new(0.6,0,1,0); name.Position=UDim2.new(0,10,0,0)
            name.BackgroundTransparency=1; name.Text=depth.."📂 "..f.name.." ("..f.partCount..")"
            name.TextColor3=C.TextPrimary; name.Font=Enum.Font.GothamMedium; name.TextSize=12
            name.TextXAlignment=Enum.TextXAlignment.Left; name.TextTruncate=Enum.TextTruncate.AtEnd; name.Parent=row

            local useBtn = Instance.new("TextButton"); useBtn.Size=UDim2.new(0,50,0,24)
            useBtn.Position=UDim2.new(1,-60,0.5,-12); useBtn.BackgroundColor3=C.Accent
            useBtn.Text="USE"; useBtn.TextColor3=Color3.new(1,1,1); useBtn.Font=Enum.Font.GothamBold
            useBtn.TextSize=11; useBtn.Parent=row; Utils.CreateCorner(useBtn,6)

            local path = f.path
            useBtn.MouseButton1Click:Connect(function()
                Config.FolderPath=path
                State.UIElements.Folder.Text=path
                Notify.Send("📂 Selected: "..path,C.Success)
            end)
        end

        Notify.Send("🔍 Found "..#folders.." folders",C.Info)
    end,2)

    -- Unique names in current folder
    Comp.CreateButton(ep,"📋 Show Part Names in Current Folder",C.AccentDark,function()
        if not Scanner then return end
        local names = Scanner.GetUniquePartNames()
        local count=0
        for name,qty in pairs(names) do
            count=count+1; if count>10 then break end
            Notify.Send("🧩 "..name.." (×"..qty..")",C.Info,4)
        end
        if count==0 then Notify.Send("No parts in folder",C.TextSecondary) end
    end,3)

    -- ===== TAB BUTTONS =====
    local pagesList = {sp,stp,ep}
    local tabNames = {"📊 Status","⚙️ Settings","🔍 Explorer"}
    local tabBtns = {}
    for i,name in ipairs(tabNames) do
        local btn = Instance.new("TextButton"); btn.Size=UDim2.new(1/#tabNames,-3,1,0)
        btn.BackgroundColor3=i==1 and C.Accent or C.SurfaceLight
        btn.BackgroundTransparency=i==1 and 0 or 0.5; btn.Text=name
        btn.TextColor3=i==1 and C.TextPrimary or C.TextSecondary; btn.Font=Enum.Font.GothamBold
        btn.TextSize=13; btn.AutoButtonColor=false; btn.Parent=tabBar; Utils.CreateCorner(btn,8)
        tabBtns[i]=btn
        btn.MouseButton1Click:Connect(function()
            for j,pg in ipairs(pagesList) do pg.Visible=(j==i)
                Utils.Tween(tabBtns[j],{BackgroundColor3=(j==i) and C.Accent or C.SurfaceLight,
                    BackgroundTransparency=(j==i) and 0 or 0.5,
                    TextColor3=(j==i) and C.TextPrimary or C.TextSecondary},0.2)
            end
        end)
    end

    -- ===== FOOTER =====
    local ft = Instance.new("Frame"); ft.Size=UDim2.new(1,-20,0,88); ft.Position=UDim2.new(0,10,1,-96)
    ft.BackgroundTransparency=1; ft.Parent=mf

    local tb = Instance.new("TextButton"); tb.Size=UDim2.new(1,0,0,40); tb.BackgroundColor3=C.Warning
    tb.Text="⏸️ DEACTIVATE"; tb.TextColor3=Color3.fromRGB(30,30,30); tb.Font=Enum.Font.GothamBlack
    tb.TextSize=15; tb.AutoButtonColor=false; tb.ClipsDescendants=true; tb.Parent=ft; Utils.CreateCorner(tb,10)
    tb.MouseButton1Click:Connect(function()
        Utils.AnimateClick(tb); Utils.Ripple(tb,State.Mouse.X,State.Mouse.Y)
        State.IsActive=not State.IsActive
        if State.IsActive then tb.Text="⏸️ DEACTIVATE"; Utils.Tween(tb,{BackgroundColor3=C.Warning},0.2)
            Notify.Send("▶️ Activated",C.Success)
        else tb.Text="▶️ ACTIVATE"; Utils.Tween(tb,{BackgroundColor3=C.Success},0.2)
            State.LoopActive=false; Notify.Send("⏸️ Paused",C.Warning) end
    end)

    local sr = Instance.new("Frame"); sr.Size=UDim2.new(1,0,0,36); sr.Position=UDim2.new(0,0,0,46)
    sr.BackgroundTransparency=1; sr.Parent=ft
    Utils.CreateListLayout(sr,Enum.FillDirection.Horizontal,5)

    local function fBtn(text,color,sz,cb)
        local b=Instance.new("TextButton"); b.Size=UDim2.new(sz,-3,1,0); b.BackgroundColor3=color
        b.Text=text; b.TextColor3=C.TextPrimary; b.Font=Enum.Font.GothamBold; b.TextSize=12
        b.AutoButtonColor=false; b.ClipsDescendants=true; b.Parent=sr; Utils.CreateCorner(b,8)
        Utils.AddHover(b,0.15,0)
        b.MouseButton1Click:Connect(function() Utils.AnimateClick(b); cb(b) end); return b
    end

    fBtn("🔄 Loop",C.AccentDark,0.25,function()
        Config.LoopMode=not Config.LoopMode; State.LoopActive=false
        State.UIElements.Mode.Text=Config.LoopMode and "Loop" or "Single"
        Notify.Send("Mode: "..(Config.LoopMode and "Loop" or "Single"),C.Info)
    end)
    fBtn("🔓 Release",Color3.fromRGB(160,110,30),0.25,function()
        local c=#State.PartsToTeleport; Engine.ReleaseAll()
        Notify.Send("🔓 Released "..c,C.Warning)
    end)
    fBtn("📌 Mini",C.SurfaceLight,0.25,function()
        Config.MiniMode=true; mf.Visible=false; State.UIVisible=false
        local mp=gui:FindFirstChild("MiniPanel"); if mp then mp.Visible=true end
        Notify.Send("📌 Mini mode (M to expand)",C.Info)
    end)
    fBtn("✕",C.Danger,0.25,function()
        State.IsRunning=false; State.IsActive=false; Engine.ReleaseAll()
        if State.SelectionBox then State.SelectionBox:Destroy() end
        if Presets then Presets.AutoSave() end
        shared.TCP.Loaded=false
        Utils.Tween(mf,{BackgroundTransparency=1,Size=UDim2.new(0,440,0,0)},0.3)
        task.delay(0.35,function() gui:Destroy() end)
    end)

    -- ===== MINI PANEL =====
    local mp = Instance.new("Frame"); mp.Name="MiniPanel"; mp.Size=UDim2.new(0,200,0,36)
    mp.Position=UDim2.new(0.5,-100,0,10); mp.BackgroundColor3=C.Background; mp.BackgroundTransparency=0.1
    mp.BorderSizePixel=0; mp.Visible=false; mp.Active=true; mp.Draggable=true; mp.Parent=gui
    Utils.CreateCorner(mp,18); Utils.CreateStroke(mp,C.Accent,1,0.5)

    local md = Instance.new("Frame"); md.Size=UDim2.new(0,10,0,10); md.Position=UDim2.new(0,12,0.5,-5)
    md.BackgroundColor3=C.Success; md.BorderSizePixel=0; md.Parent=mp; Utils.CreateCorner(md,5)
    local mc = Instance.new("TextLabel"); mc.Size=UDim2.new(0,80,1,0); mc.Position=UDim2.new(0,28,0,0)
    mc.BackgroundTransparency=1; mc.Text="0/50"; mc.TextColor3=C.TextPrimary; mc.Font=Enum.Font.GothamBold
    mc.TextSize=14; mc.TextXAlignment=Enum.TextXAlignment.Left; mc.Parent=mp
    local ml = Instance.new("TextLabel"); ml.Size=UDim2.new(0,24,1,0); ml.Position=UDim2.new(0,110,0,0)
    ml.BackgroundTransparency=1; ml.Text="⏸"; ml.TextColor3=C.TextSecondary; ml.Font=Enum.Font.GothamBold
    ml.TextSize=16; ml.Parent=mp
    local me = Instance.new("TextButton"); me.Size=UDim2.new(0,44,0,24); me.Position=UDim2.new(1,-52,0.5,-12)
    me.BackgroundColor3=C.Accent; me.BackgroundTransparency=0.5; me.Text="▼"; me.TextColor3=C.TextPrimary
    me.Font=Enum.Font.GothamBold; me.TextSize=12; me.Parent=mp; Utils.CreateCorner(me,6)
    me.MouseButton1Click:Connect(function()
        Config.MiniMode=false; mp.Visible=false; mf.Visible=true; State.UIVisible=true
    end)

    State.UIElements.MiniDot=md; State.UIElements.MiniCounter=mc; State.UIElements.MiniLoop=ml

    -- Mini panel updater
    task.spawn(function()
        while State.IsRunning do
            if mp.Visible then
                mc.Text = #State.PartsToTeleport.."/"..Config.MaxParts
                md.BackgroundColor3 = State.IsActive and C.Success or C.Warning
                ml.Text = State.LoopActive and "🔄" or "⏸"
            end
            task.wait(0.2)
        end
    end)

    return gui
end

return UI
