local companyMapStaffs = {}
local function clearStaffs(bossId)
	
	if(companyMapStaffs[bossId] == nil) then return end
	
	for i = 1,#companyMapStaffs[bossId] do
		if(DoesEntityExist(companyMapStaffs[bossId][i].ped)) then
			DeleteEntity(companyMapStaffs[bossId][i].ped)
		end
		
		print('clearStaff ',bossId,companyMapStaffs[bossId][i].ped)
		Wait(10)
	end
	companyMapStaffs[bossId] = {}
end

RegisterNetEvent("xp:company_help_addStaff",function(source,item)

	if(companyMapStaffs[source] == nil) then
			companyMapStaffs[source] = {}
		end
		
	if(not item.model) then print('not support item ',item) return end
	
	table.insert(companyMapStaffs[source],item)
	--print('company_help_addStaff ',source,ESX.DumpTable(item))
	
	
end)

RegisterNetEvent("xp:company_help_clearStaffs",function(source)

	clearStaffs(source)
	
	
end)

RegisterNetEvent('esx:playerDropped', function(source, reason)

 clearStaffs(source)
 
end)

RegisterNetEvent('esx:playerLoaded', function(source, xPlayer, isNew)
  clearStaffs(source)
end)

RegisterNetEvent('xp:getNetPedByModel', function(source, model,callback)

 print('call xp:getNetPedByModel ',source, model)
 if(companyMapStaffs[source] == nil) then return callback(nil) end
	
	local i = 1
	
	
	while(i<=#companyMapStaffs[source]) do
	
		--print('companyMapStaffs',i,ESX.DumpTable(companyMapStaffs))
		if(companyMapStaffs[source][i].model == model) then
			--print('isexist',DoesEntityExist(companyMapStaffs[source][i].ped),ESX.DumpTable(companyMapStaffs[source][i]))
			if(DoesEntityExist(companyMapStaffs[source][i].ped)) then
				callback(companyMapStaffs[source][i])
				return
			else
				table.remove(companyMapStaffs[source],i)
				i = i - 1
			end
			
		
		end
		
		i = i + 1
	
	end

	callback(nil)
 
 
end)



--[[Citizen.CreateThread(function()
		while true do
		
		for bossId,staffs in pairs(companyMapStaffs) do
			if(staffs) then
				for i,staff in pairs(staffs) do
					if(DoesEntityExist(staff) and IsPedDeadOrDying(staff,false)) then
						DeleteEntity(staff)
						break
					end
				end
			end
		end
		
	end
end)]]