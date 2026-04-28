-- AoTR GUI | by Taishotokiyo
-- Clean tab-based GUI, executor compatible

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

repeat task.wait(0.1) until lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
task.wait(0.5)

pcall(function()
    local o = game:GetService("CoreGui"):FindFirstChild("AOTR_GUI")
    if o then o:Destroy() end
end)

-- STATE
local T = {
    AutoFarm = false,
    AutoRaid = false,
    AutoExecute = false,
    TitanESP = false,
    AutoReload = false,
    InfiniteGas = false,
    SpeedBoost = false,
    AutoMission = false,
    AutoChest = false,
    AutoEscape = false,
    HitboxExtend = false,
    AutoRetry = false,
}

local STATS = {kills=0, missions=0, raids=0}
local lastHit = 0
local espFolder = nil

-- HELPERS
local function safe(f) pcall(f) end
local function rng(n) return n + (math.random()-0.5)*n*0.2 end

local function fireKw(kws, a1, a2)
    for _, folder in ipairs({RS, workspace}) do
        safe(function()
            for _, r in ipairs(folder:GetDescendants()) do
                if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
                    local n = r.Name:lower()
                    for _, k in ipairs(kws) do
                        if n:find(k, 1, true) then
                            safe(function()
                                if r:IsA("RemoteEvent") then r:FireServer(a1, a2)
                                else r:InvokeServer(a1, a2) end
                            end)
                        end
                    end
                end
            end
        end)
    end
end

local NAPE_TAGS = {"nape","napehit","weakpoint","weak","neck","killzone"}
local function getNape(m)
    for _, p in ipairs(m:GetDescendants()) do
        if p:IsA("BasePart") then
            local n = p.Name:lower()
            for _, t in ipairs(NAPE_TAGS) do
                if n:find(t, 1, true) then return p end
            end
        end
    end
    return m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso")
end

local function nearTitan(hrp)
    local best, bestM, bestD = nil, nil, math.huge
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("Model") and o ~= lp.Character and not Players:GetPlayerFromCharacter(o) then
            local h = o:FindFirstChildOfClass("Humanoid")
            local r = o:FindFirstChild("HumanoidRootPart") or o:FindFirstChild("Torso")
            if h and r and h.Health > 0 then
                local d = (hrp.Position - r.Position).Magnitude
                if d < bestD then bestD=d; best=r; bestM=o end
            end
        end
    end
    return best, bestM, bestD
end

-- ══════════════════════════════════════
-- GUI
-- ══════════════════════════════════════
local CoreGui = game:GetService("CoreGui")

local sg = Instance.new("ScreenGui")
sg.Name = "AOTR_GUI"
sg.ResetOnSpawn = false
sg.DisplayOrder = 999
sg.IgnoreGuiInset = true
sg.Parent = CoreGui

-- MAIN WINDOW
local win = Instance.new("Frame", sg)
win.Size = UDim2.new(0, 480, 0, 340)
win.Position = UDim2.new(0.5, -240, 0.5, -170)
win.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
win.BorderSizePixel = 0
win.Active = true
win.Draggable = true
win.ClipsDescendants = true
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 10)
local winStroke = Instance.new("UIStroke", win)
winStroke.Color = Color3.fromRGB(40, 40, 65)
winStroke.Thickness = 1.5

-- TOP BAR
local topBar = Instance.new("Frame", win)
topBar.Size = UDim2.new(1, 0, 0, 36)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
topBar.BorderSizePixel = 0

local logo = Instance.new("TextLabel", topBar)
logo.Size = UDim2.new(0, 200, 1, 0)
logo.Position = UDim2.new(0, 12, 0, 0)
logo.BackgroundTransparency = 1
logo.Text = "⚔ AoTR Script  |  v1"
logo.TextColor3 = Color3.fromRGB(255, 255, 255)
logo.Font = Enum.Font.GothamBold
logo.TextSize = 13
logo.TextXAlignment = Enum.TextXAlignment.Left

local byLbl = Instance.new("TextLabel", topBar)
byLbl.Size = UDim2.new(0, 160, 1, 0)
byLbl.Position = UDim2.new(0, 200, 0, 0)
byLbl.BackgroundTransparency = 1
byLbl.Text = "by Taishotokiyo"
byLbl.TextColor3 = Color3.fromRGB(100, 100, 140)
byLbl.Font = Enum.Font.Gotham
byLbl.TextSize = 11
byLbl.TextXAlignment = Enum.TextXAlignment.Left

-- Stats label top right
local statsTop = Instance.new("TextLabel", topBar)
statsTop.Size = UDim2.new(0, 200, 1, 0)
statsTop.Position = UDim2.new(1, -210, 0, 0)
statsTop.BackgroundTransparency = 1
statsTop.Text = "⚔0  🎮0  🔴0"
statsTop.TextColor3 = Color3.fromRGB(150, 150, 200)
statsTop.Font = Enum.Font.Gotham
statsTop.TextSize = 11
statsTop.TextXAlignment = Enum.TextXAlignment.Right

local function updStats()
    statsTop.Text = string.format("⚔%d Kills  🎮%d Miss  🔴%d Raids", STATS.kills, STATS.missions, STATS.raids)
end

-- Close/minimize buttons
local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -30, 0.5, -12)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 11
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 5)
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

local minBtn = Instance.new("TextButton", topBar)
minBtn.Size = UDim2.new(0, 24, 0, 24)
minBtn.Position = UDim2.new(1, -58, 0.5, -12)
minBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
minBtn.Text = "—"
minBtn.TextColor3 = Color3.new(1,1,1)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 11
minBtn.BorderSizePixel = 0
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 5)
local mini = false
minBtn.MouseButton1Click:Connect(function()
    mini = not mini
    win.Size = mini and UDim2.new(0,480,0,36) or UDim2.new(0,480,0,340)
    minBtn.Text = mini and "+" or "—"
end)

-- LEFT TAB BAR
local tabBar = Instance.new("Frame", win)
tabBar.Size = UDim2.new(0, 110, 1, -36)
tabBar.Position = UDim2.new(0, 0, 0, 36)
tabBar.BackgroundColor3 = Color3.fromRGB(18, 18, 27)
tabBar.BorderSizePixel = 0

local tabLayout = Instance.new("UIListLayout", tabBar)
tabLayout.Padding = UDim.new(0, 2)
local tabPad = Instance.new("UIPadding", tabBar)
tabPad.PaddingTop = UDim.new(0, 8)
tabPad.PaddingLeft = UDim.new(0, 6)
tabPad.PaddingRight = UDim.new(0, 6)

-- CONTENT AREA
local content = Instance.new("Frame", win)
content.Size = UDim2.new(1, -110, 1, -36)
content.Position = UDim2.new(0, 110, 0, 36)
content.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
content.BorderSizePixel = 0

-- Divider line
local div = Instance.new("Frame", win)
div.Size = UDim2.new(0, 1, 1, -36)
div.Position = UDim2.new(0, 110, 0, 36)
div.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
div.BorderSizePixel = 0

-- STATUS BAR BOTTOM
local stBar = Instance.new("Frame", win)
stBar.Size = UDim2.new(1, -110, 0, 22)
stBar.Position = UDim2.new(0, 110, 1, -22)
stBar.BackgroundColor3 = Color3.fromRGB(18, 18, 27)
stBar.BorderSizePixel = 0

local stLbl = Instance.new("TextLabel", stBar)
stLbl.Size = UDim2.new(1, -8, 1, 0)
stLbl.Position = UDim2.new(0, 8, 0, 0)
stLbl.BackgroundTransparency = 1
stLbl.Text = "● Idle"
stLbl.TextColor3 = Color3.fromRGB(120, 120, 160)
stLbl.Font = Enum.Font.Gotham
stLbl.TextSize = 10
stLbl.TextXAlignment = Enum.TextXAlignment.Left

-- ══════════════════════════════════════
-- TAB + TOGGLE SYSTEM
-- ══════════════════════════════════════
local tabs = {}
local tabBtns = {}
local currentTab = nil
local toggleRefs = {}

local function createTabPage()
    local page = Instance.new("ScrollingFrame", content)
    page.Size = UDim2.new(1, 0, 1, -22)
    page.Position = UDim2.new(0, 0, 0, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 120)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    local ll = Instance.new("UIListLayout", page)
    ll.Padding = UDim.new(0, 4)
    ll.HorizontalAlignment = Enum.HorizontalAlignment.Center
    local lp2 = Instance.new("UIPadding", page)
    lp2.PaddingTop = UDim.new(0, 8)
    lp2.PaddingBottom = UDim.new(0, 8)
    return page
end

local function addTab(icon, name)
    local page = createTabPage()
    tabs[name] = page

    local btn = Instance.new("TextButton", tabBar)
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local iLbl = Instance.new("TextLabel", btn)
    iLbl.Size = UDim2.new(0, 24, 1, 0)
    iLbl.Position = UDim2.new(0, 6, 0, 0)
    iLbl.BackgroundTransparency = 1
    iLbl.Text = icon
    iLbl.TextSize = 14
    iLbl.Font = Enum.Font.GothamBold

    local nLbl = Instance.new("TextLabel", btn)
    nLbl.Size = UDim2.new(1, -30, 1, 0)
    nLbl.Position = UDim2.new(0, 28, 0, 0)
    nLbl.BackgroundTransparency = 1
    nLbl.Text = name
    nLbl.TextColor3 = Color3.fromRGB(160, 160, 200)
    nLbl.Font = Enum.Font.Gotham
    nLbl.TextSize = 11
    nLbl.TextXAlignment = Enum.TextXAlignment.Left

    tabBtns[name] = {btn=btn, lbl=nLbl}

    btn.MouseButton1Click:Connect(function()
        -- hide all pages
        for _, p in pairs(tabs) do p.Visible = false end
        -- reset all tab buttons
        for _, tb in pairs(tabBtns) do
            tb.btn.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
            tb.lbl.TextColor3 = Color3.fromRGB(160, 160, 200)
        end
        -- show this page
        page.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
        nLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        currentTab = name
    end)

    return page
end

local function tog(page, icon, name, desc, key, cb)
    local btn = Instance.new("TextButton", page)
    btn.Size = UDim2.new(0, 340, 0, 44)
    btn.BackgroundColor3 = Color3.fromRGB(22, 22, 34)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    local bs = Instance.new("UIStroke", btn)
    bs.Color = Color3.fromRGB(35, 35, 55)
    bs.Thickness = 1

    local il = Instance.new("TextLabel", btn)
    il.Size = UDim2.new(0, 32, 1, 0)
    il.BackgroundTransparency = 1
    il.Text = icon
    il.TextSize = 14
    il.Font = Enum.Font.GothamBold

    local nl = Instance.new("TextLabel", btn)
    nl.Size = UDim2.new(1, -80, 0, 20)
    nl.Position = UDim2.new(0, 32, 0, 5)
    nl.BackgroundTransparency = 1
    nl.Text = name
    nl.TextColor3 = Color3.fromRGB(210, 210, 220)
    nl.Font = Enum.Font.GothamBold
    nl.TextSize = 12
    nl.TextXAlignment = Enum.TextXAlignment.Left

    local dl = Instance.new("TextLabel", btn)
    dl.Size = UDim2.new(1, -80, 0, 13)
    dl.Position = UDim2.new(0, 32, 0, 26)
    dl.BackgroundTransparency = 1
    dl.Text = desc
    dl.TextColor3 = Color3.fromRGB(100, 100, 130)
    dl.Font = Enum.Font.Gotham
    dl.TextSize = 10
    dl.TextXAlignment = Enum.TextXAlignment.Left

    -- Toggle pill
    local pill = Instance.new("Frame", btn)
    pill.Size = UDim2.new(0, 36, 0, 18)
    pill.Position = UDim2.new(1, -44, 0.5, -9)
    pill.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
    pill.BorderSizePixel = 0
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    local dot = Instance.new("Frame", pill)
    dot.Size = UDim2.new(0, 12, 0, 12)
    dot.Position = UDim2.new(0, 3, 0.5, -6)
    dot.BackgroundColor3 = Color3.fromRGB(80, 80, 110)
    dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local function refresh()
        local on = T[key]
        btn.BackgroundColor3 = on and Color3.fromRGB(28, 22, 42) or Color3.fromRGB(22, 22, 34)
        bs.Color = on and Color3.fromRGB(100, 60, 200) or Color3.fromRGB(35, 35, 55)
        nl.TextColor3 = on and Color3.fromRGB(200, 170, 255) or Color3.fromRGB(210, 210, 220)
        pill.BackgroundColor3 = on and Color3.fromRGB(100, 60, 200) or Color3.fromRGB(35, 35, 55)
        dot.BackgroundColor3 = on and Color3.new(1,1,1) or Color3.fromRGB(80, 80, 110)
        dot.Position = on and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
    end

    btn.MouseButton1Click:Connect(function()
        T[key] = not T[key]
        refresh()
        if cb then task.spawn(cb, T[key]) end
    end)

    toggleRefs[key] = refresh
    refresh()
end

-- ══════════════════════════════════════
-- BUILD TABS
-- ══════════════════════════════════════
local farmPage  = addTab("⚔", "Farm")
local raidPage  = addTab("🔴", "Raid")
local gearPage  = addTab("🔧", "Gear")
local visualPage = addTab("👁", "Visual")
local miscPage  = addTab("⚙", "Misc")

-- Show first tab
tabs["Farm"].Visible = true
tabBtns["Farm"].btn.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
tabBtns["Farm"].lbl.TextColor3 = Color3.fromRGB(255, 255, 255)

-- FARM TAB
tog(farmPage, "⚔", "Auto Farm Missions", "Kills titans in missions", "AutoFarm", function(on)
    if not on then return end
    task.spawn(function()
        while T.AutoFarm do
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local root, model = nearTitan(hrp)
                if model and root then
                    local nape = getNape(model)
                    local tgt = nape or root
                    hrp.CFrame = CFrame.new(tgt.Position + Vector3.new(0, 12, -3))
                    task.wait(0.05)
                    if (hrp.Position - tgt.Position).Magnitude < 30 then
                        fireKw({"attack","slash","nape","kill","hit","damage"}, model)
                        task.wait(0.04)
                        hrp.CFrame = CFrame.new(tgt.Position + Vector3.new(0, 3, 0))
                        task.wait(0.03)
                        fireKw({"attack","slash","nape","kill","hit"}, model)
                        local th = model:FindFirstChildOfClass("Humanoid")
                        if th and th.Health < th.MaxHealth * 0.1 then
                            STATS.kills = STATS.kills + 1
                            updStats()
                        end
                    end
                end
            end
            task.wait(rng(0.1))
        end
    end)
end)

tog(farmPage, "🎯", "Auto Execute (Nape)", "Teleports to nape & executes", "AutoExecute", function(on)
    if not on then return end
    task.spawn(function()
        while T.AutoExecute do
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local root, model = nearTitan(hrp)
                if model then
                    local nape = getNape(model)
                    if nape then
                        hrp.CFrame = CFrame.new(nape.Position + Vector3.new(0, 5, 0))
                        task.wait(0.04)
                        fireKw({"attack","nape","execute","kill","slash","hit"}, model)
                        STATS.kills = STATS.kills + 1
                        updStats()
                    end
                end
            end
            task.wait(rng(0.08))
        end
    end)
end)

tog(farmPage, "🚀", "Auto Mission Connect", "Auto joins missions", "AutoMission", function(on)
    if not on then return end
    task.spawn(function()
        while T.AutoMission do
            fireKw({"mission","start","join","play","begin"})
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    local n = (obj.ActionText or ""):lower()
                    if n:find("start") or n:find("mission") or n:find("play") then
                        safe(function() obj.Triggered:Fire(lp) end)
                    end
                end
            end
            STATS.missions = STATS.missions + 1
            updStats()
            task.wait(rng(55))
        end
    end)
end)

tog(farmPage, "🔄", "Auto Retry", "Auto clicks retry after death", "AutoRetry", function(on)
    if not on then return end
    task.spawn(function()
        while T.AutoRetry do
            for _, obj in ipairs(lp.PlayerGui:GetDescendants()) do
                if obj:IsA("TextButton") then
                    local t = obj.Text:lower()
                    if t:find("retry") or t:find("restart") or t:find("play again") then
                        safe(function() obj.MouseButton1Click:Fire() end)
                    end
                end
            end
            task.wait(rng(3))
        end
    end)
end)

-- RAID TAB
tog(raidPage, "🔴", "Auto Farm Raids", "Farms raid waves automatically", "AutoRaid", function(on)
    if not on then return end
    task.spawn(function()
        while T.AutoRaid do
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local root, model = nearTitan(hrp)
                if model and root then
                    local nape = getNape(model)
                    local tgt = nape or root
                    hrp.CFrame = CFrame.new(tgt.Position + Vector3.new(0, 12, -3))
                    task.wait(0.05)
                    fireKw({"attack","slash","nape","kill","hit","thunderspear","ts"}, model)
                    task.wait(0.04)
                    hrp.CFrame = CFrame.new(tgt.Position + Vector3.new(0, 3, 0))
                    task.wait(0.03)
                    fireKw({"attack","nape","kill","hit"}, model)
                    local th = model:FindFirstChildOfClass("Humanoid")
                    if th and th.Health < th.MaxHealth * 0.1 then
                        STATS.raids = STATS.raids + 1
                        updStats()
                    end
                end
            end
            task.wait(rng(0.1))
        end
    end)
end)

tog(raidPage, "📦", "Auto Open Raid Chests", "Opens chests after raid", "AutoChest", function(on)
    if not on then return end
    task.spawn(function()
        while T.AutoChest do
            fireKw({"chest","open","loot","claim","reward","collect"})
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    local n = (obj.ActionText or ""):lower()
                    if n:find("open") or n:find("chest") or n:find("claim") then
                        safe(function() obj.Triggered:Fire(lp) end)
                    end
                end
            end
            task.wait(rng(2))
        end
    end)
end)

-- GEAR TAB
tog(gearPage, "🗡", "Auto Reload Blades", "Reloads blades & spears", "AutoReload", function(on)
    if not on then return end
    task.spawn(function()
        while T.AutoReload do
            fireKw({"reload","refill","blade","spear","ammo"})
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    local n = (obj.ActionText or ""):lower()
                    if n:find("reload") or n:find("refill") or n:find("blade") then
                        safe(function() obj.Triggered:Fire(lp) end)
                    end
                end
            end
            task.wait(rng(1.5))
        end
    end)
end)

tog(gearPage, "⛽", "Infinite Gas", "Keeps gas maxed out", "InfiniteGas", function(on)
    if not on then return end
    task.spawn(function()
        while T.InfiniteGas do
            for _, v in ipairs(lp:GetDescendants()) do
                if (v.Name:lower():find("gas") or v.Name:lower():find("fuel")) then
                    safe(function() v.Value = 9999 end)
                end
            end
            task.wait(0.2)
        end
    end)
end)

tog(gearPage, "🏃", "Speed Boost", "3x walk speed", "SpeedBoost", function(on)
    local char = lp.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = on and 60 or 16 end
    end
end)

-- VISUAL TAB
tog(visualPage, "🔴", "Titan ESP", "Red box on titans, yellow on nape", "TitanESP", function(on)
    if espFolder then espFolder:Destroy(); espFolder = nil end
    if not on then return end
    espFolder = Instance.new("Folder", workspace)
    espFolder.Name = "_AOTR_ESP"
    task.spawn(function()
        while T.TitanESP do
            for _, o in ipairs(workspace:GetDescendants()) do
                if o:IsA("Model") and not Players:GetPlayerFromCharacter(o) and o ~= lp.Character then
                    local h = o:FindFirstChildOfClass("Humanoid")
                    if h and h.Health > 0 and not o:FindFirstChild("_ESPhl") then
                        local hl = Instance.new("Highlight", espFolder)
                        hl.Name = "_ESPhl"
                        hl.Adornee = o
                        hl.FillColor = Color3.fromRGB(200, 28, 28)
                        hl.OutlineColor = Color3.fromRGB(255, 80, 80)
                        hl.FillTransparency = 0.5
                        hl.OutlineTransparency = 0
                        local nape = getNape(o)
                        if nape and not nape:FindFirstChild("_NAPEhl") then
                            local nh = Instance.new("Highlight", espFolder)
                            nh.Name = "_NAPEhl"
                            nh.Adornee = nape
                            nh.FillColor = Color3.fromRGB(255, 220, 0)
                            nh.OutlineColor = Color3.fromRGB(255, 255, 100)
                            nh.FillTransparency = 0.3
                            nh.OutlineTransparency = 0
                        end
                    end
                end
            end
            task.wait(1.5)
        end
        if espFolder then espFolder:Destroy(); espFolder = nil end
    end)
end)

tog(visualPage, "📦", "Hitbox Extender", "Makes nape hitbox bigger", "HitboxExtend")

-- MISC TAB
tog(miscPage, "🔓", "Auto Escape Grab", "Escapes titan grabs", "AutoEscape", function(on)
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
                            if hrp then
                                hrp.CFrame = hrp.CFrame * CFrame.new(math.random(-12,12), 8, math.random(-12,12))
                            end
                        end
                    end
                end
            end
            task.wait(0.15)
        end
    end)
end)

tog(miscPage, "🙈", "Hide UI", "Hides game UI", "HideUI", function(on)
    safe(function() game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, not on) end)
    for _, g in ipairs(lp.PlayerGui:GetChildren()) do
        if g.Name ~= "AOTR_GUI" then
            safe(function() g.Enabled = not on end)
        end
    end
end)

-- ══════════════════════════════════════
-- HEARTBEAT
-- ══════════════════════════════════════
RunService.Heartbeat:Connect(function()
    local active = {}
    for k, v in pairs(T) do if v then table.insert(active, k) end end
    stLbl.Text = #active > 0 and ("● " .. table.concat(active, "  ·  ")) or "● Idle"
end)

warn("✅ AoTR GUI loaded!")
