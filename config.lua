Config = {}
Config.Locale = 'en'

Config.Accounts = {
	bank = _U('account_bank'),
	black_money = _U('account_black_money'),
	money = _U('account_money')
}

Config.StartingAccountMoney = {money = 10000,bank = 10000, black_money = 0}	---เงินเริ่มต้น
Config.AutoRemove 			= 500	--ตั้งเวลาลบไอเท็มที่ทิ้งแล้ว 20 วินาที
Config.EnableSocietyPayouts = false -- pay from the society account that the player is employed at? Requirement: esx_society
Config.EnableHud            = false -- enable the default hud? Display current job and accounts (black, bank & cash)
Config.PaycheckInterval     = 30 * 60000 -- how often to recieve pay checks in milliseconds
Config.EnableDebug          = false
Config.adminRanks = { -- change this as your server ranking ( default are : superadmin | admin | moderator )
	'superadmin'
}

Config.Spawnpoint = {}