local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local RE = RS:WaitForChild("RemoteEvents")
local CoreEvent = RE:WaitForChild("CoreEvent")
local EquipFishEvent = RE:WaitForChild("EquipFishEvent")
local UpdateHotbarEvent = RE:WaitForChild("UpdateHotbar")

local Player = game.Players.LocalPlayer
local MainGui = Player:WaitForChild("PlayerGui"):WaitForChild("MainGui")
local Hotbar = MainGui:WaitForChild("Hotbar")

local Slot1 = Hotbar:WaitForChild("Slot1")
local Slot2 = Hotbar:WaitForChild("Slot2")
local Slot3 = Hotbar:WaitForChild("Slot3")
local Slot4 = Hotbar:WaitForChild("Slot4")
local Slot5 = Hotbar:WaitForChild("Slot5")

local FishSlots = {Slot2, Slot3, Slot4, Slot5}

local RodEquipped = false
local equippedSlot = nil

local function setSelected(slotObject)
	Slot1.UIStroke.Color = Color3.fromRGB(0, 0, 0)
	for _, slot in ipairs(FishSlots) do
		slot.UIStroke.Color = Color3.fromRGB(0, 0, 0)
	end

	if slotObject then
		slotObject.UIStroke.Color = Color3.fromRGB(255, 255, 255)
	end
end

local function updateHotbar()
	Slot1.item.Text = Player.EquippedRod.Value
	
	local fishInventory = Player.FishInventory:GetChildren()

	for _, slot in ipairs(FishSlots) do
		slot.item.Text = ""
	end

	for i = 1, math.min(#fishInventory, 4) do
		FishSlots[i].item.Text = fishInventory[i].Name
	end
end

CoreEvent.OnClientEvent:Connect(function(eventtype)
	if eventtype == "DisableBackpack" then
		game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end
end)

UIS.InputBegan:Connect(function(Input, processed)
	if processed then return end
	if Input.UserInputType ~= Enum.UserInputType.Keyboard then return end

	if Input.KeyCode == Enum.KeyCode.One then
		equippedSlot = nil
		EquipFishEvent:FireServer("UnequipFish")

		if RodEquipped then
			CoreEvent:FireServer("UnequipRod")
			RodEquipped = false
			setSelected(nil)
		else
			CoreEvent:FireServer("EquipRod")
			RodEquipped = true
			setSelected(Slot1)
		end
		return
	end

	local slotNumber = nil

	if Input.KeyCode == Enum.KeyCode.Two then
		slotNumber = 1
	elseif Input.KeyCode == Enum.KeyCode.Three then
		slotNumber = 2
	elseif Input.KeyCode == Enum.KeyCode.Four then
		slotNumber = 3
	elseif Input.KeyCode == Enum.KeyCode.Five then
		slotNumber = 4
	end

	if slotNumber then
		if RodEquipped then
			CoreEvent:FireServer("UnequipRod")
			RodEquipped = false
		end

		if equippedSlot == slotNumber then
			EquipFishEvent:FireServer("UnequipFish")
			equippedSlot = nil
			setSelected(nil)
		else
			EquipFishEvent:FireServer("EquipFish", slotNumber)
			equippedSlot = slotNumber
			setSelected(FishSlots[slotNumber])
		end
	end
end)

UpdateHotbarEvent.OnClientEvent:Connect(updateHotbar)