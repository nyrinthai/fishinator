local BoatManager = {}

BoatManager.PlayerBoats = {}

function BoatManager:ReplaceBoat(player, newBoat)
	local oldBoat = self.PlayerBoats[player]
	if oldBoat and oldBoat.Parent then
		oldBoat:Destroy()
	end

	self.PlayerBoats[player] = newBoat

	newBoat.Destroying:Connect(function()
		if self.PlayerBoats[player] == newBoat then
			self.PlayerBoats[player] = nil
		end
	end)
end

function BoatManager:RemoveBoat(player)
	local boat = self.PlayerBoats[player]
	if boat and boat.Parent then
		boat:Destroy()
	end
	self.PlayerBoats[player] = nil
end

return BoatManager