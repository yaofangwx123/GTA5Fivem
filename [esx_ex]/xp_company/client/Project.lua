local table_num = {"0","1","2","3","4","5","6","7","8","9"}
local table_char = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"}

 function getProjectName(n)
	
	local s = table_char[math.random(#table_char)]
	for i =1, n do
		s = s .. table_num[math.random(#table_num)]
	end
	return s
end

function addProjectRequest()

	
	if(not isCompanyLoaded()) then return end
	
	
	
	
	
	for index,department in pairs(company.departments) do
	
		if(department.leaderId) then
		
		 local staffLeader = getStaffById(department.leaderId)
		 
		 if(isStaffExist(staffLeader)) then
			
			local isHaveProject = false
			
			for i ,project in pairs(company.projects) do
				if(project.staffId == staffLeader.id and project.status == 0) then
					isHaveProject = true
					break
				end
			end
			
			
			if(not isHaveProject) then
				
				local staffsGroup = getLeaderStaffsById(staffLeader.id)
				if(staffsGroup) then

					--createProject(staffLeader,staffsGroup)	
					
					if(staffLeader.workStatus == Config.WorkStatus_Working and not staffLeader.playerId and isStaffHasPermisson(staffLeader,Config.PERMISSION_PROJECT)  and isStaffExist(staffLeader) and not isRequestExistPermission(staffLeader.id,Config.PERMISSION_PROJECT) ) then
					
						local request = {
											
											comId = company.id,
											permissonId = Config.PERMISSION_PROJECT,
											requestId = company.myStaffId,
											responseId = staffLeader.id,
											reportUp = 0,
											workdays = 0,
											status = 0,
											cntTotal = 1,
											data = {},
											createTime = company.cmtime
											
											}
											ESX.TriggerServerCallback('xp_company:addRequest',function(result)
											 if(result > 0) then
												request.id = result
												request.cntCurrent = 0
												request.cntTotal = 1
												request.data = json.encode({})
												table.insert(company.requests,request)
											 end
											 
											end,request)
						
					end
					
					
					
					
				end
				
			end
			
		 end
			
		end
	
	end


end


 function createProject(staffCreate,staffs)
	
	
	--根据员工能力生成对应项目
	
	
	
	
	local days = math.random(3,7)
	local endTime = caculateDaysAdd(company.cmtime,days - 1)
	
	local dayCreateNum = (Config.WorkTimeAMEnd - Config.WorkTimeAMStart) - 1
	--一天的产能
	local dayTotalCreateValues = {[Config.Skill_Program] = 0,[Config.Skill_Design] = 0,[Config.Skill_Test] = 0}
	for index,staff in pairs(staffs) do
		for skIndex,skill in pairs(staff.skills) do
			if(skill.id == Config.Skill_Program or skill.id == Config.Skill_Design or skill.id == Config.Skill_Test) then
				dayTotalCreateValues[skill.id] = dayTotalCreateValues[skill.id] + skill.value * dayCreateNum * Config.OneMinute/5 * (days)
			end
			
		end
	end
	
	
	
	
	
	
	local tasks = {}
	local reward = 0
	
	for index,skill in pairs(Config.Skills) do
		
		if(skill.id == Config.Skill_Program or skill.id == Config.Skill_Design or skill.id == Config.Skill_Test) then
			tasks[index] = {total = math.floor(math.random(math.floor(dayTotalCreateValues[index]*0.4),math.floor(dayTotalCreateValues[index]*0.7))),current = 0,name = skill.name}
		
			reward = reward + skill.rate/5500 * tasks[index].total
		end
		
		
	end
	
	local skillValue = 1
	if(isStaffHasPermisson(staffCreate,Config.PERMISSION_PROJECT) and isStaffHasSkill(staffCreate,Config.Skill_Project)) then
		for index,skill in pairs(staffCreate.skills) do
			if(index == Config.Skill_Project) then
				skillValue = skill.value
			end
		end
	end
	
	
	if(skillValue < math.random(1,100)) then
		reward = math.random(math.floor(0.4*reward),math.floor(0.8*reward))
	else
		reward = math.random(math.floor(0.9*reward),math.floor(1.4*reward))
	end
	

	local isVirtual = math.random(1,10) < 5
	local project = {
		comId = company.id,
		staffId = staffCreate.id,
		reward = math.floor(isVirtual and reward*0.3 or reward),
		isVirtual = isVirtual,
		name = getProjectName(5),
		createTime = company.cmtime,
		endTime = endTime,
		tasks = tasks,
		realReward = 0,
		status = 0
	}
	
	print('project',ESX.DumpTable(project))
	return project
	
end


 function importProject(responseStaff,result,project,callback)
	if(company and company.projects) then
	
		for index,request in pairs(company.requests) do
				if(request.permissonId == Config.PERMISSION_PROJECT and request.targetPedId == project.pedId  and request.status == 0) then
					
					if(not isHaveDelopStaff()) then
						result = false
					end
					
					if(result) then
					
						local indexStart = getNearPosIndexByCoords(GetEntityCoords(request.targetPedId))
						local path  = Mesh.getPath(Config.MESHPOINT, indexStart, Config.POS_86)
						addMeshRoute(request.targetPedId,path,1.0,{{script = Config.Script_DISMISS}}) 
					
						ESX.TriggerServerCallback('xp_company:addProject',function(result,currentProject)
									
									if(result) then
									
										table.insert(company.projects,currentProject)
										--showStaffToBossMessage()
										ESX.TriggerServerCallback('xp_company:doOneRequest',function(result,currentRequest)
										
											if(result) then
												company.requests[index] = currentRequest
												--print('request state update ',ESX.DumpTable(request))
												if(company.requests[index].status == 0 ) then
														company.requests[index].localStart = nil
														company.requests[index].localStatus = nil
														company.requests[index].targetPedId = nil
												end
												
														
											end
											
											callback(result)
											
											print('requests state update ',ESX.DumpTable(company.requests))

										end,request)

										showStaffToBossMessage(responseStaff,TranslateCap('import_project')..project.name)
										
										
									end
									
									callback(result)
									

								end,project)
					else
						pedDismiss(request.targetPedId)
						
						request.localStart = nil
						request.localStatus = nil
						request.targetPedId = nil
						request.initRequestData = nil
						request.startTime = nil
						callback(true)
					end
				
				
					break
				end
		
		end
	end	
end


local function updateProject()
	
	--and ()
	if(company.projects and #company.projects ~= 0 ) then
	
		for index,project in pairs(company.projects) do
				
				if(not project.isFinished and (project.isUpdate or project.status ~= 0)) then
					project.isUpdate = false
					print('update project',project.name)
					ESX.TriggerServerCallback('xp_company:updateProject',function(result)
						if(result) then
							if(project.status ~= 0) then
								project.isFinished = true
							end
							
						end
					end,project,company.cmtime)
					
					--if(project.status ~= 0) then
					--	break
				--	end
					
					
				end
				
				
		end
		
	end
	
		
end


local function doProjects()

	if(not company.staffs) then  return end
	

			--print('doProjects -12 ',ESX.DumpTable(company.projects))
			if(company.projects and #company.projects ~= 0 ) then
			
				for index,staff in pairs(company.staffs) do
					staff.doTaskEnable = true
				end
				
				for index,project in pairs(company.projects) do
				
					
					
				    local staffsGroup = getLeaderStaffsById(project.staffId)
					local leaderProjSkillValue = getStaffSkillValue(getStaffById(project.staffId),Config.Skill_Project)
					if(staffsGroup) then
						
						local cntDo = 0
						for index,staff in pairs(staffsGroup) do

								if(project.status == 0 and not staff.playerId and staff.workStatus == Config.WorkStatus_Working and staff.doTaskEnable) then
									staff.doTaskEnable = false
									local superAblity = getStaffSkillValue(staff)
									
									for skill,task in pairs(project.tasks) do
									
										for i = 1,#staff.skills do
											if(staff.skills[i].id == skill and task.current < task.total) then
												local doValue = math.floor(staff.skills[i].value * staff.honest/100.0)
												if(superAblity >= Config.SuperAbility  and math.random(1,3) == 2) then
													doValue = doValue * 5
												end
												if(doValue < 1) then
													doValue = 2
												end
												
												if(staff.meetingSeatIndex and math.random(1,3) == 2) then
													
													
													
													doValue = math.floor(doValue * 2)
													
												end
												
												
												--项目经理加成
												if(math.random(1,3) == 2 and math.random(0,leaderProjSkillValue) < 80) then
		
													doValue = math.floor(doValue * 2)
													
												end
												
												
												task.current = task.current + doValue
												if(task.current > task.total) then
													task.current = task.total
												end
												project.isUpdate = true
												--print('do task ',skill,staff.id,doValue,task.current..'/'..task.total)
												
											end
										end
										
										
										
									end
								end
								
								
								local isFinish = true
								for skill,task in pairs(project.tasks) do
									if(task.current < task.total) then
										isFinish = false
										break
									end
								end
								
									
								if(project.status == 0 and (company.cmtime.year*360 + company.cmtime.month*30+company.cmtime.day)>project.endTime.year*360 + project.endTime.month*30+project.endTime.day) then
									project.status = 2
								elseif(isFinish) then
									project.status = 1
									if(not project.notify) then
										project.notify = true
										showStaffToBossMessage(getStaffById(project.staffId),project.name ..TranslateCap('projectEnd'))
									end
									
								end
						
						
							cntDo = cntDo + 1
							
							if(cntDo >= 10) then break end
						
						end
						
						
					end
				
				
				
				
				end
				
				

			end

	
end

addTimerSecListener('Project.lua',function()
	
	if(not isCompanyLoaded()) then return end
	
	
	if(secCount%Config.OneMinute == 0) then
	
		updateProject()
		
		addProjectRequest()
	end
	
	--print('dddddd:',secCount%5)
	if(secCount%5 == 0) then
		
		doProjects()
	end
	
end)


