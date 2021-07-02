local config = {}

config.DataStore = game:GetService("DataStoreService"):GetDataStore("AdminData")
config.OrderedStore = game:GetService("DataStoreService"):GetOrderedDataStore("A")

config.Prefix = "?"

config.Ranks = {
	["Super Administrator"] = {
		
	},
	Administrator = {
		
	},
	Moderator = {
		
	},
	Banned = {
		
	}
}

config.Permissions = {
	["Super Administrator"] = 4,
	Administrator = 3,
	Moderator = 2
}

config.Webhook = {
	Url = "Some discord webhook",
	Username = "Player Moderation"
}

config.CooldownTime = 300000 --// Milliseconds

config.Cooldowns = {
	
}

return config
