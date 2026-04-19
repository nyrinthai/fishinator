print("VendorScript loaded!")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local localRep = 0

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local VendorRemote = game.ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("VendorRemote")

local gui = script.Parent
local frame = script.Parent
local chatScroll = frame:WaitForChild("ChatScroll")
local chatInput = frame:WaitForChild("InputRow"):WaitForChild("ChatInput")
local sendBtn = frame:WaitForChild("InputRow"):WaitForChild("SendButton")
local fishNameLabel = frame:WaitForChild("FishBar"):WaitForChild("FishName")
local marketValueLabel = frame:WaitForChild("FishBar"):WaitForChild("MarketValue")
local repLabel = frame:WaitForChild("Header"):WaitForChild("RepLabel")
local activeOfferButtons = {}

local scrollLayout = chatScroll:FindFirstChildWhichIsA("UIListLayout")
if not scrollLayout then
	scrollLayout = Instance.new("UIListLayout")
	scrollLayout.FillDirection = Enum.FillDirection.Vertical
	scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
	scrollLayout.Padding = UDim.new(0, 8)
	scrollLayout.Parent = chatScroll
end

scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	chatScroll.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 16)
end)

local isOpen = false
local isWaiting = false -- prevent spamming while vendor is replying

-- The fish the player is currently selling (set this from your fishing system)
local currentFish = {
	species = "none",
	size = "none",
	value = 0
}

local function updateRepLabel(rep)
	local tier
	if rep >= 75 then tier = "Trusted"
	elseif rep >= 40 then tier = "Familiar"
	elseif rep >= 10 then tier = "Neutral"
	else tier = "New"
	end
	repLabel.Text = "Rep: " .. rep .. " (" .. tier .. ")"
end

-- UI Templates
local function createMessageBubble(text, isPlayer, isOffer, offerAmount)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 0)
	container.BackgroundTransparency = 1
	container.AutomaticSize = Enum.AutomaticSize.Y
	container.Name = "Message"

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = isPlayer and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
	layout.Padding = UDim.new(0, 4)
	layout.Parent = container

	-- Name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 16)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = isPlayer and "You" or "Triple T"
	nameLabel.TextSize = 11
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	nameLabel.TextXAlignment = isPlayer and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
	nameLabel.LayoutOrder = 1
	nameLabel.Parent = container

	-- Bubble
	local bubble = Instance.new("TextLabel")
	bubble.Size = UDim2.new(0.78, 0, 0, 0)
	bubble.AutomaticSize = Enum.AutomaticSize.Y
	bubble.BackgroundColor3 = isPlayer and Color3.fromRGB(55, 138, 221) or Color3.fromRGB(240, 240, 240)
	bubble.TextColor3 = isPlayer and Color3.fromRGB(230, 241, 251) or Color3.fromRGB(30, 30, 30)
	bubble.Text = text
	bubble.TextSize = 13
	bubble.Font = Enum.Font.Gotham
	bubble.TextWrapped = true
	bubble.TextXAlignment = Enum.TextXAlignment.Left
	bubble.Position = isPlayer and UDim2.new(0.22, 0, 0, 0) or UDim2.new(0, 0, 0, 0)
	bubble.LayoutOrder = 2

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = bubble

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = bubble

	bubble.Parent = container


	-- Offer buttons if vendor made an offer
	if isOffer and offerAmount then
		local offerBox = Instance.new("Frame")
		offerBox.Size = UDim2.new(0.78, 0, 0, 80)
		offerBox.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
		offerBox.LayoutOrder = 3

		local offerCorner = Instance.new("UICorner")
		offerCorner.CornerRadius = UDim.new(0, 10)
		offerCorner.Parent = offerBox

		local offerPadding = Instance.new("UIPadding")
		offerPadding.PaddingTop = UDim.new(0, 10)
		offerPadding.PaddingBottom = UDim.new(0, 10)
		offerPadding.PaddingLeft = UDim.new(0, 12)
		offerPadding.PaddingRight = UDim.new(0, 12)
		offerPadding.Parent = offerBox

		local amountLabel = Instance.new("TextLabel")
		amountLabel.Size = UDim2.new(1, 0, 0, 24)
		amountLabel.BackgroundTransparency = 1
		amountLabel.Text = "$" .. offerAmount
		amountLabel.TextSize = 18
		amountLabel.Font = Enum.Font.GothamBold
		amountLabel.TextColor3 = Color3.fromRGB(30, 30, 30)
		amountLabel.TextXAlignment = Enum.TextXAlignment.Left
		amountLabel.Parent = offerBox

		local btnRow = Instance.new("Frame")
		btnRow.Size = UDim2.new(1, 0, 0, 32)
		btnRow.Position = UDim2.new(0, 0, 0, 36)
		btnRow.BackgroundTransparency = 1
		btnRow.Parent = offerBox

		local btnLayout = Instance.new("UIListLayout")
		btnLayout.FillDirection = Enum.FillDirection.Horizontal
		btnLayout.Padding = UDim.new(0, 8)
		btnLayout.Parent = btnRow

		local acceptBtn = Instance.new("TextButton")
		table.insert(activeOfferButtons, acceptBtn)
		acceptBtn.Size = UDim2.new(1, -4, 1, 0)
		acceptBtn.BackgroundColor3 = Color3.fromRGB(29, 158, 117)
		acceptBtn.TextColor3 = Color3.fromRGB(225, 245, 238)
		acceptBtn.Text = "Accept"
		acceptBtn.TextSize = 13
		acceptBtn.Font = Enum.Font.GothamBold
		Instance.new("UICorner", acceptBtn).CornerRadius = UDim.new(0, 8)
		acceptBtn.Parent = btnRow

		-- Accept: complete the transaction
		acceptBtn.MouseButton1Click:Connect(function()
			acceptBtn.Active = false
			acceptBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
			chatInput.TextEditable = false
			sendBtn.Active = false
			chatInput.PlaceholderText = "Deal complete!"
			-- Fire to server to give player the money
			VendorRemote:FireServer("ACCEPT_OFFER", currentFish.species, currentFish.size, offerAmount)
			addMessage("Deal! Here's your $" .. offerAmount .. ". Pleasure doin' business!", false, false, nil)
			
		end)

		offerBox.Parent = container
	end

	return container
end

-- Add message to chat scroll
function addMessage(text, isPlayer, isOffer, offerAmount)
	local bubble = createMessageBubble(text, isPlayer, isOffer, offerAmount)
	bubble.Parent = chatScroll

	-- Scroll to bottom
	task.wait(0.1)
	chatScroll.CanvasPosition = Vector2.new(0, chatScroll.AbsoluteCanvasSize.Y)
end

-- Extract offer amount from vendor reply (looks for $ followed by digits)
local function extractOffer(text)
	local amount = text:match("%[OFFER:(%d+)%]")
	return amount and tonumber(amount) or nil
end

local typingIndicator = frame:WaitForChild("TypingFrame")
-- Send message
local function sendMessage()
	if isWaiting then return end
	local text = chatInput.Text
	if text == "" or text == nil then return end
	print("Sending message:", text)

	chatInput.Text = ""
	addMessage(text, true, false, nil)
	isWaiting = true
	sendBtn.Active = false
	
	typingIndicator.Visible = true
	VendorRemote:FireServer(text, currentFish.species, currentFish.size)
end

local function getCurrentFish()
	local character = player.Character
	if not character then return nil end

	local tool = character:FindFirstChildWhichIsA("Tool")
	if not tool then return nil end

	local species = tool.Name
	local sizeObj = tool:FindFirstChild("FishSize")
	local valueObj = tool:FindFirstChild("Value")

	if not sizeObj or not valueObj then return nil end

	return {
		species = species,
		size = sizeObj.Value,
		value = valueObj.Value
	}
end

sendBtn.MouseButton1Click:Connect(sendMessage)

chatInput.FocusLost:Connect(function(enterPressed)
	if enterPressed then sendMessage() end
end)

-- Receive vendor reply
VendorRemote.OnClientEvent:Connect(function(reply, rep)
	if reply == "REP_UPDATE" then
		localRep = rep
		updateRepLabel(rep)
		return
	end
	typingIndicator.Visible = false
	if rep then updateRepLabel(rep) end
	print("Client received:", reply)
	print("Offer found:", extractOffer(reply))
	if reply == nil then return end
	isWaiting = false

	for _, btn in pairs(activeOfferButtons) do
		btn.Active = false
		btn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
		btn.Text = "Expired"
	end
	activeOfferButtons = {}


	if reply:find("%[VENDOR_DONE%]") then
		local cleanedReply = reply:gsub("%[VENDOR_DONE%]", "")
		addMessage(cleanedReply, false, false, nil)
		chatInput.TextEditable = false
		sendBtn.Active = false
		chatInput.PlaceholderText = "Triple T refuses to deal with you..."
		return
	end

	sendBtn.Active = true
	local offerAmount = extractOffer(reply)
	local displayText = reply:gsub("%[OFFER:%d+%]", function(match)
		return "$" .. match:match("%d+")
	end)
	addMessage(displayText, false, offerAmount ~= nil, offerAmount)
end)


local vendorNPC = workspace:WaitForChild("World Components"):WaitForChild("Vendor Stand"):WaitForChild("Triple T")
local prompt = vendorNPC:WaitForChild("Torso"):WaitForChild("ProximityPrompt")

prompt.Triggered:Connect(function(triggeringPlayer)
	if triggeringPlayer ~= player then return end
	if isOpen then return end
	updateRepLabel(localRep)
	print("Prompt triggered, isOpen:", isOpen)
	print("Fish found:", getCurrentFish())
	local fish = getCurrentFish()
	if fish then
		currentFish = fish
	else
		currentFish = { species = "none", size = "none", value = 0 }
	end

	fishNameLabel.Text = currentFish.species ~= "none" and (currentFish.size .. " " .. currentFish.species) or "No fish equipped"
	marketValueLabel.Text = currentFish.value > 0 and ("Market value: $" .. currentFish.value) or ""
	frame.Visible = true
	isOpen = true
	if #chatScroll:GetChildren() <= 3 then
		isWaiting = true
		sendBtn.Active = false
		typingIndicator.Visible = true
		VendorRemote:FireServer("GREETING", currentFish.species, currentFish.size)
	end
end)

local closeBtn = frame:WaitForChild("X")
closeBtn.MouseButton1Click:Connect(function()
	frame.Visible = false
	isOpen = false
	isWaiting = false
	sendBtn.Active = true
	chatInput.TextEditable = true  
	chatInput.PlaceholderText = "Make your case..."
	chatInput.Active = true
	activeOfferButtons = {}
	for _, child in pairs(chatScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	VendorRemote:FireServer("CLEAR_HISTORY", "none", "none")
end)

frame.Visible = false