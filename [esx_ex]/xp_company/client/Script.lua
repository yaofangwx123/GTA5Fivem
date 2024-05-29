 function createRandomEvent(staff)
	
	if(not isStaffExist(staff) or staff.meetingSeatIndex) then return end
	--print('createRandomEvent',staff.id,'run',staff.script,not isPedBusyRequest(staff.id), not isStaffBusyTalking(staff),staff.workStatus == Config.WorkStatus_Working,IsPedUsingScenario(staff.pedId,Config.Script_Sit))
	if(  not isPedBusyRequest(staff.id) and not isStaffBusyTalking(staff) and  staff.workStatus == Config.WorkStatus_Working and IsPedUsingScenario(staff.pedId,Config.Script_Sit))then
		
		if(math.random(1,50) == 5) then
			--print('staff go to talk to staff-1')
			--找领导谈话
			--[[local leaderStaff = getLeaderStaff(staff)
			
			if(staff.id == leaderStaff.id) then
				return
			end]]
			
			for index,staff_ in pairs(company.staffs) do
				if(staff.id ~= staff_.id  and not isPedBusyRequest(staff_.id) and not isStaffBusyTalking(staff_) and  staff_.workStatus == Config.WorkStatus_Working and IsPedUsingScenario(staff_.pedId,Config.Script_Sit)
				) then
					
					local path  = Mesh.getPath(Config.MESHPOINT, staff.seatId, getNearPosIndex(staff_.seatId))
					addMeshRoute(staff.pedId,path,Config.Default_speed,{{script = Config.Script_Def_Talk,data = {total = math.random(10,30),toPedId = staff_.pedId}}})
					--print('staff go to talk to staff-2')
					break
					
				end
			end
		elseif((math.random(1,100) > staff.honest and math.random(1,10) == 5) or math.random(1,200) == 5) then
			
			local tagertPosition = Config.AniPos[math.random(1,#Config.AniPos)]
			if(not Config.POS[tagertPosition].isChair) then
				
				local aniIndex = math.random(1,#Config.Animations)
				local path  = Mesh.getPath(Config.MESHPOINT, staff.seatId, tagertPosition)
				addMeshRoute(staff.pedId,path,Config.Default_speed,{{script = Config.Animations[aniIndex].ani,data = {total = math.random(20,35) + (100 - math.random(staff.honest,100))}}})

				
			end
		end
		
	end

	
end

