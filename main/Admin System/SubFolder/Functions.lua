local funcs = {}

local serverLogs = {}

local config = require(script.Parent.Config)
local cmds = require(script.Parent.Commands)

function funcs.IsCommand(cmd)
	if cmds[cmd] then return cmds[cmd] end
	
	for _,cmdList in pairs(cmds) do
		if table.find(cmdList.Aliases, cmd) then
			return cmdList
		end
	end
	
	return nil
end

function funcs.AddLog(player, args)
	if not serverLogs[player.Name] then
		serverLogs[player.Name] = {}
	end
	
	local command = args[1] or "No command"
	local target = args[2] or "No target"
	local extraArgs = table.concat(args, " ", 3) or "No extra arguments"
	
	local format = string.format("Player: %s | Command: %s | Target: %s | Extra: %s", player.Name, command, target, extraArgs)
	
	table.insert(serverLogs[player.Name], format)
end

function funcs.CanExecute(player, command)
	local req = command.Permission
	local con = config.Ranks
	
	if req == "Super Administrator" then
		if con["Super Administrator"][player.UserId] then
			return true
		end
		return false
	elseif req == "Administrator" then
		if con["Super Administrator"][player.UserId] or con.Administrator[player.UserId] then
			return true
		end
		return false
	elseif req == "Moderator" then
		if con["Super Administrator"][player.UserId] or con.Administrator[player.UserId] or con.Moderator[player.UserId] then
			return true
		end
		return false
	end
end

return funcs
