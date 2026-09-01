-- NyraUI v9.0  •  Farms-focused layout
-- Z = toggle visibility

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local CAS              = game:GetService("ContextActionService")
local Workspace        = game:GetService("Workspace")

local LP     = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

pcall(function() CAS:UnbindAction("NyraToggle") end)
for _,n in ipairs({"NyraUI","NyraCrosshair","NyraVel","NyraFOV"}) do
    local o = CoreGui:FindFirstChild(n); if o then o:Destroy() end
end

-- ════════════════════════════════════════════════════════════
--  CONFIG  (only farms kept)
-- ════════════════════════════════════════════════════════════
local Cfg = {
    -- farms
    bankFarm         = false,
    binsFarm         = false,
    casinoFarm       = false,
    gunpowderFarm    = false,
    atmFarm          = false,
    jewelryFarm      = false,
    -- sliders
    tweenSpeed       = 1.0,  -- seconds per tween (0.5 to 5)
    respawnTime      = 10,   -- seconds for reset cooldown (5 to 15)
    -- keybind
    keybindToggle    = "Z",
}

-- ════════════════════════════════════════════════════════════
--  PALETTE  (vizor-style near-black)
-- ════════════════════════════════════════════════════════════
local C = {
    bg       = Color3.fromRGB(17,  17,  17),
    sidebar  = Color3.fromRGB(17,  17,  17),
    mid      = Color3.fromRGB(20,  20,  20),
    right    = Color3.fromRGB(23,  23,  23),
    card     = Color3.fromRGB(26,  26,  26),
    cardHov  = Color3.fromRGB(32,  32,  32),
    row      = Color3.fromRGB(26,  26,  26),
    rowHov   = Color3.fromRGB(32,  32,  32),
    tab      = Color3.fromRGB(30,  30,  30),
    tabSel   = Color3.fromRGB(38,  38,  38),
    border   = Color3.fromRGB(38,  38,  38),
    borderLo = Color3.fromRGB(30,  30,  30),
    txt      = Color3.fromRGB(242, 242, 242),
    txtSub   = Color3.fromRGB(140, 140, 140),
    txtDim   = Color3.fromRGB(72,  72,  72),
    sldBg    = Color3.fromRGB(50,  50,  50),
    sldFill  = Color3.fromRGB(200, 200, 200),
    togOff   = Color3.fromRGB(60,  60,  60),
    togOn    = Color3.fromRGB(255, 255, 255),
    white    = Color3.fromRGB(255, 255, 255),
    black    = Color3.fromRGB(0,   0,   0),
    red      = Color3.fromRGB(220, 50,  50),
    green    = Color3.fromRGB(80,  200, 120),
}

-- ════════════════════════════════════════════════════════════
--  HELPERS
-- ════════════════════════════════════════════════════════════
local function N(cls, props)
    local o = Instance.new(cls)
    for k,v in pairs(props) do if type(k)=="string" then o[k]=v end end
    return o
end
local function cr(r,p)  local u=Instance.new("UICorner");u.CornerRadius=UDim.new(0,r);u.Parent=p end
local function sk(c,t,p) local s=Instance.new("UIStroke");s.Color=c;s.Thickness=t;s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Parent=p end
local function pd(l,r,t,b,p) local u=Instance.new("UIPadding");u.PaddingLeft=UDim.new(0,l);u.PaddingRight=UDim.new(0,r);u.PaddingTop=UDim.new(0,t);u.PaddingBottom=UDim.new(0,b);u.Parent=p end
local function vl(sp,p)  local l=Instance.new("UIListLayout");l.SortOrder=Enum.SortOrder.LayoutOrder;l.Padding=UDim.new(0,sp);l.Parent=p;return l end
local function hl(sp,p)  local l=Instance.new("UIListLayout");l.FillDirection=Enum.FillDirection.Horizontal;l.SortOrder=Enum.SortOrder.LayoutOrder;l.Padding=UDim.new(0,sp);l.Parent=p;return l end
local function tw(o,t,props) TweenService:Create(o,TweenInfo.new(t,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),props):Play() end
local function line(parent,lo)
    return N("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.border,BorderSizePixel=0,ZIndex=4,LayoutOrder=lo or 0,Parent=parent})
end

-- New helper: tween HumanoidRootPart to target position
local function tweenTo(hrp, targetPos, duration)
    if not hrp or not targetPos then return end
    duration = duration or Cfg.tweenSpeed
    local tween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = CFrame.new(targetPos.X, targetPos.Y, targetPos.Z)})
    tween:Play()
    tween.Completed:Wait()
end

-- ════════════════════════════════════════════════════════════
--  SCREEN GUI + ROOT WINDOW
-- ════════════════════════════════════════════════════════════
local Screen
pcall(function()
    Screen = N("ScreenGui",{Name="NyraUI",ResetOnSpawn=false,
        ZIndexBehavior=Enum.ZIndexBehavior.Global,DisplayOrder=999,IgnoreGuiInset=true,Parent=CoreGui})
end)
if not Screen then
    Screen = N("ScreenGui",{Name="NyraUI",ResetOnSpawn=false,
        ZIndexBehavior=Enum.ZIndexBehavior.Global,DisplayOrder=999,IgnoreGuiInset=true,
        Parent=LP:WaitForChild("PlayerGui")})
end

local WIN_W,WIN_H = 960,580

-- ════════════════════════════════════════════════════════════
--  MAIN WINDOW
-- ════════════════════════════════════════════════════════════
local Win = N("Frame",{Name="Window",
    Size=UDim2.new(0,WIN_W,0,WIN_H),
    AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.new(0.5,0,0.5,0),
    BackgroundColor3=C.bg, BorderSizePixel=0,
    ClipsDescendants=true, Visible=true,
    BackgroundTransparency=0, Parent=Screen})
cr(10,Win); sk(C.border,1,Win)

-- drag
do
    local drag,ds,dp=false,nil,nil
    Win.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true;ds=i.Position;dp=Win.Position end end)
    Win.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-ds; Win.Position=UDim2.new(dp.X.Scale,dp.X.Offset+d.X,dp.Y.Scale,dp.Y.Offset+d.Y)
        end
    end)
end

-- ════════════════════════════════════════════════════════════
--  LEFT SIDEBAR  240px
-- ════════════════════════════════════════════════════════════
local SB_W = 240
local Sidebar = N("Frame",{Size=UDim2.new(0,SB_W,1,0),BackgroundColor3=C.sidebar,BorderSizePixel=0,ZIndex=3,Parent=Win})
N("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(1,-1,0,0),BackgroundColor3=C.border,BorderSizePixel=0,ZIndex=4,Parent=Sidebar})

local SbScroll = N("ScrollingFrame",{Size=UDim2.new(1,0,1,-56),Position=UDim2.new(0,0,0,0),
    BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,
    ScrollBarImageColor3=C.borderLo,CanvasSize=UDim2.new(0,0,0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=3,Parent=Sidebar})
local SbInner = N("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
    BackgroundTransparency=1,ZIndex=3,Parent=SbScroll})
vl(0,SbInner)
pd(12,12,10,10,SbInner)

-- branding strip at bottom of sidebar
local Brand = N("Frame",{Size=UDim2.new(1,0,0,56),AnchorPoint=Vector2.new(0,1),
    Position=UDim2.new(0,0,1,0),BackgroundColor3=C.sidebar,BorderSizePixel=0,ZIndex=4,Parent=Sidebar})
N("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.border,BorderSizePixel=0,ZIndex=5,Parent=Brand})
pd(16,0,0,0,Brand)
N("TextLabel",{Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,8),
    BackgroundTransparency=1,Text="Nyra",TextColor3=C.txt,TextSize=14,
    Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5,Parent=Brand})
N("TextLabel",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,0,30),
    BackgroundTransparency=1,Text="the best hard time script",TextColor3=C.txtDim,TextSize=9,
    Font=Enum.Font.SourceSans,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5,Parent=Brand})

-- ════════════════════════════════════════════════════════════
--  MIDDLE PANEL  260px
-- ════════════════════════════════════════════════════════════
local MID_W = 260
local MidPanel = N("Frame",{Size=UDim2.new(0,MID_W,1,0),Position=UDim2.new(0,SB_W,0,0),
    BackgroundColor3=C.mid,BorderSizePixel=0,ZIndex=3,Parent=Win})
N("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(1,-1,0,0),BackgroundColor3=C.border,BorderSizePixel=0,ZIndex=4,Parent=MidPanel})

-- item header
local MidHeader = N("Frame",{Size=UDim2.new(1,0,0,72),BackgroundTransparency=1,ZIndex=4,Parent=MidPanel})
pd(16,16,14,0,MidHeader)
local MidTitle = N("TextLabel",{Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,12),
    BackgroundTransparency=1,Text="",TextColor3=C.txt,TextSize=14,Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5,Parent=MidHeader})
local MidDesc = N("TextLabel",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,0,36),
    BackgroundTransparency=1,Text="",TextColor3=C.txtSub,TextSize=9,Font=Enum.Font.SourceSans,
    TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,ZIndex=5,Parent=MidHeader})
N("Frame",{Size=UDim2.new(1,-32,0,1),Position=UDim2.new(0,16,1,-1),BackgroundColor3=C.border,BorderSizePixel=0,ZIndex=4,Parent=MidHeader})

-- tab bar
local TabBar = N("Frame",{Size=UDim2.new(1,0,0,36),Position=UDim2.new(0,0,0,72),
    BackgroundTransparency=1,ZIndex=4,Parent=MidPanel})
pd(16,16,0,0,TabBar)
local TabRow = N("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ZIndex=4,Parent=TabBar})
hl(4,TabRow)
N("Frame",{Size=UDim2.new(1,-32,0,1),Position=UDim2.new(0,16,1,-1),BackgroundColor3=C.border,BorderSizePixel=0,ZIndex=4,Parent=TabBar})

-- right panel scroll
local RIGHT_X = SB_W + MID_W
local RightPanel = N("ScrollingFrame",{
    Size=UDim2.new(1,-RIGHT_X,1,0),Position=UDim2.new(0,RIGHT_X,0,0),
    BackgroundColor3=C.right,BorderSizePixel=0,
    ScrollBarThickness=2,ScrollBarImageColor3=C.borderLo,
    CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
    ZIndex=3,Parent=Win})
local RightInner = N("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
    BackgroundTransparency=1,ZIndex=3,Parent=RightPanel})
vl(0,RightInner)
pd(20,20,12,16,RightInner)

-- ════════════════════════════════════════════════════════════
--  WIDGET BUILDERS
-- ════════════════════════════════════════════════════════════

-- Section label
local function secLabel(parent, title, lo)
    local f = N("Frame",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,
        ZIndex=4,LayoutOrder=lo or 0,Parent=parent})
    N("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
        Text=title:upper(),TextColor3=C.txtDim,TextSize=9,Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5,Parent=f})
    return f
end

-- Setting row container
local function mkRow(parent, title, sub, lo)
    local row = N("Frame",{Size=UDim2.new(1,0,0,sub and 56 or 44),
        BackgroundColor3=C.row,BorderSizePixel=0,ZIndex=4,LayoutOrder=lo or 0,Parent=parent})
    cr(8,row)
    N("TextLabel",{Size=UDim2.new(0.65,0,0,18),Position=UDim2.new(0,14,0,sub and 9 or 13),
        BackgroundTransparency=1,Text=title,TextColor3=C.txt,TextSize=12,
        Font=Enum.Font.SourceSansSemibold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5,Parent=row})
    if sub then
        N("TextLabel",{Size=UDim2.new(0.65,0,0,13),Position=UDim2.new(0,14,0,28),
            BackgroundTransparency=1,Text=sub,TextColor3=C.txtSub,TextSize=9,
            Font=Enum.Font.SourceSans,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5,Parent=row})
    end
    row.MouseEnter:Connect(function() tw(row,0.08,{BackgroundColor3=C.rowHov}) end)
    row.MouseLeave:Connect(function() tw(row,0.08,{BackgroundColor3=C.row}) end)
    return row
end

-- Toggle
local function mkToggle(parent, title, sub, cfgKey, lo, cb)
    local row = mkRow(parent,title,sub,lo)
    local track = N("Frame",{Size=UDim2.new(0,44,0,24),AnchorPoint=Vector2.new(1,0.5),
        Position=UDim2.new(1,-14,0.5,0),BorderSizePixel=0,ZIndex=5,Parent=row})
    cr(12,track)
    local thumb = N("Frame",{Size=UDim2.new(0,18,0,18),AnchorPoint=Vector2.new(0,0.5),
        Position=UDim2.new(0,3,0.5,0),BackgroundColor3=C.white,BorderSizePixel=0,ZIndex=6,Parent=track})
    cr(9,thumb)
    local function refresh()
        local on = Cfg[cfgKey]
        tw(track,0.15,{BackgroundColor3=on and C.togOn or C.togOff})
        tw(thumb,0.15,{Position=on and UDim2.new(0,23,0.5,0) or UDim2.new(0,3,0.5,0),
            BackgroundColor3=on and C.bg or C.white})
    end
    refresh()
    row.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            Cfg[cfgKey]=not Cfg[cfgKey]; refresh(); if cb then cb(Cfg[cfgKey]) end
        end
    end)
    return row
end

-- Slider (new widget)
local function mkSlider(parent, title, sub, cfgKey, minVal, maxVal, lo, cb)
    local row = mkRow(parent, title, sub, lo)
    local sliderBg = N("Frame", {Size=UDim2.new(0,120,0,6), AnchorPoint=Vector2.new(1,0.5),
        Position=UDim2.new(1,-14,0.5,0), BackgroundColor3=C.sldBg, BorderSizePixel=0, ZIndex=5, Parent=row})
    cr(3, sliderBg)
    local sliderFill = N("Frame", {Size=UDim2.new(0.5,0,1,0), BackgroundColor3=C.sldFill, BorderSizePixel=0, ZIndex=6, Parent=sliderBg})
    cr(3, sliderFill)
    local thumb = N("Frame", {Size=UDim2.new(0,12,0,12), AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(0.5,0,0.5,0), BackgroundColor3=C.white, BorderSizePixel=0, ZIndex=7, Parent=sliderBg})
    cr(6, thumb)
    local valueLabel = N("TextLabel", {Size=UDim2.new(0.4,0,1,0), Position=UDim2.new(0,-50,0,0),
        BackgroundTransparency=1, Text=string.format("%.1f", Cfg[cfgKey]), TextColor3=C.txt, TextSize=10,
        Font=Enum.Font.SourceSans, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5, Parent=row})

    local function updateSlider()
        local val = Cfg[cfgKey]
        local ratio = (val - minVal) / (maxVal - minVal)
        tw(sliderFill, 0.1, {Size=UDim2.new(ratio, 0, 1, 0)})
        tw(thumb, 0.1, {Position=UDim2.new(ratio, 0, 0.5, 0)})
        valueLabel.Text = string.format("%.1f", val)
        if cb then cb(val) end
    end
    updateSlider()

    local dragging = false
    sliderBg.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    sliderBg.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = UserInputService:GetMouseLocation()
            local relPos = mousePos.X - sliderBg.AbsolutePosition.X
            local ratio = math.clamp(relPos / sliderBg.AbsoluteSize.X, 0, 1)
            Cfg[cfgKey] = minVal + ratio * (maxVal - minVal)
            updateSlider()
        end
    end)
    return row
end

-- ════════════════════════════════════════════════════════════
--  SIDEBAR / PAGE SYSTEM
-- ════════════════════════════════════════════════════════════
local activeItem = nil
local activeTabName = nil

local function clearRight()
    for _,c in ipairs(RightInner:GetChildren()) do
        if not c:IsA("UIPadding") and not c:IsA("UIListLayout") then c:Destroy() end
    end
end
local function clearTabs()
    for _,c in ipairs(TabRow:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
end

-- tab button builder
local tabBtns = {}
local function buildTabs(tabDefs)
    clearTabs(); tabBtns={}
    for idx,td in ipairs(tabDefs) do
        local b = N("TextButton",{Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,
            BackgroundColor3=C.tab,BorderSizePixel=0,
            Text=td.name,TextColor3=C.txtSub,TextSize=10,Font=Enum.Font.SourceSans,
            ZIndex=6,LayoutOrder=idx,Parent=TabRow})
        cr(6,b); pd(10,10,0,0,b)
        td.btn=b; tabBtns[td.name]=td
        b.MouseButton1Click:Connect(function()
            for _,t in pairs(tabBtns) do
                tw(t.btn,0.1,{BackgroundColor3=C.tab}); t.btn.TextColor3=C.txtSub; t.btn.Font=Enum.Font.SourceSans
            end
            tw(b,0.1,{BackgroundColor3=C.tabSel}); b.TextColor3=C.white; b.Font=Enum.Font.SourceSansSemibold
            activeTabName=td.name
            clearRight()
            if td.build then td.build(RightInner) end
        end)
    end
    -- activate first tab
    if tabDefs[1] then
        local t=tabDefs[1]
        t.btn.BackgroundColor3=C.tabSel; t.btn.TextColor3=C.white; t.btn.Font=Enum.Font.SourceSansSemibold
        activeTabName=t.name; clearRight()
        if t.build then t.build(RightInner) end
    end
end

-- sidebar group label
local function sbGroup(title, lo)
    local f = N("Frame",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,ZIndex=4,LayoutOrder=lo,Parent=SbInner})
    N("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=title,
        TextColor3=C.txtDim,TextSize=9,Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5,Parent=f})
    return f
end

-- sidebar item card
local function sbItem(title, lo, onSelect)
    local card = N("TextButton",{Size=UDim2.new(1,0,0,36),BackgroundColor3=C.card,
        BorderSizePixel=0,Text="",ZIndex=4,LayoutOrder=lo,Parent=SbInner})
    cr(8,card)
    local lbl = N("TextLabel",{Size=UDim2.new(1,0,1,0),Position=UDim2.new(0,14,0,0),
        BackgroundTransparency=1,Text=title,TextColor3=C.txt,TextSize=11,
        Font=Enum.Font.SourceSansSemibold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5,Parent=card})
    card.MouseEnter:Connect(function() if activeItem~=title then tw(card,0.08,{BackgroundColor3=C.cardHov}) end end)
    card.MouseLeave:Connect(function() if activeItem~=title then tw(card,0.08,{BackgroundColor3=C.card}) end end)
    card.MouseButton1Click:Connect(function()
        if activeItem==title then return end
        activeItem=title
        for _,c in ipairs(SbInner:GetChildren()) do
            if c:IsA("TextButton") then tw(c,0.08,{BackgroundColor3=C.card}) end
        end
        tw(card,0.08,{BackgroundColor3=C.tabSel})
        onSelect()
    end)
    return card, lbl
end

-- ════════════════════════════════════════════════════════════
--  FARMS
-- ════════════════════════════════════════════════════════════
local function selectFarms()
    MidTitle.Text="Auto Farms"
    MidDesc.Text="Automatically collect money from various sources"

    buildTabs({
        { name="Farms", build=function(P)
            secLabel(P,"Money",1)
            mkToggle(P,"Bank Farm","Auto-rob the bank repeatedly","bankFarm",2)
            mkToggle(P,"ATM Farm","Holds R at each ATM underground","atmFarm",3)
            mkToggle(P,"Casino Farm","Holds E at each casino spot underground","casinoFarm",4)
            mkToggle(P,"Bins Farm","Holds R at each bin underground","binsFarm",5)
            mkToggle(P,"Jewelry Farm","Holds E at each jewelry display underground","jewelryFarm",6)
            mkToggle(P,"Gunpowder Farm","Auto-collect and sell gunpowder","gunpowderFarm",7)
            secLabel(P,"Settings",8)
            mkSlider(P,"Tween Speed","Seconds per move","tweenSpeed",0.5,5.0,9)
            mkSlider(P,"Respawn Time","Seconds after reset","respawnTime",5,15,10)
        end},
    })
end

-- ════════════════════════════════════════════════════════════
--  BUILD SIDEBAR GROUPS
-- ════════════════════════════════════════════════════════════
sbGroup("Farms",1)
sbItem("Auto Farms",2, selectFarms)

-- boot: select first item
selectFarms()
-- mark Farms card as active visually
do
    local cards={}
    for _,c in ipairs(SbInner:GetChildren()) do if c:IsA("TextButton") then table.insert(cards,c) end end
    if cards[1] then cards[1].BackgroundColor3=C.tabSel end
    activeItem="Auto Farms"
end

-- ════════════════════════════════════════════════════════════
--  KEY HELPERS
-- ════════════════════════════════════════════════════════════
-- Try every known executor key API so it works across Synapse, KRNL, Fluxus, etc.
-- ════════════════════════════════════════════════════════════
--  PROXIMITY PROMPT HELPERS
-- ════════════════════════════════════════════════════════════

local function getPromptNear(position, radius)
    radius = radius or 6

    local closest = nil
    local closestDist = radius

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local parent = obj.Parent
            local part = nil

            if parent:IsA("BasePart") then
                part = parent
            elseif parent:IsA("Attachment") and parent.Parent:IsA("BasePart") then
                part = parent.Parent
            end

            if part then
                local dist = (part.Position - position).Magnitude

                if dist <= closestDist then
                    closest = obj
                    closestDist = dist
                end
            end
        end
    end

    return closest
end

local function activatePromptAt(position, radius)
    local prompt = getPromptNear(position, radius or 8)

    if not prompt then
        return false
    end

    -- Roblox exploit environments commonly expose
    -- fireproximityprompt for activating an existing prompt.
    if fireproximityprompt then
        local ok = pcall(function()
            fireproximityprompt(prompt)
        end)

        return ok
    end

    return false
end

local function activatePromptRepeated(position, duration, radius)
    local prompt = getPromptNear(position, radius or 8)

    if not prompt then
        return false
    end

    duration = duration or 1.5

    if fireproximityprompt then
        local start = os.clock()

        while os.clock() - start < duration do
            if not prompt.Parent then
                break
            end

            pcall(function()
                fireproximityprompt(prompt)
            end)

            task.wait(0.1)
        end

        return true
    end

    return false
end

-- Make existing prompts nearly instant.
local function setPromptDuration(obj)
    if obj:IsA("ProximityPrompt") then
        obj.HoldDuration = 0.01
    end
end

for _, obj in ipairs(Workspace:GetDescendants()) do
    setPromptDuration(obj)
end

Workspace.DescendantAdded:Connect(setPromptDuration)

-- helper: reset character via Esc → R → Shift (fast in-game menu reset)
local function resetAndWait()
    local oldChar = LP.Character

    -- Server reset event
    pcall(function()
        ResetEvent:FireServer("Reset")
    end)

    -- Wait for the new character
    local t = 0
    repeat
        task.wait(0.1)
        t += 0.1
    until (
        LP.Character
        and LP.Character ~= oldChar
        and LP.Character:FindFirstChild("HumanoidRootPart")
    ) or t > 8

    task.wait(0.5)
end
    -- wait for new character to load (up to 8 s)
    local t = 0
    repeat
        task.wait(0.1); t = t + 0.1
    until (LP.Character and LP.Character ~= oldChar and LP.Character:FindFirstChild("HumanoidRootPart")) or t > 8
    task.wait(0.5) -- settle before next TP
end

-- ════════════════════════════════════════════════════════════
--  BANK FARM
-- ════════════════════════════════════════════════════════════

local BANK_BUTTON_POS = Vector3.new(-808, 2, -43)   -- green/red check
local HOTEL_POS       = Vector3.new(-574, 6, 120)   -- delivery point

-- Three waves of cash-bag spots inside the bank
local BANK_WAVES = {
    {   -- wave 1
        Vector3.new(-799, 2, -33),
        Vector3.new(-794, 2, -35),
        Vector3.new(-790, 2, -36),
        Vector3.new(-791, 2, -31),
        Vector3.new(-795, 2, -31),
        Vector3.new(-798, 2, -29),
        Vector3.new(-801, 2, -30),
        Vector3.new(-803, 2, -34),
    },
    {   -- wave 2
        Vector3.new(-806, 2, -35),
        Vector3.new(-807, 2, -31),
        Vector3.new(-805, 2, -26),
        Vector3.new(-801, 2, -25),
        Vector3.new(-795, 2, -26),
        Vector3.new(-792, 2, -27),
        Vector3.new(-796, 2, -22),
        Vector3.new(-800, 2, -24),
    },
    {   -- wave 3
        Vector3.new(-805, 2, -22),
        Vector3.new(-800, 2, -21),
        Vector3.new(-797, 2, -22),
        Vector3.new(-791, 2, -22),
        Vector3.new(-792, 2, -18),
        Vector3.new(-795, 2, -18),
        Vector3.new(-800, 2, -21),
        Vector3.new(-806, 2, -22),
    },
}

local function getBankButtonColor()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            if (obj.Position - BANK_BUTTON_POS).Magnitude < 3 then
                return obj.BrickColor
            end
        end
    end
    return nil
end

local function bankIsOpen()
    local bc = getBankButtonColor()
    if not bc then return false end
    local name = bc.Name:lower()
    return name:find("green") ~= nil or name:find("lime") ~= nil
end

-- deliver to hotel: tween there, spam E for 5 s, then reset character
local function deliverAndReset()
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        tweenTo(hrp, HOTEL_POS, Cfg.tweenSpeed)
        task.wait(0.5)
        activatePromptRepeated(HOTEL_POS, 5.0, 10)
        task.wait(0.3)
    end
    resetAndWait()
    -- wait configured respawn time underground
    local waited = 0
    while waited < Cfg.respawnTime and Cfg.bankFarm do
        task.wait(0.5); waited = waited + 0.5
    end
    -- tween back up to bank
    char = LP.Character
    hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        tweenTo(hrp, BANK_BUTTON_POS, Cfg.tweenSpeed)
        task.wait(0.3)
    end
end

local function runBankLoop()
    while Cfg.bankFarm do
        -- wait for bank to be open (green button)
        while Cfg.bankFarm and not bankIsOpen() do
            task.wait(1.0)
        end
        if not Cfg.bankFarm then break end

        -- rob each wave then deliver to hotel
        for _, wave in ipairs(BANK_WAVES) do
            if not Cfg.bankFarm then break end
            local tpCount = 0
            for _, pos in ipairs(wave) do
                if not Cfg.bankFarm then break end
                local char = LP.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    tweenTo(hrp, pos, Cfg.tweenSpeed)
                    task.wait(0.3)
                    holdE(1.5)   -- pick up cash bag
                    task.wait(0.5)
                    tpCount = tpCount + 1
                    -- reset every 2 teleports mid-wave
                    if tpCount % 2 == 0 then
                        if not Cfg.bankFarm then break end
                        resetAndWait()
                    end
                else
                    task.wait(1.0)
                end
            end
            if not Cfg.bankFarm then break end
            -- wave done: deliver to hotel + reset
            deliverAndReset()
        end
    end
end

-- ════════════════════════════════════════════════════════════
--  BINS FARM  +  ATM FARM
-- ════════════════════════════════════════════════════════════

local BINS_COORDS = {
    Vector3.new(-1224, 3, -585),
    Vector3.new(-196,  2, -28),
    Vector3.new(-572,  2, -22),
    Vector3.new(-744,  3, -76),
    Vector3.new(-1018, 3, -199),
    Vector3.new(-1169, 3, -325),
    Vector3.new(-1225, 3, -298),
    Vector3.new(-1312, 2, -403),
    Vector3.new(-1223, 3, -585),
    Vector3.new(-1066, 3, -650),
    Vector3.new(-1043, 3, -520),
    Vector3.new(-1032, 3, -560),
    Vector3.new(-881,  2, -600),
    Vector3.new(-1020, 2, -725),
    Vector3.new(-1148, 2, -550),
}

local ATM_COORDS = {
    Vector3.new(-1059, 3, -459),
    Vector3.new(-1059, 3, -579),
    Vector3.new(-1273, 3, -573),
    Vector3.new(-1222, 3, -457),
    Vector3.new(-1011, 2, -222),
    Vector3.new(-1039, 3, -153),
    Vector3.new(-844,  3, -91),
    Vector3.new(-674,  3, -220),
    Vector3.new(-664,  2, -370),
    Vector3.new(-820,  3, -562),
    Vector3.new(-644,  3, -657),
    Vector3.new(-621,  3, -562),
    Vector3.new(-492,  3, -387),
}

local JEWELRY_COORDS = {
    Vector3.new(-607, 3, -625),
    Vector3.new(-607, 3, -633),
    Vector3.new(-596, 3, -625),
    Vector3.new(-596, 3, -633),
    Vector3.new(-585, 3, -647),
    Vector3.new(-584, 3, -612),
    Vector3.new(-585, 3, -604),
    Vector3.new(-622, 3, -624),
    Vector3.new(-621, 3, -634),
    Vector3.new(-633, 3, -633),
    Vector3.new(-632, 3, -624),
    Vector3.new(-646, 3, -625),
    Vector3.new(-645, 3, -633),
    Vector3.new(-657, 3, -633),
    Vector3.new(-657, 3, -624),
    Vector3.new(-667, 3, -638),
    Vector3.new(-667, 3, -647),
    Vector3.new(-667, 3, -613),
    Vector3.new(-668, 3, -604),
}

-- Casino: given coords plus a 3x3 grid of offsets around each to hit every slot
local CASINO_BASE = {
    Vector3.new(-1161, 4, -776),
    Vector3.new(-1159, 4, -781),
    Vector3.new(-1167, 4, -779),
    Vector3.new(-1173, 4, -775),
    Vector3.new(-1173, 7, -784),
    Vector3.new(-1171, 7, -788),
    Vector3.new(-1172, 7, -792),
    Vector3.new(-1172, 4, -798),
    Vector3.new(-1167, 4, -801),
    Vector3.new(-1166, 4, -795),
}
-- expand with ±2 offsets on X/Z to cover surrounding area
local CASINO_COORDS = {}
local _casinoOffsets = {-2, 0, 2}
for _, base in ipairs(CASINO_BASE) do
    for _, ox in ipairs(_casinoOffsets) do
        for _, oz in ipairs(_casinoOffsets) do
            table.insert(CASINO_COORDS, Vector3.new(base.X+ox, base.Y, base.Z+oz))
        end
    end
end

-- Bins: tween → settle → hold R 3 s → tween to next bin, reset every 2 bins
local function runBinsLoop()
    local count = 0
    while Cfg.binsFarm do
        for idx = 1, #BINS_COORDS do
            if not Cfg.binsFarm then break end
            local char = LP.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local pos = BINS_COORDS[idx]
                tweenTo(hrp, pos, Cfg.tweenSpeed)
                task.wait(0.3)    -- settle
                activatePromptRepeated(pos, 3.0, 8)--Activates Prompt to trigger it to Rob
                task.wait(0.5)    -- brief gap before next TP
                count = count + 1
                -- reset every 2 bins
                if count % 2 == 0 then
                    if not Cfg.binsFarm then break end
                    resetAndWait()
                end
            else
                task.wait(1.0)
            end
        end
        if not Cfg.binsFarm then break end
        -- full cycle done: reset + configured respawn time cooldown
        resetAndWait()
        local waited = 0
        while waited < Cfg.respawnTime and Cfg.binsFarm do
            task.wait(0.5); waited = waited + 0.5
        end
    end
end

-- ATM: configured tween time per ATM × 2 = ~7 s then reset character
local function runAtmLoop()
    local count = 0
    local atmIdx = 1
    while Cfg.atmFarm do
        if not Cfg.atmFarm then break end
        -- always re-fetch character fresh each iteration
        local char = LP.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then task.wait(1.0); continue end

        local pos = ATM_COORDS[atmIdx]
        tweenTo(hrp, pos, Cfg.tweenSpeed)
        task.wait(0.2)    -- settle
        activatePromptRepeated(pos, 1.5, 8)
        task.wait(0.2)
        activatePromptRepeated(pos, 1.5, 8)
        -- collect
        task.wait(0.3)    -- gap  →  3.5 s per ATM, 2 ATMs = 7 s
        count = count + 1
        atmIdx = atmIdx % #ATM_COORDS + 1

        -- reset after every 2 ATMs
        if count % 2 == 0 then
            if not Cfg.atmFarm then break end
            resetAndWait()
            -- wait configured respawn time
            local waited = 0
            while waited < Cfg.respawnTime and Cfg.atmFarm do
                task.wait(0.5); waited = waited + 0.5
            end
        end
    end
end

-- E-hold loop (jewelry, casino)
local function runEFarmLoop(cfgKey, coords)
    local idx = 1
    local count = 0
    while Cfg[cfgKey] do
        local char = LP.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local pos = coords[idx]
            tweenTo(hrp, pos, Cfg.tweenSpeed)
            task.wait(0.5)            -- settle
            activatePromptRepeated(pos, 3.5, 8)
            task.wait(0.3)            -- brief gap before next spot
            count = count + 1
            -- every 2 teleports: tween to hotel, spam E, then reset
            if count % 2 == 0 then
                if not Cfg[cfgKey] then break end
                -- tween to hotel
                local c2 = LP.Character
                local h2 = c2 and c2:FindFirstChild("HumanoidRootPart")
                if h2 then
                    tweenTo(h2, HOTEL_POS, Cfg.tweenSpeed)
                    task.wait(0.5)
                    activatePromptRepeated(HOTEL_POS, 5.0, 10)
                    task.wait(0.3)
                end
                resetAndWait()
                -- wait configured respawn time
                local waited = 0
                while waited < Cfg.respawnTime and Cfg[cfgKey] do
                    task.wait(0.5); waited = waited + 0.5
                end
            end
        else
            task.wait(1.0)
        end
        idx = idx % #coords + 1
    end
end

-- Casino vault check coordinate
local CASINO_DOOR_POS = Vector3.new(-1147, 4, -764)

-- Find the part at/near the vault door and read its color
local function getVaultDoorColor()
    -- look for any BasePart within 3 studs of the check coordinate
    local found = nil
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            if (obj.Position - CASINO_DOOR_POS).Magnitude < 3 then
                found = obj; break
            end
        end
    end
    return found and found.BrickColor or nil
end

local function vaultIsOpen()
    local bc = getVaultDoorColor()
    if not bc then return false end
    -- green = open, red = locked
    -- BrickColor names that count as "green"
    local name = bc.Name:lower()
    return name:find("green") ~= nil or name:find("lime") ~= nil or name:find("bright green") ~= nil
end

-- Casino: check vault door color each cycle
--   RED  → tween underground at door pos to bypass, then farm
--   GREEN → tween to door, click E to enter, then farm
local function runCasinoLoop()
    while Cfg.casinoFarm do
        local char = LP.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then task.wait(1); continue end

if vaultIsOpen() then
    tweenTo(hrp, CASINO_DOOR_POS, Cfg.tweenSpeed)
    task.wait(0.8)

    -- Enter using the ProximityPrompt instead of E.
    activatePromptAt(CASINO_DOOR_POS, 8)

    task.wait(1.0)
else
    tweenTo(hrp, CASINO_DOOR_POS, Cfg.tweenSpeed)
    task.wait(0.5)
end


        -- farm all casino coords (spam E at each), hotel+reset every 2 TPs
        local casinoCount = 0
        for idx = 1, #CASINO_COORDS do
            if not Cfg.casinoFarm then break end
            char = LP.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local pos = CASINO_COORDS[idx]
                tweenTo(hrp, pos, Cfg.tweenSpeed)
                task.wait(0.5)
                activatePromptRepeated(pos, 3.5, 8)--Replacment of the Hold continously function
                task.wait(0.3)
                casinoCount = casinoCount + 1
                -- every 2 TPs: tween to hotel → spam E → reset
                if casinoCount % 2 == 0 then
                    if not Cfg.casinoFarm then break end
                    local c2 = LP.Character
                    local h2 = c2 and c2:FindFirstChild("HumanoidRootPart")
                    if h2 then
                        tweenTo(h2, HOTEL_POS, Cfg.tweenSpeed)
                        task.wait(0.5)
                        activatePromptRepeated(HOTEL_POS, 5.0, 10)
                        task.wait(0.3)
                    end
                    resetAndWait()
                    -- wait configured respawn time
                    local waited = 0
                    while waited < Cfg.respawnTime and Cfg.casinoFarm do
                        task.wait(0.5); waited = waited + 0.5
                    end
                end
            else
                task.wait(1.0)
            end
        end

        if not Cfg.casinoFarm then break end
    end
end

-- ---- active flags + watcher ----
local bankFarmActive    = false
local binsFarmActive    = false
local atmFarmActive     = false
local casinoFarmActive  = false
local jewelryFarmActive = false

RunService.Heartbeat:Connect(function()
    -- Bank
    if Cfg.bankFarm and not bankFarmActive then
        bankFarmActive = true
        task.spawn(function() runBankLoop(); bankFarmActive = false end)
    end
    if not Cfg.bankFarm then bankFarmActive = false end

    -- Bins: hold R 2.5 s
    if Cfg.binsFarm and not binsFarmActive then
        binsFarmActive = true
        task.spawn(function() runBinsLoop(); binsFarmActive = false end)
    end
    if not Cfg.binsFarm then binsFarmActive = false end

    -- ATM: hold R 1.5 s then click E
    if Cfg.atmFarm and not atmFarmActive then
        atmFarmActive = true
        task.spawn(function() runAtmLoop(); atmFarmActive = false end)
    end
    if not Cfg.atmFarm then atmFarmActive = false end

    -- Casino (smart vault check)
    if Cfg.casinoFarm and not casinoFarmActive then
        casinoFarmActive = true
        task.spawn(function() runCasinoLoop(); casinoFarmActive = false end)
    end
    if not Cfg.casinoFarm then casinoFarmActive = false end

    -- Jewelry (E)
    if Cfg.jewelryFarm and not jewelryFarmActive then
        jewelryFarmActive = true
        task.spawn(function() runEFarmLoop("jewelryFarm", JEWELRY_COORDS); jewelryFarmActive = false end)
    end
    if not Cfg.jewelryFarm then jewelryFarmActive = false end
end)

-- ════════════════════════════════════════════════════════════
--  Z KEY TOGGLE
-- ════════════════════════════════════════════════════════════
local uiVis=true
CAS:BindAction("NyraToggle",function(_,state)
    if state~=Enum.UserInputState.Begin then return end
    uiVis=not uiVis; Win.Visible=uiVis
end,false,Enum.KeyCode.Z)

-- ════════════════════════════════════════════════════════════
--  PROXIMITY PROMPT SPEED  (set all HoldDuration to 0.1 s)
-- ════════════════════════════════════════════════════════════
local function setPromptDuration(pp)
    if pp:IsA("ProximityPrompt") then pp.HoldDuration = 0.01 end
end
for _, pp in ipairs(Workspace:GetDescendants()) do setPromptDuration(pp) end
Workspace.DescendantAdded:Connect(setPromptDuration)
