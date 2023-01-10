local onTimer       = {}
local savedCoords   = {}
local warnedPlayers = {}
local deadPlayers   = {}

ESX.RegisterCommand('tp', 'superadmin', function(xPlayer, args, showError)
	xPlayer.setCoords({x = args.x, y = args.y, z = args.z})
end, false, {help = _U('command_setcoords'), validate = true, arguments = {
	{name = 'x', help = _U('command_setcoords_x'), type = 'number'},
	{name = 'y', help = _U('command_setcoords_y'), type = 'number'},
	{name = 'z', help = _U('command_setcoords_z'), type = 'number'}
}})

ESX.RegisterCommand('setjob', 'superadmin', function(xPlayer, args, showError)
	if ESX.DoesJobExist(args.job, args.grade) then
		args.playerId.setJob(args.job, args.grade)
	else
		showError(_U('command_setjob_invalid'))
	end
end, true, {help = _U('command_setjob'), validate = true, arguments = {
	{name = 'playerId', help = _U('commandgeneric_playerid'), type = 'player'},
	{name = 'job', help = _U('command_setjob_job'), type = 'string'},
	{name = 'grade', help = _U('command_setjob_grade'), type = 'number'}
}})

ESX.RegisterCommand('car', 'superadmin', function(xPlayer, args, showError)
	xPlayer.triggerEvent('esx:spawnVehicle', args.car)
end, false, {help = _U('command_car'), validate = false, arguments = {
	{name = 'car', help = _U('command_car_car'), type = 'any'}
}})

ESX.RegisterCommand('addcar', 'superadmin', function(xPlayer, args, showError)
    args.playerId.triggerEvent('addvehicle', args.vehicle)
end, true, {help = 'เสกรถให้ผู้เล่นเป็นเจ้าของ', validate = true, arguments = {
    {name = 'playerId', help = 'ใส่ ID', type = 'player'},
    {name = 'vehicle', help = 'ใส่ชื่อ Model รถ', type = 'any'},
}})

ESX.RegisterCommand({'cardel', 'dv'}, 'admin', function(xPlayer, args, showError)
	xPlayer.triggerEvent('esx:deleteVehicle', args.radius)
end, false, {help = _U('command_cardel'), validate = false, arguments = {
	{name = 'radius', help = _U('command_cardel_radius'), type = 'any'}
}})

ESX.RegisterCommand('setaccountmoney', 'superadmin', function(xPlayer, args, showError)
	if args.playerId.getAccount(args.account) then
		args.playerId.setAccountMoney(args.account, args.amount)
	else
		showError(_U('command_giveaccountmoney_invalid'))
	end
end, true, {help = _U('command_setaccountmoney'), validate = true, arguments = {
	{name = 'playerId', help = _U('commandgeneric_playerid'), type = 'player'},
	{name = 'account', help = _U('command_giveaccountmoney_account'), type = 'string'},
	{name = 'amount', help = _U('command_setaccountmoney_amount'), type = 'number'}
}})

ESX.RegisterCommand('giveaccountmoney', 'superadmin', function(xPlayer, args, showError)
	if args.playerId.getAccount(args.account) then
		args.playerId.addAccountMoney(args.account, args.amount)
	else
		showError(_U('command_giveaccountmoney_invalid'))
	end
end, true, {help = _U('command_giveaccountmoney'), validate = true, arguments = {
	{name = 'playerId', help = _U('commandgeneric_playerid'), type = 'player'},
	{name = 'account', help = _U('command_giveaccountmoney_account'), type = 'string'},
	{name = 'amount', help = _U('command_giveaccountmoney_amount'), type = 'number'}
}})

ESX.RegisterCommand('giveitem', 'superadmin', function(xPlayer, args, showError)
	if args.count == nil then
		args.playerId.addInventoryItem(args.item, 1)
	else
		args.playerId.addInventoryItem(args.item, args.count)
	end
end, true, {help = _U('command_giveitem'), validate = true, arguments = {
	{name = 'playerId', help = _U('commandgeneric_playerid'), type = 'player'},
	{name = 'item', help = _U('command_giveitem_item'), type = 'item'},
	{name = 'count', help = _U('command_giveitem_count'), type = 'number'}
}})

ESX.RegisterCommand('givemoney', 'superadmin', function(xPlayer, args, showError)
	args.playerId.addMoney(args.count)
end, true, {help = '', validate = true, arguments = {
	{name = 'playerId', help = 'ไอดี', type = 'player'},
	{name = 'count', help = 'จำนวนเงิน', type = 'number'}
}})

ESX.RegisterCommand('giveweapon', 'superadmin', function(xPlayer, args, showError)
	if args.playerId.hasWeapon(args.weapon) then
		showError(_U('command_giveweapon_hasalready'))
	else
		args.playerId.addWeapon(args.weapon, args.ammo)
	end
end, true, {help = _U('command_giveweapon'), validate = true, arguments = {
	{name = 'playerId', help = _U('commandgeneric_playerid'), type = 'player'},
	{name = 'weapon', help = _U('command_giveweapon_weapon'), type = 'weapon'},
	{name = 'ammo', help = _U('command_giveweapon_ammo'), type = 'number'}
}})



------------------------------------------------------------

ESX.RegisterCommand({'clear', 'cls'}, 'user', function(xPlayer, args, showError)
	xPlayer.triggerEvent('chat:clear')
end, false, {help = _U('command_clear')})

ESX.RegisterCommand({'clearall', 'clsall'}, 'superadmin', function(xPlayer, args, showError)
	TriggerClientEvent('chat:clear', -1)
end, false, {help = _U('command_clearall')})

ESX.RegisterCommand('clearinventory', 'superadmin', function(xPlayer, args, showError)
	for k,v in ipairs(args.playerId.inventory) do
		if v.count > 0 then
			args.playerId.setInventoryItem(v.name, 0)
		end
	end
end, true, {help = _U('command_clearinventory'), validate = true, arguments = {
	{name = 'playerId', help = _U('commandgeneric_playerid'), type = 'player'}
}})

ESX.RegisterCommand('clearloadout', 'superadmin', function(xPlayer, args, showError)
	for k,v in ipairs(args.playerId.loadout) do
		args.playerId.removeWeapon(v.name)
	end
end, true, {help = _U('command_clearloadout'), validate = true, arguments = {
	{name = 'playerId', help = _U('commandgeneric_playerid'), type = 'player'}
}})

ESX.RegisterCommand('setgroup', 'superadmin', function(xPlayer, args, showError)
	args.playerId.setGroup(args.group)
end, true, {help = _U('command_setgroup'), validate = true, arguments = {
	{name = 'playerId', help = _U('commandgeneric_playerid'), type = 'player'},
	{name = 'group', help = _U('command_setgroup_group'), type = 'string'},
}})

ESX.RegisterCommand('save', 'superadmin', function(xPlayer, args, showError)
	ESX.SavePlayer(args.playerId)
end, true, {help = _U('command_save'), validate = true, arguments = {
	{name = 'playerId', help = _U('commandgeneric_playerid'), type = 'player'}
}})

ESX.RegisterCommand('saveall', 'superadmin', function(xPlayer, args, showError)
	ESX.SavePlayers()
end, true, {help = _U('command_saveall')})

-- ESX.RegisterCommand('spawnped', 'superadmin', function(xPlayer, args, showError)
-- 	xPlayer.triggerEvent('esx:spawnPed', args.ped)
-- end, false, {help = ''), validate = false, arguments = {
-- 	{name = 'ped', help = '', type = 'any'}
-- }})

-- ESX.RegisterCommand('spawnobj', 'superadmin', function(xPlayer, args, showError)
-- 	xPlayer.triggerEvent('esx:spawnobject', args.obj)
-- end, false, {help = ''), validate = false, arguments = {
-- 	{name = 'ped', help = '', type = 'any'}
-- }})

-- ESX.RegisterCommand('coord', 'superadmin', function(xPlayer, args, showError)
-- 	xPlayer.triggerEvent('')
-- end, false, {help = ''})

-- ESX.RegisterCommand('tpm', 'superadmin', function(xPlayer, args, showError)
-- 	xPlayer.triggerEvent('esx:tpm')
-- end, false, {help = ''})

-- RegisterCommand("bring", function(source, args, rawCommand)	-- /bring [ID]
-- 	if source ~= 0 then
-- 	  	local xPlayer = ESX.GetPlayerFromId(source)
-- 	  	if havePermission(xPlayer) then
-- 	    	if args[1] and tonumber(args[1]) then
-- 	      		local targetId = tonumber(args[1])
-- 	      		local xTarget = ESX.GetPlayerFromId(targetId)
-- 	      		if xTarget then
-- 	        		local targetCoords = xTarget.getCoords()
-- 	        		local playerCoords = xPlayer.getCoords()
-- 	        		savedCoords[targetId] = targetCoords
-- 	        		xTarget.setCoords(playerCoords)
-- 	        		xPlayer.triggerEvent("chatMessage", _U('bring_adminside', args[1]))
-- 	        		-- xTarget.triggerEvent("chatMessage", _U('bring_playerside'))
-- 	      		else
-- 	        		xPlayer.triggerEvent("chatMessage", _U('not_online', 'BRING'))
-- 	      		end
-- 	    	else
-- 	      		xPlayer.triggerEvent("chatMessage", _U('invalid_input', 'BRING'))
-- 	    	end
-- 	  	end
-- 	end
-- end, false)

---------- goto/goback ----------
-- RegisterCommand("goto", function(source, args, rawCommand)	-- /goto [ID]
-- 	if source ~= 0 then
--   		local xPlayer = ESX.GetPlayerFromId(source)
--   		if havePermission(xPlayer) then
--     		if args[1] and tonumber(args[1]) then
--       			local targetId = tonumber(args[1])
--       			local xTarget = ESX.GetPlayerFromId(targetId)
--       			if xTarget then
--         			local targetCoords = xTarget.getCoords()
--         			local playerCoords = xPlayer.getCoords()
--         			savedCoords[source] = playerCoords
--         			xPlayer.setCoords(targetCoords)
--         			xPlayer.triggerEvent("chatMessage", _U('goto_admin', args[1]))
-- 					-- xTarget.triggerEvent("chatMessage",  _U('goto_player'))
--       			else
--         			xPlayer.triggerEvent("chatMessage", _U('not_online', 'GOTO'))
--       			end
--     		else
--       			xPlayer.triggerEvent("chatMessage", _U('invalid_input', 'GOTO'))
--     		end
--   		end
-- 	end
-- end, false)


-- RegisterCommand("goback", function(source, args, rawCommand)	-- /goback will teleport you back where you was befor /goto
-- 	if source ~= 0 then
-- 	  	local xPlayer = ESX.GetPlayerFromId(source)
-- 	  	if havePermission(xPlayer) then
-- 	    	local playerCoords = savedCoords[source]
-- 	    	if playerCoords then
-- 	      		xPlayer.setCoords(playerCoords)
-- 				xPlayer.triggerEvent("chatMessage", _U('goback'))
-- 	      		savedCoords[source] = nil
-- 	    	else
-- 	      		xPlayer.triggerEvent("chatMessage", _U('goback_error'))
-- 	    	end
-- 	  	end
-- 	end
-- end, false)

-- RegisterCommand("die", function(source)
-- 	local xPlayer = ESX.GetPlayerFromId(source)
-- 		TriggerClientEvent('es_adminplus:kill', source)
-- 		xPlayer.triggerEvent('chatMessage', "ฆ่าตัวตาย")
-- end, false)


-- RegisterCommand("reviveall", function(source, args, rawCommand)	-- reviveall (can be used from console)
-- 	canRevive = false
-- 	if source == 0 then
-- 		canRevive = true
-- 	else
-- 		local xPlayer = ESX.GetPlayerFromId(source)
-- 		if havePermission(xPlayer) then
-- 			canRevive = true
-- 		end
-- 	end
-- 	if canRevive then
-- 		for i,data in pairs(deadPlayers) do
-- 			TriggerClientEvent('esx_ambulancejob:revive', i)
-- 		end
-- 	end
-- end, false)

---------- freeze/unfreeze ---------
-- RegisterCommand("freeze", function(source, args, rawCommand)	-- /freeze [ID]
-- 	if source ~= 0 then
--   		local xPlayer = ESX.GetPlayerFromId(source)
--   		if havePermission(xPlayer) then
--     		if args[1] and tonumber(args[1]) then
--       			local targetId = tonumber(args[1])
--       			local xTarget = ESX.GetPlayerFromId(targetId)
--       			if xTarget then
--         			xTarget.triggerEvent("esx_admin:freezePlayer", 'freeze')
-- 					xPlayer.triggerEvent("chatMessage", _U('freeze_admin', args[1]))
-- 					-- xTarget.triggerEvent("chatMessage", _U('freeze_player'))
--       			else
--         			xPlayer.triggerEvent("chatMessage", _U('not_online', 'FREEZE'))
--       			end
--     		else
-- 		      	xPlayer.triggerEvent("chatMessage", _U('invalid_input', 'FREEZE'))
--     		end
--   		end
-- 	end
-- end, false)

-- RegisterCommand("unfreeze", function(source, args, rawCommand)	-- /unfreeze [ID]
-- 	if source ~= 0 then
--   		local xPlayer = ESX.GetPlayerFromId(source)
--   		if havePermission(xPlayer) then
--     		if args[1] and tonumber(args[1]) then
--       			local targetId = tonumber(args[1])
--       			local xTarget = ESX.GetPlayerFromId(targetId)
--       			if xTarget then
--         			xTarget.triggerEvent("esx_admin:freezePlayer", 'unfreeze')
-- 					xPlayer.triggerEvent("chatMessage", _U('unfreeze_admin', args[1]))
-- 					-- xTarget.triggerEvent("chatMessage", _U('unfreeze_player'))
--       			else
--         			xPlayer.triggerEvent("chatMessage", _U('not_online', 'UNFREEZE'))
--       			end
--     		else
--       			xPlayer.triggerEvent("chatMessage", _U('invalid_input', 'UNFREEZE'))
--     		end
--   		end
-- 	end
-- end, false)

-- ---------- kill ----------
-- RegisterCommand("kill", function(source, args, rawCommand)	-- /kill [ID]
-- 	if source ~= 0 then
-- 		local xPlayer = ESX.GetPlayerFromId(source)
-- 		if havePermission(xPlayer) then
-- 			if args[1] and tonumber(args[1]) then
-- 				local targetId = tonumber(args[1])
--       			local xTarget = ESX.GetPlayerFromId(targetId)
--       			if xTarget then
-- 					xTarget.triggerEvent("esx_admin:killPlayer")
--         			xPlayer.triggerEvent("chatMessage", _U('kill_admin', targetId))
-- 					-- xTarget.triggerEvent('chatMessage', _U('kill_by_admin'))
--       			else
--         			xPlayer.triggerEvent("chatMessage", _U('not_online', 'KILL'))
--       			end
--     		else
--       			xPlayer.triggerEvent("chatMessage", _U('invalid_input', 'KILL'))
--     		end
--   		end
-- 	end
-- end, false)

---------- Noclip --------
-- RegisterCommand("noclip", function(source, args, rawCommand)	-- /goback will teleport you back where you was befor /goto
-- 	if source ~= 0 then
-- 	  	local xPlayer = ESX.GetPlayerFromId(source)
-- 	  	if havePermission(xPlayer) then
-- 	    	xPlayer.triggerEvent("esx_admin:noclip")
-- 	  	end
-- 	end
-- end, false)


------------ functions and events ------------
RegisterNetEvent('esx:onPlayerDeath')
AddEventHandler('esx:onPlayerDeath', function(data)
	deadPlayers[source] = data
end)

RegisterNetEvent('esx:onPlayerSpawn')
AddEventHandler('esx:onPlayerSpawn', function()
	if deadPlayers[source] then
		deadPlayers[source] = nil
	end
end)

AddEventHandler('esx:playerDropped', function(playerId, reason)
	-- empty tables when player no longer online
	if onTimer[playerId] then
		onTimer[playerId] = nil
	end
    if savedCoords[playerId] then
    	savedCoords[playerId] = nil
    end
	if warnedPlayers[playerId] then
		warnedPlayers[playerId] = nil
	end
	if deadPlayers[playerId] then
		deadPlayers[playerId] = nil
	end
end)

function havePermission(xPlayer, exclude)	-- you can exclude rank(s) from having permission to specific commands 	[exclude only take tables]
	if exclude and type(exclude) ~= 'table' then exclude = nil;print("^3[esx_admin] ^1ERROR ^0exclude argument is not table..^0") end	-- will prevent from errors if you pass wrong argument

	local playerGroup = xPlayer.getGroup()
	for k,v in pairs(Config.adminRanks) do
		if v == playerGroup then
			if not exclude then
				return true
			else
				for a,b in pairs(exclude) do
					if b == v then
						return false
					end
				end
				return true
			end
		end
	end
	return false
end