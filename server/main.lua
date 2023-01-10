RegisterNetEvent('esx:onPlayerJoined')
AddEventHandler('esx:onPlayerJoined', function()
	if not ESX.Players[source] then
		onPlayerJoined(source)
	end
end)

function onPlayerJoined(playerId)
	local identifier

	
	for k,v in ipairs(GetPlayerIdentifiers(playerId)) do
        if string.match(v, 'steam:') then
            identifier = v
            break
        end
    end

	if identifier then
		if ESX.GetPlayerFromIdentifier(identifier) then
			DropPlayer(playerId, ('เกิดข้อผิดพลาดขึ้น !\nรหัสข้อผิดพลาด : identifier-active-ingame\n\nข้อผิดพลาดนี้เกิดจากผู้เล่นในเซิฟเวอร์ใช้บัญชี Steam เดียวกันกับคุณ ตรวจสอบให้แน่ใจว่าคุณไม่ได้ใช้บัญชี Steam เดียวกัน \n\nSteam : %s'):format(identifier))
		else
			MySQL.Async.fetchScalar('SELECT 1 FROM users WHERE identifier = @identifier', {
				['@identifier'] = identifier
			}, function(result)
				if result then
					loadESXPlayer(identifier, playerId)
				else
					local accounts = {}

					for account,money in pairs(Config.StartingAccountMoney) do
						accounts[account] = money
					end

					MySQL.Async.execute('INSERT INTO users (accounts, identifier) VALUES (@accounts, @identifier)', {
						['@accounts'] = json.encode(accounts),
						['@identifier'] = identifier
					}, function(rowsChanged)
						loadESXPlayer(identifier, playerId)
					end)

				end
			end)
		end
	else
		DropPlayer(playerId, 'เกิดข้อผิดพลาดขึ้น !\nรหัสข้อผิดพลาด : identifier-missing-ingame\n\nไม่พบการเชื่อมต่อกับ Steam กรุณาลองใหม่อีกครั้งหรือติดต่อแอดมิน')
	end
end

AddEventHandler('playerConnecting', function(name, setCallback, deferrals)
	deferrals.defer()
	local playerId, identifier = source
	Citizen.Wait(100)

	for k,v in ipairs(GetPlayerIdentifiers(playerId)) do
		if string.match(v, 'steam:') then
			identifier = v
			break
		end
	end

	if identifier then
		if ESX.GetPlayerFromIdentifier(identifier) then
			deferrals.done(('เกิดข้อผิดพลาดขึ้น !\nรหัสข้อผิดพลาด : identifier-active\n\nข้อผิดพลาดนี้เกิดจากผู้เล่นในเซิฟเวอร์ใช้บัญชี Steam เดียวกันกับคุณ ตรวจสอบให้แน่ใจว่าคุณไม่ได้ใช้บัญชี Steam เดียวกัน \n\nSteam : %s'):format(identifier))
		else
			deferrals.done()
		end
	else
		deferrals.done('เกิดข้อผิดพลาดขึ้น !\nรหัสข้อผิดพลาด : identifier-missing\n\nไม่พบการเชื่อมต่อกับ Steam กรุณาลองใหม่อีกครั้งหรือติดต่อแอดมิน')
	end
end)


function loadESXPlayer(identifier, playerId)
	local tasks = {}

	local userData = {
		accounts = {},
		inventory = {},
		job = {},
		loadout = {},
		playerName = GetPlayerName(playerId),
	}

	table.insert(tasks, function(cb)
		MySQL.Async.fetchAll('SELECT accounts, job, job_grade, `group`, loadout, position, inventory FROM users WHERE identifier = @identifier', {
			['@identifier'] = identifier
		}, function(result)
			local job, grade, jobObject, gradeObject = result[1].job, tostring(result[1].job_grade)
			local foundAccounts, foundItems = {}, {}

			-- Accounts
			if result[1].accounts and result[1].accounts ~= '' then
				local accounts = json.decode(result[1].accounts)

				for account,money in pairs(accounts) do
					foundAccounts[account] = money
				end
			end

			for account,label in pairs(Config.Accounts) do
				table.insert(userData.accounts, {
					name = account,
					money = foundAccounts[account] or Config.StartingAccountMoney[account] or 0,
					label = label
				})
			end

			-- Job
			if ESX.DoesJobExist(job, grade) then
				jobObject, gradeObject = ESX.Jobs[job], ESX.Jobs[job].grades[grade]
			else
				print(('[^2SupSibz.Base^7] [^3WARNING^7] Ignoring invalid job for %s [job: %s, grade: %s]'):format(identifier, job, grade))
				job, grade = 'unemployed', '0'
				jobObject, gradeObject = ESX.Jobs[job], ESX.Jobs[job].grades[grade]
			end

			userData.job.id = jobObject.id
			userData.job.name = jobObject.name
			userData.job.label = jobObject.label

			userData.job.grade = tonumber(grade)
			userData.job.grade_name = gradeObject.name
			userData.job.grade_label = gradeObject.label
			userData.job.grade_salary = gradeObject.salary

			userData.job.skin_male = {}
			userData.job.skin_female = {}

			if gradeObject.skin_male then userData.job.skin_male = json.decode(gradeObject.skin_male) end
			if gradeObject.skin_female then userData.job.skin_female = json.decode(gradeObject.skin_female) end

			-- Inventory
			if result[1].inventory and result[1].inventory ~= '' then
				local inventory = json.decode(result[1].inventory)

				for name,count in pairs(inventory) do
					local item = ESX.Items[name]

					if item then
						foundItems[name] = count
					else
						print(('[^2SupSibz.Base^7] [^3WARNING^7] Ignoring invalid item "%s" for "%s"'):format(name, identifier))
					end
				end
			end

			for name,item in pairs(ESX.Items) do
				local count = foundItems[name] or 0

				table.insert(userData.inventory, {
					name = name,
					count = count,
					label = item.label,
					limit = item.limit,
					usable = ESX.UsableItemsCallbacks[name] ~= nil,
					rare = item.rare,
					canRemove = item.canRemove
				})
			end

			table.sort(userData.inventory, function(a, b)
				return a.label < b.label
			end)

			-- Group
			if result[1].group then
				userData.group = result[1].group
			else
				userData.group = 'user'
			end

			-- Loadout
			if result[1].loadout and result[1].loadout ~= '' then
				local loadout = json.decode(result[1].loadout)

				for name,weapon in pairs(loadout) do
					local label = ESX.GetWeaponLabel(name)

					if label then
						if not weapon.components then weapon.components = {} end
						if not weapon.tintIndex then weapon.tintIndex = 0 end

						table.insert(userData.loadout, {
							name = name,
							ammo = weapon.ammo,
							label = label,
							components = weapon.components,
							tintIndex = weapon.tintIndex
						})
					end
				end
			end

			-- Position
			if result[1].position and result[1].position ~= '' then
				userData.coords = json.decode(result[1].position)
			else
				print('[^2SupSibz.Base^7] [^3WARNING^7] Column "position" in "users" table is missing required default value. Using backup coords, fix your database.')
				userData.coords = {x = -269.4, y = -955.3, z = 31.2, heading = 205.8}
			end

			cb()
		end)
	end)

	Async.parallel(tasks, function(results)
		local xPlayer = CreateExtendedPlayer(playerId, identifier, userData.group, userData.accounts, userData.inventory, userData.weight, userData.job, userData.loadout, userData.playerName, userData.coords)
		ESX.Players[playerId] = xPlayer
		TriggerEvent('esx:playerLoaded', playerId, xPlayer)

		xPlayer.triggerEvent('esx:playerLoaded', {
			accounts = xPlayer.getAccounts(),
			coords = xPlayer.getCoords(),
			identifier = xPlayer.getIdentifier(),
			inventory = xPlayer.getInventory(),
			job = xPlayer.getJob(),
			loadout = xPlayer.getLoadout(),
			money = xPlayer.getMoney()
		})

		xPlayer.triggerEvent('esx:createMissingPickups', ESX.Pickups)
		xPlayer.triggerEvent('esx:registerSuggestions', ESX.RegisteredCommands)
		--print(('[SupSibz.Base] [^2INFO^7] A player with name "%s^7" has connected to the server with assigned player id %s'):format(xPlayer.getName(), playerId))
	end)
	
end

AddEventHandler('chatMessage', function(playerId, author, message)
	if message:sub(1, 1) == '/' and playerId > 0 then
		CancelEvent()
		local commandName = message:sub(1):gmatch("%w+")()
		TriggerClientEvent('chat:addMessage', playerId, {args = {'^1SYSTEM', _U('commanderror_invalidcommand', commandName)}})
	end
end)

AddEventHandler('playerDropped', function(reason)
	local playerId = source
	local xPlayer = ESX.GetPlayerFromId(playerId)

	if xPlayer then
		TriggerEvent('esx:playerDropped', playerId, reason)

		ESX.SavePlayer(xPlayer, function()
			ESX.Players[playerId] = nil
		end)
		
		MySQL.Async.execute('UPDATE users SET `name` = @name WHERE `identifier` = @identifier', {
			['@identifier'] = xPlayer.identifier,
			['@name'] = GetPlayerName(playerId)
		})
	end
end)

RegisterNetEvent('esx:updateCoords')
AddEventHandler('esx:updateCoords', function(coords)
	--local xPlayer = ESX.GetPlayerFromId(source)
--
	--if xPlayer then
	--	xPlayer.updateCoords(coords)
	--end
	local xPlayer = ESX.GetPlayerFromId(source)
	local playerCoords = GetEntityCoords(GetPlayerPed(source))
	local playerHeading = ESX.Math.Round(GetEntityHeading(GetPlayerPed(source)), 1)
	local formattedCoords = {x = ESX.Math.Round(playerCoords.x, 1), y = ESX.Math.Round(playerCoords.y, 1), z = ESX.Math.Round(playerCoords.z, 1), heading = playerHeading}
	if xPlayer then
		xPlayer.updateCoords(formattedCoords)
	end
end)

RegisterNetEvent('esx:updateWeaponAmmo')
AddEventHandler('esx:updateWeaponAmmo', function(weaponName, ammoCount)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer then
		xPlayer.updateWeaponAmmo(weaponName, ammoCount)
	end
end)

RegisterNetEvent('esx:giveInventoryItem')
AddEventHandler('esx:giveInventoryItem', function(target, type, itemName, itemCount)
	local playerId = source
	local sourceXPlayer = ESX.GetPlayerFromId(playerId)
	local targetXPlayer = ESX.GetPlayerFromId(target)

	if type == 'item_standard' then
		local sourceItem = sourceXPlayer.getInventoryItem(itemName)
		local targetItem = targetXPlayer.getInventoryItem(itemName)

		if itemCount > 0 and sourceItem.count >= itemCount then
			-- if targetXPlayer.canCarryItem(itemName, itemCount) then
			if targetItem.limit ~= -1 and (targetItem.count + itemCount) > targetItem.limit then
				

				-- local sourceItemBalance    = sourceXPlayer.getInventoryItem(itemName).count
				-- local targetItemBalance    = targetXPlayer.getInventoryItem(itemName).count

				--local sendToDiscord = ''.. sourceXPlayer.name .. ' ส่ง ' .. ESX.GetItemLabel(itemName) .. ' ให้กับ ' .. targetXPlayer.name .. ' จำนวน ' .. ESX.Math.GroupDigits(itemCount) .. ''
				--TriggerEvent('azael_discordlogs:sendToDiscord', 'GiveItem', sendToDiscord, sourceXPlayer.source, '^1')	
								
				-- Citizen.Wait(100)
								
				--local sendToDiscord2 = ''.. targetXPlayer.name .. ' ได้รับ ' .. ESX.GetItemLabel(itemName) .. ' จาก ' .. sourceXPlayer.name .. ' จำนวน ' .. ESX.Math.GroupDigits(itemCount) .. ''
				--TriggerEvent('azael_discordlogs:sendToDiscord', 'GiveItem', sendToDiscord2, targetXPlayer.source, '^2')
				TriggerClientEvent("pNotify:SendNotification", source, {
					text = '<strong class="red-text">ล้มเหลว</strong> คุณ <strong class="blue-text">' .. targetXPlayer.name ..'</strong> ไม่สามารถรับไอเทมจากคุณได้เนื่องจากจำนวนเกินขีดจำกัด',
					type = "information",
					timeout = 5000,
					layout = "centerRight",
					queue = "global"
				})
			else
				sourceXPlayer.removeInventoryItem(itemName, itemCount)
				targetXPlayer.addInventoryItem   (itemName, itemCount)
			end
		else
			TriggerClientEvent("pNotify:SendNotification", source, {
				text = '<strong class="red-text">ล้มเหลว</strong> ปริมาณที่ไม่ถูกต้อง',
				type = "information",
				timeout = 5000,
				layout = "centerRight",
				queue = "global"
			})
		end
	elseif type == 'item_account' then
		if itemCount > 0 and sourceXPlayer.getAccount(itemName).money >= itemCount then
			sourceXPlayer.removeAccountMoney(itemName, itemCount)
			targetXPlayer.addAccountMoney   (itemName, itemCount)

			--local sendToDiscord = ''.. sourceXPlayer.name .. ' ส่ง ' .. Config.Accounts[itemName] .. ' ให้กับ ' .. targetXPlayer.name .. ' จำนวน $' .. ESX.Math.GroupDigits(itemCount) .. ''
			--TriggerEvent('azael_discordlogs:sendToDiscord', 'GiveMoney', sendToDiscord, sourceXPlayer.source, '^1')	
						
			-- Citizen.Wait(100)
						
			--local sendToDiscord2 = ''.. targetXPlayer.name .. ' ได้รับ ' .. Config.Accounts[itemName] .. ' จาก ' .. sourceXPlayer.name .. ' จำนวน $' .. ESX.Math.GroupDigits(itemCount) .. ''
			--TriggerEvent('azael_discordlogs:sendToDiscord', 'GiveMoney', sendToDiscord2, targetXPlayer.source, '^2')
			-- TriggerClientEvent("pNotify:SendNotification", source, { --แจ้งเตือนเรา _source = owned
			-- 	text = '<strong class="blue-text">ช่วยเหลือ</strong> ส่ง <strong class="amber-text">เงินสด</strong> จำนวน ' .. itemCount..'',
			-- 	type = "information",
			-- 	timeout = 5000,
			-- 	layout = "centerRight",
			-- 	queue = "global"
			-- })
			-- TriggerClientEvent("pNotify:SendNotification", target, { --แจ้งเตือนเป้าหมาย target = Other players
			-- 	text = '<strong class="blue-text">ช่วยเหลือ</strong> ได้รับ <strong class="amber-text">เงินสด</strong> จำนวน ' .. itemCount..'',
			-- 	type = "information",
			-- 	timeout = 5000,
			-- 	layout = "centerRight",
			-- 	queue = "global"
			-- })
		else
			TriggerClientEvent("pNotify:SendNotification", source, {
				text = '<strong class="red-text">ล้มเหลว</strong> ปริมาณที่ไม่ถูกต้อง',
				type = "information",
				timeout = 5000,
				layout = "centerRight",
				queue = "global"
			})
		end
	elseif type == 'item_weapon' then
		if sourceXPlayer.hasWeapon(itemName) then
			local weaponLabel = ESX.GetWeaponLabel(itemName)

			if not targetXPlayer.hasWeapon(itemName) then
				local _, weapon = sourceXPlayer.getWeapon(itemName)
				local _, weaponObject = ESX.GetWeapon(itemName)
				itemCount = weapon.ammo

				sourceXPlayer.removeWeapon(itemName)
				targetXPlayer.addWeapon(itemName, itemCount)

				if weaponObject.ammo and itemCount > 0 then
					local ammoLabel = weaponObject.ammo.label

					TriggerClientEvent("pNotify:SendNotification", source, {
						text = '<strong class="blue-text">ช่วยเหลือ</strong> ส่ง <strong class="amber-text">'.. weaponLabel ..'</strong> (กระสุน จำนวน ' .. itemCount ..')',
						type = "information",
						timeout = 5000,
						layout = "centerRight",
						queue = "global"
					})
					TriggerClientEvent("pNotify:SendNotification", target, {
						text = '<strong class="blue-text">ช่วยเหลือ</strong> ได้รับ <strong class="amber-text">'.. weaponLabel ..'</strong> (กระสุน จำนวน ' .. itemCount ..')',
						type = "information",
						timeout = 5000,
						layout = "centerRight",
						queue = "global"
					})
				else
					TriggerClientEvent("pNotify:SendNotification", source, {
						text = '<strong class="blue-text">ช่วยเหลือ</strong> ส่ง <strong class="amber-text">'.. weaponLabel ..'</strong>',
						type = "information",
						timeout = 5000,
						layout = "centerRight",
						queue = "global"
					})
					TriggerClientEvent("pNotify:SendNotification", target, {
						text = '<strong class="blue-text">ช่วยเหลือ</strong> ได้รับ <strong class="amber-text">'.. weaponLabel ..'</strong>',
						type = "information",
						timeout = 5000,
						layout = "centerRight",
						queue = "global"
					})
				end
				--[[if weaponObject.ammo and itemCount > 0 then
					local sendToDiscord = ''.. sourceXPlayer.name .. ' ส่ง '.. weaponLabel ..' และ ' .. weaponObject.ammo.label .. ' จำนวน ' .. ESX.Math.GroupDigits(itemCount) .. ' ให้กับ ' .. targetXPlayer.name .. ''
					TriggerEvent('azael_discordlogs:sendToDiscord', 'GiveWeapon', sendToDiscord, sourceXPlayer.source, '^1')	
						
					Citizen.Wait(100)
						
					local sendToDiscord2 = ''.. targetXPlayer.name .. ' ได้รับ '.. weaponLabel ..' และ ' .. weaponObject.ammo.label .. ' จำนวน ' .. ESX.Math.GroupDigits(itemCount) .. ' จาก ' .. sourceXPlayer.name .. ''
					TriggerEvent('azael_discordlogs:sendToDiscord', 'GiveWeapon', sendToDiscord2, targetXPlayer.source, '^2')
				else
					local sendToDiscord = ''.. sourceXPlayer.name .. ' ส่ง '.. weaponLabel ..' ให้กับ ' .. targetXPlayer.name .. ''
					TriggerEvent('azael_discordlogs:sendToDiscord', 'GiveWeapon', sendToDiscord, sourceXPlayer.source, '^1')	
						
					Citizen.Wait(100)
						
					local sendToDiscord2 = ''.. targetXPlayer.name .. ' ได้รับ '.. weaponLabel ..' จาก ' .. sourceXPlayer.name .. ''
					TriggerEvent('azael_discordlogs:sendToDiscord', 'GiveWeapon', sendToDiscord2, targetXPlayer.source, '^2')
				end]]
			else
				TriggerClientEvent("pNotify:SendNotification", source, {
					text = '<strong class="red-text">ล้มเหลว</strong> ผู้เล่นมีอาวุธอยู่แล้ว',
					type = "information",
					timeout = 5000,
					layout = "centerRight",
					queue = "global"
				})
				TriggerClientEvent("pNotify:SendNotification", target, {
					text = '<strong class="red-text">ล้มเหลว</strong> คุณมีอาวุธอยู่แล้ว',
					type = "information",
					timeout = 5000,
					layout = "centerRight",
					queue = "global"
				})
			end
		end
	elseif type == 'item_ammo' then
		if sourceXPlayer.hasWeapon(itemName) then
			local weaponNum, weapon = sourceXPlayer.getWeapon(itemName)

			if targetXPlayer.hasWeapon(itemName) then
				local _, weaponObject = ESX.GetWeapon(itemName)

				if weaponObject.ammo then
					local ammoLabel = weaponObject.ammo.label

					if weapon.ammo >= itemCount then
						sourceXPlayer.removeWeaponAmmo(itemName, itemCount)
						targetXPlayer.addWeaponAmmo(itemName, itemCount)

						sourceXPlayer.showNotification(_U('gave_weapon_ammo', itemCount, ammoLabel, weapon.label, targetXPlayer.name))
						targetXPlayer.showNotification(_U('received_weapon_ammo', itemCount, ammoLabel, weapon.label, sourceXPlayer.name))

						--local sendToDiscord = ''.. sourceXPlayer.name .. ' ส่ง '.. ammoLabel ..' ของ ' .. weapon.label .. ' จำนวน ' .. ESX.Math.GroupDigits(itemCount) .. ' ให้กับ ' .. targetXPlayer.name .. ''
						--TriggerEvent('azael_discordlogs:sendToDiscord', 'GiveAmmo', sendToDiscord, sourceXPlayer.source, '^1')	
							
						Citizen.Wait(100)
							
						--local sendToDiscord2 = ''.. targetXPlayer.name .. ' ได้รับ '.. ammoLabel ..' ของ ' .. weapon.label .. '  จำนวน ' .. ESX.Math.GroupDigits(itemCount) .. ' จาก ' .. sourceXPlayer.name .. ''
						--TriggerEvent('azael_discordlogs:sendToDiscord', 'GiveAmmo', sendToDiscord2, targetXPlayer.source, '^2')
					end
				end
			else
				sourceXPlayer.showNotification(_U('gave_weapon_noweapon', targetXPlayer.name))
				targetXPlayer.showNotification(_U('received_weapon_noweapon', sourceXPlayer.name, weapon.label))
			end
		end
	end
end)

RegisterNetEvent('esx:removeInventoryItem')
AddEventHandler('esx:removeInventoryItem', function(type, itemName, itemCount)
	local playerId = source
	local xPlayer = ESX.GetPlayerFromId(source)

	if type == 'item_standard' then
		if itemCount == nil or itemCount < 1 then
			
			TriggerClientEvent("pNotify:SendNotification", source, {
				text = '<strong class="red-text">ล้มเหลว</strong> ปริมาณที่ไม่ถูกต้อง',
				type = "information",
				timeout = 5000,
				layout = "centerRight",
				queue = "global"
			})
		else
			local xItem = xPlayer.getInventoryItem(itemName)

			if (itemCount > xItem.count or xItem.count < 1) then
				
				TriggerClientEvent("pNotify:SendNotification", source, {
					text = '<strong class="red-text">ล้มเหลว</strong> ปริมาณที่ไม่ถูกต้อง',
					type = "information",
					timeout = 5000,
					layout = "centerRight",
					queue = "global"
				})
			else
				xPlayer.removeInventoryItem(itemName, itemCount)

				TriggerClientEvent("pNotify:SendNotification", source, {
					text = '<strong class="green-text">ช่วยเหลือ</strong> คุณโยน <strong class="green-text">'..xItem.label..'</strong><strong class="yellow-text"> ['..itemCount..']</strong> ลงพื้น',
					type = "information",
					timeout = 5000,
					layout = "centerRight",
					queue = "global"
				})
				--local sendToDiscord = ''.. xPlayer.name .. ' ทิ้ง '.. xItem.label ..' จำนวน ' .. ESX.Math.GroupDigits(itemCount) .. ''
				--TriggerEvent('azael_discordlogs:sendToDiscord', 'RemoveItem', sendToDiscord, xPlayer.source, '^1')
			end
		end
	elseif type == 'item_account' then
		if itemCount == nil or itemCount < 1 then
			
			TriggerClientEvent("pNotify:SendNotification", source, {
				text = '<strong class="red-text">ล้มเหลว</strong> ปริมาณที่ไม่ถูกต้อง',
				type = "information",
				timeout = 5000,
				layout = "centerRight",
				queue = "global"
			})
		else
			local account = xPlayer.getAccount(itemName)

			if (itemCount > account.money or account.money < 1) then
				
				TriggerClientEvent("pNotify:SendNotification", source, {
					text = '<strong class="red-text">ล้มเหลว</strong> ปริมาณที่ไม่ถูกต้อง',
					type = "information",
					timeout = 5000,
					layout = "centerRight",
					queue = "global"
				})
			else
				xPlayer.removeAccountMoney(itemName, itemCount)
				
				TriggerClientEvent("pNotify:SendNotification", source, {
					text = '<strong class="green-text">ช่วยเหลือ</strong>คุณโยน <strong class="green-text">'..string.lower(account.label)..' <strong class="yellow-text">['..ESX.Math.GroupDigits(itemCount)..']</strong> ลงพื้น<center>',
					type = "information",
					timeout = 5000,
					layout = "centerRight",
					queue = "global"
				})
				--local sendToDiscord = ''.. xPlayer.name .. ' ทิ้ง ' .. Config.Accounts[itemName] .. ' จำนวน $' .. ESX.Math.GroupDigits(itemCount) .. ''
				--TriggerEvent('azael_discordlogs:sendToDiscord', 'RemoveMoney', sendToDiscord, xPlayer.source, '^1')
			end
		end
	elseif type == 'item_weapon' then
		itemName = string.upper(itemName)

		if xPlayer.hasWeapon(itemName) then
			local _, weapon = xPlayer.getWeapon(itemName)
			local _, weaponObject = ESX.GetWeapon(itemName)
			local components, pickupLabel = ESX.Table.Clone(weapon.components)
			xPlayer.removeWeapon(itemName)

			if weaponObject.ammo and weapon.ammo > 0 then
				local ammoLabel = weaponObject.ammo.label
				pickupLabel = ('~y~%s~s~ [~g~%s~s~ %s]'):format(weapon.label, weapon.ammo, ammoLabel)
				xPlayer.showNotification(_U('threw_weapon_ammo', weapon.label, weapon.ammo, ammoLabel))
			else
				pickupLabel = ('~y~%s~s~'):format(weapon.label)
			end
			--if weaponObject.ammo and weapon.ammo > 0 then
				--local sendToDiscord = ''.. xPlayer.name .. ' ทิ้ง ' .. weapon.label .. ' และ ' .. weaponObject.ammo.label .. ' จำนวน ' .. ESX.Math.GroupDigits(weapon.ammo) .. ''
				--TriggerEvent('azael_discordlogs:sendToDiscord', 'RemoveWeapon', sendToDiscord, xPlayer.source, '^1')
			--else
				--local sendToDiscord = ''.. xPlayer.name .. ' ทิ้ง ' .. weapon.label .. ''
				--TriggerEvent('azael_discordlogs:sendToDiscord', 'RemoveWeapon', sendToDiscord, xPlayer.source, '^1')
			--end
		end
	end
end)

RegisterNetEvent('esx:useItem')
AddEventHandler('esx:useItem', function(itemName)
	local xPlayer = ESX.GetPlayerFromId(source)
	local count = xPlayer.getInventoryItem(itemName).count

	if count > 0 then
		ESX.UseItem(source, itemName)
	else
		TriggerClientEvent("pNotify:SendNotification", source, {
			text = '<strong class="red-text">ล้มเหลว</strong> การกระทำเป็นไปไม่ได้',
			type = "information",
			timeout = 5000,
			layout = "centerRight",
			queue = "global"
		})
	end
end)

RegisterNetEvent('esx:onPickup')
AddEventHandler('esx:onPickup', function(pickupId)
	local pickup, xPlayer, success = ESX.Pickups[pickupId], ESX.GetPlayerFromId(source)

	if pickup then
		if pickup.type == 'item_standard' then
			if xPlayer.canCarryItem(pickup.name, pickup.count) then
				xPlayer.addInventoryItem(pickup.name, pickup.count)
				success = true
				--local sendToDiscord = ''.. xPlayer.name .. ' เก็บ ' .. ESX.GetItemLabel(pickup.name) .. ' จำนวน ' .. ESX.Math.GroupDigits(pickup.count) ..''
				--TriggerEvent('azael_discordlogs:sendToDiscord', 'PickupItem', sendToDiscord, xPlayer.source, '^2')
			else
				--xPlayer.showNotification(_U('threw_cannot_pickup'))
				TriggerClientEvent('pNotify:SendNotification', source, {
					text = "เนื่องจากกระเป๋าเต็ม คุณไม่สามารถเก็บได้อีก",
					type = "error",
					queue = "center",
					timeout = 5000,
					layout = "bottomCenter"
				})
			end
		elseif pickup.type == 'item_account' then
			success = true
			xPlayer.addAccountMoney(pickup.name, pickup.count)

			--local sendToDiscord = ''.. xPlayer.name .. ' เก็บ ' .. Config.Accounts[pickup.name] .. ' จำนวน $' .. ESX.Math.GroupDigits(pickup.count) ..''
			--TriggerEvent('azael_discordlogs:sendToDiscord', 'PickupMoney', sendToDiscord, xPlayer.source, '^2')

		elseif pickup.type == 'item_weapon' then
			if xPlayer.hasWeapon(pickup.name) then

				TriggerClientEvent('pNotify:SendNotification', source, {
					text = "คุณมีอาวุธ " ..pickup.name.. " อยู่แล้ว",
					type = "error",
					queue = "center",
					timeout = 5000,
					layout = "bottomCenter"
				})
			else
				success = true
				xPlayer.addWeapon(pickup.name, pickup.count)
				xPlayer.setWeaponTint(pickup.name, pickup.tintIndex)

				for k,v in ipairs(pickup.components) do
					xPlayer.addWeaponComponent(pickup.name, v)
				end

				--if pickup.count > 0 then
				--	local sendToDiscord = ''.. xPlayer.name .. ' เก็บ ' .. ESX.GetWeaponLabel(pickup.name) .. ' และ กระสุน จำนวน ' .. ESX.Math.GroupDigits(pickup.count) .. ''
				--	TriggerEvent('azael_discordlogs:sendToDiscord', 'PickupWeapon', sendToDiscord, xPlayer.source, '^2')
				--else
				--	local sendToDiscord = ''.. xPlayer.name .. ' เก็บ ' .. ESX.GetWeaponLabel(pickup.name) .. ''
				--	TriggerEvent('azael_discordlogs:sendToDiscord', 'PickupWeapon', sendToDiscord, xPlayer.source, '^2')
				--end
			end
		end

		if success then
			ESX.Pickups[pickupId] = nil
			TriggerClientEvent('esx:removePickup', -1, pickupId)
		end
	end
end)

ESX.RegisterServerCallback('esx:getPlayerData', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)

	cb({
		identifier   = xPlayer.identifier,
		accounts     = xPlayer.getAccounts(),
		inventory    = xPlayer.getInventory(),
		job          = xPlayer.getJob(),
		loadout      = xPlayer.getLoadout(),
		money        = xPlayer.getMoney()
	})
end)

ESX.RegisterServerCallback('esx:getOtherPlayerData', function(source, cb, target)
	local xPlayer = ESX.GetPlayerFromId(target)

	cb({
		identifier   = xPlayer.identifier,
		accounts     = xPlayer.getAccounts(),
		inventory    = xPlayer.getInventory(),
		job          = xPlayer.getJob(),
		loadout      = xPlayer.getLoadout(),
		money        = xPlayer.getMoney()
	})
end)

ESX.RegisterServerCallback('esx:getPlayerNames', function(source, cb, players)
	players[source] = nil

	for playerId,v in pairs(players) do
		local xPlayer = ESX.GetPlayerFromId(playerId)

		if xPlayer then
			players[playerId] = xPlayer.getName()
		else
			players[playerId] = nil
		end
	end

	cb(players)
end)

ESX.StartDBSync()
--ESX.StartPayCheck()