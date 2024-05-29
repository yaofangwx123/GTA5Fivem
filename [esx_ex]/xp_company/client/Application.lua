--不能调换座位到招聘的座位
--部门主管可以在编辑菜单调
--



secCount = 0

local millCnt = 0

RegisterNetEvent('onResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
		TriggerServerEvent('xp:company_help_clearStaffs',GetPlayerServerId(PlayerId()))
		--加载任务
		initCompanyData(true)
		
	end
end)

RegisterNetEvent('xp:company:client:initCompanyData', function()
  print('xp:company:client:initCompanyData')
  initCompanyData(true)
end)


local timerSecsListeners = {}

function addTimerSecListener(key,callback)

	print('addTimerSecListener',key)
	for index,listener in pairs(timerSecsListeners) do
		if(key == listener.key) then
			return
		end
	end

	table.insert(timerSecsListeners,{key = key,callback = callback})

end


function removeTimerSecListener(key)

	for index,listener in pairs(timerSecsListeners) do
		if(key == listener.key) then
			table.remove(timerSecsListeners,index);
		end
	end


end

local function notifyTimerSecListener()

	for index,listener in pairs(timerSecsListeners) do
		listener.callback()
	end


end

CreateThread(function()
		
			while true do 
				millCnt = millCnt + 1
				if(millCnt >= 180) then
					millCnt = 0
					secCount = secCount + 1
					
					notifyTimerSecListener()

				
					
				end
				Wait(1)
			
			end	
end)	



		
AddEventHandler("CEventObjectCollision", function(a, b,c,d,e,f,g)
	--print('CEventObjectCollision',ESX.DumpTable(a),b,ESX.DumpTable(c),d,e,f,g)
	if(a and #a ~= 0) then
		local staff = getStaffByPedId(a[1])
		if(staff) then
			print('Collision ',staff.name)
			ClearPedTasks(a[1])
		end
	end
end)



