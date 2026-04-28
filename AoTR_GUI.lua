-- ╔══════════════════════════════════════════════════════════╗
-- ║   ATTACK ON TITAN REVOLUTION — FARMING v3.0             ║
-- ║              by Taishotokiyo                            ║
-- ╚══════════════════════════════════════════════════════════╝

-- ══════════════════════════════════════
--  SERVICES
-- ══════════════════════════════════════
local Players          = game:GetService("Players")
local RS               = game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local lp               = Players.LocalPlayer

repeat task.wait(0.1) until lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
task.wait(1)

pcall(function()
    game:GetService("CoreGui"):FindFirstChild("AOTR_v3") and
    game:GetService("CoreGui"):FindFirstChild("AOTR_v3"):Destroy()
end)

-- ══════════════════════════════════════
--  CONFIG
-- ══════════════════════════════════════
local CFG = {
    KILL_DELAY     = 1.5,
    MAX_KILLS      = 500,
    BOSS_HP_CUTOFF = 0.15,
    HITBOX         = 35,
    POSITION_MODE  = "Above",   -- "Above" / "Behind"
    ABOVE_Y        = 12,
    STREAK_TARGET  = 10,
    REJOIN_DELAY   = 3,
    BOSS_HP_MAX    = 5000,
    ATTACK_WAIT    = 0.07,
}

-- ══════════════════════════════════════
--  STATE
-- ══════════════════════════════════════
local T = {
    FarmBlade   = false,
    FarmTS      = false,
    AutoLeave   = false,
    AutoConnect = false,
    AutoStreak  = false,
    AutoEject   = false,
    AntiAFK     = false,
}

local loopGuard = {}

local stats = { kills=0, missions=0, raids=0, streak=0 }

-- ══════════════════════════════════════
--  NAPE / TITAN HELPERS
-- ══════════════════════════════════════
local NAPE_KWS = {"nape","napehit","weakpoint","weak","neck","killzone","neckback","hitzone","vital","critical","back"}

local function getNape(model)
    -- Priority 1: exact name match
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            local n = p.Name:lower()
            for _, k in ipairs(NAPE_KWS) do
                if n == k then return p end
            end
        end
    end
    -- Priority 2: contains keyword
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            local n = p.Name:lower()
            for _, k in ipairs(NAPE_KWS) do
                if n:find(k,1,true) then return p end
            end
        end
    end
    -- Priority 3: upper-back geometry heuristic
    local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
    if root then
        local best, bestScore = root, -999
        for _, p in ipairs(model:GetDescendants()) do
            if p:IsA("BasePart") and p ~= root then
                local rel = root.CFrame:PointToObjectSpace(p.Position)
                -- upper (rel.Y > 0) and behind (rel.Z < 0 in Roblox = in front of CFrame? depends on game)
                local score = rel.Y - math.abs(rel.X) * 0.5
                if score > bestScore then bestScore = score; best = p end
            end
        end
        return best
    end
    return model:FindFirstChildOfClass("BasePart")
end

local function getTitans(hrp, maxDist)
    local list = {}
    maxDist = maxDist or 9999
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= lp.Character and not Players:GetPlayerFromCharacter(obj) then
            local h = obj:FindFirstChildOfClass("Humanoid")
            local r = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
            if h and r and h.Health > 0 then
                local d = (hrp.Position - r.Position).Magnitude
                if d < maxDist then
                    table.insert(list, {model=obj, root=r, hum=h, dist=d})
                end
            end
        end
    end
    table.sort(list, function(a,b) return a.dist < b.dist end)
    return list
end

-- ══════════════════════════════════════
--  TOOL HELPERS
-- ══════════════════════════════════════
local function getEquippedTool()
    local char = lp.Character
    if not char then return nil end
    for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") then return t end
    end
    return nil
end

local function equipToolByKeyword(kws)
    -- Try to equip from backpack
    local bp = lp:FindFirstChild("Backpack")
    if not bp then return end
    for _, t in ipairs(bp:GetChildren()) do
        if t:IsA("Tool") then
            local n = t.Name:lower()
            for _, k in ipairs(kws) do
                if n:find(k,1,true) then
                    lp.Character.Humanoid:EquipTool(t)
                    task.wait(0.2)
                    return t
                end
            end
        end
    end
end

-- Fire all remotes whose name contains any keyword
local remoteCache, remoteCacheTime = {}, 0
local function buildCache()
    remoteCache = {}
    for _, r in ipairs(RS:GetDescendants()) do
        if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
            remoteCache[r.Name:lower()] = r
        end
    end
    -- also workspace
    for _, r in ipairs(workspace:GetDescendants()) do
        if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
            if not remoteCache[r.Name:lower()] then
                remoteCache[r.Name:lower()] = r
            end
        end
    end
    remoteCacheTime = tick()
end
buildCache()

local function fireKw(kws, ...)
    if tick() - remoteCacheTime > 20 then buildCache() end
    for name, r in pairs(remoteCache) do
        for _, k in ipairs(kws) do
            if name:find(k,1,true) then
                pcall(function()
                    if r:IsA("RemoteEvent") then r:FireServer(...)
                    else r:InvokeServer(...) end
                end)
                break
            end
        end
    end
end

-- ══════════════════════════════════════
--  CORE ATTACK
-- ══════════════════════════════════════
-- Strategy: teleport HRP onto nape, then:
-- 1. Activate the equipped tool  (handles blade/ODM swing)
-- 2. Fire attack remotes with the nape part as argument
-- 3. Simulate a touch event via CFrame nudge
local function doAttack(model, weaponType)
    local nape = getNape(model)
    if not nape then return false end
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local hBefore = model:FindFirstChildOfClass("Humanoid")
    if not hBefore or hBefore.Health <= 0 then return true end

    -- Position above/behind nape
    local offset = CFG.POSITION_MODE == "Behind"
        and Vector3.new(0, 4, 3)
        or  Vector3.new(0, CFG.ABOVE_Y, 0)

    hrp.CFrame = CFrame.new(nape.Position + offset)
    task.wait(CFG.ATTACK_WAIT)

    -- Snap right onto nape
    hrp.CFrame = CFrame.new(nape.Position + Vector3.new(0, 3, 0))
    task.wait(0.03)

    if weaponType == "ts" then
        -- Thunderspear: fire spear remotes pointed at nape
        fireKw({"thunderspear","ts","spear","launch","fire","shoot","throw","explode"},
               nape.Position, model)
        task.wait(0.05)
        fireKw({"thunderspear","ts","spear"}, model, nape)
    else
        -- Blade: activate tool first, then fire remotes
        local tool = getEquippedTool()
        if tool then
            pcall(function() tool:Activate() end)
            -- Also try RemoteEvent inside tool
            for _, r in ipairs(tool:GetDescendants()) do
                if r:IsA("RemoteEvent") then
                    pcall(function() r:FireServer(nape, nape.Position) end)
                end
            end
        end
        -- Fire generic attack remotes
        fireKw({"attack","slash","nape","execute","hit","swing","damage","strike","kill","cut"},
               nape, nape.Position, model)
        task.wait(0.04)
        -- Second pass with model as first arg
        fireKw({"attack","slash","nape","hit","damage"}, model, nape.Position)
    end

    task.wait(0.1)
    local hAfter = model:FindFirstChildOfClass("Humanoid")
    return not hAfter or hAfter.Health <= 0
end

-- ══════════════════════════════════════
--  LOBBY / CONNECT
-- ══════════════════════════════════════
local lastLeave = 0
local function clickBtn(kws)
    for _, obj in ipairs(lp.PlayerGui:GetDescendants()) do
        if (obj:IsA("TextButton") or obj:IsA("ImageButton")) then
            local t = (obj.Text or ""):lower()
            local n = obj.Name:lower()
            for _, k in ipairs(kws) do
                if t:find(k,1,true) or n:find(k,1,true) then
                    pcall(function() obj.MouseButton1Click:Fire() end)
                    return true
                end
            end
        end
    end
end

local function leaveToLobby()
    if tick() - lastLeave < 3 then return end
    lastLeave = tick()
    fireKw({"leave","lobby","exit","menu","returnlobby"})
    clickBtn({"leave","lobby","exit","menu","return"})
end

local function joinGame(mode)
    fireKw({mode,"join","connect","start","play"})
    clickBtn({mode,"join","connect","start","play"})
end

local function inMission()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) and obj ~= lp.Character then
            local h = obj:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then return true end
        end
    end
    return false
end

-- ══════════════════════════════════════
--  FARM LOOP
-- ══════════════════════════════════════
local function farmLoop(mode, weaponType)
    local key = (weaponType=="ts") and (mode=="raid" and "RaidTS" or "FarmTS") or
                (mode=="raid" and "RaidBlade" or "FarmBlade")
    if loopGuard[key] then return end
    loopGuard[key] = true

    -- Equip the right tool once
    if weaponType == "ts" then
        equipToolByKeyword({"thunderspear","ts","spear"})
    else
        equipToolByKeyword({"blade","sword","odm","gear","saber","ripper","knife"})
    end

    task.spawn(function()
        while T[key] do
            if not inMission() then
                joinGame(mode)
                task.wait(5)
                if mode=="mission" then stats.missions+=1 else stats.raids+=1 end
            end

            local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(1); continue end

            local titans = getTitans(hrp)
            local n = #titans

            if n == 0 then
                task.wait(2)
                if T.AutoLeave and stats.kills >= CFG.MAX_KILLS then
                    leaveToLobby(); stats.kills=0
                    task.wait(CFG.REJOIN_DELAY)
                end

            elseif n == 1 then
                local t = titans[1]
                local boss = t.hum.MaxHealth > CFG.BOSS_HP_MAX
                local pct  = t.hum.Health / t.hum.MaxHealth
                if boss and pct < CFG.BOSS_HP_CUTOFF then
                    task.wait(CFG.KILL_DELAY)
                else
                    task.wait(CFG.KILL_DELAY)
                    if doAttack(t.model, weaponType) then
                        stats.kills+=1; stats.streak+=1
                    end
                end
                if T.AutoStreak and stats.streak >= CFG.STREAK_TARGET then
                    leaveToLobby(); stats.streak=0
                    task.wait(CFG.REJOIN_DELAY)
                end

            else
                -- Kill all except last
                for i = 1, n-1 do
                    if not T[key] then break end
                    local t = titans[i]
                    local boss = t.hum.MaxHealth > CFG.BOSS_HP_MAX
                    local pct  = t.hum.Health / t.hum.MaxHealth
                    if not (boss and pct < CFG.BOSS_HP_CUTOFF) then
                        if doAttack(t.model, weaponType) then stats.kills+=1 end
                        task.wait(0.15)
                    end
                end
            end

            task.wait(0.08)
        end
        loopGuard[key] = nil
    end)
end

-- ══════════════════════════════════════
--  GUI — CLEAN MINIMAL DESIGN
-- ══════════════════════════════════════
local CoreGui = game:GetService("CoreGui")
local sg = Instance.new("ScreenGui", CoreGui)
sg.Name = "AOTR_v3"
sg.ResetOnSpawn = false
sg.DisplayOrder = 999
sg.IgnoreGuiInset = true

-- Main window
local win = Instance.new("Frame", sg)
win.Size             = UDim2.new(0, 260, 0, 420)
win.Position         = UDim2.new(1, -276, 0, 16)
win.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
win.BorderSizePixel  = 0
win.Active           = true
win.Draggable        = true
win.ClipsDescendants = true
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 10)
local winLine = Instance.new("UIStroke", win)
winLine.Color     = Color3.fromRGB(155, 15, 15)
winLine.Thickness = 1

-- Header strip
local hdr = Instance.new("Frame", win)
hdr.Size             = UDim2.new(1, 0, 0, 36)
hdr.BackgroundColor3 = Color3.fromRGB(120, 8, 8)
hdr.BorderSizePixel  = 0
local hg = Instance.new("UIGradient", hdr)
hg.Color = ColorSequence.new(Color3.fromRGB(160,10,10), Color3.fromRGB(80,4,4))

local hTitle = Instance.new("TextLabel", hdr)
hTitle.Size              = UDim2.new(1, -60, 1, 0)
hTitle.Position          = UDim2.new(0, 10, 0, 0)
hTitle.BackgroundTransparency = 1
hTitle.Text              = "⚔  AoTR Farm  v3"
hTitle.TextColor3        = Color3.new(1,1,1)
hTitle.Font              = Enum.Font.GothamBold
hTitle.TextSize          = 12
hTitle.TextXAlignment    = Enum.TextXAlignment.Left

-- Minimize
local miniBtn = Instance.new("TextButton", hdr)
miniBtn.Size             = UDim2.new(0, 22, 0, 22)
miniBtn.Position         = UDim2.new(1, -28, 0.5, -11)
miniBtn.BackgroundColor3 = Color3.fromRGB(55, 4, 4)
miniBtn.Text             = "—"
miniBtn.TextColor3       = Color3.new(1,1,1)
miniBtn.Font             = Enum.Font.GothamBold
miniBtn.TextSize         = 10
miniBtn.BorderSizePixel  = 0
Instance.new("UICorner", miniBtn).CornerRadius = UDim.new(0, 4)
local minimized = false
miniBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    TweenService:Create(win, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
        Size = minimized and UDim2.new(0,260,0,36) or UDim2.new(0,260,0,420)
    }):Play()
    miniBtn.Text = minimized and "+" or "—"
end)

-- Stats row
local statsRow = Instance.new("Frame", win)
statsRow.Size             = UDim2.new(1, 0, 0, 24)
statsRow.Position         = UDim2.new(0, 0, 0, 36)
statsRow.BackgroundColor3 = Color3.fromRGB(20, 6, 6)
statsRow.BorderSizePixel  = 0
local statsLbl = Instance.new("TextLabel", statsRow)
statsLbl.Size              = UDim2.new(1, -8, 1, 0)
statsLbl.Position          = UDim2.new(0, 8, 0, 0)
statsLbl.BackgroundTransparency = 1
statsLbl.Text              = "⚔ 0   🎮 0   🔥 0"
statsLbl.TextColor3        = Color3.fromRGB(230, 130, 130)
statsLbl.Font              = Enum.Font.Gotham
statsLbl.TextSize          = 10
statsLbl.TextXAlignment    = Enum.TextXAlignment.Left

-- Scroll
local scroll = Instance.new("ScrollingFrame", win)
scroll.Size                = UDim2.new(1, 0, 1, -84)
scroll.Position            = UDim2.new(0, 0, 0, 60)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel     = 0
scroll.ScrollBarThickness  = 2
scroll.ScrollBarImageColor3 = Color3.fromRGB(155,15,15)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize          = UDim2.new(0,0,0,0)
local sll = Instance.new("UIListLayout", scroll)
sll.Padding             = UDim.new(0, 4)
sll.HorizontalAlignment = Enum.HorizontalAlignment.Center
local spad = Instance.new("UIPadding", scroll)
spad.PaddingTop    = UDim.new(0, 6)
spad.PaddingBottom = UDim.new(0, 8)

-- Status bar
local stBar = Instance.new("Frame", win)
stBar.Size             = UDim2.new(1, 0, 0, 22)
stBar.Position         = UDim2.new(0, 0, 1, -22)
stBar.BackgroundColor3 = Color3.fromRGB(120, 8, 8)
stBar.BorderSizePixel  = 0
local stLbl = Instance.new("TextLabel", stBar)
stLbl.Size              = UDim2.new(1,-8,1,0)
stLbl.Position          = UDim2.new(0,8,0,0)
stLbl.BackgroundTransparency = 1
stLbl.Text              = "● Idle"
stLbl.TextColor3        = Color3.fromRGB(255,190,190)
stLbl.Font              = Enum.Font.Gotham
stLbl.TextSize          = 10
stLbl.TextXAlignment    = Enum.TextXAlignment.Left

-- ══════════════════════════════════════
--  COMPONENT BUILDERS
-- ══════════════════════════════════════
local toggleRefs = {}

local function divider(label)
    local f = Instance.new("Frame", scroll)
    f.Size             = UDim2.new(0, 240, 0, 18)
    f.BackgroundTransparency = 1
    local l = Instance.new("TextLabel", f)
    l.Size              = UDim2.new(1,0,1,0)
    l.BackgroundTransparency = 1
    l.Text              = label
    l.TextColor3        = Color3.fromRGB(180, 28, 28)
    l.Font              = Enum.Font.GothamBold
    l.TextSize          = 10
    l.TextXAlignment    = Enum.TextXAlignment.Left
end

local function toggle(icon, label, key, callback)
    local btn = Instance.new("TextButton", scroll)
    btn.Size             = UDim2.new(0, 240, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    btn.Text             = ""
    btn.AutoButtonColor  = false
    btn.BorderSizePixel  = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color     = Color3.fromRGB(30, 30, 46)
    stroke.Thickness = 1

    local ic = Instance.new("TextLabel", btn)
    ic.Size              = UDim2.new(0, 32, 1, 0)
    ic.BackgroundTransparency = 1
    ic.Text              = icon
    ic.TextSize          = 14
    ic.Font              = Enum.Font.GothamBold
    ic.TextXAlignment    = Enum.TextXAlignment.Center

    local lbl = Instance.new("TextLabel", btn)
    lbl.Size             = UDim2.new(1, -78, 1, 0)
    lbl.Position         = UDim2.new(0, 32, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text             = label
    lbl.TextColor3       = Color3.fromRGB(200, 200, 210)
    lbl.Font             = Enum.Font.GothamBold
    lbl.TextSize         = 11
    lbl.TextXAlignment   = Enum.TextXAlignment.Left

    -- Pill
    local pill = Instance.new("Frame", btn)
    pill.Size             = UDim2.new(0, 36, 0, 18)
    pill.Position         = UDim2.new(1, -42, 0.5, -9)
    pill.BackgroundColor3 = Color3.fromRGB(28, 28, 44)
    pill.BorderSizePixel  = 0
    Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 4)
    local pillTxt = Instance.new("TextLabel", pill)
    pillTxt.Size              = UDim2.new(1,0,1,0)
    pillTxt.BackgroundTransparency = 1
    pillTxt.Text              = "OFF"
    pillTxt.TextColor3        = Color3.fromRGB(100,100,130)
    pillTxt.Font              = Enum.Font.GothamBold
    pillTxt.TextSize          = 9

    local function refresh(anim)
        local on = T[key]
        local bg   = on and Color3.fromRGB(30,5,5)   or Color3.fromRGB(18,18,26)
        local brd  = on and Color3.fromRGB(155,15,15) or Color3.fromRGB(30,30,46)
        local tc   = on and Color3.fromRGB(255,175,175) or Color3.fromRGB(200,200,210)
        local pb   = on and Color3.fromRGB(120,8,8)  or Color3.fromRGB(28,28,44)
        local pt   = on and Color3.new(1,1,1)         or Color3.fromRGB(100,100,130)
        if anim then
            local ti = TweenInfo.new(0.14)
            TweenService:Create(btn,   ti, {BackgroundColor3=bg}):Play()
            TweenService:Create(stroke,ti, {Color=brd}):Play()
            TweenService:Create(lbl,   ti, {TextColor3=tc}):Play()
            TweenService:Create(pill,  ti, {BackgroundColor3=pb}):Play()
            TweenService:Create(pillTxt,ti,{TextColor3=pt}):Play()
        else
            btn.BackgroundColor3  = bg
            stroke.Color          = brd
            lbl.TextColor3        = tc
            pill.BackgroundColor3 = pb
            pillTxt.TextColor3    = pt
        end
        pillTxt.Text = on and "ON" or "OFF"
    end

    btn.MouseButton1Click:Connect(function()
        T[key] = not T[key]
        refresh(true)
        if callback then task.spawn(callback, T[key]) end
    end)

    toggleRefs[key] = function() refresh(false) end
    refresh(false)
end

local function sliderRow(label, min, max, default, fmt, onChange)
    local f = Instance.new("Frame", scroll)
    f.Size             = UDim2.new(0, 240, 0, 44)
    f.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    f.BorderSizePixel  = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 7)
    Instance.new("UIStroke", f).Color = Color3.fromRGB(30,30,46)

    local lbl = Instance.new("TextLabel", f)
    lbl.Size              = UDim2.new(1,-10,0,20)
    lbl.Position          = UDim2.new(0,10,0,3)
    lbl.BackgroundTransparency = 1
    lbl.Text              = string.format(label..":  "..fmt, default)
    lbl.TextColor3        = Color3.fromRGB(195,195,205)
    lbl.Font              = Enum.Font.Gotham
    lbl.TextSize          = 10
    lbl.TextXAlignment    = Enum.TextXAlignment.Left

    local track = Instance.new("Frame", f)
    track.Size             = UDim2.new(1,-20,0,5)
    track.Position         = UDim2.new(0,10,1,-12)
    track.BackgroundColor3 = Color3.fromRGB(28,16,32)
    track.BorderSizePixel  = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(0,3)

    local p0 = math.clamp((default-min)/(max-min),0,1)
    local fill = Instance.new("Frame", track)
    fill.Size             = UDim2.new(p0,0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(165,16,16)
    fill.BorderSizePixel  = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0,3)

    local knob = Instance.new("TextButton", track)
    knob.Size             = UDim2.new(0,12,0,12)
    knob.AnchorPoint      = Vector2.new(0.5,0.5)
    knob.Position         = UDim2.new(p0,0,0.5,0)
    knob.BackgroundColor3 = Color3.fromRGB(210,30,30)
    knob.Text             = ""
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 4
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    local dragging = false
    knob.MouseButton1Down:Connect(function() dragging=true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not dragging or i.UserInputType~=Enum.UserInputType.MouseMovement then return end
        local p = math.clamp((i.Position.X - track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local v = min + p*(max-min)
        fill.Size     = UDim2.new(p,0,1,0)
        knob.Position = UDim2.new(p,0,0.5,0)
        lbl.Text      = string.format(label..":  "..fmt, v)
        if onChange then onChange(v) end
    end)
end

-- ══════════════════════════════════════
--  POPULATE GUI
-- ══════════════════════════════════════
divider("  ⚔  MISSIONS")
toggle("🗡", "Farm Blades",       "FarmBlade",   function(on) if on then farmLoop("mission","blade") end end)
toggle("💥", "Farm Thunderspears","FarmTS",       function(on) if on then farmLoop("mission","ts")    end end)

divider("  ⚡  AUTOMATION")
toggle("🔗", "Auto Connect",  "AutoConnect", function(on)
    if not on or loopGuard["AutoConnect"] then return end
    loopGuard["AutoConnect"] = true
    task.spawn(function()
        while T.AutoConnect do
            if not inMission() then joinGame("mission"); task.wait(6) end
            task.wait(2)
        end
        loopGuard["AutoConnect"] = nil
    end)
end)
toggle("🚪", "Auto Leave",    "AutoLeave")
toggle("🔥", "Auto Streak",   "AutoStreak")

divider("  🛡  UTILITY")
toggle("🪂", "Auto Eject",  "AutoEject")
toggle("💤", "Anti-AFK",    "AntiAFK", function(on)
    if not on or loopGuard["AntiAFK"] then return end
    loopGuard["AntiAFK"] = true
    task.spawn(function()
        while T.AntiAFK do
            local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local c = hrp.CFrame
                hrp.CFrame = c * CFrame.new(0.1,0,0)
                task.wait(0.1)
                hrp.CFrame = c
            end
            task.wait(55)
        end
        loopGuard["AntiAFK"] = nil
    end)
end)

divider("  ⚙  SETTINGS")
sliderRow("Kill Delay",  0, 10, CFG.KILL_DELAY,     "%.1fs", function(v) CFG.KILL_DELAY     = v end)
sliderRow("Max Kills",   1, 500,CFG.MAX_KILLS,       "%.0f",  function(v) CFG.MAX_KILLS      = v end)
sliderRow("Boss HP %",   0, 1,  CFG.BOSS_HP_CUTOFF, "%.0f%%",function(v) CFG.BOSS_HP_CUTOFF = v end)
sliderRow("Streak At",   1, 50, CFG.STREAK_TARGET,  "%.0f",  function(v) CFG.STREAK_TARGET  = v end)

-- Pos buttons
local posRow = Instance.new("Frame", scroll)
posRow.Size             = UDim2.new(0, 240, 0, 38)
posRow.BackgroundColor3 = Color3.fromRGB(18,18,26)
posRow.BorderSizePixel  = 0
Instance.new("UICorner", posRow).CornerRadius = UDim.new(0,7)
Instance.new("UIStroke", posRow).Color = Color3.fromRGB(30,30,46)
local posLbl = Instance.new("TextLabel", posRow)
posLbl.Size              = UDim2.new(0,80,1,0)
posLbl.Position          = UDim2.new(0,8,0,0)
posLbl.BackgroundTransparency = 1
posLbl.Text              = "📍 Position"
posLbl.TextColor3        = Color3.fromRGB(195,195,205)
posLbl.Font              = Enum.Font.GothamBold
posLbl.TextSize          = 10
posLbl.TextXAlignment    = Enum.TextXAlignment.Left
local posButtons = {}
local posModes = {"Above","Behind"}
for i, m in ipairs(posModes) do
    local b = Instance.new("TextButton", posRow)
    b.Size             = UDim2.new(0, 66, 0, 24)
    b.Position         = UDim2.new(0, 80 + (i-1)*72, 0.5, -12)
    b.BackgroundColor3 = CFG.POSITION_MODE==m and Color3.fromRGB(120,8,8) or Color3.fromRGB(28,16,32)
    b.Text             = m
    b.TextColor3       = Color3.new(1,1,1)
    b.Font             = Enum.Font.GothamBold
    b.TextSize         = 10
    b.BorderSizePixel  = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,5)
    posButtons[m] = b
    b.MouseButton1Click:Connect(function()
        CFG.POSITION_MODE = m
        for _, bm in ipairs(posModes) do
            TweenService:Create(posButtons[bm], TweenInfo.new(0.12), {
                BackgroundColor3 = bm==m and Color3.fromRGB(120,8,8) or Color3.fromRGB(28,16,32)
            }):Play()
        end
    end)
end

-- ══════════════════════════════════════
--  HEARTBEAT
-- ══════════════════════════════════════
local lastEjectTime = 0

RunService.Heartbeat:Connect(function()
    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    local now = tick()

    -- Auto Eject
    if T.AutoEject and hum.Health > 0 and now - lastEjectTime > 0.3 then
        local grabbed = hum:GetState() == Enum.HumanoidStateType.Physics
        if not grabbed then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BoolValue") and v.Value then
                    local n = v.Name:lower()
                    if n:find("grab") or n:find("caught") or n:find("held") then
                        grabbed = true; break
                    end
                end
            end
        end
        if grabbed then
            fireKw({"escape","eject","free","break","release"})
            hrp.CFrame = hrp.CFrame * CFrame.new(math.random(-12,12), 10, math.random(-12,12))
            lastEjectTime = now
        end
    end

    -- Stats label
    statsLbl.Text = string.format("⚔ %d   🎮 %d   🔥 %d streak", stats.kills, stats.missions, stats.streak)

    -- Status
    local active = {}
    for k, v in pairs(T) do if v then table.insert(active, k) end end
    stLbl.Text = #active > 0 and "● " .. table.concat(active, " · ") or "● Idle"
end)

warn("✅ AoTR Farm v3.0 loaded!")
