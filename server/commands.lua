ESX.RegisterCommand('setcoords', 'admin', function(xPlayer, args, showError)
	xPlayer.setCoords({x = args.x, y = args.y, z = args.z})
end, false, {help = _U('command_setcoords'), validate = true, arguments = {
	{name = 'x', help = _U('command_setcoords_x'), type = 'number'},
	{name = 'y', help = _U('command_setcoords_y'), type = 'number'},
	{name = 'z', help = _U('command_setcoords_z'), type = 'number'}
}})

ESX.RegisterCommand('setjob', 'admin', function(xPlayer, args, showError)
	if ESX.DoesJobExist(args.job, args.grade) then
		args.playerId.setJob(args.job, args.grade)

		if xPlayer.source == args.playerId.source then
			local sendToDiscord = ''.. xPlayer.name .. ' เปลี่ยนอาชีพให้ตนเอง เป็น ' .. args.job .. ' ระดับ ' .. args.grade .. ''
			TriggerEvent('azael_dc-serverlogs:sendToDiscord', 'AdminCommands', sendToDiscord, xPlayer.source, '^2')
		else
			local sendToDiscord = ''.. xPlayer.name .. ' เปลี่ยนอาชีพให้ ' .. args.playerId.name ..' เป็น ' .. args.job .. ' ระดับ ' .. args.grade .. ''
			TriggerEvent('azael_dc-serverlogs:sendToDiscord', 'AdminCommands', sendToDiscord, xPlayer.source, '^3')
		
			Citizen.Wait(100)
		
			local sendToDiscord = ''.. args.playerId.name .. ' ถูกเปลี่ยนอาชีพเป็น ' .. args.job .. ' ระดับ ' .. args.grade .. ' โดย ' .. xPlayer.name ..' '
			TriggerEvent('azael_dc-serverlogs:sendToDiscord', 'AdminCommands', sendToDiscord, args.playerId.source, '^2')
		end		
	else
		showError(_U('command_setjob_invalid'))
	end
end, true, {help = _U('command_setjob'), validate = true, arguments = {
	{name = 'playerId', help = _U('commandgeneric_playerid'), type = 'player'},
	{name = 'job', help = _U('command_setjob_job'), type = 'string'},
	{name = 'grade', help = _U('command_setjob_grade'), type = 'number'}
}})

ESX.RegisterCommand('car', 'mod', function(xPlayer, args, showError)
	xPlayer.triggerEvent('esx:spawnVehicle', args.car)
end, false, {help = _U('command_car'), validate = false, arguments = {
	{name = 'car', help = _U('command_car_car'), type = 'any'}
}})

ESX.RegisterCommand({'cardel', 'dv'}, 'admin', function(xPlayer, args, showError)
	xPlayer.triggerEvent('esx:deleteVehicle', args.radius)
end, false, {help = _U('command_cardel'), validate = false, arguments = {
	{name = 'radius', help = _U('command_cardel_radius'), type = 'any'}
}})

ESX.RegisterCommand('setaccountmoney', 'admin', function(xPlayer, args, showError)
	if args.playerId.getAccount(args.account) then
		args.playerId.setAccountMoney(args.account, args.amount)

		if xPlayer.source == args.playerId.source then
			local sendToDiscord = ''.. xPlayer.name .. ' กำหนด ' .. args.account .. ' ให้ตนเอง เป็น $' .. ESX.Math.GroupDigits(args.amount) .. ''
			TriggerEvent('azael_dc-serverlogs:sendToDiscord', 'AdminCommands', sendToDiscord, xPlayer.source, '^2')
		else
			local sendToDiscord = ''.. xPlayer.name .. ' กำหนด ' .. args.account .. ' ให้ '.. args.playerId.name .. ' เป็น $' .. ESX.Math.GroupDigits(args.amount) .. ''
			TriggerEvent('azael_dc-serverlogs:sendToDiscord', 'AdminCommands', sendToDiscord, xPlayer.source, '^3')
		
			Citizen.Wait(100)
		
			local sendToDiscord = ''.. args.playerId.name .. ' ถูกกำหนด ' .. args.account .. ' เป็น $' .. ESX.Math.GroupDigits(args.amount) .. ' โดย ' .. xPlayer.name ..''
			TriggerEvent('azael_dc-serverlogs:sendToDiscord', 'AdminCommands', sendToDiscord, args.playerId.source, '^2')
		end
	else
		showError(_U('command_giveaccountmoney_invalid'))
	end
end, true, {help = _U('command_setaccountmoney'), validate = true, arguments = {
	{name = 'playerId', help = _U('commandgeneric_playerid'), type = 'player'},
	{name = 'account', help = _U('command_giveaccountmoney_account'), type = 'string'},
	{name = 'amount', help = _U('command_setaccountmoney_amount'), type = 'number'}
}})

ESX.RegisterCommand('giveaccountmoney', 'admin', function(xPlayer, args, showError)
	if args.playerId.getAccount(args.account) then
		args.playerId.addAccountMoney(args.account, args.amount)

		if xPlayer.source == args.playerId.source then
			local sendToDiscord = ''.. xPlayer.name .. ' เพิ่ม ' .. args.account .. ' จำนวน $' .. ESX.Math.GroupDigits(args.amount) .. ' ให้ตนเอง'
			TriggerEvent('azael_dc-serverlogs:sendToDiscord', 'AdminCommands', sendToDiscord, xPlayer.source, '^2')
		else
			local sendToDiscord = ''.. xPlayer.name .. ' เพิ่ม ' .. args.account .. ' จำนวน $' .. ESX.Math.GroupDigits(args.amount) .. ' ให้ '.. args.playerId.name .. ''
			TriggerEvent('azael_dc-serverlogs:sendToDiscord', 'AdminCommands', sendToDiscord, xPlayer.source, '^3')
		
			Citizen.Wait(100)
		
			local sendToDiscord = ''.. args.playerId.name .. ' ได้รับ ' .. args.account .. ' จำนวน $' .. ESX.Math.GroupDigits(args.amount) .. ' โดย ' .. xPlayer.name ..''
			TriggerEvent('azael_dc-serverlogs:sendToDiscord', 'AdminCommands', sendToDiscord, args.playerId.source, '^2')
		end
	else
		showError(_U('command_giveaccountmoney_invalid'))
	end
end, true, {help = _U('command_giveaccountmoney'), validate = true, arguments = {
	{name = 'playerId', help = _U('commandgeneric_playerid'), type = 'player'},
	{name = 'account', help = _U('command_giveaccountmoney_account'), type = 'string'},
	{name = 'amount', help = _U('command_giveaccountmoney_amount'), type = 'number'}
}})

ESX.RegisterCommand('giveitem', 'admin', function(xPlayer, args, showError)
	args.playerId.addInventoryItem(args.item, args.count)

	if xPlayer.source == args.playerId.source then
		local sendToDiscord = ''.. xPlayer.name .. ' เพิ่ม ' .. ESX.GetItemLabel(args.item) .. ' จำนวน ' .. ESX.Math.GroupDigits(args.count) .. ' ให้ตนเอง'
		TriggerEvent('azael_dc-serverlogs:sendToDiscord', 'AdminCommands', sendToDiscord, xPlayer.source, '^2')
	else
		local sendToDiscord = ''.. xPlayer.name .. ' เพิ่ม ' .. ESX.GetItemLabel(args.item) .. ' จำนวน ' .. ESX.Math.GroupDigits(args.count) .. ' ให้ '.. args.playerId.name .. ' '
		TriggerEvent('azael_dc-serverlogs:sendToDiscord', 'AdminCommands', sendToDiscord, xPlayer.source, '^3')
	
		Citizen.Wait(100)
	
		local sendToDiscord = ''.. args.playerId.name .. ' ได้รับ ' .. ESX.GetItemLabel(args.item) .. ' จำนวน ' .. ESX.Math.GroupDigits(args.count) .. ' โดย ' .. xPlayer.name ..''
		TriggerEvent('azael_dc-serverlogs:sendToDiscord', 'AdminCommands', sendToDiscord, args.playerId.source, '^2')
	end
end, true, {help = _U('command_giveitem'), validate = true, arguments = {
	{name = 'playerId', help = _U('commandgeneric_playerid'), type = 'player'},
	{name = 'item', help = _U('command_giveitem_item'), type = 'item'},
	{name = 'count', help = _U('command_giveitem_count'), type = 'number'}
}})

ESX.RegisterCommand('giveweapon', 'admin', function(xPlayer, args, showError)
	args.playerId.addWeapon(args.weapon, args.ammo)

	if xPlayer.source == args.playerId.source then
		local sendToDiscord = ''.. xPlayer.name .. ' เพิ่ม ' .. ESX.GetWeaponLabel(args.weapon) .. ' และ กระสุน จำนวน ' .. ESX.Math.GroupDigits(args.ammo) .. ' ให้ตนเอง'
		TriggerEvent('azael_dc-serverlogs:sendToDiscord', 'AdminCommands', sendToDiscord, xPlayer.source, '^2')
	else
		local sendToDiscord = ''.. xPlayer.name .. ' เพิ่ม ' .. ESX.GetWeaponLabel(args.weapon) .. ' และ กระสุน จำนวน ' .. ESX.Math.GroupDigits(args.ammo) .. ' ให้ '.. args.playerId.name .. ''
		TriggerEvent('azael_dc-serverlogs:sendToDiscord', 'AdminCommands', sendToDiscord, xPlayer.source, '^3')
	
		Citizen.Wait(100)
	
		local sendToDiscord = ''.. args.playerId.name .. ' ได้รับ ' .. ESX.GetWeaponLabel(args.weapon) .. ' และ กระสุน จำนวน ' .. ESX.Math.GroupDigits(args.ammo) .. ' โดย ' .. xPlayer.name ..''
		TriggerEvent('azael_dc-serverlogs:sendToDiscord', 'AdminCommands', sendToDiscord, args.playerId.source, '^2')
	end
end, true, {help = _U('command_giveweapon'), validate = true, arguments = {
	{name = 'playerId', help = _U('commandgeneric_playerid'), type = 'player'},
	{name = 'weapon', help = _U('command_giveweapon_weapon'), type = 'weapon'},
	{name = 'ammo', help = _U('command_giveweapon_ammo'), type = 'number'}
}})

ESX.RegisterCommand('giveweaponcomponent', 'admin', function(xPlayer, args, showError)
	if args.playerId.hasWeapon(args.weaponName) then
		local component = ESX.GetWeaponComponent(args.weaponName, args.componentName)

		if component then
			if xPlayer.hasWeaponComponent(args.weaponName, args.componentName) then
				showError(_U('command_giveweaponcomponent_hasalready'))
			else
				xPlayer.addWeaponComponent(args.weaponName, args.componentName)

				if xPlayer.source == args.playerId.source then
					local sendToDiscord = ''.. xPlayer.name .. ' เพิ่ม ' .. component.label .. ' ส่วนประกอบของ ' .. ESX.GetWeaponLabel(args.weaponName) .. ' ให้ตนเอง'
					TriggerEvent('azael_dc-serverlogs:sendToDiscord', 'AdminCommands', sendToDiscord, xPlayer.source, '^2')
				else
					local sendToDiscord = ''.. xPlayer.name .. ' เพิ่ม ' .. component.label .. ' ส่วนประกอบของ ' .. ESX.GetWeaponLabel(args.weaponName) .. ' ให้ '.. args.playerId.name .. ''
					TriggerEvent('azael_dc-serverlogs:sendToDiscord', 'AdminCommands', sendToDiscord, xPlayer.source, '^3')
				
					Citizen.Wait(100)
				
					local sendToDiscord = ''.. args.playerId.name .. ' ได้รับ ' .. component.label .. ' ส่วนประกอบของ ' .. ESX.GetWeaponLabel(args.weaponName) .. ' โดย ' .. xPlayer.name ..''
					TriggerEvent('azael_dc-serverlogs:sendToDiscord', 'AdminCommands', sendToDiscord, args.playerId.source, '^2')
				end				
			end
		else
			showError(_U('command_giveweaponcomponent_invalid'))
		end
	else
		showError(_U('command_giveweaponcomponent_missingweapon'))
	end
end, true, {help = _U('command_giveweaponcomponent'), validate = true, arguments = {
	{name = 'playerId', help = _U('commandgeneric_playerid'), type = 'player'},
	{name = 'weaponName', help = _U('command_giveweapon_weapon'), type = 'weapon'},
	{name = 'componentName', help = _U('command_giveweaponcomponent_component'), type = 'string'}
}})

-- ESX.RegisterCommand({'clear', 'cls'}, 'user', function(xPlayer, args, showError)
-- 	xPlayer.triggerEvent('chat:clear')
-- end, false, {help = _U('command_clear')})

ESX.RegisterCommand({'clearall', 'clsall'}, 'admin', function(xPlayer, args, showError)
	TriggerClientEvent('chat:clear', -1)
end, false, {help = _U('command_clearall')})

ESX.RegisterCommand('clearinventory', 'admin', function(xPlayer, args, showError)
	for k,v in ipairs(args.playerId.inventory) do
		if v.count > 0 then
			args.playerId.setInventoryItem(v.name, 0)
		end
	end
end, true, {help = _U('command_clearinventory'), validate = true, arguments = {
	{name = 'playerId', help = _U('commandgeneric_playerid'), type = 'player'}
}})

ESX.RegisterCommand('clearloadout', 'admin', function(xPlayer, args, showError)
	for k,v in ipairs(args.playerId.loadout) do
		args.playerId.removeWeapon(v.name)
	end
end, true, {help = _U('command_clearloadout'), validate = true, arguments = {
	{name = 'playerId', help = _U('commandgeneric_playerid'), type = 'player'}
}})

ESX.RegisterCommand('setgroup', 'admin', function(xPlayer, args, showError)
	args.playerId.setGroup(args.group)
end, true, {help = _U('command_setgroup'), validate = true, arguments = {
	{name = 'playerId', help = _U('commandgeneric_playerid'), type = 'player'},
	{name = 'group', help = _U('command_setgroup_group'), type = 'string'},
}})

ESX.RegisterCommand('save', 'admin', function(xPlayer, args, showError)
	ESX.SavePlayer(args.playerId)
end, true, {help = _U('command_save'), validate = true, arguments = {
	{name = 'playerId', help = _U('commandgeneric_playerid'), type = 'player'}
}})

ESX.RegisterCommand('saveall', 'admin', function(xPlayer, args, showError)
	ESX.SavePlayers()
end, true, {help = _U('command_saveall')})
