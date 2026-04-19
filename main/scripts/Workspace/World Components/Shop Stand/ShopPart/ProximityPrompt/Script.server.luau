local p = script.Parent

p.Triggered:Connect(function(player)
	player.PlayerGui.ShopGui.Enabled = not player.PlayerGui.ShopGui.Enabled
end)