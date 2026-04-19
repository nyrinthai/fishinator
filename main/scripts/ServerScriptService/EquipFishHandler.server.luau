local RS = game:GetService("ReplicatedStorage")
local RE = RS:WaitForChild("RemoteEvents")
local EquipFishEvent = RE:WaitForChild("EquipFishEvent")

local equippedFishByPlayer = {}

local function unequipCurrentFish(player)
	local equippedFish = equippedFishByPlayer[player]
	if equippedFish and equippedFish.Parent then
		equippedFish:Destroy()
	end
	equippedFishByPlayer[player] = nil
end

EquipFishEvent.OnServerEvent:Connect(function(player, action, slotIndex)
	local character = player.Character
	if not character then return end

	local fishInventoryFolder = player:FindFirstChild("FishInventory")
	if not fishInventoryFolder then return end

	local fishInventory = fishInventoryFolder:GetChildren()

	if action == "UnequipFish" then
		unequipCurrentFish(player)
		player.SlotEquipped.Value = 0
		return
	end

	if action == "EquipFish" then
		player.SlotEquipped.Value = slotIndex
		slotIndex = tonumber(slotIndex)
		if not slotIndex then return end
		if slotIndex < 1 or slotIndex > 4 then return end

		local sourceFish = fishInventory[slotIndex]
		if not sourceFish then
			unequipCurrentFish(player)
			return
		end

		unequipCurrentFish(player)

		local clonedFish = sourceFish:Clone()
		clonedFish.Parent = character
		equippedFishByPlayer[player] = clonedFish
	end
end)

game.Players.PlayerRemoving:Connect(function(player)
	equippedFishByPlayer[player] = nil
end)