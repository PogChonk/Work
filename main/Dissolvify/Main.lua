local dissolvify = require(game:GetService("ReplicatedStorage").Dissolvify)

game:GetService("Players").PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(msg)
		if msg:lower() == "dissolve" then
			if player.Character then
				dissolvify.dissolve(player.Character)
			end
		end
	end)
end)
