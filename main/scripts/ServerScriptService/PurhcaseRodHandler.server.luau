local RS = game:GetService("ReplicatedStorage")
local RE = RS:WaitForChild("RemoteEvents")
local Rods = game:GetService("ServerStorage"):WaitForChild("Rods")
local PurchaseRodEvent = RE:WaitForChild("PurchaseRod")
local UpdateShopUIEvent = RE:WaitForChild("UpdateShopUI")
local UpdateGameDiffEvent = RE:WaitForChild("UpdateMinigameDifficulty")
local UpdateHotbarEvent = RE:WaitForChild("UpdateHotbar")
local DataStoreService = game:GetService("DataStoreService")
local LevelDataStore = DataStoreService:GetDataStore("Level")
PurchaseRodEvent.OnServerEvent:Connect(function(player, upgrade)
	local leaderstats = player:WaitForChild("leaderstats")
	local playerMoney = leaderstats:WaitForChild("Coines").Value
	if upgrade == "upg1" and playerMoney >= 500 and leaderstats:WaitForChild("level").Value == 1 then
		destroyRod(player)
		leaderstats:WaitForChild("Coines").Value -= 500
		leaderstats:WaitForChild("level").Value = 2
		player.EquippedRod.Value = "Amethyst Rod"
		LevelDataStore:SetAsync(tostring(player.UserId), 2)
	elseif upgrade == "upg2" and playerMoney >= 2000 and leaderstats:WaitForChild("level").Value == 2 then
		destroyRod(player)
		leaderstats:WaitForChild("Coines").Value -= 2000
		leaderstats:WaitForChild("level").Value = 3
		player.EquippedRod.Value = "Emerald Rod"
		LevelDataStore:SetAsync(tostring(player.UserId), 3)
	elseif upgrade == "upg3" and playerMoney >= 5000 and leaderstats:WaitForChild("level").Value == 3 then
		destroyRod(player)
		leaderstats:WaitForChild("Coines").Value -= 5000
		leaderstats:WaitForChild("level").Value = 4
		player.EquippedRod.Value = "Crimson Rod"
		LevelDataStore:SetAsync(tostring(player.UserId), 4)
	end
	UpdateShopUIEvent:FireClient(player)
	updateGameDiff(player)
	UpdateHotbarEvent:FireClient(player)
end)

function destroyRod(player)
	local Rod = player.Character:FindFirstChild(player.EquippedRod.Value)
	if Rod then
		Rod:Destroy()
		player.isFishing.Value = false
	end
end

function updateGameDiff(player)
	local rodClone = Rods:FindFirstChild(player.EquippedRod.Value)
	local barSize = rodClone:GetAttribute("BarSize")
	local ProgressDecaySpeed = rodClone:GetAttribute("ProgressDecaySpeed")
	local ProgressFillSpeed = rodClone:GetAttribute("ProgressFillSpeed")
	UpdateGameDiffEvent:FireClient(player, barSize, ProgressFillSpeed, ProgressDecaySpeed)

end