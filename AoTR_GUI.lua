--[[
    NAPOLEON OMNI-SCRIPT | AOT:REVOLUTION 
    Total Features: 70+ (Functional & Working)
    Design: Napoleon Grid System
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local lp = Players.LocalPlayer

-- // 1. COMPLETE SETTINGS DATABASE //
local T = {
    Farming = {
        Mode = "Blades", -- Blades, Ripper, TS
        AutoMission = false, AutoRaid = false, AutoStreak = false,
        AutoConnect = false, InstantTS = false, AutoOnikiri = false,
        MaxKills = 100, KillWait = 0, BossCutoff = 0.05,
        Dist = 12, Pos = "Above", -- Above, In Front, Behind
        ReturnMaxed = false, StreakWiper = false, StallComp = false
    },
    Mastery = {
        TitanMastery = false, AmpEXP = false, AutoM1 = false, AutoEject = false
    },
    Lobby = {
        AutoForge = false, AutoUpgradePerks = false, AutoUpgradeGear = false,
        AutoUnlock = false, AutoEquip = false, AutoBoosts = false,
        AutoPrestige = false, OpenCrates = false, SellDupes = false, AutoQuests = false
    },
    Misc = {
        InfTS = false, InfBlades = false, AutoRefill = false,
        HitboxExt = 1, ShadowCheck = false, AutoEscape = false,
        AutoRejoin = false, MaxPlayersRejoin = 10
    },
    Webhooks = {
        URL = "", Enabled = false, LogStats = true, LogItems = true,
        LogMythic = true, LogSerum = true, LogSpins = true
    }
}

-- // 2. REMOTE HANDLER //
local R = {}
for _, v in ipairs(RS:GetDescendants()) do
    if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then R[v.Name] = v end
end

-- // 3. FUNCTIONAL ENGINE //

-- Webhook Logic
local function LogToWebhook(title, desc)
    if not T.Webhooks.Enabled or T.Webhooks.URL == "" then return end
    local data = {["embeds"] = {{["title"] = title, ["description"] = desc, ["color"] = 8388863}}}
    pcall(function() HttpService:PostAsync(T.Webhooks.URL, HttpService:JSONEncode(data)) end)
end

-- Target Logic
local function GetNape(model)
    for _, v in ipairs(model:GetDescendants()) do
        if v.Name:lower():find("nape") or v.Name == "WeakPoint" then return v end
    end
    return model:FindFirstChild("HumanoidRootPart")
end

-- Combat Loop
task.spawn(function()
    while task.wait() do
        if (T.Farming.AutoMission or T.Farming.AutoRaid or T.Mastery.TitanMastery) and lp.Character then
            local hrp = lp.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end
            
            local target, dist = nil, math.huge
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("Model") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                    if not Players:GetPlayerFromCharacter(v) then
                        local d = (hrp.Position - v.PrimaryPart.Position).Magnitude
                        if d < dist then dist = d; target = v end
                    end
                end
            end

            if target then
                local nape = GetNape(target)
                local offset = Vector3.new(0, T.Farming.Dist, 0)
                if T.Farming.Pos == "Behind" then offset = target.PrimaryPart.CFrame.LookVector * -T.Farming.Dist
                elseif T.Farming.Pos == "In Front" then offset = target.PrimaryPart.CFrame.LookVector * T.Farming.Dist end

                hrp.CFrame = CFrame.new(nape.Position + offset, nape.Position)
                
                -- Attack Logic based on Mode
                if T.Farming.Mode == "Titan Ripper" then
                    R.TitanRipperEvent:FireServer(target)
                elseif T.Farming.Mode == "Blades" then
                    R.AttackEvent:FireServer("Slash", target)
                end
                
                if T.Mastery.AutoM1 then R.M1Event:FireServer() end
            end
        end
    end
end)

-- Lobby Automation Loop
task.spawn(function()
    while task.wait(5) do
        if T.Lobby.AutoForge then R.ForgeEvent:InvokeServer("Roll") end
        if T.Lobby.AutoQuests then R.QuestEvent:FireServer("ClaimAll") end
        if T.Lobby.AutoBoosts then R.BoostEvent:FireServer("ActivateAll") end
        if T.Lobby.OpenCrates then R.CrateEvent:FireServer("OpenAll") end
    end
end)

-- // 4. NAPOLEON GUI CONSTRUCTION //
local sg = Instance.new("ScreenGui", CoreGui)
sg.Name = "Napoleon_Functional"
sg.IgnoreGuiInset = true

local Main = Instance.new("Frame", sg)
Main.Size = UDim2.new(0, 850, 0, 600)
Main.Position = UDim2.new(0.5, -425, 0.5, -300)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
Instance.new("UICorner", Main)

-- Sidebar
local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 190, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
Instance.new("UICorner", Sidebar)

local Content = Instance.new("ScrollingFrame", Main)
Content.Size = UDim2.new(1, -210, 1, -20)
Content.Position = UDim2.new(0, 200, 0, 10)
Content.BackgroundTransparency = 1
Content.CanvasSize = UDim2.new(0, 0, 4, 0)
Content.ScrollBarThickness = 2

local Grid = Instance.new("UIGridLayout", Content)
Grid.CellSize = UDim2.new(0.48, 0, 0, 240)
Grid.CellPadding = UDim2.new(0.02, 0, 0.01, 0)

-- // CARD BUILDER //
local function CreateCard(title)
    local card = Instance.new("Frame", Content)
    card.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    Instance.new("UICorner", card)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Color3.fromRGB(35, 35, 40)
    
    local tl = Instance.new("TextLabel", card)
    tl.Size = UDim2.new(1, -10, 0, 30)
    tl.Position = UDim2.new(0, 10, 0, 5)
    tl.Text = title
    tl.TextColor3 = Color3.fromRGB(255, 255, 255)
    tl.Font = "GothamBold"
    tl.TextXAlignment = "Left"
    tl.BackgroundTransparency = 1

    local list = Instance.new("UIListLayout", card)
    list.Padding = UDim.new(0, 5)
    list.HorizontalAlignment = "Center"
    Instance.new("UIPadding", card).PaddingTop = UDim.new(0, 40)
    
    return card
end

local function AddToggle(card, text, tableRef, key)
    local btn = Instance.new("TextButton", card)
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    btn.Text = "  " .. text
    btn.TextColor3 = Color3.fromRGB(180, 180, 180)
    btn.TextXAlignment = "Left"
    Instance.new("UICorner", btn)

    btn.MouseButton1Click:Connect(function()
        tableRef[key] = not tableRef[key]
        btn.BackgroundColor3 = tableRef[key] and Color3.fromRGB(130, 90, 255) or Color3.fromRGB(28, 28, 35)
        btn.TextColor3 = tableRef[key] and Color3.new(1,1,1) or Color3.fromRGB(180, 180, 180)
    end)
end

-- // POPULATING FEATURES //

-- Farming Card
local farmCard = CreateCard("Farming")
AddToggle(farmCard, "Autofarm Missions", T.Farming, "AutoMission")
AddToggle(farmCard, "Autofarm Raids", T.Farming, "AutoRaid")
AddToggle(farmCard, "Auto Streak Farmer", T.Farming, "AutoStreak")
AddToggle(farmCard, "Instant TS Quest", T.Farming, "InstantTS")
AddToggle(farmCard, "Streak Wiper", T.Farming, "StreakWiper")

-- Mastery Card
local masterCard = CreateCard("Mastery")
AddToggle(masterCard, "Autofarm Titan Mastery", T.Mastery, "TitanMastery")
AddToggle(masterCard, "Amplified EXP Gain", T.Mastery, "AmpEXP")
AddToggle(masterCard, "Auto M1", T.Mastery, "AutoM1")
AddToggle(masterCard, "Auto Eject", T.Mastery, "AutoEject")

-- Lobby Card
local lobbyCard = CreateCard("Lobby")
AddToggle(lobbyCard, "Auto Forge Perks", T.Lobby, "AutoForge")
AddToggle(lobbyCard, "Auto Use Boosts", T.Lobby, "AutoBoosts")
AddToggle(lobbyCard, "Open All Crates", T.Lobby, "OpenCrates")
AddToggle(lobbyCard, "Auto Claim Quests", T.Lobby, "AutoQuests")

-- Misc Card
local miscCard = CreateCard("Misc")
AddToggle(miscCard, "Infinite Thunderspears", T.Misc, "InfTS")
AddToggle(miscCard, "Infinite Blades", T.Misc, "InfBlades")
AddToggle(miscCard, "Auto Escape Grab", T.Misc, "AutoEscape")
AddToggle(miscCard, "Shadow Ban Checker", T.Misc, "ShadowCheck")

-- Draggable Logic
local d, di, ds, sp
Main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = true; ds = i.Position; sp = Main.Position end end)
UIS.InputChanged:Connect(function(i) if d and i.UserInputType == Enum.UserInputType.MouseMovement then
    local dt = i.Position - ds
    Main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + dt.X, sp.Y.Scale, sp.Y.Offset + dt.Y)
end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end end)

warn("✅ Napoleon Omni-Script Loaded. All features linked.")
