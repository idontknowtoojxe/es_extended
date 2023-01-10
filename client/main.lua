local isPaused, isDead, pickups = false, false, {}
local modelLoaded = false


Citizen.CreateThread(function()
	while true do
		Citizen.Wait(100)

		if NetworkIsPlayerActive(PlayerId()) then
			TriggerServerEvent('esx:onPlayerJoined')
			break
		end
	end
end)

local firstConnect = true

AddEventHandler("playerSpawned", function(spawn)
	
	while not ESX.PlayerLoaded or not ESX.PlayerData do
		 Citizen.Wait(500)
		 print('Wait Load Model')
	end

	if not firstConnect then
		return
	end

	local playerData = ESX.PlayerData

    if firstConnect then
		firstConnect = false
		-- local elements = {{label = "ยืนยัน <strong class='blue-text'>ตัวละคร</strong> โหลดเสร็จแล้ว", value = '1' }}

		-- ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'xMaps', {
		-- 	title    = 'ระบบป้องกันตกแมพ [ ยืนยันเพื่อเข้าเกมส์ ]',
		-- 	align    = 'center',
		-- 	elements = elements
		-- }, function(data,menu)
		-- 	if data.current.value == '1' then
		-- 		menu.close()
		-- 		FreezeEntityPosition(PlayerPedId(), false)
		-- 	end
		-- end, function(data,menu)
		-- 	menu.close()
		-- 	FreezeEntityPosition(PlayerPedId(), false)
		-- end)
		Citizen.CreateThread(function ()
			local pressTime = 0
		
			FreezeEntityPosition(PlayerPedId(), true)
		
			while true do
				if IsControlPressed(0,32)then
					pressTime = pressTime + 1
				end
				if IsControlPressed(0,33)then
					pressTime = pressTime + 1
				end
				if IsControlPressed(0,34)then
					pressTime = pressTime + 1
				end
				if IsControlPressed(0,35)then
					pressTime = pressTime + 1
				end
				
				if IsControlReleased(0,32) and IsControlReleased(0,33) and IsControlReleased(0,34) and IsControlReleased(0,35) then
					pressTime = 0
				end
		
				if pressTime > 20 then
					isBreak = true
					FreezeEntityPosition(PlayerPedId(), false)
					break
				end
				
				Citizen.Wait(0)
			end
		end)
		
		ESX.Game.Teleport(PlayerPedId(), {
			x = playerData.coords.x,
			y = playerData.coords.y,
			z = playerData.coords.z + 0.25,
			heading = playerData.coords.heading
		}, function()
			TriggerServerEvent('esx:onPlayerSpawn')
			TriggerEvent('esx:onPlayerSpawn')
			TriggerEvent('playerSpawned') -- compatibility with old scripts, will be removed soon
			TriggerEvent('esx:restoreLoadout')
			Citizen.Wait(4000)
			ShutdownLoadingScreen()
			ShutdownLoadingScreenNui()
			
			DoScreenFadeIn(10000)
			StartServerSyncLoops()
		end)
		
		TriggerEvent('esx:loadingScreenOff')
    end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerData)
	ESX.PlayerLoaded = true
	ESX.PlayerData = playerData

	-- check if player is coming from loading screen
	if GetEntityModel(PlayerPedId()) == GetHashKey('PLAYER_ZERO') then
		local defaultModel = GetHashKey('mp_m_freemode_01')
		RequestModel(defaultModel)

		while not HasModelLoaded(defaultModel) do
			Citizen.Wait(10)
		end

		SetPlayerModel(PlayerId(), defaultModel)
		SetPedDefaultComponentVariation(PlayerPedId())
		SetPedComponentVariation(PlayerPedId(), true)
		SetModelAsNoLongerNeeded(defaultModel)
	end

	-- freeze the player
	-- FreezeEntityPosition(PlayerPedId(), true)

	-- enable PVP
	SetCanAttackFriendly(PlayerPedId(), true, false)
	NetworkSetFriendlyFireOption(true)

	-- disable wanted level
	ClearPlayerWantedLevel(PlayerId())
	SetMaxWantedLevel(0)

	Citizen.Wait(20000)
	local ped = PlayerPedId()    			-- ผู้เล่น
    local has = GetEntityModel(ped)    		-- เช็ค has model ของผู้เล่น
    if has == -1667301416 then        		-- ผู้หญิง
        if not IsEntityDead(ped) then    	-- เมื่อผู้เล่นไม่ได้ตาย
            SetPedMaxHealth(ped, 200)    	-- ตั้งค่าจำนวนเลือดสูงสุด = 200
            SetEntityHealth(ped, 200)    	-- เพิ่มเลือดให้ = 200
        end
	end
end)

--AddEventHandler('esx:onPlayerSpawn', function() isDead = false end)

AddEventHandler('esx:onPlayerSpawn', function()
	ESX.SetPlayerData('ped', PlayerPedId())
	ESX.SetPlayerData('dead', false)
	IsDead = false
end)

--AddEventHandler('esx:onPlayerDeath', function() isDead = true end)

AddEventHandler('esx:onPlayerSpawn', function() isDead = false end)
AddEventHandler('esx:onPlayerDeath', function()
	ESX.SetPlayerData('ped', PlayerPedId())
	ESX.SetPlayerData('dead', true)
	IsDead = true
end)

AddEventHandler('skinchanger:modelLoaded', function()
	while not ESX.PlayerLoaded do
		Citizen.Wait(100)
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

	-- if Config.EnableHud then
	-- 	ESX.UI.HUD.UpdateElement('account_' .. account.name, {
	-- 		money = ESX.Math.GroupDigits(account.money)
	-- 	})
	-- end
end)

RegisterNetEvent('esx:addInventoryItem')
AddEventHandler('esx:addInventoryItem', function(item, count, showNotification)
	local found = false
	
	for k,v in ipairs(ESX.PlayerData.inventory) do
		if v.name == item then
			--ESX.UI.ShowInventoryItemNotification(true, v.label, count - v.count)
			ESX.PlayerData.inventory[k].count = count

			found = true
			break
		end
	end

	if showNotification then
		--ESX.UI.ShowInventoryItemNotification(true, item, count)
	end

	if ESX.UI.Menu.IsOpen('default', 'es_extended', 'inventory') then
		ESX.ShowInventory()
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

	if showNotification then
		--ESX.UI.ShowInventoryItemNotification(false, item, count)
	end

	if ESX.UI.Menu.IsOpen('default', 'es_extended', 'inventory') then
		ESX.ShowInventory()
	end
end)


RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
end)

RegisterNetEvent('esx:addWeapon')
AddEventHandler('esx:addWeapon', function(weaponName, ammo)
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)

	GiveWeaponToPed(playerPed, weaponHash, ammo, false, false)
end)

RegisterNetEvent('esx:addWeaponComponent')
AddEventHandler('esx:addWeaponComponent', function(weaponName, weaponComponent)
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)
	local componentHash = ESX.GetWeaponComponent(weaponName, weaponComponent).hash

	GiveWeaponComponentToPed(playerPed, weaponHash, componentHash)
end)

RegisterNetEvent('esx:setWeaponAmmo')
AddEventHandler('esx:setWeaponAmmo', function(weaponName, weaponAmmo)
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)

	SetPedAmmo(playerPed, weaponHash, weaponAmmo)
end)

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
-- 		ESX.Game.SpawnLocalObject('prop_money_bag_01', coords, setObjectProperties)
-- 	end
-- end)

RegisterNetEvent('esx:createMissingPickups')
AddEventHandler('esx:createMissingPickups', function(missingPickups)
	for pickupId,pickup in pairs(missingPickups) do
		TriggerEvent('esx:createPickup', pickupId, pickup.label, pickup.coords, pickup.type, pickup.name, pickup.components, pickup.tintIndex)
	end
end)

RegisterNetEvent('esx:registerSuggestions')
AddEventHandler('esx:registerSuggestions', function(registeredCommands)
	for name,command in pairs(registeredCommands) do
		if command.suggestion then
			TriggerEvent('chat:addSuggestion', ('/%s'):format(name), command.suggestion.help, command.suggestion.arguments)
		end
	end
end)

RegisterNetEvent('esx:removePickup')
AddEventHandler('esx:removePickup', function(pickupId)
	if pickups[pickupId] and pickups[pickupId].obj then
		ESX.Game.DeleteObject(pickups[pickupId].obj)
		pickups[pickupId] = nil
	end
end)

RegisterNetEvent('esx:deleteVehicle')
AddEventHandler('esx:deleteVehicle', function(radius)
	local playerPed = PlayerPedId()

	if radius and tonumber(radius) then
		radius = tonumber(radius) + 0.01
		local vehicles = ESX.Game.GetVehiclesInArea(GetEntityCoords(playerPed), radius)

		for k,entity in ipairs(vehicles) do
			local attempt = 0

			while not NetworkHasControlOfEntity(entity) and attempt < 100 and DoesEntityExist(entity) do
				Citizen.Wait(100)
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
			Citizen.Wait(100)
			NetworkRequestControlOfEntity(vehicle)
			attempt = attempt + 1
		end

		if DoesEntityExist(vehicle) and NetworkHasControlOfEntity(vehicle) then
			ESX.Game.DeleteVehicle(vehicle)
		end
	end
end)

-- Pause menu disables HUD display
-- if Config.EnableHud then
-- 	Citizen.CreateThread(function()
-- 		while true do
-- 			Citizen.Wait(300)

-- 			if IsPauseMenuActive() and not isPaused then
-- 				isPaused = true
-- 				ESX.UI.HUD.SetDisplay(0.0)
-- 			elseif not IsPauseMenuActive() and isPaused then
-- 				isPaused = false
-- 				ESX.UI.HUD.SetDisplay(1.0)
-- 			end
-- 		end
-- 	end)

-- 	AddEventHandler('esx:loadingScreenOff', function()
-- 		ESX.UI.HUD.SetDisplay(1.0)
-- 	end)
-- end

function StartServerSyncLoops()
	-- keep track of ammo
	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(100)

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
			--local rdm = math.random(1000, 10000)
			Citizen.Wait(10000)
			local playerPed = PlayerPedId()

			if DoesEntityExist(playerPed) then
				local playerCoords = GetEntityCoords(playerPed)
				local distance = #(playerCoords - previousCoords)

				if distance > 1 then
					previousCoords = playerCoords
					--local playerHeading = ESX.Math.Round(GetEntityHeading(playerPed), 1)
					--local formattedCoords = {x = ESX.Math.Round(playerCoords.x, 1), y = ESX.Math.Round(playerCoords.y, 1), z = ESX.Math.Round(playerCoords.z, 1), heading = playerHeading}
					--TriggerServerEvent('esx:updateCoords', formattedCoords)
					TriggerServerEvent('esx:updateCoords')
				end
			end
		end
	end)
end

-- Citizen.CreateThread(function()
-- 	while true do
-- 		Citizen.Wait(0)

-- 		if IsControlJustReleased(0, 289) then
-- 			if IsInputDisabled(0) and not isDead and not ESX.UI.Menu.IsOpen('default', 'es_extended', 'inventory') then
-- 				ESX.ShowInventory()
-- 			end
-- 		end
-- 	end
-- end)

-- -- Pickups
-- Citizen.CreateThread(function()
-- 	while true do
-- 		Citizen.Wait(0)
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
--[[
RegisterNetEvent('esx:GetPlayerCoords')
AddEventHandler('esx:GetPlayerCoords', function()
	local p = PlayerPedId()
	local c = GetEntityCoords(p)
	local h = GetEntityHeading(p)
	print('X =',c.x, 'Y =',c.y ,'Z =',c.z, 'H =',h)
end)
]]

--[[
RegisterNetEvent("esx:tpm")
AddEventHandler("esx:tpm", function()
    local WaypointHandle = GetFirstBlipInfoId(8)
    if DoesBlipExist(WaypointHandle) then
        local waypointCoords = GetBlipInfoIdCoord(WaypointHandle)

        for height = 1, 1000 do
            SetPedCoordsKeepVehicle(PlayerPedId(), waypointCoords["x"], waypointCoords["y"], height + 0.0)

            local foundGround, zPos = GetGroundZFor_3dCoord(waypointCoords["x"], waypointCoords["y"], height + 0.0)

            if foundGround then
                SetPedCoordsKeepVehicle(PlayerPedId(), waypointCoords["x"], waypointCoords["y"], height + 0.0)

                break
            end

            Citizen.Wait(5)
        end
        ESX.ShowNotification('teleported')
    else
        ESX.ShowNotification('set_waypoint')
    end
end)
]]
--[[
RegisterNetEvent("esx_admin:killPlayer")
AddEventHandler("esx_admin:killPlayer", function()
  SetEntityHealth(PlayerPedId(), 0)
  --TriggerEvent('ENS_inventoryhud:closeInventory')
end)
]]
--[[
RegisterNetEvent("esx_admin:freezePlayer")
AddEventHandler("esx_admin:freezePlayer", function(input)
    local player = PlayerId()
	local ped = PlayerPedId()
    if input == 'freeze' then
        SetEntityCollision(ped, false)
        FreezeEntityPosition(ped, true)
        SetPlayerInvincible(player, true)
    elseif input == 'unfreeze' then
        SetEntityCollision(ped, true)
	    FreezeEntityPosition(ped, false)
        SetPlayerInvincible(player, false)
    end
end)
]]