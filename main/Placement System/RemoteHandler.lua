local replicatedStorage = game:GetService("ReplicatedStorage")
local remotes = replicatedStorage:WaitForChild("Remotes")
local furn = replicatedStorage:WaitForChild("Furniture")

remotes.PlaceItem.OnServerEvent:Connect(function(player, name, cf, tn)
	local toPlace = furn:FindFirstChild(name):Clone()
	local hb = toPlace:WaitForChild("Hitbox")
	local owner = hb.Owner
	owner.Value = player.Name
	toPlace.Parent = workspace
	toPlace:SetPrimaryPartCFrame(cf)
	local tile = hb.Tile
	tile.Value = tn
end)

remotes.GetOwner.OnServerInvoke = function(player, hitbox)
	if hitbox:FindFirstChild("Owner") then
		if hitbox.Owner.Value == player.Name then
			return true
		else
			return false
		end
	end
end

remotes.PickupItem.OnServerEvent:Connect(function(player, item)
	item:Destroy()
end)
