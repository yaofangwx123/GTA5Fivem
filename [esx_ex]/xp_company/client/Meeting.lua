 meetingTime = 0
 meetingNotify = false
 meetingStaffId = nil

 function getRandomMeetingStaffs(staffOpen,num)
	
	if(not company or not company.staffs) then return nil end
	
	local staffIds = {}
	
	for index,staff in pairs(company.staffs) do
		if(not staff.playerId and staff.id ~= staffOpen.id and isStaffExist(staff)) then
			table.insert(staffIds,staff.id)
		end
	end
	
	local staffsJoins = {}
	if(num > #staffIds) then return nil end
	
	while #staffsJoins < num and #staffIds ~= 0 do
		print("idslen",#staffIds)
		local index = math.random(1,#staffIds)
		table.insert(staffsJoins,getStaffById(staffIds[index]))
		
		table.remove(staffIds,index)
	end
	
	return staffsJoins
	
	
end



 function isMeetingOthersReady()
	
	if(meetingTime == 0 or not company.staffs) then return false end
	
	for index,staff in pairs(company.staffs) do
		
		if(staff.id ~= meetingStaffId and staff.meetingSeatIndex and not isStaffSitSeat(staff,staff.meetingSeatIndex)) then 
			return false 
		end
		
	end
	
	return true
	
end

 function isStaffMeeting(staff)
	
	if(not isStaffExist(staff)) then
	return nil end
	
	--[[if(IsPedUsingScenario(staff.pedId,Config.Script_Sit) and #(GetEntityCoords(staff.pedId) - Config.POS[staff.seatId].position) > 3) then
	local entityId,distance = ESX.Game.GetClosestObject(GetEntityCoords(staff.pedId),{[GetHashKey("xm_prop_x17_avengerchair_02")] = true})
	return entityId end]]
	
	return nil
	
end



 function isMeetingRoomEnable()

    
	for i,meetingSeat in pairs(Config.MeetingChairs) do
		if(not meetingSeat.enable) then
			print('meeting not enable sit ',meetingSeat)
			return false
		end
	end
	
	return true

end



 function openMeeting(staffOpen,staffsJoin)
	
	if(meetingTime ~= 0 or not isMeetingRoomEnable() or not staffsJoin or (#staffsJoin + 1) > #Config.MeetingChairs or not isStaffExist(staffOpen)) then
		--print(meetingTime ~= 0,not isMeetingRoomEnable(),not staffsJoin or (#staffsJoin + 1) > #Config.MeetingChairs,not isStaffExist(staffOpen))
	return false end
	

	meetingNotify = false
	meetingTime = math.random(90,360)
	meetingStaffId = staffOpen.id

	
	if(not staffOpen.playerId) then
		--local path  = Mesh.getPath(Config.MESHPOINT, getNearPosIndexByCoords(GetEntityCoords(staffOpen.pedId)), Config.POS_143)
		--addMeshRoute(staffOpen.pedId,path,Config.Default_speed,{{script = Config.Script_Sit,data = Config.POS_143}})
		staffOpen.meetingSeatIndex = Config.POS_143
	end
	
	for index,staff in pairs(staffsJoin) do
		if(not staff.playerId and isStaffExist(staff) and not isPedBusyRequest(staff.pedId)) then
		
		
			local i = #Config.MeetingChairs
			while(i >= 1) do
				local meetingSeat = Config.MeetingChairs[i]
				if(meetingSeat.enable and meetingSeat.index ~= Config.POS_143) then
					meetingSeat.enable = false
					staff.meetingSeatIndex = meetingSeat.index
					break
				end
				
				i = i - 1
				
			end
		
			--[[for i,meetingSeat in pairs(Config.MeetingChairs) do
				if(meetingSeat.enable and meetingSeat.index ~= Config.POS_143) then
					meetingSeat.enable = false
					staff.meetingSeatIndex = meetingSeat.index
					
					
					break
				end
					
		
			end]]
			
			
		end
		
	end
	
	
	
	showStaffMessage(staffOpen,TranslateCap('msg_openmeeting')..meetingTime)
	
	return true
	
	
end

 function isStaffOpenMeeting()
 
    if(not company.staffs) then return end

	
	for index,staff in pairs(company.staffs) do
	
		local isOk = true
		if(meetingTime ~= 0 or not isMeetingRoomEnable() or staff.playerId or not isTimeWork() or not isStaffExist(staff) or isPedBusyRequest(staff.pedId) or IsPedUsingScenario(staff.pedId,Config.Script_Sit) ~= 1) then isOk = false  end
	
		--条件能力
		local isDpManager = false
		if(isOk) then
			local isHightPercent = false
			
				for index,dp in pairs(company.departments) do
					if(dp.leaderId == staff.id) then
						isHightPercent = true
						isDpManager = true
						break
					end
				end
			
			
			if(not isHightPercent and math.random(1,5) == 2) then
				isHightPercent = Config.POS[staff.seatId].leaderChair
			end
		
			if(not isHightPercent) then isOk = false end
		end
		
		
		if(isOk and staff.id == meetingStaffId and not  math.random(1,10) ~= 3) then isOk = false end
		
		if(isOk and math.random(1,20) ~= 2 or math.random(1,100) > staff.honest) then isOk = false end
		
		local num = 0
		if(isOk) then
			num = math.random(1,#company.staffs - 1)
			if(num < 2) then isOk = false end
		end
		
		local  joinsStaffs = nil
		if(isOk) then
			if(isDpManager) then
				if(math.random(1,10) >= 8) then
					joinsStaffs = getLeaderStaffsById(staff.id)
					while(joinsStaffs and #joinsStaffs >13) do
						table.remove(joinsStaffs,#joinsStaffs)
					end
				end
			end
			if(not joinsStaffs) then
				joinsStaffs = getRandomMeetingStaffs(staff,num)
			end
			
			if(not joinsStaffs or #joinsStaffs == 0) then isOk = false end
		end
		
		if(isOk) then
			openMeeting(staff,joinsStaffs)
			break
		end
		
	end
 
	
	
end

local function staffGoMeeting()

if(not company.staffs) then return end

	
	for index,staff in pairs(company.staffs) do
		local isAllAready = isMeetingOthersReady()
		if(staff.meetingSeatIndex and  not isStaffSitSeat(staff,staff.meetingSeatIndex)) then
			
			
			if(staff.id ~= meetingStaffId or (isAllAready and staff.id == meetingStaffId) ) then
				
				local isGoing = false
				local meshItem = isPedMeshing(staff.pedId)
				if(meshItem and meshItem.routeGroup[#meshItem.routeGroup][#meshItem.routeGroup[#meshItem.routeGroup]] == staff.meetingSeatIndex) then
					isGoing = true
				end
				
				if(not isGoing) then
					goMeeting = false
					--ClearPedTasksImmediately(staff.pedId)
					pedStand(staff.pedId)
					resetStaffScript(staff)
					local path  = Mesh.getPath(Config.MESHPOINT, getNearPosIndexByCoords(GetEntityCoords(staff.pedId)), staff.meetingSeatIndex)
					addMeshRoute(staff.pedId,path,Config.Default_speed,{{script = Config.Script_Sit,data = staff.meetingSeatIndex}})
					
					print('openmeeting-path-------------------------------->',staff.name)
				end
			end

		end
	end
end

local function meetingEffect()
	
	local isMeetingHumanResource = false
	local staffAbilityValue = 0
	if(meetingTime ~= 0) then
		local stff = getStaffById(meetingStaffId)
		isMeetingHumanResource = isStaffHasPermisson(stff,Config.PERMISSION_Hire)
		staffAbilityValue = getStaffSkillValue(stff)
		if(meetingStaffId == company.myStaffId) then
			staffAbilityValue = 100
		end
	end
	for index,staff in pairs(company.staffs) do
			

		if(isMeetingHumanResource) then
									
			if(staff.honest < 100 and math.random(1,500) < staffAbilityValue) then
					staff.honest = staff.honest + 1

					ESX.TriggerServerCallback('xp_company:updateStaffHonest',function(result)
					  print('staff honest is update ',staff.id,staff.honest)
					end,{staff})
			end

			
		end
	end
	
end

addTimerSecListener('Meeting.lua',function()
	
	
	if(not isCompanyLoaded()) then return end
	
		if(meetingTime > 0) then
			meetingTime = meetingTime - 1			
		end
	
	
	if(not isWorkTime) then
		
		 if(meetingTime > 0) then
			meetingTime = 0
	     end	
		
		
	end
	
	if(isMeetingOthersReady() and not meetingNotify and company.myStaffId == meetingStaffId) then
			meetingNotify = true
			showMsg(TranslateCap('msg_meetingalready'))
	end
	
	if(secCount%5 == 0) then
		isStaffOpenMeeting()
		staffGoMeeting()
		meetingEffect()
	end
	
	
end)