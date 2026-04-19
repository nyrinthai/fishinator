print("VendorServer loaded!")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local FishValues = require(script.Parent.FishingServer)
local VendorRemote = game.ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("VendorRemote")
local ReputationStore = DataStoreService:GetDataStore("VendorReputation")
local UHE = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("UpdateHotbar")
local PROXY_URL = "https://fishinator-proxy-production.up.railway.app/chat"
local CoreEvent = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("CoreEvent")
local playerHistories = {}
local playerReputations = {}

Players.PlayerAdded:Connect(function(player)
	local success, rep = pcall(function()
		return ReputationStore:GetAsync("rep_" .. player.UserId)
	end)
	CoreEvent:FireClient(player, "DisableBackpack")

	playerReputations[player.UserId] = success and rep or 0
	print(player.Name .. " reputation loaded:", playerReputations[player.UserId])
	task.wait(1)
	VendorRemote:FireClient(player, "REP_UPDATE", playerReputations[player.UserId])
end)

Players.PlayerRemoving:Connect(function(player)
	local rep = playerReputations[player.UserId] or 0
	pcall(function()
		ReputationStore:SetAsync("rep_" .. player.UserId, rep)
	end)
	playerReputations[player.UserId] = nil
	playerHistories[player.UserId] = nil
end)

local function getRepTier(rep)
	if rep >= 75 then return "trusted"
	elseif rep >= 40 then return "familiar"
	elseif rep >= 10 then return "neutral"
	else return "new"
	end
end

local function getRepContext(rep)
	local tier = getRepTier(rep)
	if tier == "trusted" then
		return "[REPUTATION: This player is a trusted regular. Start your opening offer at 70% to 80% of market value. Be warm and friendly.] "
	elseif tier == "familiar" then
		return "[REPUTATION: This player is a familiar face. Start your opening offer at 65% to 75% of market value. Be slightly friendlier than usual.] "
	elseif tier == "neutral" then
		return "[REPUTATION: This player is a known customer. Start your opening offer at 55% to 70% of market value.] "
	else
		return "[REPUTATION: New customer, never seen them before. Start your opening offer at 50% to 65% of market value. Be cautious.] "
	end
end

local function callVendor(player, prompt, fishSpecies, fishSize)
	local fishData = FishValues[fishSpecies]
	local baseValue = fishData and fishData.Values and fishData.Values[fishSize] or 0
	local userId = player.UserId

	if not playerHistories[userId] then
		playerHistories[userId] = {}
	end

	local rep = playerReputations[userId] or 0
	local repContext = getRepContext(rep)

	local fullPrompt = string.format(
		"%s[Player is selling a %s %s. Base market value is $%d] Player says: %s",
		repContext, fishSize, fishSpecies, baseValue, prompt
	)

	local success, response = pcall(function()
		return HttpService:RequestAsync({
			Url = PROXY_URL,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode({
				prompt = fullPrompt,
				history = playerHistories[userId]
			})
		})
	end)

	if success and response.StatusCode == 200 then
		local data = HttpService:JSONDecode(response.Body)
		playerHistories[userId] = data.history

		if data.reply and data.reply:find("%[VENDOR_DONE%]") then
			playerReputations[userId] = math.max(0, (playerReputations[userId] or 0) - 10)
			pcall(function()
				ReputationStore:SetAsync("rep_" .. userId, playerReputations[userId])
			end)
		end

		return data.reply
	else
		warn("Vendor proxy error:", response and response.Body or "unknown")
		return "Hmm, I'm not sure about that. Try again!"
	end
end

VendorRemote.OnServerEvent:Connect(function(player, prompt, fishSpecies, fishSize, offerAmount)
	print("Server received:", prompt, fishSpecies, fishSize)

	if prompt == "GREETING" then
		VendorRemote:FireClient(player, "REP_UPDATE", playerReputations[player.UserId] or 0)
		local hasFish = fishSpecies ~= "none" and FishValues[fishSpecies] ~= nil
		local greetingPrompt
		local userId = player.UserId
		local rep = playerReputations[userId] or 0
		local repContext = getRepContext(rep)

		if hasFish then
			local fishData = FishValues[fishSpecies]
			local baseValue = fishData and fishData.Values and fishData.Values[fishSize] or 0
			greetingPrompt = string.format(
				"[%sPlayer just opened the shop holding a %s %s. Market value $%d. Greet them, comment on the fish, then immediately make an opening offer.]",
				repContext, fishSize, fishSpecies, baseValue
			)
		else
			greetingPrompt = "[" .. repContext .. "Player just opened the shop with no fish in hand. Tell them to come back when they have a fish to sell. Stay in character.]"
		end

		print("Greeting prompt with fish:", greetingPrompt)

		if not playerHistories[userId] then
			playerHistories[userId] = {}
		end

		local success, response = pcall(function()
			return HttpService:RequestAsync({
				Url = PROXY_URL,
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = HttpService:JSONEncode({
					prompt = greetingPrompt,
					history = playerHistories[userId]
				})
			})
		end)

		if success and response.StatusCode == 200 then
			local data = HttpService:JSONDecode(response.Body)
			playerHistories[userId] = data.history
			print("Greeting reply:", data.reply)
			VendorRemote:FireClient(player, data.reply, playerReputations[player.UserId] or 0)
		else
			warn("Greeting error:", response and response.StatusCode, response and response.Body)
			VendorRemote:FireClient(player, "Arrgh, somethin's gone wrong with me thinkin'... try again!", playerReputations[player.UserId] or 0)
		end
		return
	end

	if prompt == "ACCEPT_OFFER" then
		local amount = tonumber(offerAmount)
		local fish =player.Character:FindFirstChildWhichIsA("Tool")
		if not fish then return end
		if amount then
			local coins = player:FindFirstChild("leaderstats") and
				player.leaderstats:FindFirstChild("Coines")
			if coins then
				coins.Value = coins.Value + amount
				print(player.FishInventory:GetChildren())
				print(player.SlotEquipped.Value)
				player.FishInventory:GetChildren()[player.SlotEquipped.Value]:Destroy()
				fish:Destroy()
				UHE:FireClient(player)
				print(player.Name .. " received $" .. amount)
			end
			playerReputations[player.UserId] = (playerReputations[player.UserId] or 0) + 5
			pcall(function()
				ReputationStore:SetAsync("rep_" .. player.UserId, playerReputations[player.UserId])
			end)
		end
		playerHistories[player.UserId] = {}
		
		return
	end

	if prompt == "CLEAR_HISTORY" then
		playerHistories[player.UserId] = {}
		return
	end

	local reply = callVendor(player, prompt, fishSpecies, fishSize)
	print("Got reply:", reply)
	VendorRemote:FireClient(player, reply, playerReputations[player.UserId] or 0)
end)

local function setReputation(player, amount)
	playerReputations[player.UserId] = amount
	pcall(function()
		ReputationStore:SetAsync("rep_" .. player.UserId, amount)
	end)
	print(player.Name .. " reputation set to:", amount)
end

-- Set your own rep to max on join for testing
Players.PlayerAdded:Connect(function(player)
	if player.Name == "TheOrbitalLight" then
		task.wait(1)
 		setReputation(player, 100)
	end
end)

--So the tiers across 0-100 are:

--	0-9: New — cautious, 50-65%
--	10-39: Neutral — normal, 55-70%
--	40-74: Familiar — friendlier, 65-75%
--	75-100: Trusted — warm, 70-80%