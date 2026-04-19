local players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RS = game:GetService("ReplicatedStorage")
local RE = RS:WaitForChild("RemoteEvents")
local SSS = game:GetService("ServerScriptService")
local CoreEvent = RE:WaitForChild("CoreEvent")
local FishingEvent = RE:WaitForChild("StartFishingMinigame")
local RodsFolder = game.ServerStorage:WaitForChild("Rods")
local IdleFishingEvent = RE:WaitForChild("IdleFishing")
local EndFishingEvent = RE:WaitForChild("EndFishingMinigame")
local FishingServer = require(SSS:WaitForChild("FishingServer"))
local UpdateHotbarEvent = RE:WaitForChild("UpdateHotbar")
local DataStoreService = game:GetService("DataStoreService")
local CoinesDataStore = DataStoreService:GetDataStore("Coines")
local LevelDataStore = DataStoreService:GetDataStore("Level")
local CaughtDataStore = DataStoreService:GetDataStore("Caught")

-- Helper: safely load from a DataStore with pcall
local function loadData(store, key, default)
	local success, value = pcall(function()
		return store:GetAsync(key)
	end)
	if success and value ~= nil then
		return value
	end
	return default
end

-- Helper: safely save to a DataStore with pcall
local function saveData(store, key, value)
	local success, err = pcall(function()
		store:SetAsync(key, value)
	end)
	if not success then
		warn("DataStore save failed for key " .. key .. ": " .. tostring(err))
	end
end

players.PlayerAdded:Connect(function(plyr)
	local userId = tostring(plyr.UserId)

	-- Load saved data (falls back to defaults if no data exists yet)
	local savedCoines  = loadData(CoinesDataStore, userId, 10000)
	local savedLevel   = loadData(LevelDataStore,  userId, 1)
	local savedCaught  = loadData(CaughtDataStore, userId, 0)
	
	--savedCoines = 10000
	--savedLevel = 1
	--savedCaught = 0

	-- leaderstats folder
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = plyr

	local coines = Instance.new("IntValue")
	coines.Name = "Coines"
	coines.Value = savedCoines
	coines.Parent = leaderstats

	local fishCaught = Instance.new("IntValue")
	fishCaught.Name = "FishesCaught"
	fishCaught.Value = savedCaught
	fishCaught.Parent = leaderstats

	local level = Instance.new("IntValue")
	level.Name = "level"
	level.Value = savedLevel
	level.Parent = leaderstats

	-- Non-persistent player state
	local fishInventory = Instance.new("Folder")
	fishInventory.Name = "FishInventory"
	fishInventory.Parent = plyr

	local isFishing = Instance.new("BoolValue")
	isFishing.Name = "isFishing"
	isFishing.Value = false
	isFishing.Parent = plyr

	local currentFishCatching = Instance.new("StringValue")
	currentFishCatching.Name = "currentFishCatching"
	currentFishCatching.Value = ""
	currentFishCatching.Parent = plyr

	local EquippedRod = Instance.new("StringValue")
	EquippedRod.Name = "EquippedRod"
	EquippedRod.Value = "Starter Rod"
	EquippedRod.Parent = plyr

	local slotEquipped = Instance.new("IntValue")
	slotEquipped.Name = "SlotEquipped"
	slotEquipped.Value = 0
	slotEquipped.Parent = plyr
	
	-- hi chris :D
	
	plyr.CharacterAdded:Connect(function(chr)
		CoreEvent:FireClient(plyr, "DisableBackpack")
		UpdateHotbarEvent:FireClient(plyr)
	end)
	
	
end)

CoreEvent.OnServerEvent:Connect(function(plyr, eventtype)
	local Character = plyr.Character
	if eventtype == "EquipRod" then
		local Rod = RodsFolder:FindFirstChild(plyr.EquippedRod.Value)
		--local Rod = plyr.Backpack:FindFirstChild(plyr.EquippedRod.Value)
		if Rod then
			local RodClone = Rod:Clone()
			local RodCasted = Instance.new("BoolValue")
			RodCasted.Name = "RodCasted"
			RodCasted.Value = false
			RodCasted.Parent = RodClone
			RodClone.Parent = Character
			
			local CastForce = 70
			local UpForce = 35
			local LineLength = 20 -- 15
			
			RodClone.Activated:Connect(function()
				if plyr.isFishing.Value == true then return end
				local StartPosition = Character.HumanoidRootPart.Position
				-- local Direction =  Character.HumanoidRootPart.CFrame.LookVector
				-- make dir diagonally downward instead !
				local Direction = (Character.HumanoidRootPart.CFrame.LookVector * 30) + Vector3.new(0, -10, 0)
				local RayCastParams = RaycastParams.new()
				RayCastParams.FilterType = Enum.RaycastFilterType.Exclude
				RayCastParams.FilterDescendantsInstances = {Character:GetDescendants()}
				
				-- local Ray = workspace:Raycast(StartPosition, Direction * 8, RayCastParams)
				local Ray = workspace:Raycast(StartPosition, Direction, RayCastParams)
				local NearWater = false
				local sub = false
				--print(Ray and Ray.Instance.Name)
				
				-- WaterDetectionPart overlaps water terrain + a bit higher
				if Ray and Ray.Instance and 
					(Ray.Instance.Name == "WaterDetectionPart" or Ray.Instance.Name == "WaterDetectionPart2") then
					NearWater = true
					if Ray.Instance.Name == "WaterDetectionPart2" then
						sub = true
					end
					--print("YOU ARE NEAR WATER YAY")
				end
				
				if RodCasted.Value == false and NearWater == true then
					RodCasted.Value = true
					
					local RodAttachment = RodClone.Part.Attachment1
					local Bobber = Instance.new("Part")
					Bobber.Name = "Bobber"
					Bobber.Size = Vector3.new(0.5, 0.5, 0.5)
					Bobber.Shape = Enum.PartType.Ball
					Bobber.Material = Enum.Material.Plastic
					Bobber.Color = Color3.new(255, 60, 60)
					Bobber.CanCollide = true
					Bobber.Anchored = false
					Bobber.Position = RodClone.Part.Position + Character.HumanoidRootPart.CFrame.LookVector * 2
					Bobber.Parent = RodClone
					
					local BobberAttachment = Instance.new("Attachment")
					BobberAttachment.Parent = Bobber
					
					local Rope = Instance.new("RopeConstraint")
					Rope.Attachment0 = RodAttachment
					Rope.Attachment1 = BobberAttachment
					Rope.Length = LineLength
					Rope.Visible = true
					Rope.Thickness = 0.05
					Rope.Parent = Bobber
					
					
					Direction = Character.HumanoidRootPart.CFrame.LookVector
					--Direction = (Character.HumanoidRootPart.CFrame.LookVector * 2)
					Bobber.AssemblyLinearVelocity = Direction * CastForce + Vector3.new(0, UpForce, 0)

					
					Bobber.Touched:Connect(function(hit)
						if hit:HasTag("stop") and not Bobber.Anchored then
							Bobber.AssemblyLinearVelocity = Vector3.zero
							Bobber.AssemblyAngularVelocity = Vector3.zero
							Character.HumanoidRootPart.Anchored = true
							--Bobber.Anchored = true
						end
					end)
					task.spawn(function() -- Looking for fish to catch
						plyr.isFishing.Value = true
						task.wait(math.random(2,6))
						-- if plyr.isFishing.Value == false then return end
						if plyr.isFishing.Value == false or not RodCasted.Value then return end
						
						--plyr.currentFishCatching.Value = FishingServer.getRandomFishName()..","..FishingServer.getRandomFishSize()
						if not sub then
							local fishName = FishingServer.getRandomOffshoreFish() 
							local fishSize = FishingServer.getRandomFishSize()
							print(sub, fishName, fishSize)
						else
							local fishName = FishingServer.getRandomSubFish() 
							local fishSize = FishingServer.getRandomFishSize()
							print(sub, fishName, fishSize)
						end
						
						plyr.currentFishCatching.Value = fishName .. "," .. fishSize
						FishingEvent:FireClient(plyr, plyr.currentFishCatching.Value)						
					end)
				elseif RodCasted.Value == true and NearWater == true then
					RodClone.Bobber:Destroy()
					RodCasted.Value = false
					plyr.currentFishCatching.Value = ""
					Character.HumanoidRootPart.Anchored = false
				end
				
			end)
		end
	elseif eventtype == "UnequipRod" then
		Character.HumanoidRootPart.Anchored = false
		local Rod = Character:FindFirstChild(plyr.EquippedRod.Value)
		if Rod then
			Rod:Destroy()
			plyr.isFishing.Value = false
		end
		
	end
	
end)


-- Save data when a player leaves
players.PlayerRemoving:Connect(function(plyr)
	local userId = tostring(plyr.UserId)
	local leaderstats = plyr:FindFirstChild("leaderstats")
	if not leaderstats then return end
	saveData(CoinesDataStore, userId, leaderstats.Coines.Value)
	saveData(LevelDataStore,  userId, leaderstats.level.Value)
	saveData(CaughtDataStore, userId, leaderstats.FishesCaught.Value)
end)

-- Catch server shutdowns so data saves before the server closes
game:BindToClose(function()
	for _, plyr in ipairs(players:GetPlayers()) do
		local userId = tostring(plyr.UserId)
		local leaderstats = plyr:FindFirstChild("leaderstats")
		if leaderstats then
			saveData(CoinesDataStore, userId, leaderstats.Coines.Value)
			saveData(LevelDataStore,  userId, leaderstats.level.Value)
			saveData(CaughtDataStore, userId, leaderstats.FishesCaught.Value)
		end
	end
end)