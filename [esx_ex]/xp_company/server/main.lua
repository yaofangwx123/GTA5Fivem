--[[
	所有字段需要转json的按照lua格式提交，mysql插入更新会自动encode
	
	
]]


local function isUpdateSucess(result)
	return result and result['affectedRows'] ~= 0
end

ESX.RegisterServerCallback("xp:company:spawnPed",function(source,cb,model,coords)


 
	 --local model = 'a_m_y_vinewood_02' -- Model can be either a string or a hash
	 -- Coords Can either be vector or a table (such as {x = 0, y = 0, z = 0})
	 
	 --首先根据已存在的先获取
	 print('spawnPed',source,cb,model,coords)
	 TriggerEvent('xp:getNetPedByModel',source,model,function(item)
	 
	 
		if(item) then
			
			--[[if(#(GetEntityCoords(item.ped) - Config.CompanyCenter) < 70) then
			
			return
			end]]
			
			
			print("复用",item.netId,#(GetEntityCoords(item.ped) - Config.CompanyCenter))
			cb(exist,item.netId)
			return
			
		end
	 
		
		local Heading = 0 -- Sets the Rotation/Heading the ped spawns at, can be any number
		ESX.OneSync.SpawnPed(model,coords, Heading, function(NetId)
		  Wait(300) -- While not needed, it is best to wait a few milliseconds to ensure the ped is available
		  local Ped = NetworkGetEntityFromNetworkId(NetId) -- Grab Entity Handle From Network Id
		  local exist = DoesEntityExist(Ped) -- returns true/false depending on if the ped exists.
		  print(exist and 'Successfully Spawned Ped!' or 'Failed to Spawn Ped!',model)
		  TriggerEvent('xp:company_help_addStaff',source,{ped = Ped,netId = NetId,model = model})
		  cb(exist,NetId)
		end)

		
	 
	 end)
	 
	 
	
		
	
	
end)

RegisterNetEvent("xp:company:swpveh",function(coords)


		print("bbbb")
	 local model = 'akula' -- Model can be either a string or a hash
	 -- Coords Can either be vector or a table (such as {x = 0, y = 0, z = 0})
	local Heading = 0 -- Sets the Rotation/Heading the ped spawns at, can be any number
	ESX.OneSync.SpawnVehicle(model,coords, Heading,{}, function(NetId)
	  Wait(250) -- While not needed, it is best to wait a few milliseconds to ensure the ped is available
	  local Ped = NetworkGetEntityFromNetworkId(NetId) -- Grab Entity Handle From Network Id
	  local Exists = DoesEntityExist(Ped) -- returns true/false depending on if the ped exists.
	  print(Exists and 'Successfully Spawned Ped!' or 'Failed to Spawn Ped!')
	end)
	
end)

RegisterNetEvent('esx:playerLoaded', function(source, xPlayer, isNew)

	TriggerClientEvent('xp:company:client:initCompanyData', source)


end)

local function getPermissions(cb)
		--查询公司
	--[[MySQL.query('SELECT * FROM `xp_com_permission`',
	{
		
	}, cb)]]
	
	cb(Config.Permissons)
end

local function updateDepartment(department,callback)
		MySQL.query('update xp_com_department set upDepartmentId = ?,name = ?,leaderId = ? where comId = ? and id = ?',
	{
		department.upDepartmentId,
		department.name,
		department.leaderId,
		department.comId,
		department.id
		
	}, callback)
end



local function addFinance(finance)


print('finance',ESX.DumpTable(finance))

if(finance.subType == Config.FinanceSubType_Salary) then
	local salaryFinance = MySQL.single.await('select * from xp_com_finance where comId = ? and  subType = ? and des = ?',{
		finance.comId,
		finance.subType,
		finance.des
	})
	
	if(salaryFinance) then
		return salaryFinance
	end
end

if(not finance.status) then
	finance.status = 0
end

return MySQL.insert.await('insert into `xp_com_finance` (comId,mainType,subType,subId,money,status,des,createTime) VALUES (?,?,?,?,?,?,?,?)',
	{
		finance.comId,
		finance.mainType,
		finance.subType,
		not finance.subId and 0 or finance.subId,
		finance.money,
		finance.status,
		finance.des,
		json.encode(finance.createTime)
		
	})
end

local function getCompanyDepartment(comId,cb)
		--查询公司
		
	MySQL.query('select o.name as leaderName,a.* from xp_com_department as a left join xp_com_staff as o on a.leaderId = o.id where a.comId = ?',
	{
		comId
	}, function(departments)
		for i = 1,#departments do
			for j = 1,#departments do
				if (departments[j].id == departments[i].upDepartmentId) then
					departments[i].upDepartmentName = departments[j].name
				break
				end
			end
		end
		
		cb(departments)
												
											
	end)
end

local function addNotification(notificationData)
	
	local result = MySQL.insert.await('insert into `xp_com_notification` (comId,mainType,data,readed,shortMsg,createTime) VALUES (?,?,?,?,?,?)',
	{
		notificationData.comId,
		notificationData.mainType,
		json.encode(notificationData.data),
		0,
		notificationData.shortMsg,
		json.encode(notificationData.createTime)
		
	})
	
end


	
local function getNotifications(comId,page)
	
	return MySQL.query.await('select * from xp_com_notification where comId = ? order by id desc limit ' .. (page*15)..',15',
	{
		comId
	})
	
end



local function readNotification(comId,notiId)
	local result = MySQL.query.await('update xp_com_notification set status = 1 where comId = ? and id = ?',
		{
			comId,
			notiId
		})
		
	return isUpdateSucess(result)	
end

local function getCompanyStaffs(comId)
		--查询公司
	local result = MySQL.query.await('select xp_com_staff.*,xp_com_department.name as departmentName from xp_com_staff left join xp_com_department on xp_com_staff.departmentId = xp_com_department.id where xp_com_staff.comId = ? and status = 0',
	{
		comId
	})
	return result
	
	
	
end

local function getCompanyProjects(comId,status,cb)
		--查询公司
	MySQL.query('select * from xp_com_project where comId = ? and status = ?',
	{
		comId,status
	}, cb)
	
	
	
end

local function finishProject(comId,id,reward)
	
	return MySQL.query.await('update xp_com_project set realReward = ?,status = 1 where comId = ? and id = ?',
	{
		reward,
		comId,
		id,
		
	})
	
end

local function getCompanyProjectById(comId,id)
		--查询公司
	return MySQL.single.await('select * from xp_com_project where comId = ? and id = ?',
	{
		comId,id
	})
	
	
	
end


local function getCompanyFinances(comId,page)
		--查询公司
	return MySQL.query.await('select * from xp_com_finance where comId = ? order by id desc limit ' .. (page*15)..',15',
	{
		comId
	})
	
	
	
end

local function getCompanyFinancesNum(comId,rowNum)
		--查询公司
	return MySQL.query.await('select * from xp_com_finance where comId = ? and status = 0 limit '..rowNum,
	{
		comId
		
	})
	
	
	
end



local function getCompanyOneFinanceByTypes(comId,subTypes)
		--查询公司
	local typesStr = ''
	for i =1,#subTypes do
		typesStr = typesStr .. subTypes[i] .. ','
	end	
	return MySQL.single.await('select * from xp_com_finance where comId = ? and status = 0 and subType in (?) limit 1',
	{
		comId,
		subTypes
	})
	
	
	
end


local function getStaffsCheck(comId,dayTime)
	
	return MySQL.query.await('SELECT * FROM xp_com_check WHERE comId = ? and dayTime = ?',
		{
			comId,
			dayTime.year..'-'..dayTime.month..'-'..dayTime.day
		})
	
	
	
end

local function addStaff(staff,callback)
	
		--staff.createTime = os.time() * 1000
		MySQL.insert('insert into `xp_com_staff` (name,post,sex,comId, departmentId, model,salary,honest,seatId,skills,playerId,permissons,createTime,status) VALUES (?, ?,?,?, ?,?,?,?,?,?,?,?,?,?)',
	{
		staff.name,
		staff.post,
		staff.sex,
		staff.comId,
		staff.departmentId,
		staff.model,
		staff.salary,
		staff.honest,
		staff.seatId,
		json.encode(staff.skills),
		staff.playerId,
		json.encode(staff.permissons),
		json.encode(staff.createTime),
		0
	}, function(id)
		
		callback(id)
		
	end)
	
end

local function addDepartment(department,callback)

		MySQL.insert('insert into `xp_com_department` (comId,name,upDepartmentId,leaderId,createTime) VALUES (?, ?, ?,?,?)',
	{
		department.comId,
		department.name,
		department.upDepartmentId,
		department.leaderId,
		json.encode(department.createTime)
		
	}, function(id)
		
		print("addDepartment",id)
		callback(id)
		
	end)
end

ESX.RegisterServerCallback('xp_company:getMyCompany', function(source, cb)
	local xPlayer  = ESX.GetPlayerFromId(source)

	--查询公司
	MySQL.query('SELECT * FROM `xp_com_company` WHERE `owner` = @identifier LIMIT 1',
	{
		['@identifier'] 	= xPlayer.identifier
	}, function(result)
		
		print("xp_company:getMyCompany",ESX.DumpTable(result))
		if(#result == 1) then
		    local company = result[1]
			
			company.cmtime = json.decode(company.cmtime)
			local staffs = getCompanyStaffs(company.id)
			
				local staffsCheck = getStaffsCheck(company.id,company.cmtime)
			for i = 1,#staffs do
				staffs[i].skills = json.decode(staffs[i].skills)
				staffs[i].permissons = json.decode(staffs[i].permissons)
				staffs[i].createTime = json.decode(staffs[i].createTime)
				staffs[i].tmpoffwork = staffs[i].tmpoffwork and json.decode(staffs[i].tmpoffwork) or nil
				for j = 1,#staffsCheck do
					if(staffsCheck[j].staffId == staffs[i].id) then
						staffs[i].workSegments = json.decode(staffsCheck[j].workSegments)
					end
				end
				
				if(not staffs[i].workSegments) then
					staffs[i].workSegments = {}
				end
			end
					company.staffs = staffs
					getCompanyDepartment(company.id,function(departments)
						company.departments = departments
						getPermissions(function(permissons)
							company.permissons = permissons
							
							getCompanyProjects(company.id,0,function(projects)
							
								for i = 1,#projects do
									projects[i].tasks = json.decode(projects[i].tasks)
									projects[i].endTime  = json.decode(projects[i].endTime)
								end
							

								company.projects = projects
								
								
								
								
								cb(company)
							end)
							
						end)		
					end) 
			
			
		else
			cb({})	
		end

	end)
end)


ESX.RegisterServerCallback('xp_company:getCompanyOneFinanceByTypes', function(source, cb,comId,subTypes)
	local result = getCompanyOneFinanceByTypes(comId,subTypes)
	cb(result)

end)

ESX.RegisterServerCallback('xp_company:deleteDepartment', function(source, cb,comId,departmentId,cmtime)
	
	local staffs = MySQL.query.await('SELECT * from xp_com_staff WHERE comId = ? and departmentId = ? and status = 0',
		{
			comId,
			departmentId
		})
		
	if(staffs and #staffs ~= 0) then
		print('aaaaaaaa')
		cb(false,TranslateCap('delDpError'))
		return
	end	
		
	local result = MySQL.update.await('DELETE FROM xp_com_department WHERE id = ?', {departmentId})	
	--[[if(result) then
		if(staffs and #staffs ~= 0) then
			local dp = {
			  comId = comId,
			  name = TranslateCap('new_department'),
			  createTime = cmtime
			}
			addDepartment(dp
			,function(id)
				dp.id = id
				MySQL.query('update xp_com_staff set departmentId = ? where comId = ? and status = 0 and departmentId = ?',{id,comId,departmentId},function(result)end)
				cb(result,dp)
			end)
		else
			cb(result)
		end
	else
		cb(result)
	end	]]
	print('bbbbb',result)
cb(result,nil)
	

end)

ESX.RegisterServerCallback('xp_company:getCompanyDepartment', function(source, cb,comId)
	getCompanyDepartment(comId,cb)

end)

ESX.RegisterServerCallback('xp_company:getCompanyFinances', function(source, cb,comId,page)
	local result = getCompanyFinances(comId,page)
	cb(result)
end)

ESX.RegisterServerCallback('xp_company:getNotifications', function(source, cb,comId,page)
	local result = getNotifications(comId,page)
	cb(result)
end)



ESX.RegisterServerCallback('xp_company:getCompanyFinancesNum', function(source, cb,comId,rowNum)
	local result = getCompanyFinancesNum(comId,rowNum)
	cb(result)
end)


ESX.RegisterServerCallback('xp_company:getCompanyFinanceData', function(source, cb,comId)
	
	local result = MySQL.query.await('select mainType,sum(money) as money from xp_com_finance where comId = ? and status = 1 or (mainType = 0) group by mainType',
		{
			comId
		})
	cb(result)
end)

ESX.RegisterServerCallback('xp_company:cancelTask', function(source, cb,task)
	
	local result = MySQL.query.await('update xp_com_request set status = 2 where comId = ? and id = ?',
		{
			task.comId,
			task.id
		})
	cb(isUpdateSucess(result))
end)



ESX.RegisterServerCallback('xp_company:updateStaffHonest', function(source, cb,staffs)
	
	
	for index,staff in  pairs(staffs) do
		local result = MySQL.query.await('update xp_com_staff set honest = ? where comId = ? and id = ?',
		{
			staff.honest,
			staff.comId,
			staff.id
			
		})
	end
	
		
		
	cb(true)
end)			


ESX.RegisterServerCallback('xp_company:getCompanyStaffs', function(source, cb,comId)
	local result = getCompanyStaffs(comId)
	cb(result)
end)

ESX.RegisterServerCallback('xp_company:getPermissions', function(source, cb)
	getPermissions(cb)

end)

ESX.RegisterServerCallback('xp_company:updateDepartment', function(source, cb,department)
	
	local oldDepartment = MySQL.single.await('select * from xp_com_department where id = ? limit 1',
	{
		department.id
	})
	
	local oldDpLeaderId = oldDepartment.leaderId
	
	updateDepartment(department,function(result)
		print("updateDepartment",ESX.DumpTable(result))
		local r = result and result['affectedRows'] ~= 0 
		if(r) then
			if(oldDpLeaderId) then
				MySQL.query.await('update xp_com_project set staffId = ? where staffId = ? and status = 0',
				{
					department.leaderId,
					oldDpLeaderId
					
				})
			end
		end
		cb(r)
	end)

end)

ESX.RegisterServerCallback('xp_company:addStaffSalary', function(source,cb,staff,percent)
	local honest = staff.honest + (math.random(1,3) == 2 and 2 or 0)
	if(honest>100) then
		honest = 100
	end
	local salary = math.floor(staff.salary + staff.salary*percent)
	local result = MySQL.query.await('update xp_com_staff set honest = ?,salary = ? where comId = ? and id = ?',
	{
		honest,
		salary,
		staff.comId,
		staff.id
		
	})
	local isOk = isUpdateSucess(result)
	if(isOk) then
		staff.honest = honest
		staff.salary = salary 		
	end
	
	cb(isOk,staff)
end)

ESX.RegisterServerCallback('xp_company:getCompanyProjectById', function(source, cb,comId,id)
	
	cb(getCompanyProjectById(comId,id))

end)

ESX.RegisterServerCallback('xp_company:addDepartment', function(source, cb,department)
	
		
	addDepartment(department,function(id)
		department.id = id
		cb(id > 0,department)
	end)

end)

ESX.RegisterServerCallback('xp_company:changeProAmin', function(source, cb,params)
	
		local result = MySQL.query.await('update xp_com_project set staffId = ? where id = ?',
	{
		params.staffId,
		params.id
		
	})
	local isOk = isUpdateSucess(result)
	
	cb(isOk)

end)


--更新公司业务
ESX.RegisterServerCallback('xp_company:updateCompanyBusiness', function(source,cb,id,cmtime)
	
		
		MySQL.query('update xp_com_company set cmtime = ? where id = ?',
	{
		json.encode(cmtime),
		id
		
	}, function(result)
		
		print("updateCompanyBusiness",ESX.DumpTable(result))
		cb(result and result['affectedRows'] ~= 0 )
		
	end)
	

end)

ESX.RegisterServerCallback('xp_company:updateProject', function(source,cb,project,time)
	
		print('xp_company:updateProject-call',ESX.DumpTable(project))
		MySQL.query('update xp_com_project set tasks = ?,status = ? where comId = ? and id = ?',
	{
		json.encode(project.tasks),
		project.status,
		project.comId,
		project.id
		
	}, function(result)
		
		if(result) then
						--打钱
			if(project.status == 1) then
			
				
				--[[local xPlayer  = ESX.GetPlayerFromId(source)
				xPlayer.addMoney(project.reward)
				xPlayer.addAccountMoney('bank', project.reward)]]
				
				
				
				
			end
			
			
			
			--先记账
			if(project.status ~= 0) then
				local finance = {
							comId = project.comId,
							mainType = project.status == 1 and Config.FinanceMainType_In or Config.FinanceMainType_Out,
							subType = project.status == 1 and Config.FinanceSubType_ProjectReward or Config.FinanceSubType_ProjectFire,
							subId = project.id,
							money = project.status == 1 and project.reward or math.floor(Config.Project_Fire*project.reward),
							des = project.name,
							createTime = time
						}
						
				print('before add finance ',finance,Config.FinanceMainType_In,Config.FinanceMainType_Out,finance.mainType)		
				addFinance(finance)
			
			end
				
		end
		
		
		print("updateProject",ESX.DumpTable(result))
		cb(result and result['affectedRows'] ~= 0 )
		
	end)
	

end)

ESX.RegisterServerCallback('xp_company:updateStaffFromWeb', function(source, cb,staffs)
	
	print(ESX.DumpTable(staffs))
	
		--[[local result = MySQL.query.await('update xp_com_staff set departmentId = ?,post = ?,salary = ?,seatId = ?,permissons = ? where comId = ? and id = ?',
	{
		staff.departmentId,
		staff.post,
		staff.salary,
		staff.seatId,
		json.encode(staff.permissons),
		staff.comId,
		staff.id
		
	}, function(result)
		
		print("updateStaffFromWeb",ESX.DumpTable(result))
		cb(result and result['affectedRows'] ~= 0 )
		
	end)]]
	
	for index,staff in pairs(staffs) do
		local result = MySQL.query.await('update xp_com_staff set departmentId = ?,post = ?,salary = ?,seatId = ?,permissons = ? where comId = ? and id = ?',
		{
			staff.departmentId,
			staff.post,
			staff.salary,
			staff.seatId,
			json.encode(staff.permissons),
			staff.comId,
			staff.id
			
		})
		
		if(not isUpdateSucess(result)) then
		return cb(false) end
		
	end
	
	cb(true)
	
	
	
	

end)

ESX.RegisterServerCallback('xp_company:addRequest', function(source, cb,request)
	
	print('addRequest',ESX.DumpTable(request))
	
		MySQL.insert('insert into `xp_com_request` (comId,requestId,responseId,cntTotal,cntCurrent,permissonId,workdays,data,status,reportUp,createTime) VALUES (?, ?, ?,?,?,?, ?, ?,?,?,?)',
	{
		request.comId,
		request.requestId,
		request.responseId,
		request.cntTotal,
		0,
		request.permissonId,
		request.workdays,
		json.encode(request.data),
		request.status,
		request.reportUp,
		json.encode(request.createTime)
		
	}, function(id)
		
		print("addRequest",id)
		cb(id)
		
	end)

end)

--[[ESX.RegisterServerCallback('xp_company:updateStaffFromWeb', function(source, cb,staff)
	
	print(ESX.DumpTable(staff))
	
		MySQL.query('update xp_com_staff set departmentId = ?,post = ?,salary = ?,seatId = ?,permissons = ? where comId = ? and id = ?',
	{
		staff.departmentId,
		staff.post,
		staff.salary,
		staff.seatId,
		json.encode(staff.permissons),
		staff.comId,
		staff.id
		
	}, function(result)
		
		print("updateStaffFromWeb",ESX.DumpTable(result))
		cb(result and result['affectedRows'] ~= 0 )
		
	end)

end)]]


ESX.RegisterServerCallback('xp_company:addFinance', function(source, cb,finances)
	
	print('addFinance',ESX.DumpTable(finances))
	
	for i = 1,#finances do
		 addFinance(finances[i])
	end
	

	cb(true)

end)



ESX.RegisterServerCallback('xp_company:deleteStaff', function(source, cb,staff,autoFire,cmtime)
	
	
	
	local result = MySQL.update.await('update xp_com_staff set status = ? WHERE comId = ? and id = ?', {autoFire and 2 or 1,staff.comId,staff.id})
	 MySQL.update.await('update  xp_com_department set leaderId = ? WHERE comId = ? and leaderId = ?', {nil,staff.comId,staff.id})
	--print('deleteStaff-result',ESX.DumpTable(staff),ESX.DumpTable(cmtime),autoFire)
	local isSucess = result and result ~= 0
	if(isSucess) then
	
		if(not autoFire) then
			local payMonth = math.ceil(math.abs((cmtime.year*360 + cmtime.month*30 + cmtime.segment) - (staff.createTime.year*360 + staff.createTime.month*30 + staff.createTime.segment))/10.0)
			print('主动裁员赔偿 ',payMonth*staff.salary)
			local finance = {
							comId = staff.comId,
							mainType = Config.FinanceMainType_Out,
							subType = Config.FinanceSubType_ComDayNormal,
							subId = 0,
							money = payMonth*staff.salary,
							des = TranslateCap('fire_payback'),
							createTime = cmtime
						}
			addFinance(finance)
		end
	
		--删除员工相关
		result = MySQL.update.await('DELETE FROM xp_com_request WHERE comId = ? and responseId = ?', {staff.comId,staff.id})
		
		--增加到消息队列
		if(autoFire) then
			addNotification({
				comId = staff.comId,
				mainType = Config.Notification_Type_AutoFire,
				data = {id = staff.id},
				readed = 0,
				shortMsg = staff.name,
				createTime = cmtime
			
			})
		end
		
		--更新考勤信息
		local checks = MySQL.single.await('SELECT * FROM xp_com_check WHERE comId = ? and staffId = ? and dayTime = ? LIMIT 1', {staff.comId,staff.id,cmtime.year..'-'..cmtime.month..'-'..cmtime.day})
		if(checks) then
			local workSegments = json.decode(checks.workSegments)
			for index,seg in pairs(workSegments) do
				if(seg.seg >= cmtime.segment) then
					seg.on = false
				end
			end
			--print('更新考勤',ESX.DumpTable(workSegments),checks.id)
			local effectRow = MySQL.update.await('update xp_com_check set workSegments = ? where id = ?',{json.encode(workSegments),checks.id})
			--print('effectRow',effectRow)
		end
		
	end
	cb(isSucess)

end)


ESX.RegisterServerCallback('xp_company:doFinance', function(source,cb,finance)
	
	local id = finance.id
	local xPlayer  = ESX.GetPlayerFromId(source)
	local bankMoney = xPlayer.getAccount("bank").money
	 print("doFinance ",ESX.DumpTable(finance))
	local finance =  MySQL.single.await('select * from xp_com_finance where id = ?',
	{
		id
		
	})
	
	if(finance) then
		
		if(finance.subType == Config.FinanceSubType_Salary or
		finance.subType == Config.FinanceSubType_ProjectFire or
		finance.subType == Config.FinanceSubType_ComDayNormal) then
			if(bankMoney < finance.money) then
				cb(false,TranslateCap('regiest_moneyerror'))
			else
				xPlayer.removeAccountMoney('bank',finance.money)
				xPlayer.removeAccountMoney('money',finance.money)
				
				
				--同时更新
				MySQL.query.await('update  xp_com_finance set status = 1 where id = ?',
				{
					id
					
				})
				cb(true,TranslateCap('handle_sucess'))
			end
		elseif(finance.subType == Config.FinanceSubType_ProjectReward) then	

				local project = getCompanyProjectById(finance.comId,finance.subId)
				if(not project or project.status ~= 1) then
					cb(false,TranslateCap('handle_fail'))
					return
				end


				local result = finishProject(finance.comId,finance.subId,project.reward)

				if(not isUpdateSucess(result)) then
					cb(false,TranslateCap('handle_fail'))
					return
				end
				--同时更新

				result = MySQL.query.await('update  xp_com_finance set status = 1 where comId = ? and id = ?',
				{
					finance.comId,
					id
					
				})
				

				
				if(not isUpdateSucess(result)) then
					cb(false,TranslateCap('handle_fail'))
					return
				end
				

				xPlayer.addAccountMoney('money',finance.money)
				xPlayer.addAccountMoney('bank',finance.money)
				
				cb(true,TranslateCap('handle_sucess'))
		
		end
		
	else
		cb(false,TranslateCap('handle_fail'))
	end
	

end)

ESX.RegisterServerCallback('xp_company:addProject', function(source, cb,project)
	
		MySQL.insert('insert into `xp_com_project` (comId,staffId,name,createTime,endTime,tasks,model,reward,realReward,status) VALUES (?, ?,?, ?,?,?,?, ?, ?,?)',
	{
		project.comId,
		project.staffId,
		project.name,
		json.encode(project.createTime),
		json.encode(project.endTime),
		json.encode(project.tasks),
		project.model,
		project.reward,
		0,
		0
		
	}, function(id)
		project.id = id
		print("addProject",id)
		cb(id>0,project)
		
	end)

end)

ESX.RegisterServerCallback('xp_company:doOneRequest', function(source, cb,request)

	print('doOneRequest',ESX.DumpTable(request))
	request.cntCurrent = request.cntCurrent + 1
	if(request.cntCurrent == request.cntTotal) then
		request.status = 1						
	end
	MySQL.query('update xp_com_request set cntCurrent = ?,status = ? where comId = ? and id = ?',
	{
		request.cntCurrent,
		request.status,
		request.comId,
		request.id
		
	}, function(result)
		
		print("doOneRequest",ESX.DumpTable(result))
		cb(result and result['affectedRows'] ~= 0,request)
		
	end)

end)

ESX.RegisterServerCallback('xp_company:getRequests', function(source, cb,comId)

	--查询公司
	MySQL.query('SELECT * FROM `xp_com_request` WHERE `comId` = ? and status = 0',
	{
		comId
	}, function(result)
		
		print("getRequests",result)
		
		cb(result)
		
	end)
end)

ESX.RegisterServerCallback('xp_company:check', function(source, cb,staffs,dayTime)

	--查询公司
	
	
	
	
	
	--[[MySQL.query('SELECT * FROM `xp_com_check` WHERE `comId` = ? and staffId = ? and dayTime = ?',
	{
		comId,
		staffId,
		dayTime.year..'-'..dayTime.month..'-'..dayTime.day
	}, function(result)
	
		if(#result==1) then
			MySQL.query('update `xp_com_check` set workSegments = ?  WHERE `comId` = ? and staffId = ? and dayTime = ?',
			{
				json.encode(workSegments),
				comId,
				staffId,
				dayTime.year..'-'..dayTime.month..'-'..dayTime.day
			}, function(result)

				cb(result)
				
			end)
		else
			MySQL.insert('insert into `xp_com_check` (comId, staffId, dayTime,workSegments) VALUES (?, ?, ?,?)',
			{
				comId,
				staffId,
				dayTime.year..'-'..dayTime.month..'-'..dayTime.day,
				json.encode(workSegments)
				
			}, function(id)
				local result = id > 0 and true or false
				cb(result)
				end)
		end
		
	end)]]--
	

	for i = 1,#staffs do
		local staff = staffs[i]
		--print('check',staff.name,ESX.DumpTable(staff.workSegments))
		local staffCheck = MySQL.single.await('SELECT * FROM xp_com_check WHERE comId = ? and staffId = ? and dayTime = ? limit 1',
		{
			staff.comId,
			staff.id,
			dayTime.year..'-'..dayTime.month..'-'..dayTime.day
		})
		
		if(staffCheck) then
			local updateCheck = MySQL.update.await('update `xp_com_check` set workSegments = ?  WHERE `comId` = ? and staffId = ? and dayTime = ?',
			{
				json.encode(staff.workSegments),
				staff.comId,
				staff.id,
				dayTime.year..'-'..dayTime.month..'-'..dayTime.day
			})
		else
			local insertCheck = MySQL.insert.await('insert into `xp_com_check` (comId, staffId, dayTime,workSegments) VALUES (?, ?, ?,?)',
			{
				staff.comId,
				staff.id,
				dayTime.year..'-'..dayTime.month..'-'..dayTime.day,
				json.encode(staff.workSegments)
				
			})
		end
		
		--同时更新员工的忠诚度
		MySQL.update.await('update `xp_com_staff` set honest = ?  WHERE `comId` = ? and id = ?',
			{
				staff.honest,
				staff.comId,
				staff.id
			})
		
	end
	
	cb(true)
	
end)


ESX.RegisterServerCallback('xp_company:regiestCompany', function(source, cb,name,companyCEOName,sex,identy)
	local xPlayer  = ESX.GetPlayerFromId(source)
	local bankMoney = xPlayer.getAccount("bank").money
	if(bankMoney < Config.RegiestMoney) then
		cb(false,TranslateCap("regiest_moneyerror"))
		return
	end 
	MySQL.insert('insert into `xp_com_company` (owner, name, regiestMoney,regiestTime,status,cmtime) VALUES (?, ?, ?,?,?,?)',
	{
		xPlayer.identifier,
		name,
		Config.RegiestMoney,
		os.time() * 1000,
		1,
		json.encode({year = 0,month = 1,day = 1,segment = 0})
	}, function(id)
		local result = id > 0 and true or false
		if(result) then
			xPlayer.removeAccountMoney("bank",Config.RegiestMoney)
			xPlayer.removeAccountMoney('money',Config.RegiestMoney)
			
			
			local finance = {
							comId = id,
							mainType = Config.FinanceMainType_Out,
							subType = Config.FinanceSubType_ComDayNormal,
							subId = 0,
							money = Config.RegiestMoney,
							status = 1,
							des = TranslateCap('regiest_com'),
							createTime = {year = 0,month = 1,day = 1,segment = 0}
						}
						
			addFinance(finance)			
			
			--add Department
			
			local department = {}
			department.comId = id
			department.name = TranslateCap('departmentCeo')
			
		    department.createTime = {year = 0,month = 1,day = 1,segment = 0}
			
			addDepartment(department,function(id)
				department.id = id
				
				--add ceo
				
				local staff = {}
				staff.name = companyCEOName
				staff.post = TranslateCap('ceo')
				staff.sex  = sex
				staff.comId = department.comId
				staff.departmentId = department.id
				staff.model = nil
				staff.salary = 0
				staff.honest = 100
				staff.seatId = Config.POS_2LevelBossChair 
				staff.skills = {}
				staff.playerId = identy
				staff.permissons = {2,3}
				staff.createTime = {year = 0,month = 1,day = 1,segment = 0}
				
				addStaff(staff,function(id)
				local result = id > 0 and true or false
				staff.id = id
				
				department.leaderId = staff.id
				department.upDepartmentId = department.id
				updateDepartment(department,function(result)
				
				end)
				print('regiest callback')
				cb(result,TranslateCap(result and "regiest_sucess" or "regiest_fail"))
				end)
				
				
			end)
			
			
			
			
			
		end
		
		print("getMyCompany",id)
		
	end)
end)

--[[ESX.RegisterServerCallback('xp_company:addDepartment', function(source, cb,department)
	local xPlayer  = ESX.GetPlayerFromId(source)

		MySQL.insert('insert into `xp_com_department` (comId, level, name,createTime) VALUES (?, ?, ?,?)',
	{
		department.comId,
		department.level,
		department.name,
		os.time() * 1000
	}, function(id)
		local result = id > 0 and true or false
	
		cb(result,TranslateCap(result and "handle_sucess" or "handle_fail"))
		
		
	end)
	
	
end)]]

ESX.RegisterServerCallback('xp_company:addStaff', function(source, cb,staff,cmtime)
	
	addStaff(staff,function(id)
		local result = id > 0 and true or false
		staff.id = id
		
		if(result) then
			
			
			local allSegments = {}
			for i = 0,59 do
				if(i >= Config.WorkTimeAMStart and i <= Config.WorkTimeAMEnd) then
					table.insert(allSegments,{seg = i,on = (i >= cmtime.segment)})
				end
			
			
			local result = MySQL.insert.await('insert into `xp_com_check` (comId,staffId,dayTime,workSegments) VALUES (?, ?, ?,?)',
						{
							staff.comId,
							staff.id,
							cmtime.year..'-'..cmtime.month..'-'..cmtime.day,
							json.encode(allSegments)
							
						})
			end			
			
		end
		
		cb(result,staff)
	end)
	
	
end)


ESX.RegisterServerCallback('xp_company:staffTmpOffWork', function(source, cb,staff,cmtime,startTime,endTime)
	

	local checks = MySQL.single.await('SELECT * FROM xp_com_check WHERE comId = ? and staffId = ? and dayTime = ? LIMIT 1', {staff.comId,staff.id,cmtime.year..'-'..cmtime.month..'-'..cmtime.day})
		if(checks) then
			local workSegments = json.decode(checks.workSegments)
			local startSegment = startTime.year*12*60*30 + startTime.month*60*30 + startTime.day*60 + startTime.segment
			local endSegment = endTime.year*12*60*30 + endTime.month*60*30 + endTime.day*60 + endTime.segment
			for index,seg in pairs(workSegments) do
				local currentSegment = cmtime.year*12*60*30 + cmtime.month*60*30 + cmtime.day*60 + seg.seg
				if(currentSegment >= startSegment and currentSegment <= endSegment) then
					seg.on = false
				end
			end
			print('请假考勤',ESX.DumpTable(workSegments),checks.id)
			local effectRow = MySQL.update.await('update xp_com_check set workSegments = ? where id = ?',{json.encode(workSegments),checks.id})
			print('effectRow',effectRow)
			
			--同时更新员工请假字段
			MySQL.update.await('update xp_com_staff set tmpoffwork = ? where id = ?',{json.encode({startTime = startTime,endTime = endTime}),staff.id})
			
			
			cb(true)
		else
			cb(false)
		end
	
end)

ESX.RegisterServerCallback('xp_company:prepareNewDay', function(source, cb,comId,dayTime)
	
	print('prepareNewDay',comId,dayTime)
	local staffs = getCompanyStaffs(comId)
	if(not staffs) then cb(true) return end
	local time_ = dayTime.year..'-'..dayTime.month..'-'..dayTime.day
	local timeStrNow = json.encode(dayTime)
	
	
	--计算昨日公司开支
	
	--[[local row = MySQL.single.await('SELECT dayTime FROM xp_com_check WHERE comId = ? order by id desc LIMIT 1', {comId})
	print('timeStrNow ',timeStrNow,row)
	if(row and row.dayTime == (dayTime.year..'-'..dayTime.month..'-'..dayTime.day)) then
		row = nil
	end
	
	if(row) then
		print('check company ouu pay ',row.dayTime)
		local checks = MySQL.query.await('SELECT * FROM xp_com_check WHERE comId = ? and dayTime = ?  ', {comId,row.dayTime})
		local salaryTotal = 0
		for index,staff in pairs(staffs) do
			for i,check in pairs(checks) do
				if(check.staffId == staff.id) then
					local segmentWorks = json.decode(check.workSegments)
					local realWorkSegment = 0
					for s,seg in pairs(segmentWorks) do
						if(seg.on) then
							realWorkSegment = realWorkSegment + 1
						end
					end
					local salary = math.floor(staff.salary*realWorkSegment/(Config.WorkTimeAMEnd - Config.WorkTimeAMStart + 1))
					salaryTotal = salaryTotal + salary
					print('add salary',staff.id,salary)
					break
				end
			end
		end
		

		local fianaces = {
							{
							comId = comId,
							mainType = Config.FinanceMainType_Out,
							subType = Config.FinanceSubType_ComDayNormal,
							subId = 0,
							money = Config.conpanyRentMoney,
							des = TranslateCap('cmpRent'),
							createTime = timeStrNow
							},
							{
							comId = comId,
							mainType = Config.FinanceMainType_Out,
							subType = Config.FinanceSubType_ComDayNormal,
							subId = 0,
							money = (#staffs)*math.random(1000,5000),
							des = TranslateCap('cmpDayLife'),
							createTime = timeStrNow
							}}
						if(salaryTotal > 0) then
						
						
							table.insert(fianaces,{
							comId = comId,
							mainType = Config.FinanceMainType_Out,
							subType = Config.FinanceSubType_Salary,
							subId = 0,
							money = salaryTotal,
							des = row.dayTime,
							createTime = timeStrNow
							})
							
							for i = 1,#fianaces do
							addFinance(fianaces[i])
							end	
		
						end
		end	]]	
	
	--获取所有的考勤分组
	local checkGroupTimes = MySQL.query.await('SELECT dayTime FROM xp_com_check WHERE comId = ? GROUP BY dayTime',{comId})
	if(checkGroupTimes) then
		--检查公司账目
		local companySalaryTimes = MySQL.query.await('select des from xp_com_finance where comId = ? and mainType = 0 and subType = 0',{comId})
		--print('checkGroupTimes',ESX.DumpTable(checkGroupTimes),ESX.DumpTable(companySalaryTimes))
		for index1,checkGroupItem in pairs(checkGroupTimes) do
			local isCheckPayed = checkGroupItem.dayTime == time_
			if(not isCheckPayed and companySalaryTimes) then
				for index2,cmpSalaryTime in pairs(companySalaryTimes) do
					if(cmpSalaryTime.des == (TranslateCap('cmpSalary')..' ('..checkGroupItem.dayTime..')')) then
						isCheckPayed = true
						break
					end
				end
				
			end
			--print('isCheckPayed',isCheckPayed,checkGroupItem.dayTime)
			if(not isCheckPayed) then
				
				local checks = MySQL.query.await('SELECT * FROM xp_com_check WHERE comId = ? and dayTime = ?  ', {comId,checkGroupItem.dayTime})
				local salaryTotal = 0
				for index,staff in pairs(staffs) do
					for i,check in pairs(checks) do
						if(check.staffId == staff.id) then
							local segmentWorks = json.decode(check.workSegments)
							local realWorkSegment = 0
							for s,seg in pairs(segmentWorks) do
								
								if(seg.on) then
									realWorkSegment = realWorkSegment + 1
								end
							end
							local salary = math.floor(staff.salary*realWorkSegment/(Config.WorkTimeAMEnd - Config.WorkTimeAMStart + 1))
							salaryTotal = salaryTotal + salary
							--print('add salary',staff.id,salary)
							break
						end
					end
				end
				

				local fianaces = {
									{
									comId = comId,
									mainType = Config.FinanceMainType_Out,
									subType = Config.FinanceSubType_ComDayNormal,
									subId = 0,
									money = Config.conpanyRentMoney,
									des = TranslateCap('cmpRent')..' ('..checkGroupItem.dayTime..')',
									createTime = dayTime
									},
									{
									comId = comId,
									mainType = Config.FinanceMainType_Out,
									subType = Config.FinanceSubType_ComDayNormal,
									subId = 0,
									money = (#checks)*math.random(500,1000),
									des = TranslateCap('cmpDayLife')..' ('..checkGroupItem.dayTime..')',
									createTime = dayTime
									}}
								if(salaryTotal > 0) then
								
								
									table.insert(fianaces,{
									comId = comId,
									mainType = Config.FinanceMainType_Out,
									subType = Config.FinanceSubType_Salary,
									subId = 0,
									money = salaryTotal,
									des = TranslateCap('cmpSalary')..' ('..checkGroupItem.dayTime..')',
									createTime = dayTime
									})
									
									for i = 1,#fianaces do
									addFinance(fianaces[i])
									end	
				
								end
				end
				
			end
			
			
		end
		
		
	
	
	
	
	--生成新的考勤记录
	local row = MySQL.single.await('SELECT * FROM xp_com_check WHERE comId = ? and dayTime = ?  LIMIT 1', {comId,time_})
	--print('timeStrNow ',time_,row)
	if(row == nil) then
		for index,staff in pairs(staffs) do
		
			if(not staff.playerId) then
				
				local allSegments = {}
					for i = 0,59 do
						if(i >= Config.WorkTimeAMStart and i <= Config.WorkTimeAMEnd) then
							
							local isOnWork = true
							--员工有没有请假
							if(staff.tmpoffwork and #staff.tmpoffwork ~= 0) then
								 print(staff.id,staff.tmpoffwork)
								local tmpoffwork = json.decode(staff.tmpoffwork)
								local startSegment = tmpoffwork.startTime.year*12*60*30 + tmpoffwork.startTime.month*60*30 + tmpoffwork.startTime.day*60 + tmpoffwork.startTime.segment
								local endSegment = tmpoffwork.endTime.year*12*60*30 + tmpoffwork.endTime.month*60*30 + tmpoffwork.endTime.day*60 + tmpoffwork.endTime.segment
								local currentSegment = dayTime.year*12*60*30 + dayTime.month*60*30 + dayTime.day*60 + i
								if(currentSegment>=startSegment and currentSegment<=endSegment) then
									isOnWork = false
								end
							end
							
							table.insert(allSegments,{seg = i,on = isOnWork})
							
						end
					end

						local result = MySQL.insert.await('insert into `xp_com_check` (comId,staffId,dayTime,workSegments) VALUES (?, ?, ?,?)',
						{
							comId,
							staff.id,
							time_,
							json.encode(allSegments)
							
						})
				
			end
			
		end
	end

			
	cb(true)

end)

RegisterNetEvent('onResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
		
		print('server resource start call')
		
		--[[CreateThread(function()
		
			while true do
				Wait(1000)
				
			end
		
		end)]]
		
	end
end)