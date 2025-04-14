-- STEP LOGGER GUI SETUP --
local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "StepLoggerGUI"
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 40)
frame.Position = UDim2.new(0, 10, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local toggleButton = Instance.new("TextButton", frame)
toggleButton.Size = UDim2.new(1, 0, 0, 40)
toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 18
toggleButton.Text = "📜 Step Logger (Click to Toggle)"

local stepsFrame = Instance.new("Frame", frame)
stepsFrame.Size = UDim2.new(1, 0, 0, 360)
stepsFrame.Position = UDim2.new(0, 0, 0, 40)
stepsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
stepsFrame.Visible = true

local layout = Instance.new("UIListLayout", stepsFrame)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 4)

local isVisible = true
toggleButton.MouseButton1Click:Connect(function()
	isVisible = not isVisible
	stepsFrame.Visible = isVisible
	frame.Size = UDim2.new(0, 300, 0, isVisible and 400 or 40)
end)

local steps = {}
local function addStep(text)
	local label = Instance.new("TextLabel", stepsFrame)
	label.Text = "⏳ " .. text
	label.Size = UDim2.new(1, -10, 0, 22)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(200, 200, 200)
	label.Font = Enum.Font.SourceSans
	label.TextSize = 18
	label.TextXAlignment = Enum.TextXAlignment.Left
	return label
end

local function updateStep(i, status)
	if steps[i] then
		local label = steps[i]
		local txt = label.Text:sub(3)
		if status == "done" then
			label.Text = "✅ " .. txt
			label.TextColor3 = Color3.fromRGB(100, 255, 100)
		elseif status == "error" then
			label.Text = "❌ " .. txt
			label.TextColor3 = Color3.fromRGB(255, 100, 100)
		elseif status == "current" then
			label.Text = "🔄 " .. txt
			label.TextColor3 = Color3.fromRGB(255, 255, 0)
		end
	end
end

function runStep(index, description, callback)
	steps[index] = addStep(description)
	updateStep(index, "current")
	coroutine.wrap(function()
		while true do
			local success, err = pcall(callback)
			if success then
				updateStep(index, "done")
				break
			else
				updateStep(index, "error")
				wait(1)
				updateStep(index, "current")
			end
		end
	end)()
end

-- MONEY FUNCTION --
local function getMoney()
	local text = playerGui.LocalCoreGui.GameInformation.MoneyFrame.Frame.Money.Text
	return tonumber(text:gsub(",", "")) or 0
end

-- PLACEMENT DATA --
local placements = {
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
	Vector3.new(63.191307067871094, 164.20449829101562, 25.816713333129883),
}

-- PLACE TOWERS --
for i, pos in ipairs(placements) do
	runStep(i, "Place Tower " .. i, function()
		if getMoney() >= 300 then
			local args = {
				[1] = "Cashier",
				[2] = pos,
				[3] = workspace.TowerDefence.PlacementZones.Part
			}
			game:GetService("ReplicatedStorage")
				.ReplicatedStorage_Source.Packages.Knit.Services
				.TowerDefenceTowersService.RF.PlaceTower:InvokeServer(unpack(args))
		else
			error("Not enough money to place tower")
		end
	end)
end

-- UPGRADE TOWERS (wait for placement first) --
task.delay(#placements + 5, function()
	for i = 1, #placements do
		runStep(#placements + i, "Upgrade Tower " .. i, function()
			if getMoney() >= 400 then
				local args = {[1] = i}
				game:GetService("ReplicatedStorage")
					.ReplicatedStorage_Source.Packages.Knit.Services
					.TowerDefenceTowersService.RF.UpgradeTower:InvokeServer(unpack(args))
			else
				error("Not enough money to upgrade tower")
			end
		end)
	end
end)

-- AUTO-REPLAY DETECTION --
task.spawn(function()
	local replayPath = game:GetService("ReplicatedStorage")
		.ReplicatedStorage_Source.Packages.Knit.Services
		.TowerDefenceRunner.RE.Vote

	local function tryReplay()
		pcall(function()
			replayPath:FireServer("Replay")
		end)
	end

	local guiPath = playerGui:WaitForChild("LocalCoreGui", 60)
	if guiPath then
		local voteUi = guiPath:WaitForChild("EndGame", 60)
		if voteUi then
			voteUi:GetPropertyChangedSignal("Visible"):Connect(function()
				if voteUi.Visible then
					tryReplay()
				end
			end)
		end
	end
end)
