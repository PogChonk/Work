local players = game:GetService("Players")

local main = require(script.AdminSystem.Main)
local prefix = main.Config.Prefix

local dataStore = main.Config.DataStore

local replicatedStorage = game:GetService("ReplicatedStorage")
local remotes = replicatedStorage:WaitForChild("Remotes")

players.PlayerAdded:Connect(function(player)	
	if main.Config.Ranks.Banned[player.UserId] and main.Config.Ranks.Banned[player.UserId][1] then player:Kick(main.Config.Ranks.Banned[player.UserId][2]) end
	
	if game.CreatorType == Enum.CreatorType.User and game.CreatorId == player.UserId then
		main.Config.Ranks["Super Administrator"][player.UserId] = true
	end
	
	main.Config.Cooldowns[player] = DateTime.now().UnixTimestampMillis
	
	local count = 0
	local max = 5
	
	local success, response
	
	repeat wait(1)
		success, response = pcall(function()
			return dataStore:GetAsync(player.UserId)
		end)
		count += 1
	until success or count >= max
	
	if success then
		if response then
			for rank, value in pairs(response) do
				if value then
					main.Config.Ranks[rank][player.UserId] = value
				end
			end
			
			if response.Banned and response.Banned[1] then
				player:Kick(response.Banned[2])
			end
		end
	else
		warn(response)
	end
	
	for rank,idlist in pairs(main.Config.Ranks) do
		if idlist[player.UserId] and rank ~= "Banned" then
			remotes.Notify:FireClient(player, "You are a(n) "..rank)
		end
	end
	
	player.Chatted:Connect(function(msg)
		if string.sub(msg, 1, #prefix) == prefix then
			local args = string.split(msg, " ")
			local command = string.sub(string.lower(args[1]), #prefix + 1, #args[1])
			local cmd = main.Functions.IsCommand(command)
			if cmd then
				if cmd.Permission == "Anyone" then
					main.Functions.AddLog(player, args)
					table.remove(args, 1)
					cmd.Execute(player, args)
				else
					if main.Functions.CanExecute(player, cmd) then
						main.Functions.AddLog(player, args)
						table.remove(args, 1)
						cmd.Execute(player, args)
					else
						remotes.Notify:FireClient(player, "You are not a high enough rank to execute this command!")
					end
				end
			end
		end
	end)
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
	local toSave = {}
	
	for rank, idlist in pairs(main.Config.Ranks) do
		if idlist[player.UserId] then
			toSave[rank] = idlist[player.UserId]
		end
	end
	
	local valid, returned = pcall(function()
		dataStore:SetAsync(player.UserId, toSave)
	end)
	
	if not valid then warn(returned) end
end)

game:BindToClose(function()
	for _,player in pairs(game:GetService("Players"):GetPlayers()) do
		coroutine.wrap(function()
			local toSave = {}

			for rank, idlist in pairs(main.Config.Ranks) do
				if idlist[player.UserId] then
					toSave[rank] = idlist[player.UserId]
				end
			end

			local valid, returned = pcall(function()
				dataStore:SetAsync(player.UserId, toSave)
			end)

			if not valid then warn(returned) end
		end)()
	end
	wait(30)
end)
