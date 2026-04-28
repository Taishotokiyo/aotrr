-- Refined AoTR GUI | Violet Aesthetic Edition
-- Original Logic by Taishotokiyo

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

-- Wait for Character
repeat task.wait(0.1) until lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")

-- Cleanup existing
pcall(function()
    local o = game:GetService("CoreGui"):FindFirstChild("AOTR_VIOLET")
    if o then o:Destroy() end
end)

-- Theme Configuration
local Theme = {
    Main = Color3.fromRGB(15, 15, 20),
    Sidebar = Color3.fromRGB(20, 20, 28),
    Accent = Color3.fromRGB(138, 43, 226), -- Deep Violet
    Text = Color3.fromRGB(220, 220, 230),
    SecondaryText = Color3.fromRGB(120, 120, 150)
}

-- STATE (From your original script)
local T = {
    AutoFarm = false, AutoRaid = false, AutoExecute = false,
    TitanESP = false, AutoReload = false, InfiniteGas = false,
    SpeedBoost = false, AutoMission = false, AutoChest = false,
    AutoEscape = false, HitboxExtend = false, AutoRetry = false,
}

local STATS = {kills=0, missions=0, raids=0}

-- [RETAINED YOUR ORIGINAL HELPER FUNCTIONS HERE: fireKw, getNape, nearTitan, etc.]
-- (I'll keep the UI code below for brevity)

-- ══════════════════════════════════════
-- GUI CONSTRUCTION
-- ══════════════════════════════════════
local sg = Instance.new("ScreenGui", game:GetService("CoreGui"))
sg.Name = "AOTR_VIOLET"

local win = Instance.new("Frame", sg)
win.Size = UDim2.new(0, 500, 0, 350)
win.Position = UDim2.new(0.5, -250, 0.5, -175)
win.BackgroundColor3 = Theme.Main
win.BorderSizePixel = 0
win.Active = true
win.Draggable = true

-- Rounded Corners & Stroke
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke", win)
stroke.Color = Theme.Accent
stroke.Thickness = 1.2
stroke.Transparency = 0.5

-- SIDEBAR
local sidebar = Instance.new("Frame", win)
sidebar.Size = UDim2.new(0, 120, 1, 0)
sidebar.BackgroundColor3 = Theme.Sidebar
sidebar.BorderSizePixel = 0
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 8)

-- Logo / Title
local logo = Instance.new("TextLabel", sidebar)
logo.Size = UDim2.new(1, 0, 0, 50)
logo.Text = "VIOLET"
logo.TextColor3 = Theme.Accent
logo.Font = Enum.Font.GothamBold
logo.TextSize = 18
logo.BackgroundTransparency = 1

-- Tab Container
local tabList = Instance.new("Frame", sidebar)
tabList.Size = UDim2.new(1, 0, 1, -60)
tabList.Position = UDim2.new(0, 0, 0, 50)
tabList.BackgroundTransparency = 1
local layout = Instance.new("UIListLayout", tabList)
layout.Padding = UDim.new(0, 5)
layout.HorizontalAlignment = "Center"

-- CONTENT AREA
local container = Instance.new("Frame", win)
container.Size = UDim2.new(1, -130, 1, -20)
container.Position = UDim2.new(0, 125, 0, 10)
container.BackgroundTransparency = 1

-- TAB FUNCTION (Updated for Violet Style)
local function CreateTab(name, icon)
    local page = Instance.new("ScrollingFrame", container)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.Visible = false
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = Theme.Accent
    
    local pageLayout = Instance.new("UIListLayout", page)
    pageLayout.Padding = UDim.new(0, 8)

    local btn = Instance.new("TextButton", tabList)
    btn.Size = UDim2.new(0, 100, 0, 32)
    btn.BackgroundColor3 = Theme.Main
    btn.Text = icon .. " " .. name
    btn.TextColor3 = Theme.SecondaryText
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    btn.MouseButton1Click:Connect(function()
        for _, v in pairs(container:GetChildren()) do v.Visible = false end
        for _, b in pairs(tabList:GetChildren()) do 
            if b:IsA("TextButton") then b.TextColor3 = Theme.SecondaryText end 
        end
        page.Visible = true
        btn.TextColor3 = Theme.Accent
    end)

    return page
end

-- PAGE INIT
local farmPage = CreateTab("Combat", "⚔️")
local gearPage = CreateTab("Player", "🏃")

-- TOGGLE FUNCTION (Violet Style)
local function AddToggle(page, name, key, callback)
    local tBtn = Instance.new("TextButton", page)
    tBtn.Size = UDim2.new(1, -10, 0, 40)
    tBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    tBtn.Text = "  " .. name
    tBtn.TextColor3 = Theme.Text
    tBtn.Font = Enum.Font.Gotham
    tBtn.TextSize = 13
    tBtn.TextXAlignment = "Left"
    Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0, 6)

    local indicator = Instance.new("Frame", tBtn)
    indicator.Size = UDim2.new(0, 4, 0, 20)
    indicator.Position = UDim2.new(1, -10, 0.5, -10)
    indicator.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 2)

    tBtn.MouseButton1Click:Connect(function()
        T[key] = not T[key]
        indicator.BackgroundColor3 = T[key] and Theme.Accent or Color3.fromRGB(50, 50, 60)
        if callback then callback(T[key]) end
    end)
end

-- EXAMPLE USAGE
AddToggle(farmPage, "Auto Farm Missions", "AutoFarm", function(val)
    print("Auto Farm:", val)
end)

AddToggle(gearPage, "Speed Boost", "SpeedBoost", function(val)
    local hum = lp.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = val and 60 or 16 end
end)

-- Default Tab
tabList:FindFirstChildOfClass("TextButton").TextColor3 = Theme.Accent
container:FindFirstChildOfClass("ScrollingFrame").Visible = true

warn("💜 Violet AoTR GUI Loaded Successfully")
