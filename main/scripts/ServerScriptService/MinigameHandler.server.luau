local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local SSS = game:GetService("ServerScriptService")

--local Fishes = SS:WaitForChild("Fishes")
local Fish = SS:WaitForChild("Fish")
local RE = RS:WaitForChild("RemoteEvents")
local EndFishingEvent = RE:WaitForChild("EndFishingMinigame")
local UpdateHotbarEvent = RE:WaitForChild("UpdateHotbar")
local DataStoreService = game:GetService("DataStoreService")
local CaughtDataStore = DataStoreService:GetDataStore("Caught")
local FishingServer = require(SSS:WaitForChild("FishingServer"))

local function cleanupRod(player)
	local character = player.Character
	if not character then return end

	local rod = character:FindFirstChild(player.EquippedRod.Value)
	if not rod then return end

	local bobber = rod:FindFirstChild("Bobber")
	if bobber then
		bobber:Destroy()
	end

	local rodCasted = rod:FindFirstChild("RodCasted")
	if rodCasted then
		rodCasted.Value = false
	end
end

EndFishingEvent.OnServerEvent:Connect(function(player, status)
	local currentFishCatching = player.currentFishCatching.Value
	if status == "win" and currentFishCatching ~= "" then
		player.leaderstats.FishesCaught.Value += 1
		CaughtDataStore:SetAsync(tostring(player.UserId), player.leaderstats.FishesCaught.Value)
		local splitData = string.split(currentFishCatching, ",")
		local fishName = splitData[1]
		local fishSize = splitData[2]

		local fishTemplate = Fish:FindFirstChild(fishName)
		local fishInventory = player:FindFirstChild("FishInventory")
		if fishTemplate and fishInventory and #fishInventory:GetChildren() < 4 then
			local clonedFish = fishTemplate:Clone()

			local fishValue = Instance.new("IntValue")
			fishValue.Name = "Value"
			
			-- local data = FishingServer.OffshoreFish[fishName]
			--fishValue.Value = FishingServer[fishName][fishSize]
			local data = FishingServer[fishName]
			if data then
				fishValue.Value = data.Values[fishSize]
			else
				print("no data")
			end
			
			fishValue.Parent = clonedFish

			local fishSizeString = Instance.new("StringValue")
			fishSizeString.Name = "FishSize"
			fishSizeString.Value = fishSize
			fishSizeString.Parent = clonedFish

			clonedFish.Parent = fishInventory
			UpdateHotbarEvent:FireClient(player)
		end
	elseif status == "lose" then
		print("player lost the fish")
	end
	player.Character.HumanoidRootPart.Anchored = false

	cleanupRod(player)
	player.isFishing.Value = false
	player.currentFishCatching.Value = ""
end)