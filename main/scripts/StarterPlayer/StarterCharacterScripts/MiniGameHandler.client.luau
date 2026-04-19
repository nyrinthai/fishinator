local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RE = RS:WaitForChild("RemoteEvents")
local StartFishingEvent = RE:WaitForChild("StartFishingMinigame")
local EndFishingEvent = RE:WaitForChild("EndFishingMinigame")
local UpdateGameDiffEvent = RE:WaitForChild("UpdateMinigameDifficulty")
local player = game.Players.LocalPlayer

--==================================================
-- GREEN BAR TUNING
--==================================================
local GREENBAR_START_Y = 0.5
local GREENBAR_SIZE = 0.27
local GREENBAR_GRAVITY = 1500         -- pulls bar downward
local GREENBAR_CLICK_FORCE = 3000     -- upward force while holding click
local GREENBAR_MAX_SPEED = 900        -- max up/down speed
local GREENBAR_RESPONSIVENESS = 1     -- overall multiplier for bar movement feel

--==================================================
-- PROGRESS BAR TUNING
--==================================================
local PROGRESS_FILL_RATE = 0.35       -- per second when touching fish
local PROGRESS_DRAIN_RATE = 0.10      -- per second when not touching fish
local PROGRESS_START = 0.25


UpdateGameDiffEvent.OnClientEvent:Connect(function(barSize, fillRate, fillDecay)
	PROGRESS_FILL_RATE = fillRate
	PROGRESS_DRAIN_RATE = fillDecay
	GREENBAR_SIZE = barSize

	local minigameGui = player.PlayerGui:FindFirstChild("FishingMinigame")
	if not minigameGui then return end

	local minigameFrame = minigameGui:FindFirstChild("Minigame")
	if not minigameFrame then return end

	local greenBarFrame = minigameFrame:FindFirstChild("GreenBar")
	if not greenBarFrame then return end

	greenBarFrame.Size = UDim2.new(
		greenBarFrame.Size.X.Scale,
		greenBarFrame.Size.X.Offset,
		GREENBAR_SIZE,
		greenBarFrame.Size.Y.Offset
	)
end)
--==================================================
-- FISH MOVEMENT TUNING
--==================================================
local FISH_START_Y = 0.4

local FISH_MIN_SPEED = 80             -- minimum fish speed
local FISH_MAX_SPEED = 260            -- maximum fish speed
local FISH_DIRECTION_CHANGE_MIN = 0.35 -- shortest time before changing movement
local FISH_DIRECTION_CHANGE_MAX = 1.2  -- longest time before changing movement
local FISH_EDGE_BOUNCE_DAMPING = 0.35  -- slows fish when it hits top/bottom

--==================================================
-- STATE
--==================================================
local holdingClick = false
local minigameRunning = false
local currentRod = nil

local function stopMinigame(result)
	if not minigameRunning then return end

	minigameRunning = false
	holdingClick = false
	currentRod = nil

	local minigameGui = player.PlayerGui:FindFirstChild("FishingMinigame")
	if minigameGui then
		minigameGui.Enabled = false
	end

	if result then
		EndFishingEvent:FireServer(result)
	end
end

local function isFishingRod(tool)
	return tool and tool:IsA("Tool") and string.find(tool.Name:lower(), "rod")
end

local function watchCharacter(character)
	character.ChildAdded:Connect(function(child)
		if isFishingRod(child) then
			currentRod = child
		end
	end)

	character.ChildRemoved:Connect(function(child)
		if child == currentRod then
			stopMinigame("cancel") -- or "lose" if your server does not handle "cancel"
		end
	end)
end

if player.Character then
	watchCharacter(player.Character)
end

player.CharacterAdded:Connect(watchCharacter)

UIS.InputBegan:Connect(function(input, processing)
	if processing then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		holdingClick = true
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		holdingClick = false
	end
end)

StartFishingEvent.OnClientEvent:Connect(function(attemptedFish)
	if minigameRunning then return end
	
	local character = player.Character
	if not character then return end

	for _, child in ipairs(character:GetChildren()) do
		if isFishingRod(child) then
			currentRod = child
			break
		end
	end

	if not currentRod then return end
	
	minigameRunning = true
	local MinigameGUI = player:WaitForChild("PlayerGui"):WaitForChild("FishingMinigame")
	local ProgressFrame = MinigameGUI:WaitForChild("ProgressBar")
	local FillFrame = ProgressFrame:WaitForChild("Fill")

	local MinigameFrame = MinigameGUI:WaitForChild("Minigame")
	local FishFrame = MinigameFrame:WaitForChild("Fish")
	local GreenBarFrame = MinigameFrame:WaitForChild("GreenBar")

	MinigameGUI.Enabled = true

	local progress = PROGRESS_START
	local greenBarVelocity = 0
	local fishVelocity = 0
	local fishMoveTimer = 0
	-- starting positions
	GreenBarFrame.Position = UDim2.new(
		GreenBarFrame.Position.X.Scale,
		GreenBarFrame.Position.X.Offset,
		GREENBAR_START_Y,
		0
	)

	FishFrame.Position = UDim2.new(
		FishFrame.Position.X.Scale,
		FishFrame.Position.X.Offset,
		FISH_START_Y,
		0
	)

	FillFrame.Size = UDim2.new(1, 0, progress, 0)
	FillFrame.Position = UDim2.new(0, 0, 1 - progress, 0)

	local function getRandomFishVelocity()
		local speed = math.random(FISH_MIN_SPEED, FISH_MAX_SPEED)
		local direction = math.random(0, 1) == 0 and -1 or 1
		return speed * direction
	end

	local function getRandomFishChangeTime()
		return math.random() * (FISH_DIRECTION_CHANGE_MAX - FISH_DIRECTION_CHANGE_MIN) + FISH_DIRECTION_CHANGE_MIN
	end

	fishVelocity = getRandomFishVelocity()
	fishMoveTimer = getRandomFishChangeTime()

	local connection
	connection = RunService.RenderStepped:Connect(function(deltaTime)
		if not minigameRunning then
			connection:Disconnect()
			return
		end

		--==================================================
		-- GREEN BAR MOVEMENT
		--==================================================
		local clickForce = 0
		if holdingClick then
			clickForce = -GREENBAR_CLICK_FORCE * GREENBAR_RESPONSIVENESS
		end

		local gravityForce = GREENBAR_GRAVITY * GREENBAR_RESPONSIVENESS
		local acceleration = gravityForce + clickForce

		greenBarVelocity += acceleration * deltaTime
		greenBarVelocity = math.clamp(greenBarVelocity, -GREENBAR_MAX_SPEED, GREENBAR_MAX_SPEED)

		local currentGreenY = GreenBarFrame.Position.Y.Scale
		local greenScaleVelocity = greenBarVelocity / MinigameFrame.AbsoluteSize.Y
		local newGreenY = currentGreenY + greenScaleVelocity * deltaTime

		local maxGreenY = 1 - GreenBarFrame.Size.Y.Scale
		newGreenY = math.clamp(newGreenY, 0, maxGreenY)

		if newGreenY <= 0 or newGreenY >= maxGreenY then
			greenBarVelocity = 0
		end

		GreenBarFrame.Position = UDim2.new(
			GreenBarFrame.Position.X.Scale,
			GreenBarFrame.Position.X.Offset,
			newGreenY,
			0
		)

		--==================================================
		-- FISH MOVEMENT
		--==================================================
		fishMoveTimer -= deltaTime
		if fishMoveTimer <= 0 then
			fishVelocity = getRandomFishVelocity()
			fishMoveTimer = getRandomFishChangeTime()
		end

		local currentFishY = FishFrame.Position.Y.Scale
		local fishScaleVelocity = fishVelocity / MinigameFrame.AbsoluteSize.Y
		local newFishY = currentFishY + fishScaleVelocity * deltaTime

		local maxFishY = 1 - FishFrame.Size.Y.Scale

		if newFishY <= 0 then
			newFishY = 0
			fishVelocity = -fishVelocity * FISH_EDGE_BOUNCE_DAMPING
			fishMoveTimer = getRandomFishChangeTime()
		elseif newFishY >= maxFishY then
			newFishY = maxFishY
			fishVelocity = -fishVelocity * FISH_EDGE_BOUNCE_DAMPING
			fishMoveTimer = getRandomFishChangeTime()
		end

		FishFrame.Position = UDim2.new(
			FishFrame.Position.X.Scale,
			FishFrame.Position.X.Offset,
			newFishY,
			0
		)

		--==================================================
		-- OVERLAP CHECK
		--==================================================
		local greenTop = GreenBarFrame.AbsolutePosition.Y
		local greenBottom = greenTop + GreenBarFrame.AbsoluteSize.Y

		local fishTop = FishFrame.AbsolutePosition.Y
		local fishBottom = fishTop + FishFrame.AbsoluteSize.Y

		local touchingFish = greenBottom >= fishTop and greenTop <= fishBottom

		--==================================================
		-- PROGRESS BAR
		--==================================================
		if touchingFish then
			progress = math.clamp(progress + PROGRESS_FILL_RATE * deltaTime, 0, 1)
		else
			progress = math.clamp(progress - PROGRESS_DRAIN_RATE * deltaTime, 0, 1)
		end

		FillFrame.Size = UDim2.new(1, 0, progress, 0)
		FillFrame.Position = UDim2.new(0, 0, 1 - progress, 0)

		--==================================================
		-- END CONDITIONS
		--==================================================
		if progress >= 1 then
			stopMinigame("win")
		elseif progress <= 0 then
			stopMinigame("lose")
		end
	end)
end)