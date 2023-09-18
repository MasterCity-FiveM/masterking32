ESX = nil
local starttick, tick, maxPlayers = GetGameTimer(), GetGameTimer() ,GetConvarInt('sv_maxclients', 1024)

-- DDOS--
local UserTriggers, DDoS_TIME = {}, 5 -- sec
-- DDOS--

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

while ESX == nil do
	Citizen.Wait(0)
end
		
-- DDOS --
ESX.AddCustomFunction("anti_ddos", function(source, name, data)
	Citizen.CreateThread(function()
		if not name then
			if source then
				print ('[MasterkinG32 Anti DDoser]: Name is empty! - Source: ' .. source)
				return
			end
			
			print ('[MasterkinG32 Anti DDoser]: Name is empty!')
			return
		end

		if not source then
			print ('[MasterkinG32 Anti DDoser]: User is empty! - ' .. name)
			return
		end

		name = name:gsub(":", "_")
		if not Config.TriggerList[name] then
			print ('[MasterkinG32 Anti DDoser]: Cant Find The Trigger Count - ' .. name)
			return
		end

		local xPlayer = ESX.GetPlayerFromId(source)

		if not xPlayer or xPlayer.identifier == nil then
			print ('[MasterkinG32 Anti DDoser]: Player is not exists - Trigger: ' .. name)
			return
		end
		
		identifierArName = xPlayer.identifier:gsub(":", "")
		
		if UserTriggers[identifierArName] == nil then
			UserTriggers[identifierArName] = {}
		end

		local TimeNow = os.time()

		if UserTriggers[identifierArName][name] == nil then
			UserTriggers[identifierArName][name] = {count = 0, time = TimeNow + DDoS_TIME}
		end 
		
		local old_count = UserTriggers[identifierArName][name].count
		UserTriggers[identifierArName][name].count = old_count + 1

		if UserTriggers[identifierArName][name].count > Config.TriggerList[name] and UserTriggers[identifierArName][name].time > TimeNow then
			print('[MasterkinG32 Anti DDoser]: ' .. xPlayer.identifier .. ' Kicked from the server, using: ' .. name)
			if data ~= nil then
				ESX.RunCustomFunction("discord", xPlayer.source, 'ddos', 'Anti DDoS Kick.', 'Trigger: **'..name..'**\nParameters: **'..json.encode(data)..'**')
			else
				ESX.RunCustomFunction("discord", xPlayer.source, 'ddos', 'Anti DDoS Kick.', 'Trigger: **'..name..'**')
			end
			showMessage('Spammer Detected, Please check anti_ddos logs.')
			
			playerID = xPlayer.source
			Citizen.Wait(100)
			DropPlayer(playerID, ('\n❌ MasterCity Warden ❌\n⚠ Something is Wrong with You!\n🌐 SteamHex: %s\n📞 Discord: Discord.MasterCity.iR\n💫 If you Think It\'s a Mistake, Contact us.'):format(xPlayer.identifier))
			UserTriggers[identifierArName][name] = {count = 1, time = TimeNow + DDoS_TIME}
		elseif UserTriggers[identifierArName][name].time < TimeNow then
			UserTriggers[identifierArName][name] = nil
			UserTriggers[identifierArName][name] = {count = 1, time = TimeNow + DDoS_TIME}
		end
	end)
end)

local UnderShowMessage = false
function showMessage(Msg)
	Citizen.CreateThread(function()
		if UnderShowMessage == false then
			UnderShowMessage = true
			Citizen.CreateThread(function()
				local xAll = ESX.GetPlayers()
				for i=1, #xAll, 1 do
					local xTarget = ESX.GetPlayerFromId(xAll[i])
					if xTarget and xTarget.getRank() > 0 then
						TriggerClientEvent("pNotify:SendNotification", xTarget.source, { text = 'Master Warden: ' .. Msg, type = "error", timeout = 5000, layout = "centerLeft"})
						TriggerClientEvent('chatMessageError', xTarget.source, 'Master Warden', Msg)
					end
				end
				
				Citizen.Wait(150)
				UnderShowMessage = false
			end)
		end
	end)
end
-- DDOS --

LastMessage = {}
LastMessage.content = 0
LastMessage.time = 0
-- DISCORD --
ESX.AddCustomFunction("discord", function(source, webhook, title, message, color)
	Citizen.CreateThread(function()
		if not source or not webhook then
			print('[Discord Webhook]: Something is empty!')
			return
		end
		
		if not Config.DiscordChannels[webhook] then
			print('[Discord Webhook]: Cant Find - ' .. webhook)
			return
		end
		
		 
		if not color then
			color = "8663711"
		end
		
		local xPlayer = ESX.GetPlayerFromId(source)

		if not xPlayer or xPlayer.identifier == nil then
			print ('[Discord Webhook]: Player is not exists -' .. source)
			return
		end
		
		local name = '(' .. source .. ')'
		
		if GetPlayerName(source) ~= nil then
			name = GetPlayerName(source) .. name
		end
		
		--local name = xPlayer.firstname .. ' ' .. xPlayer.lastname
		if xPlayer.firstname ~= nil and xPlayer.lastname ~= nil then
			name = name .. ' **\nIC Name: **' .. xPlayer.firstname .. '_' .. xPlayer.lastname
		end
		
		--local ip = GetPlayerEndpoint(source)
		local ping = GetPlayerPing(source)
		local steamhex = xPlayer.identifier
		local steamid  = false
		local discord  = false

		for k,v in pairs(GetPlayerIdentifiers(source))do
			
			if string.sub(v, 1, string.len("steam:")) == "steam:" then
				steamid = v
			elseif string.sub(v, 1, string.len("discord:")) == "discord:" then
				discord = v
			end
		end
		
		if discord ~= false then
			_discordID ="\n**Discord ID:  ** <@" .. discord:gsub("discord:", "") ..">"
		else
			_discordID = ""
		end
		
		if steamid ~= false then
			_steamURL ="\n **Steam Url  **https://steamcommunity.com/profiles/" ..tonumber(steamid:gsub("steam:", ""),16)..""
		else
			_steamURL = "\nSteam URL: NotFound((Player Cannot Connect⛔))"
		end
	
		local content = "Player: **" .. name .. "**\nSteam Hex: **" .. steamhex .. _discordID .. _steamURL .. "**"
		
		if message ~= nil and message ~= "" then
			content = "Player: **" .. name .. "**\nSteam Hex: **" .. steamhex .. _discordID .. _steamURL .. "**\n\n" .. message
		end
		
		local connect = {
			{
				["color"] = color,
				["title"] = title,
				["description"] = content,
			}
		}
		
		tmpContent = source .. webhook .. title .. message .. color .. content
		
		if not (tmpContent == LastMessage.content and os.time() <= LastMessage.time) then
			LastMessage.content = tmpContent
			LastMessage.time = os.time() + 2
			PerformHttpRequest(Config.DiscordChannels[webhook], function(err, text, headers) end, 'POST', json.encode({username = "MasterCity.iR", embeds = connect}), { ['Content-Type'] = 'application/json' })
		end
	end)
end)

ESX.AddCustomFunction("discordmsg", function(webhook, title, message, color)
	Citizen.CreateThread(function()
		if not webhook or not message then
			return
		end
		
		if not color then
			color = "8663711"
		end
		
		if not Config.DiscordChannels[webhook] then
			print('[Discord Webhook]: Cant Find - ' .. webhook)
			return
		end

		local connect = {
			{
				["color"] = color,
				["title"] = title,
				["description"] = message,
			}
		}
		
		PerformHttpRequest(Config.DiscordChannels[webhook], function(err, text, headers) end, 'POST', json.encode({username = "MasterCity.iR", embeds = connect}), { ['Content-Type'] = 'application/json' })
	end)
end)
-- DISCORD --

AddEventHandler('playerDropped', function(reason)
	local steamid  = false
	local discord  = false
	
    for k,v in pairs(GetPlayerIdentifiers(source))do
	  if string.sub(v, 1, string.len("steam:")) == "steam:" then
		steamid = v
	  elseif string.sub(v, 1, string.len("discord:")) == "discord:" then
		discord = v
	  end
    end
	
	if discord ~= false then
		_discordID ="\n**Discord ID:  ** <@" .. discord:gsub("discord:", "") ..">"
	else
		_discordID = ""
	end
	
	if steamid ~= false then
		_steamURL ="\n **Steam Url  **https://steamcommunity.com/profiles/" ..tonumber(steamid:gsub("steam:", ""),16)..""
	else
		_steamURL = "\nSteam URL: NotFound((Player Cannot Connect⛔))"
	end
	
	local name = GetPlayerName(source)
	local steamhex = GetPlayerIdentifier(source)
	if steamhex == nil then
		steamhex = 'n/a'
	end
	ESX.RunCustomFunction("discordmsg", 'disconnect', 'Player Disconnected.', "Player: **"..name.."** \nSteam Hex: **"..steamhex.._discordID.._steamURL.."**\nReason: **"..reason.."**")
end)

Citizen.CreateThread(function()
	ESX.RegisterServerCallback('masterking32:get_server_uptime', function(cb)
		cb(tick - starttick)
	end)
	
	ESX.RegisterServerCallback('masterking32:getMaxPlayers', function(source, cb)
		cb(maxPlayers)
	end)
end)

Citizen.CreateThread(function()
	ExecuteCommand(string.format("sets \"Developer & Founder\" \"Amin.MasterkinG\""))
	ExecuteCommand(string.format("sets Website \"https://mastercity.ir\""))
	ExecuteCommand(string.format("sets Discord \"https://discord.mastercity.ir\""))
		
	while true do
		Citizen.Wait(15000) -- check all 15 seconds
		
		local xAll = ESX.GetPlayers()
		if #xAll > 0 then
			TriggerClientEvent('masterking32:PlayersCount', -1, #xAll)
		end
		
		tick = GetGameTimer()
		uptimeDay = math.floor((tick-starttick)/86400000)
        uptimeHour = math.floor((tick-starttick)/3600000) % 24
		uptimeMinute = math.floor((tick-starttick)/60000) % 60
		uptimeSecond = math.floor((tick-starttick)/1000) % 60
		ExecuteCommand(string.format("sets Uptime \"%2d Days %2d Hours %2d Minutes %2d Seconds\"", uptimeDay, uptimeHour, uptimeMinute, uptimeSecond))
		
		uptime = string.format("%02dd %02dh %02dm",uptimeDay, uptimeHour, uptimeMinute)
		TriggerClientEvent('uptime:tick', -1, uptime)
		TriggerEvent('uptime:tick', uptime)
	end
end)

Citizen.CreateThread(function()
	local starttick = GetGameTimer()
	while true do
		-- Check the weather and time.
		PerformHttpRequest('http://mastercity.ir/files/api/weather.php', function(err, text, headers) 
			local json_data = json.decode(text)
			if json_data and json_data.hour and json_data.minute and json_data.weather then
				TriggerEvent('vSync:setTime', json_data.hour, json_data.minute)
				TriggerEvent('vSync:setWeather', json_data.weather)
			end
		end, 'POST', json.encode({}), { ['Content-Type'] = 'application/json' })
		Citizen.Wait(180000) -- 3 minutes
	end
end)
