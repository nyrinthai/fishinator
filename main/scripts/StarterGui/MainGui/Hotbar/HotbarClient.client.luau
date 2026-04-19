local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RE = ReplicatedStorage:WaitForChild("RemoteEvents")
local CoreEvent = RE:WaitForChild("CoreEvent")
local EquipFishEvent = RE:WaitForChild("EquipFishEvent")
local UpdateHotbarEvent = RE:WaitForChild("UpdateHotbar")

local player = game.Players.LocalPlayer
local hotbar = script.Parent
local previewFolder = ReplicatedStorage:WaitForChild("ItemPreviews")

local Slot1 = hotbar:WaitForChild("Slot1")
local Slot2 = hotbar:WaitForChild("Slot2")
local Slot3 = hotbar:WaitForChild("Slot3")
local Slot4 = hotbar:WaitForChild("Slot4")
local Slot5 = hotbar:WaitForChild("Slot5")

local FishSlots = {Slot2, Slot3, Slot4, Slot5}

local RodEquipped = false
local equippedSlot = nil

local function clearViewport(viewportFrame)
	for _, child in ipairs(viewportFrame:GetChildren()) do
		child:Destroy()
	end
	viewportFrame.BackgroundTransparency = 1
end

local function setupViewport(viewportFrame, itemName)
	clearViewport(viewportFrame)

	if not itemName or itemName == "" then
		return
	end

	local sourceModel = previewFolder:FindFirstChild(itemName)
	if not sourceModel then
		warn("Missing preview model for", itemName)
		return
	end

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewportFrame

	local clone = sourceModel:Clone()
	clone.Parent = worldModel

	local camera = Instance.new("Camera")
	camera.Parent = viewportFrame
	viewportFrame.CurrentCamera = camera
	viewportFrame.BackgroundTransparency = 1

	local cf, size = clone:GetBoundingBox()
	local center = cf.Position
	local biggest = math.max(size.X, size.Y, size.Z)
	local distance = biggest * 0.5

	camera.CFrame = CFrame.new(
		center + Vector3.new(distance, distance * 0.4, distance),
		center
	)
end

local function updateSlot(slot, itemName)
	slot.item.Text = itemName or ""

	local viewport = slot:FindFirstChild("ViewportFrame")
	if not viewport then
		return
	end

	if itemName and itemName ~= "" then
		setupViewport(viewport, itemName)
	else
		clearViewport(viewport)
	end
end

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
	local rodName = player:WaitForChild("EquippedRod").Value
	updateSlot(Slot1, rodName)

	local fishInventory = player:WaitForChild("FishInventory"):GetChildren()

	for _, slot in ipairs(FishSlots) do
		updateSlot(slot, nil)
	end

	for i = 1, math.min(#fishInventory, 4) do
		updateSlot(FishSlots[i], fishInventory[i].Name)
	end
end

UIS.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end

	if input.KeyCode == Enum.KeyCode.One then
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

	if input.KeyCode == Enum.KeyCode.Two then
		slotNumber = 1
	elseif input.KeyCode == Enum.KeyCode.Three then
		slotNumber = 2
	elseif input.KeyCode == Enum.KeyCode.Four then
		slotNumber = 3
	elseif input.KeyCode == Enum.KeyCode.Five then
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

updateHotbar()