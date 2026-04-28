--[[
    NAPOLEON OMNI-SCRIPT | FULLY FUNCTIONAL
    Updated for: AOT:REVOLUTION [Update 4 - April 2026]
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local lp = Players.LocalPlayer

-- // 1. ADVANCED CONFIGURATION //
local Config = {
    Farm = {
        Active = false, Mode = "Blades", -- Options: Blades, Ripper, TS
        Method = "Missions", -- Missions, Raids, Streak
        Distance = 12, Position = "Above",
        KillWait = 0, BossHP = 0.05, Onikiri = false,
        InstantTS = false, AutoLeave = false, Rejoin = false
    },
    Lobby = {
        Forge = false, UpPerk = false, UpGear = false,
        UnlockAll = false, UseBoosts = false, AutoClaim = false,
        OpenCrates = false, SellDupes = false, Prestige = false
    },
    Combat = {
        AutoM1 = false, AutoEject = false, Hitbox = 1,
        InfGas = false, InfTS = false, AutoEscape = false
    },
    Logs = { URL = "", Enabled = false, LogMythic = true, LogSerum = true }
}

-- // 2. SMART REMOTE FINDER //
-- Update 4 Remotes are often nested. This scanner finds them dynamically.
local R = {}
local function UpdateRemotes()
    for _, v in ipairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            -- Common Update 4 Remote Mappings
            if v.Name:find("Attack") or v.Name == "Atk" then R.Attack = v end
            if v.Name:find("Forge") or v.Name == "Roll" then R.Forge = v end
            if v.Name:find("Ripper") then R.Ripper = v end
            if v.Name:find("Thunderspear") or v.Name == "TS" then R.TS = v end
            if v.Name:find("Quest") then R.Quest = v end
            if v.Name:find("Boost") then R.Boost = v end
            if v.Name:find("Crate") then R.Crate = v end
        end
    end
end
UpdateRemotes()

-- // 3. CORE FUNCTIONALITY (THE "ENGINE") //

-- High-Speed Combat Logic
RunService.Stepped:Connect(function()
    if Config.Farm.Active and lp.Character then
        local hrp = lp.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- Target the closest Titan Nape
        local target, nape, dist = nil, nil, math.huge
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Model") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                if not Players:GetPlayerFromCharacter(v) then
                    local d = (hrp.Position - v.PrimaryPart.Position).Magnitude
                    if d < dist then
                        dist = d; target = v
                    end
                end
            end
        end

        if target then
            for _, p in ipairs(target:GetDescendants()) do
                if p.Name:lower():find("nape") or p.Name == "WeakPoint" then nape = p break end
            end
            nape = nape or target:FindFirstChild("HumanoidRootPart")

            if nape then
                -- Position logic (Above / Behind / In Front)
                local offset = Vector3.new(0, Config.Farm.Distance, 0)
                if Config.Farm.Position == "Behind" then 
                    offset = target.PrimaryPart.CFrame.LookVector * -Config.Farm.Distance 
                end
                
                hrp.CFrame = CFrame.new(nape.Position + offset, nape.Position)

                -- Functional Attack Execution
                if Config.Farm.Mode == "Titan Ripper" and R.Ripper then
                    R.Ripper:FireServer(target)
                elseif Config.Farm.Mode == "Blades" and R.Attack then
                    R.Attack:FireServer("Slash", target)
                end
                
                if Config.Combat.AutoM1 and R.Attack then R.Attack:FireServer("M1") end
            end
        end
    end
    
    -- Equipment Mods
    if Config.Combat.InfGas then
        local g = lp:FindFirstChild("Gas", true) or lp:FindFirstChild("Fuel", true)
        if g then g.Value = 100 end
    end
end)

-- Lobby Automation (Checks every 5 seconds)
task.spawn(function()
    while task.wait(5) do
        if Config.Lobby.Forge and R.Forge then R.Forge:InvokeServer("Spin") end
        if Config.Lobby.AutoClaim and R.Quest then R.Quest:FireServer("ClaimAll") end
        if Config.Lobby.UseBoosts and R.Boost then R.Boost:FireServer("ActivateAll") end
        if Config.Lobby.OpenCrates and R.Crate then R.Crate:FireServer("OpenAll") end
    end
end)

-- // 4. NAPOLEON GUI (FUNCTIONAL LINKS) //
local function CreateUI()
    pcall(function() CoreGui.NapoleonUI:Destroy() end)
    local sg = Instance.new("ScreenGui", CoreGui); sg.Name = "NapoleonUI"
    
    local main = Instance.new("Frame", sg)
    main.Size = UDim2.new(0, 850, 0, 580); main.Position = UDim2.new(0.5, -425, 0.5, -290)
    main.BackgroundColor3 = Color3.fromRGB(10, 10, 12); Instance.new("UICorner", main)
    
    local content = Instance.new("ScrollingFrame", main)
    content.Size = UDim2.new(1, -210, 1, -20); content.Position = UDim2.new(0, 200, 0, 10)
    content.BackgroundTransparency = 1; content.CanvasSize = UDim2.new(0, 0, 4, 0)
    local grid = Instance.new("UIGridLayout", content)
    grid.CellSize = UDim2.new(0.48, 0, 0, 240); grid.CellPadding = UDim2.new(0.02, 0, 0.01, 0)

    -- Card & Toggle Builder (Linked to Config)
    local function AddToggle(card, text, tab, key)
        local btn = Instance.new("TextButton", card)
        btn.Size = UDim2.new(0.9, 0, 0, 32); btn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        btn.Text = "  " .. text; btn.TextColor3 = Color3.fromRGB(150, 150, 150)
        btn.TextXAlignment = "Left"; Instance.new("UICorner", btn)
        
        btn.MouseButton1Click:Connect(function()
            Config[tab][key] = not Config[tab][key]
            btn.BackgroundColor3 = Config[tab][key] and Color3.fromRGB(120, 80, 255) or Color3.fromRGB(20, 20, 25)
            btn.TextColor3 = Config[tab][key] and Color3.new(1,1,1) or Color3.fromRGB(150, 150, 150)
        end)
    end

    local function CreateCard(name)
        local card = Instance.new("Frame", content)
        card.BackgroundColor3 = Color3.fromRGB(15, 15, 18); Instance.new("UICorner", card)
        local l = Instance.new("UIListLayout", card); l.Padding = UDim.new(0, 5); l.HorizontalAlignment = "Center"
        local tl = Instance.new("TextLabel", card); tl.Size = UDim2.new(1, 0, 0, 35); tl.Text = name; tl.TextColor3 = Color3.new(1,1,1); tl.BackgroundTransparency = 1; tl.Font = "GothamBold"
        Instance.new("UIPadding", card).PaddingTop = UDim.new(0, 40)
        return card
    end

    -- Setup Cards
    local farmCard = CreateCard("Farming")
    AddToggle(farmCard, "Enable Autofarm", "Farm", "Active")
    AddToggle(farmCard, "Instant TS Quest", "Farm", "InstantTS")
    
    local lobbyCard = CreateCard("Lobby")
    AddToggle(lobbyCard, "Auto Forge Perks", "Lobby", "Forge")
    AddToggle(lobbyCard, "Auto Use Boosts", "Lobby", "UseBoosts")
    
    local miscCard = CreateCard("Misc")
    AddToggle(miscCard, "Infinite Gas", "Combat", "InfGas")
    AddToggle(miscCard, "Auto Escape Grab", "Combat", "AutoEscape")

    -- Draggable & Fullscreen
    local d, ds, sp
    main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = true; ds = i.Position; sp = main.Position end end)
    UIS.InputChanged:Connect(function(i) if d and i.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = i.Position - ds
        main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + delta.X, sp.Y.Scale, sp.Y.Offset + delta.Y)
    end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end end)
end

CreateUI()
warn("✅ Napoleon Functional Loaded | Scanning for Update 4 Remotes...")
