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

-- Constantly tries to vote for replay every 5 seconds
task.spawn(function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local replayRemote = ReplicatedStorage:WaitForChild("ReplicatedStorage_Source")
        :WaitForChild("Packages"):WaitForChild("Knit")
        :WaitForChild("Services"):WaitForChild("TowerDefenceRunner")
        :WaitForChild("RE"):WaitForChild("Vote")

    while true do
        pcall(function()
            replayRemote:FireServer("Replay")
        end)
        wait(5)
    end
end)
