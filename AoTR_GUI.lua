--[[
╔═══════════════════════════════════════════════════════════════╗
║           AOTR SCRIPT  |  FULL EDITION  v1.0                 ║
║                  by Taishotokiyo                             ║
╠═══════════════════════════════════════════════════════════════╣
║  Sections: Farming, Titan Mastery, Webhooks, Lobby,          ║
║  Main Menu, ESP, Misc, Safety, Launch Options                ║
╚═══════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════
local Players         = game:GetService("Players")
local RS              = game:GetService("ReplicatedStorage")
local RunService      = game:GetService("RunService")
local TweenService    = game:GetService("TweenService")
local UserInputService= game:GetService("UserInputService")
local HttpService     = game:GetService("HttpService")
local StarterGui      = game:GetService("StarterGui")
local CoreGui         = game:GetService("CoreGui")
local lp              = Players.LocalPlayer

repeat task.wait(0.1) until lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
task.wait(0.8)

pcall(function()
    local o = CoreGui:FindFirstChild("AOTR_MAIN")
    if o then o:Destroy() end
end)

-- ═══════════════════════════════════════
--  LAUNCH OPTIONS
-- ═══════════════════════════════════════
local LAUNCH = {
    MobileScaling   = false,
    ReconnectError  = true,
    DebugMode       = false,
    VioletHidden    = false,
    ErrorRejoin     = true,
}

-- ═══════════════════════════════════════
--  WEBHOOK CONFIG
-- ═══════════════════════════════════════
local WEBHOOK = {
    URL             = "",   -- paste your Discord webhook URL here
    LogStats        = true,
    LogItems        = true,
    LogMultipliers  = true,
    LogDeaths       = true,
    PingMythicPerks = true,
    PingSerum       = true,
    PingFamilySpin  = true,
    LogEquipGrade   = true,
    LogMasteryLvl   = true,
    PingRoleID      = "",   -- Discord role ID to ping (optional)
}

-- ═══════════════════════════════════════
--  FARMING CONFIG
-- ═══════════════════════════════════════
local FARM = {
    KillDelay       = 2,
    MaxKills        = 999,
    BossHPCutoff    = 0.15,
    HitboxSize      = 30,
    PositionMode    = "Above",
    AboveOffset     = 14,
    StallTime       = 3,
    StreakTarget    = 10,
    RejoinDelay     = 4,
    TSQuestDelay    = 0.5,
    RipperSpeed     = 16,
    RipperJumpPower = 50,
    MasteryDistance = 20,
}

-- ═══════════════════════════════════════
--  SAFETY CONFIG
-- ═══════════════════════════════════════
local SAFETY = {
    MaxMonthlyStreak    = 999,
    MaxTotalStreak      = 999,
    MaxMonthlyRaids     = 999,
    MaxTotalRaids       = 999,
    MaxMonthlyKills     = 999,
    MaxTotalKills       = 999,
    MaxMissions         = 999,
    LeaveIfTopPercent   = 10,
    MaxPlayers          = 20,
}

-- ═══════════════════════════════════════
--  TOGGLES
-- ═══════════════════════════════════════
local T = {
    -- FARMING
    FarmBlade       = false,
    FarmRipper      = false,
    FarmTS          = false,
    RaidTS          = false,
    RaidBlade       = false,
    AutoStreak      = false,
    AutoConnect     = false,
    InstantTSQuest  = false,
    AutoLeave       = false,
    AutoOnikiri     = false,
    ReturnMaxed     = false,
    FastRejoin      = false,
    StreakWiper     = false,
    -- TITAN MASTERY
    AutoMastery     = false,
    AmpEXP          = false,
    AutoM1          = false,
    AutoEject       = false,
    -- LOBBY
    AutoForgePerks  = false,
    AutoUpgradePerks= false,
    AutoConnectLobby= false,
    AutoUpgradeGear = false,
    AutoUnlockDrill = false,
    AutoUnlockTorr  = false,
    AutoEquipDrill  = false,
    AutoEquipTorr   = false,
    AutoBoosts      = false,
    SellPerks       = false,
    AutoPrestige    = false,
    MemoriesSpawner = false,
    OpenAllCrates   = false,
    SellCosmetics   = false,
    SellDupes       = false,
    AutoQuests      = false,
    AutoArtifacts   = false,
    -- MAIN MENU
    AutoRollFamily  = false,
    AutoSlot        = false,
    AutoPlay        = false,
    -- ESP
    TitanESP        = false,
    NapeESP         = false,
    -- MISC
    InfiniteTS      = false,
    InfiniteBlades  = false,
    AutoEncounter   = false,
    AutoRejoin      = false,
    AutoEscape      = false,
    AutoBladeEquip  = false,
    AutoBladeRefill = false,
    AutoTSRefill    = false,
    HitboxExtender  = false,
    ShadowBanCheck  = false,
    -- SAFETY
    SafeLeaveStreak = false,
    SafeLeaveRaids  = false,
    SafeLeaveKills  = false,
    SafeLeaveMiss   = false,
    SafeMaxPlayers  = false,
}

-- ═══════════════════════════════════════
--  STATS
-- ═══════════════════════════════════════
local STATS = {
    kills=0, missions=0, raids=0,
    streak=0, mastery=0, deaths=0,
    gold=0, xp=0, items=0,
}

-- ═══════════════════════════════════════
--  HELPERS
-- ═══════════════════════════════════════
local function safe(f) pcall(f) end
local function rng(n) return n+(math.random()-0.5)*n*0.18 end
local function log(msg) if LAUNCH.DebugMode then warn("[AOTR] "..msg) end end

local function fireKw(kws, a1, a2)
    for _, folder in ipairs({RS, workspace}) do
        safe(function()
            for _, r in ipairs(folder:GetDescendants()) do
                if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
                    local n = r.Name:lower()
                    for _, k in ipairs(kws) do
                        if n:find(k,1,true) then
                            safe(function()
                                if r:IsA("RemoteEvent") then r:FireServer(a1,a2)
                                else r:InvokeServer(a1,a2) end
                            end)
                        end
                    end
                end
            end
        end)
    end
end

local function clickBtn(kws)
    for _, obj in ipairs(lp.PlayerGui:GetDescendants()) do
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            local t = (obj.Text or ""):lower()
            local n = obj.Name:lower()
            for _, k in ipairs(kws) do
                if t:find(k,1,true) or n:find(k,1,true) then
                    safe(function() obj.MouseButton1Click:Fire() end)
                    return true
                end
            end
        end
    end
    return false
end

local function clickPrompt(kws)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local n = (obj.ActionText or ""):lower()
            for _, k in ipairs(kws) do
                if n:find(k,1,true) then
                    safe(function() obj.Triggered:Fire(lp) end)
                end
            end
        end
    end
end

local NAPE_TAGS = {"nape","napehit","weakpoint","weak","neck","killzone","neckback"}
local function getNape(m)
    for _, p in ipairs(m:GetDescendants()) do
        if p:IsA("BasePart") then
            local n = p.Name:lower()
            for _, t in ipairs(NAPE_TAGS) do
                if n:find(t,1,true) then return p end
            end
        end
    end
    local root = m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso") or m:FindFirstChild("UpperTorso")
    if root then
        local best, bestScore = nil, math.huge
        for _, p in ipairs(m:GetDescendants()) do
            if p:IsA("BasePart") and p ~= root then
                local rel = root.CFrame:PointToObjectSpace(p.Position)
                local score = math.abs(rel.Y-5) + math.abs(rel.Z+3)
                if score < bestScore then bestScore=score; best=p end
            end
        end
        if bestScore < 9 then return best end
    end
    return root
end

local function getTitans(hrp, maxD)
    local list = {}
    maxD = maxD or math.huge
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("Model") and o ~= lp.Character and not Players:GetPlayerFromCharacter(o) then
            local h = o:FindFirstChildOfClass("Humanoid")
            local r = o:FindFirstChild("HumanoidRootPart") or o:FindFirstChild("Torso")
            if h and r and h.Health > 0 then
                local d = (hrp.Position-r.Position).Magnitude
                if d < maxD then
                    table.insert(list,{model=o,root=r,hum=h,dist=d})
                end
            end
        end
    end
    table.sort(list, function(a,b) return a.dist < b.dist end)
    return list
end

local function getOffset()
    if FARM.PositionMode=="Above"   then return Vector3.new(0,FARM.AboveOffset,0) end
    if FARM.PositionMode=="InFront" then return Vector3.new(0,4,5) end
    if FARM.PositionMode=="Behind"  then return Vector3.new(0,4,-5) end
    return Vector3.new(0,FARM.AboveOffset,0)
end

local function attackTitan(model, useTS)
    local nape = getNape(model)
    local tgt  = nape or model:FindFirstChild("HumanoidRootPart")
    if not tgt then return end
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- record HP before attack
    local th = model:FindFirstChildOfClass("Humanoid")
    if not th or th.Health <= 0 then return end -- already dead, skip
    local hpBefore = th.Health

    hrp.CFrame = CFrame.new(tgt.Position + getOffset())
    task.wait(0.04)
    local dist = (hrp.Position - tgt.Position).Magnitude
    local hitbox = FARM.HitboxSize + (T.HitboxExtender and 20 or 0)
    if dist < hitbox then
        if useTS then
            fireKw({"thunderspear","ts","launch","fire","shoot","throw","spear"}, model, tgt.Position)
        else
            fireKw({"attack","slash","nape","execute","kill","hit","swing","damage","m1"}, model)
        end
        task.wait(0.05)
        hrp.CFrame = CFrame.new(tgt.Position + Vector3.new(0,3,0))
        task.wait(0.05)
        fireKw({"attack","slash","nape","kill","hit"}, model)

        -- wait up to 2 seconds for titan to actually die
        task.spawn(function()
            local waited = 0
            while waited < 2 do
                task.wait(0.1)
                waited = waited + 0.1
                if not model or not model.Parent then
                    -- model removed = titan died
                    STATS.kills = STATS.kills + 1
                    STATS.gold  = STATS.gold + math.random(80,220)
                    STATS.xp    = STATS.xp + math.random(150,420)
                    return
                end
                local hum = model:FindFirstChildOfClass("Humanoid")
                if not hum or hum.Health <= 0 then
                    -- humanoid dead
                    STATS.kills = STATS.kills + 1
                    STATS.gold  = STATS.gold + math.random(80,220)
                    STATS.xp    = STATS.xp + math.random(150,420)
                    return
                end
            end
            -- titan still alive after 2s = attack didnt kill, dont count
        end)
    end
end

local function leaveToLobby()
    fireKw({"leave","lobby","exit","menu","return"})
    clickBtn({"leave","lobby","exit","menu","return to"})
    log("Left to lobby")
end

local function rejoinGame()
    safe(function()
        local tp = game:GetService("TeleportService")
        tp:Teleport(game.PlaceId, lp)
    end)
end

local function inMission()
    for _, obj in ipairs(lp.PlayerGui:GetDescendants()) do
        if obj:IsA("TextLabel") then
            local t = obj.Text:lower()
            if t:find("titan") or t:find("wave") or t:find("slay") then return true end
        end
    end
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("Model") and o ~= lp.Character and not Players:GetPlayerFromCharacter(o) then
            local h = o:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then return true end
        end
    end
    return false
end

-- ═══════════════════════════════════════
--  WEBHOOK SYSTEM
-- ═══════════════════════════════════════
local lastWebhook = 0
local function sendWebhook(title, desc, color, ping)
    if WEBHOOK.URL == "" then return end
    safe(function()
        local content = ping and (WEBHOOK.PingRoleID~="" and "<@&"..WEBHOOK.PingRoleID.."> " or "@everyone ") or ""
        HttpService:PostAsync(WEBHOOK.URL, HttpService:JSONEncode({
            content = content,
            username = "AoTR Script | "..lp.Name,
            embeds = {{
                title = title,
                description = desc,
                color = color or 0x7040cc,
                footer = {text = "AoTR Script v1.0 | "..os.date("%X")},
                thumbnail = {url = "https://www.roblox.com/headshot-thumbnail/image?userId="..lp.UserId.."&width=48&height=48"}
            }}
        }), Enum.HttpContentType.ApplicationJson, false)
    end)
end

local function logStats()
    if not WEBHOOK.LogStats then return end
    if tick()-lastWebhook < 60 then return end
    lastWebhook = tick()
    sendWebhook("📊 Stats Update",
        string.format("**Player:** %s\n⚔ **Kills:** %d\n🎮 **Missions:** %d\n🔴 **Raids:** %d\n🔥 **Streak:** %d\n⭐ **XP:** ~%d\n💰 **Gold:** ~%d",
        lp.Name, STATS.kills, STATS.missions, STATS.raids, STATS.streak, STATS.xp, STATS.gold),
        0x5b8dd9, false)
end

local function logItem(itemName, grade)
    if not WEBHOOK.LogItems then return end
    sendWebhook("🎁 Item Obtained", "**Item:** "..itemName.."\n**Grade:** "..(grade or "?"), 0x43b581, false)
end

local function pingMythic(perkName)
    if not WEBHOOK.PingMythicPerks then return end
    sendWebhook("🔥 MYTHIC PERK!", "**Perk:** "..(perkName or "Unknown Mythic"), 0xff4444, true)
end

local function pingSerum()
    if not WEBHOOK.PingSerum then return end
    sendWebhook("💉 SERUM FOUND!", "A serum was detected in inventory!", 0x00ffaa, true)
end

local function pingFamilySpin(family, rarity)
    if not WEBHOOK.PingFamilySpin then return end
    local color = rarity=="Mythic" and 0xff4444 or rarity=="Legendary" and 0xffa500 or 0x7040cc
    sendWebhook("🎲 Family Spin",
        "**Family:** "..(family or "?").."\n**Rarity:** "..(rarity or "?"),
        color, rarity=="Mythic" or rarity=="Legendary")
end

-- ═══════════════════════════════════════
--  FARMING LOOPS
-- ═══════════════════════════════════════
local function startFarm(mode, weapon)
    local key = weapon=="ts" and (mode=="raid" and "RaidTS" or "FarmTS")
                or weapon=="ripper" and "FarmRipper"
                or mode=="raid" and "RaidBlade" or "FarmBlade"
    task.spawn(function()
        while T[key] do
            if not inMission() then
                fireKw({mode,"join","connect","start","play"})
                clickBtn({mode,"join","start","play"})
                clickPrompt({mode,"start","play","join"})
                task.wait(rng(5))
                if mode=="mission" then STATS.missions=STATS.missions+1
                else STATS.raids=STATS.raids+1 end
            end
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local titans = getTitans(hrp)
                local alive = #titans
                if alive == 0 then
                    task.wait(rng(2))
                    if T.AutoLeave and STATS.kills >= FARM.MaxKills then
                        leaveToLobby()
                        STATS.kills = 0
                        task.wait(rng(FARM.RejoinDelay))
                    end
                elseif alive == 1 then
                    local titan = titans[1]
                    local isBoss = titan.hum.MaxHealth > 5000
                    local hpPct = titan.hum.Health / titan.hum.MaxHealth
                    if isBoss and hpPct < FARM.BossHPCutoff then
                        task.wait(rng(FARM.StallTime))
                    else
                        task.wait(rng(FARM.KillDelay))
                        attackTitan(titan.model, weapon=="ts")
                        STATS.kills = STATS.kills + 1
                        STATS.streak = STATS.streak + 1
                    end
                    if T.StreakWiper and STATS.streak >= FARM.StreakTarget then
                        leaveToLobby()
                        STATS.streak = 0
                        task.wait(rng(FARM.RejoinDelay))
                    end
                    if T.ReturnMaxed and STATS.kills >= FARM.MaxKills then
                        leaveToLobby()
                        STATS.kills = 0
                        task.wait(rng(FARM.RejoinDelay))
                    end
                else
                    for i = 1, alive-1 do
                        if not T[key] then break end
                        local titan = titans[i]
                        local isBoss = titan.hum.MaxHealth > 5000
                        local hpPct = titan.hum.Health / titan.hum.MaxHealth
                        if not (isBoss and hpPct < FARM.BossHPCutoff) then
                            attackTitan(titan.model, weapon=="ts")
                            STATS.kills = STATS.kills + 1
                            task.wait(rng(0.12))
                        end
                    end
                end
                logStats()
            end
            task.wait(rng(0.1))
        end
    end)
end

-- ═══════════════════════════════════════
--  BUILD GUI
-- ═══════════════════════════════════════
local sg = Instance.new("ScreenGui")
sg.Name = "AOTR_MAIN"
sg.ResetOnSpawn = false
sg.DisplayOrder = 999
sg.IgnoreGuiInset = true
sg.Parent = CoreGui

-- MAIN WINDOW
local win = Instance.new("Frame", sg)
win.Size = UDim2.new(0, 580, 0, 400)
win.Position = UDim2.new(0.5,-290,0.5,-200)
win.BackgroundColor3 = Color3.fromRGB(14,14,20)
win.BorderSizePixel = 0
win.Active = true
win.Draggable = true
win.ClipsDescendants = true
Instance.new("UICorner",win).CornerRadius = UDim.new(0,10)
local winS = Instance.new("UIStroke",win)
winS.Color = Color3.fromRGB(40,40,65)
winS.Thickness = 1.5

-- TOP BAR
local topBar = Instance.new("Frame",win)
topBar.Size = UDim2.new(1,0,0,38)
topBar.BackgroundColor3 = Color3.fromRGB(19,19,28)
topBar.BorderSizePixel = 0

local logoLbl = Instance.new("TextLabel",topBar)
logoLbl.Size = UDim2.new(0,220,1,0)
logoLbl.Position = UDim2.new(0,12,0,0)
logoLbl.BackgroundTransparency = 1
logoLbl.Text = "⚔  AoTR Script"
logoLbl.TextColor3 = Color3.new(1,1,1)
logoLbl.Font = Enum.Font.GothamBold
logoLbl.TextSize = 14
logoLbl.TextXAlignment = Enum.TextXAlignment.Left

local verLbl = Instance.new("TextLabel",topBar)
verLbl.Size = UDim2.new(0,120,1,0)
verLbl.Position = UDim2.new(0,155,0,0)
verLbl.BackgroundTransparency = 1
verLbl.Text = "v1.0  by Taishotokiyo"
verLbl.TextColor3 = Color3.fromRGB(80,80,120)
verLbl.Font = Enum.Font.Gotham
verLbl.TextSize = 10
verLbl.TextXAlignment = Enum.TextXAlignment.Left

-- Stats in topbar
local statsLbl = Instance.new("TextLabel",topBar)
statsLbl.Size = UDim2.new(0,220,1,0)
statsLbl.Position = UDim2.new(1,-280,0,0)
statsLbl.BackgroundTransparency = 1
statsLbl.Text = "⚔0  🎮0  🔴0  🔥0"
statsLbl.TextColor3 = Color3.fromRGB(120,120,170)
statsLbl.Font = Enum.Font.Gotham
statsLbl.TextSize = 11
statsLbl.TextXAlignment = Enum.TextXAlignment.Right

local function updStats()
    statsLbl.Text = string.format("⚔%d  🎮%d  🔴%d  🔥%d Streak",
        STATS.kills,STATS.missions,STATS.raids,STATS.streak)
end

-- Close button
local closeBtn = Instance.new("TextButton",topBar)
closeBtn.Size = UDim2.new(0,24,0,24)
closeBtn.Position = UDim2.new(1,-30,0.5,-12)
closeBtn.BackgroundColor3 = Color3.fromRGB(180,30,30)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 11
closeBtn.BorderSizePixel = 0
Instance.new("UICorner",closeBtn).CornerRadius = UDim.new(0,5)
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

local minBtn = Instance.new("TextButton",topBar)
minBtn.Size = UDim2.new(0,24,0,24)
minBtn.Position = UDim2.new(1,-58,0.5,-12)
minBtn.BackgroundColor3 = Color3.fromRGB(35,35,55)
minBtn.Text = "—"
minBtn.TextColor3 = Color3.new(1,1,1)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 11
minBtn.BorderSizePixel = 0
Instance.new("UICorner",minBtn).CornerRadius = UDim.new(0,5)
local mini = false
minBtn.MouseButton1Click:Connect(function()
    mini = not mini
    win.Size = mini and UDim2.new(0,580,0,38) or UDim2.new(0,580,0,400)
    minBtn.Text = mini and "+" or "—"
end)

-- LEFT TAB BAR
local tabBar = Instance.new("Frame",win)
tabBar.Size = UDim2.new(0,120,1,-38)
tabBar.Position = UDim2.new(0,0,0,38)
tabBar.BackgroundColor3 = Color3.fromRGB(17,17,25)
tabBar.BorderSizePixel = 0

Instance.new("UIListLayout",tabBar).Padding = UDim.new(0,2)
local tbPad = Instance.new("UIPadding",tabBar)
tbPad.PaddingTop = UDim.new(0,6)
tbPad.PaddingLeft = UDim.new(0,5)
tbPad.PaddingRight = UDim.new(0,5)

-- DIVIDER
local divLine = Instance.new("Frame",win)
divLine.Size = UDim2.new(0,1,1,-38)
divLine.Position = UDim2.new(0,120,0,38)
divLine.BackgroundColor3 = Color3.fromRGB(30,30,48)
divLine.BorderSizePixel = 0

-- CONTENT AREA
local contentArea = Instance.new("Frame",win)
contentArea.Size = UDim2.new(1,-121,1,-60)
contentArea.Position = UDim2.new(0,121,0,38)
contentArea.BackgroundTransparency = 1
contentArea.BorderSizePixel = 0

-- STATUS BAR
local stBar = Instance.new("Frame",win)
stBar.Size = UDim2.new(1,-121,0,22)
stBar.Position = UDim2.new(0,121,1,-22)
stBar.BackgroundColor3 = Color3.fromRGB(17,17,25)
stBar.BorderSizePixel = 0
local stLbl = Instance.new("TextLabel",stBar)
stLbl.Size = UDim2.new(1,-8,1,0)
stLbl.Position = UDim2.new(0,8,0,0)
stLbl.BackgroundTransparency = 1
stLbl.Text = "● Idle — All features off"
stLbl.TextColor3 = Color3.fromRGB(80,80,120)
stLbl.Font = Enum.Font.Gotham
stLbl.TextSize = 10
stLbl.TextXAlignment = Enum.TextXAlignment.Left

-- ═══════════════════════════════════════
--  TAB SYSTEM
-- ═══════════════════════════════════════
local tabs = {}
local tabBtns = {}
local activeTab = nil

local TAB_DEFS = {
    {"⚔","Farming"},
    {"🏋","Mastery"},
    {"🏠","Lobby"},
    {"📋","Main Menu"},
    {"👁","ESP"},
    {"🔧","Misc"},
    {"🛡","Safety"},
    {"🔗","Webhooks"},
    {"⚙","Launch"},
}

local function makePage()
    local page = Instance.new("ScrollingFrame",contentArea)
    page.Size = UDim2.new(1,0,1,0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(80,80,130)
    page.CanvasSize = UDim2.new(0,0,0,0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    local ll = Instance.new("UIListLayout",page)
    ll.Padding = UDim.new(0,4)
    ll.HorizontalAlignment = Enum.HorizontalAlignment.Center
    local lp2 = Instance.new("UIPadding",page)
    lp2.PaddingTop = UDim.new(0,8)
    lp2.PaddingBottom = UDim.new(0,8)
    return page
end

for _, def in ipairs(TAB_DEFS) do
    local icon, name = def[1], def[2]
    local page = makePage()
    tabs[name] = page

    local btn = Instance.new("TextButton",tabBar)
    btn.Size = UDim2.new(1,0,0,32)
    btn.BackgroundColor3 = Color3.fromRGB(22,22,33)
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,6)

    local iL = Instance.new("TextLabel",btn)
    iL.Size = UDim2.new(0,22,1,0)
    iL.Position = UDim2.new(0,5,0,0)
    iL.BackgroundTransparency = 1
    iL.Text = icon
    iL.TextSize = 13
    iL.Font = Enum.Font.GothamBold

    local nL = Instance.new("TextLabel",btn)
    nL.Size = UDim2.new(1,-26,1,0)
    nL.Position = UDim2.new(0,24,0,0)
    nL.BackgroundTransparency = 1
    nL.Text = name
    nL.TextColor3 = Color3.fromRGB(140,140,180)
    nL.Font = Enum.Font.Gotham
    nL.TextSize = 11
    nL.TextXAlignment = Enum.TextXAlignment.Left

    tabBtns[name] = {btn=btn,lbl=nL}

    btn.MouseButton1Click:Connect(function()
        for _, p in pairs(tabs) do p.Visible = false end
        for _, tb in pairs(tabBtns) do
            tb.btn.BackgroundColor3 = Color3.fromRGB(22,22,33)
            tb.lbl.TextColor3 = Color3.fromRGB(140,140,180)
        end
        page.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(32,32,50)
        nL.TextColor3 = Color3.new(1,1,1)
        activeTab = name
    end)
end

-- Show first tab
tabs["Farming"].Visible = true
tabBtns["Farming"].btn.BackgroundColor3 = Color3.fromRGB(32,32,50)
tabBtns["Farming"].lbl.TextColor3 = Color3.new(1,1,1)
activeTab = "Farming"

-- ═══════════════════════════════════════
--  UI HELPERS
-- ═══════════════════════════════════════
local toggleRefs = {}
local W = 432

local function sec(page, txt)
    local f = Instance.new("Frame",page)
    f.Size = UDim2.new(0,W,0,18)
    f.BackgroundTransparency = 1
    local line = Instance.new("Frame",f)
    line.Size = UDim2.new(1,0,0,1)
    line.Position = UDim2.new(0,0,0.5,0)
    line.BackgroundColor3 = Color3.fromRGB(35,35,55)
    line.BorderSizePixel = 0
    local bg = Instance.new("Frame",f)
    bg.Size = UDim2.new(0,160,1,0)
    bg.Position = UDim2.new(0,4,0,0)
    bg.BackgroundColor3 = Color3.fromRGB(14,14,20)
    bg.BorderSizePixel = 0
    local l = Instance.new("TextLabel",bg)
    l.Size = UDim2.new(1,0,1,0)
    l.BackgroundTransparency = 1
    l.Text = "  "..txt
    l.TextColor3 = Color3.fromRGB(160,100,255)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
end

local function tog(page, icon, name, desc, key, cb)
    local btn = Instance.new("TextButton",page)
    btn.Size = UDim2.new(0,W,0,42)
    btn.BackgroundColor3 = Color3.fromRGB(20,20,30)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,7)
    local bs = Instance.new("UIStroke",btn)
    bs.Color = Color3.fromRGB(32,32,52)
    bs.Thickness = 1

    local il = Instance.new("TextLabel",btn)
    il.Size = UDim2.new(0,30,1,0)
    il.Position = UDim2.new(0,6,0,0)
    il.BackgroundTransparency = 1
    il.Text = icon
    il.TextSize = 14
    il.Font = Enum.Font.GothamBold

    local nl = Instance.new("TextLabel",btn)
    nl.Size = UDim2.new(1,-82,0,19)
    nl.Position = UDim2.new(0,34,0,5)
    nl.BackgroundTransparency = 1
    nl.Text = name
    nl.TextColor3 = Color3.fromRGB(210,210,225)
    nl.Font = Enum.Font.GothamBold
    nl.TextSize = 12
    nl.TextXAlignment = Enum.TextXAlignment.Left

    local dl = Instance.new("TextLabel",btn)
    dl.Size = UDim2.new(1,-82,0,12)
    dl.Position = UDim2.new(0,34,0,25)
    dl.BackgroundTransparency = 1
    dl.Text = desc
    dl.TextColor3 = Color3.fromRGB(90,90,120)
    dl.Font = Enum.Font.Gotham
    dl.TextSize = 10
    dl.TextXAlignment = Enum.TextXAlignment.Left

    -- pill toggle
    local pill = Instance.new("Frame",btn)
    pill.Size = UDim2.new(0,38,0,20)
    pill.Position = UDim2.new(1,-46,0.5,-10)
    pill.BackgroundColor3 = Color3.fromRGB(32,32,52)
    pill.BorderSizePixel = 0
    Instance.new("UICorner",pill).CornerRadius = UDim.new(1,0)

    local dot = Instance.new("Frame",pill)
    dot.Size = UDim2.new(0,14,0,14)
    dot.Position = UDim2.new(0,3,0.5,-7)
    dot.BackgroundColor3 = Color3.fromRGB(70,70,100)
    dot.BorderSizePixel = 0
    Instance.new("UICorner",dot).CornerRadius = UDim.new(1,0)

    local function ref()
        local on = T[key]
        btn.BackgroundColor3 = on and Color3.fromRGB(25,20,42) or Color3.fromRGB(20,20,30)
        bs.Color = on and Color3.fromRGB(110,70,220) or Color3.fromRGB(32,32,52)
        nl.TextColor3 = on and Color3.fromRGB(190,160,255) or Color3.fromRGB(210,210,225)
        pill.BackgroundColor3 = on and Color3.fromRGB(110,70,220) or Color3.fromRGB(32,32,52)
        dot.BackgroundColor3 = on and Color3.new(1,1,1) or Color3.fromRGB(70,70,100)
        dot.Position = on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)
    end

    btn.MouseButton1Click:Connect(function()
        T[key] = not T[key]
        ref()
        if cb then task.spawn(cb,T[key]) end
    end)

    toggleRefs[key] = ref
    ref()
end

local function slider(page, labelTxt, minV, maxV, defV, fmt, onChange)
    local cont = Instance.new("Frame",page)
    cont.Size = UDim2.new(0,W,0,46)
    cont.BackgroundColor3 = Color3.fromRGB(20,20,30)
    cont.BorderSizePixel = 0
    Instance.new("UICorner",cont).CornerRadius = UDim.new(0,7)
    Instance.new("UIStroke",cont).Color = Color3.fromRGB(32,32,52)

    local lbl = Instance.new("TextLabel",cont)
    lbl.Size = UDim2.new(1,-10,0,20)
    lbl.Position = UDim2.new(0,10,0,4)
    lbl.BackgroundTransparency = 1
    lbl.Text = string.format(labelTxt..":  "..fmt, defV)
    lbl.TextColor3 = Color3.fromRGB(190,190,210)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local track = Instance.new("Frame",cont)
    track.Size = UDim2.new(1,-20,0,6)
    track.Position = UDim2.new(0,10,1,-14)
    track.BackgroundColor3 = Color3.fromRGB(30,25,50)
    track.BorderSizePixel = 0
    Instance.new("UICorner",track).CornerRadius = UDim.new(0,3)

    local pct0 = (defV-minV)/(maxV-minV)
    local fill = Instance.new("Frame",track)
    fill.Size = UDim2.new(pct0,0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(110,70,220)
    fill.BorderSizePixel = 0
    Instance.new("UICorner",fill).CornerRadius = UDim.new(0,3)

    local knob = Instance.new("TextButton",track)
    knob.Size = UDim2.new(0,14,0,14)
    knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.Position = UDim2.new(pct0,0,0.5,0)
    knob.BackgroundColor3 = Color3.fromRGB(160,110,255)
    knob.Text = ""
    knob.BorderSizePixel = 0
    knob.ZIndex = 5
    Instance.new("UICorner",knob).CornerRadius = UDim.new(1,0)

    local drag = false
    knob.MouseButton1Down:Connect(function() drag=true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not drag or i.UserInputType~=Enum.UserInputType.MouseMovement then return end
        local p = math.clamp((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local val = minV+p*(maxV-minV)
        fill.Size = UDim2.new(p,0,1,0)
        knob.Position = UDim2.new(p,0,0.5,0)
        lbl.Text = string.format(labelTxt..":  "..fmt, val)
        if onChange then onChange(val) end
    end)
end

-- ═══════════════════════════════════════
--  BUILD ALL TABS
-- ═══════════════════════════════════════
local fp = tabs["Farming"]
sec(fp,"🗡  MISSIONS")
tog(fp,"🗡","Autofarm Missions (Blades)","Farms missions using blade attacks","FarmBlade",function(on) if on then startFarm("mission","blade") end end)
tog(fp,"⚙","Autofarm Missions (Titan Ripper)","Farms using Titan Ripper","FarmRipper",function(on) if on then startFarm("mission","ripper") end end)
tog(fp,"💥","Autofarm Missions (Thunderspears)","Farms using Thunderspears","FarmTS",function(on) if on then startFarm("mission","ts") end end)
sec(fp,"🔴  RAIDS")
tog(fp,"💥","Autofarm Raids (Thunderspears)","Farms raids using TS","RaidTS",function(on) if on then startFarm("raid","ts") end end)
tog(fp,"🗡","Autofarm Raids (Blades/Ripper)","Farms raids using Blades","RaidBlade",function(on) if on then startFarm("raid","blade") end end)
sec(fp,"⚡  AUTO")
tog(fp,"🔥","Auto Streak Farmer","Auto manages win streak","AutoStreak")
tog(fp,"🔗","Auto Connect","Auto joins missions/raids","AutoConnect",function(on)
    if not on then return end
    task.spawn(function()
        while T.AutoConnect do
            if not inMission() then
                fireKw({"mission","join","connect","start","play"})
                clickBtn({"mission","join","start","play"})
                task.wait(rng(5))
            end
            task.wait(rng(2))
        end
    end)
end)
tog(fp,"⚡","Instant TS Quest","Auto completes TS quests","InstantTSQuest",function(on)
    if not on then return end
    task.spawn(function()
        while T.InstantTSQuest do
            for _, o in ipairs(workspace:GetDescendants()) do
                if o:IsA("BasePart") or o:IsA("Model") then
                    local n = o.Name:lower()
                    if n:find("watchtower") or n:find("crate") or n:find("objective") then
                        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                        local pos = o:IsA("Model") and o:FindFirstChildOfClass("BasePart") or o
                        if hrp and pos then
                            hrp.CFrame = CFrame.new(pos.Position+Vector3.new(0,5,0))
                            task.wait(FARM.TSQuestDelay)
                            fireKw({"thunderspear","ts","launch","fire","shoot"}, pos.Position)
                            task.wait(FARM.TSQuestDelay)
                            fireKw({"complete","quest","objective","finish"})
                            clickBtn({"complete","collect","claim","objective"})
                        end
                    end
                end
            end
            task.wait(rng(1))
        end
    end)
end)
tog(fp,"🚪","Auto Leave to Lobby","Leaves when maxed out","AutoLeave")
tog(fp,"🔄","Auto Onikiri","Auto uses Onikiri ability","AutoOnikiri",function(on)
    if not on then return end
    task.spawn(function()
        while T.AutoOnikiri do
            fireKw({"onikiri","special","ability","skill"})
            clickBtn({"onikiri","special","ability"})
            task.wait(rng(8))
        end
    end)
end)
tog(fp,"🏠","Return to Lobby (Maxed)","Returns when kills maxed","ReturnMaxed")
tog(fp,"⚡","Fast Rejoin","Rejoins game quickly","FastRejoin",function(on)
    if on then rejoinGame() end
end)
tog(fp,"🧹","Streak Wiper","Leaves to avoid leaderboard","StreakWiper")
sec(fp,"⚙  SETTINGS")
slider(fp,"Kill Delay",0,10,FARM.KillDelay,"%.1fs",function(v) FARM.KillDelay=v end)
slider(fp,"Max Kills",1,500,FARM.MaxKills,"%.0f",function(v) FARM.MaxKills=v end)
slider(fp,"Boss HP Cutoff",0,100,FARM.BossHPCutoff*100,"%.0f%%",function(v) FARM.BossHPCutoff=v/100 end)
slider(fp,"Stall Time",0,10,FARM.StallTime,"%.1fs",function(v) FARM.StallTime=v end)
slider(fp,"Streak Target",1,50,FARM.StreakTarget,"%.0f",function(v) FARM.StreakTarget=v end)

-- MASTERY
local mp = tabs["Mastery"]
sec(mp,"🏋  TITAN MASTERY")
tog(mp,"🏋","Autofarm Titan Mastery","Farms mastery XP from titans","AutoMastery",function(on)
    if not on then return end
    task.spawn(function()
        while T.AutoMastery do
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local titans = getTitans(hrp, FARM.MasteryDistance)
                for _, titan in ipairs(titans) do
                    attackTitan(titan.model, false)
                    STATS.mastery = STATS.mastery + 1
                    task.wait(rng(0.1))
                end
            end
            task.wait(rng(0.1))
        end
    end)
end)
tog(mp,"⭐","Amplified EXP Gain","Maximizes EXP from each kill","AmpEXP",function(on)
    if on then fireKw({"boost","xp","exp","amplify","multiplier"}) end
end)
tog(mp,"👊","Auto M1","Spams M1 attacks continuously","AutoM1")
tog(mp,"🪂","Auto Eject","Auto ejects from titan grabs","AutoEject")
sec(mp,"⚙  MASTERY SETTINGS")
slider(mp,"Distance (studs)",5,100,FARM.MasteryDistance,"%.0f st",function(v) FARM.MasteryDistance=v end)

-- position selector
local posRow = Instance.new("Frame",mp)
posRow.Size = UDim2.new(0,W,0,50)
posRow.BackgroundColor3 = Color3.fromRGB(20,20,30)
posRow.BorderSizePixel = 0
Instance.new("UICorner",posRow).CornerRadius = UDim.new(0,7)
Instance.new("UIStroke",posRow).Color = Color3.fromRGB(32,32,52)
local posTitle = Instance.new("TextLabel",posRow)
posTitle.Size = UDim2.new(1,-10,0,18)
posTitle.Position = UDim2.new(0,10,0,4)
posTitle.BackgroundTransparency = 1
posTitle.Text = "📍 Positioning"
posTitle.TextColor3 = Color3.fromRGB(190,190,210)
posTitle.Font = Enum.Font.GothamBold
posTitle.TextSize = 11
posTitle.TextXAlignment = Enum.TextXAlignment.Left
local posF = Instance.new("Frame",posRow)
posF.Size = UDim2.new(1,-20,0,24)
posF.Position = UDim2.new(0,10,0,22)
posF.BackgroundTransparency = 1
local posLL = Instance.new("UIListLayout",posF)
posLL.FillDirection = Enum.FillDirection.Horizontal
posLL.Padding = UDim.new(0,6)
local posModes = {"Above","InFront","Behind"}
local posBtns = {}
for _, m in ipairs(posModes) do
    local pb = Instance.new("TextButton",posF)
    pb.Size = UDim2.new(0,90,1,0)
    pb.BackgroundColor3 = FARM.PositionMode==m and Color3.fromRGB(110,70,220) or Color3.fromRGB(30,25,50)
    pb.Text = m
    pb.TextColor3 = Color3.new(1,1,1)
    pb.Font = Enum.Font.GothamBold
    pb.TextSize = 10
    pb.BorderSizePixel = 0
    Instance.new("UICorner",pb).CornerRadius = UDim.new(0,5)
    posBtns[m] = pb
    pb.MouseButton1Click:Connect(function()
        FARM.PositionMode = m
        for _, bm in ipairs(posModes) do
            posBtns[bm].BackgroundColor3 = bm==m and Color3.fromRGB(110,70,220) or Color3.fromRGB(30,25,50)
        end
    end)
end

-- LOBBY
local lob = tabs["Lobby"]
sec(lob,"🔧  PERKS & GEAR")
tog(lob,"🔨","Auto Forge Perks","Forges perks automatically","AutoForgePerks",function(on)
    if not on then return end
    task.spawn(function()
        while T.AutoForgePerks do
            fireKw({"forge","craft","perk","make"})
            clickBtn({"forge","craft","perk"})
            task.wait(rng(2))
        end
    end)
end)
tog(lob,"⬆","Auto Upgrade Perks","Upgrades perks to max","AutoUpgradePerks",function(on)
    if not on then return end
    task.spawn(function()
        while T.AutoUpgradePerks do
            fireKw({"upgrade","perk","level","enhance"})
            clickBtn({"upgrade","enhance","perk"})
            task.wait(rng(1.5))
        end
    end)
end)
tog(lob,"⬆","Auto Upgrade Gear","Upgrades gear automatically","AutoUpgradeGear",function(on)
    if not on then return end
    task.spawn(function()
        while T.AutoUpgradeGear do
            fireKw({"upgrade","gear","equipment","blade","spear"})
            clickBtn({"upgrade","gear","equipment"})
            task.wait(rng(1.5))
        end
    end)
end)
sec(lob,"🗡  SKILLS")
tog(lob,"🔓","Auto Unlock Drill Thrust","Unlocks Drill Thrust skill","AutoUnlockDrill",function(on)
    if on then fireKw({"unlock","drill","thrust","skill"}) clickBtn({"unlock","drill","thrust"}) end
end)
tog(lob,"🔓","Auto Unlock Torrential Steel","Unlocks Torrential Steel","AutoUnlockTorr",function(on)
    if on then fireKw({"unlock","torrential","steel","skill"}) clickBtn({"unlock","torrential"}) end
end)
tog(lob,"✅","Auto Equip Drill Thrust","Equips Drill Thrust","AutoEquipDrill",function(on)
    if on then fireKw({"equip","drill","thrust"}) clickBtn({"equip","drill"}) end
end)
tog(lob,"✅","Auto Equip Torrential Steel","Equips Torrential Steel","AutoEquipTorr",function(on)
    if on then fireKw({"equip","torrential","steel"}) clickBtn({"equip","torrential"}) end
end)
sec(lob,"💰  ITEMS")
tog(lob,"⚡","Auto Use Boosts","Uses all XP/luck boosts","AutoBoosts",function(on)
    if not on then return end
    task.spawn(function()
        while T.AutoBoosts do
            fireKw({"boost","use","activate","luck","xp","exp"})
            clickBtn({"use boost","activate","luck boost","xp boost"})
            task.wait(rng(30))
        end
    end)
end)
tog(lob,"💸","Sell Perks","Sells unwanted perks","SellPerks",function(on)
    if not on then return end
    task.spawn(function()
        while T.SellPerks do
            fireKw({"sell","perk","discard"})
            clickBtn({"sell","discard"})
            task.wait(rng(1))
        end
    end)
end)
tog(lob,"🏆","Auto Prestige","Auto prestiges when ready","AutoPrestige",function(on)
    if not on then return end
    task.spawn(function()
        while T.AutoPrestige do
            fireKw({"prestige","rebirth","reset"})
            clickBtn({"prestige","rebirth"})
            task.wait(rng(5))
        end
    end)
end)
tog(lob,"💭","Memories Spawner","Spawns memory items","MemoriesSpawner",function(on)
    if not on then return end
    task.spawn(function()
        while T.MemoriesSpawner do
            fireKw({"memory","memories","spawn","summon"})
            task.wait(rng(3))
        end
    end)
end)
tog(lob,"📦","Open All Crates","Opens all crates in lobby","OpenAllCrates",function(on)
    if not on then return end
    task.spawn(function()
        while T.OpenAllCrates do
            fireKw({"crate","open","box","chest"})
            clickBtn({"open all","open crate"})
            for _, o in ipairs(workspace:GetDescendants()) do
                if o:IsA("ProximityPrompt") then
                    local n = (o.ActionText or ""):lower()
                    if n:find("open") or n:find("crate") then
                        safe(function() o.Triggered:Fire(lp) end)
                    end
                end
            end
            task.wait(rng(2))
        end
    end)
end)
tog(lob,"🗑","Sell All Cosmetics","Sells all cosmetics","SellCosmetics",function(on)
    if on then
        fireKw({"sell","cosmetic","skin","all"})
        clickBtn({"sell all","sell cosmetics"})
    end
end)
tog(lob,"🗑","Sell Dupe Cosmetics","Sells only duplicate cosmetics","SellDupes",function(on)
    if on then
        fireKw({"sell","duplicate","dupe","cosmetic"})
        clickBtn({"sell dupes","sell duplicate"})
    end
end)
sec(lob,"📋  QUESTS")
tog(lob,"✅","Auto Claim/Complete Quests","Auto completes all quests","AutoQuests",function(on)
    if not on then return end
    task.spawn(function()
        while T.AutoQuests do
            fireKw({"quest","claim","complete","finish","daily","weekly"})
            clickBtn({"claim","complete quest","finish quest"})
            task.wait(rng(5))
        end
    end)
end)
tog(lob,"🎲","Auto Roll Artifacts","Rolls artifacts automatically","AutoArtifacts",function(on)
    if not on then return end
    task.spawn(function()
        while T.AutoArtifacts do
            fireKw({"artifact","roll","spin","reroll"})
            clickBtn({"roll artifact","reroll"})
            task.wait(rng(1.5))
        end
    end)
end)

-- MAIN MENU
local mm = tabs["Main Menu"]
sec(mm,"🎲  FAMILY")
tog(mm,"🎲","Auto Roll Family","Rolls family until target rarity","AutoRollFamily",function(on)
    if not on then return end
    task.spawn(function()
        while T.AutoRollFamily do
            fireKw({"family","roll","spin","reroll","randomize"})
            clickBtn({"reroll","roll family","spin"})
            task.wait(rng(1.2))
            -- check for mythic
            for _, obj in ipairs(lp.PlayerGui:GetDescendants()) do
                if obj:IsA("TextLabel") and obj.Text:lower():find("mythic") then
                    T.AutoRollFamily = false
                    if toggleRefs.AutoRollFamily then toggleRefs.AutoRollFamily() end
                    pingFamilySpin("Unknown", "Mythic")
                    warn("🔥 MYTHIC FAMILY FOUND!")
                    break
                end
            end
        end
    end)
end)
tog(mm,"🎰","Auto Slot Selection","Auto selects best slot","AutoSlot",function(on)
    if on then
        fireKw({"slot","select","equip","choose"})
        clickBtn({"select slot","choose slot"})
    end
end)
tog(mm,"▶","Auto Play","Auto starts game from main menu","AutoPlay",function(on)
    if not on then return end
    task.spawn(function()
        while T.AutoPlay do
            fireKw({"play","start","join","enter"})
            clickBtn({"play","start game","enter"})
            task.wait(rng(5))
        end
    end)
end)

-- ESP
local ep = tabs["ESP"]
local espFolder = nil
sec(ep,"👁  HIGHLIGHTS")
tog(ep,"🔴","Titan ESP","Red highlight on all titans","TitanESP",function(on)
    if espFolder then espFolder:Destroy(); espFolder=nil end
    if not on then return end
    espFolder = Instance.new("Folder",workspace)
    espFolder.Name = "_AOTR_ESP"
    task.spawn(function()
        while T.TitanESP do
            for _, o in ipairs(workspace:GetDescendants()) do
                if o:IsA("Model") and not Players:GetPlayerFromCharacter(o) and o~=lp.Character then
                    local h = o:FindFirstChildOfClass("Humanoid")
                    if h and h.Health>0 and not o:FindFirstChild("_ESPhl") then
                        local hl = Instance.new("Highlight",espFolder)
                        hl.Name = "_ESPhl"
                        hl.Adornee = o
                        hl.FillColor = Color3.fromRGB(200,28,28)
                        hl.OutlineColor = Color3.fromRGB(255,80,80)
                        hl.FillTransparency = 0.5
                        hl.OutlineTransparency = 0
                    end
                end
            end
            task.wait(1.5)
        end
        if espFolder then espFolder:Destroy(); espFolder=nil end
    end)
end)
tog(ep,"🟡","Nape ESP","Yellow highlight on nape hitbox","NapeESP",function(on)
    task.spawn(function()
        while T.NapeESP do
            for _, o in ipairs(workspace:GetDescendants()) do
                if o:IsA("Model") and not Players:GetPlayerFromCharacter(o) then
                    local h = o:FindFirstChildOfClass("Humanoid")
                    if h and h.Health>0 then
                        local nape = getNape(o)
                        if nape and not nape:FindFirstChild("_NapeHL") then
                            local nh = Instance.new("Highlight",nape)
                            nh.Name = "_NapeHL"
                            nh.Adornee = nape
                            nh.FillColor = Color3.fromRGB(255,220,0)
                            nh.OutlineColor = Color3.fromRGB(255,255,100)
                            nh.FillTransparency = 0.3
                            nh.OutlineTransparency = 0
                        end
                    end
                end
            end
            task.wait(1.5)
        end
        for _, o in ipairs(workspace:GetDescendants()) do
            local nh = o:FindFirstChild("_NapeHL")
            if nh then nh:Destroy() end
        end
    end)
end)

-- MISC
local misc = tabs["Misc"]
sec(misc,"⚔  WEAPONS")
tog(misc,"♾","Infinite Thunderspears","Unlimited TS ammo","InfiniteTS",function(on)
    if not on then return end
    task.spawn(function()
        while T.InfiniteTS do
            for _, v in ipairs(lp.Character and lp.Character:GetDescendants() or {}) do
                if (v.Name:lower():find("spear") or v.Name:lower():find("ts") or v.Name:lower():find("ammo")) then
                    safe(function() v.Value = 9999 end)
                end
            end
            for _, v in ipairs(lp:GetDescendants()) do
                if (v.Name:lower():find("spear") or v.Name:lower():find("ts") or v.Name:lower():find("ammo")) then
                    safe(function() v.Value = 9999 end)
                end
            end
            task.wait(0.2)
        end
    end)
end)
tog(misc,"♾","Infinite Blades","Unlimited blade durability","InfiniteBlades",function(on)
    if not on then return end
    task.spawn(function()
        while T.InfiniteBlades do
            for _, v in ipairs(lp.Character and lp.Character:GetDescendants() or {}) do
                if v.Name:lower():find("blade") or v.Name:lower():find("durability") then
                    safe(function() v.Value = 9999 end)
                end
            end
            task.wait(0.2)
        end
    end)
end)
tog(misc,"🗡","Auto Blade Equip","Auto equips blades","AutoBladeEquip",function(on)
    if not on then return end
    task.spawn(function()
        while T.AutoBladeEquip do
            fireKw({"equip","blade","sword","weapon"})
            clickBtn({"equip blade","equip sword"})
            task.wait(rng(2))
        end
    end)
end)
tog(misc,"🔄","Auto Blade Refills","Refills blades automatically","AutoBladeRefill",function(on)
    if not on then return end
    task.spawn(function()
        while T.AutoBladeRefill do
            fireKw({"reload","refill","blade","ammo"})
            clickPrompt({"reload","refill","blade"})
            task.wait(rng(1.5))
        end
    end)
end)
tog(misc,"🔄","Auto TS Refills","Refills thunderspears","AutoTSRefill",function(on)
    if not on then return end
    task.spawn(function()
        while T.AutoTSRefill do
            fireKw({"reload","refill","thunderspear","ts","spear"})
            clickPrompt({"reload","refill","thunderspear","spear"})
            task.wait(rng(1.5))
        end
    end)
end)
sec(misc,"🔧  UTILITY")
tog(misc,"📦","Hitbox Extender","Extends nape detection radius","HitboxExtender",function(on)
    FARM.HitboxSize = on and 55 or 30
end)
tog(misc,"🔍","Shadow Ban Checker","Checks if shadowbanned","ShadowBanCheck",function(on)
    if on then
        task.spawn(function()
            local count = 0
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= lp then count=count+1 end
            end
            if count == 0 then
                warn("⚠️ POSSIBLE SHADOW BAN — No other players detected!")
            else
                warn("✅ Not shadow banned — "..count.." players in server")
            end
            T.ShadowBanCheck = false
            if toggleRefs.ShadowBanCheck then toggleRefs.ShadowBanCheck() end
        end)
    end
end)
tog(misc,"🏠","Return to Menu","Returns to main menu","ReturnMenu",function(on)
    if on then leaveToLobby() T.ReturnMenu=false if toggleRefs.ReturnMenu then toggleRefs.ReturnMenu() end end
end)
tog(misc,"🔄","Auto Rejoin","Auto rejoins on disconnect","AutoRejoin",function(on)
    if not on then return end
    task.spawn(function()
        while T.AutoRejoin do
            if #Players:GetPlayers() == 1 then
                task.wait(3)
                rejoinGame()
            end
            task.wait(5)
        end
    end)
end)
tog(misc,"🔓","Auto Escape Grab","Escapes titan grabs automatically","AutoEscape",function(on)
    if not on then return end
    task.spawn(function()
        while T.AutoEscape do
            local char = lp.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                for _, v in ipairs(char:GetDescendants()) do
                    if v:IsA("BoolValue") and v.Value then
                        local n = v.Name:lower()
                        if n:find("grab") or n:find("caught") or n:find("held") then
                            fireKw({"escape","free","break","grab","release"})
                            if hrp then hrp.CFrame = hrp.CFrame*CFrame.new(math.random(-12,12),8,math.random(-12,12)) end
                        end
                    end
                end
            end
            task.wait(0.15)
        end
    end)
end)
tog(misc,"🔄","Force Retry","Forces retry on current mission","ForceRetry",function(on)
    if on then
        fireKw({"retry","restart","respawn"})
        clickBtn({"retry","restart"})
        T.ForceRetry=false
        if toggleRefs.ForceRetry then toggleRefs.ForceRetry() end
    end
end)
tog(misc,"🔍","Auto Encounter (Dev Hop)","Hops servers for dev","AutoEncounter",function(on)
    if not on then return end
    task.spawn(function()
        while T.AutoEncounter do
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Name:lower():find("dev") or p.Name:lower():find("admin") or p.Name:lower():find("owner") then
                    warn("👑 Found possible dev: "..p.Name)
                    T.AutoEncounter = false
                    if toggleRefs.AutoEncounter then toggleRefs.AutoEncounter() end
                    return
                end
            end
            safe(function()
                local ts = game:GetService("TeleportService")
                local servers = ts:GetSortedGameInstances(game.PlaceId, 10)
                if servers and #servers > 0 then
                    ts:TeleportToPlaceInstance(game.PlaceId, servers[math.random(#servers)].Id, lp)
                end
            end)
            task.wait(rng(8))
        end
    end)
end)

-- SAFETY
local sp = tabs["Safety"]
sec(sp,"🛡  LEADERBOARD PROTECTION")
tog(sp,"🛡","Leave if Monthly Streak > X","Safety: streak leaderboard","SafeLeaveStreak",function(on)
    if not on then return end
    task.spawn(function()
        while T.SafeLeaveStreak do
            if STATS.streak >= SAFETY.MaxMonthlyStreak then
                leaveToLobby()
                warn("🛡 Safety: Left — streak too high ("..STATS.streak..")")
            end
            task.wait(10)
        end
    end)
end)
tog(sp,"🛡","Leave if Monthly Raids > X","Safety: raids leaderboard","SafeLeaveRaids",function(on)
    if not on then return end
    task.spawn(function()
        while T.SafeLeaveRaids do
            if STATS.raids >= SAFETY.MaxMonthlyRaids then
                leaveToLobby()
                warn("🛡 Safety: Left — raids too high ("..STATS.raids..")")
            end
            task.wait(10)
        end
    end)
end)
tog(sp,"🛡","Leave if Monthly Kills > X","Safety: kills leaderboard","SafeLeaveKills",function(on)
    if not on then return end
    task.spawn(function()
        while T.SafeLeaveKills do
            if STATS.kills >= SAFETY.MaxMonthlyKills then
                leaveToLobby()
                warn("🛡 Safety: Left — kills too high ("..STATS.kills..")")
            end
            task.wait(10)
        end
    end)
end)
tog(sp,"🛡","Leave if Missions > X","Safety: missions leaderboard","SafeLeaveMiss",function(on)
    if not on then return end
    task.spawn(function()
        while T.SafeLeaveMiss do
            if STATS.missions >= SAFETY.MaxMissions then
                leaveToLobby()
                warn("🛡 Safety: Left — missions too high ("..STATS.missions..")")
            end
            task.wait(10)
        end
    end)
end)
tog(sp,"👥","Leave if Max Players > X","Leaves overpopulated servers","SafeMaxPlayers",function(on)
    if not on then return end
    task.spawn(function()
        while T.SafeMaxPlayers do
            if #Players:GetPlayers() > SAFETY.MaxPlayers then
                leaveToLobby()
                warn("🛡 Safety: Left — too many players")
            end
            task.wait(10)
        end
    end)
end)
sec(sp,"⚙  SAFETY SETTINGS")
slider(sp,"Max Monthly Streak",1,9999,SAFETY.MaxMonthlyStreak,"%.0f",function(v) SAFETY.MaxMonthlyStreak=v end)
slider(sp,"Max Monthly Raids",1,9999,SAFETY.MaxMonthlyRaids,"%.0f",function(v) SAFETY.MaxMonthlyRaids=v end)
slider(sp,"Max Monthly Kills",1,9999,SAFETY.MaxMonthlyKills,"%.0f",function(v) SAFETY.MaxMonthlyKills=v end)
slider(sp,"Max Missions",1,9999,SAFETY.MaxMissions,"%.0f",function(v) SAFETY.MaxMissions=v end)
slider(sp,"Max Players in Server",2,100,SAFETY.MaxPlayers,"%.0f",function(v) SAFETY.MaxPlayers=v end)

-- WEBHOOKS
local wp = tabs["Webhooks"]
sec(wp,"🔗  WEBHOOK CONFIG")
local urlBox = Instance.new("Frame",wp)
urlBox.Size = UDim2.new(0,W,0,46)
urlBox.BackgroundColor3 = Color3.fromRGB(20,20,30)
urlBox.BorderSizePixel = 0
Instance.new("UICorner",urlBox).CornerRadius = UDim.new(0,7)
Instance.new("UIStroke",urlBox).Color = Color3.fromRGB(110,70,220)
local urlTitle = Instance.new("TextLabel",urlBox)
urlTitle.Size = UDim2.new(1,-10,0,18)
urlTitle.Position = UDim2.new(0,10,0,4)
urlTitle.BackgroundTransparency = 1
urlTitle.Text = "🔗 Webhook URL — Edit WEBHOOK.URL in script"
urlTitle.TextColor3 = Color3.fromRGB(160,120,255)
urlTitle.Font = Enum.Font.GothamBold
urlTitle.TextSize = 11
urlTitle.TextXAlignment = Enum.TextXAlignment.Left
local urlNote = Instance.new("TextLabel",urlBox)
urlNote.Size = UDim2.new(1,-10,0,16)
urlNote.Position = UDim2.new(0,10,0,24)
urlNote.BackgroundTransparency = 1
urlNote.Text = "Paste your Discord webhook URL at the top of the script"
urlNote.TextColor3 = Color3.fromRGB(100,100,140)
urlNote.Font = Enum.Font.Gotham
urlNote.TextSize = 10
urlNote.TextXAlignment = Enum.TextXAlignment.Left
sec(wp,"📋  LOG SETTINGS")
local webhookToggles = {
    {"📊","Log Stats","LogStats"},
    {"🎁","Log Items","LogItems"},
    {"⚡","Log Multipliers","LogMultipliers"},
    {"💀","Log Deaths","LogDeaths"},
    {"🔥","Ping Mythic Perks","PingMythicPerks"},
    {"💉","Ping Serum","PingSerum"},
    {"🎲","Ping Family Spins","PingFamilySpin"},
    {"⚔","Log Equipment Grade","LogEquipGrade"},
    {"🏋","Log Mastery Levels","LogMasteryLvl"},
}
for _, wt in ipairs(webhookToggles) do
    local icon, name, key = wt[1], wt[2], wt[3]
    local btn = Instance.new("TextButton",wp)
    btn.Size = UDim2.new(0,W,0,36)
    btn.BackgroundColor3 = WEBHOOK[key] and Color3.fromRGB(25,20,42) or Color3.fromRGB(20,20,30)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,7)
    local bss = Instance.new("UIStroke",btn)
    bss.Color = WEBHOOK[key] and Color3.fromRGB(110,70,220) or Color3.fromRGB(32,32,52)
    bss.Thickness = 1
    local il2 = Instance.new("TextLabel",btn)
    il2.Size = UDim2.new(0,30,1,0)
    il2.Position = UDim2.new(0,6,0,0)
    il2.BackgroundTransparency = 1
    il2.Text = icon
    il2.TextSize = 13
    il2.Font = Enum.Font.GothamBold
    local nl2 = Instance.new("TextLabel",btn)
    nl2.Size = UDim2.new(1,-72,1,0)
    nl2.Position = UDim2.new(0,32,0,0)
    nl2.BackgroundTransparency = 1
    nl2.Text = name
    nl2.TextColor3 = WEBHOOK[key] and Color3.fromRGB(190,160,255) or Color3.fromRGB(210,210,225)
    nl2.Font = Enum.Font.GothamBold
    nl2.TextSize = 12
    nl2.TextXAlignment = Enum.TextXAlignment.Left
    local pill2 = Instance.new("TextLabel",btn)
    pill2.Size = UDim2.new(0,36,0,18)
    pill2.Position = UDim2.new(1,-42,0.5,-9)
    pill2.BackgroundColor3 = WEBHOOK[key] and Color3.fromRGB(110,70,220) or Color3.fromRGB(32,32,52)
    pill2.Text = WEBHOOK[key] and "ON" or "OFF"
    pill2.TextColor3 = WEBHOOK[key] and Color3.new(1,1,1) or Color3.fromRGB(110,110,140)
    pill2.Font = Enum.Font.GothamBold
    pill2.TextSize = 10
    Instance.new("UICorner",pill2).CornerRadius = UDim.new(0,4)
    btn.MouseButton1Click:Connect(function()
        WEBHOOK[key] = not WEBHOOK[key]
        local on = WEBHOOK[key]
        btn.BackgroundColor3 = on and Color3.fromRGB(25,20,42) or Color3.fromRGB(20,20,30)
        bss.Color = on and Color3.fromRGB(110,70,220) or Color3.fromRGB(32,32,52)
        nl2.TextColor3 = on and Color3.fromRGB(190,160,255) or Color3.fromRGB(210,210,225)
        pill2.Text = on and "ON" or "OFF"
        pill2.BackgroundColor3 = on and Color3.fromRGB(110,70,220) or Color3.fromRGB(32,32,52)
        pill2.TextColor3 = on and Color3.new(1,1,1) or Color3.fromRGB(110,110,140)
    end)
end

-- LAUNCH
local lp2 = tabs["Launch"]
sec(lp2,"⚙  LAUNCH OPTIONS")
local launchDefs = {
    {"📱","Mobile Scaling","Scales UI for mobile","MobileScaling"},
    {"🔄","Reconnect on Error","Auto reconnects on errors","ReconnectError"},
    {"🐛","Debug Mode","Shows debug logs in output","DebugMode"},
    {"👻","Violet Hidden","Hides script from task list","VioletHidden"},
    {"🔄","Error Rejoin","Rejoins on critical errors","ErrorRejoin"},
}
for _, ld in ipairs(launchDefs) do
    local icon, name, desc, key = ld[1], ld[2], ld[3], ld[4]
    local btn = Instance.new("TextButton",lp2)
    btn.Size = UDim2.new(0,W,0,42)
    btn.BackgroundColor3 = LAUNCH[key] and Color3.fromRGB(25,20,42) or Color3.fromRGB(20,20,30)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,7)
    local bss = Instance.new("UIStroke",btn)
    bss.Color = LAUNCH[key] and Color3.fromRGB(110,70,220) or Color3.fromRGB(32,32,52)
    bss.Thickness = 1
    local iL = Instance.new("TextLabel",btn)
    iL.Size = UDim2.new(0,30,1,0)
    iL.Position = UDim2.new(0,6,0,0)
    iL.BackgroundTransparency = 1
    iL.Text = icon
    iL.TextSize = 14
    iL.Font = Enum.Font.GothamBold
    local nL = Instance.new("TextLabel",btn)
    nL.Size = UDim2.new(1,-82,0,19)
    nL.Position = UDim2.new(0,34,0,5)
    nL.BackgroundTransparency = 1
    nL.Text = name
    nL.TextColor3 = LAUNCH[key] and Color3.fromRGB(190,160,255) or Color3.fromRGB(210,210,225)
    nL.Font = Enum.Font.GothamBold
    nL.TextSize = 12
    nL.TextXAlignment = Enum.TextXAlignment.Left
    local dL = Instance.new("TextLabel",btn)
    dL.Size = UDim2.new(1,-82,0,12)
    dL.Position = UDim2.new(0,34,0,25)
    dL.BackgroundTransparency = 1
    dL.Text = desc
    dL.TextColor3 = Color3.fromRGB(90,90,120)
    dL.Font = Enum.Font.Gotham
    dL.TextSize = 10
    dL.TextXAlignment = Enum.TextXAlignment.Left
    local pL = Instance.new("TextLabel",btn)
    pL.Size = UDim2.new(0,36,0,18)
    pL.Position = UDim2.new(1,-42,0.5,-9)
    pL.BackgroundColor3 = LAUNCH[key] and Color3.fromRGB(110,70,220) or Color3.fromRGB(32,32,52)
    pL.Text = LAUNCH[key] and "ON" or "OFF"
    pL.TextColor3 = LAUNCH[key] and Color3.new(1,1,1) or Color3.fromRGB(110,110,140)
    pL.Font = Enum.Font.GothamBold
    pL.TextSize = 10
    Instance.new("UICorner",pL).CornerRadius = UDim.new(0,4)
    btn.MouseButton1Click:Connect(function()
        LAUNCH[key] = not LAUNCH[key]
        local on = LAUNCH[key]
        btn.BackgroundColor3 = on and Color3.fromRGB(25,20,42) or Color3.fromRGB(20,20,30)
        bss.Color = on and Color3.fromRGB(110,70,220) or Color3.fromRGB(32,32,52)
        nL.TextColor3 = on and Color3.fromRGB(190,160,255) or Color3.fromRGB(210,210,225)
        pL.Text = on and "ON" or "OFF"
        pL.BackgroundColor3 = on and Color3.fromRGB(110,70,220) or Color3.fromRGB(32,32,52)
        pL.TextColor3 = on and Color3.new(1,1,1) or Color3.fromRGB(110,110,140)
    end)
end

-- ═══════════════════════════════════════
--  MAIN HEARTBEAT
-- ═══════════════════════════════════════
local lastHit = 0
local lastEject = 0

RunService.Heartbeat:Connect(function()
    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end
    local now = tick()

    -- Auto M1
    if T.AutoM1 and now-lastHit > 0.09+math.random()*0.04 then
        local titans = getTitans(hrp, 40)
        if #titans > 0 then
            attackTitan(titans[1].model, false)
        end
        lastHit = now
    end

    -- Auto Eject
    if T.AutoEject and now-lastEject > 0.2 then
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BoolValue") and v.Value then
                local n = v.Name:lower()
                if n:find("grab") or n:find("caught") or n:find("held") then
                    fireKw({"escape","eject","free","break","grab"})
                    hrp.CFrame = hrp.CFrame*CFrame.new(math.random(-12,12),8,math.random(-12,12))
                    lastEject = now
                end
            end
        end
    end

    -- Error rejoin
    if LAUNCH.ErrorRejoin then
        if hum.Health <= 0 then
            STATS.deaths = STATS.deaths + 1
            task.wait(3)
            safe(function() rejoinGame() end)
        end
    end

    -- Status update
    local active = {}
    for k, v in pairs(T) do if v then table.insert(active, k) end end
    stLbl.Text = #active>0 and ("● "..table.concat(active,"  ·  ")) or "● Idle — All features off"
    updStats()
end)

-- Auto reconnect
if LAUNCH.ReconnectError then
    game:GetService("Players").LocalPlayer.OnTeleport:Connect(function(state)
        if state == Enum.TeleportState.Failed then
            task.wait(3)
            rejoinGame()
        end
    end)
end

warn("✅ AoTR Script v1.0 FULL loaded! — "..lp.Name)
print("📋 Tabs: Farming | Mastery | Lobby | Main Menu | ESP | Misc | Safety | Webhooks | Launch")
