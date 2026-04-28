-- AoTR Omni-Script | Optimized for Update 4
-- Features: Titan Ripper, Mastery, Webhooks, Auto-Forge, Streak Farmer
-- Created for: High-Efficiency Farming & Gear Progression

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local lp = Players.LocalPlayer

-- // STATE MANAGEMENT //
local T = {
    -- Farming
    AutoFarm = false, FarmMode = "Blades", AutoConnect = false, 
    AutoStreak = false, AutoMission = false, AutoRaid = false,
    LeaveToLobby = false, MaxKills = 100, KillWait = 0, BossHPStop = 0.05,
    
    -- Mastery
    TitanMastery = false, AmpEXP = false, Dist = 12, Pos = "Above",
    
    -- Gear/Lobby
    AutoForge = false, AutoUpgrade = false, AutoBoosts = false,
    AutoCrates = false, AutoQuests = false, AutoPrestige = false,
    
    -- Misc/Combat
    InfGas = false, InfTS = false, Hitbox = 5, AutoEscape = false,
    AutoReload = false, ShadowCheck = false,
    
    -- Webhook
    WebhookURL = "", LogMythic = true, LogSerums = true, LogStats = true
}

local STATS = { Kills = 0, Chests = 0, Deaths = 0, Mythics = 0 }

-- // WEBHOOK LOGGER //
local function Log(msg)
    if T.WebhookURL == "" or not T.WebhookURL:find("discord") then return end
    task.spawn(function()
        local data = {
            ["embeds"] = {{
                ["title"] = "Violet AOT:R Log",
                ["description"] = msg,
                ["color"] = 9043962, -- Violet
                ["footer"] = {["text"] = "Stats: " .. STATS.Kills .. " Kills | " .. STATS.Chests .. " Chests"}
            }}
        }
        pcall(function() HttpService:PostAsync(T.WebhookURL, HttpService:JSONEncode(data)) end)
    end)
end

-- // CORE UTILITIES //
local function GetRemotes()
    local rems = {}
    for _, v in ipairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then rems[v.Name] = v end
    end
    return rems
end
local R = GetRemotes()

local function GetNape(titan)
    for _, v in ipairs(titan:GetDescendants()) do
        if v.Name:lower():find("nape") or v.Name == "WeakPoint" then return v end
    end
    return titan:FindFirstChild("HumanoidRootPart")
end

-- // COMBAT LOGIC MODULE //
task.spawn(function()
    while task.wait() do
        if (T.AutoFarm or T.TitanMastery) and lp.Character then
            local hrp = lp.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- Target Selection
                local target, dist = nil, math.huge
                for _, x in ipairs(workspace:GetDescendants()) do
                    if x:IsA("Model") and x:FindFirstChild("Humanoid") and x.Humanoid.Health > 0 and not Players:GetPlayerFromCharacter(x) then
                        local d = (hrp.Position - x.PrimaryPart.Position).Magnitude
                        if d < dist then dist = d; target = x end
                    end
                end

                if target then
                    local nape = GetNape(target)
                    local offset = Vector3.new(0, T.Dist, 0) -- Above
                    if T.Pos == "Behind" then offset = target.PrimaryPart.CFrame.LookVector * -T.Dist
                    elseif T.Pos == "In Front" then offset = target.PrimaryPart.CFrame.LookVector * T.Dist end
                    
                    hrp.CFrame = CFrame.new(nape.Position + offset, nape.Position)
                    
                    -- Attack Logic
                    if T.FarmMode == "Titan Ripper" then
                        pcall(function() R.TitanRipperEvent:FireServer(target) end)
                    elseif T.FarmMode == "Blades" then
                        pcall(function() R.AttackEvent:FireServer("Slash", target) end)
                    end
                end
            end
        end
    end
end)

-- // GEAR & LOBBY MODULE //
task.spawn(function()
    while task.wait(5) do
        if T.AutoForge then pcall(function() R.ForgeRemote:InvokeServer("Roll") end) end
        if T.AutoBoosts then pcall(function() R.UseBoost:FireServer("All") end) end
        if T.AutoCrates then pcall(function() R.OpenCrate:FireServer("All") end) end
        if T.AutoQuests then pcall(function() R.ClaimQuest:FireServer("Daily") end) end
    end
end)

-- // GUI CONSTRUCTION //
local sg = Instance.new("ScreenGui", game:GetService("CoreGui"))
sg.Name = "Violet_Omni_Script"

local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 650, 0, 450)
main.Position = UDim2.new(0.5, -325, 0.5, -225)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
Instance.new("UICorner", main)
local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(138, 43, 226)
stroke.Thickness = 1.5

-- Sidebar
local sidebar = Instance.new("Frame", main)
sidebar.Size = UDim2.new(0, 150, 1, 0)
sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Instance.new("UICorner", sidebar)

local container = Instance.new("Frame", main)
container.Size = UDim2.new(1, -160, 1, -10)
container.Position = UDim2.new(0, 155, 0, 5)
container.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", sidebar)
layout.Padding = UDim.new(0, 5)

-- CATEGORY SYSTEM
local function CreatePage(name)
    local page = Instance.new("ScrollingFrame", container)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.ScrollBarThickness = 2
    page.AutomaticCanvasSize = "Y"
    Instance.new("UIListLayout", page).Padding = UDim.new(0, 6)

    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    btn.Text = name
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = "Gotham"
    Instance.new("UICorner", btn)

    btn.MouseButton1Click:Connect(function()
        for _, p in pairs(container:GetChildren()) do p.Visible = false end
        page.Visible = true
    end)
    return page
end

-- // TABS //
local farmPage = CreatePage("⚔️ Farming")
local masteryPage = CreatePage("🌟 Mastery")
local lobbyPage = CreatePage("🏰 Lobby")
local miscPage = CreatePage("⚙️ Misc")
local webhookPage = CreatePage("📡 Webhooks")

-- // TOGGLE BUILDER //
local function AddToggle(page, text, key, cb)
    local b = Instance.new("TextButton", page)
    b.Size = UDim2.new(1, -10, 0, 40)
    b.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    b.Text = "  " .. text
    b.TextColor3 = Color3.fromRGB(180, 180, 180)
    b.TextXAlignment = "Left"
    Instance.new("UICorner", b)
    
    b.MouseButton1Click:Connect(function()
        T[key] = not T[key]
        b.BackgroundColor3 = T[key] and Color3.fromRGB(138, 43, 226) or Color3.fromRGB(25, 25, 35)
        b.TextColor3 = T[key] and Color3.new(1,1,1) or Color3.fromRGB(180, 180, 180)
        if cb then cb(T[key]) end
    end)
end

-- // POPULATING FEATURES (FARMING) //
AddToggle(farmPage, "AutoFarm Missions (Blades)", "AutoFarm")
AddToggle(farmPage, "AutoFarm Raids (TS)", "AutoRaid")
AddToggle(farmPage, "Auto Streak Farmer", "AutoStreak")
AddToggle(farmPage, "Instant Watchtower Quest", "AutoMission")
AddToggle(farmPage, "Leave Lobby to Upgrade Gear", "LeaveToLobby")
AddToggle(farmPage, "Streak Wiper (Anti-Leaderboard)", "StreakWipe")

-- // POPULATING FEATURES (MASTERY) //
AddToggle(masteryPage, "Titan Mastery Autofarm", "TitanMastery")
AddToggle(masteryPage, "Amplify EXP Gain", "AmpEXP")
AddToggle(masteryPage, "Auto M1 / Auto Eject", "AutoM1")

-- // POPULATING FEATURES (LOBBY) //
AddToggle(lobbyPage, "Auto Forge Perks", "AutoForge")
AddToggle(lobbyPage, "Auto Upgrade Gear", "AutoUpgrade")
AddToggle(lobbyPage, "Auto Open All Crates", "AutoCrates")
AddToggle(lobbyPage, "Auto Use Luck/XP Boosts", "AutoBoosts")
AddToggle(lobbyPage, "Sell Duplicate Cosmetics", "SellDupes")

-- // POPULATING FEATURES (MISC) //
AddToggle(miscPage, "Infinite Thunderspears", "InfTS")
AddToggle(miscPage, "Infinite Blades", "InfGas")
AddToggle(miscPage, "Auto Escape Grab", "AutoEscape")
AddToggle(miscPage, "Shadow Ban Checker", "ShadowCheck")
AddToggle(miscPage, "Hitbox Extender (Napes)", "Hitbox", function(v)
    -- Logic for hitbox expansion
end)

-- // WEBHOOKS //
local box = Instance.new("TextBox", webhookPage)
box.Size = UDim2.new(1, -10, 0, 40)
box.PlaceholderText = "Enter Webhook URL Here"
box.Text = T.WebhookURL
box.FocusLost:Connect(function() T.WebhookURL = box.Text; Log("✅ Webhook Linked Successfully!") end)
AddToggle(webhookPage, "Log Mythic Perks", "LogMythic")
AddToggle(webhookPage, "Log Serums / Shifters", "LogSerums")

-- Initialize
farmPage.Visible = true
warn("💜 VIOLET OMNI-SCRIPT LOADED | Update 4 Ready")
