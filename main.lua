-- NyraUI v1.0  •  vizor-style 3-panel layout
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
--  CONFIG
-- ════════════════════════════════════════════════════════════
local Cfg = {
    -- combat
    aimbotEnabled    = false,
    aimbotHold       = false,   -- false = toggle, true = hold
    aimbotFOV        = 150,
    aimbotSmooth     = 0.18,
    aimbotPart       = "Head",
    aimbotVisCheck   = true,
    aimbotTeamCheck  = true,
    aimbotKey        = "MouseButton2",
    aimbotPrediction = true,
    aimbotPredMult   = 0.10,
    aimbotFOVCircle  = true,
    aimbotTargetLock = false,  -- stay locked on current target until lost
    silentEnabled    = false,
    silentHold       = false,
    silentKey        = "MouseButton2",  -- independent key for silent aim
    silentHitscan    = true,
    silentRaycast    = true,   -- also hook modern Workspace:Raycast()
    silentFOV        = 200,
    silentTeamCheck  = true,
    silentPart       = "Head", -- body part silent aim redirects to
    antiAimEnabled   = false,
    antiAimMode      = "Spin",
    antiAimSpeed     = 10,
    -- exploit
    wallbangEnabled  = false,  -- make char parts passthrough so bullets/rays go through walls
    hitboxEnabled    = false,  -- expand enemy HRP hitbox
    hitboxSize       = 6,      -- studs to expand hitbox by
    fakeLagEnabled   = false,  -- throttle network updates to desync position
    fakeLagStrength  = 8,      -- frames to skip per packet
    rapidFireEnabled = false,  -- reduce tool fire cooldown
    -- visuals
    espEnabled       = false,
    espBoxes         = true,
    espNames         = true,
    espHealth        = true,
    espDistance      = true,
    espTracers       = false,
    espSkeleton      = false,
    espTeamColor     = false,
    espMaxDist       = 1000,
    chamsEnabled     = false,
    chamsTransp      = 0.45,
    -- crosshair
    crosshairEnabled = false,
    crosshairSize    = 10,
    crosshairGap     = 4,
    crosshairThick   = 2,
    crosshairStyle   = "Cross",   -- Cross | Dot | Circle
    -- velocity hud
    velHudEnabled    = false,
    -- misc
    flyEnabled          = false,
    flySpeed            = 60,
    walkSpeedEnabled    = false,
    walkSpeed           = 16,
    noclipEnabled       = false,
    infJumpEnabled      = false,
    -- farms
    bankFarm         = false,
    binsFarm         = false,
    casinoFarm       = false,
    gunpowderFarm    = false,
    atmFarm          = false,
    jewelryFarm      = false,
    antiAfkEnabled   = false,  -- hide underground + auto-trigger bank/casino/jewelry when ready
    farmTweenSpeed   = 16,     -- studs/s for farm tweens (slow start, constant speed)
    autoRejoinEnabled = false, -- auto-rejoin on kick and resume farms
    -- players
    spectateTarget   = "",
    -- player notes (table, keyed by player name)
    playerNotes      = {},
    -- settings
    accentColor      = Color3.fromRGB(255,255,255),
    keybindToggle    = "Z",
    keybindAimbot    = "MouseButton2",
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
local function tw(o,t,props,style,dir)
    TweenService:Create(o,TweenInfo.new(t,style or Enum.EasingStyle.Quad,dir or Enum.EasingDirection.Out),props):Play()
end
-- bounce tween (Quint Out — snappier feel for button presses)
local function twSnap(o,t,props) TweenService:Create(o,TweenInfo.new(t,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),props):Play() end
-- quick flash: animate to flashProps then back to restProps
local function twFlash(o, flashProps, restProps, halfTime)
    halfTime = halfTime or 0.06
    twSnap(o, halfTime, flashProps)
    task.delay(halfTime, function() twSnap(o, halfTime*1.5, restProps) end)
end
local function line(parent,lo)
    return N("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.border,BorderSizePixel=0,ZIndex=4,LayoutOrder=lo or 0,Parent=parent})
end

-- icon circle  (simple letter/symbol in a round frame)
local function iconCircle(parent, sym, sz)
    sz = sz or 28
    local f = N("Frame",{Size=UDim2.new(0,sz,0,sz),BackgroundColor3=C.borderLo,BorderSizePixel=0,ZIndex=6,Parent=parent})
    cr(sz/2,f)
    N("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=sym,
        TextColor3=C.txtSub,TextSize=sz*0.45,Font=Enum.Font.SourceSansBold,ZIndex=7,Parent=f})
    return f
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
--  MAIN WINDOW  (hidden until intro finishes)
-- ════════════════════════════════════════════════════════════
local Win = N("Frame",{Name="Window",
    Size=UDim2.new(0,WIN_W,0,WIN_H),
    AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.new(0.5,0,0.5,0),
    BackgroundColor3=C.bg, BorderSizePixel=0,
    ClipsDescendants=true, Visible=false,
    BackgroundTransparency=1, Parent=Screen})
cr(10,Win); sk(C.border,1,Win)

-- ════════════════════════════════════════════════════════════
--  INTRO SPLASH  (panel-sized, sits on top of Win)
-- ════════════════════════════════════════════════════════════
local Splash = N("Frame",{
    Size=UDim2.new(0,WIN_W,0,WIN_H),
    AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.new(0.5,0,0.5,0),
    BackgroundColor3=Color3.fromRGB(10,10,10),
    BorderSizePixel=0, ZIndex=1000, Parent=Screen
})
cr(10,Splash); sk(Color3.fromRGB(30,30,30),1,Splash)

-- top + bottom accent lines (sweep inward from edges)
local AccentTop = N("Frame",{
    Size=UDim2.new(0,0,0,1), Position=UDim2.new(0,0,0,0),
    BackgroundColor3=Color3.fromRGB(255,255,255),
    BorderSizePixel=0, ZIndex=1002, Parent=Splash
})
local AccentBot = N("Frame",{
    Size=UDim2.new(0,0,0,1),
    AnchorPoint=Vector2.new(1,1), Position=UDim2.new(1,0,1,0),
    BackgroundColor3=Color3.fromRGB(255,255,255),
    BorderSizePixel=0, ZIndex=1002, Parent=Splash
})

-- corner brackets  TL / TR / BL / BR  (each is two thin lines)
local function mkCorner(parent, ax, ay, px, py, flipX, flipY)
    local g = N("Frame",{Size=UDim2.new(0,24,0,24),
        AnchorPoint=Vector2.new(ax,ay), Position=UDim2.new(px,0,py,0),
        BackgroundTransparency=1, ZIndex=1003, Parent=parent})
    -- horizontal arm
    N("Frame",{Size=UDim2.new(1,0,0,1),
        AnchorPoint=Vector2.new(flipX and 1 or 0, flipY and 1 or 0),
        Position=UDim2.new(flipX and 1 or 0,0, flipY and 1 or 0,0),
        BackgroundColor3=Color3.fromRGB(80,80,80),BorderSizePixel=0,ZIndex=1004,Parent=g})
    -- vertical arm
    N("Frame",{Size=UDim2.new(0,1,1,0),
        AnchorPoint=Vector2.new(flipX and 1 or 0, flipY and 1 or 0),
        Position=UDim2.new(flipX and 1 or 0,0, flipY and 1 or 0,0),
        BackgroundColor3=Color3.fromRGB(80,80,80),BorderSizePixel=0,ZIndex=1004,Parent=g})
    return g
end
mkCorner(Splash, 0,0, 0,0, false,false)  -- TL
mkCorner(Splash, 1,0, 1,0, true, false)  -- TR
mkCorner(Splash, 0,1, 0,1, false,true)   -- BL
mkCorner(Splash, 1,1, 1,1, true, true)   -- BR

-- centre group
local SplashCentre = N("Frame",{
    Size=UDim2.new(0,400,0,180),
    AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.new(0.5,0,0.5,0),
    BackgroundTransparency=1, ZIndex=1002, Parent=Splash
})

-- logo (starts transparent + offset down)
local SplashLogo = N("TextLabel",{
    Size=UDim2.new(1,0,0,80),
    Position=UDim2.new(0,0,0,10),
    BackgroundTransparency=1,
    Text="NYRA",
    TextColor3=Color3.fromRGB(255,255,255),
    TextSize=72, Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Center,
    TextTransparency=1, ZIndex=1004, Parent=SplashCentre
})

-- thin divider line under logo
local SplashDiv = N("Frame",{
    Size=UDim2.new(0,0,0,1),
    AnchorPoint=Vector2.new(0.5,0),
    Position=UDim2.new(0.5,0,0,82),
    BackgroundColor3=Color3.fromRGB(40,40,40),
    BorderSizePixel=0, ZIndex=1004, Parent=SplashCentre
})

-- subtitle
local SplashSub = N("TextLabel",{
    Size=UDim2.new(1,0,0,18),
    Position=UDim2.new(0,0,0,90),
    BackgroundTransparency=1,
    Text="the best hard time script",
    TextColor3=Color3.fromRGB(55,55,55),
    TextSize=11, Font=Enum.Font.SourceSans,
    TextXAlignment=Enum.TextXAlignment.Center,
    TextTransparency=1, ZIndex=1004, Parent=SplashCentre
})

-- loading bar track
local BarTrack = N("Frame",{
    Size=UDim2.new(0,300,0,2),
    AnchorPoint=Vector2.new(0.5,0),
    Position=UDim2.new(0.5,0,0,142),
    BackgroundColor3=Color3.fromRGB(22,22,22),
    BorderSizePixel=0, ZIndex=1004, Parent=SplashCentre
})
cr(1,BarTrack)
local BarFill = N("Frame",{
    Size=UDim2.new(0,0,1,0),
    BackgroundColor3=Color3.fromRGB(210,210,210),
    BorderSizePixel=0, ZIndex=1005, Parent=BarTrack
})
cr(1,BarFill)

-- glowing leading dot on bar
local BarDot = N("Frame",{
    Size=UDim2.new(0,6,0,6),
    AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.new(0,0,0.5,0),
    BackgroundColor3=Color3.fromRGB(255,255,255),
    BorderSizePixel=0, ZIndex=1006, Parent=BarFill
})
cr(3,BarDot)

-- status label
local BarLabel = N("TextLabel",{
    Size=UDim2.new(1,0,0,13),
    AnchorPoint=Vector2.new(0.5,0),
    Position=UDim2.new(0.5,0,1,7),
    BackgroundTransparency=1,
    Text="",
    TextColor3=Color3.fromRGB(45,45,45),
    TextSize=9, Font=Enum.Font.SourceSansSemibold,
    TextXAlignment=Enum.TextXAlignment.Center,
    TextTransparency=1, ZIndex=1005, Parent=BarTrack
})

-- bottom-left: product tag
N("TextLabel",{
    Size=UDim2.new(0,120,0,13),
    AnchorPoint=Vector2.new(0,1),
    Position=UDim2.new(0,18,1,-14),
    BackgroundTransparency=1,
    Text="NYRA  ·  v1.0",
    TextColor3=Color3.fromRGB(30,30,30),
    TextSize=9, Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left,
    ZIndex=1002, Parent=Splash
})

-- bottom-right: build tag
N("TextLabel",{
    Size=UDim2.new(0,120,0,13),
    AnchorPoint=Vector2.new(1,1),
    Position=UDim2.new(1,-18,1,-14),
    BackgroundTransparency=1,
    Text="hard time script",
    TextColor3=Color3.fromRGB(30,30,30),
    TextSize=9, Font=Enum.Font.SourceSans,
    TextXAlignment=Enum.TextXAlignment.Right,
    ZIndex=1002, Parent=Splash
})

-- keep a ref so animation can access it
local AccentLine = AccentTop  -- alias used by old animation code

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
--  LEFT SIDEBAR  240px  (category groups + sub-items)
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
--  MIDDLE PANEL  260px  (item header + tab bar + content stub)
-- ════════════════════════════════════════════════════════════
local MID_W = 260
local MidPanel = N("Frame",{Size=UDim2.new(0,MID_W,1,0),Position=UDim2.new(0,SB_W,0,0),
    BackgroundColor3=C.mid,BorderSizePixel=0,ZIndex=3,Parent=Win})
N("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(1,-1,0,0),BackgroundColor3=C.border,BorderSizePixel=0,ZIndex=4,Parent=MidPanel})

-- item header (title + description, no icon)
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

-- right panel scroll (settings rows live here)
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
--  WIDGET BUILDERS  (vizor row style)
-- ════════════════════════════════════════════════════════════

-- Section label  (GENERAL, ADDITIONAL, etc.) — with left accent bar
local function secLabel(parent, title, lo)
    local f = N("Frame",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,
        ZIndex=4,LayoutOrder=lo or 0,Parent=parent})
    -- left bar
    N("Frame",{Size=UDim2.new(0,2,0,10),AnchorPoint=Vector2.new(0,0.5),
        Position=UDim2.new(0,0,0.5,0),BackgroundColor3=C.txtDim,
        BorderSizePixel=0,ZIndex=5,Parent=f})
    N("TextLabel",{Size=UDim2.new(1,0,1,0),Position=UDim2.new(0,8,0,0),
        BackgroundTransparency=1,
        Text=title:upper(),TextColor3=C.txtDim,TextSize=9,Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5,Parent=f})
    return f
end

-- lookup table: row instance → accent bar frame
local _rowAccents = {}

-- Setting row container  (title + sub-title + right widget)
local function mkRow(parent, title, sub, lo)
    local row = N("Frame",{Size=UDim2.new(1,0,0,sub and 56 or 44),
        BackgroundColor3=C.row,BorderSizePixel=0,ZIndex=4,LayoutOrder=lo or 0,Parent=parent})
    cr(8,row)
    -- left hover accent bar (transparent by default)
    local rowAccent = N("Frame",{
        Size=UDim2.new(0,2,0.55,0), AnchorPoint=Vector2.new(0,0.5),
        Position=UDim2.new(0,0,0.5,0),
        BackgroundColor3=C.white, BackgroundTransparency=1,
        BorderSizePixel=0, ZIndex=6, Parent=row
    })
    cr(1, rowAccent)
    _rowAccents[row] = rowAccent   -- store in module-level table (Roblox Instances don't support custom fields)
    N("TextLabel",{Size=UDim2.new(0.65,0,0,18),Position=UDim2.new(0,14,0,sub and 9 or 13),
        BackgroundTransparency=1,Text=title,TextColor3=C.txt,TextSize=12,
        Font=Enum.Font.SourceSansSemibold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5,Parent=row})
    if sub then
        N("TextLabel",{Size=UDim2.new(0.65,0,0,13),Position=UDim2.new(0,14,0,28),
            BackgroundTransparency=1,Text=sub,TextColor3=C.txtSub,TextSize=9,
            Font=Enum.Font.SourceSans,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5,Parent=row})
    end
    row.MouseEnter:Connect(function()
        twSnap(row, 0.10, {BackgroundColor3=C.rowHov})
        twSnap(rowAccent, 0.10, {BackgroundTransparency=0.5})
    end)
    row.MouseLeave:Connect(function()
        twSnap(row, 0.12, {BackgroundColor3=C.row})
        twSnap(rowAccent, 0.12, {BackgroundTransparency=1})
    end)
    return row
end

-- helper: get accent bar for a row
local function rowAccent(row)
    return _rowAccents[row]
end

-- Status Toggle  (coloured square indicator + iOS pill, for movement features)
local function mkStatusToggle(parent, title, sub, cfgKey, lo, cb)
    local row = mkRow(parent,title,sub,lo)

    -- square status indicator on the left
    local sq = N("Frame",{
        Size=UDim2.new(0,10,0,10),
        AnchorPoint=Vector2.new(0,0.5),
        Position=UDim2.new(0,-2,0.5,0),
        BorderSizePixel=0, ZIndex=6, Parent=row
    })
    cr(2,sq)

    -- iOS toggle on the right
    local track = N("Frame",{Size=UDim2.new(0,44,0,24),AnchorPoint=Vector2.new(1,0.5),
        Position=UDim2.new(1,-14,0.5,0),BorderSizePixel=0,ZIndex=5,Parent=row})
    cr(12,track)
    sk(C.borderLo, 1, track)
    local thumb = N("Frame",{Size=UDim2.new(0,18,0,18),AnchorPoint=Vector2.new(0,0.5),
        Position=UDim2.new(0,3,0.5,0),BackgroundColor3=C.white,BorderSizePixel=0,ZIndex=6,Parent=track})
    cr(9,thumb)

    local function refresh()
        local on = Cfg[cfgKey]
        twSnap(sq,   0.15, {BackgroundColor3 = on and Color3.fromRGB(80,200,120) or Color3.fromRGB(38,38,38)})
        twSnap(track,0.15, {BackgroundColor3 = on and C.togOn or C.togOff})
        twSnap(thumb,0.07, {Size=UDim2.new(0,22,0,18)})
        task.delay(0.07, function()
            twSnap(thumb, 0.14, {
                Size             = UDim2.new(0,18,0,18),
                Position         = on and UDim2.new(0,23,0.5,0) or UDim2.new(0,3,0.5,0),
                BackgroundColor3 = on and C.bg or C.white,
            })
        end)
    end
    -- initial state, no animation
    local on0 = Cfg[cfgKey]
    sq.BackgroundColor3    = on0 and Color3.fromRGB(80,200,120) or Color3.fromRGB(38,38,38)
    track.BackgroundColor3 = on0 and C.togOn or C.togOff
    thumb.Position         = on0 and UDim2.new(0,23,0.5,0) or UDim2.new(0,3,0.5,0)
    thumb.BackgroundColor3 = on0 and C.bg or C.white
    row.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            local ac = rowAccent(row)
            if ac then
                twSnap(ac, 0.04, {BackgroundTransparency=0})
                task.delay(0.12, function() twSnap(ac, 0.14, {BackgroundTransparency=1}) end)
            end
            Cfg[cfgKey]=not Cfg[cfgKey]; refresh(); if cb then cb(Cfg[cfgKey]) end
        end
    end)
    return row
end

-- Toggle  (iOS-style pill with squish animation)
local function mkToggle(parent, title, sub, cfgKey, lo, cb)
    local row = mkRow(parent,title,sub,lo)
    local track = N("Frame",{Size=UDim2.new(0,44,0,24),AnchorPoint=Vector2.new(1,0.5),
        Position=UDim2.new(1,-14,0.5,0),BorderSizePixel=0,ZIndex=5,Parent=row})
    cr(12,track)
    sk(C.borderLo, 1, track)  -- subtle border so track is visible in off state
    local thumb = N("Frame",{Size=UDim2.new(0,18,0,18),AnchorPoint=Vector2.new(0,0.5),
        Position=UDim2.new(0,3,0.5,0),BackgroundColor3=C.white,BorderSizePixel=0,ZIndex=6,Parent=track})
    cr(9,thumb)
    local function refresh(animate)
        local on = Cfg[cfgKey]
        local t  = animate==false and 0 or 0.18
        twSnap(track, t, {BackgroundColor3=on and C.togOn or C.togOff})
        -- squish thumb wide on press, then snap to final position
        twSnap(thumb, 0.07, {Size=UDim2.new(0,22,0,18)})
        task.delay(0.07, function()
            twSnap(thumb, 0.14, {
                Size             = UDim2.new(0,18,0,18),
                Position         = on and UDim2.new(0,23,0.5,0) or UDim2.new(0,3,0.5,0),
                BackgroundColor3 = on and C.bg or C.white,
            })
        end)
    end
    -- initial state, no animation
    local on0 = Cfg[cfgKey]
    track.BackgroundColor3 = on0 and C.togOn or C.togOff
    thumb.Position         = on0 and UDim2.new(0,23,0.5,0) or UDim2.new(0,3,0.5,0)
    thumb.BackgroundColor3 = on0 and C.bg or C.white
    row.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            local ac = rowAccent(row)
            if ac then
                twSnap(ac, 0.04, {BackgroundTransparency=0})
                task.delay(0.12, function() twSnap(ac, 0.14, {BackgroundTransparency=1}) end)
            end
            Cfg[cfgKey]=not Cfg[cfgKey]; refresh(); if cb then cb(Cfg[cfgKey]) end
        end
    end)
    return row
end

-- Slider  (full-width, white knob)
local function mkSlider(parent, title, sub, cfgKey, mn, mx, fmt, lo, cb)
    local row = mkRow(parent,title,sub,lo)
    row.Size = UDim2.new(1,0,0,sub and 68 or 58)

    local valL = N("TextLabel",{Size=UDim2.new(0.3,0,0,18),AnchorPoint=Vector2.new(1,0),
        Position=UDim2.new(1,-14,0,sub and 9 or 13),
        BackgroundTransparency=1,Text="",TextColor3=C.txtSub,TextSize=11,
        Font=Enum.Font.SourceSans,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=5,Parent=row})

    local trackY = sub and 46 or 36
    local tBg = N("Frame",{Size=UDim2.new(1,-28,0,4),Position=UDim2.new(0,14,0,trackY),
        BackgroundColor3=C.sldBg,BorderSizePixel=0,ZIndex=5,Parent=row})
    cr(2,tBg)
    local fill = N("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=C.sldFill,BorderSizePixel=0,ZIndex=6,Parent=tBg})
    cr(2,fill)
    local knob = N("Frame",{Size=UDim2.new(0,14,0,14),AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(0,0,0.5,0),BackgroundColor3=C.white,BorderSizePixel=0,ZIndex=7,Parent=tBg})
    cr(7,knob)

    local function setV(v)
        v=math.clamp(v,mn,mx); Cfg[cfgKey]=v
        local p=(v-mn)/(mx-mn)
        fill.Size=UDim2.new(p,0,1,0); knob.Position=UDim2.new(p,0,0.5,0)
        valL.Text=fmt and string.format(fmt,v) or string.format("%.3g",v)
        if cb then cb(v) end
    end
    setV(Cfg[cfgKey])

    local drag=false
    tBg.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true
            local a=tBg.AbsolutePosition; local s=tBg.AbsoluteSize
            setV(mn+(mx-mn)*math.clamp((i.Position.X-a.X)/s.X,0,1))
        end
    end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local a=tBg.AbsolutePosition; local s=tBg.AbsoluteSize
            setV(mn+(mx-mn)*math.clamp((i.Position.X-a.X)/s.X,0,1))
        end
    end)
    return row
end

-- Dropdown
local function mkDrop(parent, title, sub, opts, cfgKey, lo, cb)
    local row = mkRow(parent,title,sub,lo)
    local pill = N("Frame",{Size=UDim2.new(0,120,0,26),AnchorPoint=Vector2.new(1,0.5),
        Position=UDim2.new(1,-14,0.5,0),BackgroundColor3=C.card,BorderSizePixel=0,ZIndex=5,Parent=row})
    cr(6,pill); sk(C.border,1,pill)
    local pLbl = N("TextLabel",{Size=UDim2.new(1,-18,1,0),Position=UDim2.new(0,8,0,0),
        BackgroundTransparency=1,Text=Cfg[cfgKey] or opts[1],TextColor3=C.txt,TextSize=10,
        Font=Enum.Font.SourceSans,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6,Parent=pill})
    N("TextLabel",{Size=UDim2.new(0,12,1,0),AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-4,0.5,0),
        BackgroundTransparency=1,Text="v",TextColor3=C.txtDim,TextSize=8,Font=Enum.Font.GothamBold,ZIndex=6,Parent=pill})
    local panel,open=nil,false
    local function close() if panel then panel:Destroy();panel=nil end; open=false end
    local function openD()
        if open then close(); return end; open=true
        panel=N("Frame",{Size=UDim2.new(0,120,0,math.min(#opts*28+4,120)),
            AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-14,1,4),
            BackgroundColor3=C.card,BorderSizePixel=0,ZIndex=20,Parent=row})
        cr(6,panel); sk(C.border,1,panel)
        local sc=N("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
            BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=C.borderLo,
            CanvasSize=UDim2.new(0,0,0,#opts*28),ZIndex=20,Parent=panel})
        for i,opt in ipairs(opts) do
            local it=N("TextButton",{Size=UDim2.new(1,0,0,28),Position=UDim2.new(0,0,0,(i-1)*28),
                BackgroundColor3=Cfg[cfgKey]==opt and C.tabSel or C.card,
                BackgroundTransparency=0,BorderSizePixel=0,Text=opt,
                TextColor3=Cfg[cfgKey]==opt and C.white or C.txtSub,
                TextSize=10,Font=Enum.Font.SourceSans,ZIndex=21,Parent=sc})
            pd(10,0,0,0,it)
            it.MouseButton1Click:Connect(function() Cfg[cfgKey]=opt;pLbl.Text=opt;if cb then cb(opt) end;close() end)
            it.MouseEnter:Connect(function() tw(it,0.06,{BackgroundColor3=C.cardHov,TextColor3=C.white}) end)
            it.MouseLeave:Connect(function() tw(it,0.06,{BackgroundColor3=Cfg[cfgKey]==opt and C.tabSel or C.card,TextColor3=Cfg[cfgKey]==opt and C.white or C.txtSub}) end)
        end
    end
    pill.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then openD() end end)
    return row
end

-- Info row (static key=value)
local function mkInfo(parent, title, val, lo)
    local row = mkRow(parent,title,nil,lo)
    N("TextLabel",{Size=UDim2.new(0.4,0,1,0),AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-14,0,0),
        BackgroundTransparency=1,Text=val,TextColor3=C.txtSub,TextSize=11,
        Font=Enum.Font.SourceSans,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=5,Parent=row})
    return row
end

-- Action button row
local function mkButton(parent, title, sub, btnLabel, lo, cb)
    local row = mkRow(parent,title,sub,lo)
    local btn = N("TextButton",{Size=UDim2.new(0,90,0,26),AnchorPoint=Vector2.new(1,0.5),
        Position=UDim2.new(1,-14,0.5,0),BackgroundColor3=C.card,BorderSizePixel=0,
        Text=btnLabel,TextColor3=C.txt,TextSize=10,Font=Enum.Font.SourceSansSemibold,ZIndex=5,Parent=row})
    cr(6,btn); sk(C.border,1,btn)
    btn.MouseButton1Click:Connect(function()
        twFlash(btn,{BackgroundColor3=C.tabSel,TextColor3=C.white},{BackgroundColor3=C.cardHov,TextColor3=C.txt},0.07)
        if cb then cb() end
    end)
    btn.MouseEnter:Connect(function() twSnap(btn,0.09,{BackgroundColor3=C.cardHov}) end)
    btn.MouseLeave:Connect(function() twSnap(btn,0.12,{BackgroundColor3=C.card}) end)
    return row
end

-- Text input row  (for player notes, etc.)
local function mkTextInput(parent, title, sub, placeholder, lo, cb)
    local row = N("Frame",{Size=UDim2.new(1,0,0,sub and 68 or 58),
        BackgroundColor3=C.row,BorderSizePixel=0,ZIndex=4,LayoutOrder=lo or 0,Parent=parent})
    cr(8,row)
    N("TextLabel",{Size=UDim2.new(0.55,0,0,18),Position=UDim2.new(0,14,0,sub and 9 or 8),
        BackgroundTransparency=1,Text=title,TextColor3=C.txt,TextSize=12,
        Font=Enum.Font.SourceSansSemibold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5,Parent=row})
    if sub then
        N("TextLabel",{Size=UDim2.new(0.55,0,0,13),Position=UDim2.new(0,14,0,28),
            BackgroundTransparency=1,Text=sub,TextColor3=C.txtSub,TextSize=9,
            Font=Enum.Font.SourceSans,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5,Parent=row})
    end
    local box = N("TextBox",{
        Size=UDim2.new(1,-28,0,26),Position=UDim2.new(0,14,1,-34),
        BackgroundColor3=C.card,BorderSizePixel=0,
        Text=placeholder or "",PlaceholderText=placeholder or "",
        TextColor3=C.txt,PlaceholderColor3=C.txtDim,
        TextSize=10,Font=Enum.Font.SourceSans,
        TextXAlignment=Enum.TextXAlignment.Left,
        ClearTextOnFocus=false,ZIndex=5,Parent=row})
    cr(5,box); sk(C.border,1,box); pd(8,8,0,0,box)
    box.FocusLost:Connect(function() if cb then cb(box.Text) end end)
    row.MouseEnter:Connect(function() tw(row,0.08,{BackgroundColor3=C.rowHov}) end)
    row.MouseLeave:Connect(function() tw(row,0.08,{BackgroundColor3=C.row}) end)
    return row, box
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
        b.MouseEnter:Connect(function()
            if activeTabName~=td.name then twSnap(b,0.08,{BackgroundColor3=C.tabSel}) end
        end)
        b.MouseLeave:Connect(function()
            if activeTabName~=td.name then twSnap(b,0.10,{BackgroundColor3=C.tab}) end
        end)
        b.MouseButton1Click:Connect(function()
            -- flash the clicked tab
            twFlash(b,{BackgroundColor3=C.white},{BackgroundColor3=C.tabSel},0.05)
            task.delay(0.12,function()
                for _,t in pairs(tabBtns) do
                    twSnap(t.btn,0.12,{BackgroundColor3=C.tab}); t.btn.TextColor3=C.txtSub; t.btn.Font=Enum.Font.SourceSans
                end
                twSnap(b,0.12,{BackgroundColor3=C.tabSel}); b.TextColor3=C.white; b.Font=Enum.Font.SourceSansSemibold
                activeTabName=td.name
                clearRight()
                if td.build then td.build(RightInner) end
            end)
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
    -- left accent bar (hidden when not selected)
    local accent = N("Frame",{Size=UDim2.new(0,2,0.6,0),AnchorPoint=Vector2.new(0,0.5),
        Position=UDim2.new(0,0,0.5,0),BackgroundColor3=C.white,BackgroundTransparency=1,
        BorderSizePixel=0,ZIndex=6,Parent=card})
    cr(1,accent)
    local lbl = N("TextLabel",{Size=UDim2.new(1,0,1,0),Position=UDim2.new(0,14,0,0),
        BackgroundTransparency=1,Text=title,TextColor3=C.txt,TextSize=11,
        Font=Enum.Font.SourceSansSemibold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5,Parent=card})
    card.MouseEnter:Connect(function()
        if activeItem~=title then
            twSnap(card,0.10,{BackgroundColor3=C.cardHov})
            twSnap(lbl, 0.10,{TextColor3=C.white})
        end
    end)
    card.MouseLeave:Connect(function()
        if activeItem~=title then
            twSnap(card,0.12,{BackgroundColor3=C.card})
            twSnap(lbl, 0.12,{TextColor3=C.txt})
            twSnap(accent,0.12,{BackgroundTransparency=1})
        end
    end)
    card.MouseButton1Click:Connect(function()
        if activeItem==title then return end
        -- flash press
        twFlash(card,{BackgroundColor3=C.white},{BackgroundColor3=C.tabSel},0.06)
        task.delay(0.13,function()
            activeItem=title
            for _,c in ipairs(SbInner:GetChildren()) do
                if c:IsA("TextButton") then
                    twSnap(c,0.12,{BackgroundColor3=C.card})
                    -- hide accent on all other cards
                    local ac=c:FindFirstChild("Frame")
                    if ac then twSnap(ac,0.12,{BackgroundTransparency=1}) end
                    -- dim labels
                    local lb=c:FindFirstChildWhichIsA("TextLabel")
                    if lb then twSnap(lb,0.12,{TextColor3=C.txt}) end
                end
            end
            twSnap(card,0.12,{BackgroundColor3=C.tabSel})
            twSnap(accent,0.15,{BackgroundTransparency=0})
            twSnap(lbl,0.12,{TextColor3=C.white})
            onSelect()
        end)
    end)
    return card, lbl
end

-- ════════════════════════════════════════════════════════════
--  PAGE DEFINITIONS
-- ════════════════════════════════════════════════════════════

-- helper: spacer between section groups
local function sp(parent,h,lo)
    N("Frame",{Size=UDim2.new(1,0,0,h),BackgroundTransparency=1,ZIndex=3,LayoutOrder=lo,Parent=parent})
end

------------------------------------------------------------------
--  COMBAT → Aimbot
------------------------------------------------------------------
local function selectAimbot()
    MidTitle.Text="Aim Assistance"
    MidDesc.Text="Improves precision, recoil control, and target tracking"

    buildTabs({
        { name="General", build=function(P)
            secLabel(P,"Master",1)
            mkToggle(P,"Enable Aimbot","Activates aimbot targeting","aimbotEnabled",2)
            secLabel(P,"Filtering",3)
            mkToggle(P,"Team Check","Skip teammates","aimbotTeamCheck",4)
            mkToggle(P,"Visibility Check","Only aim at visible targets","aimbotVisCheck",5)
            mkToggle(P,"Target Lock","Stay locked on current target until lost","aimbotTargetLock",6)
            secLabel(P,"Targeting",7)
            mkDrop(P,"Target Part","Body part to aim at",{"Head","HumanoidRootPart","UpperTorso","Torso"},"aimbotPart",8)
            mkSlider(P,"Field of View","Targeting radius in pixels","aimbotFOV",10,500,"%.0f px",9)
            mkSlider(P,"Smoothness","Lower = snappier  |  Higher = smoother","aimbotSmooth",0.01,1.0,"%.2f",10)
            secLabel(P,"FOV Circle",11)
            mkToggle(P,"Show FOV Circle","Renders aimbot FOV ring on screen","aimbotFOVCircle",12)
        end},
        { name="Prediction", build=function(P)
            secLabel(P,"Velocity Prediction",1)
            mkToggle(P,"Enable Prediction","Lead targets based on velocity","aimbotPrediction",2)
            mkSlider(P,"Prediction Multiplier","Higher = further lead","aimbotPredMult",0.01,1.0,"%.2f",3)
            secLabel(P,"Info",4)
            mkInfo(P,"Projectile Speed","~800 studs/s assumed",5)
            mkInfo(P,"Tip","Raise multiplier if shots fall short",6)
        end},
        { name="Keybind", build=function(P)
            secLabel(P,"Trigger",1)
            mkDrop(P,"Aimbot Key","Key to activate aimbot",{"MouseButton2","E","Q","LeftShift","X","F"},"aimbotKey",2)
            mkToggle(P,"Hold Mode","Hold key to aim, release to stop","aimbotHold",3)
        end},
    })
end

------------------------------------------------------------------
--  COMBAT → Silent Aim
------------------------------------------------------------------
local function selectSilent()
    MidTitle.Text="Silent Aim"
    MidDesc.Text="Redirects bullets to the nearest target without moving camera"

    buildTabs({
        { name="General", build=function(P)
            secLabel(P,"Master",1)
            mkToggle(P,"Enable Silent Aim","Redirects bullets to nearest target","silentEnabled",2)
            secLabel(P,"Filtering",3)
            mkToggle(P,"Team Check","Skip teammates","silentTeamCheck",4)
            mkSlider(P,"FOV","Targeting radius in pixels","silentFOV",10,500,"%.0f px",5)
            secLabel(P,"Targeting",6)
            mkDrop(P,"Target Part","Body part bullets redirect to",{"Head","HumanoidRootPart","UpperTorso","Torso"},"silentPart",7)
        end},
        { name="Hooks", build=function(P)
            secLabel(P,"Ray API Hooks",1)
            mkToggle(P,"Legacy Hitscan","Hook FindPartOnRay (older games)","silentHitscan",2)
            mkToggle(P,"Modern Raycast","Hook Workspace:Raycast (most games)","silentRaycast",3)
            secLabel(P,"Info",4)
            mkInfo(P,"Coverage","Both hooks active = maximum compatibility",5)
        end},
        { name="Keybind", build=function(P)
            secLabel(P,"Trigger",1)
            mkDrop(P,"Silent Aim Key","Key to activate silent aim",{"MouseButton2","E","Q","LeftShift","X","F"},"silentKey",2)
            mkToggle(P,"Hold Mode","Hold key to aim, release to stop","silentHold",3)
            secLabel(P,"Info",4)
            mkInfo(P,"Note","Silent key is independent of aimbot key",5)
        end},
    })
end

------------------------------------------------------------------
--  COMBAT → Anti-Aim + Exploits
------------------------------------------------------------------
local function selectAntiAim()
    MidTitle.Text="Anti-Aim & Exploits"
    MidDesc.Text="Desync, wallbang, hitbox expansion and more"

    buildTabs({
        { name="Anti-Aim", build=function(P)
            secLabel(P,"Rotation Desync",1)
            mkToggle(P,"Enable Anti-Aim","Desync your character rotation","antiAimEnabled",2)
            mkDrop(P,"Mode","Rotation behaviour",{"Spin","Jitter","Static","360"},"antiAimMode",3)
            mkSlider(P,"Speed","Rotation speed multiplier","antiAimSpeed",1,25,"%.0f",4)
        end},
        { name="Wallbang", build=function(P)
            secLabel(P,"Wallbang",1)
            mkToggle(P,"Enable Wallbang","Makes your character non-collidable so bullets/rays pass through walls to hit you","wallbangEnabled",2)
            secLabel(P,"Info",3)
            mkInfo(P,"Effect","Character parts set CanCollide=false",4)
            mkInfo(P,"Note","Also allows walking through thin walls",5)
        end},
        { name="Hitbox", build=function(P)
            secLabel(P,"Hitbox Expander",1)
            mkToggle(P,"Enable Hitbox","Inflates enemy HumanoidRootPart size","hitboxEnabled",2)
            mkSlider(P,"Expand Size","Extra studs added to enemy HRP","hitboxSize",1,20,"%.0f st",3)
            secLabel(P,"Info",4)
            mkInfo(P,"Effect","Larger hitbox = easier to register hits",5)
        end},
        { name="Exploits", build=function(P)
            secLabel(P,"Fake Lag",1)
            mkToggle(P,"Enable Fake Lag","Throttles position updates to desync","fakeLagEnabled",2)
            mkSlider(P,"Strength","Frames skipped per update","fakeLagStrength",1,20,"%.0f",3)
            secLabel(P,"Rapid Fire",4)
            mkToggle(P,"Enable Rapid Fire","Reduces tool activation cooldown to near-zero","rapidFireEnabled",5)
            secLabel(P,"Info",6)
            mkInfo(P,"Note","Rapid Fire works on tools with GripForward trigger",7)
        end},
    })
end

------------------------------------------------------------------
--  VISUALS → ESP
------------------------------------------------------------------
local function selectESP()
    MidTitle.Text="Extra Sensory Perception"
    MidDesc.Text="Draws overlays on players through walls and distance"

    buildTabs({
        { name="General", build=function(P)
            secLabel(P,"Toggle",1)
            mkToggle(P,"Enable ESP","Master switch for all overlays","espEnabled",2)
            secLabel(P,"Overlays",3)
            mkToggle(P,"Bounding Boxes","2D box around players","espBoxes",4)
            mkToggle(P,"Names","Show player name above","espNames",5)
            mkToggle(P,"Health Bar","HP bar beside box","espHealth",6)
            mkToggle(P,"Distance","Stud distance below name","espDistance",7)
            mkToggle(P,"Tracers","Line from screen edge to player","espTracers",8)
            mkToggle(P,"Skeleton","Bone skeleton overlay","espSkeleton",9)
            mkToggle(P,"Team Color","Tint by team color","espTeamColor",10)
            secLabel(P,"Range",11)
            mkSlider(P,"Max Distance","Hide ESP beyond this range","espMaxDist",100,3000,"%.0f",12)
        end},
    })
end

------------------------------------------------------------------
--  VISUALS → Chams
------------------------------------------------------------------
local function selectChams()
    MidTitle.Text="Chams"
    MidDesc.Text="Make player models glow through walls"

    buildTabs({
        { name="General", build=function(P)
            secLabel(P,"Toggle",1)
            mkToggle(P,"Enable Chams","Neon material on enemy models","chamsEnabled",2)
            mkSlider(P,"Transparency","Model see-through amount","chamsTransp",0,0.98,"%.2f",3)
        end},
    })
end

------------------------------------------------------------------
--  VISUALS → Crosshair
------------------------------------------------------------------
local function selectCrosshair()
    MidTitle.Text="Crosshair Overlay"
    MidDesc.Text="Custom crosshair drawn over the screen via Drawing API"

    buildTabs({
        { name="General", build=function(P)
            secLabel(P,"Toggle",1)
            mkToggle(P,"Enable Crosshair","Draw custom crosshair on screen","crosshairEnabled",2)
            secLabel(P,"Style",3)
            mkDrop(P,"Style","Shape of the crosshair",{"Cross","Dot","Circle"},"crosshairStyle",4)
            secLabel(P,"Dimensions",5)
            mkSlider(P,"Size","Length of each arm (Cross) or radius (Circle)","crosshairSize",2,40,"%.0f px",6)
            mkSlider(P,"Gap","Space between centre and arms","crosshairGap",0,20,"%.0f px",7)
            mkSlider(P,"Thickness","Line width","crosshairThick",1,6,"%.0f px",8)
        end},
    })
end

------------------------------------------------------------------
--  MISC → Fly / Speed / Noclip / InfJump / Velocity HUD
------------------------------------------------------------------
local function selectMisc()
    MidTitle.Text="World Manipulation"
    MidDesc.Text="Movement cheats and physics overrides"

    buildTabs({
        { name="Movement", build=function(P)
            secLabel(P,"Fly",1)
            mkStatusToggle(P,"Enable Fly","WASD + Space/Ctrl camera-relative fly","flyEnabled",2)
            mkSlider(P,"Fly Speed","Units per second","flySpeed",5,250,"%.0f",3)
            secLabel(P,"Walk",4)
            mkStatusToggle(P,"Walk Speed Override","Enable custom walk speed","walkSpeedEnabled",5)
            mkSlider(P,"Walk Speed","Base walk speed (default 16)","walkSpeed",2,100,"%.0f",6)
            secLabel(P,"Other",7)
            mkStatusToggle(P,"Noclip","Walk through walls","noclipEnabled",8)
            mkStatusToggle(P,"Infinite Jump","Jump again mid-air","infJumpEnabled",9)
        end},
        { name="Velocity HUD", build=function(P)
            secLabel(P,"Velocity Display",1)
            mkToggle(P,"Enable Velocity HUD","Shows current speed in studs/s on screen","velHudEnabled",2)
            mkInfo(P,"Display","Bottom-center of screen",3)
            mkInfo(P,"Format","XZ speed  |  Y speed",4)
        end},
    })
end

------------------------------------------------------------------
--  MISC → Teleport
------------------------------------------------------------------
local TP_LOCATIONS = {
    { name="Casino",            pos=Vector3.new(-1159, 4, -673) },
    { name="Tacos",             pos=Vector3.new(-1009, 2, -136) },
    { name="Gun Store 1",       pos=Vector3.new(-1183, 2, -452) },
    { name="Pawn Shop",         pos=Vector3.new(-1293, 2, -846) },
    { name="Country Vehicles",  pos=Vector3.new(-1155, 3, -963) },
    { name="Gunpowder",         pos=Vector3.new(-918,  2, -975) },
    { name="Firework Launcher", pos=Vector3.new(-812,  3, -822) },
    { name="Jewelry",           pos=Vector3.new(-627,  3, -643) },
    { name="Gun Store 2",       pos=Vector3.new(-609,  2, -78)  },
    { name="Bank",              pos=Vector3.new(-800,  2, -50)  },
    { name="Luxury Cars",       pos=Vector3.new(-794,  3, -314) },
    { name="Juggernaut",        pos=Vector3.new(-69,   4, -79)  },
}

local function selectTeleport()
    MidTitle.Text="Teleport"
    MidDesc.Text="Instantly move to any location on the map"

    buildTabs({
        { name="Locations", build=function(P)
            secLabel(P,"Locations",1)
            for i, loc in ipairs(TP_LOCATIONS) do
                local row = N("Frame",{
                    Size=UDim2.new(1,0,0,40),
                    BackgroundColor3=C.row, BorderSizePixel=0,
                    ZIndex=4, LayoutOrder=i+1, Parent=P
                })
                cr(8,row)

                -- left accent bar
                local ac = N("Frame",{
                    Size=UDim2.new(0,2,0.55,0), AnchorPoint=Vector2.new(0,0.5),
                    Position=UDim2.new(0,0,0.5,0),
                    BackgroundColor3=C.white, BackgroundTransparency=1,
                    BorderSizePixel=0, ZIndex=6, Parent=row
                })
                cr(1,ac)

                -- name
                N("TextLabel",{
                    Size=UDim2.new(1,-110,1,0), Position=UDim2.new(0,14,0,0),
                    BackgroundTransparency=1, Text=loc.name,
                    TextColor3=C.txt, TextSize=12,
                    Font=Enum.Font.SourceSansSemibold,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    ZIndex=5, Parent=row
                })

                -- teleport button
                local btn = N("TextButton",{
                    Size=UDim2.new(0,70,0,26),
                    AnchorPoint=Vector2.new(1,0.5),
                    Position=UDim2.new(1,-8,0.5,0),
                    BackgroundColor3=C.card, BorderSizePixel=0,
                    Text="Teleport", TextColor3=C.txt,
                    TextSize=10, Font=Enum.Font.SourceSansSemibold,
                    ZIndex=6, Parent=row
                })
                cr(6,btn); sk(C.border,1,btn)

                row.MouseEnter:Connect(function()
                    twSnap(row,0.10,{BackgroundColor3=C.rowHov})
                    twSnap(ac, 0.10,{BackgroundTransparency=0.5})
                end)
                row.MouseLeave:Connect(function()
                    twSnap(row,0.12,{BackgroundColor3=C.row})
                    twSnap(ac, 0.12,{BackgroundTransparency=1})
                end)
                btn.MouseEnter:Connect(function() twSnap(btn,0.08,{BackgroundColor3=C.cardHov}) end)
                btn.MouseLeave:Connect(function() twSnap(btn,0.10,{BackgroundColor3=C.card}) end)

                local tpPos = loc.pos
                btn.MouseButton1Click:Connect(function()
                    twSnap(ac,0.04,{BackgroundTransparency=0})
                    twFlash(btn,
                        {BackgroundColor3=C.white,  TextColor3=C.bg},
                        {BackgroundColor3=C.cardHov, TextColor3=C.txt}, 0.07)
                    task.delay(0.10, function()
                        twSnap(ac,0.14,{BackgroundTransparency=1})
                        pcall(function()
                            local char = LP.Character
                            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                hrp.CFrame = CFrame.new(tpPos.X, tpPos.Y, tpPos.Z)
                            end
                        end)
                    end)
                end)
            end
        end},
    })
end

------------------------------------------------------------------
--  FARMS
------------------------------------------------------------------
local function selectFarms()
    MidTitle.Text="Auto Farms"
    MidDesc.Text="Automatically collect money from various sources"

    buildTabs({
        { name="Farms", build=function(P)
            secLabel(P,"AFK",1)
            mkToggle(P,"Anti-AFK Farm","Hides underground, auto-runs bank/casino/jewelry when ready","antiAfkEnabled",2)
            secLabel(P,"Money",3)
            mkToggle(P,"Bank Farm","Auto-rob the bank repeatedly","bankFarm",4)
            mkToggle(P,"ATM Farm","Holds R at each ATM underground","atmFarm",5)
            mkToggle(P,"Casino Farm","Holds E at each casino spot underground","casinoFarm",6)
            mkToggle(P,"Bins Farm","Holds R at each bin underground","binsFarm",7)
            mkToggle(P,"Jewelry Farm","Holds E at each jewelry display underground","jewelryFarm",8)
            mkToggle(P,"Gunpowder Farm","Auto-collect and sell gunpowder","gunpowderFarm",9)
            secLabel(P,"Settings",10)
            mkSlider(P,"Farm Tween Speed","Studs/s for farm movements (slow start, constant)","farmTweenSpeed",10,50,"%.0f",11)
            mkToggle(P,"Auto Rejoin","Rejoin server on kick and resume farms","autoRejoinEnabled",12)
        end},
    })
end

------------------------------------------------------------------
--  PLAYERS
------------------------------------------------------------------
local function selectPlayers()
    MidTitle.Text="Player Options"
    MidDesc.Text="Interact with online players"

    buildTabs({
        { name="Players", build=function(P)
            -- Stop Spectate button (global, always visible)
            secLabel(P,"Spectate",1)
            local stopRow = N("Frame",{Size=UDim2.new(1,0,0,44),BackgroundColor3=C.row,
                BorderSizePixel=0,ZIndex=4,LayoutOrder=2,Parent=P})
            cr(8,stopRow)
            N("TextLabel",{Size=UDim2.new(0.6,0,1,0),Position=UDim2.new(0,14,0,0),
                BackgroundTransparency=1,Text="Stop Spectating",TextColor3=C.txt,TextSize=12,
                Font=Enum.Font.SourceSansSemibold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5,Parent=stopRow})
            N("TextLabel",{Size=UDim2.new(0.6,0,0,13),Position=UDim2.new(0,14,0,26),
                BackgroundTransparency=1,Text="Return camera to your character",TextColor3=C.txtSub,TextSize=9,
                Font=Enum.Font.SourceSans,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5,Parent=stopRow})
            local stopBtn = N("TextButton",{Size=UDim2.new(0,100,0,26),AnchorPoint=Vector2.new(1,0.5),
                Position=UDim2.new(1,-14,0.5,0),BackgroundColor3=C.card,BorderSizePixel=0,
                Text="Stop Spectate",TextColor3=C.txt,TextSize=10,Font=Enum.Font.SourceSansSemibold,ZIndex=5,Parent=stopRow})
            cr(6,stopBtn); sk(C.border,1,stopBtn)
            stopBtn.MouseButton1Click:Connect(function()
                pcall(function()
                    local char=LP.Character
                    local hum=char and char:FindFirstChildWhichIsA("Humanoid")
                    Camera.CameraSubject=hum or (char and char:FindFirstChild("HumanoidRootPart"))
                end)
            end)
            stopBtn.MouseEnter:Connect(function() tw(stopBtn,0.08,{BackgroundColor3=C.cardHov}) end)
            stopBtn.MouseLeave:Connect(function() tw(stopBtn,0.08,{BackgroundColor3=C.card}) end)
            stopRow.MouseEnter:Connect(function() tw(stopRow,0.08,{BackgroundColor3=C.rowHov}) end)
            stopRow.MouseLeave:Connect(function() tw(stopRow,0.08,{BackgroundColor3=C.row}) end)

            secLabel(P,"Actions",3)
            -- dynamic player list
            local lo=4
            for _,p in ipairs(Players:GetPlayers()) do
                if p==LP then continue end
                -- player action row (expanded height to fit note input)
                local prow = N("Frame",{Size=UDim2.new(1,0,0,80),BackgroundColor3=C.row,
                    BorderSizePixel=0,ZIndex=4,LayoutOrder=lo,Parent=P})
                cr(8,prow)
                N("TextLabel",{Size=UDim2.new(0.45,0,0,20),Position=UDim2.new(0,14,0,6),
                    BackgroundTransparency=1,Text=p.Name,TextColor3=C.txt,TextSize=11,
                    Font=Enum.Font.SourceSansSemibold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5,Parent=prow})

                -- action buttons (top-right)
                local btnFrame = N("Frame",{Size=UDim2.new(0.52,0,0,28),AnchorPoint=Vector2.new(1,0),
                    Position=UDim2.new(1,-8,0,8),BackgroundTransparency=1,ZIndex=5,Parent=prow})
                hl(4,btnFrame)

                local function mkAct(lbText, clr, action)
                    local b = N("TextButton",{Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,
                        BackgroundColor3=clr,BorderSizePixel=0,Text=lbText,TextColor3=C.white,
                        TextSize=9,Font=Enum.Font.SourceSansSemibold,ZIndex=6,Parent=btnFrame})
                    cr(5,b); pd(6,6,0,0,b)
                    -- hover: lighten
                    local hovClr = Color3.new(
                        math.min(clr.R+0.12,1),
                        math.min(clr.G+0.12,1),
                        math.min(clr.B+0.12,1)
                    )
                    b.MouseEnter:Connect(function() twSnap(b,0.08,{BackgroundColor3=hovClr}) end)
                    b.MouseLeave:Connect(function() twSnap(b,0.10,{BackgroundColor3=clr}) end)
                    b.MouseButton1Click:Connect(function()
                        twFlash(b,{BackgroundColor3=C.white},{BackgroundColor3=hovClr},0.06)
                        task.delay(0.13,function() pcall(action) end)
                    end)
                end

                -- Spectate
                mkAct("Spectate",Color3.fromRGB(60,60,70),function()
                    local char=p.Character; if not char then return end
                    local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                    Camera.CameraSubject=char:FindFirstChildWhichIsA("Humanoid") or hrp
                end)
                -- TP to
                mkAct("TP",Color3.fromRGB(40,80,60),function()
                    local char=LP.Character; if not char then return end
                    local lhrp=char:FindFirstChild("HumanoidRootPart"); if not lhrp then return end
                    local thr=p.Character and p.Character:FindFirstChild("HumanoidRootPart"); if not thr then return end
                    lhrp.CFrame=thr.CFrame+Vector3.new(3,0,0)
                end)
                -- Gun Kill
                mkAct("Gun Kill",Color3.fromRGB(100,30,30),function()
                    local hum=p.Character and p.Character:FindFirstChildWhichIsA("Humanoid"); if not hum then return end
                    hum.Health=0
                end)
                -- Fist Kill
                mkAct("Fist Kill",Color3.fromRGB(80,50,20),function()
                    local hum=p.Character and p.Character:FindFirstChildWhichIsA("Humanoid"); if not hum then return end
                    hum:TakeDamage(hum.MaxHealth)
                end)

                -- Note input (bottom of player row)
                local noteBox = N("TextBox",{
                    Size=UDim2.new(1,-28,0,22),Position=UDim2.new(0,14,0,50),
                    BackgroundColor3=C.card,BorderSizePixel=0,
                    Text=Cfg.playerNotes[p.Name] or "",
                    PlaceholderText="Add a note about "..p.Name.."...",
                    TextColor3=C.txt,PlaceholderColor3=C.txtDim,
                    TextSize=9,Font=Enum.Font.SourceSans,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    ClearTextOnFocus=false,ZIndex=5,Parent=prow})
                cr(4,noteBox); sk(C.borderLo,1,noteBox); pd(6,6,0,0,noteBox)
                noteBox.FocusLost:Connect(function()
                    Cfg.playerNotes[p.Name]=noteBox.Text
                end)

                prow.MouseEnter:Connect(function() tw(prow,0.08,{BackgroundColor3=C.rowHov}) end)
                prow.MouseLeave:Connect(function() tw(prow,0.08,{BackgroundColor3=C.row}) end)

                lo=lo+1
            end
            if lo==4 then
                secLabel(P,"No other players online",4)
            end
        end},
    })
end

------------------------------------------------------------------
--  SETTINGS
------------------------------------------------------------------
local function selectSettings()
    MidTitle.Text="Global Settings"
    MidDesc.Text="Keybinds, colors and preferences"

    buildTabs({
        { name="Keybinds", build=function(P)
            secLabel(P,"UI",1)
            mkInfo(P,"Toggle Window","Z key",2)
            secLabel(P,"Combat",3)
            mkDrop(P,"Aimbot Key",nil,{"MouseButton2","E","Q","LeftShift","X"},"aimbotKey",4)
        end},
        { name="Colours", build=function(P)
            secLabel(P,"Accent",1)
            -- color swatch row
            local swrow = N("Frame",{Size=UDim2.new(1,0,0,44),BackgroundColor3=C.row,
                BorderSizePixel=0,ZIndex=4,LayoutOrder=2,Parent=P})
            cr(8,swrow)
            N("TextLabel",{Size=UDim2.new(0.4,0,1,0),Position=UDim2.new(0,14,0,0),
                BackgroundTransparency=1,Text="Accent Color",TextColor3=C.txt,TextSize=12,
                Font=Enum.Font.SourceSansSemibold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5,Parent=swrow})
            local colors={Color3.fromRGB(255,255,255),Color3.fromRGB(220,50,50),Color3.fromRGB(50,150,220),Color3.fromRGB(80,200,120),Color3.fromRGB(200,130,50),Color3.fromRGB(150,80,220)}
            local sw = N("Frame",{Size=UDim2.new(0.55,0,0,26),AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-14,0.5,0),BackgroundTransparency=1,ZIndex=5,Parent=swrow})
            hl(6,sw)
            for _,col in ipairs(colors) do
                local b=N("TextButton",{Size=UDim2.new(0,26,0,26),BackgroundColor3=col,BorderSizePixel=0,Text="",ZIndex=6,Parent=sw})
                cr(5,b)
                b.MouseButton1Click:Connect(function()
                    Cfg.accentColor=col
                    -- update toggle-on color and slider fill live
                    C.togOn=col; C.sldFill=col
                end)
            end
        end},
    })
end

-- ════════════════════════════════════════════════════════════
--  BUILD SIDEBAR GROUPS
-- ════════════════════════════════════════════════════════════
sbGroup("Combat",1)
sbItem("Aim Assistance",2, selectAimbot)
sbItem("Silent Aim",3,     selectSilent)
sbItem("Anti-Aim",4,       selectAntiAim)

sp(SbInner,4,5)
sbGroup("Visuals",6)
sbItem("ESP",7,       selectESP)
sbItem("Chams",8,     selectChams)
sbItem("Crosshair",9, selectCrosshair)

sp(SbInner,4,10)
sbGroup("Misc",11)
sbItem("World Manipulation",12, selectMisc)
sbItem("Teleport",13,           selectTeleport)

sp(SbInner,4,14)
sbGroup("Farms",15)
sbItem("Auto Farms",16,     selectFarms)

sp(SbInner,4,17)
sbGroup("Players",18)
sbItem("Player Actions",19, selectPlayers)

sp(SbInner,4,20)
sbGroup("Settings",21)
sbItem("Global",22,         selectSettings)

-- boot: select first item
selectAimbot()
-- mark Aim Assistance card as active visually
do
    local cards={}
    for _,c in ipairs(SbInner:GetChildren()) do if c:IsA("TextButton") then table.insert(cards,c) end end
    if cards[1] then cards[1].BackgroundColor3=C.tabSel end
    activeItem="Aim Assistance"
end

-- ════════════════════════════════════════════════════════════
--  INTRO ANIMATION  (runs once on load)
-- ════════════════════════════════════════════════════════════
task.spawn(function()
    -- ── stage 1: dual accent lines sweep from both edges inward ──
    tw(AccentTop, 0.55, {Size=UDim2.new(1,0,0,1)})
    tw(AccentBot, 0.55, {Size=UDim2.new(1,0,0,1)})
    task.wait(0.60)

    -- ── stage 2: logo slides up AND fades in (must be two separate tweens) ──
    SplashLogo.Position        = UDim2.new(0,0,0,28)
    SplashLogo.TextTransparency = 1
    -- position tween
    TweenService:Create(SplashLogo,
        TweenInfo.new(0.50, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Position = UDim2.new(0,0,0,10)}
    ):Play()
    -- transparency tween (separate — Roblox can't batch Position + TextTransparency)
    TweenService:Create(SplashLogo,
        TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 0}
    ):Play()
    task.wait(0.35)

    -- ── stage 3: divider line expands from centre ──
    tw(SplashDiv, 0.35, {Size=UDim2.new(0,300,0,1)})
    task.wait(0.20)

    -- ── stage 4: subtitle + bar label fade in ──
    tw(SplashSub,  0.30, {TextTransparency=0})
    tw(BarLabel,   0.30, {TextTransparency=0})
    task.wait(0.40)

    -- ── stage 5: step loading bar with status text ──
    -- BarDot lives inside BarFill; keep it pinned at the right edge of the fill
    -- by tweening its Position to (1,0, 0.5,0) each step (right edge, centered Y)
    local steps = {
        { t="initializing...",    p=0.20 },
        { t="loading modules...", p=0.50 },
        { t="building ui...",     p=0.75 },
        { t="connecting...",      p=0.90 },
        { t="ready",              p=1.00 },
    }
    for _, s in ipairs(steps) do
        BarLabel.Text = s.t
        tw(BarFill, 0.28, {Size=UDim2.new(s.p, 0, 1, 0)})
        -- dot stays at right edge of the fill bar, vertically centred
        BarDot.Position = UDim2.new(1, 0, 0.5, 0)
        task.wait(0.38)
    end
    task.wait(0.10)

    -- ── stage 6: flash dot white → dim ──
    tw(BarDot, 0.10, {BackgroundColor3=Color3.fromRGB(255,255,255)})
    task.wait(0.12)
    tw(BarDot, 0.20, {BackgroundColor3=Color3.fromRGB(80,80,80)})
    task.wait(0.28)

    -- ── stage 7: fade all splash content out ──
    tw(SplashLogo, 0.25, {TextTransparency=1})
    tw(SplashSub,  0.25, {TextTransparency=1})
    tw(SplashDiv,  0.25, {BackgroundTransparency=1})
    tw(BarFill,    0.25, {BackgroundTransparency=1})
    tw(BarTrack,   0.25, {BackgroundTransparency=1})
    tw(BarLabel,   0.25, {TextTransparency=1})
    tw(BarDot,     0.25, {BackgroundTransparency=1})
    tw(AccentTop,  0.25, {BackgroundTransparency=1})
    tw(AccentBot,  0.25, {BackgroundTransparency=1})
    task.wait(0.30)

    -- ── stage 8: splash collapses to a horizontal line ──
    tw(Splash, 0.28, {
        Size                   = UDim2.new(0, WIN_W, 0, 2),
        BackgroundTransparency = 1,
    })
    task.wait(0.30)

    -- ── stage 9: main window expands from the line ──
    -- Make sure window is fully opaque before revealing
    Win.BackgroundTransparency = 0
    Win.Size                   = UDim2.new(0, WIN_W, 0, 2)
    Win.AnchorPoint            = Vector2.new(0.5, 0.5)
    Win.Position               = UDim2.new(0.5, 0, 0.5, 0)
    Win.Visible                = true
    TweenService:Create(Win,
        TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, WIN_W, 0, WIN_H)}
    ):Play()
    task.wait(0.50)

    Splash:Destroy()
end)

-- ════════════════════════════════════════════════════════════
--  FOV CIRCLE
-- ════════════════════════════════════════════════════════════
local fovCircle
if Drawing then
    fovCircle=Drawing.new("Circle")
    fovCircle.Visible=false; fovCircle.Thickness=1; fovCircle.Filled=false
    fovCircle.Color=Color3.fromRGB(255,255,255); fovCircle.NumSides=64
end
RunService.RenderStepped:Connect(function()
    if fovCircle then
        fovCircle.Visible=Cfg.aimbotFOVCircle and Cfg.aimbotEnabled
        if fovCircle.Visible then
            local vp=Camera.ViewportSize
            fovCircle.Position=Vector2.new(vp.X/2,vp.Y/2)
            fovCircle.Radius=Cfg.aimbotFOV
        end
    end
end)

-- ════════════════════════════════════════════════════════════
--  ESP
-- ════════════════════════════════════════════════════════════
-- skeleton bone pairs (HRP-relative joint names)
local SK_BONES = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}

local espD={}
local function clearESP(p)
    if not espD[p] then return end
    for _,d in pairs(espD[p]) do pcall(function() d:Remove() end) end
    espD[p]=nil
end
local function makeESP(p)
    if not Drawing then return end
    clearESP(p)
    local d={}
    d.box=Drawing.new("Square"); d.box.Visible=false; d.box.Thickness=1; d.box.Filled=false
    d.nm=Drawing.new("Text");   d.nm.Visible=false;  d.nm.Size=13; d.nm.Center=true; d.nm.Outline=true
    d.tr=Drawing.new("Line");   d.tr.Visible=false;  d.tr.Thickness=1
    d.hbg=Drawing.new("Square");d.hbg.Visible=false; d.hbg.Filled=true; d.hbg.Color=Color3.fromRGB(20,20,20)
    d.hfl=Drawing.new("Square");d.hfl.Visible=false; d.hfl.Filled=true
    -- skeleton lines
    d.sk={}
    for i=1,#SK_BONES do
        local l=Drawing.new("Line"); l.Visible=false; l.Thickness=1; l.Color=Color3.fromRGB(255,255,255)
        d.sk[i]=l
    end
    espD[p]=d
end

local espUpdateTimer = 0
RunService.RenderStepped:Connect(function(dt)
    espUpdateTimer = espUpdateTimer + dt
    if espUpdateTimer >= 0.1 then
        espUpdateTimer = 0
        if not Drawing then return end
        for _,p in ipairs(Players:GetPlayers()) do
            if p==LP then continue end
            local d=espD[p]; if not d then makeESP(p); d=espD[p] end; if not d then continue end
            local char=p.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart")
            local hum=char and char:FindFirstChildWhichIsA("Humanoid")
            if not hrp or not Cfg.espEnabled then
                for _,v in pairs(d) do
                    if type(v)=="table" then for _,l in pairs(v) do l.Visible=false end
                    else v.Visible=false end
                end
                continue
            end
            local dist=(Camera.CFrame.Position-hrp.Position).Magnitude
            if dist>Cfg.espMaxDist then
                for _,v in pairs(d) do
                    if type(v)=="table" then for _,l in pairs(v) do l.Visible=false end
                    else v.Visible=false end
                end
                continue
            end
            local sp,onS=Camera:WorldToViewportPoint(hrp.Position)
            if not onS then
                for _,v in pairs(d) do
                    if type(v)=="table" then for _,l in pairs(v) do l.Visible=false end
                    else v.Visible=false end
                end
                continue
            end
            local hp2=Camera:WorldToViewportPoint(hrp.Position+Vector3.new(0,3,0))
            local fp2=Camera:WorldToViewportPoint(hrp.Position+Vector3.new(0,-3,0))
            local bH=math.abs(hp2.Y-fp2.Y); local bW=bH*0.55
            local bx=sp.X-bW/2; local by=hp2.Y
            local bc=Cfg.espTeamColor and p.Team and p.TeamColor.Color or Color3.fromRGB(255,255,255)
            d.box.Visible=Cfg.espBoxes
            if Cfg.espBoxes then d.box.Position=Vector2.new(bx,by);d.box.Size=Vector2.new(bW,bH);d.box.Color=bc end
            d.nm.Visible=Cfg.espNames
            if Cfg.espNames then d.nm.Text=p.Name..(Cfg.espDistance and (" "..math.floor(dist).."m") or "");d.nm.Position=Vector2.new(sp.X,by-16);d.nm.Color=bc end
            d.tr.Visible=Cfg.espTracers
            if Cfg.espTracers then local vp=Camera.ViewportSize;d.tr.From=Vector2.new(vp.X/2,vp.Y);d.tr.To=Vector2.new(sp.X,sp.Y);d.tr.Color=bc end
            local hp=hum and hum.Health or 0; local mhp=hum and hum.MaxHealth or 100; local pct=math.clamp(hp/math.max(mhp,1),0,1)
            d.hbg.Visible=Cfg.espHealth; d.hfl.Visible=Cfg.espHealth
            if Cfg.espHealth then
                local bh2=bH*pct; d.hbg.Position=Vector2.new(bx-6,by); d.hbg.Size=Vector2.new(3,bH)
                d.hfl.Position=Vector2.new(bx-6,by+bH-bh2); d.hfl.Size=Vector2.new(3,bh2)
                d.hfl.Color=Color3.fromHSV(pct*0.33,0.9,0.85)
            end
            -- skeleton
            for i,pair in ipairs(SK_BONES) do
                local l=d.sk[i]
                if not Cfg.espSkeleton then l.Visible=false; continue end
                local p1=char:FindFirstChild(pair[1]); local p2=char:FindFirstChild(pair[2])
                if p1 and p2 then
                    local s1,o1=Camera:WorldToViewportPoint(p1.Position)
                    local s2,o2=Camera:WorldToViewportPoint(p2.Position)
                    if o1 and o2 then
                        l.From=Vector2.new(s1.X,s1.Y); l.To=Vector2.new(s2.X,s2.Y)
                        l.Color=bc; l.Visible=true
                    else l.Visible=false end
                else l.Visible=false end
            end
        end
    end
end)

Players.PlayerRemoving:Connect(clearESP); Players.PlayerAdded:Connect(makeESP)
for _,p in ipairs(Players:GetPlayers()) do if p~=LP then makeESP(p) end end

-- ════════════════════════════════════════════════════════════
--  CHAMS
-- ════════════════════════════════════════════════════════════
local chamO={}
local function applyChams(p)
    local char=p.Character; if not char then return end
    for _,pt in ipairs(char:GetDescendants()) do
        if pt:IsA("BasePart") and pt.Name~="HumanoidRootPart" then
            if not chamO[pt] then chamO[pt]={Color=pt.Color,Material=pt.Material,Transparency=pt.Transparency} end
            pt.Color=Color3.fromRGB(220,50,50); pt.Material=Enum.Material.Neon; pt.Transparency=Cfg.chamsTransp
        end
    end
end
local function removeChams(p)
    if not p.Character then return end
    for _,pt in ipairs(p.Character:GetDescendants()) do
        if pt:IsA("BasePart") and chamO[pt] then
            local o=chamO[pt]; pcall(function() pt.Color=o.Color;pt.Material=o.Material;pt.Transparency=o.Transparency end); chamO[pt]=nil
        end
    end
end
local function refreshChams()
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP then if Cfg.chamsEnabled then applyChams(p) else removeChams(p) end end end
end
for _,p in ipairs(Players:GetPlayers()) do if p~=LP then p.CharacterAdded:Connect(function() task.wait(0.2); if Cfg.chamsEnabled then applyChams(p) end end) end end
Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function() task.wait(0.2); if Cfg.chamsEnabled then applyChams(p) end end) end)

-- ════════════════════════════════════════════════════════════
--  AIMBOT  (prediction + smooth + target-lock)
-- ════════════════════════════════════════════════════════════

-- Shared raycast params (ignore local character + ignore terrain for vis check)
local _abParams = RaycastParams.new()
_abParams.FilterType = Enum.RaycastFilterType.Exclude
_abParams.FilterDescendantsInstances = {}

local function _abRefreshParams()
    if LP.Character then _abParams.FilterDescendantsInstances = {LP.Character} end
end
LP.CharacterAdded:Connect(_abRefreshParams)
_abRefreshParams()

-- Delta-time corrected smooth factor
local function smoothFactor(smooth, dt)
    return 1 - (1 - smooth) ^ (dt * 60)
end

-- Velocity-lead prediction (dt-based, not hardcoded *60)
local function predictPos(hrp, part, dt)
    if not Cfg.aimbotPrediction then return part.Position end
    local vel  = hrp.AssemblyLinearVelocity
    local dist = (Camera.CFrame.Position - part.Position).Magnitude
    -- lead = velocity * travel_time_estimate * user_multiplier
    local travelTime = dist / 800   -- assumes ~800 stud/s projectile speed
    return part.Position + vel * travelTime * Cfg.aimbotPredMult * 8
end

-- Visibility check using modern Workspace:Raycast()
local function isVisible(origin, target, targetChar)
    local dir = (target - origin)
    local result = Workspace:Raycast(origin, dir, _abParams)
    if not result then return true end  -- nothing hit → clear
    -- hit something that belongs to the target character → still visible
    return targetChar:IsAncestorOf(result.Instance)
end

-- Locked-on target (for target-lock mode)
local _lockTarget = nil   -- Player | nil

local function clearLock() _lockTarget = nil end
Players.PlayerRemoving:Connect(clearLock)

local function isTargetValid(p)
    if not p or not p.Parent then return false end
    if Cfg.aimbotTeamCheck and LP.Team and p.Team == LP.Team then return false end
    local char = p.Character; if not char then return false end
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildWhichIsA("Humanoid")
    return hrp and hum and hum.Health > 0
end

local function getAimTarget(dt)
    local ctr = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    -- if lock is on and the locked target is still valid + in FOV, keep it
    if Cfg.aimbotTargetLock and _lockTarget and isTargetValid(_lockTarget) then
        local char = _lockTarget.Character
        local hrp  = char:FindFirstChild("HumanoidRootPart")
        local part = char:FindFirstChild(Cfg.aimbotPart) or hrp
        local wpos = predictPos(hrp, part, dt)
        local sp, onS = Camera:WorldToViewportPoint(wpos)
        if onS then
            local d = (Vector2.new(sp.X, sp.Y) - ctr).Magnitude
            if d < Cfg.aimbotFOV then
                if not Cfg.aimbotVisCheck or isVisible(Camera.CFrame.Position, wpos, char) then
                    return { wpos = wpos, player = _lockTarget }
                end
            end
        end
        -- fell out of FOV or LoS — release lock
        _lockTarget = nil
    end

    -- scan for best candidate
    local best = math.huge
    local tgt  = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        if not isTargetValid(p) then continue end
        local char = p.Character
        local hrp  = char:FindFirstChild("HumanoidRootPart")
        local part = char:FindFirstChild(Cfg.aimbotPart) or hrp
        local wpos = predictPos(hrp, part, dt)
        local sp, onS = Camera:WorldToViewportPoint(wpos)
        if not onS then continue end
        local d = (Vector2.new(sp.X, sp.Y) - ctr).Magnitude
        if d >= Cfg.aimbotFOV or d >= best then continue end
        if Cfg.aimbotVisCheck and not isVisible(Camera.CFrame.Position, wpos, char) then continue end
        best = d
        tgt  = { wpos = wpos, player = p }
    end

    if tgt and Cfg.aimbotTargetLock then _lockTarget = tgt.player end
    return tgt
end

-- ════════════════════════════════════════════════════════════
--  SILENT AIM  (legacy ray hook + modern Raycast hook)
-- ════════════════════════════════════════════════════════════

-- Separate hold-state for silent aim key
local _saDown = false

local function isSilentActive()
    if Cfg.silentHold then return _saDown else return Cfg.silentEnabled end
end

local function getSilentTarget()
    if not Cfg.silentEnabled then return nil end
    local best = math.huge
    local tgt  = nil
    local ctr  = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        if Cfg.silentTeamCheck and LP.Team and p.Team == LP.Team then continue end
        local char = p.Character; if not char then continue end
        local hrp  = char:FindFirstChild("HumanoidRootPart")
        local hum  = char:FindFirstChildWhichIsA("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then continue end
        -- aim at configured body part (Head by default)
        local part = char:FindFirstChild(Cfg.silentPart) or hrp
        local sp, onS = Camera:WorldToViewportPoint(part.Position)
        if not onS then continue end
        local d = (Vector2.new(sp.X, sp.Y) - ctr).Magnitude
        if d < Cfg.silentFOV and d < best then best = d; tgt = part end
    end
    return tgt
end

-- Hold-key tracking for both aimbot and silent aim
local abDown = false
local function isAbDown()
    if Cfg.aimbotHold then return abDown else return Cfg.aimbotEnabled end
end

local function _isKeyMatch(i, key)
    if key == "MouseButton2" then
        return i.UserInputType == Enum.UserInputType.MouseButton2
    else
        return i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode.Name == key
    end
end

UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if _isKeyMatch(i, Cfg.aimbotKey)  then abDown  = true end
    if _isKeyMatch(i, Cfg.silentKey)  then _saDown = true end
end)
UserInputService.InputEnded:Connect(function(i)
    if _isKeyMatch(i, Cfg.aimbotKey)  then abDown  = false end
    if _isKeyMatch(i, Cfg.silentKey)  then _saDown = false end
end)

-- Silent aim hook — covers legacy Ray API + modern Raycast API
do
    local mt = getrawmetatable and getrawmetatable(game)
    if mt then
        local old = mt.__namecall
        local ro  = setreadonly or function() end
        ro(mt, false)
        mt.__namecall = function(self, ...)
            local m = getnamecallmethod and getnamecallmethod()
            if isSilentActive() then
                -- legacy: FindPartOnRay / FindPartOnRayWithWhitelist / FindPartOnRayWithIgnoreList
                if Cfg.silentHitscan and (
                    m == "FindPartOnRay" or
                    m == "FindPartOnRayWithWhitelist" or
                    m == "FindPartOnRayWithIgnoreList"
                ) then
                    local part = getSilentTarget()
                    if part then
                        local args = {...}
                        local ray  = args[1]
                        if ray and typeof(ray) == "Ray" then
                            args[1] = Ray.new(ray.Origin,
                                (part.Position - ray.Origin).Unit * ray.Direction.Magnitude)
                        end
                        return old(self, table.unpack(args))
                    end
                end
                -- modern: Workspace:Raycast(origin, direction, params?)
                if Cfg.silentRaycast and m == "Raycast" and self == Workspace then
                    local part = getSilentTarget()
                    if part then
                        local args   = {...}
                        local origin = args[1]
                        local dir    = args[2]
                        if origin and dir then
                            local mag  = dir.Magnitude
                            args[2]    = (part.Position - origin).Unit * mag
                        end
                        return old(self, table.unpack(args))
                    end
                end
            end
            return old(self, ...)
        end
        ro(mt, true)
    end
end

RunService.RenderStepped:Connect(function(dt)
    if Cfg.aimbotEnabled and isAbDown() then
        local t = getAimTarget(dt)
        if t then
            local goal   = CFrame.new(Camera.CFrame.Position, t.wpos)
            local factor = smoothFactor(Cfg.aimbotSmooth, dt)
            Camera.CFrame = Camera.CFrame:Lerp(goal, factor)
        end
    end
end)

-- ════════════════════════════════════════════════════════════
--  HEARTBEAT  (anti-aim, wallbang, hitbox, fake lag, rapid fire, walkspeed, chams)
-- ════════════════════════════════════════════════════════════
local aaAngle    = 0
local _flFrame   = 0          -- fake lag frame counter
local _origHrpSizes = {}      -- original HRP sizes for hitbox restore
local _prevHitbox   = false

-- restore expanded hitboxes when feature is toggled off
local function restoreHitboxes()
    for p, sz in pairs(_origHrpSizes) do
        pcall(function()
            local char = p.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.Size = sz end
            end
        end)
        _origHrpSizes[p] = nil
    end
end

RunService.Heartbeat:Connect(function(dt)
    if Cfg.antiAimEnabled then
        local char = LP.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            if Cfg.antiAimMode == "Spin" then
                aaAngle = (aaAngle + Cfg.antiAimSpeed) % 360
                hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(aaAngle), 0)
            elseif Cfg.antiAimMode == "Jitter" then
                hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad((math.random(0,1)==0 and 1 or -1)*90), 0)
            elseif Cfg.antiAimMode == "Static" then
                hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(180), 0)
            elseif Cfg.antiAimMode == "360" then
                aaAngle = (aaAngle + Cfg.antiAimSpeed * 2) % 360
                hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(aaAngle), math.rad(45))
            end
        end
    end

    if Cfg.wallbangEnabled then
        -- make every player's character parts non-collidable so bullets pass through
        for _, p in ipairs(Players:GetPlayers()) do
            pcall(function()
                local char = p.Character
                if not char then return end
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end)
        end
        -- also disable local character collisions
        pcall(function()
            local char = LP.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    end

    if Cfg.hitboxEnabled then
        _prevHitbox = true
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP then continue end
            pcall(function()
                local char = p.Character
                if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                if not _origHrpSizes[p] then
                    _origHrpSizes[p] = hrp.Size
                end
                hrp.Size = Vector3.new(Cfg.hitboxSize, Cfg.hitboxSize, Cfg.hitboxSize)
            end)
        end
    elseif _prevHitbox then
        _prevHitbox = false
        restoreHitboxes()
    end

    if Cfg.fakeLagEnabled and not Cfg.antiAimEnabled then
        _flFrame = _flFrame + 1
        if _flFrame >= Cfg.fakeLagStrength then
            _flFrame = 0
        else
            local char = LP.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Anchored = true
                task.defer(function() pcall(function() hrp.Anchored = false end) end)
            end
        end
    end

    if Cfg.rapidFireEnabled then
        local char = LP.Character
        if char then
            for _, tool in ipairs(char:GetChildren()) do
                if tool:IsA("Tool") then
                    pcall(function() tool.ManualActivationOnly = false end)
                    local function applyRapidFire(v)
                        if not (v:IsA("NumberValue") or v:IsA("IntValue")) then return end
                        local n = v.Name:lower()
                        -- only target fire-timing values — never damage, health, ammo, range, force, speed, power
                        local isTimingValue =
                            n == "cooldown"   or n == "firerate"  or n == "firedelay"  or
                            n == "shootdelay" or n == "debounce"  or n == "interval"   or
                            n == "waittime"   or n == "rate"      or n == "reloadtime" or
                            n == "shotdelay"  or n == "firecooldown"
                        local isSafeToZero = not (
                            n:find("damage")  or n:find("dmg")     or n:find("health") or
                            n:find("ammo")    or n:find("bullet")  or n:find("range")  or
                            n:find("force")   or n:find("speed")   or n:find("power")  or
                            n:find("pellet")  or n:find("spread")  or n:find("recoil") or
                            n:find("clip")    or n:find("magazine") or n:find("mag")
                        )
                        if isTimingValue and isSafeToZero then
                            if v.Value > 0 then v.Value = 0 end
                        end
                    end
                    for _, v in ipairs(tool:GetDescendants()) do
                        pcall(applyRapidFire, v)
                        if v:IsA("Configuration") then
                            for _, cv in ipairs(v:GetChildren()) do
                                pcall(applyRapidFire, cv)
                            end
                        end
                    end
                end
            end
        end
    end

    do
        local char = LP.Character
        if char then
            local hum = char:FindFirstChildWhichIsA("Humanoid")
            if hum then hum.WalkSpeed = Cfg.walkSpeedEnabled and Cfg.walkSpeed or 16 end
        end
    end

    pcall(refreshChams)
end)

-- restore hitboxes on character respawn to avoid floating ghost sizes
LP.CharacterAdded:Connect(function()
    _origHrpSizes = {}
end)

-- ════════════════════════════════════════════════════════════
--  FLY
-- ════════════════════════════════════════════════════════════
local flyConn,prevFly=nil,false
local function startFly()
    local char=LP.Character; if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local hum=char:FindFirstChildWhichIsA("Humanoid"); if not hum then return end
    hum.PlatformStand=true
    local bg=Instance.new("BodyGyro"); bg.MaxTorque=Vector3.new(1e9,1e9,1e9); bg.D=120; bg.Parent=hrp
    local bv=Instance.new("BodyVelocity"); bv.MaxForce=Vector3.new(1e9,1e9,1e9); bv.Parent=hrp
    flyConn=RunService.Heartbeat:Connect(function()
        if not Cfg.flyEnabled then
            pcall(function() bg:Destroy();bv:Destroy();hum.PlatformStand=false end)
            flyConn:Disconnect(); flyConn=nil; return
        end
        local cf=Camera.CFrame; local v=Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then v=v+cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then v=v-cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then v=v-cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then v=v+cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then v=v+Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then v=v-Vector3.new(0,1,0) end
        bv.Velocity=v.Magnitude>0 and v.Unit*Cfg.flySpeed or Vector3.zero
        bg.CFrame=cf
    end)
end
local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn=nil end
    local char=LP.Character; if not char then return end
    for _,d in ipairs(char:GetDescendants()) do if d:IsA("BodyGyro") or d:IsA("BodyVelocity") then d:Destroy() end end
    local hum=char:FindFirstChildWhichIsA("Humanoid"); if hum then hum.PlatformStand=false end
end
RunService.Heartbeat:Connect(function()
    if Cfg.flyEnabled~=prevFly then prevFly=Cfg.flyEnabled; if Cfg.flyEnabled then startFly() else stopFly() end end
end)
LP.CharacterAdded:Connect(function() task.wait(0.3); if Cfg.flyEnabled then startFly() end end)

-- ════════════════════════════════════════════════════════════
--  NOCLIP
-- ════════════════════════════════════════════════════════════
RunService.Stepped:Connect(function()
    if Cfg.noclipEnabled and not Cfg.wallbangEnabled then
        local char=LP.Character; if not char then return end
        for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
    end
end)

-- ════════════════════════════════════════════════════════════
--  INFINITE JUMP
-- ════════════════════════════════════════════════════════════
UserInputService.JumpRequest:Connect(function()
    if Cfg.infJumpEnabled then
        local char=LP.Character; if not char then return end
        local hum=char:FindFirstChildWhichIsA("Humanoid"); if not hum then return end
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ════════════════════════════════════════════════════════════
--  KEY HELPERS
-- ════════════════════════════════════════════════════════════
-- Try every known executor key API so it works across Synapse, KRNL, Fluxus, etc.
local VIM = nil
pcall(function() VIM = game:GetService("VirtualInputManager") end)

local function pressKey(keyCode)
    if VIM then pcall(function() VIM:SendKeyEvent(true,  keyCode, false, game) end) end
    pcall(function() keypress(keyCode) end)
end
local function releaseKey(keyCode)
    if VIM then pcall(function() VIM:SendKeyEvent(false, keyCode, false, game) end) end
    pcall(function() keyrelease(keyCode) end)
end

local KEY_R      = Enum.KeyCode.R.Value          -- 0x52
local KEY_E      = Enum.KeyCode.E.Value          -- 0x45
local KEY_ESC    = Enum.KeyCode.Escape.Value     -- 0x1B
local KEY_RETURN = Enum.KeyCode.Return.Value     -- 0x0D
local KEY_LSHIFT = Enum.KeyCode.LeftShift.Value  -- 0xA0

local function holdR(seconds)
    pressKey(KEY_R)
    task.wait(seconds)
    releaseKey(KEY_R)
end

local function holdE(seconds)
    -- spam E clicks every 0.08 s for the full duration
    local elapsed = 0
    while elapsed < seconds do
        pressKey(KEY_E)
        task.wait(0.04)
        releaseKey(KEY_E)
        task.wait(0.04)
        elapsed = elapsed + 0.08
    end
end

local function holdEContinuous(seconds)
    -- press and hold E for the full duration, then release once
    pressKey(KEY_E)
    task.wait(seconds)
    releaseKey(KEY_E)
end

-- helper: reset character via Esc → R → Shift (fast in-game menu reset)
local function resetAndWait()
    local oldChar = LP.Character

    -- Esc to open menu
    pressKey(KEY_ESC)
    task.wait(0.08)
    releaseKey(KEY_ESC)
    task.wait(0.2)   -- menu open

    -- R to highlight Reset Character
    pressKey(KEY_R)
    task.wait(0.08)
    releaseKey(KEY_R)
    task.wait(0.15)  -- confirmation prompt

    -- Shift to confirm instantly
    pressKey(KEY_LSHIFT)
    task.wait(0.08)
    releaseKey(KEY_LSHIFT)
    -- also hit Enter as fallback in case Shift didn't work
    task.wait(0.05)
    pressKey(KEY_RETURN)
    task.wait(0.08)
    releaseKey(KEY_RETURN)

    -- wait for new character to load (up to 8 s)
    local t = 0
    repeat
        task.wait(0.1); t = t + 0.1
    until (LP.Character and LP.Character ~= oldChar and LP.Character:FindFirstChild("HumanoidRootPart")) or t > 8
    task.wait(0.5) -- settle before next TP
end

-- ════════════════════════════════════════════════════════════
--  TWEEN TO POS HELPER (for farms)
-- ════════════════════════════════════════════════════════════
local function tweenToPos(hrp, targetPos, speed)
    speed = speed or Cfg.farmTweenSpeed
    local dist = (hrp.Position - targetPos).Magnitude
    local duration = math.max(dist / speed, 0.05)
    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        { CFrame = CFrame.new(targetPos) * hrp.CFrame.Rotation }
    )
    tween:Play()
    tween.Completed:Wait()
end

-- ════════════════════════════════════════════════════════════
--  BANK FARM
-- ════════════════════════════════════════════════════════════

local HOTEL_POS = Vector3.new(-574, 6, 120)

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

-- shared toast notification
local function nyraNotify(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title    = title,
            Text     = text,
            Duration = duration or 6,
        })
    end)
end

-- read robbery readiness from game.Workspace.Buttons.StartRobbery.Head children
local function robberyReady(childName)
    local ok, result = pcall(function()
        local head = Workspace.Buttons.StartRobbery.Head
        -- try exact name first, then case-insensitive fallback
        local part = head:FindFirstChild(childName)
        if not part then
            local lower = childName:lower()
            for _, c in ipairs(head:GetChildren()) do
                if c.Name:lower() == lower then part = c; break end
            end
        end
        if not part then return true end  -- can't find button, assume open so farm doesn't hang
        return part.BrickColor ~= BrickColor.new("Bright red")
    end)
    return ok and result
end

local function bankIsOpen()
    return robberyReady("Bank")
end

-- deliver to hotel: TP there, spam E for 5 s, then reset character
local function deliverAndReset()
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(HOTEL_POS.X, HOTEL_POS.Y, HOTEL_POS.Z)
        task.wait(0.5)
        holdE(5.0)   -- spam E to deliver/collect at hotel
        task.wait(0.3)
    end
    resetAndWait()
end

local function runBankLoop()
    while Cfg.bankFarm do
        -- wait for bank to be open
        local notifiedBank = false
        while Cfg.bankFarm and not bankIsOpen() do
            if not notifiedBank then
                nyraNotify("Bank Locked", "Bank robbery isn't ready yet - keep the farm on, it'll kick in the second it opens!", 8)
                notifiedBank = true
            end
            task.wait(1.0)
        end
        if not Cfg.bankFarm then break end

        -- flatten all wave coords into one list
        local allCoords = {}
        for _, wave in ipairs(BANK_WAVES) do
            for _, pos in ipairs(wave) do
                table.insert(allCoords, pos)
            end
        end

        -- TP to first coord, then tween the rest
        local count = 0
        for i, pos in ipairs(allCoords) do
            if not Cfg.bankFarm then break end
            local char = LP.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(1.0); continue end

            if i == 1 then
                hrp.CFrame = CFrame.new(pos.X, pos.Y, pos.Z)
                task.wait(0.2)
            else
                tweenToPos(hrp, pos)
            end
            task.wait(0.15)
            holdE(1.5)   -- pick up cash bag
            task.wait(0.2)
            count = count + 1

            if count % 8 == 0 then
                if not Cfg.bankFarm then break end
                deliverAndReset()
            end
        end

        if not Cfg.bankFarm then break end
        -- deliver remainder if not on exact 8 boundary
        deliverAndReset()
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

-- Jewelry display coords — every case inside the jewelry store
local JEWELRY_COORDS = {
    -- left wing cases
    Vector3.new(-607, 3, -625),
    Vector3.new(-607, 3, -633),
    Vector3.new(-596, 3, -625),
    Vector3.new(-596, 3, -633),
    Vector3.new(-585, 3, -647),
    Vector3.new(-584, 3, -612),
    Vector3.new(-585, 3, -604),
    -- centre aisle cases
    Vector3.new(-622, 3, -624),
    Vector3.new(-621, 3, -634),
    Vector3.new(-633, 3, -633),
    Vector3.new(-632, 3, -624),
    Vector3.new(-646, 3, -625),
    Vector3.new(-645, 3, -633),
    -- right wing cases
    Vector3.new(-657, 3, -633),
    Vector3.new(-657, 3, -624),
    Vector3.new(-667, 3, -638),
    Vector3.new(-667, 3, -647),
    Vector3.new(-667, 3, -613),
    Vector3.new(-668, 3, -604),
}
-- entry point — outside the jewelry store door
local JEWELRY_ENTRY = Vector3.new(-600, 3, -608)

local CASINO_COORDS = {
    Vector3.new(-1154, 4, -775),
    Vector3.new(-1156, 4, -781),
    Vector3.new(-1161, 4, -781),
    Vector3.new(-1159, 4, -786),
    Vector3.new(-1154, 4, -789),
    Vector3.new(-1153, 4, -793),
    Vector3.new(-1151, 4, -785),
    Vector3.new(-1143, 7, -784),
    Vector3.new(-1144, 7, -788),
    Vector3.new(-1143, 7, -790),
    Vector3.new(-1148, 4, -798),
    Vector3.new(-1142, 4, -800),
    Vector3.new(-1157, 4, -798),
    Vector3.new(-1159, 4, -800),
    Vector3.new(-1164, 4, -795),
    Vector3.new(-1165, 4, -787),
    Vector3.new(-1173, 7, -783),
    Vector3.new(-1172, 7, -786),
}

-- Bins: TP → settle → hold R 3 s → teleport to next bin, reset every 3 bins
local function runBinsLoop()
    local count = 0
    while Cfg.binsFarm do
        for idx = 1, #BINS_COORDS do
            if not Cfg.binsFarm then break end
            local char = LP.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(1.0); continue end

            -- TP to bin position
            local pos = BINS_COORDS[idx]
            tweenToPos(hrp, pos)
            task.wait(0.3)    -- settle
            holdR(3.0)        -- hold R 3 s to loot bin
            task.wait(0.5)    -- brief gap before next TP
            count = count + 1
            -- reset every 2 bins
            if count % 2 == 0 then
                if not Cfg.binsFarm then break end
                resetAndWait()
            end
        end
        if not Cfg.binsFarm then break end
        -- full cycle done: reset + 12 s cooldown
        resetAndWait()
        local waited = 0
        while waited < 12 and Cfg.binsFarm do
            task.wait(0.5); waited = waited + 0.5
        end
    end
end

-- ATM: TP → holdR 0.7s (rob) → holdE 0.7s (item 1) → holdE 0.7s (item 2) → reset every 2 ATMs
local function runAtmLoop()
    local count = 0
    while Cfg.atmFarm do
        for idx = 1, #ATM_COORDS do
            if not Cfg.atmFarm then break end
            local char = LP.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(1.0); continue end

            -- tween to ATM
            local pos = ATM_COORDS[idx]
            tweenToPos(hrp, pos)
            task.wait(0.25)   -- settle

            -- rob the ATM (hold R once — drops 2 items on the ground)
            holdR(0.7)
            task.wait(0.15)

            -- collect item 1
            holdEContinuous(0.7)
            task.wait(0.12)

            -- collect item 2
            holdEContinuous(0.7)
            task.wait(0.2)

            count = count + 1

            -- reset every 2 ATMs to bank loot
            if count % 2 == 0 then
                if not Cfg.atmFarm then break end
                resetAndWait()
            end
        end

        if not Cfg.atmFarm then break end
        -- end of full cycle — reset any remainder then loop back
        resetAndWait()
        task.wait(1.0)
    end
end

local function jewelryIsOpen()
    return robberyReady("Jewelry")
end

-- Deliver jewelry loot to hotel and reset
local function jewelryDeliverAndReset()
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(HOTEL_POS.X, HOTEL_POS.Y, HOTEL_POS.Z)
        task.wait(0.4)
        holdEContinuous(4.5)   -- hold E long enough for full delivery animation
        task.wait(0.3)
    end
    resetAndWait()
end

local function runJewelryLoop()
    while Cfg.jewelryFarm do
        -- wait for robbery to be open
        local notified = false
        while Cfg.jewelryFarm and not jewelryIsOpen() do
            if not notified then
                nyraNotify("Jewelry Locked", "Jewelry robbery isn't ready yet — farm will start automatically when it opens!", 8)
                notified = true
            end
            task.wait(1.0)
        end
        if not Cfg.jewelryFarm then break end

        -- TP to store entry
        local char = LP.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then task.wait(1.0); continue end
        tweenToPos(hrp, JEWELRY_ENTRY)
        task.wait(0.4)

        -- smash every case: TP directly (they are close, tween wastes time)
        local collected = 0
        for i, pos in ipairs(JEWELRY_COORDS) do
            if not Cfg.jewelryFarm then break end
            char = LP.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(1.0); continue end

            tweenToPos(hrp, pos)
            task.wait(0.18)           -- settle before interacting
            holdEContinuous(1.0)      -- smash/loot the case (1 s is enough)
            task.wait(0.12)
            collected = collected + 1

            -- mid-loop delivery every 10 cases to avoid dropping loot on reset
            if collected % 10 == 0 and i < #JEWELRY_COORDS then
                if not Cfg.jewelryFarm then break end
                jewelryDeliverAndReset()
                -- re-acquire char after reset
                char = LP.Character
                hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then break end
                -- jump back to where we left off
                tweenToPos(hrp, pos)
                task.wait(0.3)
            end
        end

        if not Cfg.jewelryFarm then break end
        -- deliver whatever is left after finishing all cases
        jewelryDeliverAndReset()
    end
end

-- Casino vault check coordinate
local CASINO_START_POS = Vector3.new(-1146, 4, -764)

local function casinoIsOpen()
    return robberyReady("Casino")
end

-- Casino farm loop
local function runCasinoLoop()
    while Cfg.casinoFarm do
        -- wait for casino robbery to be ready
        local notifiedCasino = false
        while Cfg.casinoFarm and not casinoIsOpen() do
            if not notifiedCasino then
                nyraNotify("Casino Locked", "Casino robbery isn't ready yet - keep the farm on, it'll start automatically when it opens!", 8)
                notifiedCasino = true
            end
            task.wait(1.0)
        end
        if not Cfg.casinoFarm then break end

        -- TP to casino start
        local char = LP.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then task.wait(1); continue end
        tweenToPos(hrp, CASINO_START_POS)
        task.wait(0.4)

        -- tween between each slot, hold E at each, hotel+reset every 8
        local casinoCount = 0
        for i, pos in ipairs(CASINO_COORDS) do
            if not Cfg.casinoFarm then break end
            char = LP.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(1.0); continue end

            if i == 1 then
                hrp.CFrame = CFrame.new(pos.X, pos.Y, pos.Z)
                task.wait(0.2)
            else
                tweenToPos(hrp, pos)
            end
            task.wait(0.15)
            pressKey(KEY_E)
            task.wait(2.5)
            releaseKey(KEY_E)
            task.wait(0.2)
            casinoCount = casinoCount + 1

            if casinoCount % 8 == 0 then
                if not Cfg.casinoFarm then break end
                local c2 = LP.Character
                local h2 = c2 and c2:FindFirstChild("HumanoidRootPart")
                if h2 then
                    tweenToPos(h2, HOTEL_POS)
                    task.wait(0.3)
                    pressKey(KEY_E)
                    task.wait(4.0)
                    releaseKey(KEY_E)
                    task.wait(0.3)
                end
                resetAndWait()
            end
        end

        if not Cfg.casinoFarm then break end
        -- deliver remainder after full cycle
        local c2 = LP.Character
        local h2 = c2 and c2:FindFirstChild("HumanoidRootPart")
        if h2 then
            tweenToPos(h2, HOTEL_POS)
            task.wait(0.3)
            pressKey(KEY_E)
            task.wait(4.0)
            releaseKey(KEY_E)
            task.wait(0.3)
        end
        resetAndWait()
    end
end

-- ════════════════════════════════════════════════════════════
--  GUNPOWDER FARM
-- ════════════════════════════════════════════════════════════

local GUNPOWDER_START = Vector3.new(-906, 2, -987)

local GUNPOWDER_COORDS = {
    Vector3.new(-910, 2, -1000),
    Vector3.new(-904, 2, -1000),
    Vector3.new(-899, 2, -1004),
    Vector3.new(-907, 2, -1005),
    Vector3.new(-914, 2, -1006),
    Vector3.new(-922, 2, -1007),
    Vector3.new(-924, 2, -1001),
    Vector3.new(-930, 2, -1003),
    Vector3.new(-937, 2, -1000),
    Vector3.new(-937, 5, -1008),
    Vector3.new(-936, 5, -1012),
    Vector3.new(-937, 5, -1016),
    Vector3.new(-938, 2, -1023),
    Vector3.new(-933, 2, -1027),
    Vector3.new(-925, 6, -1030),
    Vector3.new(-924, 2, -1025),
    Vector3.new(-918, 2, -1024),
    Vector3.new(-914, 6, -1030),
    Vector3.new(-908, 2, -1026),
    Vector3.new(-901, 2, -1029),
    Vector3.new(-905, 5, -1018),
    Vector3.new(-907, 5, -1016),
    Vector3.new(-907, 5, -1012),
    Vector3.new(-913, 2, -1018),
    Vector3.new(-917, 2, -1015),
    Vector3.new(-914, 2, -1012),
    Vector3.new(-922, 2, -1013),
    Vector3.new(-928, 2, -1013),
    Vector3.new(-929, 2, -1018),
    Vector3.new(-924, 2, -1019),
}

local function runGunpowderLoop()
    while Cfg.gunpowderFarm do
        -- check if factory robbery is ready
        local notifiedGun = false
        while Cfg.gunpowderFarm and not robberyReady("Factory") do
            if not notifiedGun then
                nyraNotify("Factory Locked", "Gunpowder robbery isn't ready yet - keep the farm on, it'll start automatically when it opens!", 8)
                notifiedGun = true
            end
            task.wait(1.0)
        end
        if not Cfg.gunpowderFarm then break end

        -- TP to start position
        local char = LP.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then task.wait(1.0); continue end
        tweenToPos(hrp, GUNPOWDER_START)
        task.wait(0.4)

        -- tween between each bag, hold E at each one
        local count = 0
        for i, pos in ipairs(GUNPOWDER_COORDS) do
            if not Cfg.gunpowderFarm then break end
            char = LP.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(1.0); continue end

            if i == 1 then
                hrp.CFrame = CFrame.new(pos.X, pos.Y, pos.Z)
                task.wait(0.2)
            else
                tweenToPos(hrp, pos)
            end
            task.wait(0.15)
            pressKey(KEY_E)
            task.wait(1.0)
            releaseKey(KEY_E)
            task.wait(0.2)
            count = count + 1

            -- every 8 bags: deliver to hotel, hold E, reset
            if count % 8 == 0 then
                if not Cfg.gunpowderFarm then break end
                local c2 = LP.Character
                local h2 = c2 and c2:FindFirstChild("HumanoidRootPart")
                if h2 then
                    tweenToPos(h2, HOTEL_POS)
                    task.wait(0.3)
                    pressKey(KEY_E)
                    task.wait(4.0)
                    releaseKey(KEY_E)
                    task.wait(0.3)
                end
                resetAndWait()
            end
        end

        if not Cfg.gunpowderFarm then break end
        -- deliver remainder after full cycle
        local c2 = LP.Character
        local h2 = c2 and c2:FindFirstChild("HumanoidRootPart")
        if h2 then
            tweenToPos(h2, HOTEL_POS)
            task.wait(0.3)
            pressKey(KEY_E)
            task.wait(4.0)
            releaseKey(KEY_E)
            task.wait(0.3)
        end
        resetAndWait()
    end
end

-- ════════════════════════════════════════════════════════════
--  ANTI-AFK FARM
--  Hides the player underground in a safe spot, prevents the
--  Roblox AFK kick, and fires bank/casino/jewelry automatically
--  the moment each robbery becomes ready.
-- ════════════════════════════════════════════════════════════

-- Permanent underground hiding position — stays here between heists
local ANTI_AFK_HIDE_POS = Vector3.new(-897, -87, -598)

local function runAntiAfkLoop()
    nyraNotify("Anti-AFK", "Tweening underground — will auto-farm when any heist opens.", 6)

    -- Tween smoothly to the hide position (looks natural, not an instant pop)
    local function tweenToHide(speed)
        speed = speed or 40  -- studs/s
        local char = LP.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local dist     = (hrp.Position - ANTI_AFK_HIDE_POS).Magnitude
        local duration = math.max(dist / speed, 0.3)
        local t = TweenService:Create(hrp,
            TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {CFrame = CFrame.new(ANTI_AFK_HIDE_POS) * hrp.CFrame.Rotation}
        )
        t:Play()
        t.Completed:Wait()
    end
    tweenToHide()

    local kickTimer  = 0
    local KICK_EVERY = 60   -- jump every 60 s to prevent Roblox AFK kick

    while Cfg.antiAfkEnabled do
        -- ── Anti-kick: simulate activity every 60 s ──
        kickTimer = kickTimer + 1
        if kickTimer >= KICK_EVERY then
            kickTimer = 0
            pcall(function()
                local char = LP.Character
                local hum  = char and char:FindFirstChildWhichIsA("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
            task.wait(0.4)
            tweenToHide(80)   -- quick tween back after jump
        end

        -- ── Check heists — tween in when ready, tween back when done ──

        -- Bank
        if Cfg.bankFarm and bankIsOpen() then
            nyraNotify("Anti-AFK", "Bank is open! Tweening in to farm.", 5)
            runBankLoop()
            task.wait(0.5)
            tweenToHide()
        end

        -- Casino
        if Cfg.casinoFarm and casinoIsOpen() then
            nyraNotify("Anti-AFK", "Casino is open! Tweening in to farm.", 5)
            runCasinoLoop()
            task.wait(0.5)
            tweenToHide()
        end

        -- Jewelry
        if Cfg.jewelryFarm and jewelryIsOpen() then
            nyraNotify("Anti-AFK", "Jewelry is open! Tweening in to farm.", 5)
            runJewelryLoop()
            task.wait(0.5)
            tweenToHide()
        end

        -- Gunpowder
        if Cfg.gunpowderFarm and robberyReady("Factory") then
            nyraNotify("Anti-AFK", "Factory is open! Tweening in to farm.", 5)
            runGunpowderLoop()
            task.wait(0.5)
            tweenToHide()
        end

        task.wait(1.0)   -- poll every second
    end

    nyraNotify("Anti-AFK", "Anti-AFK stopped.", 4)
end

-- ── Auto Rejoin ──
if Cfg.autoRejoinEnabled then
    _G.NyraFarmActive = Cfg.bankFarm or Cfg.casinoFarm or Cfg.jewelryFarm or Cfg.gunpowderFarm or Cfg.atmFarm or Cfg.binsFarm or Cfg.antiAfkEnabled
    LP.OnTeleport:Connect(function(state)
        if state == Enum.TeleportState.Started and _G.NyraFarmActive then
            nyraNotify("Auto Rejoin", "Detected teleport/kick. Rejoining server and resuming farms.", 10)
            local ts = game:GetService("TeleportService")
            ts:TeleportToPlaceInstance(game.PlaceId, game.JobId)
        end
    end)
end

-- ── Resume farms on script re-execution (if auto-rejoined) ──
if _G.NyraFarmActive then
    nyraNotify("Auto Rejoin", "Script re-executed. Resuming active farms.", 8)
    task.delay(2, function()  -- wait for character to load
        if Cfg.bankFarm then task.spawn(runBankLoop) end
        if Cfg.casinoFarm then task.spawn(runCasinoLoop) end
        if Cfg.jewelryFarm then task.spawn(runJewelryLoop) end
        if Cfg.gunpowderFarm then task.spawn(runGunpowderLoop) end
        if Cfg.atmFarm then task.spawn(runAtmLoop) end
        if Cfg.binsFarm then task.spawn(runBinsLoop) end
        if Cfg.antiAfkEnabled then task.spawn(runAntiAfkLoop) end
    end)
end

-- ── Farm watchers ──
local bankFarmActive       = false
local binsFarmActive       = false
local atmFarmActive        = false
local casinoFarmActive     = false
local jewelryFarmActive    = false
local gunpowderFarmActive  = false
local antiAfkActive        = false

RunService.Heartbeat:Connect(function()
    -- Anti-AFK (runs first — owns the character while active)
    if Cfg.antiAfkEnabled and not antiAfkActive then
        antiAfkActive = true
        task.spawn(function() runAntiAfkLoop(); antiAfkActive = false end)
    end
    if not Cfg.antiAfkEnabled then antiAfkActive = false end

    -- Bank (only if anti-afk isn't managing it)
    if Cfg.bankFarm and not bankFarmActive and not Cfg.antiAfkEnabled then
        bankFarmActive = true
        task.spawn(function() runBankLoop(); bankFarmActive = false end)
    end
    if not Cfg.bankFarm then bankFarmActive = false end

    -- Bins
    if Cfg.binsFarm and not binsFarmActive then
        binsFarmActive = true
        task.spawn(function() runBinsLoop(); binsFarmActive = false end)
    end
    if not Cfg.binsFarm then binsFarmActive = false end

    -- ATM
    if Cfg.atmFarm and not atmFarmActive then
        atmFarmActive = true
        task.spawn(function() runAtmLoop(); atmFarmActive = false end)
    end
    if not Cfg.atmFarm then atmFarmActive = false end

    -- Casino (only if anti-afk isn't managing it)
    if Cfg.casinoFarm and not casinoFarmActive and not Cfg.antiAfkEnabled then
        casinoFarmActive = true
        task.spawn(function() runCasinoLoop(); casinoFarmActive = false end)
    end
    if not Cfg.casinoFarm then casinoFarmActive = false end

    -- Jewelry (only if anti-afk isn't managing it)
    if Cfg.jewelryFarm and not jewelryFarmActive and not Cfg.antiAfkEnabled then
        jewelryFarmActive = true
        task.spawn(function() runJewelryLoop(); jewelryFarmActive = false end)
    end
    if not Cfg.jewelryFarm then jewelryFarmActive = false end

    -- Gunpowder (only if anti-afk isn't managing it)
    if Cfg.gunpowderFarm and not gunpowderFarmActive and not Cfg.antiAfkEnabled then
        gunpowderFarmActive = true
        task.spawn(function() runGunpowderLoop(); gunpowderFarmActive = false end)
    end
    if not Cfg.gunpowderFarm then gunpowderFarmActive = false end
end)

-- ════════════════════════════════════════════════════════════
--  CROSSHAIR OVERLAY  (Drawing API)
-- ════════════════════════════════════════════════════════════
local chLines={}   -- reusable Drawing lines (up to 4 for Cross style)
local chDot=nil
local chCircle=nil
if Drawing then
    for i=1,4 do
        chLines[i]=Drawing.new("Line")
        chLines[i].Visible=false; chLines[i].ZIndex=5
    end
    chDot=Drawing.new("Circle")
    chDot.Visible=false; chDot.Filled=true; chDot.NumSides=32
    chCircle=Drawing.new("Circle")
    chCircle.Visible=false; chCircle.Filled=false; chCircle.NumSides=64
end

local function updateCrosshair()
    if not Drawing then return end
    local on=Cfg.crosshairEnabled
    local style=Cfg.crosshairStyle
    local sz=Cfg.crosshairSize
    local gap=Cfg.crosshairGap
    local thick=Cfg.crosshairThick
    local col=Color3.fromRGB(255,255,255)
    local vp=Camera.ViewportSize
    local cx=vp.X/2; local cy=vp.Y/2

    -- hide all first
    for i=1,4 do chLines[i].Visible=false end
    chDot.Visible=false; chCircle.Visible=false

    if not on then return end

    if style=="Cross" then
        -- top
        chLines[1].From=Vector2.new(cx,cy-gap-sz); chLines[1].To=Vector2.new(cx,cy-gap)
        -- bottom
        chLines[2].From=Vector2.new(cx,cy+gap);    chLines[2].To=Vector2.new(cx,cy+gap+sz)
        -- left
        chLines[3].From=Vector2.new(cx-gap-sz,cy); chLines[3].To=Vector2.new(cx-gap,cy)
        -- right
        chLines[4].From=Vector2.new(cx+gap,cy);    chLines[4].To=Vector2.new(cx+gap+sz,cy)
        for i=1,4 do
            chLines[i].Color=col; chLines[i].Thickness=thick; chLines[i].Visible=true
        end
    elseif style=="Dot" then
        chDot.Position=Vector2.new(cx,cy); chDot.Radius=thick+1
        chDot.Color=col; chDot.Visible=true
    elseif style=="Circle" then
        chCircle.Position=Vector2.new(cx,cy); chCircle.Radius=sz
        chCircle.Color=col; chCircle.Thickness=thick; chCircle.Visible=true
    end
end

RunService.RenderStepped:Connect(updateCrosshair)

-- ════════════════════════════════════════════════════════════
--  VELOCITY PREDICTION DISPLAY  (Drawing API)
-- ════════════════════════════════════════════════════════════
local velText=nil
if Drawing then
    velText=Drawing.new("Text")
    velText.Visible=false; velText.Size=14; velText.Center=true; velText.Outline=true
    velText.Color=Color3.fromRGB(255,255,255); velText.ZIndex=5
end

RunService.Heartbeat:Connect(function()
    if not velText then return end
    if not Cfg.velHudEnabled then velText.Visible=false; return end
    local char=LP.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then velText.Visible=false; return end
    local vel=hrp.AssemblyLinearVelocity
    local xzSpeed=math.sqrt(vel.X^2+vel.Z^2)
    local ySpeed=vel.Y
    local vp=Camera.ViewportSize
    velText.Position=Vector2.new(vp.X/2, vp.Y-40)
    velText.Text=string.format("XZ: %.1f  |  Y: %.1f", xzSpeed, ySpeed)
    velText.Visible=true
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
    if pp:IsA("ProximityPrompt") then pp.HoldDuration = 0.1 end
end
for _, pp in ipairs(Workspace:GetDescendants()) do setPromptDuration(pp) end
Workspace.DescendantAdded:Connect(setPromptDuration)
