script.Parent.Triggered:Connect(function(player)
	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local destination = game.Workspace:WaitForChild("Underwater Portion"):WaitForChild("TeleportDestination")

	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero

	hrp.CFrame = destination.CFrame * CFrame.new(0, 4, 0)
end)