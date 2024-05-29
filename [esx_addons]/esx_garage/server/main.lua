RegisterServerEvent('esx_garage:updateOwnedVehicle')
AddEventHandler('esx_garage:updateOwnedVehicle', function(stored, parking, Impound, data, spawn)
	local source = source
	local xPlayer  = ESX.GetPlayerFromId(source)
		MySQL.update('UPDATE owned_vehicles SET `stored` = @stored, `parking` = @parking, `pound` = @Impound, `vehicle` = @vehicle WHERE `plate` = @plate AND `owner` = @identifier',
		{
			['@identifier'] = xPlayer.identifier,
			['@vehicle'] 	= json.encode(data.vehicleProps),
			['@plate'] 		= data.vehicleProps.plate,
			['@stored']     = stored,
			['@parking']    = parking,
			['@Impound']    	= Impound
		})

		if stored then
			xPlayer.showNotification(TranslateCap('veh_stored'))
		else 
			ESX.OneSync.SpawnVehicle(data.vehicleProps.model, spawn, data.spawnPoint.heading,data.vehicleProps, function(vehicle)
				local vehicle = NetworkGetEntityFromNetworkId(vehicle)
				Wait(300)
				TaskWarpPedIntoVehicle(GetPlayerPed(source), vehicle, -1)
			end)
		end
end)

RegisterServerEvent('esx_garage:setImpound')
AddEventHandler('esx_garage:setImpound', function(Impound, vehicleProps)
	local source = source
	local xPlayer  = ESX.GetPlayerFromId(source)

		MySQL.update('UPDATE owned_vehicles SET `stored` = @stored, `pound` = @Impound, `vehicle` = @vehicle WHERE `plate` = @plate AND `owner` = @identifier',
		{
			['@identifier'] = xPlayer.identifier,
			['@vehicle'] 	= json.encode(vehicleProps),
			['@plate'] 		= vehicleProps.plate,
			['@stored']     = 2,
			['@Impound']    	= Impound
		})

		xPlayer.showNotification(TranslateCap('veh_impounded'))
end)


ESX.RegisterServerCallback('esx_garage:getVehiclesInParking', function(source, cb, parking)
	local xPlayer  = ESX.GetPlayerFromId(source)

	MySQL.query('SELECT * FROM `owned_vehicles` WHERE `owner` = @identifier AND `parking` = @parking AND `stored` = 1',
	{
		['@identifier'] 	= xPlayer.identifier,
		['@parking']     	= parking
	}, function(result)

		local vehicles = {}
		for i = 1, #result, 1 do
			table.insert(vehicles, {
				vehicle 	= json.decode(result[i].vehicle),
				plate 		= result[i].plate
			})
		end

		cb(vehicles)
	end)
end)

local function checkVehicleOwner(source,cb,plate)

	 local xPlayer = ESX.GetPlayerFromId(source)
	print("plate:",plate,source)
	MySQL.query('SELECT COUNT(*) as count FROM `owned_vehicles` WHERE `owner` = @identifier AND `plate` = @plate',
	{
		['@identifier'] 	= xPlayer.identifier,
		['@plate']     		= plate
	}, function(result)

		if tonumber(result[1].count) > 0 then
			return cb(true)
		else
			return cb(false)
		end
	end)

end


ESX.RegisterServerCallback("esx_garage:updateVehicleOwner",function(source,cb,plate,coords,heading_,properties,needCallback)
if(properties == nil) then
	print("updateVehicleOwner properties is nil,ignore",plate)
return end
print("updateVehicleOwner",json.encode(properties),"plate",plate,coords,source,ESX.DumpTable(cb))
MySQL.update('UPDATE owned_vehicles SET position = ?,properties = ? WHERE plate = ?', {json.encode({x = coords.x,y = coords.y,z = coords.z,heading =  heading_}),
json.encode(properties),
plate},
				function(rowsChanged)
					print("Update vehicle:",rowsChanged)
					if(needCallback ~= nil and rowsChanged ~= 0) then
						
						
						local xPlayer  = ESX.GetPlayerFromId(source)

						MySQL.query('SELECT * FROM `owned_vehicles` WHERE `owner` = @identifier and plate = @plate',
						{
							['@identifier'] 	= xPlayer.identifier,
							['@plate'] 	        = ESX.Trim(plate)
						}, function(result)

							for i = 1,#result do
								cb({
									vehicle 	= json.decode(result[i].vehicle),
									plate 		= result[i].plate,
									position    = json.decode(result[i].position),
									properties  = json.decode(result[i].properties),
									stored      = result[i].stored
									
								})
							end
						end)
						
						
					end
				end)

end)

--RegisterServerEvent("esx_garage:getAllOwnerVehicles")
ESX.RegisterServerCallback('esx_garage:getAllOwnerVehicles', function(source, cb)
	local xPlayer  = ESX.GetPlayerFromId(source)

	MySQL.query('SELECT * FROM `owned_vehicles` WHERE `owner` = @identifier',
	{
		['@identifier'] 	= xPlayer.identifier
	}, function(result)

		local vehicles = {}
		for i = 1, #result, 1 do
			table.insert(vehicles, {
				vehicle 	= json.decode(result[i].vehicle),
				plate 		= result[i].plate,
				position    = json.decode(result[i].position),
				properties  = json.decode(result[i].properties),
				stored      = result[i].stored
				
			})
		end

		cb(vehicles)
	end)
end)


ESX.RegisterServerCallback('esx_garage:checkVehicleOwner', function(source, cb, plate)
   checkVehicleOwner(source,cb,plate)
end)

-- Pounds part
ESX.RegisterServerCallback('esx_garage:getVehiclesImpounded', function(source, cb)
	local xPlayer  = ESX.GetPlayerFromId(source)

	MySQL.query('SELECT * FROM `owned_vehicles` WHERE `owner` = @identifier AND `stored` = 0',
	{
		['@identifier'] 	= xPlayer.identifier,
	}, function(result)
		local vehicles = {}
		
		for i = 1, #result, 1 do
			table.insert(vehicles, {
				vehicle 	= json.decode(result[i].vehicle),
				plate 		= result[i].plate
			})
		end

		cb(vehicles)
	end)
end)

ESX.RegisterServerCallback('esx_garage:getVehiclesInPound', function(source, cb, Impound)
	local xPlayer  = ESX.GetPlayerFromId(source)

	MySQL.query('SELECT * FROM `owned_vehicles` WHERE `owner` = @identifier AND `pound` = @Impound AND `stored` = 2',
	{
		['@identifier'] 	= xPlayer.identifier,
		['@Impound']     	    = Impound
	}, function(result)
		local vehicles = {}

		for i = 1, #result, 1 do
			table.insert(vehicles, {
				vehicle 	= json.decode(result[i].vehicle),
				plate 		= result[i].plate
			})
		end

		cb(vehicles)
	end)
end)

ESX.RegisterServerCallback('esx_garage:checkMoney', function(source, cb, amount)
	local xPlayer = ESX.GetPlayerFromId(source)

	cb(xPlayer.getMoney() >= amount)
end)

RegisterServerEvent("esx_garage:payPound")
AddEventHandler("esx_garage:payPound", function(amount)
		local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer.getMoney() >= amount then
        xPlayer.removeMoney(amount, "Impound Fee")
				xPlayer.showNotification(TranslateCap('pay_Impound_bill', amount))
    else
		xPlayer.showNotification(TranslateCap('missing_money'))
    end
end)