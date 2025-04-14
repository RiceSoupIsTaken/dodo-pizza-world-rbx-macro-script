-- Create the GUI
local player = game:GetService("Players").LocalPlayer
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "StepLoggerGUI"

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 300, 0, 400)
frame.Position = UDim2.new(0, 10, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0

local uiList = Instance.new("UIListLayout", frame)
uiList.SortOrder = Enum.SortOrder.LayoutOrder
uiList.Padding = UDim.new(0, 4)

-- Helper to add step labels
local function addStep(stepText)
    local label = Instance.new("TextLabel", frame)
    label.Text = "🔄 " .. stepText
    label.Size = UDim2.new(1, -10, 0, 22)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.SourceSans
    label.TextSize = 18
    label.TextXAlignment = Enum.TextXAlignment.Left
    return label
end

-- Steps list to reference later
local steps = {}

-- API to update steps
local function updateStep(index, status)
    if steps[index] then
        if status == "done" then
            steps[index].Text = "✅ " .. steps[index].Text:sub(3)
            steps[index].TextColor3 = Color3.fromRGB(100, 255, 100)
        elseif status == "error" then
            steps[index].Text = "❌ " .. steps[index].Text:sub(3)
            steps[index].TextColor3 = Color3.fromRGB(255, 100, 100)
        elseif status == "current" then
            steps[index].Text = "🔄 " .. steps[index].Text:sub(3)
            steps[index].TextColor3 = Color3.fromRGB(200, 200, 0)
        end
    end
end

-- You can use this when running actions
local function runStep(index, text, callback)
    steps[index] = addStep(text)
    updateStep(index, "current")
    local success, err = pcall(callback)
    if success then
        updateStep(index, "done")
    else
        updateStep(index, "error")
        warn("[Step " .. index .. " Error]:", err)
    end
end

-- Example usage
-- runStep(1, "Place Tower 1", function()
--     -- do something
--     wait(1)
-- end)

-- runStep(2, "Upgrade Tower 1", function()
--     -- do something
--     wait(1)
-- end)


-- Configs
local placementCost = 300
local upgradeCost = 400

-- Cash getter
local function getCash()
    local moneyLabel = game:GetService("Players").LocalPlayer
        .PlayerGui:WaitForChild("LocalCoreGui")
        .GameInformation.MoneyFrame.Frame.Money

    local text = moneyLabel.Text:gsub("[^%d]", "") -- remove any currency symbols/commas
    return tonumber(text) or 0
end

-- Retry wrapper: waits until cash is enough and keeps trying until it works
local function waitForCashAndInvoke(minCash, callback)
    repeat
        while getCash() < minCash do wait(0.5) end
        local success = pcall(callback)
        if not success then wait(1) end
    until success
    wait(1) -- brief pause before moving to next step
end

-- Services
local towerService = game:GetService("ReplicatedStorage")
    :WaitForChild("ReplicatedStorage_Source")
    :WaitForChild("Packages")
    :WaitForChild("Knit")
    :WaitForChild("Services")
    :WaitForChild("TowerDefenceTowersService")
    :WaitForChild("RF")

local placeTower = towerService:WaitForChild("PlaceTower")
local upgradeTower = towerService:WaitForChild("UpgradeTower")

local placementPart = workspace:WaitForChild("TowerDefence")
    :WaitForChild("PlacementZones")
    :WaitForChild("Part")

-- Your original tower positions
local placementData = {
    Vector3.new(39.991790771484375, 164.20449829101562, 20.603740692138672),
    Vector3.new(32.1312370300293, 164.20449829101562, -34.23534393310547),
    Vector3.new(2.2988967895507812, 164.20449829101562, -40.914947509765625),
    Vector3.new(75.24893951416016, 164.20449829101562, 28.478487014770508),
    Vector3.new(98.90203094482422, 164.20449829101562, 12.393043518066406),
    Vector3.new(109.18995666503906, 164.20449829101562, -5.977588653564453),
    Vector3.new(97.11384582519531, 164.20449829101562, -8.561219215393066),
    Vector3.new(111.86917114257812, 164.20449829101562, -17.99962043762207),
    Vector3.new(111.09819793701172, 164.20449829101562, 14.672422409057617),
    Vector3.new(96.43547821044922, 164.20449829101562, 24.32724380493164),
    Vector3.new(77.8611068725586, 164.20449829101562, 16.693479537963867),
    Vector3.new(63.191307067871094, 164.20449829101562, 25.816713333129883)
}

-- Step 1: Place all towers in order
for _, pos in ipairs(placementData) do
    waitForCashAndInvoke(placementCost, function()
        placeTower:InvokeServer("Cashier", pos, placementPart)
    end)
end

-- Step 2: Upgrade all towers once, in order
for i = 1, #placementData do
    waitForCashAndInvoke(upgradeCost, function()
        upgradeTower:InvokeServer(i)
    end)
end

-- Function to auto vote replay when button shows up
local function autoVoteReplay()
    local gui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

    gui.ChildAdded:Connect(function(child)
        if child:IsA("ScreenGui") and child:FindFirstChild("Replay") then
            print("Replay UI detected, voting now...")
            pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("ReplicatedStorage_Source")
                    :WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services")
                    :WaitForChild("TowerDefenceRunner"):WaitForChild("RE")
                    :WaitForChild("Vote"):FireServer("Replay")
            end)
        end
    end)
end

autoVoteReplay()
