 financeList = {}
 isFinanceNomoreData = false







 function comfirnFinance(result,finance,callback)
	print('comfirnFinance',finance)
	if(result) then
		ESX.TriggerServerCallback('xp_company:doFinance',function(result,msg)
									

			for i = 1,#company.requests do
				if(company.requests[i].subId == finance.id) then
			
					
			
					--回去
					if(company.requests[i].permissonId == Config.PERMISSION_SALARY or 
					company.requests[i].subType == Config.FinanceSubType_ProjectFire) then
						local staff = getStaffById(company.requests[i].responseId)
						local indexStart = getNearPosIndexByCoords(GetEntityCoords(staff.pedId))
						local path  = Mesh.getPath(Config.MESHPOINT, indexStart, staff.seatId)
						addMeshRoute(staff.pedId,path,Config.Default_speed,{{script = Config.Script_Sit,data = staff.seatId}})
						
						if(finance.subType == Config.FinanceSubType_Salary)then
							
							for index,staff in pairs(company.staffs) do
								if(not staff.playerId and math.random(1,3) == 2 and staff.honest < 100) then
									staff.honest = staff.honest + 1
								end
								
							end
						
						
							ESX.TriggerServerCallback('xp_company:updateStaffHonest',function(result)
							
								if(result) then
									showStaffToBossMessage(staff,TranslateCap('msg_payhappy'))
								end
							
							
							end,company.staffs)
							
							
						
						end	
						
					elseif(company.requests[i].permissonId == Config.PERMISSION_PROJECT) then
						pedDismiss(company.requests[i].targetPedId)
					end
					
						company.requests[i].localStart = nil
						company.requests[i].localStatus = nil
						company.requests[i].targetPedId = nil
						company.requests[i].startTime = nil
						company.requests[i].initRequestData = nil
					
					if(result) then
						
						if(company.requests[i].permissonId == Config.PERMISSION_PROJECT and company.requests[i].subType ~= Config.FinanceSubType_ProjectFire) then
							showStaffToBossMessage(getStaffById(company.requests[i].responseId),TranslateCap('projectpayed',company.requests[i].project.name))
							--同时移除project
							--[[for p,project in pairs(company.projects) do
								if(company.requests[i].project.id == project.id) then
									table.remove(company.projects)
									break
								end
							end]]
						end
						
						
						table.remove(company.requests,i)
						
						for index = 1,#financeList do
							if(financeList[index].id == finance.id) then
								table.remove(financeList,index)
								break
							end
						end

						
					end


					break
				end
			end
			
		
		
		callback(result)
		

	end,finance)
	else
			
		for i = 1,#company.requests do
			if(company.requests[i].subId == finance.id) then
				
				--回去
					if(company.requests[i].permissonId == Config.PERMISSION_SALARY) then
						local staff = getStaffById(company.requests[i].responseId)
						local indexStart = getNearPosIndexByCoords(GetEntityCoords(staff.pedId))
						local path  = Mesh.getPath(Config.MESHPOINT, indexStart, staff.seatId)
						addMeshRoute(staff.pedId,path,Config.Default_speed,{{script = Config.Script_Sit,data = staff.seatId}})
					elseif(company.requests[i].permissonId == Config.PERMISSION_PROJECT) then
						local indexStart = getNearPosIndexByCoords(GetEntityCoords(company.requests[i].targetPedId))
						local path  = Mesh.getPath(Config.MESHPOINT, indexStart, Config.SwapPoints[math.random(1,#Config.SwapPoints)])
						addMeshRoute(company.requests[i].targetPedId,path,Config.Default_speed,{{script = Config.Script_DISMISS}})	
					end
					
					company.requests[i].localStart = nil
					company.requests[i].localStatus = nil
					company.requests[i].targetPedId = nil
					company.requests[i].startTime = nil
					company.requests[i].initRequestData = nil
				break
			end
		end
		
		callback(true)
			
	end
	
end