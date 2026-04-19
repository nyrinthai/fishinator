local btn = script.Parent

btn.Activated:Connect(function()
	btn.Parent.Parent.Enabled = not btn.Parent.Parent.Enabled
end)