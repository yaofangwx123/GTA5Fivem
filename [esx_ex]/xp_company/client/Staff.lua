
--[[Staff管理类
	
	1.staff的日常行为管理
	2.交换座位异常
	3.下班异常

]]--

groupName = 'xpcompany'	
NetworkSetFriendlyFireOption(false)
AddRelationshipGroup(groupName)

 function getStaffByPedId(pedId)
	if(company == nil or company.staffs == nil) then return nil end
	for index,staff in pairs(company.staffs) do
		if(staff.pedId == pedId) then
			return staff
		end	
	end
	return nil
end

 function getStaffsSalary()
	
	local total = 0
	local totalSegmentsOneDay = (Config.WorkTimeAMEnd - Config.WorkTimeAMStart)  + 1
	for index,staff in pairs(company.staffs) do
		total = total + math.floor(#staff.workSegments*staff.salary/totalSegmentsOneDay)
	end
	
	return total
	
end

 function isStaffLowSalary(staff)
	
	if(not staff or staff.playerId) then return false end
	
	local shouldSalary = 0
	for index,ski in pairs(staff.skills) do
		for i,standSki in pairs(Config.Skills) do
			if(standSki.id == ski.id) then
				shouldSalary = shouldSalary + ski.value * standSki.rate/100
				break
			end
		end
	end
	
	
	return staff.salary < shouldSalary
	
end

 function getStaffById(staffId)
	if(company == nil or company.staffs == nil) then return nil end
	for index,staff in pairs(company.staffs) do
		if(staff.id == staffId) then
			return staff
		end	
	end
	return nil
end


function getLeaderStaffsById(staffId)
	if(company == nil or company.staffs == nil) then return nil end
	local result = {}
	
	local departmentId = nil
	for index,department in pairs(company.departments) do
		if(staffId == department.leaderId) then
			
			departmentId = department.id
			
		end
	end
	
	for index,staff in pairs(company.staffs) do
		if(staff.id ~= staffId and staff.departmentId == departmentId) then
			
			table.insert(result,staff)
			
		end	
	end
	return #result ~= 0 and result or nil
end

 function isStaffHasPermisson(staff,permisson)
	
	if(not isStaffExist(staff) or not staff.permissons) then return false end
	
	for i = 1,#staff.permissons do
		if(staff.permissons[i] == permisson) then
		return true
		end
	end
	
	return false
	
end

 function isStaffHasSkill(staff,skill)
	
	if(not staff.skills) then return false end
	
	for i = 1,#staff.skills do
		if(staff.skills[i].id == skill) then
		return true
		end
	end
	
	return false
	
end

 function resetStaffScript(staff)
	staff.script = nil
	staff.scriptTime = nil
	staff.scriptTimeCnt = nil
	staff.scriptToPedId = nil
end

 function isInDebugStaffId(staffId)
	
	if(#Config.SwapStaffId == 0) then
		return true
	end


	for index,id in pairs( Config.SwapStaffId) do
		if(id == staffId) then
			return true
		end
	end
	
	return false

end

 function isStaffExist(staff)
	return  staff and  staff.pedId and  DoesEntityExist(staff.pedId)
end


 function fireStaff(staff,autoFire,callback)
	
	ESX.TriggerServerCallback('xp_company:deleteStaff',function(result)
	
		if(result) then
			for i = 1,#company.staffs do
				if(company.staffs[i].id == staff.id) then
					staff.meetingSeatIndex = nil
					pedDismiss(company.staffs[i].pedId)	
					table.remove(company.staffs,i)
					--移除所有request
					clearStaffRequest(staff)
					for p,chairMeeting in pairs(Config.MeetingChairs) do
						if(chairMeeting.index == company.staffs[i].meetingSeatIndex) then
							chairMeeting.enable = true
							break
						end
					end
					updateCmpSeatStatus(company)
					break
				end
			end
			
			
		end
		
		callback(result)
	
	end,staff,autoFire,company.cmtime)
	
end


 function getLeaderStaff(staff)

	for index,department in pairs(company.departments) do
		if(staff.departmentId == department.id) then
			for i,staff_ in pairs(company.staffs) do
				if(staff_.id == department.leaderId) then
					return staff_
				end
			end
		end
	end
	
	return nil
	
end

 function isStaffBusyTalking(sta)
	
	for index,staff in pairs(company.staffs) do
		if(staff.script and staff.scriptToPedId == sta.pedId) then
			return true
		end
		
	end
	
	
	--查看mesh里面的是否有这样的路径
	
	for index,item in pairs(naviMesh) do
		if(item.endScript) then
			for si = 1,#item.endScript do
				
				if(item.endScript[si].script == Config.Script_Def_Talk and item.endScript[si].data.toPedId == sta.pedId) then
					return true
				end
			end
		end
	end
	
	return false
	
end

 function getStaffSkillValue(staff,skill)
	if(not isStaffExist(staff)) then return 0 end
	local total = 0
	for index,ski in pairs(staff.skills) do
		if(not skill) then
			total = total + ski.value
		elseif(ski.id == skill) then
			return ski.value
		end
	end
	
	return total
	
end

 function getRandomStaffs(staffs,num)

	if(num > #staffs) then return nil end
	
	if(num == #staffs) then return staffs end
	
	local result = {}
	
	while #result < num do
		local index = math.random(1,#staffs)
		
		table.insert(result,staffs[index])
		
		table.remove(staffs,index)
	end
	
	return result

end

 function isStaffAtTmpOffWork(staff)

	if(not staff.tmpoffwork or #staff.tmpoffwork == 0) then return false end
	
	local startSegment = staff.tmpoffwork.startTime.year*12*60*30 + staff.tmpoffwork.startTime.month*60*30 + staff.tmpoffwork.startTime.day*60 + staff.tmpoffwork.startTime.segment
	local endSegment = staff.tmpoffwork.endTime.year*12*60*30 + staff.tmpoffwork.endTime.month*60*30 + staff.tmpoffwork.endTime.day*60 + staff.tmpoffwork.endTime.segment
	local currentSegment = company.cmtime.year*12*60*30 + company.cmtime.month*60*30 + company.cmtime.day*60 + company.cmtime.segment
	
	return currentSegment >= startSegment and currentSegment <= endSegment

end

 function isStaffHaveTmpOffWork(staff)

	if(not staff.tmpoffwork or #staff.tmpoffwork == 0) then return false end
	
	local endSegment = staff.tmpoffwork.endTime.year*12*60*30 + staff.tmpoffwork.endTime.month*60*30 + staff.tmpoffwork.endTime.day*60 + staff.tmpoffwork.endTime.segment
	local currentSegment = company.cmtime.year*12*60*30 + company.cmtime.month*60*30 + company.cmtime.day*60 + company.cmtime.segment
	
	return currentSegment <= endSegment

end

 function staffBackSeat(staff)
	
	if(not isStaffExist(staff)) then return end
	
	local nearIndex = getNearPosIndexByCoords(GetEntityCoords(staff.pedId))
	local path = Mesh.getPath(Config.MESHPOINT, nearIndex, staff.seatId)
	print('staffBackSeat',staff.id)
	addMeshRoute(staff.pedId,path,Config.Default_speed,{{script = Config.Script_Sit,data = staff.seatId}})
	
end

 function swapStaff(staff,swpPoint,fixIndex)
 
	
	if(#(GetEntityCoords(PlayerPedId()) - Config.CompanyCenter) > 80) then return print('stop swapStaff') end
 
 
	staff.swpPoint = swpPoint
	ESX.TriggerServerCallback("xp:company:spawnPed",function(result,netId)
	local pedId = NetworkGetEntityFromNetworkId(netId)
	
	if(DoesEntityExist(pedId)) then
		staff.pedId = pedId
		staff.voice = Voice.getPedVoice(staff.model)
		staff.workStatus = Config.WorkStatus_GoToWork
		staff.script = nil
		staff.toPedId = nil
		resetStaffRequest(staff)
		getStaffRequestFromFinanceList(staff)
		
		SetPedRelationshipGroupHash(staff.pedId, groupName)	
		print('initcompany create ',staff.name,staff.id,staff.pedId)
		--routine
		
		
		local path  = Mesh.getPath(Config.MESHPOINT, fixIndex and fixIndex or Config.SwapPoints[staff.swpPoint], staff.seatId)
		addMeshRoute(pedId,path,1.0,{{script = Config.Script_Sit,data = staff.seatId}}) 
		staff.iconHeadTagId = CreateFakeMpGamerTag( pedId, staff.name ..'['..staff.departmentName..'-'..staff.post..']', false, true, tostring(staff.pedId),0)
	end
	
	end,staff.model,
	fixIndex and Config.POS[fixIndex].position or Config.POS[Config.SwapPoints[staff.swpPoint]].position,
	company.id)
	
	

	
end



 function isStaffSitSeat(staff,seatId)
	if(not isStaffExist(staff)) then return false end
	
	if(IsPedUsingScenario(staff.pedId,Config.Script_Sit) == 1 and #(GetEntityCoords(staff.pedId) - Config.POS[seatId].chairPos) < 1) then return true end
	
	return false
	
	
end



 function getStaffSeatId(staff)
	if(not isStaffExist(staff) or IsPedUsingScenario(staff.pedId,Config.Script_Sit) ~= 1) then return false end
	
	for index,pos in pairs(Config.POS) do
		if((pos.isChair or pos.isMeetingChair) and #(GetEntityCoords(staff.pedId) - pos.chairPos) < 1) then
			return index
		end
	end
	
	return nil
	
	
end

 function getStaffToStaffsRandomByPermisson(staff,permisson,includePlayer)

		local staffsDeal = {}
		for index,staff_ in pairs(company.staffs) do
			
			if(isStaffHasPermisson(staff_,permisson) and staff.id ~= staff_.id and isStaffExist(staff_) and ((not includePlayer and not staff_.playerId )or includePlayer) ) then
				
				table.insert(staffsDeal,staff_)
			end
		end
		
		if(#staffsDeal == 0) then return nil end
		
		
		return getRandomStaffs(staffsDeal,1)[1]


end








 function getStaffRequestFromFinanceList(staff)
	
	
	for index,finance in pairs(financeList) do
		print('getStaffRequestFromFinanceList ',isRequestExistFinance(finance.id))
		--print('financeList',finance.id,ESX.DumpTable(staff.permissons),isStaffHasPermisson(staff,Config.PERMISSION_PROJECT),finance.subType == Config.FinanceSubType_ProjectReward)
		if(not isRequestExistFinance(finance.id)) then
			--一般是具备工资核算相关处理
				if((finance.subType == Config.FinanceSubType_Salary or finance.subType == Config.FinanceSubType_ComDayNormal) and 
					isStaffHasPermisson(staff,Config.PERMISSION_SALARY) and isStaffHasSkill(staff,Config.Skill_Resource)
				) then
				
				--print('staff add request PERMISSION_SALARY ',staff.id,finance.id)
				table.insert(company.requests,{
										
										id = 0,
										subId = finance.id,
										subType = finance.subType,
										comId = company.id,
										permissonId = Config.PERMISSION_SALARY,
										requestId = company.myStaffId,
										responseId = staff.id,
										cntTotal = 1,
										cntCurrent = 0,
										status = 0,
										data = json.encode(finance),
										workdays = 0,
										reportUp = 1,
										createTime = company.cmtime
										
									})
				break					
					
			elseif((finance.subType == Config.FinanceSubType_ProjectReward or finance.subType == Config.FinanceSubType_ProjectFire) and
				isStaffHasPermisson(staff,Config.PERMISSION_PROJECT)  and isStaffHasSkill(staff,Config.Skill_Project)
			) then

				--print('staff add request PERMISSION_PROJECT ',staff.id,finance.id)
				
				ESX.TriggerServerCallback('xp_company:getCompanyProjectById',function(project)
					--print('finance get project ',finance.id,ESX.DumpTable(project))
					if(project) then
					
					for i,req in pairs(company.requests) do
							if(req.data and json.decode(req.data).subId == project.id) then
								return
							end
					end	
						
						
					table.insert(company.requests,{
										
										id = 0,
										subId = finance.id,
										subType = finance.subType,
										comId = company.id,
										permissonId = Config.PERMISSION_PROJECT,
										requestId = finance.subType == Config.FinanceSubType_ProjectFire and company.myStaffId or staff.id,
										responseId = staff.id,
										cntTotal = 1,
										cntCurrent = 0,
										status = 0,
										data = json.encode(finance),
										workdays = 0,
										reportUp = finance.subType == Config.FinanceSubType_ProjectFire and 1 or 0,
										createTime = company.cmtime,
										project = project
										
									})
					
						--[[for i,req in pairs(company.requests) do
							if(req.data and json.decode(req.data).subId == project.id) then
								req.project = project

								break
							end
						end]]
						
						
					end
					
				end,company.id,finance.subId)
				
				
				
				break	
				
				
				end	
		end
		
		
		
			
		
		
	end
	
	
	
	
	
end







 function hireStaffResult(result,staff,auto,callback)
	--print('hireStaffResult-1 ',result)
	if(company and company.requests) then
		for index,request in pairs(company.requests) do
			--print('hireStaffResult-2 ',request.targetPedId,staff.pedId)
			if(request.permissonId == Config.PERMISSION_Hire and request.targetPedId == staff.pedId and request.status == 0) then
				
				request.localStatus = result and 'success hire' or 'fail hire'
				
				local indexStart = getNearPosIndexByCoords(GetEntityCoords(request.targetPedId))

				if(result) then
					if(not staff.seatId) then
						for i = 1,#company.chairs do
							if(company.chairs[i].enable and not company.chairs[i].leaderChair) then
								staff.seatId = company.chairs[i].id
								
								print('seat is set auto ',staff.seatId)
							break
							end
						end	
					end
					
					if(not staff.seatId) then
						result = false
						print('not enough chair')
							request.status = 2
							local index_ = index
							ESX.TriggerServerCallback('xp_company:doOneRequest',function(result,currentRequest)
							
							if(result) then
							
								table.remove(company.requests,index_)
								--company.requests[index] = currentRequest
								--company.requests[index].localStart = nil
								--company.requests[index].localStatus = nil
								--company.requests[index].targetPedId = nil
										
							end
							
							callback(result)
							
							print('requests state update ',ESX.DumpTable(company.requests))

						end,request)
						
					end
					
				end

				if(result) then
					--local pedCoords = GetEntityCoords(staff.pedId)
					--local heading   = GetEntityHeading(staff.pedId)
					staff.model = request.targetPedModel
					staff.voice = request.targPedVoice
					staff.workSegments = {}
					--staff.position = {x = pedCoords.x,y = pedCoords.y, z = pedCoords.z,w = heading}
					staff.permissons = {}
					staff.createTime = company.cmtime
					staff.workStatus = Config.WorkStatus_GoToWork
					ESX.TriggerServerCallback('xp_company:addStaff',function(result,newStaff)
						
						--todo 更新本地员工列表
						if(result) then
							--任务状态刷新
					table.insert(company.staffs,newStaff)
					for i,department in pairs(company.departments) do
						if(newStaff.departmentId == department.id) then
							newStaff.departmentName = department.name
						end
					end
					newStaff.iconHeadTagId = CreateFakeMpGamerTag( newStaff.pedId, newStaff.name ..'['..newStaff.departmentName..'-'..newStaff.post..']', false, true,tostring(newStaff.pedId),0)
					TriggerServerEvent('xp:company_help_addStaff',GetPlayerServerId(PlayerId()),newStaff.pedId)
					print('add staff ok ',ESX.DumpTable(newStaff))
					
					showStaffToBossMessage(newStaff,TranslateCap('entercmp_msg')..company.name)
					SetPedRelationshipGroupHash(newStaff.pedId, groupName)	
					
					local seatId = tonumber(newStaff.seatId)
					
					
					
					for i = 1,#company.chairs do
						if(company.chairs[i].id == seatId) then
							company.chairs[i].enable = false
							print('seat is disable ',seatId)
						break
						end
					end					
					local path  = Mesh.getPath(Config.MESHPOINT, indexStart, seatId)
					print('path is ',path,ESX.DumpTable(request))
					addMeshRoute(request.targetPedId,path,1.0,{{script = Config.Script_Sit,data = seatId}}) 
						
							
						ESX.TriggerServerCallback('xp_company:doOneRequest',function(result,currentRequest)
							
							if(result) then
								company.requests[index] = currentRequest
								--print('request state update ',ESX.DumpTable(request))
								if(company.requests[index].status == 0 ) then
										company.requests[index].localStart = nil
										company.requests[index].localStatus = nil
										company.requests[index].targetPedId = nil
										company.requests[index].initRequestData = nil
										company.requests[index].startTime = nil
								end
										
							end
							
							callback(result)
							
							print('requests state update ',ESX.DumpTable(company.requests))

						end,request)
	
							
						else
							callback(false)
						end
						
						
						
						
					end,staff,company.cmtime)
				else
					
					local path  = Mesh.getPath(Config.MESHPOINT, indexStart, Config.SwapPoints[math.random(1,#Config.SwapPoints)])
					addMeshRoute(request.targetPedId,path,1.0,{{script = Config.Script_DISMISS}}) 
					request.localStart = nil
					request.localStatus = nil
					request.targetPedId = nil
					request.initRequestData = nil
					request.startTime = nil
					callback(true)
				end
				return
			end
		end
	else
		callback(false)
	end
end





 function tmpOffWorkJuge(staffJuge,staffTmpOffwork,tmpTime,result,callback)

	if(not isStaffExist(staffJuge) or not isStaffExist(staffTmpOffwork)) then callback(false) return end
	
	if(not result) then
		staffBackSeat(staffTmpOffwork)
		
		if(math.random(1,10) == 2) then
			 staffTmpOffwork.honest = staffTmpOffwork.honest - 1
			 if(staffTmpOffwork.honest < 0) then
				staffTmpOffwork.honest = 0
			 end
			ESX.TriggerServerCallback('xp_company:updateStaffHonest',function(result)
			
			end,{staffTmpOffwork})
		end
		
		callback(true)
		return
	end
	
	ESX.TriggerServerCallback('xp_company:staffTmpOffWork',function(result)
	
		  for index,staff in pairs(company.staffs) do
			if(staff.id == staffTmpOffwork.id) then
				staff.tmpoffwork = tmpTime
				break
			end
		  end	
		  staffBackSeat(staffTmpOffwork)
	
		  callback(json.encode(result))
		  
		  if(staffJuge.id ~= company.myStaffId) then
			showTargetStaffMessage(staffJuge,staffTmpOffwork,TranslateCap('msg_tmpoffworkok'))
		  end
		  
		  
	end,staffTmpOffwork,company.cmtime,tmpTime.startTime,tmpTime.endTime)
	
end







--新函数增加的地方

 function dealStaffReqOffwork(staff)
		
		local staffsDeal = {}
		for index,staff_ in pairs(company.staffs) do
			if(isStaffHasPermisson(staff_,Config.PERMISSION_Fire) and not staff_.playerId and staff.id ~= staff_.id and isStaffExist(staff_)) then
				--showStaffToBossMessage(staff_,TranslateCap('staffleavel','['..staff.departmentName..']'..staff.post..' '..staff.name))
				table.insert(staffsDeal,staff_)
			end
		end
		
		if(#staffsDeal == 0) then 
			
			fireStaff(staff,true,function(result)
										if(result) then
											showMsg(TranslateCap('staffleavel','['..staff.departmentName..']'..staff.post..' '..staff.name))
										end
		end)
			
		return end
		print('dealStaffReqOffwork',staff.id,#staffsDeal)
		local staffSelect = getRandomStaffs(staffsDeal,1)[1]
		
		local request = {
											
											comId = company.id,
											permissonId = Config.PERMISSION_Fire,
											requestId = company.myStaffId,
											responseId = staffSelect.id,
											reportUp = 1,
											workdays = 3,
											status = 0,
											cntTotal = 1,
											data = {id = staff.id},
											createTime = company.cmtime
											
											}
											ESX.TriggerServerCallback('xp_company:addRequest',function(result)
											 if(result > 0) then
												request.id = result
												request.cntCurrent = 0
												request.cntTotal = 1
												--request.data = json.encode({})
												table.insert(company.requests,request)
											 end
											 
											end,request)
		
		
	
		
end

