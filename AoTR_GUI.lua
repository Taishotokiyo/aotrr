-- Napoleon Styled UI | AOT:R Update 4
-- Features: Draggable, Expandable, Card-Based Layout

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer

-- Cleanup
pcall(function() if CoreGui:FindFirstChild("NapoleonUI") then CoreGui.NapoleonUI:Destroy() end end)

-- State & Settings
local T = {
    -- Character
    NoCooldown = false, NoStun = false, TryHit = false,
    -- ODM & Blade
    GearSpeed = false, GearSpeedVal = 1, ODMRange = 665, FastAttack = false, AttackSpeed = 1, BladeDurability = 5,
    -- Titans
    HitboxValue = 1, FreezeTitan = false, KillAura = false, KillDelay = 1, KillRadius = 200,
    -- Criticals
    CritChance = 1, CritDamage = 1,
    -- Infinite
    InfGas = false, InfRefill = false
}

-- UI Setup
local sg = Instance.new("ScreenGui", CoreGui)
sg.Name = "NapoleonUI"
sg.IgnoreGuiInset = true

local main = Instance.new("Frame", sg)
main.Name = "Main"
main.Size = UDim2.new(0, 800, 0, 550)
main.Position = UDim2.new(0.5, -400, 0.5, -275)
main.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
main.BorderSizePixel = 0
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 6)

-- Sidebar
local sidebar = Instance.new("Frame", main)
sidebar.Size = UDim2.new(0, 180, 1, 0)
sidebar.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
sidebar.BorderSizePixel = 0
Instance.new("UICorner", sidebar)

local logo = Instance.new("TextLabel", sidebar)
logo.Size = UDim2.new(1, 0, 0, 60)
logo.Text = "🐻 Napoleon"
logo.TextColor3 = Color3.new(1, 1, 1)
logo.Font = Enum.Font.GothamBold
logo.TextSize = 20
logo.BackgroundTransparency = 1

-- Top Search Bar area
local topBar = Instance.new("Frame", main)
topBar.Size = UDim2.new(1, -190, 0, 50)
topBar.Position = UDim2.new(0, 185, 0, 5)
topBar.BackgroundTransparency = 1

local search = Instance.new("TextBox", topBar)
search.Size = UDim2.new(1, -40, 0, 35)
search.Position = UDim2.new(0, 0, 0, 5)
search.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
search.Text = ""
search.PlaceholderText = "Search..."
search.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", search)

-- Content Grid (Scrolling)
local content = Instance.new("ScrollingFrame", main)
content.Size = UDim2.new(1, -195, 1, -70)
content.Position = UDim2.new(0, 190, 0, 60)
content.BackgroundTransparency = 1
content.ScrollBarThickness = 2
content.CanvasSize = UDim2.new(0, 0, 2, 0)

local grid = Instance.new("UIGridLayout", content)
grid.CellSize = UDim2.new(0.48, 0, 0, 180)
grid.CellPadding = UDim2.new(0.02, 0, 0.02, 0)

-- // UI BUILDER FUNCTIONS //

local function CreateCard(title)
    local card = Instance.new("Frame", content)
    card.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    card.BorderSizePixel = 0
    Instance.new("UICorner", card)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Color3.fromRGB(30, 30, 35)
    
    local tl = Instance.new("TextLabel", card)
    tl.Size = UDim2.new(1, -10, 0, 30)
    tl.Position = UDim2.new(0, 10, 0, 5)
    tl.Text = title
    tl.TextColor3 = Color3.fromRGB(200, 200, 200)
    tl.TextXAlignment = "Left"
    tl.BackgroundTransparency = 1
    tl.Font = "GothamBold"
    tl.TextSize = 14
    
    local list = Instance.new("UIListLayout", card)
    list.Padding = UDim.new(0, 5)
    list.HorizontalAlignment = "Center"
    
    local pad = Instance.new("UIPadding", card)
    pad.PaddingTop = UDim.new(0, 35)
    
    return card
end

local function AddToggle(card, text, key)
    local row = Instance.new("Frame", card)
    row.Size = UDim2.new(0.9, 0, 0, 25)
    row.BackgroundTransparency = 1
    
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.7, 0, 1, 0)
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(160, 160, 160)
    lbl.TextXAlignment = "Left"
    lbl.BackgroundTransparency = 1
    lbl.Font = "Gotham"
    lbl.TextSize = 12
    
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(0, 35, 0, 18)
    btn.Position = UDim2.new(1, -40, 0.5, -9)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    btn.Text = ""
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    
    local dot = Instance.new("Frame", btn)
    dot.Size = UDim2.new(0, 12, 0, 12)
    dot.Position = UDim2.new(0, 3, 0.5, -6)
    dot.BackgroundColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    
    btn.MouseButton1Click:Connect(function()
        T[key] = not T[key]
        btn.BackgroundColor3 = T[key] and Color3.fromRGB(120, 80, 255) or Color3.fromRGB(40, 40, 45)
        dot.Position = T[key] and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
    end)
end

local function AddSlider(card, text, min, max, key)
    local sFrame = Instance.new("Frame", card)
    sFrame.Size = UDim2.new(0.9, 0, 0, 20)
    sFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    Instance.new("UICorner", sFrame)
    
    local fill = Instance.new("Frame", sFrame)
    fill.Size = UDim2.new(0.5, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(120, 80, 255)
    Instance.new("UICorner", fill)
    
    local lbl = Instance.new("TextLabel", sFrame)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.Text = text .. ": " .. T[key]
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.BackgroundTransparency = 1
    lbl.TextSize = 10
    lbl.Font = "Gotham"
end

-- // CREATE SECTIONS //
local charCard = CreateCard("Character")
AddToggle(charCard, "No Cooldown Boost", "NoCooldown")
AddToggle(charCard, "No Stun", "NoStun")
AddToggle(charCard, "Try Hit", "TryHit")

local odmCard = CreateCard("ODMG & Blade")
AddToggle(odmCard, "Gear Speed", "GearSpeed")
AddSlider(odmCard, "Set ODM Range", 0, 1000, "ODMRange")
AddToggle(odmCard, "Fast Attack Speed", "FastAttack")

local titanCard = CreateCard("Titans")
AddToggle(titanCard, "Freeze Titan", "FreezeTitan")
AddToggle(titanCard, "Kill Aura", "KillAura")
AddSlider(titanCard, "Set Kill Radius", 0, 500, "KillRadius")

local critCard = CreateCard("Criticals")
AddSlider(critCard, "Set Crit Chance", 0, 1, "CritChance")
AddSlider(critCard, "Set Crit Damage", 0, 1, "CritDamage")

local infCard = CreateCard("Infinite")
AddToggle(infCard, "Infinite Gas", "InfGas")
AddToggle(infCard, "Infinite Refill", "InfRefill")

-- // DRAGGABLE & FULLSCREEN LOGIC //
local dragging, dragInput, dragStart, startPos
main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = main.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
main.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Fullscreen Toggle button (Bottom right corner icon in your image)
local fullBtn = Instance.new("ImageButton", main)
fullBtn.Size = UDim2.new(0, 20, 0, 20)
fullBtn.Position = UDim2.new(1, -25, 1, -25)
fullBtn.BackgroundTransparency = 1
fullBtn.Image = "rbxassetid://6031094678" -- Expand icon

local isFull = false
fullBtn.MouseButton1Click:Connect(function()
    isFull = not isFull
    if isFull then
        main.Size = UDim2.new(1, 0, 1, 0)
        main.Position = UDim2.new(0, 0, 0, 0)
    else
        main.Size = UDim2.new(0, 800, 0, 550)
        main.Position = UDim2.new(0.5, -400, 0.5, -275)
    end
end)

warn("✅ Napoleon UI Loaded | Use Expand Icon for Fullscreen")
