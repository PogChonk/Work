local config = require(script.Parent.Config)

local dataStore = config.DataStore

local https = game:GetService("HttpService")
local teleport = game:GetService("TeleportService")
local messaging = game:GetService("MessagingService")

local replicatedStorage = game:GetService("ReplicatedStorage")
local remotes = replicatedStorage:WaitForChild("Remotes")

local function getType(player)
	for rank,idlist in pairs(config.Ranks) do
		if idlist[player.UserId] and rank ~= "Banned" then
			return config.Permissions[rank]
		end
	end
	return 1
end

local function notify(player, msg)
	remotes.Notify:FireClient(player, msg)
end

local function getTime()
	local date = os.date("!*t")
	return string.format("%02d/%02d/%04d | %02d:%02d:%02d | UTC", date.month, date.day, date.year, date.hour, date.min, date.sec)
end

local function sendRequest(player, message)
	config.Cooldowns[player] = DateTime.now().UnixTimestampMillis
	
	local bot_username = config.Webhook.Username
	local webhook_url = config.Webhook.Url
	
	local embed = {
		{
			title = "Player Requests",
			description = "Player requesting moderation assistance",
			color = 1162222,
			fields = {
				{
					name = player.Name,
					value = "JobId: "..game.JobId,
					inline = false
				},
				{
					name = "Reason",
					value = message,
					inline = false
				}
			},
			footer = {
				text = "Requested at: "..getTime()
			}
		}
	}
	
	local toSend = {
		username = bot_username,
		embeds = embed
	}
	
	local success, response = pcall(function()
		https:RequestAsync({
			Url = webhook_url,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json"
			},
			Body = https:JSONEncode(toSend)
		})
	end)
	
	if success then
		notify(player, "Sent a request for moderators to get online!")
	else
		notify(player, "Error sending the request, please try again later!")
		warn(response.StatusMessage)
	end
end

local function getBans()
	local ids = {}
	
	local store = config.OrderedStore
	local list = store:GetSortedAsync(true, 16)
	
	for ind, page in pairs(list:GetCurrentPage()) do
		table.insert(ids, page.key)
	end
	
	while not list.IsFinished do
		list:AdvanceToNextPageAsync()
		for ind, page in pairs(list:GetCurrentPage()) do
			table.insert(ids, page.key)
		end
		wait(0.25)
	end
	
	return ids
end

local function getName(player, id)
	local success, response = pcall(function()
		return game:GetService("Players"):GetNameFromUserIdAsync(id)
	end)
	
	if success then return response end
	warn(response)
	notify(player, string.format("Error getting the name for UserId: %d!", id))
end

local cmds = {}

cmds.Commands = {
	["commands"] = {
		Execute = function(player, args)
			remotes.ShowCmds:FireClient(player, cmds.Commands, config.Prefix)
		end,
		Aliases = {
			"cmds"
		},
		Permission = "Anyone",
		Description = "Shows a list of all available commands.",
		Usage = config.Prefix.."commands"
	},
	["bans"] = {
		Execute = function(player, args)
			local names = {}
			
			for _,id in pairs(getBans()) do
				table.insert(names, getName(player, id))
			end
			
			print(#names > 0 and table.concat(names, ", ") or "None")
		end,
		Aliases = {
			
		},
		Permission = "Moderator",
		Description = "Shows a list of all current players banned.",
		Usage = config.Prefix.."bans"
	},
	["teleport"] = {
		Execute = function(player, args)
			if not args[1] then notify(player, string.format("No player specified!")) return end
			local targ = args[1]
			local targPlr = game:GetService("Players"):FindFirstChild(targ)

			if not targPlr then
				for _, plr in pairs(game:GetService("Players"):GetPlayers()) do
					if string.match(string.lower(plr.Name), string.lower(targ)) then
						targPlr = plr
						break
					end
				end
			end

			if not targPlr then notify(player, string.format("No player with the name of %s found!", targ)) return end
			
			if targPlr == player then notify(player, string.format("You cannot teleport yourself to yourself!")) return end
			
			local targChar = targPlr.Character

			if not targChar then notify(player, string.format("Player %s's character doesn't exist!", targPlr.Name)) return end

			local targHum = targChar:FindFirstChild("Humanoid")

			if not targHum or targHum.Health <= 0 then notify(player, string.format("Player %s's character is dead!", targPlr.Name)) return end

			local plrChar = player.Character

			if not plrChar then notify(player, string.format("Your character doesn't exist!")) return end

			local plrHum = plrChar:FindFirstChild("Humanoid")

			if not targHum or targHum.Health <= 0 then notify(player, string.format("You cannot teleport while your character is dead!")) return end

			local tH = targChar.HumanoidRootPart
			local pH = plrChar.HumanoidRootPart

			local pos = tH.Position + Vector3.new(0, 3, 0) + (tH.CFrame.LookVector * 3)
			local dir = Vector3.new(tH.Position.X, pH.Position.Y, tH.Position.Z)

			pH.CFrame = CFrame.lookAt(pos, dir)
		end,
		Aliases = {
			"goto",
			"to",
			"tp",
			"tele"
		},
		Permission = "Moderator",
		Description = "Teleport to a player in the server from their specified username.",
		Usage = config.Prefix.."teleport <PlayerName>"
	},
	["request"] = {
		Execute = function(player, args)
			if not args[1] then notify(player, "No reason specified!") return end
			
			if not config.Cooldowns[player] then
				sendRequest(player, table.concat(args, " "))
			elseif config.Cooldowns[player] and DateTime.now().UnixTimestampMillis - config.Cooldowns[player] < config.CooldownTime then
				local timeLeft = config.CooldownTime - (DateTime.now().UnixTimestampMillis - config.Cooldowns[player])
				local secs = math.floor((timeLeft / 1000) % 60)
				local mins = math.floor(((timeLeft / 1000) / 60) % 60)
				local form = string.format("You are on cooldown!\n%02d Minutes & %02d Seconds", mins, secs)
				notify(player, form)
			else
				sendRequest(player, table.concat(args, " "))
			end
		end,
		Aliases = {
			"req"
		},
		Permission = "Anyone",
		Description = "Notify an available moderators to join the server for a specified reason.",
		Usage = config.Prefix.."request <Reason>"
	},
	["join"] = {
		Execute = function(player, args)
			if not args[1] then notify(player, "You need to specify a valid JobId") return end

			teleport:TeleportToPlaceInstance(game.PlaceId, args[1], player)
		end,
		Aliases = {

		},
		Permission = "Moderator",
		Description = "Join a different server from the specified Job Id.",
		Usage = config.Prefix.."join <JobId>"
	},
	["kill"] = {
		Execute = function(player, args)
			if not args[1] then notify(player, string.format("No player specified")) return end
			local targ = args[1]
			local targPlr = game:GetService("Players"):FindFirstChild(targ)

			if not targPlr then
				for _, plr in pairs(game:GetService("Players"):GetPlayers()) do
					if string.match(string.lower(plr.Name), string.lower(targ)) then
						targPlr = plr
						break
					end
				end
			end

			if not targPlr then notify(player, string.format("No player with the name of %s found!", targ)) return end

			local character = targPlr.Character

			if not character then notify(player, string.format("Player %s's character doesn't exist!", targPlr.Name)) return end

			local humanoid = character:FindFirstChild("Humanoid")

			if not humanoid or humanoid.Health <= 0 then notify(player, string.format("Player %s's character is dead!", targPlr.Name)) return end

			humanoid.Health = -math.huge
		end,
		Aliases = {

		},
		Permission = "Moderator",
		Description = "Kill a specified player that will force them to respawn.",
		Usage = config.Prefix.."kill <PlayerName>"
	},
	["respawn"] = {
		Execute = function(player, args)
			if not args[1] then notify(player, string.format("No player specified!")) return end
			local targ = args[1]
			local targPlr = game:GetService("Players"):FindFirstChild(targ)

			if not targPlr then
				for _, plr in pairs(game:GetService("Players"):GetPlayers()) do
					if string.match(string.lower(plr.Name), string.lower(targ)) then
						targPlr = plr
						break
					end
				end
			end

			if not targPlr then notify(player, string.format("No player with the name of %s found!", targ)) return end

			targPlr:LoadCharacter()
		end,
		Aliases = {
			"re"
		},
		Permission = "Moderator",
		Description = "Forcefully respawn a player without killing them.",
		Usage = config.Prefix.."respawn <PlayerName>"
	},
	["kick"] = {
		Execute = function(player, args)
			if not args[1] then notify(player, string.format("No player specified!")) return end
			local targ = args[1]
			local targPlr = game:GetService("Players"):FindFirstChild(targ)

			if not targPlr then
				for _, plr in pairs(game:GetService("Players"):GetPlayers()) do
					if string.match(string.lower(plr.Name), string.lower(targ)) then
						targPlr = plr
						break
					end
				end
			end

			if not targPlr then notify(player, string.format("No player with the name of %s found!", targ)) return end

			if player == targPlr then notify(player, string.format("You cannot kick yourself!")) return end
			if getType(player) <= getType(targPlr) then notify(player, string.format("%s is a higher rank or is the same rank!", targPlr.Name)) return end

			table.remove(args, 1)
			local kickMsg = "\nReason: "..(table.concat(args, " ")).."\nBy: "..player.Name

			targPlr:Kick(kickMsg)

			notify(player, string.format("Successfully kicked %s from the server!", targPlr.Name))
		end,
		Aliases = {

		},
		Permission = "Moderator",
		Description = "Kicks a specified player from the current server with a specified reason.",
		Usage = config.Prefix.."kick <PlayerName> <Reason>"
	},
	["ban"] = {
		Execute = function(player, args)
			if not args[1] then notify(player, string.format("No player specified!")) return end
			local targ = args[1]
			local targPlr

			if game:GetService("Players"):FindFirstChild(targ) then
				targPlr = game:GetService("Players"):FindFirstChild(targ)						
			end

			if not targPlr then
				for _,plr in pairs(game:GetService("Players"):GetPlayers()) do
					if string.match(string.lower(plr.Name), string.lower(targ)) then
						targPlr = plr
						break
					end
				end
			end

			if not targPlr then
				local success, response = pcall(function()
					return game:GetService("Players"):GetUserIdFromNameAsync(targ)
				end)

				if success then
					targPlr = response
				else
					warn(response)
				end
			end

			if not targPlr then notify(player, string.format("No player with the name of %s found!", targ)) return end
			if targPlr == player then notify(player, string.format("You cannot ban yourself!")) return end

			table.remove(args, 1)
			local banMsg = "Banned!\nReason: "..(table.concat(args, " ")).."\nBy: "..player.Name
			
			local toSend = {
				BanMsg = banMsg,
				Player = player.Name,
				Target = targ,
				PlayerType = getType(player)
			}
			
			if type(targPlr) == "number" then
				messaging:PublishAsync("BanPlayer", https:JSONEncode(toSend))
				
				local banned = false
				local success, response = pcall(function()
					config.DataStore:UpdateAsync(targPlr, function(oldData)
						if oldData then
							local pt = getType(player)
							local tt

							if oldData["Super Administrator"] then
								tt = 4
							elseif oldData.Administrator then
								tt = 3
							elseif oldData.Moderator then
								tt = 2
							else
								tt = 1
							end

							if pt <= tt then notify(player, string.format("%s is a higher rank or is the same rank!", targ)) return nil end
						end

						if oldData and oldData.Banned then
							if oldData.Banned[1] then notify(player, string.format("%s is already banned for %s!", targ, string.sub(oldData.Banned[2], 8, #oldData.Banned[2]))) return nil end
							
							banned = true
							return {
								["Super Administrator"] = false,
								Administrator = false,
								Moderator = false,
								Banned = {true, banMsg}
							}
						end
						
						banned = true
						return {
							["Super Administrator"] = false,
							Administrator = false,
							Moderator = false,
							Banned = {true, banMsg}
						}
					end)
				end)

				if success and banned then
					config.OrderedStore:SetAsync(targPlr, 1)
					notify(player, string.format("Successfully banned %s!", targ))
				elseif not success then
					notify(player, string.format("Unsuccessful ban for %s!", targ))
					warn(response)
				end
			else
				if getType(player) <= getType(targPlr) then notify(player, string.format("%s is a higher rank or is the same rank!", targPlr.Name)) return end
				
				for _,idlist in pairs(config.Ranks) do
					if idlist[targPlr.UserId] then
						idlist[targPlr.UserId] = nil
					end
				end
				
				config.OrderedStore:SetAsync(targPlr.UserId, 1)				
				config.Ranks.Banned[targPlr.UserId] = {true, banMsg}
				targPlr:Kick(banMsg)
				notify(player, string.format("Successfully banned %s!", targPlr.Name))
			end
		end,
		Aliases = {

		},
		Permission = "Moderator",
		Description = "Permanently bans a player from joining the game. You can remotely ban a player or ban them in-game. You can also specify a reason for the ban.",
		Usage = config.Prefix.."ban <PlayerName> <Reason>"
	},
	["unban"] = {
		Execute = function(player, args)
			if not args[1] then notify(player, string.format("No player specified!")) return end
			local targ = args[1]
			local targPlr

			if game:GetService("Players"):FindFirstChild(targ) then
				targPlr = game:GetService("Players"):FindFirstChild(targ)						
			end

			if not targPlr then
				for _,plr in pairs(game:GetService("Players"):GetPlayers()) do
					if string.match(plr.Name, targ) then
						targPlr = plr
						break
					end
				end
			end

			if not targPlr then
				local success, response = pcall(function()
					return game:GetService("Players"):GetUserIdFromNameAsync(targ)
				end)

				if success then
					targPlr = response
				else
					warn(response)
				end
			end

			if not targPlr then notify(player, string.format("No player with the name of %s found!", targ)) return end
			
			if targPlr == player.UserId then notify(player, "You cannot attempt to unban yourself!") return end
			
			local did
			local success, response = pcall(function()
				config.DataStore:UpdateAsync(targPlr, function(oldData)
					if oldData and oldData.Banned then
						if not oldData.Banned[1] then notify(player, string.format("%s is already unbanned!", targ)) return end
						
						did = true
						return {
							["Super Administrator"] = false,
							Administrator = false,
							Moderator = false,
							Banned = {false, ""}
						}
					end
					
					did = true
					return {
						["Super Administrator"] = false,
						Administrator = false,
						Moderator = false,
						Banned = {false, ""}
					}
				end)
			end)
			
			if config.Ranks.Banned[targPlr] then
				config.Ranks.Banned[targPlr] = {false, ""}
			end

			if success and did then
				config.OrderedStore:RemoveAsync(targPlr)
				notify(player, string.format("Successfully unbanned %s!", targ))
			elseif not success then
				notify(player, string.format("Unsuccessful unban for %s!", targ))
				warn(response)
			end
		end,
		Aliases = {

		},
		Permission = "Moderator",
		Description = "Unbans a player remotely.",
		Usage = config.Prefix.."unban <PlayerName>"
	},
	["mod"] = {
		Execute = function(player, args)
			if not args[1] then notify(player, string.format("No player specified!")) return end
			local targ = args[1]
			local targPlr

			if game:GetService("Players"):FindFirstChild(targ) then
				targPlr = game:GetService("Players"):FindFirstChild(targ)						
			end

			if not targPlr then
				for _,plr in pairs(game:GetService("Players"):GetPlayers()) do
					if string.match(string.lower(plr.Name), string.lower(targ)) then
						targPlr = plr
						break
					end
				end
			end

			if not targPlr then
				local success, response = pcall(function()
					return game:GetService("Players"):GetUserIdFromNameAsync(targ)
				end)

				if success then
					targPlr = response
				else
					warn(response)
				end
			end

			if not targPlr then notify(player, string.format("No player with the name of %s found!", targ)) return end
			if targPlr == player then notify(player, string.format("You cannot give yourself Moderator permissions!")) return end

			if type(targPlr) == "number" then
				local did = false
				local success, response = pcall(function()
					config.DataStore:UpdateAsync(targPlr, function(oldData)
						if oldData then
							local pt = getType(player)
							local tt

							if oldData["Super Administrator"] then
								tt = 4
							elseif oldData.Administrator then
								tt = 3
							elseif oldData.Moderator then
								tt = 2
							else
								tt = 1
							end

							if pt <= tt then notify(player, string.format("%s is a higher rank or is the same rank!", targ)) return nil end
							if tt >= config.Permissions.Moderator then notify(player, string.format("%s is already a Moderator or higher!", targ)) return nil end

							did = true
							return {
								["Super Administrator"] = false,
								Administrator = false,
								Moderator = true,
								Banned = oldData.Banned or {false, ""}
							}
						end

						did = true
						return {
							["Super Administrator"] = false,
							Administrator = false,
							Moderator = true,
							Banned = {false, ""}
						}
					end)
				end)

				if success and did then
					notify(player, string.format("Successfully gave %s Moderator permissions!", targ))
				elseif not success then
					notify(player, string.format("Unsuccessful! Didn't give %s Moderator permissions!", targ))
					warn(response)
				end
			else
				if getType(player) <= getType(targPlr) then notify(player, string.format("%s is a higher rank than you!", targPlr.Name)) return end
				if getType(targPlr) >= config.Permissions.Moderator then notify(player, string.format("%s is already a Moderator or higher!", targPlr.Name)) return end				

				config.Ranks.Moderator[targPlr.UserId] = true

				notify(player, string.format("Successfully gave %s Moderator permissions!", targPlr.Name))
				notify(targPlr, string.format("You have been given Moderator permissions from %s!", player.Name))
			end
		end,
		Aliases = {

		},
		Permission = "Administrator",
		Description = "Gives a player Moderator permissions in-game or remotely.",
		Usage = config.Prefix.."mod <PlayerName>"
	},
	["unmod"] = {
		Execute = function(player, args)
			if not args[1] then notify(player, string.format("No player specified!")) return end
			local targ = args[1]
			local targPlr

			if game:GetService("Players"):FindFirstChild(targ) then
				targPlr = game:GetService("Players"):FindFirstChild(targ)						
			end

			if not targPlr then
				for _,plr in pairs(game:GetService("Players"):GetPlayers()) do
					if string.match(string.lower(plr.Name), string.lower(targ)) then
						targPlr = plr
						break
					end
				end
			end

			if not targPlr then
				local success, response = pcall(function()
					return game:GetService("Players"):GetUserIdFromNameAsync(targ)
				end)

				if success then
					targPlr = response
				else
					warn(response)
				end
			end

			if not targPlr then notify(player, string.format("No player with the name of %s found!", targ)) return end
			if targPlr == player then notify(player, string.format("You cannot remove your own Moderator permissions!")) return end

			if type(targPlr) == "number" then
				local did = false
				local success, response = pcall(function()
					config.DataStore:UpdateAsync(targPlr, function(oldData)
						local newData

						if oldData then
							local pt = getType(player)
							local tt

							if oldData["Super Administrator"] then
								tt = 4
							elseif oldData.Administrator then
								tt = 3
							elseif oldData.Moderator then
								tt = 2
							else
								tt = 1
							end

							if not oldData.Moderator then notify(player, string.format("%s is already not a Moderator!", targ)) return nil end
							if pt <= tt then notify(player, string.format("%s is a higher rank or is the same rank!", targ)) return nil end

							did = true
							return {
								["Super Administrator"] = false,
								Administrator = false,
								Moderator = false,
								Banned = oldData.Banned or {false, ""}
							}
						end

						did = true
						return {
							["Super Administrator"] = false,
							Administrator = false,
							Moderator = false,
							Banned = {false, ""}
						}
					end)
				end)

				if config.Ranks.Moderator[targPlr] then
					config.Ranks.Moderator[targPlr] = nil
				end

				if success and did then
					notify(player, string.format("Successfully revoked %s's Moderator permissions!", targ))
				elseif not success then
					notify(player, string.format("Unsuccessful! Didn't revoke %s's Moderator permissions!", targ))
					warn(response)
				end
			else
				if getType(player) <= getType(targPlr) then notify(player, string.format("%s is a higher rank or is the same rank!", targPlr.Name)) return end
				if not config.Ranks.Moderator[targPlr.UserId] then notify(player, string.format("%s is already not a Moderator!", targPlr.Name)) return end

				config.Ranks.Moderator[targPlr.UserId] = false
				
				notify(player, string.format("Successfully revoked %s's Moderator permissions!", targPlr.Name))
				notify(targPlr, string.format("Your Moderator permissions have been revoked by %s!", player.Name))
			end
		end,
		Aliases = {

		},
		Permission = "Administrator",
		Description = "Revokes a players Moderator permissions in-game or remotely.",
		Usage = config.Prefix.."unmod <PlayerName>"
	},
	["admin"] = {
		Execute = function(player, args)
			if not args[1] then notify(player, string.format("No player specified!")) return end
			local targ = args[1]
			local targPlr

			if game:GetService("Players"):FindFirstChild(targ) then
				targPlr = game:GetService("Players"):FindFirstChild(targ)						
			end

			if not targPlr then
				for _,plr in pairs(game:GetService("Players"):GetPlayers()) do
					if string.match(string.lower(plr.Name), string.lower(targ)) then
						targPlr = plr
						break
					end
				end
			end

			if not targPlr then
				local success, response = pcall(function()
					return game:GetService("Players"):GetUserIdFromNameAsync(targ)
				end)

				if success then
					targPlr = response
				else
					warn(response)
				end
			end

			if not targPlr then notify(player, string.format("No player with the name of %s found!", targ)) return end
			if targPlr == player then notify(player, string.format("You cannot give yourself Administrator permissions!")) return end

			if type(targPlr) == "number" then
				local did = false
				local success, response = pcall(function()
					config.DataStore:UpdateAsync(targPlr, function(oldData)
						if oldData then
							local pt = getType(player)
							local tt

							if oldData["Super Administrator"] then
								tt = 4
							elseif oldData.Administrator then
								tt = 3
							elseif oldData.Moderator then
								tt = 2
							else
								tt = 1
							end

							if pt <= tt then notify(player, string.format("%s is a higher rank or is the same rank!", targ)) return nil end
							if tt >= config.Permissions.Administrator then notify(player, string.format("%s is already an Administrator or higher!", targ)) return nil end
							
							did = true
							return {
								["Super Administrator"] = false,
								Administrator = true,
								Moderator = false,
								Banned = oldData.Banned or {false, ""}
							}
						end

						did = true
						return {
							["Super Administrator"] = false,
							Administrator = true,
							Moderator = false,
							Banned = {false, ""}
						}
					end)
				end)

				if success and did then
					notify(player, string.format("Successfully gave %s Administrator permissions!", targ))
				elseif not success then
					notify(player, string.format("Unsuccessful! Didn't give %s Administrator permissions!", targ))
					warn(response)
				end
			else
				if getType(player) <= getType(targPlr) then notify(player, string.format("%s is a higher rank than you!", targPlr.Name)) return end
				if getType(targPlr) >= config.Permissions.Administrator then notify(player, string.format("%s is already an Administrator or higher!", targPlr.Name)) return end				
				
				config.Ranks.Administrator[targPlr.UserId] = true
				
				if config.Ranks.Moderator[targPlr.UserId] then
					config.Ranks.Moderator[targPlr.UserId] = nil
				end
				
				notify(player, string.format("Successfully gave %s Administrator permissions!", targPlr.Name))
				notify(targPlr, string.format("You have been given Administrator permissions from %s!", player.Name))
			end
		end,
		Aliases = {

		},
		Permission = "Super Administrator",
		Description = "Gives a player Administrator permissions in-game or remotely.",
		Usage = config.Prefix.."admin <PlayerName>"
	},
	["unadmin"] = {
		Execute = function(player, args)
			if not args[1] then notify(player, string.format("No player specified!")) return end
			local targ = args[1]
			local targPlr

			if game:GetService("Players"):FindFirstChild(targ) then
				targPlr = game:GetService("Players"):FindFirstChild(targ)						
			end

			if not targPlr then
				for _,plr in pairs(game:GetService("Players"):GetPlayers()) do
					if string.match(string.lower(plr.Name), string.lower(targ)) then
						targPlr = plr
						break
					end
				end
			end

			if not targPlr then
				local success, response = pcall(function()
					return game:GetService("Players"):GetUserIdFromNameAsync(targ)
				end)

				if success then
					targPlr = response
				else
					warn(response)
				end
			end

			if not targPlr then notify(player, string.format("No player with the name of %s found!", targ)) return end
			if targPlr == player then notify(player, string.format("You cannot remove your own Administrator permissions!")) return end

			if type(targPlr) == "number" then
				local did = false
				local success, response = pcall(function()
					config.DataStore:UpdateAsync(targPlr, function(oldData)
						local newData
						
						if oldData then
							local pt = getType(player)
							local tt

							if oldData["Super Administrator"] then
								tt = 4
							elseif oldData.Administrator then
								tt = 3
							elseif oldData.Moderator then
								tt = 2
							else
								tt = 1
							end
							
							if not oldData.Administrator then notify(player, string.format("%s is already not an Administrator!", targ)) return nil end
							if pt <= tt then notify(player, string.format("%s is a higher rank or is the same rank!", targ)) return nil end
							
							did = true
							return {
								["Super Administrator"] = false,
								Administrator = false,
								Moderator = false,
								Banned = oldData.Banned or {false, ""}
							}
						end
						
						did = true
						return {
							["Super Administrator"] = false,
							Administrator = false,
							Moderator = false,
							Banned = {false, ""}
						}
					end)
				end)

				if config.Ranks.Administrator[targPlr] then
					config.Ranks.Administrator[targPlr] = nil
				end

				if success and did then
					notify(player, string.format("Successfully revoked %s's Administrator permissions!", targ))
				elseif not success then
					notify(player, string.format("Unsuccessful! Didn't revoke %s's Administrator permissions!", targ))
					warn(response)
				end
			else
				if getType(player) <= getType(targPlr) then notify(player, string.format("%s is a higher rank or is the same rank!", targPlr.Name)) return end
				if not config.Ranks.Administrator[targPlr.UserId] then notify(player, string.format("%s is already not an Administrator!", targPlr.Name)) return end
				
				config.Ranks.Administrator[targPlr.UserId] = false
				
				notify(player, string.format("Successfully revoked %s's Administrator permissions!", targPlr.Name))
				notify(targPlr, string.format("Your Administrator permissions have been revoked by %s!", player.Name))
			end
		end,
		Aliases = {

		},
		Permission = "Super Administrator",
		Description = "Revokes a players Administrator permissions in-game or remotely.",
		Usage = config.Prefix.."unadmin <PlayerName>"
	}
}

messaging:SubscribeAsync("BanPlayer", function(msg)
	local newMsg = https:JSONDecode(msg.Data)
	local targ = newMsg.Target
	local banner = newMsg.Player
	local banMsg = newMsg.BanMsg
	local targPlr
	
	for _,plr in pairs(game:GetService("Players"):GetPlayers()) do
		if string.match(plr.Name, targ) then
			targPlr = plr
			break
		end
	end
	
	if not targPlr then return end

	if newMsg.PlayerType <= getType(targPlr) then return end

	for _,idlist in pairs(config.Ranks) do
		if idlist[targPlr.UserId] then
			idlist[targPlr.UserId] = nil
		end
	end

	config.OrderedStore:SetAsync(targPlr.UserId, 1)				
	config.Ranks.Banned[targPlr.UserId] = {true, banMsg}
	targPlr:Kick(banMsg)
end)

return cmds.Commands
