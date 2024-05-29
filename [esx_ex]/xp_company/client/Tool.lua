 function caculateDaysAdd(times,days)


	local totalDays = times.year * 12 + times.month * 30 + times.day + days
	local year = math.floor(totalDays/360)
	local month = math.floor((totalDays - year*360)/30)
	local day = math.floor((totalDays - year*360 - month*30)%30)	
	return {year = year,month = month,day = day,segment = 59}  
		
	
end

 function isTimeOutDate(cmtime,times)
	return (times.year * 12 + times.month * 30 + times.day ) < (cmtime.year * 12 + cmtime.month * 30 + cmtime.day)
end


 function makeSkills(salary,skills,isFullSkill)
	local result = {}
	local totalSaray = tonumber(salary)
	for i = 1,#skills do
		local skillItem = Config.Skills[skills[i]]
		local skill = {id = skillItem.id,name = skillItem.name}
		if(totalSaray >= skillItem.rate) then
			skill.value = isFullSkill and 100 or math.random(50,100)
			totalSaray = totalSaray - skillItem.rate
		elseif(totalSaray >= 0 and  totalSaray < skillItem.rate) then
			local valueMin = math.floor(100 * totalSaray / skillItem.rate)
			if(valueMin < 5) then
				valueMin = 5
			end
			
			local max = valueMin + 20
			
			if(max > 100) then
				max = 100
			end
			
			skill.value = math.random(valueMin,max)
			totalSaray = 0
		else
			skill.value = math.random(5,10)
		end
		
		table.insert(result,skill)
	end
	
	return result
end

local function  reverseTable(tab)  
    local tmp = {}  
    for i = 1, #tab do  
        local key = #tab  
        tmp[i] = table.remove(tab)  
    end  
  
    return tmp  
end  

