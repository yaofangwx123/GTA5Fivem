
RegisterNetEvent("xp:aaatest",function(param)

	--print("xp:aaatest",param,source)
	--local dataType = {withdraw = 106,label = "HOSPITAL"}
	--TriggerEvent("esx_banking:doingType",source,dataType)
	
	--local allve = GetAllVehicles()
	--print("allvehicles",ESX.DumpTable(allve))
	
	   local xPlayer = ESX.GetPlayerFromId(source)
	
		Citizen.CreateThread(function()
		
				--xPlayer.addAccountMoney('money', 10000, "Paycheck")
				
				--Wait(2000)
				--xPlayer.addAccountMoney('bank', 10000, "Paycheck")
				
				--print("now",ESX.DumpTable(xPlayer.getInventory(false)))
		
		end)
	
	
	
end)



--增加钱的时候调用


--[[RegisterNetEvent("esx:addAccountMoney",function(source,accountName, money, reason)
    
	    if(accountName ~= "bank" or reason == "unknown") then return end
	  
	    local source = source
		local xPlayer = ESX.GetPlayerFromId(source)
		local identifier = xPlayer.getIdentifier()
		local bankMoney = xPlayer.getAccount('bank').money
		
		
	
	
	   local id = MySQL.insert.await('INSERT INTO banking (identifier, label, type, amount, time, balance) VALUES (?, ?, ?, ?, ?, ?)',{identifier,reason,"DEPOSIT",money, os.time() * 1000, bankMoney + money})
 
       print("xpclient savemoney = ",money,reason)
	  
	
end)]]




--[[RegisterNetEvent('xp:isCanDrive', function(source,cb,vehicle, plate, seat, displayName, netId)
    print('xp:isCanDrive', 'vehicle', vehicle, 'plate', plate, 'seat', seat, 'displayName', displayName, 'netId', netId,"source ",source)
	
	   
     TriggerEvent('esx_license:getLicenses',source, function(result)
	 
	 print(ESX.DumpTable(result))
	 
	 local hasDmv,hasDrive = false,false
	 for k,v in ipairs(result) do
		if(v["type"]=="dmv") then
			hasDmv = true
		elseif(v["type"]=="drive") then
			hasDrive = true
		end	
	 
	 end
	 
	 cb(hasDmv,hasDrive)

	end)
	
end)]]


ESX.RegisterServerCallback('xp:spwanVehicle', function(source,cb,vehicle)
    print('xp:spwanVehicle', 'vehicle',vehicle.plate)
	
			local vehData = {
			model = vehicle.vehicle.model,
			coords = vec3(vehicle.position.x,vehicle.position.y,vehicle.position.z),
			props = {plate = vehicle.plate}
			}
			

			ESX.OneSync.SpawnVehicle(vehicle.vehicle.model,vec3(vehicle.position.x,vehicle.position.y,vehicle.position.z), vehicle.position.heading, vehicle.properties, function(NetworkId)
			  Wait(500) -- While not needed, it is best to wait a few milliseconds to ensure the vehicle is available
			  local Vehicle = NetworkGetEntityFromNetworkId(NetworkId) -- returns the vehicle handle, from the NetworkId.
			  -- NetworkId is sent over, since then it can also be sent to a client for them to use, vehicle handles cannot.
			  local Exists = DoesEntityExist(NetworkId) -- returns true/false depending on if the vehicle exists.
			  print(Exists and 'Successfully Spawned Vehicle!' or 'Failed to Spawn Vehicle!')
			  cb(Exists,NetworkId)
			end)
	
end)

RegisterNetEvent('esx:setAccountMoney', function(player, accountName, money, reason)
    print(player, ' moneynet is: ', money,'reason:', reason,"accountName",accountName)
	
end)

RegisterNetEvent('esx:playerLoaded', function(player, xPlayer, isNew)
  print(player, 'loaded', xPlayer.getName())
  print('isNew:', isNew)
  if(xPlayer.getAccount("money").money ==0 and xPlayer.getAccount("bank").money == 0) then
	print("The player no money")
  end
end)

RegisterNetEvent('xp:server:clientKillPed', function()
    print("source",source)
	local xPlayer = ESX.GetPlayerFromId(source)
	if(xPlayer.getAccount("money").money ==0 and xPlayer.getAccount("bank").money == 0) then
		print("xp:server:clientKillPed with no money")
		xPlayer.kick(TranslateCap("kick_noMoneyKillPed"))
  end
end)







