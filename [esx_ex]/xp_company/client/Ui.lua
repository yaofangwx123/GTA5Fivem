isHtmlShow = false
local txtYear,txMonth,txtDay,txtSegment = TranslateCap('year'),TranslateCap('month'),TranslateCap('day'),TranslateCap('segment')
local isAllChairFind = false

 function showMsg(msg)
	
	ESX.ShowHelpNotification(msg, false, true, 5000)
	
end


 function showStaffToBossMessage(staff,message)
	if(not isStaffExist(staff)) then return end
	local mugshot,mugshotStr  = ESX.Game.GetPedMugshot(staff.pedId)
    ESX.ShowAdvancedNotification(staff.name, '['..staff.departmentName..']'..staff.post, TranslateCap('hiboss')..message, mugshotStr, 1)
    UnregisterPedheadshot(mugshot)

end

 function showTargetStaffMessage(staff,targetStaff,message)
	if(not isStaffExist(staff) or not isStaffExist(targetStaff)) then return end
	local mugshot,mugshotStr  = ESX.Game.GetPedMugshot(staff.pedId)
    ESX.ShowAdvancedNotification(staff.name, '['..staff.departmentName..']'..staff.post, TranslateCap('hi')..targetStaff.name..'！'..message, mugshotStr, 1)
    UnregisterPedheadshot(mugshot)

end

 function showStaffMessage(staff,message)
	if(not isStaffExist(staff)) then return end
	local mugshot,mugshotStr  = ESX.Game.GetPedMugshot(staff.pedId)
    ESX.ShowAdvancedNotification(staff.name, '['..staff.departmentName..']'..staff.post, message, mugshotStr, 1)
    UnregisterPedheadshot(mugshot)

end

 function switchHtml(state,data)
	if(not state) then
		isHtmlShow = false
		SetNuiFocus(false,false)
	elseif(state and not isHtmlShow) then
		isHtmlShow = true
		SetNuiFocus(true,true)
		
		if(data == nil) then
			data = {}
		end
		
		data.company = company
		
		SendNUIMessage(data)
	end
end

--key
CreateThread(function()

	while true do 
			if (IsControlJustReleased(0, 83)) then
			
			switchHtml(true,{action = 'open'})
			elseif(IsControlJustReleased(0, 84)) then
				local pedId = PlayerPedId()
				local posPed = GetEntityCoords(pedId)
				local posIndex,distance = getNearPosIndexByCoords(posPed)
				
				print('ssssss',posIndex,distance,IsPedUsingScenario(pedId,Config.Script_Sit))
				if(IsPedUsingScenario(pedId,Config.Script_Sit) == 1) then
					ClearPedTasks(pedId)
					Wait(100)
				elseif(distance < 1 and (Config.POS[posIndex].isChair  or Config.POS[posIndex].isMeetingChair )) then
		
				 pedSit(pedId,posIndex)
					
				else
					for index,pos in pairs(Config.SofaPositions) do
							if(#(pos.position - posPed) < 1) then
								pedSitSofa(pedId,index)
								break
							end
						end
				end
			end
			Wait(1)
	end

end)

RegisterCommand("cmp",function(source,args)

	if(args[1] == "location") then
		print(GetEntityCoords(PlayerPedId()),GetEntityHeading(PlayerPedId()))
	elseif(args[1] == "ani") then
		TaskStartScenarioInPlace(PlayerPedId(),args[2],0,false)
	elseif(args[1] == "findlocation") then
		print('find localtion')
		local objs = ESX.Game.GetObjects()
		local result = {}
		for index,obj in pairs(objs) do
			local model = GetEntityModel(obj)
			if(model == 1803116220) then
				
				table.insert(result, GetEntityCoords(obj))
			end
		end
		
				print('---------')
				for i,position in pairs(result) do
					local closeEntity,distance = ESX.Game.GetClosestObject(position, nil)
					local str = string.format("Config.POS_%d = %d",i+133,i+133)
					print(str)
				end
				print('---------')
				
				print('---------')
				for i,position in pairs(result) do
					local closeEntity,distance = ESX.Game.GetClosestObject(position, nil)
					local str = string.format("Config.POS[Config.POS_%d] = {position = %s,name = 'POS_%d'}",i+133,position,i+133)
					print(str)
				end
				print('---------')
		
		Citizen.CreateThread(function()

			while true do

				Wait( 1 )
				
				for i,position in pairs(result) do
					Draw3DText(position.x,position.y,position.z,1.0,tostring(i+133))
				end
				
				

			end

		end)
		
		
	elseif(args[1] == "staffani") then
		 local coords = GetEntityCoords(PlayerPedId())
		 local closeEntity,distance = ESX.Game.GetClosestPed(coords, nil)
		 createRandomEvent(getStaffById(247))
		 
		 
	elseif(args[1] == "pedtalk") then
		 local coords = GetEntityCoords(PlayerPedId())
		 local closeEntity,distance = ESX.Game.GetClosestPed(coords, nil)
		 --PlayPedAmbientSpeechNative(closeEntity,Config.Speaker[math.random(1,#Config.Speaker)],'SPEECH_PARAMS_STANDARD')
		--PlayPedAmbientSpeechNative(closeEntity,args[2],'SPEECH_PARAMS_FORCE_NORMAL_CLEAR')
		
			--local spc = Speech[math.random(1,#Speech)]
			--PlayPedAmbientSpeechWithVoiceNative(closeEntity,spc.Speeches[math.random(1,#spc.Speeches)].Name,spc.Name,'SPEECH_PARAMS_FORCE_NORMAL_CLEAR',false)
			
			--PlayPedAmbientSpeechAndCloneNative(closeEntity,args[2],'SPEECH_PARAMS_FORCE_NORMAL_CLEAR')
			
			SetPedScream(closeEntity)
			
			--PlayPedAmbientSpeechWithVoiceNative(closeEntity,args[3],args[2],'SPEECH_PARAMS_FORCE_NORMAL_CLEAR',false)
			
	elseif(args[1] == "clearani") then	
		ClearPedTasks(PlayerPedId())
	elseif(args[1] == "dis") then	
		print("distaaa",#(GetEntityCoords(PlayerPedId()) - Config.CompanyCenter))	
	elseif(args[1] == "wealther") then	
		SetWeatherTypeNow(args[2])
		SetRainLevel(0.5)
	elseif(args[1] == "request") then	
		for i = 1,#company.requests do
			local request = company.requests[i]
			--print('second',secCount)
			print('startRequest',i,ESX.DumpTable(request))	
		end				
	elseif(args[1] == "timenoon") then	
		NetworkOverrideClockTime(12,0,0)
	elseif(args[1] == "timenight") then	
		NetworkOverrideClockTime(23,0,0)	
	elseif(args[1] == "createproj") then	
		createProject(getStaffById(258))
	elseif(args[1] == "getcloseobj") then	
		 local coords = GetEntityCoords(PlayerPedId())
		 local closeEntity,distance = ESX.Game.GetClosestObject(coords, nil)
		 print("xplog closeobj is ",closeEntity,distance,GetEntityModel(closeEntity),GetEntityCoords(closeEntity),GetEntityHeading(closeEntity))
		 ESX.Game.DeleteObject(closeEntity)
	elseif(args[1] == "clearpedtask") then	
		 local coords = GetEntityCoords(PlayerPedId())
		 local closeEntity,distance = ESX.Game.GetClosestPed(coords, nil)
		 print('closeEntity is ',closeEntity)
		 ClearPedTasksImmediately(closeEntity)
		 
	elseif(args[1] == "usesc") then	
		 local coords = GetEntityCoords(PlayerPedId())
		 local closeEntity,distance = ESX.Game.GetClosestPed(coords, nil)
		 print('closeEntity is ',closeEntity,'usesc ',IsPedUsingScenario(closeEntity,Config.Script_Sit))
	
		-- ClearPedTasksImmediately(closeEntity)
    elseif(args[1] == "gosit") then	
		 local coords = GetEntityCoords(PlayerPedId())
		 local closeEntity,distance = ESX.Game.GetClosestPed(coords, nil)
		 print('closeEntity is ',closeEntity,'stand ',IsPedStill(closeEntity))
		 if(IsPedStill(closeEntity)) then
			local staff = getStaffByPedId(closeEntity)
			pedSit(closeEntity,staff.seatId,false)
		 end
		-- ClearPedTasksImmediately(closeEntity)
	  elseif(args[1] == "stand") then	
		 local coords = GetEntityCoords(PlayerPedId())
		 local closeEntity,distance = ESX.Game.GetClosestPed(coords, nil)
		print('stand up ',closeEntity)
		ClearPedTasks(closeEntity)
		TaskStandStill(closeEntity,8000)
		--local forward = GetEntityForwardVector(closeEntity)
		--print('nowPos ',nowPos,'forward ',forward)
		
		--TaskTurnPedToFaceEntity
		
		
		--[[print('aaaaaa')
		while IsPedUsingScenario(closeEntity, Config.Script_Sit) do
			Wait(100)
			
			TaskStartScenarioAtPosition(closeEntity, Config.Script_Sit, 0.0, 0.0, 0.0, 180.0, 1, true, false)
		end
		print('cccccc')
	ClearPedTasks(closeEntity)]]



	
	
	elseif(args[1] == "swppedsw") then		 

	 local coords = GetEntityCoords(PlayerPedId())
		ESX.TriggerServerCallback("xp:company:spawnPed",function(result,netId)
		 Wait(300)
		  local pedId = NetworkGetEntityFromNetworkId(netId)
		 
		
		
		
					
					
			
		end,"a_m_y_vinewood_02",coords);

	

		
	elseif(args[1] == "pedpath") then	
		 local coords = GetEntityCoords(PlayerPedId())
		 local pedCloset = ESX.Game.GetClosestPed(coords,nil)
		
		  local path = Mesh.getPath(Config.MESHPOINT, #Config.POS, 1)
		  print("path is ",ESX.DumpTable(path))
		  printPath(path)
		
		
		table.insert(naviMesh,{
						pedId = pedCloset,
						routeGroup = {path}, --数组，因为最大寻路8个
						currentPathGroupIndex = 1,--当前寻路的组索引
						currentPathIndex = 1,--当前组列表哪一步的索引
						retryCount = 0,      --当判断到异常时，则再次尝试，最大尝试次数3
						status = 1 --0:没有在寻路 1:正在寻路 2：寻路异常，可能需要重新寻路
					})
		

		elseif(args[1] == "path") then	
		 local coords = GetEntityCoords(PlayerPedId())
			
		  local path = Mesh.getPath(Config.MESHPOINT, tonumber(args[2]), tonumber(args[3]))
		  print("path is ",ESX.DumpTable(path))
		  printPath(path)
		
		
		table.insert(naviMesh,{
						pedId = PlayerPedId(),
						routeGroup = {path}, --数组，因为最大寻路8个
						currentPathGroupIndex = 1,--当前寻路的组索引
						currentPathIndex = 1,--当前组列表哪一步的索引
						retryCount = 0,      --当判断到异常时，则再次尝试，最大尝试次数3
						status = 1 --0:没有在寻路 1:正在寻路 2：寻路异常，可能需要重新寻路
					})	 
		 
	elseif(args[1] == "standped") then	
			local coords = GetEntityCoords(PlayerPedId())
		    local pedCloset = ESX.Game.GetClosestPed(coords,nil)
			print("ped is standped ",pedCloset)
			pedStand(pedCloset)
			--TaskChatToPed(pedCloset,PlayerPedId(),1,0,0,0,0,0)
			--SetPedAsGroupMember(pedCloset, 12345)
			--SetPedAsGroupMember(PlayerPedId(), 12345)
		   -- TaskGoToCoordAnyMeans(pedCloset,coords.x, coords.y, coords.z,2.0,0, 0, 786603, 0xbf800000)
			--TaskGoToEntity(pedCloset,PlayerPedId(),-1, 0.1, 1.0, 0, 0)
	elseif(args[1] == "isit") then
		local playerCoords = GetEntityCoords(PlayerPedId())
		local entityId,distance = ESX.Game.GetClosestObject(playerCoords,nil)
		print(entityId,distance,GetEntityModel(entityId))
		local posChair = GetEntityCoords(entityId)
		
		ClearPedTasks(PlayerPedId())
		TaskStartScenarioAtPosition(PlayerPedId(), Config.Script_Sit, posChair.x, posChair.y, posChair.z - 0.2, GetEntityHeading(entityId) + 180,-1,true,true) 
	elseif(args[1] == "swpped") then		 
		local playerCoords = GetEntityCoords(PlayerPedId())
		local coordsNew = vector3(playerCoords.x + 1,playerCoords.y,playerCoords.z)
		ESX.TriggerServerCallback("xp:company:spawnPed",function(result,netId)
		 Wait(100)
		 local pedId = NetworkGetEntityFromNetworkId(netId)
		  local coords = GetEntityCoords(PlayerPedId())
			
		end,"a_m_y_vinewood_02",coordsNew);
	elseif(args[1] == "swpveh") then
		 local coords = GetEntityCoords(PlayerPedId())
		 TriggerServerEvent("xp:company:swpveh",coords)
		
	elseif(args[1] == "testoffset") then
		local closeEntity,distance = ESX.Game.GetClosestObject(GetEntityCoords(PlayerPedId()), nil)
		 local coords2 = GetOffsetFromEntityInWorldCoords(closeEntity, 0.0, -1.0, 0.0)
		 
		 
		 
		 
		 	while true do

				Wait( 1 )
				
				Draw3DText(coords2.x,coords2.y,coords2.z,1.0,'a')
				
				

			end
		 
	elseif(args[1] == "addcmtime") then
		 company.cmtime.segment = company.cmtime.segment + tonumber(args[2])
		 setTimeColor()
		 
	elseif(args[1] == "testmp") then
		getLatestPointsLists(GetEntityCoords(PlayerPedId()))
	elseif(args[1] == "subcmtime") then
		  company.cmtime.segment = company.cmtime.segment - tonumber(args[2])
		 setTimeColor()
	elseif(args[1] == "fasttask") then
		for i,r in pairs(company.requests) do
			if(r.startTime) then
				r.startTime = 1
			end
		end	
	elseif(args[1] == "openmeeting") then
		local openStaff = nil
		local staffsJoins = {}
		for i,staff in pairs(company.staffs) do
			if(not staff.playerId and isStaffExist(staff)) then
				if(not openStaff) then
					openStaff = staff
				elseif(#staffsJoins < #Config.MeetingChairs - 1) then
					table.insert(staffsJoins,staff)
				end
			end
		end

		openMeeting(openStaff,staffsJoins)
	
	elseif(args[1] == "paycheck") then

		for i,staff in pairs(company.staffs) do
			isStaffLowSalary(staff)
		end

	elseif(args[1] == "closemeeting") then
		meetingTime = 3
		
	elseif(args[1] == "testtmpwork") then
		--ESX.ShowHelpNotification('胜多负少发射点范德萨范德萨范德萨范德萨', false, true, 3000)
		
		--[[fireStaff(getStaffById(308),true,function(result)
				ESX.ShowHelpNotification('测试成功', false, true, 3000)
			end)]]
			
	local staff = getStaffById(281)
	local targStaff = getStaffToStaffsRandomByPermisson(staff,Config.PERMISSION_Hire,true)
	targStaff = company.staffs[1]
	if(targStaff) then
		local path  = Mesh.getPath(Config.MESHPOINT, getNearPosIndexByCoords(GetEntityCoords(staff.pedId)), getNearPosIndex(targStaff.seatId))
		addMeshRoute(staff.pedId,path,Config.Default_speed,{{script = Config.Script_Doing ,data = {doType = Config.DoType_TmpOffWork,targetStaff = targStaff,tmpTime = {startTime = caculateDaysAdd(company.cmtime,1),endTime = caculateDaysAdd(company.cmtime,math.random(1,5))}}}},10)
		if(targStaff.id == company.myStaffId) then
			showStaffToBossMessage(staff,TranslateCap('tmpoffwork_hello'))
		end
		
		
		
	end

	
	
	elseif(args[1] == "testtest") then
				
	print('----',math.random(1,1))
		
	elseif(args[1] == "clearped") then
		 local coords = GetEntityCoords(PlayerPedId())
		 local pedCloset = ESX.Game.GetClosestPed(coords,nil)
		 print("xplog pedCloset",pedCloset)		 
		 if(pedCloset >= 0) then
			DeleteEntity(pedCloset)
		 end

	end


end,false)


--Nui-----

RegisterNUICallback('htmlEvent', function(data, cb)
    -- Do something here
	print('RegisterNUICallback',ESX.DumpTable(data))
	if(data['action'] == nil) then return end
	if(data['action'] == 'close') then
		switchHtml(false)
	elseif(data['action'] == 'regiest') then
		
		ESX.TriggerServerCallback('xp_company:regiestCompany',function(result,msg)
		  if(result) then

			initCompanyData()
			
		  end
		  
		  cb(json.encode({msg = msg,result = result}))
		  
		end,data['name'],data['companyCEOName'],IsPedMale(PlayerPedId()) and 1 or 0,ESX.PlayerData.identifier)
	elseif(data['action'] == 'getMyCompany') then
	
		getMyCompany(function(company_)
			 updateCmpSeatStatus(company_)
			 company_.prepared = company.prepared 
			cb(json.encode(company_))
		
		end)
	elseif(data['action'] == 'tmpoffworkJuge') then	
	print('basedata',data['baseData'])
		tmpOffWorkJuge(company.staffs[1],data['staff'],data['baseData'],data['result'],function(result)
		
			 cb(json.encode({result = result}))
		
		end)
	elseif(data['action'] == 'getComDepartments') then
		ESX.TriggerServerCallback('xp_company:getCompanyDepartment',function(result)
		  cb(json.encode(result))
		end,data['comId'])
	elseif(data['action'] == 'getCompanyStaffs') then
		ESX.TriggerServerCallback('xp_company:getCompanyStaffs',function(result)
		  cb(json.encode(result))
		end,data['comId'])
	elseif(data['action'] == 'getPermissions') then
		ESX.TriggerServerCallback('xp_company:getPermissions',function(result)
		  cb(json.encode(result))
		end)
	elseif(data['action'] == 'autoFireJuge') then
		local staff = data['staff']
		local request = getRequestById(data['baseData'].requestId)
		setRequestFinish(data['baseData'].requestId)
		if(data['result']) then
			fireStaff(staff,true,function(result)
				
				  if(result) then
					doOneRequest(nil,function(result)
					
					end,request)
				  end
				
				 cb(json.encode({result = result}))
				 staffBackSeat(getStaffByPedId(data['baseData'].responsePedId))
				 
			end)
		else
			
			ESX.TriggerServerCallback('xp_company:addStaffSalary',function(result,staff)
			  if(result) then
				local staff_ = getStaffById(staff.id)
				staff_.honest = staff.honest
				staff_.salary = staff.salary
				
				doOneRequest(nil,function(result)
				
				end,request)
				staffBackSeat(getStaffByPedId(data['baseData'].responsePedId))
			  end	
			  cb(json.encode({result = result}))
			end,data['staff'],0.2)	
			
		end	
	elseif(data['action'] == 'updateDepartment') then
		ESX.TriggerServerCallback('xp_company:updateDepartment',function(result)
			if(result) then
				for i = 1,#company.departments do
					if(company.departments[i].id == data['department'].id) then
						local leaderId = company.departments[i].leaderId
						if(leaderId) then
							for p,project in pairs(company.projects) do
								if(project.staffId == leaderId) then
									project.staffId = data['department'].leaderId
								end
							end
						end
						company.departments[i] = data['department']
						
						--员工更新
						for index,staff in pairs(company.staffs) do
							if(staff.departmentId == company.departments[i].id and not staff.playerId) then
								staff.departmentName = company.departments[i].name
								if(staff.iconHeadTagId) then
								RemoveMpGamerTag(staff.iconHeadTagId)
								Wait(100)
								end
								staff.iconHeadTagId = CreateFakeMpGamerTag( staff.pedId, staff.name ..'['..staff.departmentName..'-'..staff.post..']', false, true,tostring(staff.pedId),0)
							end	
						end
						
						
						break
					end
				end
				
				
				
			end
		  cb(json.encode({result = result}))
		end,data['department'])
    elseif(data['action'] == 'addDepartment') then
		data['department'].createTime = company.cmtime
		ESX.TriggerServerCallback('xp_company:addDepartment',function(result,newDepartment)
			if(result) then
				table.insert(company.departments,newDepartment)
			end
		  cb(json.encode({result = result}))
		end,data['department'])
    elseif(data['action'] == 'deleteDepartment') then
		
		ESX.TriggerServerCallback('xp_company:deleteDepartment',function(result,msg)
			if(result) then
				
				--[[if(newDepartment) then
					for index,staff in pairs(company.staffs) do
							if(staff.departmentId == data['id']) then
								staff.departmentName = newDepartment.name
								staff.departmentId = newDepartment.id
								if(staff.iconHeadTagId) then
								RemoveMpGamerTag(staff.iconHeadTagId)
								Wait(100)
								end
								staff.iconHeadTagId = CreateFakeMpGamerTag( staff.pedId, staff.name ..'['..staff.departmentName..'-'..staff.post..']', false, true,tostring(staff.pedId),0)
							end	
					end
				end]]
				
			end
		  cb(json.encode({result = result,msg = msg}))
		end,company.id,data['id'],company.cmtime)		
	elseif(data['action'] == 'updateStaffFromWeb') then
	
		local staff = getStaffById(data['staff'].id)
		
		--[[if() then
			 cb(json.encode({result = false}))
			 return
		end]]
		
		local staffsUpdate = {}
		local oldSeat = staff.seatId
		local curSeat = data['staff'].seatId
		
		if(oldSeat ~= curSeat) then
			--检查替换等座位是否可用
			for index,chair in pairs(company.chairs) do
				if(chair.id == curSeat and not chair.enable) then
					local isEnable = false
					for a,st in pairs(company.staffs) do
						if(st.seatId == curSeat) then
							isEnable = true
							st.seatId = oldSeat
							table.insert(staffsUpdate,st)	
							break
						end
					end
					
					if(not isEnable) then
						 cb(json.encode({result = false,msg = TranslateCap('seat_disable')}))
						return
					end
					
					break
				end
			end
		end
		
		table.insert(staffsUpdate,data['staff'])	
		
	
		ESX.TriggerServerCallback('xp_company:updateStaffFromWeb',function(result)
			if(result) then
				for i = 1,#company.staffs do
					if(company.staffs[i].id == data['staff'].id) then
						
						
						local isPostChange = company.staffs[i].post ~= data['staff'].post or company.staffs[i].departmentId ~= data['staff'].departmentId
						
						
						if(company.staffs[i].departmentId ~= data['staff'].departmentId) then
							for index,department in pairs(company.departments) do
								if(department.id == data['staff'].departmentId) then
									company.staffs[i].departmentName = department.name
									break
								end
							end
						end
						
						company.staffs[i].departmentId = data['staff'].departmentId
						company.staffs[i].post = data['staff'].post
						company.staffs[i].seatId = data['staff'].seatId
						company.staffs[i].permissons = data['staff'].permissons
						
						
						
						if(isPostChange and isStaffExist(company.staffs[i])) then
							if(company.staffs[i].iconHeadTagId) then
								RemoveMpGamerTag(company.staffs[i].iconHeadTagId)
								Wait(100)
							end
							company.staffs[i].iconHeadTagId = CreateFakeMpGamerTag( company.staffs[i].pedId, company.staffs[i].name ..'['..company.staffs[i].departmentName..'-'..company.staffs[i].post..']', false, true,tostring(company.staffs[i].pedId),0)
							print('referesh icon ',company.staffs[i].iconHeadTagId)
						end
						
						
						if(oldSeat ~= curSeat) then
							for index,chair in pairs(company.chairs) do
								if(chair.id == oldSeat and #staffsUpdate == 1) then
									chair.enable = true
									break
								end
							end
							
							if(isStaffExist(company.staffs[i])) then
								if(IsPedUsingScenario(company.staffs[i].pedId,Config.Script_Sit) == 1) then
									pedStand(company.staffs[i].pedId)
									Wait(100)
								end
								if(not company.staffs[i].meetingSeatIndex and meetingTime == 0) then
									staffBackSeat(company.staffs[i])
								end
								
							end
							
							if(#staffsUpdate == 2 and not staffsUpdate[1].meetingSeatIndex and meetingTime == 0 and isStaffExist(staffsUpdate[1])) then
								staffBackSeat(staffsUpdate[1])
							end
							
							
							
						end
						
						break
					end
				end
			end
		  cb(json.encode({result = result}))
		end,staffsUpdate)
	elseif(data['action'] == 'addRequest') then
		data['task'].createTime = company.cmtime
		data['task'].requestId = company.myStaffId
		if(data['task'].permissonId == Config.PERMISSION_Fire) then
			fireStaff(getStaffById(data['task'].responseId),false,function(result)
				cb(json.encode({result = result}))
			end)
			
		else
			ESX.TriggerServerCallback('xp_company:addRequest',function(result)
			 if(result > 0) then
				data['task'].id = result
				data['task'].cntCurrent = 0
				data['task'].cntTotal = tonumber(data['task'].cntTotal)
				data['task'].data = json.encode(data['task'].data)
				table.insert(company.requests,data['task'])
				 updateCmpSeatStatus(company)
			 end
			  cb(json.encode({result = result > 0}))
			end,data['task'])
		end
		
		
	elseif(data['action'] == 'getRequests') then
		ESX.TriggerServerCallback('xp_company:getRequests',function(result)
		  cb(json.encode(result))
		end,data['comId'])
	
	elseif(data['action'] == 'getCompanyFinances') then
		ESX.TriggerServerCallback('xp_company:getCompanyFinances',function(result)
		  cb(json.encode(result))
		end,data['comId'],data['page'])	
	elseif(data['action'] == 'hireStaffResult') then
			hireStaffResult(data['result'],data['staff'],false,function(result)
				cb(json.encode({result = result}))
			end)
	elseif(data['action'] == 'projectResult') then
			importProject(data['result'],data['project'],function(result)
				cb(json.encode({result = result}))
			end)
	elseif(data['action'] == 'financeResult') then
			comfirnFinance(data['result'],data['finance'],function(result)
				cb(json.encode({result = result}))
			end)
	elseif(data['action'] == 'getCompanyFinanceData') then
		ESX.TriggerServerCallback('xp_company:getCompanyFinanceData',function(result)
		  cb(json.encode(result))
		end,data['comId'])
	elseif(data['action'] == 'getNotifications') then
		ESX.TriggerServerCallback('xp_company:getNotifications',function(result)
		  cb(json.encode(result))
		end,data['comId'],data['page'])		
	elseif(data['action'] == 'clearFocused') then
		SetNuiFocus(false,false)
	elseif(data['action'] == 'addStaffSalary') then
		ESX.TriggerServerCallback('xp_company:addStaffSalary',function(result,staff)
		  if(result) then
			local staff_ = getStaffById(staff.id)
			staff_.honest = staff.honest
			staff_.salary = staff.salary
		  end	
		  cb(json.encode({result = result,staff = staff}))
		end,data['staff'],0.05)
	elseif(data['action'] == 'changeProAmin') then
		ESX.TriggerServerCallback('xp_company:changeProAmin',function(result)
		  if(result) then
			
			for index,project in pairs(company.projects) do
				if(project.id == data['params'].id ) then
				 	project.staffId = data['params'].staffId
				 break
				end
			end
			
		  end	
		  cb(json.encode({result = result}))
		end,data['params'])			
	elseif(data['action'] == 'fireStaff') then
			fireStaff(data['staff'],false,function(result)
				cb(json.encode({result = result}))
			end)
	elseif(data['action'] == 'cancelTask') then
		ESX.TriggerServerCallback('xp_company:cancelTask',function(result)
		
		 if(result) then
			for index,request in pairs(company.requests) do
				if(request.id == data['task'].id) then
					request.status = 2
					if(DoesEntityExist(request.targetPedId)) then
						pedDismiss(request.targetPedId)
					end
					break
				end
			end
			 updateCmpSeatStatus(company)
		 end	
		
		  cb(json.encode({result = result}))
		end,data['task'])
	elseif(data['action'] == 'pullSalaryStaff') then
			local staff_ = getStaffById(data['staff'].id)
			if(data['result']) then
				ESX.TriggerServerCallback('xp_company:addStaffSalary',function(result,staff)
				  if(result) then
					showStaffMessage(staff_,TranslateCap('addsalary_thanks'))
					staff_.honest = staff.honest
					staff_.salary = staff.salary
				  end	
				  cb(json.encode({result = result}))
				  staffBackSeat(data['staff'])
				end,data['staff'],0.05)
				
			else
				showStaffMessage(staff_,TranslateCap('addsalary_dispoint'))
				cb(json.encode({result = true}))
				staffBackSeat(data['staff'])
				if(math.random(1,3) == 2) then
					staff_.honest = staff_.honest - 20
					if(staff_.honest < 0) then
						staff_.honest = 0
					end
					ESX.TriggerServerCallback('xp_company:updateStaffHonest',function(result)
					 
					end,{data['staff']})
				end
			end
	
			
	
	
	
				
	elseif(data['action'] == 'stopMeeting') then
		
		meetingTime = 0
		cb(json.encode({result = true}))
    elseif(data['action'] == 'back2Seat') then
		local staff = getStaffById(data['staff'].id)
		if(isStaffExist(staff)) then
			
			staff.meetingSeatIndex = nil
			resetStaffScript(staff)
			pedStand(staff.pedId)
			staffBackSeat(staff)
			cb(json.encode({result = true}))
		else
			cb(json.encode({result = false}))
		end
		
				
	elseif(data['action'] == 'openMeeting') then
			local result = true
			local staffsJoins = {}	
			for index,staff in pairs(data['staffs']) do
				if(not staff.playerId) then
					
					local staff_ = getStaffById(staff.id)
					if(not isStaffExist(staff_)) then
						result = false
						break
					else
						table.insert(staffsJoins,staff_)
					end
					
				end
			end
			if(result) then
				
				result = openMeeting(company.staffs[1],staffsJoins)
				
			end
		
			cb(json.encode({result = result,meetingTime = meetingTime}))
	end
	
   
end)



Citizen.CreateThread(function()

	while true do

		Wait( 1 )
		
		if(company.cmtime) then
			DrawTextOnScreen(company.cmtime.year..txtYear..company.cmtime.month..txMonth..company.cmtime.day..txtDay..company.cmtime.segment..txtSegment,alarmRgb.r,alarmRgb.g,alarmRgb.b)
			--Draw3DText(Config.ClockPos.x,Config.ClockPos.y,Config.ClockPos.z - 1.0,1.0,company.cmtime.year..'年'..company.cmtime.month..'月'..company.cmtime.day..'日'..company.cmtime.segment..'时')
		end
		if(Config.ShowRoute) then
			for k,pos in pairs(Config.POS) do
			
				Draw3DText(pos.position.x,pos.position.y,pos.position.z - 1.0,1.0,tostring(k))
			end
		end		
		
		
		

	end

end)



function Draw3DText(x, y, z, scl_factor, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local p = GetGameplayCamCoords()
    local distance = GetDistanceBetweenCoords(p.x, p.y, p.z, x, y, z, 1)
    local scale = (1 / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov * scl_factor
    if onScreen then
        SetTextScale(0.0, scale)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(0, 255, 0, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

function DrawTextOnScreen(string,r,g,b) 
    SetTextFont(14)
    SetTextProportional(1)
    SetTextScale(0.0, 0.5)
    SetTextColour(r, g, b, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 150)
    SetTextDropshadow()
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(string)
    EndTextCommandDisplayText(0.44, 0.0)
end


AddEventHandler('esx:pauseMenuActive', function(isActive)
    print('pause menu state:', isActive)
	if(not isActive) then
	
		if(company.staffs) then
		
				for i = 1,#company.staffs do
					
					if(not company.staffs[i].playerId) then
						if(company.staffs[i].iconHeadTagId) then
						RemoveMpGamerTag(company.staffs[i].iconHeadTagId)
						Wait(100)
						end
						company.staffs[i].iconHeadTagId = CreateFakeMpGamerTag( company.staffs[i].pedId, company.staffs[i].name ..'['..company.staffs[i].departmentName..'-'..company.staffs[i].post..']', false, true,tostring(company.staffs[i].pedId),0)
					end					
					
					
				
						
				end
		end		
	end
end)




addTimerSecListener('Ui.lua',function()
	
	
	if(not isCompanyLoaded()) then return end
	
	if(secCount%Config.OneMinute == 0) then
		
		--更新颜色
		caculateCompanyTime()
		setTimeColor()
		
		
		
	end
	
	
	if(not isAllChairFind) then
		local isChairFind = true
		for key,value in pairs(Config.POS) do
		
			if((Config.POS[key].isChair or Config.POS[key].isMeetingChair) and Config.POS[key].chairPos == nil) then
				--1085033290
				local entityId,distance = ESX.Game.GetClosestObject(Config.POS[key].position,{[GetHashKey("xm_prop_x17_avengerchair_02")] = true})
				local model = GetEntityModel(entityId)
				local coords = GetEntityCoords(entityId)
				print(entityId,distance,model,coords.x,coords.y,coords.z)
				if((coords.x+coords.y+coords.z) > 0) then
					Config.POS[key].chairPos = GetEntityCoords(entityId)
					Config.POS[key].chairHeading = GetEntityHeading(entityId)
				else
					isChairFind = false
					print('miss chair ',key)
				end
				
				
			end
		
		end
		isAllChairFind = isChairFind
		print("isAllChairFind",isAllChairFind)
				
				
	end
	
	
	
end)