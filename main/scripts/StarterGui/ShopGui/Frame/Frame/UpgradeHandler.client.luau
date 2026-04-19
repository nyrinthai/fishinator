 local PurchaseRodEvent = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("PurchaseRod")
local UpdateShopUIEvent =  game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("UpdateShopUI")
local player = game.Players.LocalPlayer
local leaderstats = player:WaitForChild("leaderstats")
local upg1 = script.Parent.Upgrade1.PurchaseButton
local upg2 = script.Parent.Upgrade2.PurchaseButton
local upg3 = script.Parent.Upgrade3.PurchaseButton


upg1.Activated:Connect(function()
	PurchaseRodEvent:FireServer("upg1")
end)
upg2.Activated:Connect(function()
	PurchaseRodEvent:FireServer("upg2")
end)
upg3.Activated:Connect(function()
	PurchaseRodEvent:FireServer("upg3")
end)

UpdateShopUIEvent.OnClientEvent:Connect(function()
	if player.leaderstats.level.Value >= 2 then
		upg1.Active = false
		upg1.Text = "Purchased"
	end
	
	if player.leaderstats.level.Value >= 3 then
		upg2.Active = false
		upg2.Text = "Purchased"
	end
	
	if player.leaderstats.level.Value >= 4 then
		upg3.Active = false
		upg3.Text = "Purchased"
	end
	
	if player.leaderstats.level.Value == 1 then
		upg1.Text = "$500"
		upg2.Text = "Locked"
		upg3.Text = "Locked"
	end
	
	if player.leaderstats.level.Value == 2 then
		upg2.Text = "$2000"
		upg3.Text = "Locked"
	end
	
	if player.leaderstats.level.Value == 3 then
		upg3.Text = "$5000"
	end
end)


 