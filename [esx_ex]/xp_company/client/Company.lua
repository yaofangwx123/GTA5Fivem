company = {}
alarmRgb = {r = 255,g = 255,b = 255}
isWorkTime = false
isTimeToGoWork = false
local staffSwpIndexPoint = 1
 function caculateCompanyTime()
	
	company.cmtime.segment = company.cmtime.segment + 1
	
	if(company.cmtime.segment >= 60) then
		company.cmtime.day = company.cmtime.day + 1
		company.cmtime.segment = 0
		if(company.cmtime.day  > 30) then
			company.cmtime.month = company.cmtime.month + 1
			company.cmtime.day = 1
			if(company.cmtime.month > 12) then
				company.cmtime.year = company.cmtime.year + 1
				company.cmtime.month = 1
			end
		end
	end
	
	
	
	
	
end

function isCompanyLoaded()
	return company.cmtime ~= nil
end

 function updateCmpSeatStatus(company)
	
	local chairs = {}
			for index,pos in pairs(Config.POS) do
				if(pos.isChair) then
					local enable = true
					for i,staff in pairs(company.staffs) do
						if(staff.seatId == index) then
							enable = false
							break
						end
						
						--
						if(enable) then
							for i,req in pairs(company.requests) do
								if(req.permissonId == Config.PERMISSION_Hire and json.decode(req.data).seatId == index) then
									enable = false
									break
								end
							end
						end
						
					end
					table.insert(chairs,{id = index,enable = enable,txt = pos.txt,leaderChair = pos.leaderChair})
				end
			end
			
			 company.chairs = chairs
	
end

 function isTimeWork()
	if(not company.cmtime) then return false end
	
	return (company.cmtime.segment >= Config.WorkTimeAMStart and company.cmtime.segment <= Config.WorkTimeAMEnd)
end


 function isTimeToWork()

	if(not company.cmtime) then return false end
	
	return (company.cmtime.segment >= (Config.WorkTimeAMStart - Config.WorkOffsetGo) and company.cmtime.segment <= Config.WorkTimeAMEnd)
end

 function setTimeColor()
	if(isWorkTime) then
			 alarmRgb.r = 0
			 alarmRgb.g = 255
			 alarmRgb.b = 0
	elseif(isTimeToGoWork) then
			alarmRgb.r = 255
			alarmRgb.g = 255
			alarmRgb.b = 0
	else
			alarmRgb.r = 255
			alarmRgb.g = 255
			alarmRgb.b = 255	
	end
end

 function getCompanyFinancesNum()

	if(#financeList ~= 0 or isFinanceNomoreData) then return end
	isFinanceNomoreData = true
	ESX.TriggerServerCallback('xp_company:getCompanyFinancesNum',function(result)
		
		if(#result == 0) then
			
			return
		end
		
		financeList = result
		
	end,company.id,200)
end

 function isHaveDelopStaff()
	for index,staff in pairs(company.staffs) do
		for skIndex,skill in pairs(staff.skills) do
			if(skill.id == Config.Skill_Program or skill.id == Config.Skill_Design or skill.id == Config.Skill_Test) then
				return true
			end
			
		end
		
	end
	
	return false
end







 function getMyCompany(callback,caculateDayPay)

	ESX.TriggerServerCallback("xp_company:getMyCompany",function(company)
		--获取我的任务
		--print("ESX.PlayerData.identifier",ESX.PlayerData.identifier)
		
		if(company.id) then
			 for index,staff in pairs(company.staffs) do
				if(staff.playerId == ESX.PlayerData.identifier) then
					print("My staff id is ",staff.id)
					company.myStaffId = staff.id
					staff.pedId = PlayerPedId()
					SetPedRelationshipGroupHash(staff.pedId, groupName)
				end
			 end
		
			ESX.TriggerServerCallback('xp_company:getRequests',function(result_)
			
			 for index,req in pairs(result_) do
				if(req.permissonId == Config.PERMISSION_Fire) then
					local reqSegment = json.decode(req.createTime)
					local limitSegment = caculateDaysAdd(reqSegment,req.workdays)
					if(isTimeOutDate(company.cmtime,limitSegment)) then
						local data = json.decode(req.data)
						local staff = getStaffById(data.id)
						if(staff) then
							
							
							doOneRequest(req.id,function(result)
								
								fireStaff(staff,true,function(result)
										if(result) then
											showMsg(TranslateCap('staffleavel','['..staff.departmentName..']'..staff.post..' '..staff.name))
										end
							end)
								
							end,req)
						end
						
					req.status = 1	
					else 
						local data = json.decode(req.data)
						local isExistStaff = false
						for st,staff in pairs(company.staffs) do
							if(staff.id == data.id) then
								isExistStaff = true
								break
							end
						end
						
						if(not isExistStaff) then
							   doOneRequest(req.id,function(result)end,req)
							   req.status = 1	
						end
						
					end
				end
			 end
			 
			 
			 if(caculateDayPay) then
				ESX.TriggerServerCallback('xp_company:prepareNewDay',function(result)
					print('company prepare result ',result)				
					if(result) then
						company.prepared = true
					end
					
				end,company.id,company.cmtime)
			 end
			
		     company.requests = result_
			 company.meetingTime = meetingTime
			 
			 	--返回椅子
			
			 company.skills = Config.Skills
			 
			 --print("getMyCompany - Company",ESX.DumpTable(company))
			 
			 callback(company)
			 
			 --print("xp_company:getRequests",company.requests)
			 --print("company.getRequests---",ESX.DumpTable(company))
			
		end,company.id)
		
		end
		
	end)

end

 function initCompanyData(caculateDayPay)
	--查询公司与员工状态
	print('initCompanyData')
	getMyCompany(function(result)
		print('initCompanyData ok')
		company = result
		 updateCmpSeatStatus(company)
		setTimeColor()
	   
		getCompanyFinancesNum()
	   
	   
	end,caculateDayPay)
end


local function updateStaffsRequest()

	if(not company.staffs) then return end
	
	for index,staff in pairs(company.staffs) do
								
		if(staff.workStatus == Config.WorkStatus_Working ) then
		
			getStaffRequestFromFinanceList(staff)
			
		end	
					
	end

end

local function isSalaryNotPay()
--检测公司是否有拖欠薪资情况，按照日减少员工忠诚度
	if(not company.staffs) then return end
	
	if(isWorkTime) then
		local unPayDays = 0
		for index,finance in pairs(financeList) do
			if(finance.subType == Config.FinanceSubType_Salary) then
				unPayDays = unPayDays + 1
			end
		end
		
		local staffSalary = nil
		if(unPayDays > 3 and math.random(1,5) == 3) then
			
			for index,staff in pairs(company.staffs) do
				if(not staff.playerId and math.random(3,10) <= unPayDays) then
					staff.honest = staff.honest - 1
					if(staff.honest < 0) then
						staff.honest = 0
					end
				end
				
				if(not staffSalary and isStaffExist(staff) and isStaffHasPermisson(staff,Config.PERMISSION_SALARY)) then
					staffSalary = staff
				end
			end
			
			
			ESX.TriggerServerCallback('xp_company:updateStaffHonest',function(result)
			
				if(result) then
					if(staffSalary) then
						showStaffToBossMessage(staffSalary,TranslateCap('msg_paysalary'))
					end
				end
			
			end,company.staffs)
			
			
			
			
		end
	end
end


local function prepareDay()
	if(company.cmtime.segment == 1) then			
		--准备今日的员工全员打卡
		company.prepared = false
		ESX.TriggerServerCallback('xp_company:prepareNewDay',function(result)			
		if(result) then
			company.prepared = true
		end
		
		end,company.id,company.cmtime)
		

	end	
end

local function staffGoingWork()

	if(not company.staffs) then return end
	
	if(company.prepared) then
			for index,staff in pairs(company.staffs) do
				if(not staff.playerId and (not Config.SwapStaffId or isInDebugStaffId(staff.id))) then
					local staffExist = isStaffExist(staff)
					--print('staffExist ',staff.id,staffExist,#company.staffs)
					if(not staffExist) then
						if(not isStaffAtTmpOffWork(staff)) then
							staffSwpIndexPoint = staffSwpIndexPoint + 1
							if(staffSwpIndexPoint > #Config.SwapPoints) then
								staffSwpIndexPoint = 1
							end
							print('staff on work ',staff.id)
							swapStaff(staff,staffSwpIndexPoint)
							break
						end
						
						
					elseif(isStaffAtTmpOffWork(staff) and not isPedMeshing(staff.pedId)) then
						print('staff is tmpoffwork ',staff.id)
						pedDismiss(staff.pedId)
						
					end

				end
		end
						
							
	end	
end

local function staffOffingWork()

	if(not company.staffs) then return end
	
	for index,staff in pairs(company.staffs) do
			staff.script = nil
			staff.scriptTimeCnt = nil
			staff.scriptTime = nil
			if((not staff.playerId) and staff.workStatus ~= Config.WorkStatus_OffToWork and isStaffExist(staff) and staff.pedId~=nil  and not isPedBusyRequest(staff.id)) then
				print('staff off work ',staff.name)
				staffSwpIndexPoint = staffSwpIndexPoint + 1
				if(staffSwpIndexPoint > #Config.SwapPoints) then
					staffSwpIndexPoint = 1
				end
				
				local isCurrent = resetStaffRequest(staff)
				if(isCurrent and isHtmlShow) then
					SendNUIMessage({action='close dialog'})
					isHtmlShow = false
				end
				
				staff.meetingSeatIndex = nil
				staff.workStatus = Config.WorkStatus_OffToWork
				
				
				--[[if(company.cmtime.segment >= Config.WorkTimePMEnd and company.cmtime.segment <= 59) then
					ESX.TriggerServerCallback('xp_company:check',function(result)
					end,staff.comId,staff.id,{year = company.cmtime.year,month = company.cmtime.month,day = company.cmtime.day},nil,{year = company.cmtime.year,month = company.cmtime.month,day = company.cmtime.day,segment = company.cmtime.segment})
				end]]
				
				local indexNear = getNearPosIndexByCoords(GetEntityCoords(staff.pedId))
				local path = Mesh.getPath(Config.MESHPOINT,indexNear, Config.SwapPoints[staffSwpIndexPoint])
						
				addMeshRoute(staff.pedId,path,Config.Default_speed,{{script = Config.Script_DISMISS}})
				break
			end
	end
end

local function createCompanyRandomEvents()
	if(not company.staffs) then return end
	
	for index,staff in pairs(company.staffs) do
	--生成随机事件
		if(isWorkTime and not staff.playerId ) then
			createRandomEvent(staff)
			
			
				--员工离职请求
			if( ((staff.honest < 30 and math.random(0,100) > staff.honest and math.random(1,50) == 2) or math.random(1,5000) == 888) and staff.workStatus == Config.WorkStatus_Working and isStaffExist(staff) and not staff.meetingSeatIndex and not staff.playerId) then
				
				dealStaffReqOffwork(staff)
				
			end	
			
			
			--底薪检测
			--and isPedNearPos(company.staffs[1].pedId,company.staffs[1].seatId) and  IsPedUsingScenario(staff.pedId,Config.Script_Sit) == 1 
			if(not checkLowPay and  not staff.meetingSeatIndex and  ((isStaffLowSalary(staff) and math.random(1,500) == 5) or math.random(1,1000) == 5)) then
				checkLowPay = true
				local path  = Mesh.getPath(Config.MESHPOINT, getNearPosIndexByCoords(GetEntityCoords(staff.pedId)), getNearPosIndex(company.staffs[1].seatId))
				addMeshRoute(staff.pedId,path,Config.Default_speed,{{script = Config.Script_Doing ,data = {doType = Config.DoType_ReqPullPay,targetStaff = company.staffs[1]}}},10)
				showStaffToBossMessage(staff,TranslateCap('addsalary_hello'))
			elseif(not checkLowPay and math.random(1,100000) == 888 and not isStaffHaveTmpOffWork(staff)) then
				
				--请假
				checkLowPay = true
				
				local targStaff = getStaffToStaffsRandomByPermisson(staff,Config.PERMISSION_Hire,true)
				if(targStaff) then
					local path  = Mesh.getPath(Config.MESHPOINT, getNearPosIndexByCoords(GetEntityCoords(staff.pedId)), getNearPosIndex(targStaff.seatId))
					addMeshRoute(staff.pedId,path,Config.Default_speed,{{script = Config.Script_Doing ,data = {doType = Config.DoType_TmpOffWork,targetStaff = targStaff,tmpTime = {startTime = caculateDaysAdd(company.cmtime,1),endTime = caculateDaysAdd(company.cmtime,math.random(2,5))}}}},10)
					if(targStaff.id == company.myStaffId) then
						showStaffToBossMessage(staff,TranslateCap('tmpoffwork_hello'))
					end
					
					
					
				end
				
				
			
			end
				
		end
	end
	
	
								
								

								
								
							
	
end


function baseBusiness()
	
	--公司业务处理
				if(company.requests) then
					for i = 1,#company.requests do
						local request = company.requests[i]
						--print('second',secCount)
						--print('startRequest',i,ESX.DumpTable(request))
						if(request and request.status == 0) then
							
							if(request.cntCurrent ~= request.cntTotal) then
								
								--给request初始化游戏参数
								
								--这是要求我做的事情
								--print('reqtime ',request.startTime)
								if(not request.startTime or request.startTime == 0) then
									request.startTime = getRequestStartTime(secCount)
								end
								
								local timetDist = secCount - request.startTime
								
								--print('request waitTime do ',request.id,timetDist,request.startTime,request.subId)
								
								if(timetDist == -60 and request.requestId == company.myStaffId and 
								(request.permissonId == Config.PERMISSION_SALARY or request.permissonId == Config.PERMISSION_Fire or
								 (request.permissonId == Config.PERMISSION_PROJECT and request.subType == Config.FinanceSubType_ProjectFire))) then
									local responseStaff = getStaffById(request.responseId)
									
									if(not responseStaff.meetingSeatIndex) then
										showStaffToBossMessage(responseStaff,TranslateCap('meetbossbusiness'))
									end
									

									
								end
								
								if(not request.localStart and request.startTime ~= 0 and  timetDist > 0) then
								
									--一次只能进行一个任务
									--[[local isHaveProcRequest = false
									for j = 1,#company.requests do
										if(company.requests[j].responseId == company.requests[i].responseId and company.requests[j].localStart and company.requests[j].status == 0) then
											isHaveProcRequest = true
											break	
										end
									end]]
								
											request.localStatus = nil
											request.targetPedId = nil
											request.initRequestData = nil
								
									if(not isPedBusyRequest(company.requests[i].responseId)) then
									
										
										local responseStaff = getStaffById(request.responseId)
										if(request.permissonId == Config.PERMISSION_Hire
										or request.permissonId == Config.PERMISSION_Fire
										or request.permissonId == Config.PERMISSION_PROJECT
										or request.permissonId == Config.PERMISSION_SALARY) then
											--只有人在附近才开始
											
											
											--print('check resp',responseStaff,responseStaff.pedId,responseStaff.seatId)	
											if(responseStaff and isPedNearPos(responseStaff.pedId,responseStaff.seatId)) then
											
												--request.responseSeatNearPosId = getNearPosIndex(responseStaff.seatId)
												local requestStaff = getStaffById(request.requestId)
												if(request.permissonId == Config.PERMISSION_SALARY or
												request.permissonId == Config.PERMISSION_Fire or
												(request.permissonId == Config.PERMISSION_PROJECT and request.subType == Config.FinanceSubType_ProjectFire)
												) then
												
													--检查老板是否在附近
													if(requestStaff and isPedNearPos(requestStaff.pedId,requestStaff.seatId)) then
														request.localStart = true
														local path = Mesh.getPath(Config.MESHPOINT,responseStaff.seatId, getNearPosIndex(requestStaff.seatId))
														request.localStatus = 'ped is meshing'
														request.targetPedId = responseStaff.pedId
														request.targetPedModel = responseStaff.model
														addMeshRoute(responseStaff.pedId,path,Config.Default_speed)
													end
	
												else
													
													local enableStart = true
													
													if(request.permissonId == Config.PERMISSION_PROJECT and not request.subId) then
														if(not isHaveDelopStaff()) then
															enableStart = false
														end
													end
													
													if(enableStart) then
														request.localStart = true
														request.localStatus = 'create a ped' 
													end
													
												end
												
												
											else
												--print('wait staff in position for request')	
											end
										end
										
										
									else
										--print('alreadHaveProcRequest')	
									end
									
								else
								
									if(request.targetPedId and ((not DoesEntityExist(request.targetPedId)) or GetEntityHealth(request.targetPedId) == 0)) then
										request.localStatus = nil
										request.localStart  = nil
										request.targetPedId = nil
										request.initRequestData = nil
										request.startTime = nil
									end
									
									if(request.permissonId == Config.PERMISSION_Hire
									or request.permissonId == Config.PERMISSION_Fire
									or request.permissonId == Config.PERMISSION_PROJECT
									or request.permissonId == Config.PERMISSION_SALARY) then
										
										if(request.localStatus == 'create a ped' and isWorkTime) then
											request.localStatus = 'getting a ped'
											local model = Voice.getRandomModel()
											--print('swapmodel ',model)
											local isExistHash = false
											
											if(request.permissonId == Config.PERMISSION_Hire) then
												for a = 1,#company.staffs do
													if(company.staffs[a].model == model) then
														isExistHash = true
														break
													end
												end
											elseif(request.permissonId == Config.PERMISSION_PROJECT) then
												if(request.project) then
													model = request.project.model
												end
												
											end
											
											
											if(isExistHash) then
												request.localStatus = 'create a ped'
												
											else
												local swpIndex = math.random(1,#Config.SwapPoints)
												--print('swpIndex ',Config.POS[Config.SwapPoints[swpIndex]])
												ESX.TriggerServerCallback("xp:company:spawnPed",function(result,netId)
												Wait(100)
												--print('swapmodel-result-1 ',pedId)
												local pedId = NetworkGetEntityFromNetworkId(netId)
												--print('swapmodel-result-2 ',pedId)
												if(DoesEntityExist(pedId)) then
													--print('swapmodel-result-3 ',pedId)
													local responseStaff = getStaffById(request.responseId)
													local path = Mesh.getPath(Config.MESHPOINT,Config.SwapPoints[swpIndex], getNearPosIndex(responseStaff.seatId))
													request.localStatus = 'ped is meshing'
													request.targetPedId = pedId
													request.targetPedModel = model
													request.targPedVoice = Voice.getPedVoice(model)
													request.reqData = nil
													
													--print("Hire path path is ",ESX.DumpTable(path))
													
													addMeshRoute(pedId,path,1.0)
												
													
												else
													request.localStatus = 'create a ped'
												end
												
												end,model,Config.POS[Config.SwapPoints[swpIndex]].position)		
											end			
											
											
									
											Wait(100)
										elseif(request.localStatus == 'mesh finish') then 	
											print('mesh finish--------',request.routeResult)
											if(request.routeResult) then
											
												
												--request.localStatus = 'ped is areadyPos'
												--print('juge is alread')
												if((request.subId and request.subId > 0) or ((request.permissonId == Config.PERMISSION_Hire and request.responseId == company.myStaffId) or request.permissonId == Config.PERMISSION_Fire) ) then
												
													
													request.localStatus = 'ped is areadyPos'
													
												else

													request.talkNum = 0
													request.talkTotal = math.random(15,30)
													request.turn = 1
													request.localStatus = 'ped is talk'	
													
												end
												
												
												
												
											else
												DeleteEntity(request.targetPedId)
												request.targetPedId = nil
												request.localStatus = nil
												request.localStart  = nil
												request.initRequestData = nil
												request.startTime = nil
												
											end
										elseif(request.localStatus == 'ped is talk') then
												if(request.talkNum < request.talkTotal) then
													request.talkNum = request.talkNum + 1
													request.turn = request.turn + 1
													local responseStaff = getStaffById(request.responseId)
													TaskTurnPedToFaceEntity(request.targetPedId,responseStaff.pedId,-1)
													Wait(1000)
													if(request.turn%2 == 0) then
														local v = request.targPedVoice.voices[math.random(1,#request.targPedVoice.voices)]
														--print('talk-2 ',request.targPedVoice.voiceName,v)
														PlayPedAmbientSpeechWithVoiceNative(request.targetPedId,v,request.targPedVoice.voiceName,'SPEECH_PARAMS_STANDARD',false)
													else
														local v = responseStaff.voice.voices[math.random(1,#responseStaff.voice.voices)]
														--print('talk-staff ',responseStaff.voice.voiceName,v)
														PlayPedAmbientSpeechWithVoiceNative(responseStaff.pedId,v,responseStaff.voice.voiceName,'SPEECH_PARAMS_STANDARD',false)
													end
													
													
													--SetPedTalk(request.targetPedId)
													
												else
													request.localStatus = 'ped is areadyPos'
												end
										elseif(request.localStatus == 'ped is areadyPos') then
												
											  if(not request.actionReqCnt) then
													request.actionReqCnt = 0
												end
												
												request.actionReqCnt = request.actionReqCnt + 1
												
												if(request.permissonId == Config.PERMISSION_SALARY or
												 request.permissonId == Config.PERMISSION_Fire or
												(request.permissonId == Config.PERMISSION_PROJECT and request.subType == Config.FinanceSubType_ProjectFire)) then
													local requestStaff = getStaffById(request.requestId)
													if(not requestStaff or not isPedNearPos(requestStaff.pedId,requestStaff.seatId)) then
														request.actionReqCnt = 20
														print('ped is give up because requestPed not there ',request.targetPedId)
													end
												else
													local responseStaff = getStaffById(request.responseId)
													if(not responseStaff or not isPedNearPos(responseStaff.pedId,responseStaff.seatId)) then
														request.actionReqCnt = 20
														print('ped is give up because requestPed not there ',request.targetPedId)
													end
												end
												
												if(request.actionReqCnt>=20) then
													
													SendNUIMessage({action='close dialog'})
													isHtmlShow = false
													
													
												
													local nearIndex = getNearPosIndexByCoords(GetEntityCoords(request.targetPedId))
													
													if(request.permissonId == Config.PERMISSION_SALARY or
													request.permissonId == Config.PERMISSION_Fire or
													(request.permissonId == Config.PERMISSION_PROJECT and request.subType == Config.FinanceSubType_ProjectFire)) then
														local staff = getStaffById(request.responseId)
														local path = Mesh.getPath(Config.MESHPOINT, nearIndex, staff.seatId)
														local pedId = request.targetPedId
														addMeshRoute(pedId,path,1.0,{{script = Config.Script_Sit,data = staff.seatId}})
													else
														pedDismiss(request.targetPedId)
													end
													
													
													request.actionReqCnt = 0
													
													
													print('ped is give up ',request.targetPedId)

													request.targetPedId = nil
													request.localStatus = nil
													request.localStart  = nil
													request.initRequestData = nil
													request.startTime = nil
													
												end
												
												print('request data ',ESX.DumpTable(request))
												
												
												if(request.localStart) then
													local isShowPanel = company.myStaffId == request.responseId or request.reportUp == 1
													local data = type(request.data) == 'string' and json.decode(request.data) or request.data
													local staffHire = nil
													local reqPedId = nil
													local responsePedId = nil
													if(not request.reqData) then
														if(request.permissonId == Config.PERMISSION_Hire) then
														--工资浮动
														local salary = math.floor( math.random(data.salary*0.5,data.salary *2))
														if(salary < 0) then
															salary = 1000
														end
														local skills = makeSkills(salary,data.skills,false)
														local sex = IsPedMale(request.targetPedId) and 1 or 0
														--print('ped head ',request.targetPedId,head)
														 request.reqData = {
																comId = request.comId,
																name = getPedRandomName(sex),
																pedId = request.targetPedId,
																model = request.targetPedModel,
																skills = skills,
																seatId = data.seatId,
																sex = sex,
																honest = math.random(10,80),
																departmentId = data.departmentId,
																post = data.post,
																salary = salary,
																permissons = {}
																}
																
																
															
															request.initRequestData = true
															
															
															
															
															elseif(request.permissonId == Config.PERMISSION_SALARY or
															request.permissonId == Config.PERMISSION_Fire or
															(request.permissonId == Config.PERMISSION_PROJECT and request.subType == Config.FinanceSubType_ProjectFire)) then
																request.reqData = data
																request.reqData.subType = request.subType
																local requestStaff = getStaffById(request.requestId)
																local responseStaff = getStaffById(request.responseId)
																TaskTurnPedToFaceEntity(responseStaff.pedId,requestStaff.pedId,-1)
																--Wait(1000)
																--TaskStartScenarioInPlace(responseStaff.pedId,'WORLD_HUMAN_CLIPBOARD',0,false)
																request.initRequestData = true
																reqPedId = requestStaff.pedId
																responsePedId = responseStaff.pedId
															elseif(request.permissonId == Config.PERMISSION_PROJECT) then
																if(request.subId and request.subId ~= 0) then
																	request.reqData = 	data
																else
																	local staffCre = getStaffById(request.responseId)
																	local staffsGroup = getLeaderStaffsById(staffCre.id)
																	local project = createProject(staffCre,staffsGroup)
																	project.pedId = request.targetPedId
																	project.model = request.targetPedModel
																	request.reqData = project
																	
																end
																
																local responseStaff = getStaffById(request.responseId)
																TaskTurnPedToFaceEntity(request.targetPedId,responseStaff.pedId,-1)
																request.initRequestData = true
																
															
															end	
															
															
															
															
															
													end													
												
													print('request.initRequestData ','request.reqData',request.reqData,isShowPanel)
												
													local reqData = {action = 'open',reqData = request.reqData,permissonId = request.permissonId,baseData = {reqPedId = reqPedId,responsePedId = responsePedId,requestId = request.id}}
															
													
													if(isShowPanel) then
														if(not isHtmlShow) then
															switchHtml(true,reqData)
														end
													else
														local pedJugeResult = true
														if(request.permissonId == Config.PERMISSION_Hire) then
														
															--根据能力判断是否雇佣
															local responseStaff = getStaffById(request.responseId)
															local skillValue = getStaffSkillValue(responseStaff,Config.Skill_Resource)
															if(request.reqData.honest < 60) then --1.忠诚度
																
																print('honest low ',skillValue)
																if(math.random(1,100) <= skillValue) then
																	pedJugeResult = false
																	print('pedJugeResult honest is lower ',request.reqData.honest)
																end
							
															end
															
															--薪资确认
															if(pedJugeResult) then
																local maxSalary = 0
																for index,skill in pairs(request.reqData.skills) do
																	
																	maxSalary = maxSalary + Config.Skills[skill.id].rate 
																end
																local data = json.decode(request.data)
																
																
																
																	
																	
																	if(request.reqData.salary > data.salary*1.5 or request.reqData.salary < data.salary*0.9) then
																		pedJugeResult = false
																		print('pedJugeResult salary is notmatch ',request.reqData.salary)
																	else
																		local skillsExpect = makeSkills(request.reqData.salary,data.skills,true)
																		if(#request.reqData.skills == #skillsExpect) then
																			for i = 1,#skillsExpect do
																				for j = 1,#request.reqData.skills do
																					if(skillsExpect[i].id == request.reqData.skills[j].id and math.abs(skillsExpect[i].value - request.reqData.skills[j].value) > 15) then
																						pedJugeResult = false
																						print('pedJugeResult skill is notmatch ',ESX.DumpTable(skillsExpect),ESX.DumpTable(request.reqData.skills))
																						break
																					end
																				end
																				
																				if(not pedJugeResult) then
																					break
																				end
																				
																			end
																		end
																	
																	end
																	
																
																
																
															end
															
															
															if(not pedJugeResult and math.random(0,100) > data.matchLevel and request.reqData.honest >= 40) then
																pedJugeResult = true
																print('pedJugeResult ok match level ',request.reqData.salary)
															end
															
														   hireStaffResult(pedJugeResult,request.reqData,true,function(result)end)
														elseif(request.permissonId == Config.PERMISSION_PROJECT) then
															if(request.subId and request.subId ~= 0) then
																comfirnFinance(pedJugeResult,request.reqData,function(result)end)
															else
																pedJugeResult = true
																local skillValue = getStaffSkillValue(responseStaff,Config.Skill_Project)
																if(request.reqData.isVirtual and math.random(1,100) <= skillValue) then
																	pedJugeResult = false
																end
																print("project juge result ",pedJugeResult)
																importProject(responseStaff,pedJugeResult,request.reqData,function(result)end)
															end
															
														elseif(request.permissonId == Config.PERMISSION_SALARY) then
															comfirnFinance(pedJugeResult,request.reqData,function(result)end)
														end	
														
														
													end
												end
												
												
												
										
										end
									
									end
									
								end
								
								
								
								
							else
								--任务完成
									
							end
						else
							print('remove task because is finish ',i)
							table.remove(company.requests,i)
							i = i - 1
						end
					end
				end
				
				
				
				
				
				
				
	if(company.staffs) then
					local isLeaveOne = true
					for index,staff in pairs(company.staffs) do
						if(not staff.playerId and isStaffExist(staff)) then
							--print('ped sit script check 1 ',staff.pedId)
							if(staff.script and staff.script ~= Config.Script_Def_Talk) then
								--print('ped sit script check 2 ',staff.pedId,staff.script)
								if(staff.script == Config.Script_Sit) then
									local seatId = staff.meetingSeatIndex and staff.meetingSeatIndex or staff.seatId
									if(isPedSitEnable(staff.pedId,seatId)) then
										if(not staff.scriptNum) then
										staff.scriptNum = 0
										end	
										if(not staff.scriptFailNum) then
											staff.scriptFailNum = 0	
										end
										local sitScript = IsPedUsingScenario(staff.pedId,Config.Script_Sit)
										--print('ped sit script check-2 ',staff.pedId,sitScript)
										if(sitScript == 1) then
											staff.scriptNum = staff.scriptNum + 1
											if(staff.scriptNum >=5) then
												staff.script = nil
												staff.scriptNum  = 0
											end
										else
											staff.scriptNum  = 0
											staff.scriptFailNum = staff.scriptFailNum + 1
											--print('chairs',ESX.DumpTable(Config.MeetingChairs),staff.meetingSeatIndex)
											pedSit(staff.pedId,seatId,false)	
										end
									else
									
										---ClearPedTasksImmediately(staff.pedId)
										
									
									end
								
									
								
								
								else
								
									local sitScript = IsPedUsingScenario(staff.pedId,Config.Script_Sit)
									if(sitScript == 1) then
										pedStand(staff.pedId)
										Wait(100)
									end
									if(IsPedUsingAnyScenario(staff.pedId)) then
										ClearPedTasksImmediately(staff.pedId)
										Wait(100)
									end

									if(not IsPedUsingScenario(staff.pedId,staff.script)) then
										TaskStartScenarioInPlace(staff.pedId,staff.script,0,false)
										--print('staff start ani ',staff.script)
										staff.script = nil									
									end
									
								end
							elseif(staff.scriptTime) then
								
								if(staff.scriptTimeCnt < staff.scriptTime) then
									staff.scriptTimeCnt = staff.scriptTimeCnt + 1
									--print('staff.scriptTime',staff.scriptTimeCnt,staff.scriptTime)
									
									if(staff.script ~= Config.Script_Def_Talk) then
											if(staff.scriptTimeCnt % Config.BadWorkingAniTime == 0) then
												if(staff.scriptTimeCnt % 100 == 0) then
													staff.honest = staff.honest - 1
													if(staff.honest < 0) then
														staff.honest  = 0
													end
													
													ESX.TriggerServerCallback('xp_company:updateStaffHonest',function(result)
													  print('staff honest is update ',staff.id,staff.honest)
													end,{staff})
													
												end
												--print('---------a')
												--人事专员执行权限
												
												if(isWorkTime) then
													for i,staf in pairs(company.staffs) do
														if(not staf.scriptTime and staff.id ~= staf.id  and not staf.playerId and isStaffHasPermisson(staf,Config.PERMISSION_Rule) and not isPedBusyRequest(staf.id) and not isPedMeshing(staf.pedId) and not isStaffBusyTalking(staf) and not staf.meetingSeatIndex) then
															local skillValue = getStaffSkillValue(staf,Config.Skill_Resource)
															local randValue = math.random(1,100)
															--print('---------b',skillValue,randValue)
															if(randValue <skillValue ) then
																--去这个ped的位置管理回归工作岗位
																
																pedGoPosition(staf.pedId,getNearPosIndexByCoords(GetEntityCoords(staff.pedId)),{{script = Config.Animations[5].ani,data = {total = 5}}})
																--showTargetStaffMessage(staf,staff,TranslateCap('msg_badworking'))
																break
															end
														end
													end
												end
											
											end
											
											
												--检测老板和人事员工是否附近，则停止
												for i,staf in pairs(company.staffs) do
												
													if(staff.id ~= staf.id) then
														
														if(staff.scriptTime >= Config.BadWorkingAniTime  and isStaffHasPermisson(staf,Config.PERMISSION_Hire) and isStaffExist(staf) and #(GetEntityCoords(staff.pedId) - GetEntityCoords(staf.pedId)) < 3) then
															staff.scriptTimeCnt = staff.scriptTime
															break
														elseif(staf.scriptTime and #(GetEntityCoords(staff.pedId) - GetEntityCoords(staf.pedId)) < 5) then
														
																TaskTurnPedToFaceEntity(staff.pedId,staf.pedId,6000)
																local v = staff.voice.voices[math.random(1,#staff.voice.voices)]
																PlayPedAmbientSpeechWithVoiceNative(staff.pedId,v,staff.voice.voiceName,'SPEECH_PARAMS_STANDARD',false)
														end
															
													end
												
													
												end
									else

										
											if(DoesEntityExist(staff.scriptToPedId) and #(GetEntityCoords(staff.pedId) - GetEntityCoords(staff.scriptToPedId)) < 5) then
												TaskTurnPedToFaceEntity(staff.pedId,staff.scriptToPedId,6000)
												Wait(1000)
												if(staff.scriptTimeCnt == 1 and math.random(1,10) == 5) then
													
													staff.honest = staff.honest + 1
													
													if(staff.honest > 100) then
														staff.honest = 100
													end
													
													ESX.TriggerServerCallback('xp_company:updateStaffHonest',function(result)
													  print('staff honest is update-2 ',staff.id,staff.honest)
													end,{staff})
													
												end
												if(staff.scriptTimeCnt%2 == 0) then
													local staffToPed = getStaffByPedId(staff.scriptToPedId)
													local v = staffToPed.voice.voices[math.random(1,#staffToPed.voice.voices)]
													PlayPedAmbientSpeechWithVoiceNative(staffToPed.pedId,v,staffToPed.voice.voiceName,'SPEECH_PARAMS_STANDARD',false)	
												else
													local v = staff.voice.voices[math.random(1,#staff.voice.voices)]
													PlayPedAmbientSpeechWithVoiceNative(staff.pedId,v,staff.voice.voiceName,'SPEECH_PARAMS_STANDARD',false)	
												end
												
											else
												staff.scriptTimeCnt = staff.scriptTime
											end
										
											
											
											
											
									end
									
									
									
								else
									staff.script = nil
									staff.scriptTime = nil
									staff.scriptTimeCnt = nil
									staff.scriptToPedId = nil
									staff.workStatus = staff.workStatus == Config.WorkStatus_OffToWork and  Config.WorkStatus_GoToWork or Config.WorkStatus_Working
									staffBackSeat(staff)
								end
								
							end
						
							
						if(staff.voice and math.random(1,staff.meetingSeatIndex and 3 or 10) == 2) then
							PlayPedAmbientSpeechWithVoiceNative(staff.pedId,staff.voice.voices[math.random(1,#staff.voice.voices)],staff.model.voiceName,'SPEECH_PARAMS_STANDARD',false)
						end
						
						
						--检查是否在开会，在开会的话则需要起身
						
						if(meetingTime == 0 and staff.meetingSeatIndex and isLeaveOne) then
							print('stop staff meeting ',staff.meetingSeatIndex,staff.id)
	
							--pedStand(staff.pedId,staff.meetingSeatIndex)
							
							for p,chairMeeting in pairs(Config.MeetingChairs) do
								if(chairMeeting.index == staff.meetingSeatIndex) then
									chairMeeting.enable = true
									isLeaveOne = false
									break
								end
							end
							
							staff.meetingSeatIndex = nil
						
							
							staffBackSeat(staff)
						end		
							
							
						end
					end
				end			
				
				
	
end

addTimerSecListener('Company.lua',function()
	
	if(not isCompanyLoaded()) then return end
	
	isWorkTime = isTimeWork()
	isTimeToGoWork = isTimeToWork()
	setTimeColor()

	if(secCount%Config.OneMinute == 0 ) then
		
		--上传公司业务数据
		ESX.TriggerServerCallback('xp_company:updateCompanyBusiness',function(result)end,company.id,company.cmtime)
		
		if(#financeList == 0 and company.cmtime.segment%3 == 0) then
			isFinanceNomoreData = false
			getCompanyFinancesNum()
		end
		
		updateStaffsRequest()
		
		isSalaryNotPay()
		
		
		
		prepareDay()
		
		
		
	end
	
	
	if(secCount%Config.SwapTime == 0) then
		if(isTimeToGoWork) then
			staffGoingWork()
		else
			staffOffingWork()
		end
	end
	
	if(secCount%10 == 0) then
		createCompanyRandomEvents()
	end
	
	baseBusiness()
	
end)