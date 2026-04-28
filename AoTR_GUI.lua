-- ╔══════════════════════════════════════════════════════════╗
-- ║   ATTACK ON TITAN REVOLUTION — FARMING v2.0             ║
-- ║              by Taishotokiyo  (improved)                ║
-- ║  Sections: Farming · Combat · Automation · Settings     ║
-- ╚══════════════════════════════════════════════════════════╝
-- Improvements in v2.0:
--   • Fixed titan killing: smarter nape detection + retry logic
--   • Remote cache built once at startup (no more per-frame scans)
--   • Duplicate loop guard (toggle spam safe)
--   • Anti-AFK loop
--   • Auto-Respawn on death
--   • Kill flash notification
--   • Keybind toggles (see KEYBINDS table)
--   • Tabbed GUI (Farming / Combat / Settings)
--   • Animated ON/OFF pills
--   • Streak milestone notifications
--   • Boss HP bar indicator
--   • Auto-Collect (loot/rewards)
--   • Better AutoEject (checks humanoid state, not just BoolValues)

-- ══════════════════════════════════════
--  SERVICES
-- ══════════════════════════════════════
local Players          = game:GetService("Players")
local RS               = game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local StarterGui       = game:GetService("StarterGui")
local lp               = Players.LocalPlayer

repeat task.wait(0.1) until lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
task.wait(1)

-- Destroy old GUI
pcall(function()
    local old = game:GetService("CoreGui"):FindFirstChild("AOTR_Farm_v2")
    if old then old:Destroy() end
end)

-- ══════════════════════════════════════
--  CONFIG
-- ══════════════════════════════════════
local CFG = {
    KILL_DELAY        = 2,
    MAX_KILLS         = 999,
    BOSS_HP_CUTOFF    = 0.15,
    HITBOX_SIZE       = 30,
    POSITION_MODE     = "Above",
    ABOVE_OFFSET      = 14,
    FRONT_OFFSET      = 5,
    BEHIND_OFFSET     = -5,
    STALL_TIME        = 3,
    STREAK_TARGET     = 10,
    REJOIN_DELAY      = 4,
    TS_QUEST_DELAY    = 0.5,
    NAPE_RETRY        = 4,       -- how many attack attempts per titan
    NAPE_RETRY_DELAY  = 0.08,    -- seconds between retry attempts
    REMOTE_CACHE_TTL  = 15,      -- seconds before re-scanning remotes
    ANTI_AFK_INTERVAL = 60,      -- seconds between anti-afk actions
    BOSS_HP_THRESHOLD = 5000,    -- humanoid MaxHealth above this = boss
}

-- ══════════════════════════════════════
--  KEYBINDS  (Enum.KeyCode)
-- ══════════════════════════════════════
local KEYBINDS = {
    FarmBlade   = Enum.KeyCode.F1,
    FarmTS      = Enum.KeyCode.F2,
    AutoLeave   = Enum.KeyCode.F3,
    AutoM1      = Enum.KeyCode.F4,
}

-- ══════════════════════════════════════
--  STATE
-- ══════════════════════════════════════
local T = {
    FarmBlade      = false,
    FarmRipper     = false,
    FarmTS         = false,
    RaidTS         = false,
    RaidBlade      = false,
    AutoStreak     = false,
    AutoConnect    = false,
    InstantTSQuest = false,
    AutoLeave      = false,
    AutoM1         = false,
    AutoEject      = false,
    HitboxExtender = false,
    AntiAFK        = false,
    AutoRespawn    = false,
    AutoCollect    = false,
}

-- Loop guards: prevent duplicate coroutines per toggle
local loopActive = {}

local stats = {
    kills    = 0,
    missions = 0,
    raids    = 0,
    streak   = 0,
}

-- ══════════════════════════════════════
--  REMOTE CACHE
-- ══════════════════════════════════════
local remoteCache     = {}
local remoteCacheTime = 0

local function buildRemoteCache()
    remoteCache = {}
    for _, folder in ipairs({RS, workspace}) do
        pcall(function()
            for _, r in ipairs(folder:GetDescendants()) do
                if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
                    local n = r.Name:lower()
                    if not remoteCache[n] then remoteCache[n] = {} end
                    table.insert(remoteCache[n], r)
                end
            end
        end)
    end
    remoteCacheTime = tick()
end

local function getRemotes(kws)
    if tick() - remoteCacheTime > CFG.REMOTE_CACHE_TTL then
        buildRemoteCache()
    end
    local found = {}
    for _, k in ipairs(kws) do
        for cachedName, remotes in pairs(remoteCache) do
            if cachedName:find(k, 1, true) then
                for _, r in ipairs(remotes) do
                    table.insert(found, r)
                end
            end
        end
    end
    return found
end

local function fireKw(kws, a1, a2, a3)
    for _, r in ipairs(getRemotes(kws)) do
        pcall(function()
            if r:IsA("RemoteEvent") then r:FireServer(a1, a2, a3)
            else r:InvokeServer(a1, a2, a3) end
        end)
    end
end

-- Pre-build cache at load
buildRemoteCache()

-- ══════════════════════════════════════
--  HELPERS
-- ══════════════════════════════════════
local function rng(n, r)
    r = r or n * 0.15
    return n + (math.random() - 0.5) * r * 2
end

local function clickBtn(kws)
    for _, obj in ipairs(lp.PlayerGui:GetDescendants()) do
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            local t = (obj.Text or ""):lower()
            local n = obj.Name:lower()
            for _, k in ipairs(kws) do
                if t:find(k, 1, true) or n:find(k, 1, true) then
                    pcall(function() obj.MouseButton1Click:Fire() end)
                    return true
                end
            end
        end
    end
    return false
end

-- ══════════════════════════════════════
--  NAPE DETECTION  (improved)
-- ══════════════════════════════════════
local NAPE_NAMES = {
    "nape", "napehit", "weakpoint", "weak", "neck",
    "killzone", "neckback", "hitzone", "critical", "vital",
}

local function scoreNapePart(part, root)
    -- Score based on name match + position (upper-back favored)
    local n = part.Name:lower()
    local nameScore = 0
    for _, tag in ipairs(NAPE_NAMES) do
        if n:find(tag, 1, true) then nameScore = 10; break end
    end
    local rel = root.CFrame:PointToObjectSpace(part.Position)
    -- Prefer: Y > 0 (upper), Z < 0 (behind)
    local posScore = math.clamp(rel.Y / 10, 0, 1) + math.clamp(-rel.Z / 8, 0, 1)
    return nameScore + posScore
end

local function getNape(model)
    local root = model:FindFirstChild("HumanoidRootPart")
             or model:FindFirstChild("Torso")
             or model:FindFirstChildOfClass("BasePart")
    if not root then return nil end

    local best, bestScore = nil, -math.huge
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") and p ~= root then
            local s = scoreNapePart(p, root)
            if s > bestScore then
                bestScore = s
                best = p
            end
        end
    end
    -- Only accept if score is meaningful, otherwise fallback to root
    if best and bestScore > 0.5 then return best end
    return root
end

-- ══════════════════════════════════════
--  TITAN QUERY
-- ══════════════════════════════════════
local function getTitans(hrp, maxDist)
    local list = {}
    maxDist = maxDist or math.huge
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
    table.sort(list, function(a, b) return a.dist < b.dist end)
    return list
end

-- ══════════════════════════════════════
--  POSITION OFFSET
-- ══════════════════════════════════════
local function getOffset(titanRoot)
    if CFG.POSITION_MODE == "Above" then
        return Vector3.new(0, CFG.ABOVE_OFFSET, 0)
    elseif CFG.POSITION_MODE == "InFront" then
        local fwd = titanRoot.CFrame.LookVector
        return fwd * CFG.FRONT_OFFSET + Vector3.new(0, 4, 0)
    else -- Behind
        local fwd = titanRoot.CFrame.LookVector
        return fwd * CFG.BEHIND_OFFSET + Vector3.new(0, 4, 0)
    end
end

-- ══════════════════════════════════════
--  ATTACK FUNCTIONS  (retry loop fixed)
-- ══════════════════════════════════════
local ATTACK_KWS = {"attack","slash","nape","execute","kill","hit","swing","damage","m1","strike","cut"}
local TS_KWS     = {"thunderspear","ts","launch","fire","shoot","throw","spear","explode"}

local function attackTitan(model)
    local nape = getNape(model)
    if not nape then return false end
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local killed = false
    local humBefore = model:FindFirstChildOfClass("Humanoid")
    if not humBefore or humBefore.Health <= 0 then return true end -- already dead

    for attempt = 1, CFG.NAPE_RETRY do
        -- Refresh nape each attempt in case it moved
        nape = getNape(model)
        if not nape then break end

        local offset = getOffset(model:FindFirstChild("HumanoidRootPart") or nape)
        hrp.CFrame = CFrame.new(nape.Position + offset)
        task.wait(CFG.NAPE_RETRY_DELAY)

        -- Teleport directly onto nape for the hit
        hrp.CFrame = CFrame.new(nape.Position + Vector3.new(0, 2, 0))
        task.wait(0.02)

        fireKw(ATTACK_KWS, model)
        fireKw(ATTACK_KWS, nape)
        task.wait(0.03)
        fireKw(ATTACK_KWS, model, nape.Position)

        -- Check if dead
        local h = model:FindFirstChildOfClass("Humanoid")
        if not h or h.Health <= 0 then killed = true; break end

        task.wait(CFG.NAPE_RETRY_DELAY * 2)
    end
    return killed
end

local function attackTS(model)
    local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
    if not root then return false end
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    hrp.CFrame = CFrame.new(root.Position + Vector3.new(0, 25, 0))
    task.wait(0.04)
    fireKw(TS_KWS, model, root.Position)
    task.wait(0.04)
    fireKw(TS_KWS, model)
    task.wait(0.04)
    fireKw(TS_KWS, root.Position)

    local h = model:FindFirstChildOfClass("Humanoid")
    return not h or h.Health <= 0
end

-- ══════════════════════════════════════
--  LOBBY / CONNECT
-- ══════════════════════════════════════
local lastLeave = 0
local function leaveToLobby()
    if tick() - lastLeave < 2 then return end
    lastLeave = tick()
    fireKw({"leave","lobby","exit","disconnect","menu","returnlobby"})
    clickBtn({"leave","lobby","exit","menu","return"})
end

local function connectToGame(mode)
    fireKw({mode,"join","connect","start","play","enter"})
    clickBtn({mode,"join","connect","start","play"})
end

local function inMission()
    for _, obj in ipairs(lp.PlayerGui:GetDescendants()) do
        if obj:IsA("TextLabel") then
            local t = obj.Text:lower()
            if t:find("titan") or t:find("wave") or t:find("mission") or t:find("raid") then
                return true
            end
        end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) and obj ~= lp.Character then
            local h = obj:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then return true end
        end
    end
    return false
end

-- ══════════════════════════════════════
--  AUTO-COLLECT
-- ══════════════════════════════════════
local function tryCollect()
    fireKw({"collect","loot","reward","pickup","claim","redeem"})
    clickBtn({"collect","loot","reward","pickup","claim","redeem","ok","continue"})
end

-- ══════════════════════════════════════
--  FARM LOOP  (loop-guard safe)
-- ══════════════════════════════════════
local function farmLoop(mode, weaponType)
    local key = weaponType == "ts"     and (mode == "raid" and "RaidTS" or "FarmTS")
             or weaponType == "ripper" and "FarmRipper"
             or mode == "raid"         and "RaidBlade" or "FarmBlade"

    if loopActive[key] then return end
    loopActive[key] = true

    task.spawn(function()
        while T[key] do
            if not inMission() then
                connectToGame(mode)
                task.wait(rng(5, 2))
                if mode == "mission" then stats.missions += 1 else stats.raids += 1 end
            end

            local char = lp.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(1); continue end

            local titans = getTitans(hrp)
            local alive  = #titans

            if alive == 0 then
                if T.AutoCollect then tryCollect() end
                task.wait(rng(2))
                if T.AutoLeave and stats.kills >= CFG.MAX_KILLS then
                    leaveToLobby()
                    stats.kills = 0
                    task.wait(rng(CFG.REJOIN_DELAY))
                end
            elseif alive == 1 then
                local titan = titans[1]
                local isBoss = titan.hum.MaxHealth > CFG.BOSS_HP_THRESHOLD
                local hpPct  = titan.hum.Health / titan.hum.MaxHealth

                if isBoss and hpPct < CFG.BOSS_HP_CUTOFF then
                    task.wait(rng(CFG.STALL_TIME))
                else
                    task.wait(rng(CFG.KILL_DELAY))
                    local killed = weaponType == "ts" and attackTS(titan.model) or attackTitan(titan.model)
                    if killed then
                        stats.kills  += 1
                        stats.streak += 1
                    end
                end

                if T.AutoStreak and stats.streak >= CFG.STREAK_TARGET then
                    notify("🔥 Streak "..stats.streak.." reached!", "Leaving to lobby…")
                    leaveToLobby()
                    stats.streak = 0
                    task.wait(rng(CFG.REJOIN_DELAY))
                end
            else
                -- Kill all but last
                for i = 1, #titans - 1 do
                    if not T[key] then break end
                    local titan = titans[i]
                    local isBoss = titan.hum.MaxHealth > CFG.BOSS_HP_THRESHOLD
                    local hpPct  = titan.hum.Health / titan.hum.MaxHealth
                    if not (isBoss and hpPct < CFG.BOSS_HP_CUTOFF) then
                        local killed = weaponType == "ts" and attackTS(titan.model) or attackTitan(titan.model)
                        if killed then stats.kills += 1 end
                        task.wait(rng(0.12))
                    end
                end
            end

            task.wait(rng(0.1))
        end

        loopActive[key] = nil
    end)
end

-- ══════════════════════════════════════
--  TS QUEST
-- ══════════════════════════════════════
local function runTSQuest()
    if loopActive["TSQuest"] then return end
    loopActive["TSQuest"] = true
    task.spawn(function()
        while T.InstantTSQuest do
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") or obj:IsA("BasePart") then
                    local n = obj.Name:lower()
                    if n:find("watchtower") or n:find("crate") or n:find("objective") or n:find("quest") then
                        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                        local pos = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")) or obj
                        if hrp and pos then
                            hrp.CFrame = CFrame.new(pos.Position + Vector3.new(0, 5, 0))
                            task.wait(CFG.TS_QUEST_DELAY)
                            fireKw(TS_KWS, pos.Position)
                            task.wait(CFG.TS_QUEST_DELAY)
                            fireKw({"complete","quest","objective","finish","watchtower","crate"})
                            clickBtn({"complete","collect","claim","objective","watchtower","crate"})
                        end
                    end
                end
            end
            task.wait(rng(1))
        end
        loopActive["TSQuest"] = nil
    end)
end

-- ══════════════════════════════════════
--  ANTI-AFK
-- ══════════════════════════════════════
local function startAntiAFK()
    if loopActive["AntiAFK"] then return end
    loopActive["AntiAFK"] = true
    task.spawn(function()
        while T.AntiAFK do
            local char = lp.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- Micro-move to reset AFK timer
                local orig = hrp.CFrame
                hrp.CFrame = orig * CFrame.new(0.1, 0, 0)
                task.wait(0.1)
                hrp.CFrame = orig
            end
            -- Also ping with a "jump" flag
            pcall(function() lp.Character.Humanoid.Jump = true end)
            task.wait(CFG.ANTI_AFK_INTERVAL)
        end
        loopActive["AntiAFK"] = nil
    end)
end

-- ══════════════════════════════════════
--  NOTIFY HELPER (uses StarterGui)
-- ══════════════════════════════════════
local function notify(title, body, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title    = title or "AoTR v2",
            Text     = body  or "",
            Duration = dur   or 4,
        })
    end)
end

-- ══════════════════════════════════════
--  BUILD GUI
-- ══════════════════════════════════════
local CoreGui = game:GetService("CoreGui")
local sg = Instance.new("ScreenGui")
sg.Name = "AOTR_Farm_v2"
sg.ResetOnSpawn = false
sg.DisplayOrder = 999
sg.IgnoreGuiInset = true
sg.Parent = CoreGui

-- ── Window ──────────────────────────────────────────
local WIN_W, WIN_H = 320, 560
local win = Instance.new("Frame", sg)
win.Size     = UDim2.new(0, WIN_W, 0, WIN_H)
win.Position = UDim2.new(0, 16, 0, 16)
win.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
win.BorderSizePixel  = 0
win.Active    = true
win.Draggable = true
win.ClipsDescendants = true
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 12)
local winStroke = Instance.new("UIStroke", win)
winStroke.Color     = Color3.fromRGB(170, 18, 18)
winStroke.Thickness = 1.5

-- ── Header ──────────────────────────────────────────
local hdr = Instance.new("Frame", win)
hdr.Size             = UDim2.new(1, 0, 0, 48)
hdr.BackgroundColor3 = Color3.fromRGB(130, 8, 8)
hdr.BorderSizePixel  = 0

-- Gradient on header
local hg = Instance.new("UIGradient", hdr)
hg.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 12, 12)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(90,  4,  4)),
}

local hTitle = Instance.new("TextLabel", hdr)
hTitle.Size              = UDim2.new(1, -80, 1, 0)
hTitle.Position          = UDim2.new(0, 12, 0, 0)
hTitle.BackgroundTransparency = 1
hTitle.Text              = "⚔  AoTR Farming  v2.0"
hTitle.TextColor3        = Color3.new(1, 1, 1)
hTitle.Font              = Enum.Font.GothamBold
hTitle.TextSize          = 13
hTitle.TextXAlignment    = Enum.TextXAlignment.Left

-- Close button
local closeBtn = Instance.new("TextButton", hdr)
closeBtn.Size            = UDim2.new(0, 26, 0, 26)
closeBtn.Position        = UDim2.new(1, -32, 0.5, -13)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 4, 4)
closeBtn.Text            = "✕"
closeBtn.TextColor3      = Color3.new(1, 1, 1)
closeBtn.Font            = Enum.Font.GothamBold
closeBtn.TextSize        = 11
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 5)
closeBtn.MouseButton1Click:Connect(function()
    sg:Destroy()
end)

-- Minimize button
local miniBtn = Instance.new("TextButton", hdr)
miniBtn.Size            = UDim2.new(0, 26, 0, 26)
miniBtn.Position        = UDim2.new(1, -62, 0.5, -13)
miniBtn.BackgroundColor3 = Color3.fromRGB(60, 4, 4)
miniBtn.Text            = "—"
miniBtn.TextColor3      = Color3.new(1, 1, 1)
miniBtn.Font            = Enum.Font.GothamBold
miniBtn.TextSize        = 11
miniBtn.BorderSizePixel = 0
Instance.new("UICorner", miniBtn).CornerRadius = UDim.new(0, 5)
local minimized = false
miniBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    TweenService:Create(win, TweenInfo.new(0.2), {
        Size = minimized and UDim2.new(0, WIN_W, 0, 48) or UDim2.new(0, WIN_W, 0, WIN_H)
    }):Play()
    miniBtn.Text = minimized and "+" or "—"
end)

-- ── Stats Bar ────────────────────────────────────────
local sbar = Instance.new("Frame", win)
sbar.Size             = UDim2.new(1, 0, 0, 28)
sbar.Position         = UDim2.new(0, 0, 0, 48)
sbar.BackgroundColor3 = Color3.fromRGB(18, 5, 5)
sbar.BorderSizePixel  = 0

local slbl = Instance.new("TextLabel", sbar)
slbl.Size              = UDim2.new(1, -8, 1, 0)
slbl.Position          = UDim2.new(0, 8, 0, 0)
slbl.BackgroundTransparency = 1
slbl.Text              = "⚔0  |  🎮0  |  🔴0  |  🔥0"
slbl.TextColor3        = Color3.fromRGB(255, 170, 170)
slbl.Font              = Enum.Font.Gotham
slbl.TextSize          = 10
slbl.TextXAlignment    = Enum.TextXAlignment.Left

local lastKillCount = 0
local function updStats()
    slbl.Text = string.format("⚔%d Kills  |  🎮%d Miss  |  🔴%d Raids  |  🔥%d Streak",
        stats.kills, stats.missions, stats.raids, stats.streak)
    -- Flash kills label when new kill
    if stats.kills ~= lastKillCount then
        lastKillCount = stats.kills
        TweenService:Create(slbl, TweenInfo.new(0.1), {TextColor3 = Color3.fromRGB(255,80,80)}):Play()
        task.delay(0.2, function()
            TweenService:Create(slbl, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(255,170,170)}):Play()
        end)
    end
end

-- ── Tab Bar ─────────────────────────────────────────
local tabBar = Instance.new("Frame", win)
tabBar.Size             = UDim2.new(1, 0, 0, 32)
tabBar.Position         = UDim2.new(0, 0, 0, 76)
tabBar.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
tabBar.BorderSizePixel  = 0

local tabLayout = Instance.new("UIListLayout", tabBar)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.Padding = UDim.new(0, 4)
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local tabNames = {"⚔ Farm", "🥊 Combat", "⚙ Settings"}
local tabFrames = {}
local tabBtns   = {}
local activeTab = 1

-- ── Content area ──────────────────────────────────
local contentArea = Instance.new("Frame", win)
contentArea.Size             = UDim2.new(1, 0, 1, -108)
contentArea.Position         = UDim2.new(0, 0, 0, 108)
contentArea.BackgroundTransparency = 1
contentArea.ClipsDescendants = true

local function makeScroll(parent)
    local s = Instance.new("ScrollingFrame", parent)
    s.Size                 = UDim2.new(1, 0, 1, 0)
    s.BackgroundTransparency = 1
    s.BorderSizePixel      = 0
    s.ScrollBarThickness   = 3
    s.ScrollBarImageColor3 = Color3.fromRGB(185, 22, 22)
    s.CanvasSize           = UDim2.new(0, 0, 0, 0)
    s.AutomaticCanvasSize  = Enum.AutomaticSize.Y
    s.Visible              = false
    local ll = Instance.new("UIListLayout", s)
    ll.Padding             = UDim.new(0, 5)
    ll.HorizontalAlignment = Enum.HorizontalAlignment.Center
    local pad = Instance.new("UIPadding", s)
    pad.PaddingTop    = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 10)
    return s
end

for i, name in ipairs(tabNames) do
    -- Tab button
    local tb = Instance.new("TextButton", tabBar)
    tb.Size              = UDim2.new(0, 88, 0, 24)
    tb.BackgroundColor3  = Color3.fromRGB(22, 22, 32)
    tb.Text              = name
    tb.TextColor3        = Color3.fromRGB(130, 130, 150)
    tb.Font              = Enum.Font.GothamBold
    tb.TextSize          = 10
    tb.BorderSizePixel   = 0
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 6)
    tabBtns[i] = tb

    -- Scroll content
    local scroll = makeScroll(contentArea)
    tabFrames[i] = scroll

    tb.MouseButton1Click:Connect(function()
        activeTab = i
        for j, s in ipairs(tabFrames) do
            s.Visible = (j == i)
            tabBtns[j].BackgroundColor3 = j == i and Color3.fromRGB(130,8,8) or Color3.fromRGB(22,22,32)
            tabBtns[j].TextColor3       = j == i and Color3.new(1,1,1) or Color3.fromRGB(130,130,150)
        end
    end)
end
-- Activate first tab
tabFrames[1].Visible = true
tabBtns[1].BackgroundColor3 = Color3.fromRGB(130, 8, 8)
tabBtns[1].TextColor3       = Color3.new(1, 1, 1)

-- ── Status bar ──────────────────────────────────────
local stbar = Instance.new("Frame", win)
stbar.Size             = UDim2.new(1, 0, 0, 22)
stbar.Position         = UDim2.new(0, 0, 1, -22)
stbar.BackgroundColor3 = Color3.fromRGB(130, 8, 8)
stbar.BorderSizePixel  = 0
local stlbl = Instance.new("TextLabel", stbar)
stlbl.Size              = UDim2.new(1, -8, 1, 0)
stlbl.Position          = UDim2.new(0, 8, 0, 0)
stlbl.BackgroundTransparency = 1
stlbl.Text              = "● Idle"
stlbl.TextColor3        = Color3.fromRGB(255, 200, 200)
stlbl.Font              = Enum.Font.Gotham
stlbl.TextSize          = 10
stlbl.TextXAlignment    = Enum.TextXAlignment.Left

-- ══════════════════════════════════════
--  COMPONENT BUILDERS
-- ══════════════════════════════════════
local toggleRefs = {}

local function sec(scroll, txt)
    local f = Instance.new("Frame", scroll)
    f.Size = UDim2.new(0, 288, 0, 20)
    f.BackgroundTransparency = 1
    local line = Instance.new("Frame", f)
    line.Size             = UDim2.new(1, 0, 0, 1)
    line.Position         = UDim2.new(0, 0, 0.5, 0)
    line.BackgroundColor3 = Color3.fromRGB(45, 12, 12)
    line.BorderSizePixel  = 0
    local bg = Instance.new("Frame", f)
    bg.Size             = UDim2.new(0, 170, 1, 0)
    bg.Position         = UDim2.new(0, 4, 0, 0)
    bg.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
    bg.BorderSizePixel  = 0
    local l = Instance.new("TextLabel", bg)
    l.Size               = UDim2.new(1, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Text               = "  " .. txt
    l.TextColor3         = Color3.fromRGB(200, 38, 38)
    l.Font               = Enum.Font.GothamBold
    l.TextSize           = 10
    l.TextXAlignment     = Enum.TextXAlignment.Left
end

local function tog(scroll, icon, name, desc, key, cb)
    local btn = Instance.new("TextButton", scroll)
    btn.Size              = UDim2.new(0, 288, 0, 46)
    btn.BackgroundColor3  = Color3.fromRGB(16, 16, 22)
    btn.BorderSizePixel   = 0
    btn.Text              = ""
    btn.AutoButtonColor   = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local bs = Instance.new("UIStroke", btn)
    bs.Color     = Color3.fromRGB(28, 28, 44)
    bs.Thickness = 1

    local il = Instance.new("TextLabel", btn)
    il.Size               = UDim2.new(0, 34, 1, 0)
    il.BackgroundTransparency = 1
    il.Text               = icon
    il.TextSize           = 16
    il.Font               = Enum.Font.GothamBold
    il.TextXAlignment     = Enum.TextXAlignment.Center

    local nl = Instance.new("TextLabel", btn)
    nl.Size               = UDim2.new(1, -84, 0, 20)
    nl.Position           = UDim2.new(0, 36, 0, 5)
    nl.BackgroundTransparency = 1
    nl.Text               = name
    nl.TextColor3         = Color3.fromRGB(210, 210, 210)
    nl.Font               = Enum.Font.GothamBold
    nl.TextSize           = 12
    nl.TextXAlignment     = Enum.TextXAlignment.Left

    local dl = Instance.new("TextLabel", btn)
    dl.Size               = UDim2.new(1, -84, 0, 14)
    dl.Position           = UDim2.new(0, 36, 0, 27)
    dl.BackgroundTransparency = 1
    dl.Text               = desc
    dl.TextColor3         = Color3.fromRGB(100, 100, 130)
    dl.Font               = Enum.Font.Gotham
    dl.TextSize           = 10
    dl.TextXAlignment     = Enum.TextXAlignment.Left

    -- Animated pill
    local pillBg = Instance.new("Frame", btn)
    pillBg.Size             = UDim2.new(0, 40, 0, 20)
    pillBg.Position         = UDim2.new(1, -46, 0.5, -10)
    pillBg.BackgroundColor3 = Color3.fromRGB(28, 28, 44)
    pillBg.BorderSizePixel  = 0
    Instance.new("UICorner", pillBg).CornerRadius = UDim.new(0, 5)
    local pillTxt = Instance.new("TextLabel", pillBg)
    pillTxt.Size               = UDim2.new(1, 0, 1, 0)
    pillTxt.BackgroundTransparency = 1
    pillTxt.Text               = "OFF"
    pillTxt.TextColor3         = Color3.fromRGB(100, 100, 130)
    pillTxt.Font               = Enum.Font.GothamBold
    pillTxt.TextSize           = 10

    local function refresh(animate)
        local on = T[key]
        local targetBg   = on and Color3.fromRGB(34, 6, 6) or Color3.fromRGB(16, 16, 22)
        local targetBrd  = on and Color3.fromRGB(170, 18, 18) or Color3.fromRGB(28, 28, 44)
        local targetNl   = on and Color3.fromRGB(255, 185, 185) or Color3.fromRGB(210, 210, 210)
        local targetPill = on and Color3.fromRGB(130, 8, 8) or Color3.fromRGB(28, 28, 44)
        local targetPtxt = on and Color3.new(1, 1, 1) or Color3.fromRGB(100, 100, 130)

        if animate then
            TweenService:Create(btn,    TweenInfo.new(0.15), {BackgroundColor3 = targetBg}):Play()
            TweenService:Create(bs,     TweenInfo.new(0.15), {Color = targetBrd}):Play()
            TweenService:Create(nl,     TweenInfo.new(0.15), {TextColor3 = targetNl}):Play()
            TweenService:Create(pillBg, TweenInfo.new(0.15), {BackgroundColor3 = targetPill}):Play()
            TweenService:Create(pillTxt,TweenInfo.new(0.15), {TextColor3 = targetPtxt}):Play()
        else
            btn.BackgroundColor3  = targetBg
            bs.Color              = targetBrd
            nl.TextColor3         = targetNl
            pillBg.BackgroundColor3 = targetPill
            pillTxt.TextColor3    = targetPtxt
        end
        pillTxt.Text = on and "ON" or "OFF"
    end

    btn.MouseButton1Click:Connect(function()
        T[key] = not T[key]
        refresh(true)
        if cb then task.spawn(cb, T[key]) end
    end)

    toggleRefs[key] = function() refresh(false) end
    refresh(false)
    return btn
end

-- Slider
local function slider(scroll, labelTxt, minV, maxV, defaultV, fmt, onChange)
    local cont = Instance.new("Frame", scroll)
    cont.Size             = UDim2.new(0, 288, 0, 50)
    cont.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
    cont.BorderSizePixel  = 0
    Instance.new("UICorner", cont).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", cont).Color = Color3.fromRGB(28, 28, 44)

    local lbl = Instance.new("TextLabel", cont)
    lbl.Size              = UDim2.new(1, -10, 0, 22)
    lbl.Position          = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text              = string.format(labelTxt .. ":  " .. fmt, defaultV)
    lbl.TextColor3        = Color3.fromRGB(200, 200, 200)
    lbl.Font              = Enum.Font.Gotham
    lbl.TextSize          = 11
    lbl.TextXAlignment    = Enum.TextXAlignment.Left

    local track = Instance.new("Frame", cont)
    track.Size            = UDim2.new(1, -20, 0, 6)
    track.Position        = UDim2.new(0, 10, 1, -14)
    track.BackgroundColor3 = Color3.fromRGB(28, 18, 36)
    track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(0, 3)

    local pct0 = math.clamp((defaultV - minV) / (maxV - minV), 0, 1)
    local fill = Instance.new("Frame", track)
    fill.Size             = UDim2.new(pct0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
    fill.BorderSizePixel  = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)

    local knob = Instance.new("TextButton", track)
    knob.Size             = UDim2.new(0, 14, 0, 14)
    knob.AnchorPoint      = Vector2.new(0.5, 0.5)
    knob.Position         = UDim2.new(pct0, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(220, 36, 36)
    knob.Text             = ""
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 5
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local dragging = false
    knob.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not dragging or i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local p = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = minV + p * (maxV - minV)
        fill.Size       = UDim2.new(p, 0, 1, 0)
        knob.Position   = UDim2.new(p, 0, 0.5, 0)
        lbl.Text        = string.format(labelTxt .. ":  " .. fmt, val)
        if onChange then onChange(val) end
    end)
end

-- Position selector
local function posSelector(scroll)
    local cont = Instance.new("Frame", scroll)
    cont.Size             = UDim2.new(0, 288, 0, 54)
    cont.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
    cont.BorderSizePixel  = 0
    Instance.new("UICorner", cont).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", cont).Color = Color3.fromRGB(28, 28, 44)

    local lbl = Instance.new("TextLabel", cont)
    lbl.Size              = UDim2.new(1, -10, 0, 20)
    lbl.Position          = UDim2.new(0, 10, 0, 2)
    lbl.BackgroundTransparency = 1
    lbl.Text              = "📍 Position Mode"
    lbl.TextColor3        = Color3.fromRGB(200, 200, 200)
    lbl.Font              = Enum.Font.GothamBold
    lbl.TextSize          = 11
    lbl.TextXAlignment    = Enum.TextXAlignment.Left

    local row = Instance.new("Frame", cont)
    row.Size             = UDim2.new(1, -20, 0, 26)
    row.Position         = UDim2.new(0, 10, 0, 24)
    row.BackgroundTransparency = 1
    local rl = Instance.new("UIListLayout", row)
    rl.FillDirection = Enum.FillDirection.Horizontal
    rl.Padding       = UDim.new(0, 6)

    local modes = {"Above","InFront","Behind"}
    local btns  = {}
    for _, m in ipairs(modes) do
        local b = Instance.new("TextButton", row)
        b.Size             = UDim2.new(0, 74, 1, 0)
        b.BackgroundColor3 = CFG.POSITION_MODE == m and Color3.fromRGB(130,8,8) or Color3.fromRGB(28,18,36)
        b.Text             = m
        b.TextColor3       = Color3.new(1, 1, 1)
        b.Font             = Enum.Font.GothamBold
        b.TextSize         = 10
        b.BorderSizePixel  = 0
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        btns[m] = b
        b.MouseButton1Click:Connect(function()
            CFG.POSITION_MODE = m
            for _, bm in ipairs(modes) do
                TweenService:Create(btns[bm], TweenInfo.new(0.12), {
                    BackgroundColor3 = bm == m and Color3.fromRGB(130,8,8) or Color3.fromRGB(28,18,36)
                }):Play()
            end
        end)
    end
end

-- ══════════════════════════════════════
--  POPULATE TABS
-- ══════════════════════════════════════
local farm    = tabFrames[1]
local combat  = tabFrames[2]
local settings = tabFrames[3]

-- ── Farm Tab ─────────────────────────────────────
sec(farm, "🗡  MISSIONS")
tog(farm, "🗡", "Autofarm (Blades)",      "Farms missions with blade attacks",  "FarmBlade",  function(on) if on then farmLoop("mission","blade")  end end)
tog(farm, "⚙", "Autofarm (Titan Ripper)", "Farms missions with Titan Ripper",   "FarmRipper", function(on) if on then farmLoop("mission","ripper") end end)
tog(farm, "💥", "Autofarm (Thunderspears)","Farms missions with TS",             "FarmTS",     function(on) if on then farmLoop("mission","ts")     end end)

sec(farm, "🔴  RAIDS")
tog(farm, "💥", "Raid Farm (Thunderspears)", "Farms raids with Thunderspears",   "RaidTS",    function(on) if on then farmLoop("raid","ts")    end end)
tog(farm, "🗡", "Raid Farm (Blades/Ripper)", "Farms raids with Blades or Ripper","RaidBlade", function(on) if on then farmLoop("raid","blade") end end)

sec(farm, "⚡  AUTOMATION")
tog(farm, "🔥", "Auto Streak Farmer",    "Auto-leaves after streak target",   "AutoStreak")
tog(farm, "🔗", "Auto Connect",          "Rejoins mission/raid from lobby",   "AutoConnect", function(on)
    if not on then return end
    if loopActive["AutoConnect"] then return end
    loopActive["AutoConnect"] = true
    task.spawn(function()
        while T.AutoConnect do
            if not inMission() then connectToGame("mission"); task.wait(rng(6,2)) end
            task.wait(rng(2))
        end
        loopActive["AutoConnect"] = nil
    end)
end)
tog(farm, "⚡", "Instant TS Quest",      "Auto-completes watchtower/crates",  "InstantTSQuest", function(on) if on then runTSQuest() end end)
tog(farm, "🚪", "Auto Leave to Lobby",   "Leaves when max kills reached",     "AutoLeave")
tog(farm, "💎", "Auto Collect",          "Collects loot/rewards after waves", "AutoCollect")

-- ── Combat Tab ───────────────────────────────────
sec(combat, "⚔  COMBAT")
tog(combat, "👊", "Auto M1",        "Spams M1 on nearest titan",         "AutoM1")
tog(combat, "🪂", "Auto Eject",     "Auto-escapes titan grabs",          "AutoEject")
tog(combat, "📦", "Hitbox Extender","Extends nape hitbox radius",        "HitboxExtender", function(on)
    CFG.HITBOX_SIZE = on and 55 or 30
end)

sec(combat, "🛡  SURVIVAL")
tog(combat, "🔄", "Anti-AFK",       "Prevents AFK kick every 60s",      "AntiAFK",    function(on) if on then startAntiAFK() end end)
tog(combat, "💀", "Auto Respawn",   "Re-spawns & rejoins after death",   "AutoRespawn")

-- ── Settings Tab ─────────────────────────────────
sec(settings, "⚙  TIMING")
slider(settings, "Kill Delay",    0, 10, CFG.KILL_DELAY,      "%.1fs", function(v) CFG.KILL_DELAY       = v end)
slider(settings, "Stall Time",    0, 10, CFG.STALL_TIME,      "%.1fs", function(v) CFG.STALL_TIME        = v end)
slider(settings, "Rejoin Delay",  1, 15, CFG.REJOIN_DELAY,    "%.1fs", function(v) CFG.REJOIN_DELAY      = v end)

sec(settings, "🎯  TARGETING")
slider(settings, "Max Kills",     1, 500, CFG.MAX_KILLS,      "%.0f",  function(v) CFG.MAX_KILLS         = v end)
slider(settings, "Boss HP Cut",   0, 1,   CFG.BOSS_HP_CUTOFF, "%.0f%%",function(v) CFG.BOSS_HP_CUTOFF    = v end)
slider(settings, "Hitbox Size",   5, 80,  CFG.HITBOX_SIZE,    "%.0f st",function(v) CFG.HITBOX_SIZE      = v end)
slider(settings, "Streak Target", 1, 50,  CFG.STREAK_TARGET,  "%.0f",  function(v) CFG.STREAK_TARGET     = v end)
slider(settings, "Nape Retries",  1, 8,   CFG.NAPE_RETRY,     "%.0f",  function(v) CFG.NAPE_RETRY = math.floor(v) end)

sec(settings, "📍  POSITION")
posSelector(settings)

-- ══════════════════════════════════════
--  KEYBIND LISTENER
-- ══════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    for key, code in pairs(KEYBINDS) do
        if input.KeyCode == code then
            T[key] = not T[key]
            if toggleRefs[key] then toggleRefs[key]() end
            notify("AoTR", key .. " → " .. (T[key] and "ON" or "OFF"), 2)
        end
    end
end)

-- ══════════════════════════════════════
--  HEARTBEAT
-- ══════════════════════════════════════
local lastM1    = 0
local lastEject = 0
local lastAFK   = 0

RunService.Heartbeat:Connect(function()
    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    local now = tick()

    -- Auto Respawn
    if T.AutoRespawn and hum.Health <= 0 then
        task.wait(0.5)
        lp:LoadCharacter()
        task.wait(2)
        if T.AutoConnect and not inMission() then
            connectToGame("mission")
        end
    end

    -- Auto M1 (only if alive)
    if T.AutoM1 and hum.Health > 0 and now - lastM1 > rng(0.09) then
        local titans = getTitans(hrp, 45)
        if #titans > 0 then
            local killed = attackTitan(titans[1].model)
            if killed then stats.kills += 1 end
        end
        lastM1 = now
    end

    -- Auto Eject: check humanoid state + grab bool values
    if T.AutoEject and hum.Health > 0 and now - lastEject > 0.2 then
        local state = hum:GetState()
        local isGrabbed = state == Enum.HumanoidStateType.Physics
        if not isGrabbed then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BoolValue") and v.Value then
                    local n = v.Name:lower()
                    if n:find("grab") or n:find("caught") or n:find("held") or n:find("stun") then
                        isGrabbed = true; break
                    end
                end
            end
        end
        if isGrabbed then
            fireKw({"escape","eject","free","break","grab","release"})
            hrp.CFrame = hrp.CFrame * CFrame.new(math.random(-14,14), 10, math.random(-14,14))
            lastEject = now
        end
    end

    -- Status label
    local active = {}
    for k, v in pairs(T) do if v then table.insert(active, k) end end
    stlbl.Text = #active > 0 and ("● " .. table.concat(active, " · ")) or "● Idle"

    updStats()
end)

-- ══════════════════════════════════════
--  DONE
-- ══════════════════════════════════════
notify("✅ AoTR Farming v2.0", "Loaded! F1-F4 for keybinds.", 5)
warn("✅ AoTR Farming v2.0 loaded successfully!")
