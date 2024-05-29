 tasks = {}
 function resetStaffRequest(staff)
	if(not staff) then return false end
	local isCurrentRequest = false
	for index,request in pairs(company.requests) do
		if(request.responseId == staff.id) then
				if(request.localStatus == 'ped is areadyPos') then
					isCurrentRequest = true
				end
				request.localStart = nil
				request.localStatus = nil
				request.startTime = nil
		end
	end
	
	return isCurrentRequest
end

 function clearStaffRequest(staff)
	if(not staff or not company.requests) then return end
	
	
	
	local index = 1
	while true do
	
		if(#company.requests >= index) then
			if(company.requests[index].responseId == staff.id) then
				if(company.requests[index].targetPedId and DoesEntityExist(company.requests[index].targetPedId) and isStaff and not getStaffByPedId(company.requests[index].targetPedId)) then
					pedDismiss(company.requests[index].targetPedId)
				end
				table.remove(company.requests,index)
				index = index - 1
			end
		end
	
		if(#company.requests == 0 or #company.requests == index) then 
		return end
		
		index = index + 1
		
	end
	
end

 function getRequestById(requestId)
	if(not company or not company.requests) then return nil end
	
	for index,request in pairs(company.requests) do
		if(request.id == requestId) then
		return request end
	end
	
	return nil
end

 function setRequestFinish(requestId)
	if(not company or not company.requests) then return end
	
	for index,request in pairs(company.requests) do
		if(request.id == requestId) then
			request.status = 1
		return end
	end
	
end

 function isRequestExistFinance(id)
	if(company and company.requests) then
		for i = 1,#company.requests do
			if(company.requests[i].subId == id) then
				return true
			end
		end
	end
	
	return false
end

 function isRequestExistPermission(responseId,permissonId)
	if(company and company.requests) then
		for i = 1,#company.requests do
			if(company.requests[i].permissonId == permissonId and responseId == company.requests[i].responseId) then
				return true
			end
		end
	end
	
	return false
end

 function getRequestStartTime(secCount)

	if(Config.debug) then return 1 end

	if(true) then
		return secCount + math.random(60,180)
	end

	local range = 0
	if(company.cmtime.segment >= Config.WorkTimeAMStart and company.cmtime.segment <= Config.WorkTimeAMEnd) then
		range = Config.WorkTimeAMEnd - company.cmtime.segment
	end
	if(range >= 2) then
		if(Config.Debug) then return 1 end
		--return {year = company.cmtime.year,month = company.cmtime.month,segment}
		--return os.time() + math.random(30,range*60)
		--if(true) then return math.random(10,30) end
		return secCount + math.random(Config.OneMinute/2,range*Config.OneMinute)
	else
		return 60
	end
	
end

 function getRequestTargetPedId(pedId)
	if(company == nil or company.requests == nil) then return nil end
	for index,request in pairs(company.requests) do
		if(request.targetPedId == pedId) then
			return request
		end	
	end
	return nil
end

 function doOneRequest(requestId,callback,request)
		
			
		    if(not request) then
				request = getRequestById(requestId)
			end
			
			print('doOneRequest',requestId,request)
			if(not request) then
				print('not request')
			return callback(false) end
		
			ESX.TriggerServerCallback('xp_company:doOneRequest',function(result,request)
										
											if(result) then
										
												setRequestFinish(request)
												
														
											end
											
											callback(result)
											
											print('requests state update-2 ',ESX.DumpTable(company.requests))

										end,request)
		
end