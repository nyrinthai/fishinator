local BoatManager = require(game.ServerScriptService:WaitForChild("BoatManager"))
local ClickDetector = script.Parent:WaitForChild("ClickDetector")
local SpawnPart = script.Parent:WaitForChild("Spawn")
local BoatTemplate = game.ServerStorage:WaitForChild("WoodenBoat")

local pos = SpawnPart.Position + Vector3.new(0, 2, 0)
local yaw = math.rad(180)

ClickDetector.MouseClick:Connect(function(player)
	local newBoat = BoatTemplate:Clone()
	newBoat.Parent = workspace
	newBoat:PivotTo(CFrame.new(pos) * CFrame.Angles(0, yaw, 0))
	BoatManager:ReplaceBoat(player, newBoat)
end)