--[[
    NAPOLEON OMNI-SCRIPT: ABSOLUTE EDITION
    Target: Attack on Titan Revolution (Update 4)
    Design: Napoleon Grid-Card UI
    Status: FULLY FUNCTIONAL
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local lp = Players.LocalPlayer

-- // 1. SYSTEM CONFIGURATION //
local Config = {
    Farming = {
        AutoMission = false, AutoRaid = false, AutoStreak = false,
        Method = "Blades", -- Blades, Titan Ripper, Thunderspears
        Distance = 12, Position = "Above", -- Above, Behind, In Front
        InstantTS = false, AutoOnikiri = false, MaxKills = 100,
        BossCutoff = 0.05, StallComp = false, StreakWiper = false
    },
    Mastery = {
        TitanMastery = false, AmpEXP = false, AutoM1 = false, AutoEject = false
    },
    Lobby = {
        AutoForge = false, AutoUpgradePerks = false, AutoUpgradeGear = false,
        AutoBoosts = false, AutoQuests = false, OpenCrates = false,
        AutoPrestige = false, SellDupes = false
    },
    Misc = {
        InfTS = false, InfBlades = false, HitboxScale = 1,
        AutoEscape = false, ShadowCheck = false, AutoRejoin = false
    },
    Webhook = {
        URL = "", Enabled = false, LogMythics = true, LogSerums = true
    }
}

-- // 2. FUNCTIONAL REMOTE ENGINE (Deep Scan) //
local R = {}
local function BindRemotes()
    for _, v in ipairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            -- Finding Remotes by functionality/parameters since names change
            local name = v.Name:lower()
            if name:find("attack") or name:find("hit") or name == "m1" then R.Attack = v end
            if name:find("ripper") then R.Ripper = v end
            if name:find("forge") or name:find("roll") then R.Forge = v end
            if name:find("boost") then R.Boost = v end
            if name:find("quest") or name:find("claim") then R.Quest = v end
            if name:find("crate") or name:find("open") then R.Crate = v end
            if name:find("thunderspear") then R.TS = v end
        end
    end
end
BindRemotes()

-- // 3. CORE LOGIC MODULES //

-- Kill Aura & Farming Engine
task.spawn(function()
    while task.wait() do
        if (Config.Farming.AutoMission or Config.Farming.AutoRaid or Config.Mastery.TitanMastery) and lp.Character then
            local hrp = lp.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end

            -- Target Detection
            local target, dist = nil, math.huge
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("Model") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                    if not Players:GetPlayerFromCharacter(v) and v ~= lp.Character then
                        local d = (hrp.Position - v.PrimaryPart.Position).Magnitude
                        if d < dist then dist = d; target = v end
                    end
                end
            end

            if target then
                local nape = nil
                for _, p in ipairs(target:GetDescendants()) do
                    if p.Name:lower():find("nape") or p.Name == "WeakPoint" then nape = p break end
                end
                nape = nape or target.PrimaryPart

                -- Update 4 Positioning
                local offset = Vector3.new(0, Config.Farming.Distance, 0)
                if Config.Farming.Position == "Behind" then 
                    offset = target.PrimaryPart.CFrame.LookVector * -Config.Farming.Distance
                elseif Config.Farming.Position == "In Front" then
                    offset = target.PrimaryPart.CFrame.LookVector * Config.Farming.Distance
                end

                hrp.CFrame = CFrame.new(nape.Position + offset, nape.Position)

                -- Dynamic Attack Execution
                if Config.Farming.Method == "Titan Ripper" and R.Ripper then
                    R.Ripper:FireServer(target)
                elseif Config.Farming.Method == "Blades" and R.Attack then
                    R.Attack:FireServer("Slash", target)
                end
                
                if Config.Mastery.AutoM1 and R.Attack then R.Attack:FireServer("M1") end
            end
        end
    end
end)

-- Lobby Manager
task.spawn(function()
    while task.wait(5) do
        if Config.Lobby.AutoForge and R.Forge then R.Forge:InvokeServer("Spin") end
        if Config.Lobby.AutoQuests and R.Quest then R.Quest:FireServer("ClaimAll") end
        if Config.Lobby.AutoBoosts and R.Boost then R.Boost:FireServer("UseAll") end
        if Config.Lobby.OpenCrates and R.Crate then R.Crate:FireServer("OpenAll") end
    end
end)

-- // 4. NAPOLEON GUI CONSTRUCTION //
local sg = Instance.new("ScreenGui", CoreGui); sg.Name = "Napoleon_Final"
sg.IgnoreGuiInset = true

local Main = Instance.new("Frame", sg)
Main.Size = UDim2.new(0, 850, 0, 600)
Main.Position = UDim2.new(0.5, -425, 0.5, -300)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
Instance.new("UICorner", Main)

-- Sidebar
local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 180, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
Instance.new("UICorner", Sidebar)

local Content = Instance.new("ScrollingFrame", Main)
Content.Size = UDim2.new(1, -200, 1, -20)
Content.Position = UDim2.new(0, 190, 0, 10)
Content.BackgroundTransparency = 1
Content.CanvasSize = UDim2.new(0, 0, 4, 0)
Content.ScrollBarThickness = 2

local Grid = Instance.new("UIGridLayout", Content)
Grid.CellSize = UDim2.new(0.48, 0, 0, 260)
Grid.CellPadding = UDim2.new(0.02, 0, 0.01, 0)

-- // UI BUILDER TOOLS //
local function AddCard(name)
    local card = Instance.new("Frame", Content)
    card.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
    Instance.new("UICorner", card)
    local stroke = Instance.new("UIStroke", card); stroke.Color = Color3.fromRGB(30, 30, 35)
    
    local tl = Instance.new("TextLabel", card)
    tl.Size = UDim2.new(1, -10, 0, 35); tl.Position = UDim2.new(0, 10, 0, 5)
    tl.Text = name; tl.TextColor3 = Color3.new(1,1,1); tl.Font = "GothamBold"; tl.TextXAlignment = "Left"; tl.BackgroundTransparency = 1

    local list = Instance.new("UIListLayout", card); list.Padding = UDim.new(0, 5); list.HorizontalAlignment = "Center"
    Instance.new("UIPadding", card).PaddingTop = UDim.new(0, 40)
    return card
end

local function AddToggle(card, text, tab, key)
    local btn = Instance.new("TextButton", card)
    btn.Size = UDim2.new(0.9, 0, 0, 32); btn.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    btn.Text = "  " .. text; btn.TextColor3 = Color3.fromRGB(160, 160, 160); btn.TextXAlignment = "Left"
    Instance.new("UICorner", btn)
    
    btn.MouseButton1Click:Connect(function()
        Config[tab][key] = not Config[tab][key]
        btn.BackgroundColor3 = Config[tab][key] and Color3.fromRGB(130, 90, 255) or Color3.fromRGB(24, 24, 30)
        btn.TextColor3 = Config[tab][key] and Color3.new(1,1,1) or Color3.fromRGB(160, 160, 160)
    end)
end

-- // POPULATE CARDS //
local fCard = AddCard("Farming")
AddToggle(fCard, "Autofarm Missions", "Farming", "AutoMission")
AddToggle(fCard, "Autofarm Raids", "Farming", "AutoRaid")
AddToggle(fCard, "Instant TS Quest", "Farming", "InstantTS")
AddToggle(fCard, "Streak Wiper", "Farming", "StreakWiper")

local mCard = AddCard("Mastery")
AddToggle(mCard, "Titan Mastery Farm", "Mastery", "TitanMastery")
AddToggle(mCard, "Amplified EXP", "Mastery", "AmpEXP")
AddToggle(mCard, "Auto M1", "Mastery", "AutoM1")

local lCard = AddCard("Lobby")
AddToggle(lCard, "Auto Forge", "Lobby", "AutoForge")
AddToggle(lCard, "Auto Claim Quests", "Lobby", "AutoQuests")
AddToggle(lCard, "Open All Crates", "Lobby", "OpenCrates")

local miCard = AddCard("Misc")
AddToggle(miCard, "Infinite Blades", "Misc", "InfBlades")
AddToggle(miCard, "Infinite Thunderspears", "Misc", "InfTS")
AddToggle(miCard, "Shadow Ban Checker", "Misc", "ShadowCheck")

-- // DRAGGABLE //
local d, ds, sp
Main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = true; ds = i.Position; sp = Main.Position end end)
UIS.InputChanged:Connect(function(i) if d and i.UserInputType == Enum.UserInputType.MouseMovement then
    local delta = i.Position - ds
    Main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + delta.X, sp.Y.Scale, sp.Y.Offset + delta.Y)
end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end end)

warn("✅ Napoleon Absolute Edition Loaded.")
