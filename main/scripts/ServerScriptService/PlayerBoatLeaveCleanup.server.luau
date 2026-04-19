local Players = game:GetService("Players")
local BoatManager = require(game.ServerScriptService:WaitForChild("BoatManager"))

Players.PlayerRemoving:Connect(function(player)
	BoatManager:RemoveBoat(player)
end)