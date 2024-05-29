 naviMesh = {}
 naviMeshQuee = {}

 function getNearPosIndex(coordIndex)
	local lastDistance = 10000
	local coordPos = Config.POS[coordIndex].position
	local indexTarget = coordIndex
	for index,pos in pairs(Config.POS) do
		if(index ~= coordIndex) then
			local distance = #(coordPos - pos.position)
			if(distance < lastDistance) then
				indexTarget = index
				lastDistance = distance
			end
		end
		
	end
	return indexTarget
end

local function printPath(path)
	local str = ""
	for k,v in pairs(path) do
		--print(k,v,ESX.DumpTable(Config.POS[v]))
		str = str ..'['..v..']'.. Config.POS[v].name..' -> '
	end
	print(str)
end


 function routeMeshEnd(pedId,isSucess)
	
	--检查是否在请求列表中的ped
	
	if(company and company.requests) then
		for index,request in pairs(company.requests) do
			if(request.targetPedId == pedId) then
				request.routeResult = isSucess
				request.localStatus = 'mesh finish'
				return
			end
		end
	end
	
	--闲杂人等一律请出办公室
	
end



 function startRoute(pedId,pointIndexs,speed)
	 
	 
		
	 
		local staff = getStaffByPedId(pedId)
		if(staff ~= nil) then
			
				local sitScript = IsPedUsingScenario(pedId,Config.Script_Sit)
				print('ped sit script check-startRoute ',staff.pedId,sitScript)
				if(sitScript == 1) then

					pedStand(pedId)
					
					Wait(100)
					
				end
			

			if(staff.script) then
				staff.script = nil
			end
			
		end
		
		TaskFlushRoute()
		print("startRoute",pedId,pointIndexs,speed,#naviMesh,'******************************************')
		for k,v in pairs(pointIndexs) do
			TaskExtendRoute(Config.POS[v].position)
		end
		 TaskFollowPointRoute(pedId,speed,0)
end

 function pathToGroup(path)
		local pathGroup = {{}}
		local  groupIndex = 1
		for i = 1,#path do
			if(#pathGroup[groupIndex] == 8) then
				table.insert(pathGroup,{path[i-1]})
				groupIndex = groupIndex + 1
			end
			table.insert(pathGroup[groupIndex],path[i])
		end
	return pathGroup	
end

 function isPedMeshing(pedId)

		
		for i = 1,#naviMesh do
			if(naviMesh[i].pedId == pedId) then
				return naviMesh[i]
			end
		end
		
		return nil

end


local table_num = {"0","1","2","3","4","5","6","7","8","9"}
local table_char = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"}

 function getSN(n)
	
	local s = table_char[math.random(#table_char)]
	for i =1, n do
		s = s .. table_num[math.random(#table_num)]
	end
	return s
end

 function addMeshRoute(pedId,path,speed,endScript,delay)


		--如果该ped还有其他路径，则需要将之前的路径移除
		
		local index = 1
		while index <= #naviMesh do
			if(naviMesh[index].pedId == pedId) then
				print('clear old mesh navi',pedId,naviMesh[index].id)
				table.remove(naviMesh,index)
				--ClearPedTasksImmediately(pedId)
				
			else
				index = index + 1
			end
		end

		local pathGroup = pathToGroup(path)
		--print('addMeshRoute',pedId,ESX.DumpTable(pathGroup),ESX.DumpTable(endScript))

		--由于routine pool限制，当大于等于20的时候则先加入缓存池
		local naviItem = {
						id = getSN(5),
						pedId = pedId,
						startTime = secCount + (delay and delay or 0),
						speed = Config.Default_speed,
						endScript = endScript,
						routeGroup = pathGroup, --数组，因为最大寻路8个
						currentPathGroupIndex = 1,--当前寻路的组索引
						currentPathIndex = 1,--当前组列表哪一步的索引
						retryCount = 0,      --当判断到异常时，则再次尝试，最大尝试次数3
						status = 1 --0:没有在寻路 1:正在寻路 2：寻路异常，可能需要重新寻路
					}
		if(#naviMesh >= Config.RoutineMaxPool or naviItem.startTime > secCount) then
			
			table.insert(naviMeshQuee,naviItem)
			return
			
		
		end

		table.insert(naviMesh,naviItem)
end

addTimerSecListener('Mesh.lua',function()
	
	if(not isCompanyLoaded()) then return end
	
	local index = 1
				--print('meshing-------')
				while naviMesh[index] do
					item = naviMesh[index]
					--print('naviItem',ESX.DumpTable(item))
					--如果是坐的，则需要0.5的距离
					local isSitMesh = false
					if(item.endScript) then
						for si = 1,#item.endScript do
							
							if(item.endScript[si].script == Config.Script_Sit) then
								isSitMesh = true
								break
							end
						end
					end					
					
					
					if(item.status == 0 or not DoesEntityExist(item.pedId) or GetEntityHealth(item.pedId) == 0) then
						--print('remove navimesh ',item.id)
						table.remove(naviMesh,index)
						
					elseif (item.status == 1) then
						index = index + 1
						local group = item.routeGroup[item.currentPathGroupIndex]
						
						
						
						local pedSpeed = GetEntitySpeed(item.pedId)
						--[[if(isSitMesh and pedSpeed ~= 0) then
							local pos = group[#group]
							local stopDistance = #(pedCoords - Config.POS[pos].position)
							if(stopDistance <= Config.SitDistance) then
								ClearPedTasksImmediately(pedId)
								pedSpeed = 0
								print('force stop-------------------------')
							end
						end]]
						
						if(pedSpeed == 0) then
							local pedCoords = GetEntityCoords(item.pedId)
							local stopDistance = GetDistanceBetweenCoords(pedCoords,Config.POS[group[#group]].position,false)
							local targetDistance = isSitMesh and Config.SitDistance or 1.0
							print('stopDistance',stopDistance,targetDistance)
							if( stopDistance < targetDistance) then
								
							    if(item.currentPathGroupIndex == #item.routeGroup) then
									item.status = 0
									print("Navi path sucess ",item.pedId,stopDistance)
									local isBack = false
									if(item.endScript) then
										for si = 1,#item.endScript do
											
											if(item.endScript[si].script == Config.Script_DISMISS) then
												isBack = true	
												DeleteEntity(item.pedId)
												local staff = getStaffByPedId(item.pedId)
												if(staff) then
													
													staff.pedId = nil
													staff.workStatus = nil
													
												end
											elseif(item.endScript[si].script == Config.Script_Sit) then
												isBack = true
		
												
												
												local staff = getStaffByPedId(item.pedId)
												if(staff) then
													if(staff.workStatus == Config.WorkStatus_GoToWork) then
														staff.workStatus = Config.WorkStatus_Working
													end
													staff.scriptFailNum = 0
													staff.script =  Config.Script_Sit
													
													
												end
											elseif(item.endScript[si].script == Config.Script_Doing) then

												local staff = getStaffByPedId(item.pedId)
												if(staff) then
													
													if(isPedNearPos(PlayerPedId(),item.endScript[si].data.targetStaff.seatId)) then
														
														
														if(item.endScript[si].data.targetStaff.id == company.myStaffId) then
																if(not isHtmlShow) then
																	local reqData = {action = 'open',reqData = staff,doType = item.endScript[si].data.doType,baseData = item.endScript[si].data.tmpTime}
																	switchHtml(true,reqData)
																end
																
														else
															tmpOffWorkJuge(item.endScript[si].data.targetStaff,staff,item.endScript[si].data.tmpTime,math.random(1,5) < 20,function(result)--testfor
															
																
															
															end)
														end
													else
															staffBackSeat(staff)
															if(math.random(1,3) == 2) then
																 staff.honest = staff.honest - 5
																 if(staff.honest < 0) then
																	staff.honest = 0
																 end
																ESX.TriggerServerCallback('xp_company:updateStaffHonest',function(result)
																
																end,{staff})
															end
													end
													
													
													
													
													
												end	
											else

												--执行动画
												local staff = getStaffByPedId(item.pedId)
												if(staff) then
													if(item.endScript[si].script ~= Config.Script_Def_Talk) then
															staff.workStatus = Config.WorkStatus_OffToWork
													end
														
														staff.script =  item.endScript[si].script
														staff.scriptTime = item.endScript[si].data.total
														staff.scriptToPedId = item.endScript[si].data.toPedId
														staff.scriptTimeCnt = 0
													
												end
												
														
												
												
											end
										end
									end
									if(not isBack) then
										routeMeshEnd(item.pedId,true)
									end
									
								else 
									
									
									
									if(#naviMesh >= Config.RoutineMaxPool) then
										print('Navi path next add new route ',item.pedId)
										item.status = 0
										local nPath = {}
										for k = 1,#item.routeGroup do
											if(k >= item.currentPathGroupIndex) then
												for u = 1,#item.routeGroup[k] do
													table.insert(nPath,item.routeGroup[k][u])
												end
											end	
										end
										
										addMeshRoute(item.pedId,nPath,item.speed,item.endScript)
									else
										item.retryCount = 0
										item.currentPathGroupIndex = item.currentPathGroupIndex + 1
										print("Navi path next rightnow",item.pedId,item.currentPathGroupIndex)
										startRoute(item.pedId,item.routeGroup[item.currentPathGroupIndex],item.speed)
									end
									
									
								end
								
								
							else
								print('retry account ',item.retryCount)
								if(item.retryCount < 5) then
								
								
								
									item.retryCount = item.retryCount + 1
									
									--[[local minDiscance = -1
									local startIndex = 1
									for i,v in pairs(group) do
										local distance = #(Config.POS[v].position - pedCoords)
										if(minDiscance == -1 or distance < minDiscance) then
											minDiscance = distance
											startIndex = i
											print("Navi retry latestindex ",startIndex)
										end
									end
									
									
									if(startIndex ~= 1 and item.retryCount >= 5) then
										startIndex = startIndex - 1
									end
									
									if(startIndex < 1) then
										startIndex = 1
									end
									
									
									if(i ~= startIndex) then
										item.routeGroup[item.currentPathGroupIndex] = {}
										for i,v in pairs(group) do
											if(i >= startIndex) then
												table.insert(item.routeGroup[item.currentPathGroupIndex],v)
											end
										end
									end
									
									print("Navi retry count ",item.pedId,item.retryCount,stopDistance,ESX.DumpTable(item.routeGroup))]]
									
									
										
				
											
											
											local indexLatest = getNearPosIndexByCoords(GetEntityCoords(item.pedId))
											local lastGroup = item.routeGroup[#item.routeGroup]
											local lastPosIndex = lastGroup[#lastGroup]
											
											
											
											if(lastPosIndex == indexLatest) then
												
												--[[if(#lastGroup > 1) then
													indexLatest = lastGroup[#lastGroup - 1]
												end]]
												print('go straaight')
													TaskGoStraightToCoord(item.pedId,Config.POS[lastPosIndex].position.x,Config.POS[lastPosIndex].position.y,Config.POS[lastPosIndex].position.z,1.0,-1,0,0)
													Wait(1000)
													
												else
												
													if(lastPosIndex ~= indexLatest) then
														print('indexLatest',indexLatest,'lastPosIndex',lastPosIndex,'status',item.status)
														local path  = Mesh.getPath(Config.MESHPOINT, indexLatest, lastPosIndex)
														
														
														if(#naviMesh >= Config.RoutineMaxPool) then
															print('retry new path is ',ESX.DumpTable(path))
															item.status = 0
															addMeshRoute(item.pedId,path,item.speed,item.endScript)
														else
															item.routeGroup = pathToGroup(path)
															item.currentPathGroupIndex = 1
															item.currentPathIndex = 1
															print('retry new path is ',item.pedId,ESX.DumpTable(item.routeGroup))
															startRoute(item.pedId,item.routeGroup[item.currentPathGroupIndex],item.speed)
														end
														
														
														
														
														
														
													end	
												end
												
									
										
								else
									print('retry account-fail ',item.retryCount)
								   item.status = 0
								   routeMeshEnd(item.pedId,false)
								   print("Navi retry fail ",item.pedId)
								   local staff = getStaffByPedId(item.pedId)
								   if(staff) then
										print("staff retry mesh ",staff.name)
										local coordsNow = GetEntityCoords(staff.pedId)
										DeleteEntity(item.pedId)

										if(staff.workStatus == Config.WorkStatus_OffToWork) then
											staff.pedId = nil
											staff.workStatus = nil
								
										else
											Wait(10)
											swapStaff(staff,math.random(1,#Config.SwapPoints),getNearPosIndexByCoords(coordsNow))
										end
										
								   end
								   
								   --[[local request = getRequestTargetPedId(item.pedId)
								   if(request ~= nil and request.localStatus == 'give up') then
										request.localStart = nil
										request.localStatus = nil
										request.targetPedId = nil
										print('reset ped give up')
								   end]]
								   
								end
									
							end
						end						
					end
				
				end
					Wait(100)
			
				--[[while #naviMesh < Config.RoutineMaxPool and #naviMeshQuee ~= 0 do
					
					table.insert(naviMesh,naviMeshQuee[1])
					table.remove(naviMeshQuee,1)
					
					print('Add NaviQuee ',#naviMesh,#naviMeshQuee)
				end]]
				
				if(#naviMesh < Config.RoutineMaxPool and #naviMeshQuee ~= 0) then
					for a = 1,#naviMeshQuee do
					
						if(#naviMesh >= Config.RoutineMaxPool) then
							break
						end
					
						if(naviMeshQuee[a] and (not naviMeshQuee[a].startTime  or naviMeshQuee[a].startTime <= secCount)) then
							table.insert(naviMesh,naviMeshQuee[a])
							table.remove(naviMeshQuee,a)
							
							print('Add NaviQuee ',#naviMesh,#naviMeshQuee,a)
							
							a = a - 1
						else
							print('cannot add naviquee',naviMeshQuee[a],naviMeshQuee[a] and naviMeshQuee[a].startTime or -1,secCount)
						end
					
					end
				end
				
				
				if(#naviMeshQuee ~= 0) then
					print('naviMeshQuee',ESX.DumpTable(naviMeshQuee))
				end
	
	
end)


