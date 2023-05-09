local isPaused, isDead, pickups = false, false, {}

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(100)
		if NetworkIsPlayerActive(PlayerId()) then
			TriggerServerEvent('esx:onPlayerJoined')
			break
		end
	end
end)

local firstLogin = true
local modelLoaded = false

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerData)
	ESX.PlayerLoaded = true
	ESX.PlayerData = playerData

	-- check if player is coming from loading screen
	if GetEntityModel(PlayerPedId()) == 'PLAYER_ZERO' then
		local defaultModel = 'a_m_y_stbla_02'
		RequestModel(defaultModel)

		while not HasModelLoaded(defaultModel) do
			Citizen.Wait(10)
		end

		SetPlayerModel(PlayerId(), defaultModel)
		SetPedDefaultComponentVariation(PlayerPedId())
		SetPedRandomComponentVariation(PlayerPedId(), true)
		SetModelAsNoLongerNeeded(defaultModel)
	end

	-- freeze the player
	FreezeEntityPosition(PlayerPedId(), true)

	-- enable PVP
	SetCanAttackFriendly(PlayerPedId(), true, false)
	NetworkSetFriendlyFireOption(true)

	-- disable wanted level
	ClearPlayerWantedLevel(PlayerId())
	SetMaxWantedLevel(0)

	if Config.EnableHud then
		for k,v in ipairs(playerData.accounts) do
			local accountTpl = '<div><img src="img/accounts/' .. v.name .. '.png"/>&nbsp;{{money}}</div>'
			ESX.UI.HUD.RegisterElement('account_' .. v.name, k, 0, accountTpl, {money = ESX.Math.GroupDigits(v.money)})
		end

		local jobTpl = '<div>{{job_label}} - {{grade_label}}</div>'

		if playerData.job.grade_label == '' or playerData.job.grade_label == playerData.job.label then
			jobTpl = '<div>{{job_label}}</div>'
		end

		ESX.UI.HUD.RegisterElement('job', #playerData.accounts, 0, jobTpl, {
			job_label = playerData.job.label,
			grade_label = playerData.job.grade_label
		})
	end
	ESX.Game.Teleport(PlayerPedId(), {
		x = playerData.coords.x,
		y = playerData.coords.y,
		z = playerData.coords.z + 0.25,
		heading = playerData.coords.heading
	}, function()
	end)
end)

AddEventHandler('playerSpawned', function()
	if not firstLogin then
		return
	end
	firstLogin = false
	while not ESX.PlayerLoaded or not ESX.PlayerData --[[ or not loadedInnerCore ]] do
		Citizen.Wait(1000)
		print('Wait Load Model')
	end
	local playerData = ESX.PlayerData

	Citizen.CreateThread(function()
		while not modelLoaded do
			print('Wait Load Model')
			Citizen.Wait(2000)
		end
		Citizen.Wait(1000)
		print('Model Loaded')
		FreezeEntityPosition(PlayerPedId(),true)
-- 
		local elements = {
			{label = "ยืนยัน <strong class='blue-text'>ตัวละคร</strong> โหลดเสร็จแล้ว",value = '1'	},
		}
		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'xMaps', {
			title    = 'ระบบป้องกันตกแมพ',
			align    = 'center',
			elements = elements
		}, function(data,menu)
	-- 
			if data.current.value == '1' then
				menu.close()
				FreezeEntityPosition(PlayerPedId(),false)
			end
		end, function(data,menu)
			menu.close()
			FreezeEntityPosition(PlayerPedId(),false)
		end)
	end)

	-- ESX.Game.Teleport(PlayerPedId(), {
	-- 	x = playerData.coords.x,
	-- 	y = playerData.coords.y,
	-- 	z = playerData.coords.z + 0.25,
	-- 	heading = playerData.coords.heading
	-- }, function()
		TriggerServerEvent('esx:onPlayerSpawn')
		TriggerEvent('esx:onPlayerSpawn')
		-- TriggerEvent('playerSpawned') -- compatibility with old scripts, will be removed soon
		TriggerEvent('esx:restoreLoadout')
		TriggerServerEvent('crew:onPlayerLoaded', GetPlayerServerId(PlayerId()))
		
		Citizen.Wait(4000)
		ShutdownLoadingScreen()
		ShutdownLoadingScreenNui()
		-- FreezeEntityPosition(PlayerPedId(), false)
		DoScreenFadeIn(10000)
		StartServerSyncLoops()
	-- end)

	TriggerEvent('esx:loadingScreenOff')
end)

RegisterNetEvent('esx:setMaxWeight')
AddEventHandler('esx:setMaxWeight', function(newMaxWeight) ESX.PlayerData.maxWeight = newMaxWeight end)

AddEventHandler('esx:onPlayerSpawn', function() isDead = false end)
AddEventHandler('esx:onPlayerDeath', function() isDead = true end)

AddEventHandler('skinchanger:modelLoaded', function()
	while not ESX.PlayerLoaded do
		Citizen.Wait(500)
	end
	modelLoaded = true
	TriggerEvent('esx:restoreLoadout')
end)

AddEventHandler('esx:restoreLoadout', function()
	local playerPed = PlayerPedId()
	local ammoTypes = {}
	RemoveAllPedWeapons(playerPed, true)

	for k,v in ipairs(ESX.PlayerData.loadout) do
		local weaponName = v.name
		local weaponHash = GetHashKey(weaponName)

		GiveWeaponToPed(playerPed, weaponHash, 0, false, false)
		SetPedWeaponTintIndex(playerPed, weaponHash, v.tintIndex)

		local ammoType = GetPedAmmoTypeFromWeapon(playerPed, weaponHash)

		for k2,v2 in ipairs(v.components) do
			local componentHash = ESX.GetWeaponComponent(weaponName, v2).hash
			GiveWeaponComponentToPed(playerPed, weaponHash, componentHash)
		end

		if not ammoTypes[ammoType] then
			AddAmmoToPed(playerPed, weaponHash, v.ammo)
			ammoTypes[ammoType] = true
		end
	end
end)

RegisterNetEvent('esx:setAccountMoney')
AddEventHandler('esx:setAccountMoney', function(account)
	for k,v in ipairs(ESX.PlayerData.accounts) do
		if v.name == account.name then
			ESX.PlayerData.accounts[k] = account
			break
		end
	end
end)

RegisterNetEvent('esx:addInventoryItem')
AddEventHandler('esx:addInventoryItem', function(item, count, showNotification)
	for k,v in ipairs(ESX.PlayerData.inventory) do
		if v.name == item then
			ESX.PlayerData.inventory[k].count = count
			break
		end
	end
end)

RegisterNetEvent('esx:removeInventoryItem')
AddEventHandler('esx:removeInventoryItem', function(item, count, showNotification)
	for k,v in ipairs(ESX.PlayerData.inventory) do
		if v.name == item then
			--ESX.UI.ShowInventoryItemNotification(false, v.label, v.count - count)
			ESX.PlayerData.inventory[k].count = count
			break
		end
	end
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
end)

-- RegisterNetEvent('esx:addWeapon')
-- AddEventHandler('esx:addWeapon', function(weaponName, ammo)
-- 	local playerPed = PlayerPedId()
-- 	local weaponHash = GetHashKey(weaponName)

-- 	GiveWeaponToPed(playerPed, weaponHash, ammo, false, false)
-- end)

-- RegisterNetEvent('esx:addWeaponComponent')
-- AddEventHandler('esx:addWeaponComponent', function(weaponName, weaponComponent)
-- 	local playerPed = PlayerPedId()
-- 	local weaponHash = GetHashKey(weaponName)
-- 	local componentHash = ESX.GetWeaponComponent(weaponName, weaponComponent).hash

-- 	GiveWeaponComponentToPed(playerPed, weaponHash, componentHash)
-- end)

-- RegisterNetEvent('esx:setWeaponAmmo')
-- AddEventHandler('esx:setWeaponAmmo', function(weaponName, weaponAmmo)
-- 	local playerPed = PlayerPedId()
-- 	local weaponHash = GetHashKey(weaponName)

-- 	SetPedAmmo(playerPed, weaponHash, weaponAmmo)
-- end)

RegisterNetEvent('esx:setWeaponTint')
AddEventHandler('esx:setWeaponTint', function(weaponName, weaponTintIndex)
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)

	SetPedWeaponTintIndex(playerPed, weaponHash, weaponTintIndex)
end)

RegisterNetEvent('esx:removeWeapon')
AddEventHandler('esx:removeWeapon', function(weaponName)
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)

	RemoveWeaponFromPed(playerPed, weaponHash)
	SetPedAmmo(playerPed, weaponHash, 0) -- remove leftover ammo
end)

RegisterNetEvent('esx:removeWeaponComponent')
AddEventHandler('esx:removeWeaponComponent', function(weaponName, weaponComponent)
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)
	local componentHash = ESX.GetWeaponComponent(weaponName, weaponComponent).hash

	RemoveWeaponComponentFromPed(playerPed, weaponHash, componentHash)
end)

RegisterNetEvent('esx:teleport')
AddEventHandler('esx:teleport', function(coords)
	local playerPed = PlayerPedId()

	-- ensure decmial number
	coords.x = coords.x + 0.0
	coords.y = coords.y + 0.0
	coords.z = coords.z + 0.0

	ESX.Game.Teleport(playerPed, coords)
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	if Config.EnableHud then
		ESX.UI.HUD.UpdateElement('job', {
			job_label = job.label,
			grade_label = job.grade_label
		})
	end
end)

RegisterNetEvent('esx:spawnVehicle')
AddEventHandler('esx:spawnVehicle', function(vehicleName)
	local model = (type(vehicleName) == 'number' and vehicleName or GetHashKey(vehicleName))

	if IsModelInCdimage(model) then
		local playerPed = PlayerPedId()
		local playerCoords, playerHeading = GetEntityCoords(playerPed), GetEntityHeading(playerPed)

		ESX.Game.SpawnVehicle(model, playerCoords, playerHeading, function(vehicle)
			TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
		end)
	else
		TriggerEvent('chat:addMessage', {args = {'^1SYSTEM', 'Invalid vehicle model.'}})
	end
end)

-- RegisterNetEvent('esx:createPickup')
-- AddEventHandler('esx:createPickup', function(pickupId, label, coords, type, name, components, tintIndex)
-- 	local function setObjectProperties(object)
-- 		SetEntityAsMissionEntity(object, true, false)
-- 		PlaceObjectOnGroundProperly(object)
-- 		FreezeEntityPosition(object, true)
-- 		SetEntityCollision(object, false, true)

-- 		pickups[pickupId] = {
-- 			obj = object,
-- 			label = label,
-- 			inRange = false,
-- 			coords = vector3(coords.x, coords.y, coords.z)
-- 		}
-- 	end

-- 	if type == 'item_weapon' then
-- 		local weaponHash = GetHashKey(name)
-- 		ESX.Streaming.RequestWeaponAsset(weaponHash)
-- 		local pickupObject = CreateWeaponObject(weaponHash, 50, coords.x, coords.y, coords.z, true, 1.0, 0)
-- 		SetWeaponObjectTintIndex(pickupObject, tintIndex)

-- 		for k,v in ipairs(components) do
-- 			local component = ESX.GetWeaponComponent(name, v)
-- 			GiveWeaponComponentToWeaponObject(pickupObject, component.hash)
-- 		end

-- 		setObjectProperties(pickupObject)
-- 	else
-- 		-- ESX.Game.SpawnLocalObject('prop_money_bag_01', coords, setObjectProperties)
-- 	end
-- end)

-- RegisterNetEvent('esx:createMissingPickups')
-- AddEventHandler('esx:createMissingPickups', function(missingPickups)
-- 	for pickupId,pickup in pairs(missingPickups) do
-- 		TriggerEvent('esx:createPickup', pickupId, pickup.label, pickup.coords, pickup.type, pickup.name, pickup.components, pickup.tintIndex)
-- 	end
-- end)

RegisterNetEvent('esx:registerSuggestions')
AddEventHandler('esx:registerSuggestions', function(registeredCommands)
	for name,command in pairs(registeredCommands) do
		if command.suggestion then
			TriggerEvent('chat:addSuggestion', ('/%s'):format(name), command.suggestion.help, command.suggestion.arguments)
		end
	end
end)

-- RegisterNetEvent('esx:removePickup')
-- AddEventHandler('esx:removePickup', function(pickupId)
-- 	if pickups[pickupId] and pickups[pickupId].obj then
-- 		ESX.Game.DeleteObject(pickups[pickupId].obj)
-- 		pickups[pickupId] = nil
-- 	end
-- end)

RegisterNetEvent('esx:deleteVehicle')
AddEventHandler('esx:deleteVehicle', function(radius)
	local playerPed = PlayerPedId()

	if radius and tonumber(radius) then
		radius = tonumber(radius) + 0.01
		local vehicles = ESX.Game.GetVehiclesInArea(GetEntityCoords(playerPed), radius)

		for k,entity in ipairs(vehicles) do
			local attempt = 0

			while not NetworkHasControlOfEntity(entity) and attempt < 100 and DoesEntityExist(entity) do
				Citizen.Wait(500)
				NetworkRequestControlOfEntity(entity)
				attempt = attempt + 1
			end

			if DoesEntityExist(entity) and NetworkHasControlOfEntity(entity) then
				ESX.Game.DeleteVehicle(entity)
			end
		end
	else
		local vehicle, attempt = ESX.Game.GetVehicleInDirection(), 0

		if IsPedInAnyVehicle(playerPed, true) then
			vehicle = GetVehiclePedIsIn(playerPed, false)
		end

		while not NetworkHasControlOfEntity(vehicle) and attempt < 100 and DoesEntityExist(vehicle) do
			Citizen.Wait(500)
			NetworkRequestControlOfEntity(vehicle)
			attempt = attempt + 1
		end

		if DoesEntityExist(vehicle) and NetworkHasControlOfEntity(vehicle) then
			ESX.Game.DeleteVehicle(vehicle)
		end
	end
end)

function StartServerSyncLoops()
	-- keep track of ammo
	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(500)

			if isDead then
				Citizen.Wait(500)
			else
				local playerPed = PlayerPedId()

				if IsPedShooting(playerPed) then
					local _,weaponHash = GetCurrentPedWeapon(playerPed, true)
					local weapon = ESX.GetWeaponFromHash(weaponHash)

					if weapon then
						local ammoCount = GetAmmoInPedWeapon(playerPed, weaponHash)
						TriggerServerEvent('esx:updateWeaponAmmo', weapon.name, ammoCount)
					end
				end
			end
		end
	end)

	-- sync current player coords with server
	Citizen.CreateThread(function()
		local previousCoords = vector3(ESX.PlayerData.coords.x, ESX.PlayerData.coords.y, ESX.PlayerData.coords.z)

		while true do
			Citizen.Wait(10000)
			local playerPed = PlayerPedId()

			if DoesEntityExist(playerPed) then
				local playerCoords = GetEntityCoords(playerPed)
				local distance = #(playerCoords - previousCoords)

				if distance > 1 then
					previousCoords = playerCoords
					local playerHeading = ESX.Math.Round(GetEntityHeading(playerPed), 1)
					local formattedCoords = {x = ESX.Math.Round(playerCoords.x, 1), y = ESX.Math.Round(playerCoords.y, 1), z = ESX.Math.Round(playerCoords.z, 1), heading = playerHeading}
					TriggerServerEvent('esx:updateCoords', formattedCoords)
				end
			end
		end
	end)
end

-- Pickups
-- Citizen.CreateThread(function()
-- 	while true do
-- 		Citizen.Wait(10)
-- 		local playerPed = PlayerPedId()
-- 		local playerCoords, letSleep = GetEntityCoords(playerPed), true
-- 		local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer(playerCoords)

-- 		for pickupId,pickup in pairs(pickups) do
-- 			local distance = #(playerCoords - pickup.coords)

-- 			if distance < 5 then
-- 				local label = pickup.label
-- 				letSleep = false

-- 				if distance < 1 then
-- 					if IsControlJustReleased(0, 38) then
-- 						if IsPedOnFoot(playerPed) and (closestDistance == -1 or closestDistance > 3) and not pickup.inRange then
-- 							pickup.inRange = true

-- 							local dict, anim = 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor'
-- 							ESX.Streaming.RequestAnimDict(dict)
-- 							TaskPlayAnim(playerPed, dict, anim, 8.0, 1.0, 1000, 16, 0.0, false, false, false)
-- 							Citizen.Wait(1000)

-- 							TriggerServerEvent('esx:onPickup', pickupId)
-- 							PlaySoundFrontend(-1, 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
-- 						end
-- 					end

-- 					label = ('%s~n~%s'):format(label, _U('threw_pickup_prompt'))
-- 				end

-- 				ESX.Game.Utils.DrawText3D({
-- 					x = pickup.coords.x,
-- 					y = pickup.coords.y,
-- 					z = pickup.coords.z + 0.25
-- 				}, label, 1.2, 1)
-- 			elseif pickup.inRange then
-- 				pickup.inRange = false
-- 			end
-- 		end

-- 		if letSleep then
-- 			Citizen.Wait(500)
-- 		end
-- 	end
-- end)
