local max_Players = 1024
ESX = nil
PlayerData = nil
local crouched = false
local SafeZones = {
	--{radius = 35.0, coords = { ['x'] = 228.356, ['y'] = -778.378, ['z'] = 28.72888}}, -- parking
	{radius = 35.0, coords = { ['x'] = 445.2132, ['y'] = -989.4857, ['z'] = 28.43152}},
	{radius = 65.0, coords = { ['x'] = 314.6374, ['y'] = -591.2571, ['z'] = 15.2821}},
	{radius = 35.0, coords = { ['x'] = -355.622, ['y'] = -123.8505, ['z'] = 37.42346}},
	{radius = 35.0, coords = { ['x'] = 1851.02, ['y'] = 3672.198, ['z'] = 32.7113}},
	{radius = 35.0, coords = { ['x'] = 249.3363, ['y'] = -1090.615, ['z'] = 28.82495}},
	{radius = 35.0, coords = { ['x'] = 695.1165, ['y'] = 138.0264, ['z'] = 80.73926}},
	{radius = 50.0, coords = { ['x'] = -265.3978, ['y'] = -963.2044, ['z'] = 31.21753}}, -- job center 
}

local notifIn,closestZone = 1

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
	
	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(100)
	end

	PlayerData = ESX.GetPlayerData()
	
	ESX.TriggerServerCallback('masterking32:getMaxPlayers', function(maxPlayers)
		max_Players = maxPlayers
	end)
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job
end)

RegisterNetEvent('masterking32:SeatDriver')
AddEventHandler('masterking32:SeatDriver', function(location)
	local ped = GetPlayerPed( -1 )
	if IsPedInAnyVehicle(ped, false) then
		local veh = GetVehiclePedIsIn(ped, false)
		location = tonumber(location)
		if IsVehicleSeatFree(veh, location) then
			Seatdisabled = false
			Citizen.Wait(100)
			SetPedIntoVehicle(PlayerPedId(), veh, location)
			Citizen.Wait(100)
			Seatdisabled = true
		else
			exports.pNotify:SendNotification({text = "یک نفر پشت فرمون هست!", type = "info", timeout = 2500})
		end
	end
end)
disableShuffle = true

local Seatdisabled = false
Citizen.CreateThread(function()
	while not NetworkIsPlayerActive(PlayerId()) do
		Citizen.Wait(0)
	end
	
	while true do
        PedID = PlayerId()
		local ped = GetPlayerPed( -1 )
	    Citizen.Wait(0)
		-- Seat change
        if IsPedInAnyVehicle(ped, false) and not Seatdisabled then
            local veh = GetVehiclePedIsIn(ped, false)
            if GetPedInVehicleSeat(veh, 0) == ped then
				CanShuffleSeat(veh, false)
                if  GetIsTaskActive(ped, 165) then
                    SetPedIntoVehicle(PlayerPedId(), veh, 0)
                end
            end
			
			if GetPedInVehicleSeat(GetVehiclePedIsIn(GetPlayerPed(-1), false), 0) == GetPlayerPed(-1) and disableShuffle then
				if GetIsTaskActive(GetPlayerPed(-1), 165) then
					SetPedIntoVehicle(GetPlayerPed(-1), GetVehiclePedIsIn(GetPlayerPed(-1), false), 0)
				end
			end
        end
		
		-- disable PEDS
	    SetVehicleDensityMultiplierThisFrame(0.0) -- removes people walking around
        SetPedDensityMultiplierThisFrame(0.0) -- remove vehicles driving
		if GetPlayerWantedLevel(PlayerId()) ~= 0 then
            SetPlayerWantedLevel(PlayerId(), 0, false)
            SetPlayerWantedLevelNow(PlayerId(), false)
        end
		
		SetRandomVehicleDensityMultiplierThisFrame(0.0)
		SetParkedVehicleDensityMultiplierThisFrame(0.0)
		SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
		local x,y,z = table.unpack(GetEntityCoords(PlayerPedId()))
		ClearAreaOfVehicles(x, y, z, 1000, false, false, false, false, false)
		RemoveVehiclesFromGeneratorsInArea(x - 500.0, y - 500.0, z - 500.0, x + 500.0, y + 500.0, z + 500.0);
		
		-- These natives do not have to be called everyframe.
		SetGarbageTrucks(0)
		SetRandomBoats(0)
		SetCreateRandomCops(false) -- disable random cops walking/driving around.
		SetCreateRandomCopsNotOnScenarios(false) -- stop random cops (not in a scenario) from spawning.
		SetCreateRandomCopsOnScenarios(false) -- stop random cops (in a scenario) from spawning.
		
		for i = 1, 12 do
			EnableDispatchService(i, false)
		end
		
		if (DoesEntityExist(ped) and not IsEntityDead(ped)) then 
            DisableControlAction(0, 36, true) -- INPUT_DUCK  
            if (not IsPauseMenuActive()) then
                if (IsDisabledControlJustPressed(0, 36)) then 
                    RequestAnimSet( "move_ped_crouched" )
                    while (not HasAnimSetLoaded("move_ped_crouched")) do 
                        Citizen.Wait(100)
                    end 
                    if(crouched == true) then 
                        ResetPedMovementClipset(ped, 0)
                        crouched = false 
                    elseif (crouched == false) then
                        SetPedMovementClipset(ped, "move_ped_crouched", 0.2)
                        crouched = true 
                    end 
                end
            end 
        end 
		if IsPedArmed(ped, 6) then
			DisableControlAction(1, 140, true)
            DisableControlAction(1, 141, true)
			DisableControlAction(1, 142, true)
        end
		-- Car rewards.
		DisablePlayerVehicleRewards(PedID)
		-- SafeZone
		if PlayerData ~= nil and PlayerData.job ~= nil and PlayerData.job.name ~= nil and PlayerData.job.name ~= 'police' and PlayerData.job.name ~= 'sheriff' then
			local player = GetPlayerPed(-1)
			local x,y,z = table.unpack(GetEntityCoords(player, true))
			local dist = Vdist(SafeZones[closestZone].coords.x, SafeZones[closestZone].coords.y, SafeZones[closestZone].coords.z, x, y, z)
			if dist <= SafeZones[closestZone].radius then  ------------------------------------------------------------------------------ Here you can change the RADIUS of the Safe Zone. Remember, whatever you put here will DOUBLE because 
				if not notifIn then																			  -- it is a sphere. So 50 will actually result in a diameter of 100. I assume it is meters. No clue to be honest.
					--NetworkSetFriendlyFireOption(false)
					ClearPlayerWantedLevel(PlayerId())
					SetCurrentPedWeapon(player,GetHashKey("WEAPON_UNARMED"),true)
					exports.pNotify:SendNotification({text = "شما در یک منطقه امن هستید!", type = "info", timeout = 2500})
				end
				notifIn = true
			else
				if notifIn then
					--NetworkSetFriendlyFireOption(true)
					TriggerEvent("holstersweapon:ForceStop")
					exports.pNotify:SendNotification({text = "شما دیگر داخل مکان امن نیستید.", type = "info", timeout = 2500})
				end
				notifIn = false
			end
			
			if notifIn then
				SetWeaponDamageModifier(-1553120962, 0.0)
				DisableControlAction(2, 37, true) -- disable weapon wheel (Tab)
				DisableControlAction(2, 45, true) -- disable weapon wheel (R)
				DisablePlayerFiring(player,true) -- Disables firing all together if they somehow bypass inzone Mouse Disable
				DisableControlAction(0, 106, true) -- Disable in-game mouse controls
				if IsDisabledControlJustPressed(2, 37) or IsDisabledControlJustPressed(0, 106) then --if Tab is pressed, send error message
					SetCurrentPedWeapon(player,GetHashKey("WEAPON_UNARMED"),true) -- if tab is pressed it will set them to unarmed (this is to cover the vehicle glitch until I sort that all out)
					--exports.pNotify:SendNotification({text = "شما نمی توانید این کار را در این منطقه انجام دهید!", type = "error", timeout = 2500})
				end
			else
				SetWeaponDamageModifier(-1553120962, 0.4)
			end
		end
	end
end)

local OnlinePlayers = 0
RegisterNetEvent('masterking32:PlayersCount')
AddEventHandler('masterking32:PlayersCount', function(playerCounts)
	OnlinePlayers = playerCounts
end)

Citizen.CreateThread(function()
	while true do		
		SetDiscordAppId(815301542332203059)

		SetDiscordRichPresenceAsset('mc')
		
		SetRichPresence('Players: ' .. OnlinePlayers .. '/ 128')
   
        SetDiscordRichPresenceAssetText('MasterCity.iR')
		
		SetDiscordRichPresenceAction(0, "💫 ・ Connect ・ 💫", "fivem://connect/play.mastercity.ir")
        SetDiscordRichPresenceAction(1, "🌐 ・ Website ・ 🌐", "https://MasterCity.iR")
	
		-- Start SafeZone
		local playerPed = GetPlayerPed(-1)
		local x, y, z = table.unpack(GetEntityCoords(playerPed, true))
		local minDistance = 100000
		for i = 1, #SafeZones, 1 do
			dist = Vdist(SafeZones[i].coords.x, SafeZones[i].coords.y, SafeZones[i].coords.z, x, y, z)
			if dist < minDistance then
				minDistance = dist
				closestZone = i
			end
		end
		-- End SafeZone
		Citizen.Wait(15000)
	end
end)