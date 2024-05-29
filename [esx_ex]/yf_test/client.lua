
--sportsclassics offroad muscle coupes compacts
-- 车辆维修地点 车辆爆炸图标还在 观察车辆越来越多的问题

--自行车
local VECODE_BYCYCLE = 13
local owenVehicleBlips = {}
local killPeds = {}
local vehicleLastHealth = 0
--被线程持续监控的车辆
local vehicleWatching = {}
--刚刚碰撞的车辆
local vehicleIJustCollsion = {}
local licensce_allow_cars = {
    
	drive = {0,1,2,3,4,5,6,7,12,17,18},
	drive_truck = {10,20},
	drive_bike = {8}

}

--驾驶了多长事件，用于计算老化
local driveSecs = 0

local isEnableReportVehicleState = false

local otherVehiclesAllowed = {}
local isDriveTesting = false

function ltrim(input)
	
	
    return input:match("^[%s]*(.-)[%s]*$")
end


isContainCode = function(codes,code)
	 for index, value in ipairs(codes) do
        if value == code then
            return true
        end
    end
	
	return false
end

local function isJustCollisonVehicle(vehicle)
	for i = 1,#vehicleIJustCollsion do
		if(vehicle == vehicleIJustCollsion[i])then return true end
	end
	
	return false
end

local function createBlip(plate,x,y,z)
	local blip = AddBlipForCoord(x,y,z)
	SetBlipSprite(blip, 361)
	SetBlipDisplay(blip, 4)
	SetBlipScale(blip, 0.8)
	--SetBlipColour(blip, 51)
	AddTextEntry(plate,plate)
	SetBlipSprite(blip, 530)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString(plate)
	EndTextCommandSetBlipName(blip)
	
	for i = 1,#owenVehicleBlips do
			if(ltrim(plate) == ltrim(owenVehicleBlips[i].plate)) then
				if(owenVehicleBlips[i] ~= nil) then
					RemoveBlip(owenVehicleBlips[i].bilp)
				end
				owenVehicleBlips[i].blip = blip
			end
	end
	
	--print(ESX.DumpTable(owenVehicleBlips))

	return blip
end

local function HandleAllowVehicle(data)
	
	local isExist = false
	for i = 1,#otherVehiclesAllowed do
		if(ltrim(data.plate) == ltrim(otherVehiclesAllowed[i].plate)) then
			isExist = true
			if(not data.isReg) then
				otherVehiclesAllowed[i] = nil
			end
			break
		end
	end
	
	if(data.isReg) then
		if(not isExist) then
			table.insert(otherVehiclesAllowed,data)
		end
	end
	
end

local function getPlateCfg(plate)
		
		for i = 1,#otherVehiclesAllowed do
			if(ltrim(plate) == ltrim(otherVehiclesAllowed[i].plate)) then
				return otherVehiclesAllowed[i] 
			end
		end
		return nil
end

local function ExitVehicleBlips(plate,x,y,z)
	for i = 1,#owenVehicleBlips do
					if(ltrim(owenVehicleBlips[i].plate) == ltrim(plate)) then
					
						RemoveBlip(owenVehicleBlips[i].blip)
						owenVehicleBlips[i].blip = createBlip(plate,x,y,z)
						
						break
					end
				end
			
			--print(ESX.DumpTable(owenVehicleBlips))
end

local function oldVehicle(vehicle,plate)

		if(driveSecs ==0) then return end
		 local percent = driveSecs/30.0
		 

		 for k = 1,#owenVehicleBlips do
			--print("oldVehicle",percent,owenVehicleBlips[k].propertie,plate)
			if(owenVehicleBlips[k].properties ~= nil and ltrim(plate) == ltrim(owenVehicleBlips[k].plate)) then
				
				owenVehicleBlips[k].properties.bodyHealth = GetVehicleBodyHealth(vehicle) - percent*Config.VehicleOldBody
				owenVehicleBlips[k].properties.tankHealth = GetVehiclePetrolTankHealth(vehicle) - percent*Config.VehicleOldTank
				owenVehicleBlips[k].properties.engineHealth = GetVehicleEngineHealth(vehicle) - percent*Config.VehicleOldEngine
				
				--owenVehicleBlips[k].properties.dirtLevel = owenVehicleBlips[k].properties.dirtLevel + 1
				--1000 - 0
				if(owenVehicleBlips[k].properties.bodyHealth <= 0) then	
					owenVehicleBlips[k].properties.bodyHealth  = 0
				end
				--1000 ,650开始漏油
				if(owenVehicleBlips[k].properties.tankHealth <= 0) then	
					owenVehicleBlips[k].properties.tankHealth  = 0
				end
				--发动机 1000 - -4000
				if(owenVehicleBlips[k].properties.engineHealth <= -4000) then	
					owenVehicleBlips[k].properties.engineHealth  = -4000
				end
				
				
				owenVehicleBlips[k].properties.fuelLevel = GetVehicleFuelLevel(vehicle)
				
				--[[if(owenVehicleBlips[k].properties.dirtLevel >= 15) then	
					owenVehicleBlips[k].properties.dirtLevel  = 15
				end
				SetVehicleDirtLevel(myVehicle,owenVehicleBlips[k].properties.dirtLevel)]]
				
				--ESX.Game.SetVehicleProperties(myVehicle, owenVehicleBlips[k].properties)
				SetVehicleEngineHealth(vehicle,owenVehicleBlips[k].properties.engineHealth)
				SetVehicleBodyHealth(vehicle,owenVehicleBlips[k].properties.bodyHealth)
				SetVehiclePetrolTankHealth(vehicle,owenVehicleBlips[k].properties.tankHealth)
				
				--savePlayerCarProperites(myVehicle,plate,true)
				
			end
		end
		
		driveSecs = 0
end

enterVehicleJuge = function(vehicle, plate, seat, displayName, netId)


	local vehicleCode = GetVehicleClass(vehicle)
    print('esx:enteredVehicle','vehicle', vehicle, 'plate', plate, 'seat', seat, 'name', displayName, 'netId', netId,"code ",vehicleCode)
	
	local ped = PlayerPedId()
	local source = GetPlayerServerId(PlayerId())
	ESX.TriggerServerCallback('esx_license:getLicenses', function(result)
		
		
    print(ESX.DumpTable(result))

	local vehiclePed = GetVehiclePedIsIn(PlayerPedId(),false)	
	
	local vehicleCfg = getPlateCfg(plate)

	local isAllowed =  (vehicleCfg ~= nil and (not vehicleCfg.isNeedLicensce))  or license_isPemitCar(result,vehicleCode) or seat ~= -1
	
	print("vehicleOtherCfg",ESX.DumpTable(vehicleCfg),"license_isPemitCar",license_isPemitCar(result,vehicleCode))
	
	--[[if(not isAllowed) then
		for k,v in ipairs(result) do
			if(v["type"] == "drive" and (vehicleCode >=0 and vehicleCode <=7)) then
				isAllowed = true
				break
			elseif(v["type"] == "drive_truck" and (vehicleCode == 20 or vehicleCode == 10)) then
				isAllowed = true
				break
			elseif(v["type"] == "drive_bike" and vehicleCode == 8) then
				isAllowed = true
				break
			end	
		 
		 end
	end ]]
	 
	 
	 if( not isAllowed) then
	 
	   local mugshot,mugshotStr  = ESX.Game.GetPedMugshot(ped)
	   ESX.ShowAdvancedNotification(TranslateCap("warn"), TranslateCap("licensce_department"), TranslateCap("licensce_nolicensce"), mugshotStr, 1)
	   UnregisterPedheadshot(mugshot)
	   TaskLeaveVehicle(ped,vehicle,1)
	 else 
	 
	  local isMyVehicle = false
		 for i = 1,#owenVehicleBlips do
			if(ltrim(owenVehicleBlips[i].plate) == ltrim(plate)) then
				isEnableReportVehicleState = true
				isMyVehicle = true
				--移除这个blip
				if(owenVehicleBlips[i].blip ~= nil) then
					print("remove blip",owenVehicleBlips[i].blip)
					RemoveBlip(owenVehicleBlips[i].blip)
					owenVehicleBlips[i].blip = nil
				end
				
				
				if(owenVehicleBlips[i].properties ~= nil) then
					print("setfuel",owenVehicleBlips[i].properties.fuelLevel)
					SetVehicleFuelLevel(vehicle,owenVehicleBlips[i].properties.fuelLevel)
				end
				
				
				break
			end
		 end
	 
	  if(isAllowed) then
		
	
		 if(not isMyVehicle) then
				local mugshot,mugshotStr  = ESX.Game.GetPedMugshot(ped)
				   ESX.ShowAdvancedNotification(TranslateCap("warn"), TranslateCap("licensce_department"), TranslateCap("licensce_notyourcar"), mugshotStr, 1)
				   UnregisterPedheadshot(mugshot)
				   TaskLeaveVehicle(ped,vehicle,1)
			
		end
			 

		
			 
	  end	  
	 
	 
	 
		
	 
	 end
	 
	 end,source)

end


license_isPemitCar = function(licenses,vehicleCode)

	if(vehicleCode == VECODE_BYCYCLE) then
	return true end

	local isAllowed = false
	for k,v in ipairs(licenses) do
			if(v["type"] == "drive" and isContainCode(licensce_allow_cars.drive,vehicleCode)) then
				isAllowed = true
				break
			elseif(v["type"] == "drive_truck" and isContainCode(licensce_allow_cars.drive_truck,vehicleCode)) then
				isAllowed = true
				break
			elseif(v["type"] == "drive_bike" and isContainCode(licensce_allow_cars.drive_bike,vehicleCode)) then
				isAllowed = true
				break
			end	
		 
	end
	
	return isAllowed

end





AddEventHandler('esx:enteredVehicle', function(vehicle, plate, seat, displayName, netId)
	
    enterVehicleJuge(vehicle, plate, seat, displayName, netId)
	
end)


AddEventHandler('esx:vehicleSeatChange', function(vehicle, plate, seat, displayName, netId)

	 enterVehicleJuge(vehicle, plate, seat, displayName, netId)

end)




RegisterNetEvent('xp:client:HandleAllowVehicle')
AddEventHandler('xp:client:HandleAllowVehicle', function(data)
    print('xp:client:RegiestAllowVehicle',  'data', ESX.DumpTable(data))
	
	HandleAllowVehicle(data)
	
end)

local function savePlayerCarProperites(vehicle,plate,justSave,cb)

				local coords = GetEntityCoords(vehicle)
				local heading = GetEntityHeading(vehicle)
				local properties  = ESX.Game.GetVehicleProperties(vehicle)
				
				
				if(not justSave) then
					ExitVehicleBlips(plate,coords.x,coords.y,coords.z)
				end
				
				
				ESX.TriggerServerCallback("esx_garage:updateVehicleOwner",function(result)
					if(cb ~= nil) then
						cb(result)
					end
				end,ltrim(plate),coords,heading,properties,cb ~= nil)

		--[[for i = 1,#owenVehicleBlips do
			if(ltrim(plate) == ltrim(owenVehicleBlips[i].plate)) then
				local coords = GetEntityCoords(vehicle)
				local heading = GetEntityHeading(vehicle)
				local properties  = ESX.Game.GetVehicleProperties(vehicle)
				
				
				if(not justSave) then
					ExitVehicleBlips(plate,coords.x,coords.y,coords.z)
				end
				
				print("older vehicle",vehicle,plate,ESX.DumpTable(properties))

				
				TriggerServerEvent("esx_garage:updateVehicleOwner",ltrim(plate),coords,heading,properties)
			end
		end]]


end 


--RegisterNetEvent('ox_fuel:addFuelComplete')
AddEventHandler('ox_fuel:addFuelComplete', function(vehicle,fuel)
	local plate = GetVehicleNumberPlateText(vehicle)
    print('xp:client:ox_fuel:addFuelComplete', "fuel",fuel,"localvehicle",vehicle)
	print("Final getFuel",GetVehicleFuelLevel(vehicle))
			
			 for i = 1,#owenVehicleBlips do
					if(ltrim(owenVehicleBlips[i].plate) == ltrim(plate)) then
					
						
						if(owenVehicleBlips[i].properties ~= nil) then
							print("find it",fuel)
							owenVehicleBlips[i].properties.fuelLevel = fuel*1.0

						end
						
						
						break
					end
				 end
			
			savePlayerCarProperites(vehicle,GetVehicleNumberPlateText(vehicle),true)
	
	
end)


AddEventHandler('esx:exitedVehicle', function(vehicle, plate, seat, displayName, netId)
    print('xp:server:exitedVehicle', 'vehicle', vehicle, 'plate', plate, 'seat', seat, 'displayName', displayName, 'netId', netId)
	isEnableReportVehicleState = false
	oldVehicle(vehicle,plate)
	savePlayerCarProperites(vehicle,plate,false)
	
	
end)




AddEventHandler('esx:pauseMenuActive', function(isActive)
    print('pause menu state:', isActive)
	if(isActive) then
		local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
		if(vehicle ~= 0) then
			savePlayerCarProperites(vehicle,GetVehicleNumberPlateText(vehicle),true)
		end
	end
end)






local function loadAllMycars()

	Citizen.CreateThread(function()
	Citizen.Wait(0)
		ESX.TriggerServerCallback("esx_garage:getAllOwnerVehicles",function(result)
	
	  --print("xp:client playerLoaded>>getAllOwnerVehicles",ESX.DumpTable(result))
	  
	   if(owenVehicleBlips ~= nil) then
		for i = 1,#owenVehicleBlips do
			if(owenVehicleBlips[i].blip ~= nil) then
				RemoveBlip(owenVehicleBlips[i].blip)
			end
			
		end
	   end

	   owenVehicleBlips = result
	  
	  -- local vehicles = {}
	   for i =1,#owenVehicleBlips do
		
		--local isExist = false
		
	    --local vehiclesClose = GetClosestVehicle(result[i].position.x,result[i].position.y,result[i].position.z,10,0,0)
		
	
		if(owenVehicleBlips[i].stored == 0) then
			createBlip(owenVehicleBlips[i].plate,owenVehicleBlips[i].position.x,owenVehicleBlips[i].position.y,owenVehicleBlips[i].position.z)
			--[[if(not isExist) then
				table.insert(vehicles,owenVehicleBlips[i])
			end]]
		end
	
		
	    end
		
		--[[if(#vehicles ~= 0) then
			TriggerServerEvent("xp:test:spwanVehicles",vehicles)
		end]]
		
	end)
	
 
 end)
 

end

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded',function(xPlayer, isNew, skin)
 
loadAllMycars();
 
 
 
end)

AddEventHandler('esx_vehicleshop:sellVehicle',function(plate)
 
print("Sell vehicle callback",plate)
 
for i = 1,#owenVehicleBlips do
	if(plate == ESX.Trim(owenVehicleBlips[i].plate)) then
		RemoveBlip(owenVehicleBlips[i].blip)
		if(DoesEntityExist(owenVehicleBlips[i].id)) then
			ESX.Game.DeleteVehicle(owenVehicleBlips[i].id)
			
		end
		break
	end
end 
 
 loadAllMycars();
 
end)


RegisterNetEvent('esx:realoadMyVehicles',function()
 
loadAllMycars();
 
 
 
end)


AddEventHandler('esx:buyVehicle',function(netId)
 
local vehicle = NetworkGetEntityFromNetworkId(netId)
print("xplog","esx:buyVehicle",vehicle)
local plate = GetVehicleNumberPlateText(vehicle)
--[[
local coords = GetEntityCoords(vehicle)
local propertie = ESX.Game.GetVehicleProperties(vehicle)
table.insert(owenVehicleBlips,{})]]

savePlayerCarProperites(vehicle,plate,true,function(vehicle_)

	vehicle_.id = vehicle
	vehicle_.vehicleStatus = 1
	print("callbackvehicle",ESX.DumpTable(vehicle_))
	
	table.insert(owenVehicleBlips,vehicle_)
	
	

end)
 
 
end)



RegisterCommand("bbb",function(source,args)
--print(PlayerId(),GetPlayerServerId(PlayerPedId()),PlayerPedId())
--TriggerServerEvent("xp:aaatest","This is send to serve params")
--print(GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId()), -1) == PlayerPedId())

 loadAllMycars()

end,false)

RegisterCommand("ccc",function(source,args)
	
	TriggerServerEvent("xp:aaatest","This is send to serve params")
	
	--local vehicle = GetVehiclePedIsIn(PlayerPedId(),false)
	--print("isesixt",DoesEntityExist(vehicle),ESX.DumpTable(vehicle),type(vehicle))
	
	
	

end,false)

RegisterCommand("mypos",function(source,args)
	
	--(-327.5849, -144.7514, 39.0599)
	print("xp:mypos",GetEntityCoords(PlayerPedId()))
	
	--local vehicle = GetVehiclePedIsIn(PlayerPedId(),false)
	--print("isesixt",DoesEntityExist(vehicle),ESX.DumpTable(vehicle),type(vehicle))
	
	
	

end,false)


local function ensureSetVehicleProperites(vehicle,properites)
	
	local before = json.encode(properites)
	CreateThread(function()
		for i = 1,2 do
			
			print("set--->",properites.engineHealth)
			ESX.Game.SetVehicleProperties(vehicle,properites)
			--SetVehicleEngineHealth(vehicle,properites.engineHealth*1.0)
			Wait(1000)
			
			local now = json.encode(ESX.Game.GetVehicleProperties(vehicle))
			
			if(before == now) then
			 print("set ok")
			 break
			end
			
			print("get--->",GetVehicleEngineHealth(vehicle),GetVehicleFuelLevel(vehicle))
		end
	end)
	
end


Citizen.CreateThread(function()
	
			while true do
			
			Citizen.Wait(2000)
				
				local playerPed = PlayerPedId()
				--检测是否犯罪
				local allpeds = ESX.Game.GetPeds(true)
				local myVehicle = GetVehiclePedIsIn(playerPed)
				
				--print("Allped",ESX.DumpTable(allpeds))
				--[[for i = 1,#allpeds do
					--local entityType = GetEntityType(allpeds[i])
					
						local healthNow = GetEntityHealth(allpeds[i])
						local healthMax = GetEntityMaxHealth(allpeds[i])
						if(healthNow ~= healthMax) then
							
							--local damagePedId = GetPedSourceOfDamage(allpeds[i])
							local isDefineTrafficAcident = false
							--print("tag is death",allpeds[i],GetEntityType(allpeds[i]))
							if(healthNow == 0) then
							
								local causeSource = GetPedSourceOfDeath(allpeds[i])
								isDefineTrafficAcident =  myVehicle == causeSource
								if(IsPedInAnyVehicle(playerPed, false)) then
									
									local tagVehicle = GetVehiclePedIsIn(allpeds[i])
									if(tagVehicle ~=0 ) then
										--通过服务器查询这个伤害是谁弄的
										local healthNowTagVehicle = GetEntityHealth(tagVehicle)
										local healthNowMaxVehicle = GetEntityMaxHealth(tagVehicle)
										local healthPercentTag = healthNowTagVehicle/healthNowMaxVehicle
										--认为是碰撞导致
										if( healthPercentTag< 0.99 and causeSource == allpeds[i]) then
											
											--检查自身载具
											 
											 if(myVehicle ~= 0) then
												healthNowTagVehicle = GetEntityHealth(myVehicle)
												local distHealth = math.abs(healthNowTagVehicle - vehicleLastHealth)
												if(distHealth > 10) then
													isDefineTrafficAcident = true
												end
												--print(healthPercentTag,"avsb ",distHealth)
											end	
												
										 end
											 
											
									end
									
								end
								
								
								if(not IsPedAPlayer(allpeds[i])) then
										if(Config.killPedFine ~=0 and playerPed ~= allpeds[i] and (playerPed == causeSource or isDefineTrafficAcident)) then
								     local exist = false		
									 for j = 1,#killPeds do
										if(killPeds[j] == allpeds[i]) then
											exist = true
											break
										end
									 end

									 if(not exist) then
										table.insert(killPeds,allpeds[i])
										print("Object is die,tagid ",allpeds[i],"cause ",GetPedCauseOfDeath(allpeds[i]),"source ",causeSource,"mypedid ",playerPed,"isDefineTrafficAcident",isDefineTrafficAcident)
										local vehicle = GetVehiclePedIsIn(playerPed, false)
										if(vehicle ~= 0) then
											--savePlayerCarProperites(vehicle,GetVehicleNumberPlateText(vehicle),true)
										end
										
										if(isDefineTrafficAcident) then
											
										end
																		
										TriggerServerEvent("xp:server:clientKillPed");
										TriggerServerEvent("esx_banking:cutMoneyBusiness",GetPlayerServerId(PlayerId()),Config.killPedFine,"Compensate")
										
										 local mugshot,mugshotStr  = ESX.Game.GetPedMugshot(playerPed)
										   ESX.ShowAdvancedNotification(TranslateCap("warn"), TranslateCap("licensce_department"),TranslateCap("death_fine",TranslateCap(myVehicle ~= 0 and "death_traffic" or "death_fight") ,Config.killPedFine), mugshotStr, 1)
										   UnregisterPedheadshot(mugshot)
										 
										
									 end 		
									 
									end
								end
								
							
								
							else
								--print("Object is inject,case",allpeds[i],"mypedid ",PlayerPedId())
							end
						end
					
					
					
				end]]
				
				--当靠近车俩复活地点时，则复活车辆
				local coordsPed = ESX.PlayerData.coords
				--print(ESX.DumpTable(coordsPed))
				
				for i = 1,#owenVehicleBlips do
					local coords = vec3(owenVehicleBlips[i].position.x,owenVehicleBlips[i].position.y,owenVehicleBlips[i].position.z)
					local distance = #(coordsPed - coords)
					--print("distance",distance)
					if(distance <= 30 and owenVehicleBlips[i].vehicleStatus == nil) then
					--如果附近已经有了一辆，则不能复活，直接指向他
				local aroundVehicles = ESX.Game.GetVehiclesInArea(coords,30)
							for t = 1,#aroundVehicles do
								if(ltrim(owenVehicleBlips[i].plate) == ltrim(GetVehicleNumberPlateText(aroundVehicles[t]))) then
									owenVehicleBlips[i].vehicleStatus = 1
									owenVehicleBlips[i].id = aroundVehicles[t]
									print("Find the near car,just set properites",ESX.DumpTable(owenVehicleBlips[i].properties))
									 if(owenVehicleBlips[i].properties ~= nil) then
									 
										--ensureSetVehicleProperites(aroundVehicles[t],owenVehicleBlips[i].properties)
										ESX.Game.SetVehicleProperties(aroundVehicles[t],owenVehicleBlips[i].properties)
										
										print("get--->",GetVehicleEngineHealth(aroundVehicles[t]),GetVehicleFuelLevel(aroundVehicles[t]))
										
									 end
									
									break
									
									
								end
							end
					
					if(owenVehicleBlips[i].vehicleStatus == nil) then
						owenVehicleBlips[i].vehicleStatus = 0

							
						
						ESX.TriggerServerCallback("xp:spwanVehicle",function(result,NetworkId)
							
							print("xplog","car is spwan",result,NetworkId)
							if(result) then
								--已复活
								local Vehicle = NetworkGetEntityFromNetworkId(NetworkId)
								owenVehicleBlips[i].vehicleStatus = 1
								owenVehicleBlips[i].id = Vehicle
							else
								owenVehicleBlips[i].vehicleStatus = nil		
							end
						end,owenVehicleBlips[i])
					end
					
					--可能刚刚买单数属性没有，需要report一下
					--if(owenVehicleBlips[i].properties == nil) then
						
						--savePlayerCarProperites()
					
					--end
					
					
					
					end
					
	
				end
				
				
				
				
				--清理观察的车辆
				local tmp = {}
				for j = 1,#vehicleWatching do
					if(DoesEntityExist(vehicleWatching[j].id)) then
						table.insert(tmp,vehicleWatching[j])
					end
				end
				vehicleWatching = tmp
				
				
				local allVehicles = ESX.Game.GetVehicles()
				for n = 1,#allVehicles do
					local isMyDrive = myVehicle == allVehicles[n]
					local isNeedReport = IsVehicleDamaged(allVehicles[n]);
					if(isNeedReport or isMyDrive) then
						local health = GetEntityHealth(allVehicles[n])
						local fuel   = GetVehicleFuelLevel(allVehicles[n])
						local isFind = false
						local tagIndex = 1
						for w = 1,#vehicleWatching do
							if(vehicleWatching[w].id == allVehicles[n]) then
								isFind = true
								tagIndex = w
								--print("a",ESX.Math.Round(fuel/10),ESX.Math.Round(vehicleWatching[w].fuel/10 or 0))
								if(health ~= vehicleWatching[w].health or ESX.Math.Round(fuel/10) ~= ESX.Math.Round(vehicleWatching[w].fuel/10 or 0)) then
									 vehicleWatching[w].health = health
									 vehicleWatching[w].fuel = fuel
								else 
									isNeedReport = false
								end
								
								
								break
							end
						end
						
						
										
					--是不是我在车里面	
					
					if(isMyDrive) then
						
						--local vehicle      = GetVehiclePedIsIn(playerPed, false)
						local speed        = GetEntitySpeed(myVehicle)

						local plate = GetVehicleNumberPlateText(myVehicle)
						if(speed == 0) then
							if(isEnableReportVehicleState) then
								--print("save",speed)
								isEnableReportVehicleState = false
								
								oldVehicle(myVehicle,plate)
								--savePlayerCarProperites(myVehicle,plate,true)
							end
							
						else 
						 isEnableReportVehicleState = true
						 --老化
						 
						 driveSecs = driveSecs + 1
						 if(driveSecs == 30) then
							oldVehicle(myVehicle,plate)
						 end
					
						 
						 
					
						end
						
						
						
		
					end
						
						
						
						if(not isFind) then
							table.insert(vehicleWatching,{id = allVehicles[n],plate = GetVehicleNumberPlateText(allVehicles[n]),health = health,fuel = fuel})
							tagIndex = #vehicleWatching
						end
						
						if(isNeedReport) then
							print("isNeedReport ",allVehicles[n],tagIndex,#vehicleWatching,vehicleWatching[tagIndex].plate,health)
							
							
							if(health == 0) then
							local plateTrim = ltrim(vehicleWatching[tagIndex].plate)
							
							 
							  
							  --[[ for i = 1,#owenVehicleBlips do
									if(ltrim(owenVehicleBlips[i].plate) == plateTrim) then
										
										loadAllMycars()
										
										break
									end
								end]]
							
							
								ESX.TriggerServerCallback("esx_vehicleshop:delVehicle",function(result)
									
									 if(isMyDrive) then
									 TaskLeaveVehicle(playerPed,myVehicle,1)
									 SetVehicleDoorsLocked(myVehicle,2)
								     loadAllMycars()
									 
										end		
									
								end,plateTrim)
								
															  
								
							  
								
							else
								savePlayerCarProperites(vehicleWatching[tagIndex].id,vehicleWatching[tagIndex].plate,true)
							end
							
						end
						
						
					end
					
				end
				
				

				
				
			end
				
	end)
	


AddEventHandler("entityDamaged", function(dagamed, damaging,weapon,damageValue)
	local typeDamaged = GetEntityType(dagamed)
	if(typeDamaged ~= 1 and typeDamaged ~= 2) then return end

	local pedId = PlayerPedId()
	local damagedHealth = GetEntityHealth(dagamed)
	local pedVehicle = GetVehiclePedIsIn(pedId)
	local damagedVehicle = typeDamaged == 1 and GetVehiclePedIsIn(dagamed) or 0
	local fineCount = 0
    print("damaged",dagamed, damaging,"pedId:",pedId,"pVehicle",pedVehicle,"dVehicle",damagedVehicle,"health:",damagedHealth,"type",typeDamaged)
	
	--记录碰撞的车辆
	if(typeDamaged == 2 and damaging == pedVehicle) then
	
		local maxSeat = GetVehicleMaxNumberOfPassengers(dagamed)
		local seatDeathCount = 0
		for seat = -1,maxSeat do
			if(not IsVehicleSeatFree(dagamed,seat)) then
				local pedSeat = GetPedInVehicleSeat(dagamed,seat)
				--车祸死人了
				if(pedSeat ~= 0 and GetEntityHealth(pedSeat) == 0) then
					seatDeathCount = seatDeathCount + 1
					print("deathseat",dagamed,pedSeat)
				end
			end
		end
		
		local isExist = false
		local tmp = {}
		
		for i = 1,#vehicleIJustCollsion do
			if(vehicleIJustCollsion[i].vehicle == dagamed) then
				isExist = true
				if(seatDeathCount > vehicleIJustCollsion[i].seatDeath) then
					fineCount = seatDeathCount - vehicleIJustCollsion[i].seatDeath
				end
				vehicleIJustCollsion[i].seatDeath = seatDeathCount
			end
			if(DoesEntityExist(vehicleIJustCollsion[i].vehicle)) then
				table.insert(tmp,vehicleIJustCollsion[i])
			end
			
		end
		
		
		if(not isExist) then
			fineCount = seatDeathCount
			table.insert(tmp,{vehicle = dagamed,seatDeath = seatDeathCount})
		end
		vehicleIJustCollsion = tmp
		
		
		

	
	elseif(typeDamaged ~= 2 and damagedHealth == 0 and damaging == pedId) then
		print("I kill him")
		fineCount = 1
		
	end
	
	--定责
		if(fineCount ~= 0) then
			TriggerServerEvent("xp:server:clientKillPed");
			TriggerServerEvent("esx_banking:cutMoneyBusiness",GetPlayerServerId(PlayerId()),Config.killPedFine*fineCount,"Compensate")
			
			 local mugshot,mugshotStr  = ESX.Game.GetPedMugshot(pedId)
			 ESX.ShowAdvancedNotification(TranslateCap("warn"), TranslateCap("licensce_department"),TranslateCap("death_fine",pedVehicle ~= 0 and TranslateCap("death_traffic") or TranslateCap("death_fight") ,Config.killPedFine), mugshotStr, 1)
			  UnregisterPedheadshot(mugshot)
		end
		
	
	
	
	
end)
