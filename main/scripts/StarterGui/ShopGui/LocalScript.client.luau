local ReplicatedStorage = game:GetService("ReplicatedStorage")

local rodPreviews = ReplicatedStorage:WaitForChild("ItemPreviews")

local shopGui = script.Parent
local slot1 = shopGui:WaitForChild("Frame"):WaitForChild("Frame"):WaitForChild("Upgrade1")
local slot2 = shopGui:WaitForChild("Frame"):WaitForChild("Frame"):WaitForChild("Upgrade2")
local slot3 = shopGui:WaitForChild("Frame"):WaitForChild("Frame"):WaitForChild("Upgrade3")

local function showToolInViewport(viewportFrame, tool)
	viewportFrame:ClearAllChildren()

	local clone = tool:Clone()
	clone.Parent = viewportFrame

	local camera = Instance.new("Camera")
	camera.Parent = viewportFrame
	viewportFrame.CurrentCamera = camera

	local handle = clone:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		warn("Tool has no valid Handle:", tool.Name)
		return
	end

	-- Put the tool at the center of the viewport world
	clone:PivotTo(
		CFrame.new(0, -1, 0) *
			CFrame.Angles(0, 0, math.rad(70))
	)

	local size = clone:GetExtentsSize()
	local dist = math.max(size.X, size.Y, size.Z) * 0.5

	camera.CFrame = CFrame.lookAt(
		Vector3.new(0, size.Y * 0.2, dist),
		Vector3.new(0, 0, 0)
	)
end

showToolInViewport(slot1.ViewportFrame, rodPreviews:WaitForChild("Amethyst Rod"))
showToolInViewport(slot2.ViewportFrame, rodPreviews:WaitForChild("Emerald Rod"))
showToolInViewport(slot3.ViewportFrame, rodPreviews:WaitForChild("Crimson Rod"))