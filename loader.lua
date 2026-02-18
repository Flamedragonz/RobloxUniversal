if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(1)

if shared._TCP_LOADING == true then
    warn("⚠️ TCP is already loading!")
    return
end

if shared.TCP and shared.TCP.Loaded == true then
    local CoreGui = game:GetService("CoreGui")
    local player = game:GetService("Players").LocalPlayer
    local guiAlive = CoreGui:FindFirstChild("TCP_VapeStyle")
        or (player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("TCP_VapeStyle"))
    if guiAlive then
        warn("⚠️ TCP is already running!")
        return
    else
        shared.TCP = nil
    end
end

shared._TCP_LOADING = true

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer

local REPO = "Flamedragonz/RobloxUniversal"
local MAX_RETRIES = 3
local DELAY_BETWEEN = 1.5
local RETRY_DELAY = 2

local ACCENT = Color3.fromRGB(90, 80, 220)
local ACCENT_GLOW = Color3.fromRGB(130, 120, 255)
local BG_DARK = Color3.fromRGB(12, 12, 16)
local BG_SURFACE = Color3.fromRGB(22, 22, 28)
local TEXT_PRIMARY = Color3.fromRGB(240, 240, 245)
local TEXT_SECONDARY = Color3.fromRGB(120, 120, 140)
local SUCCESS = Color3.fromRGB(80, 200, 120)
local DANGER = Color3.fromRGB(220, 70, 70)
local WARNING = Color3.fromRGB(240, 180, 60)

local function fullCleanup()
    shared._TCP_LOADING = nil
    if shared.TCP then
        if shared.TCP.Modules and shared.TCP.Modules.State then
            local S = shared.TCP.Modules.State
            if S.Connections then for _,c in pairs(S.Connections) do pcall(function() c:Disconnect() end) end end
            if S.SelectionBox then pcall(function() S.SelectionBox:Destroy() end) end
        end
        shared.TCP = nil
    end
    pcall(function() local g = CoreGui:FindFirstChild("TCP_VapeStyle") if g then g:Destroy() end end)
    pcall(function() local g = CoreGui:FindFirstChild("TCP_LoadingScreen") if g then g:Destroy() end end)
end

-- ===== LOADING SCREEN =====
local LS = {}
LS._alive = true

function LS.Create()
    pcall(function() local o = CoreGui:FindFirstChild("TCP_LoadingScreen") if o then o:Destroy() end end)
    local gui = Instance.new("ScreenGui")
    gui.Name = "TCP_LoadingScreen"; gui.ResetOnSpawn = false; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 9999; gui.IgnoreGuiInset = true
    pcall(function() gui.Parent = CoreGui end) or pcall(function() gui.Parent = player.PlayerGui end)

    local overlay = Instance.new("Frame"); overlay.Size = UDim2.new(1,0,1,0); overlay.BackgroundColor3 = Color3.new(0,0,0)
    overlay.BackgroundTransparency = 1; overlay.BorderSizePixel = 0; overlay.ZIndex = 1; overlay.Parent = gui

    local card = Instance.new("Frame"); card.Name = "Card"; card.AnchorPoint = Vector2.new(0.5,0.5)
    card.Size = UDim2.new(0,380,0,0); card.Position = UDim2.new(0.5,0,0.5,0); card.BackgroundColor3 = BG_DARK
    card.BackgroundTransparency = 1; card.BorderSizePixel = 0; card.ZIndex = 10; card.Parent = gui
    local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0,16); cc.Parent = card
    local cs = Instance.new("UIStroke"); cs.Color = ACCENT; cs.Thickness = 1.5; cs.Transparency = 0.5; cs.Parent = card

    local shadow = Instance.new("ImageLabel"); shadow.Name="Shadow"; shadow.AnchorPoint=Vector2.new(0.5,0.5)
    shadow.BackgroundTransparency=1; shadow.Position=UDim2.new(0.5,0,0.5,6); shadow.Size=UDim2.new(1,50,1,50)
    shadow.ZIndex=9; shadow.Image="rbxassetid://6015897843"; shadow.ImageColor3=Color3.new(0,0,0)
    shadow.ImageTransparency=0.3; shadow.ScaleType=Enum.ScaleType.Slice; shadow.SliceCenter=Rect.new(49,49,450,450)
    shadow.Parent = card

    local logoCont = Instance.new("Frame"); logoCont.AnchorPoint=Vector2.new(0.5,0); logoCont.Size=UDim2.new(0,60,0,60)
    logoCont.Position=UDim2.new(0.5,0,0,30); logoCont.BackgroundColor3=ACCENT; logoCont.ZIndex=11; logoCont.Parent=card
    Instance.new("UICorner",logoCont).CornerRadius=UDim.new(0,14)
    local lg = Instance.new("UIGradient"); lg.Color=ColorSequence.new(ACCENT,ACCENT_GLOW); lg.Rotation=45; lg.Parent=logoCont
    local lt = Instance.new("TextLabel"); lt.Size=UDim2.new(1,0,1,0); lt.BackgroundTransparency=1; lt.Text="T"
    lt.TextColor3=Color3.new(1,1,1); lt.Font=Enum.Font.GothamBlack; lt.TextSize=30; lt.ZIndex=12; lt.Parent=logoCont
    local gr = Instance.new("UIStroke"); gr.Color=ACCENT_GLOW; gr.Thickness=2; gr.Parent=logoCont

    local ttl = Instance.new("TextLabel"); ttl.AnchorPoint=Vector2.new(0.5,0); ttl.Size=UDim2.new(1,0,0,24)
    ttl.Position=UDim2.new(0.5,0,0,100); ttl.BackgroundTransparency=1; ttl.Text="Teleport Control Panel"
    ttl.TextColor3=TEXT_PRIMARY; ttl.Font=Enum.Font.GothamBlack; ttl.TextSize=20; ttl.ZIndex=11; ttl.Parent=card

    local vl = Instance.new("TextLabel"); vl.AnchorPoint=Vector2.new(0.5,0); vl.Size=UDim2.new(1,0,0,16)
    vl.Position=UDim2.new(0.5,0,0,126); vl.BackgroundTransparency=1; vl.Text="v2.1 — Vape Style Edition"
    vl.TextColor3=TEXT_SECONDARY; vl.Font=Enum.Font.GothamMedium; vl.TextSize=12; vl.ZIndex=11; vl.Parent=card

    local pbg = Instance.new("Frame"); pbg.AnchorPoint=Vector2.new(0.5,0); pbg.Size=UDim2.new(0.8,0,0,8)
    pbg.Position=UDim2.new(0.5,0,0,165); pbg.BackgroundColor3=BG_SURFACE; pbg.BorderSizePixel=0; pbg.ZIndex=11; pbg.Parent=card
    Instance.new("UICorner",pbg).CornerRadius=UDim.new(0,4)
    local pf = Instance.new("Frame"); pf.Name="Fill"; pf.Size=UDim2.new(0,0,1,0); pf.BackgroundColor3=ACCENT
    pf.BorderSizePixel=0; pf.ZIndex=12; pf.Parent=pbg; Instance.new("UICorner",pf).CornerRadius=UDim.new(0,4)

    local pct = Instance.new("TextLabel"); pct.AnchorPoint=Vector2.new(0.5,0); pct.Size=UDim2.new(1,0,0,20)
    pct.Position=UDim2.new(0.5,0,0,178); pct.BackgroundTransparency=1; pct.Text="0%"; pct.TextColor3=ACCENT_GLOW
    pct.Font=Enum.Font.GothamBold; pct.TextSize=14; pct.ZIndex=11; pct.Parent=card

    local stl = Instance.new("TextLabel"); stl.AnchorPoint=Vector2.new(0.5,0); stl.Size=UDim2.new(0.9,0,0,18)
    stl.Position=UDim2.new(0.5,0,0,205); stl.BackgroundTransparency=1; stl.Text="Initializing..."
    stl.TextColor3=TEXT_SECONDARY; stl.Font=Enum.Font.GothamMedium; stl.TextSize=13; stl.ZIndex=11; stl.Parent=card

    local lf = Instance.new("Frame"); lf.AnchorPoint=Vector2.new(0.5,0); lf.Size=UDim2.new(0.85,0,0,70)
    lf.Position=UDim2.new(0.5,0,0,232); lf.BackgroundColor3=BG_SURFACE; lf.BorderSizePixel=0; lf.ClipsDescendants=true
    lf.ZIndex=11; lf.Parent=card; Instance.new("UICorner",lf).CornerRadius=UDim.new(0,8)
    local ll = Instance.new("UIListLayout"); ll.SortOrder=Enum.SortOrder.LayoutOrder; ll.Padding=UDim.new(0,2)
    ll.VerticalAlignment=Enum.VerticalAlignment.Bottom; ll.Parent=lf
    local lp = Instance.new("UIPadding"); lp.PaddingLeft=UDim.new(0,8); lp.PaddingRight=UDim.new(0,8)
    lp.PaddingBottom=UDim.new(0,4); lp.Parent=lf

    TweenService:Create(overlay,TweenInfo.new(0.5),{BackgroundTransparency=0.4}):Play()
    TweenService:Create(card,TweenInfo.new(0.5,Enum.EasingStyle.Back),{BackgroundTransparency=0,Size=UDim2.new(0,380,0,320)}):Play()

    task.spawn(function() while LS._alive do
        TweenService:Create(gr,TweenInfo.new(1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Transparency=0.7}):Play()
        task.wait(1); if not LS._alive then break end
        TweenService:Create(gr,TweenInfo.new(1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Transparency=0}):Play()
        task.wait(1)
    end end)

    LS.GUI=gui; LS.Card=card; LS.Overlay=overlay; LS.Fill=pf; LS.Pct=pct; LS.Status=stl; LS.Log=lf
    LS.Logo=logoCont; LS.Glow=gr; LS.Stroke=cs; LS.LC=0
    return gui
end

function LS.SetProgress(c,t) if not LS.Fill then return end
    TweenService:Create(LS.Fill,TweenInfo.new(0.3),{Size=UDim2.new(c/t,0,1,0)}):Play()
    LS.Pct.Text = math.floor(c/t*100).."%"
end
function LS.SetStatus(t) if LS.Status then LS.Status.Text = t end end
function LS.AddLog(icon,text,color)
    if not LS.Log then return end; LS.LC=LS.LC+1
    local ch={}; for _,c in pairs(LS.Log:GetChildren()) do if c:IsA("TextLabel") then table.insert(ch,c) end end
    while #ch>4 do ch[1]:Destroy(); table.remove(ch,1) end
    local e=Instance.new("TextLabel"); e.Size=UDim2.new(1,0,0,14); e.BackgroundTransparency=1
    e.Text=icon.." "..text; e.TextColor3=color or TEXT_SECONDARY; e.Font=Enum.Font.Code; e.TextSize=11
    e.TextXAlignment=Enum.TextXAlignment.Left; e.TextTruncate=Enum.TextTruncate.AtEnd; e.LayoutOrder=LS.LC
    e.ZIndex=12; e.Parent=LS.Log; e.TextTransparency=1
    TweenService:Create(e,TweenInfo.new(0.2),{TextTransparency=0}):Play()
end
function LS.Retry(n,a,m) if not LS.Status then return end
    LS.Status.Text="⏳ Retrying "..n.." ("..a.."/"..m..")"; LS.Status.TextColor3=WARNING
    LS.AddLog("🔄",n.." retry "..a.."/"..m, WARNING)
end
function LS.Dismiss() LS._alive=false; if not LS.GUI or not LS.GUI.Parent then return end
    TweenService:Create(LS.Card,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Size=UDim2.new(0,380,0,0),BackgroundTransparency=1}):Play()
    TweenService:Create(LS.Overlay,TweenInfo.new(0.5),{BackgroundTransparency=1}):Play()
    task.delay(0.6,function() if LS.GUI then LS.GUI:Destroy(); LS.GUI=nil end end)
end
function LS.ShowSuccess()
    if LS.Stroke then TweenService:Create(LS.Stroke,TweenInfo.new(0.3),{Color=SUCCESS,Transparency=0}):Play() end
    if LS.Fill then TweenService:Create(LS.Fill,TweenInfo.new(0.3),{BackgroundColor3=SUCCESS,Size=UDim2.new(1,0,1,0)}):Play() end
    if LS.Pct then LS.Pct.Text="100%"; LS.Pct.TextColor3=SUCCESS end
    if LS.Status then LS.Status.Text="✅ Ready!"; LS.Status.TextColor3=SUCCESS end
    if LS.Logo then TweenService:Create(LS.Logo,TweenInfo.new(0.3),{BackgroundColor3=SUCCESS}):Play() end
    LS.AddLog("✅","All modules loaded!",SUCCESS)
    task.delay(2,function() LS.Dismiss() end)
end
function LS.ShowError(mod,err)
    if LS.Stroke then TweenService:Create(LS.Stroke,TweenInfo.new(0.3),{Color=DANGER,Transparency=0}):Play() end
    if LS.Fill then TweenService:Create(LS.Fill,TweenInfo.new(0.3),{BackgroundColor3=DANGER}):Play() end
    if LS.Pct then LS.Pct.TextColor3=DANGER end
    if LS.Status then LS.Status.Text="❌ "..mod; LS.Status.TextColor3=DANGER end
    if LS.Logo then TweenService:Create(LS.Logo,TweenInfo.new(0.3),{BackgroundColor3=DANGER}):Play() end
    LS.AddLog("❌",mod..": "..(err or "?"),DANGER)
    local rb=Instance.new("TextButton"); rb.AnchorPoint=Vector2.new(0.5,1); rb.Size=UDim2.new(0.4,0,0,32)
    rb.Position=UDim2.new(0.3,0,1,-12); rb.BackgroundColor3=ACCENT; rb.Text="🔄 Retry"; rb.TextColor3=Color3.new(1,1,1)
    rb.Font=Enum.Font.GothamBold; rb.TextSize=14; rb.ZIndex=13; rb.Parent=LS.Card
    Instance.new("UICorner",rb).CornerRadius=UDim.new(0,8)
    rb.MouseButton1Click:Connect(function() LS._alive=false; if LS.GUI then LS.GUI:Destroy() end
        shared._TCP_LOADING=nil; shared.TCP=nil; task.wait(0.5)
        pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/"..REPO.."/main/loader.lua"))() end)
    end)
    local cb=Instance.new("TextButton"); cb.AnchorPoint=Vector2.new(0.5,1); cb.Size=UDim2.new(0.4,0,0,32)
    cb.Position=UDim2.new(0.7,0,1,-12); cb.BackgroundColor3=DANGER; cb.BackgroundTransparency=0.3; cb.Text="✕ Cancel"
    cb.TextColor3=Color3.new(1,1,1); cb.Font=Enum.Font.GothamBold; cb.TextSize=14; cb.ZIndex=13; cb.Parent=LS.Card
    Instance.new("UICorner",cb).CornerRadius=UDim.new(0,8)
    cb.MouseButton1Click:Connect(function() fullCleanup(); LS._alive=false; LS.Dismiss() end)
end

LS.Create(); task.wait(0.6)

LS.SetStatus("🔍 Detecting server...")
LS.AddLog("🔍","Connecting...",TEXT_SECONDARY)

local URL_FORMATS = {
    "https://raw.githubusercontent.com/"..REPO.."/main/modules/",
    "https://raw.githubusercontent.com/"..REPO.."/refs/heads/main/modules/",
}
local BASE_URL = nil
for _,url in pairs(URL_FORMATS) do
    local ok,r = pcall(function() return game:HttpGet(url.."config.lua") end)
    if ok and r and #r>50 and not r:find("404") then BASE_URL=url; LS.AddLog("✅","Connected",SUCCESS); break end
    task.wait(1)
end
if not BASE_URL then LS.ShowError("Connection","Cannot reach GitHub"); shared._TCP_LOADING=nil; return end

shared.TCP = {Version="2.1", Modules={}, BaseURL=BASE_URL, Loaded=false}

local function loadModule(name,i,total)
    local url = BASE_URL..name..".lua"
    for attempt=1,MAX_RETRIES do
        local ok,src = pcall(function() return game:HttpGet(url) end)
        if not ok or not src or #src<10 then
            if attempt<MAX_RETRIES then LS.Retry(name,attempt,MAX_RETRIES); task.wait(RETRY_DELAY)
            else return nil,"HTTP failed" end
        else
            if src:find("404") or src:find("Not Found") then return nil,"404 not found" end
            local comp,ce = loadstring(src,name); if not comp then return nil,"Syntax: "..tostring(ce) end
            local eok,res = pcall(comp); if not eok then return nil,"Runtime: "..tostring(res) end
            if res==nil then return nil,"returned nil" end
            LS.AddLog("✅",name.." ("..#src.."b)",SUCCESS); LS.SetProgress(i,total)
            return res,nil
        end
    end
    return nil,"Unknown"
end

-- ════════════════════════════════════
--  14 МОДУЛЕЙ (было 12, добавлены scanner и presets)
-- ════════════════════════════════════
local modules = {
    {"config","Config"}, {"state","State"}, {"utils","Utils"},
    {"notify","Notify"}, {"components","Components"}, {"engine","Engine"},
    {"scanner","Scanner"}, {"presets","Presets"},
    {"ui","UI"}, {"status","Status"}, {"teleport","Teleport"},
    {"input","Input"}, {"respawn","Respawn"}, {"init","Init"},
}

local total = #modules
LS.SetStatus("📦 Loading..."); task.wait(0.3)

local allOk = true
for i,mod in ipairs(modules) do
    LS.SetStatus("📦 "..mod[1].." ("..i.."/"..total..")")
    local res,err = loadModule(mod[1],i,total)
    if res~=nil then shared.TCP.Modules[mod[2]]=res; print("✅ [TCP] "..mod[1])
    else warn("❌ [TCP] "..mod[1]..": "..tostring(err)); LS.ShowError(mod[1],err); allOk=false; return end
    if i<total then task.wait(DELAY_BETWEEN) end
end

if allOk then shared.TCP.Loaded=true; shared._TCP_LOADING=nil; LS.ShowSuccess() end
