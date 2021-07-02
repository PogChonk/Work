local starterGui = game:GetService("StarterGui")
local replicatedStorage = game:GetService("ReplicatedStorage")

local remotes = replicatedStorage:WaitForChild("Remotes")

remotes.Notify.OnClientEvent:Connect(function(msg)
	starterGui:SetCore("SendNotification", {
		Title = "Admin System",
		Text = msg,
		Duration = 5,
	})
end)

remotes.ShowCmds.OnClientEvent:Connect(function(cmdList, pref)
	for name, propList in pairs(cmdList) do
		local cmdTemp = script.CommandTemplate:Clone()
		cmdTemp.Name = name
		local aliases = #propList.Aliases > 0 and table.concat(propList.Aliases, ", ") or "None"
		cmdTemp.Text = string.format("%s%s\n\nDescription: %s\nUsage: %s\nAliases: %s\nPermission: %s\n\n", pref, name, propList.Description, propList.Usage, aliases, propList.Permission)
		cmdTemp.Parent = script.Cmds.Holder.List
	end
	
	script.Cmds.Holder:TweenPosition(UDim2.new(0.5,0,0.5,0), "Out", "Back", 1, true)
end)
