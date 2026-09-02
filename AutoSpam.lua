--[[
    AutoClicker  |  made by GR5
    Cross-executor | High Performance
]]

-- ═══ GUARD ═══════════════════════════════════════════════
for _, n in ipairs({"ACMacro"}) do
    pcall(function() game:GetService("CoreGui"):FindFirstChild(n):Destroy() end)
    pcall(function() game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild(n):Destroy() end)
end

-- ═══ SERVİSLER ══════════════════════════════════════════
local ok, Svc = pcall(function()
    return {
        Players  = game:GetService("Players"),
        UIS      = game:GetService("UserInputService"),
        TW       = game:GetService("TweenService"),
        RS       = game:GetService("RunService"),
        Lighting = game:GetService("Lighting"),
        CoreGui  = game:GetService("CoreGui"),
        TS       = game:GetService("TeleportService"),
        VU       = game:GetService("VirtualUser"),
    }
end)
if not ok then warn("[GR5] Service error"); return end

local LP = Svc.Players.LocalPlayer
if not LP then warn("[GR5] LP yok"); return end

-- ═══ GUI ROOT ════════════════════════════════════════════
local ROOT = nil
if gethui then pcall(function() ROOT = gethui() end) end
if not ROOT then pcall(function() ROOT = Svc.CoreGui end) end
if not ROOT then ROOT = LP.PlayerGui end

local G = Instance.new("ScreenGui")
G.Name = "ACMacro"; G.ResetOnSpawn = false
G.IgnoreGuiInset = true
G.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() G.Parent = ROOT end)

-- ═══ TWEEN YARDIMCI ══════════════════════════════════════
local function tw(obj, t, props, style)
    pcall(function()
        Svc.TW:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quart), props):Play()
    end)
end

-- ═══ STATE ════════════════════════════════════════════════
local pps         = 20
local isOn        = false
local realCPS     = 0
local totalClicks = 0
local hotkey      = Enum.KeyCode.F
local binding     = false
local loopConn    = nil
local gfxOn       = false
local savedSky    = {}
local savedS, savedB, savedF

-- ═══ CLICK METHOD ════════════════════════════════════════
local HAS_M1  = type(mouse1click)   == "function"
local HAS_M1P = type(mouse1press)   == "function"
local HAS_M1R = type(mouse1release) == "function"

local function doClick()
    pcall(function()
        if HAS_M1  then mouse1click() end
        if HAS_M1P and HAS_M1R then mouse1press(); mouse1release() end
        Svc.VU:CaptureController(); Svc.VU:ClickButton1(Vector2.new())
    end)
    totalClicks = totalClicks + 1
end

-- ═══ LOOP ════════════════════════════════════════════════
local acc = 0
local function startLoop()
    isOn = true
    if loopConn then pcall(function() loopConn:Disconnect() end); loopConn = nil end
    acc = 0; local t0 = tick(); local cnt = 0
    loopConn = Svc.RS.Heartbeat:Connect(function(dt)
        if not isOn then return end
        acc = acc + pps * dt
        local n = math.min(math.floor(acc), 100)
        if n < 1 then return end
        acc = acc - n
        for i = 1, n do doClick() end
        cnt = cnt + n
        if tick() - t0 >= 1 then realCPS = cnt; cnt = 0; t0 = tick() end
    end)
end
local function stopLoop()
    isOn = false
    if loopConn then pcall(function() loopConn:Disconnect() end); loopConn = nil end
    realCPS = 0
end

-- ═══ LOW GFX ═════════════════════════════════════════════
local function applyLow()
    gfxOn = true
    pcall(function()
        savedS = Svc.Lighting.GlobalShadows; savedB = Svc.Lighting.Brightness; savedF = Svc.Lighting.FogEnd
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        Svc.Lighting.GlobalShadows = false; Svc.Lighting.FogEnd = 10e9; Svc.Lighting.Brightness = 0.5
        for _, v in ipairs(Svc.Lighting:GetChildren()) do pcall(function()
            if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("DepthOfFieldEffect") then
                table.insert(savedSky, {o=v, p=v.Parent}); v.Parent = nil end
        end) end
        for _, v in ipairs(workspace:GetDescendants()) do pcall(function()
            if v:IsA("Texture") or v:IsA("Decal") then v.Transparency = 1 end
            if v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic end
        end) end
    end)
end
local function restoreLow()
    gfxOn = false
    pcall(function()
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
        Svc.Lighting.GlobalShadows = savedS ~= nil and savedS or true
        Svc.Lighting.Brightness    = savedB ~= nil and savedB or 2
        Svc.Lighting.FogEnd        = savedF ~= nil and savedF or 10e9
        for _, t in ipairs(savedSky) do pcall(function() t.o.Parent = t.p end) end; savedSky = {}
    end)
end

-- ═══ ANA ÇERÇEVE ═════════════════════════════════════════
local FULL_H = 220; local MINI_H = 28; local minimized = false
local BG = Instance.new("Frame", G)
BG.Size = UDim2.new(0, 300, 0, FULL_H); BG.Position = UDim2.new(0.5, -150, 0.3, 0)
BG.BackgroundColor3 = Color3.fromRGB(10, 10, 14); BG.BorderSizePixel = 0
BG.ZIndex = 10; BG.Active = true; BG.ClipsDescendants = true
Instance.new("UICorner", BG).CornerRadius = UDim.new(0, 6)
local bgSt = Instance.new("UIStroke", BG); bgSt.Thickness = 1.5; bgSt.Color = Color3.fromRGB(50, 50, 70)

-- Animasyonlu border
task.spawn(function()
    local h = 0
    while BG and BG.Parent do
        h = (h + 1) % 360
        local b = math.floor(math.abs(math.sin(math.rad(h))) * 120 + 40)
        bgSt.Color = Color3.fromRGB(0, math.floor(b * 0.4), b)
        task.wait(0.05)
    end
end)

-- Header
local HDR = Instance.new("Frame", BG); HDR.Size = UDim2.new(1, 0, 0, 28); HDR.BackgroundColor3 = Color3.fromRGB(14, 14, 20); HDR.BorderSizePixel = 0; HDR.ZIndex = 11; Instance.new("UICorner", HDR).CornerRadius = UDim.new(0, 6)
local hLbl = Instance.new("TextLabel", HDR); hLbl.Size = UDim2.new(1, -8, 1, 0); hLbl.Position = UDim2.new(0, 8, 0, 0); hLbl.BackgroundTransparency = 1; hLbl.Text = "▼  AutoClicker  |  made by GR5"; hLbl.Font = Enum.Font.Code; hLbl.TextSize = 13; hLbl.TextColor3 = Color3.fromRGB(200, 200, 220); hLbl.TextXAlignment = Enum.TextXAlignment.Left; hLbl.ZIndex = 12
local hBtn = Instance.new("TextButton", HDR); hBtn.Size = UDim2.new(1, 0, 1, 0); hBtn.BackgroundTransparency = 1; hBtn.Text = ""; hBtn.ZIndex = 13; hBtn.AutoButtonColor = false

-- Drag
local dr = false; local ds = Vector2.zero; local dp2 = BG.Position; local dD = 0
hBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dr = true; dD = 0; ds = Vector2.new(i.Position.X, i.Position.Y); dp2 = BG.Position
    end
end)
Svc.UIS.InputChanged:Connect(function(i)
    if dr and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = Vector2.new(i.Position.X - ds.X, i.Position.Y - ds.Y); dD = d.Magnitude
        pcall(function() BG.Position = UDim2.new(dp2.X.Scale, dp2.X.Offset + d.X, dp2.Y.Scale, dp2.Y.Offset + d.Y) end)
    end
end)
Svc.UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dr = false end end)
hBtn.MouseButton1Click:Connect(function()
    if dD > 5 then dD = 0; return end
    minimized = not minimized
    hLbl.Text = (minimized and "▲" or "▼") .. "  AutoClicker  |  made by GR5"
    tw(BG, 0.25, {Size = UDim2.new(0, 300, 0, minimized and MINI_H or FULL_H)})
end)

-- Buton yardımcı
local function mkB(txt, x, y, w, h2, bc, tc)
    local b = Instance.new("TextButton", BG)
    b.Size = UDim2.new(0, w, 0, h2); b.Position = UDim2.new(0, x, 0, y)
    b.BackgroundColor3 = bc or Color3.fromRGB(22, 22, 32); b.BorderSizePixel = 0
    b.ZIndex = 12; b.AutoButtonColor = false; b.Text = txt
    b.Font = Enum.Font.Code; b.TextSize = 15; b.TextColor3 = tc or Color3.fromRGB(220, 220, 240)
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", b).Color = Color3.fromRGB(50, 50, 70)
    b.MouseEnter:Connect(function() tw(b, 0.1, {BackgroundColor3 = Color3.fromRGB(40, 40, 55)}) end)
    b.MouseLeave:Connect(function() tw(b, 0.1, {BackgroundColor3 = bc or Color3.fromRGB(22, 22, 32)}) end)
    return b
end

-- PPS kontrolleri
local btnP = mkB("[+]", 8, 34, 34, 24, Color3.fromRGB(0, 35, 15), Color3.fromRGB(0, 220, 100))
local btnM = mkB("[-]", 46, 34, 34, 24, Color3.fromRGB(35, 10, 10), Color3.fromRGB(220, 80, 80))
local ppsBox = Instance.new("TextBox", BG); ppsBox.Size = UDim2.new(0, 72, 0, 24); ppsBox.Position = UDim2.new(0, 85, 0, 34); ppsBox.BackgroundColor3 = Color3.fromRGB(20, 20, 30); ppsBox.BorderSizePixel = 0; ppsBox.ZIndex = 12; ppsBox.Text = tostring(pps); ppsBox.Font = Enum.Font.Code; ppsBox.TextSize = 16; ppsBox.TextColor3 = Color3.fromRGB(220, 230, 255); ppsBox.ClearTextOnFocus = false; Instance.new("UICorner", ppsBox).CornerRadius = UDim.new(0, 4); Instance.new("UIStroke", ppsBox).Color = Color3.fromRGB(50, 50, 90)
local ppsL = Instance.new("TextLabel", BG); ppsL.Size = UDim2.new(0, 40, 0, 24); ppsL.Position = UDim2.new(0, 162, 0, 34); ppsL.BackgroundTransparency = 1; ppsL.Text = "PPS"; ppsL.Font = Enum.Font.Code; ppsL.TextSize = 13; ppsL.TextColor3 = Color3.fromRGB(90, 90, 130); ppsL.ZIndex = 12; ppsL.TextXAlignment = Enum.TextXAlignment.Left
local cpsBox = Instance.new("TextLabel", BG); cpsBox.Size = UDim2.new(0, 58, 0, 24); cpsBox.Position = UDim2.new(0, 205, 0, 34); cpsBox.BackgroundColor3 = Color3.fromRGB(10, 22, 12); cpsBox.BorderSizePixel = 0; cpsBox.ZIndex = 12; cpsBox.Text = "0"; cpsBox.Font = Enum.Font.Code; cpsBox.TextSize = 16; cpsBox.TextColor3 = Color3.fromRGB(60, 220, 80); cpsBox.TextXAlignment = Enum.TextXAlignment.Center; Instance.new("UICorner", cpsBox).CornerRadius = UDim.new(0, 4); Instance.new("UIStroke", cpsBox).Color = Color3.fromRGB(20, 60, 20)
local cpsLbl = Instance.new("TextLabel", BG); cpsLbl.Size = UDim2.new(0, 36, 0, 12); cpsLbl.Position = UDim2.new(0, 215, 0, 60); cpsLbl.BackgroundTransparency = 1; cpsLbl.Text = "CPS"; cpsLbl.Font = Enum.Font.Code; cpsLbl.TextSize = 10; cpsLbl.TextColor3 = Color3.fromRGB(40, 90, 40); cpsLbl.ZIndex = 12
local totLbl = Instance.new("TextLabel", BG); totLbl.Size = UDim2.new(0, 150, 0, 16); totLbl.Position = UDim2.new(0, 5, 0, 62); totLbl.BackgroundTransparency = 1; totLbl.Text = "Total: 0"; totLbl.Font = Enum.Font.Code; totLbl.TextSize = 11; totLbl.TextColor3 = Color3.fromRGB(70, 70, 110); totLbl.ZIndex = 12

ppsBox.FocusLost:Connect(function()
    pcall(function() local v = tonumber(ppsBox.Text); if v then pps = math.max(math.floor(v), 1) end; ppsBox.Text = tostring(pps) end)
end)
local function holdCh(d2)
    task.spawn(function()
        task.wait(0.35)
        while pcall(function() return Svc.UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end) and Svc.UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
            pps = math.max(pps + d2, 1); ppsBox.Text = tostring(pps); task.wait(0.07)
        end
    end)
end
btnP.MouseButton1Click:Connect(function() pps = pps + 5; ppsBox.Text = tostring(pps) end)
btnM.MouseButton1Click:Connect(function() pps = math.max(pps - 5, 1); ppsBox.Text = tostring(pps) end)
btnP.MouseButton1Down:Connect(function() holdCh(5) end)
btnM.MouseButton1Down:Connect(function() holdCh(-5) end)

-- Hotkey seçici
local kTopL = Instance.new("TextLabel", BG); kTopL.Size = UDim2.new(0, 110, 0, 16); kTopL.Position = UDim2.new(0, 6, 0, 84); kTopL.BackgroundTransparency = 1; kTopL.Text = "Hold Key:"; kTopL.Font = Enum.Font.Code; kTopL.TextSize = 12; kTopL.TextColor3 = Color3.fromRGB(90, 90, 130); kTopL.ZIndex = 12; kTopL.TextXAlignment = Enum.TextXAlignment.Left
local keyBtn = Instance.new("TextButton", BG); keyBtn.Size = UDim2.new(0, 90, 0, 24); keyBtn.Position = UDim2.new(0, 155, 0, 80); keyBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 30); keyBtn.BorderSizePixel = 0; keyBtn.ZIndex = 12; keyBtn.AutoButtonColor = false; keyBtn.Text = "[ F ]"; keyBtn.Font = Enum.Font.Code; keyBtn.TextSize = 14; keyBtn.TextColor3 = Color3.fromRGB(180, 220, 255); Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 4); local keySt = Instance.new("UIStroke", keyBtn); keySt.Color = Color3.fromRGB(60, 60, 100)
local stLbl = Instance.new("TextLabel", BG); stLbl.Size = UDim2.new(0, 270, 0, 16); stLbl.Position = UDim2.new(0, 5, 0, 108); stLbl.BackgroundTransparency = 1; stLbl.Text = "[ F ] hold → spam  ·  release → stops"; stLbl.Font = Enum.Font.Code; stLbl.TextSize = 10; stLbl.TextColor3 = Color3.fromRGB(60, 60, 100); stLbl.ZIndex = 12

keyBtn.MouseButton1Click:Connect(function()
    if binding then return end; binding = true
    keyBtn.Text = "[ ??? ]"; keyBtn.TextColor3 = Color3.fromRGB(255, 200, 0); tw(keySt, 0.15, {Color = Color3.fromRGB(200, 160, 0)})
    local con; con = Svc.UIS.InputBegan:Connect(function(i, gp)
        if gp or i.UserInputType ~= Enum.UserInputType.Keyboard then return end
        pcall(function()
            hotkey = i.KeyCode; local nm = tostring(hotkey):gsub("Enum.KeyCode.", "")
            keyBtn.Text = "[ " .. nm .. " ]"; keyBtn.TextColor3 = Color3.fromRGB(180, 220, 255)
            stLbl.Text = "[ " .. nm .. " ] hold → spam  ·  release → stops"
            tw(keySt, 0.15, {Color = Color3.fromRGB(60, 60, 100)})
        end)
        binding = false; pcall(function() con:Disconnect() end)
    end)
end)
keyBtn.MouseEnter:Connect(function() tw(keyBtn, 0.1, {BackgroundColor3 = Color3.fromRGB(30, 30, 46)}) end)
keyBtn.MouseLeave:Connect(function() tw(keyBtn, 0.1, {BackgroundColor3 = Color3.fromRGB(18, 18, 30)}) end)

Svc.UIS.InputBegan:Connect(function(i, gp)
    if gp or binding then return end
    if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode == hotkey and not isOn then
        isOn = true; startLoop()
        tw(bgSt, 0.15, {Color = Color3.fromRGB(0, 200, 80)})
        tw(keyBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(0, 40, 16)})
        keyBtn.TextColor3 = Color3.fromRGB(60, 255, 120); stLbl.TextColor3 = Color3.fromRGB(0, 200, 80)
    end
end)
Svc.UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode == hotkey and isOn then
        stopLoop()
        tw(bgSt, 0.15, {Color = Color3.fromRGB(50, 50, 70)})
        tw(keyBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(18, 18, 30)})
        keyBtn.TextColor3 = Color3.fromRGB(180, 220, 255); stLbl.TextColor3 = Color3.fromRGB(60, 60, 100)
    end
end)

-- Low GFX butonu
local gfxBtn = Instance.new("TextButton", BG); gfxBtn.Size = UDim2.new(1, -12, 0, 28); gfxBtn.Position = UDim2.new(0, 6, 0, 128); gfxBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 34); gfxBtn.BorderSizePixel = 0; gfxBtn.ZIndex = 12; gfxBtn.AutoButtonColor = false; gfxBtn.Text = "🖥  LOW GFX  [ OFF ]"; gfxBtn.Font = Enum.Font.Code; gfxBtn.TextSize = 14; gfxBtn.TextColor3 = Color3.fromRGB(130, 130, 170); Instance.new("UICorner", gfxBtn).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", gfxBtn).Color = Color3.fromRGB(50, 50, 70)
gfxBtn.MouseButton1Click:Connect(function()
    if gfxOn then restoreLow(); gfxBtn.Text = "🖥  LOW GFX  [ OFF ]"; gfxBtn.TextColor3 = Color3.fromRGB(130, 130, 170); tw(gfxBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(20, 20, 34)})
    else applyLow(); gfxBtn.Text = "🖥  LOW GFX  [ ON  ]"; gfxBtn.TextColor3 = Color3.fromRGB(60, 220, 120); tw(gfxBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(8, 36, 16)}) end
end)
gfxBtn.MouseEnter:Connect(function() tw(gfxBtn, 0.1, {BackgroundColor3 = Color3.fromRGB(32, 32, 48)}) end)
gfxBtn.MouseLeave:Connect(function() if not gfxOn then tw(gfxBtn, 0.1, {BackgroundColor3 = Color3.fromRGB(20, 20, 34)}) end end)

-- Rejoin butonu
local rjBtn = Instance.new("TextButton", BG); rjBtn.Size = UDim2.new(1, -12, 0, 26); rjBtn.Position = UDim2.new(0, 6, 0, 161); rjBtn.BackgroundColor3 = Color3.fromRGB(22, 16, 16); rjBtn.BorderSizePixel = 0; rjBtn.ZIndex = 12; rjBtn.AutoButtonColor = false; rjBtn.Text = "🔄  Rejoin Server"; rjBtn.Font = Enum.Font.Code; rjBtn.TextSize = 14; rjBtn.TextColor3 = Color3.fromRGB(200, 100, 100); Instance.new("UICorner", rjBtn).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", rjBtn).Color = Color3.fromRGB(80, 30, 30)
rjBtn.MouseButton1Click:Connect(function() pcall(function() Svc.TS:Teleport(game.PlaceId, LP) end) end)
rjBtn.MouseEnter:Connect(function() tw(rjBtn, 0.1, {BackgroundColor3 = Color3.fromRGB(40, 20, 20)}) end)
rjBtn.MouseLeave:Connect(function() tw(rjBtn, 0.1, {BackgroundColor3 = Color3.fromRGB(22, 16, 16)}) end)

-- Status bar
local barF = Instance.new("Frame", BG); barF.Size = UDim2.new(1, -12, 0, 26); barF.Position = UDim2.new(0, 6, 0, 191); barF.BackgroundColor3 = Color3.fromRGB(14, 14, 22); barF.BorderSizePixel = 0; barF.ZIndex = 12; Instance.new("UICorner", barF).CornerRadius = UDim.new(0, 5)
local barLbl = Instance.new("TextLabel", barF); barLbl.Size = UDim2.new(1, 0, 1, 0); barLbl.BackgroundTransparency = 1; barLbl.Text = "⏹  WAITING  —  hold [ F ] to spam"; barLbl.Font = Enum.Font.Code; barLbl.TextSize = 12; barLbl.TextColor3 = Color3.fromRGB(90, 90, 130); barLbl.ZIndex = 13

Svc.RS.Heartbeat:Connect(function()
    pcall(function()
        cpsBox.Text = tostring(realCPS); totLbl.Text = "Total: " .. tostring(totalClicks)
        local kn = tostring(hotkey):gsub("Enum.KeyCode.", "")
        if isOn then barLbl.Text = "▶  RUNNING  (" .. realCPS .. " CPS)"; barLbl.TextColor3 = Color3.fromRGB(60, 220, 80); barF.BackgroundColor3 = Color3.fromRGB(6, 22, 10)
        else barLbl.Text = "⏹  IDLE  —  hold [ " .. kn .. " ] to spam"; barLbl.TextColor3 = Color3.fromRGB(90, 90, 130); barF.BackgroundColor3 = Color3.fromRGB(14, 14, 22) end
    end)
end)

print("[GR5 AutoClicker] Loaded | M1:" .. tostring(HAS_M1) .. " M1P:" .. tostring(HAS_M1P) .. " VU:true")
