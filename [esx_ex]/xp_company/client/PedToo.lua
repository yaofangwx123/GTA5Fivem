local function split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter == "") then return false end
    local pos, arr = 0, {}
    for st, sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

local femaleNameItems = "嘉、琼、桂、娣、叶、璧、璐、娅、琦、晶、妍、茜、秋、珊、莎、锦、黛、青、倩、婷、姣、婉、娴、瑾、颖、露、瑶、怡、婵、雁、蓓、纨、仪、荷、丹、蓉、眉、君、琴、蕊、薇、菁、梦、岚、苑、婕、馨、瑗、琰、韵、融、园、艺、咏、卿、聪、澜、纯、毓、悦、昭、冰、爽、琬、茗、羽、希、宁、欣、飘、育、滢、馥、筠、柔、竹、霭、凝、晓、欢、霄、枫、芸、菲、寒、伊、亚、宜、可、姬、舒、影、荔、枝、思、丽、秀、娟、英、华、慧、巧、美、娜、静、淑、惠、珠、翠、雅、芝、玉、萍、红、娥、玲、芬、芳、燕、彩、春、菊、勤、珍、贞、莉、兰、凤、洁、梅、琳、素、云、莲、真、环、雪、荣、爱、妹、霞、香、月、莺、媛、艳、瑞、凡、佳"
local maleNameItems = "涛、昌、进、林、有、坚、和、彪、博、诚、先、敬、震、振、壮、会、群、豪、心、邦、承、乐、绍、功、松、善、厚、庆、磊、民、友、裕、河、哲、江、超、浩、亮、政、谦、亨、奇、固、之、轮、翰、朗、伯、宏、言、若、鸣、朋、斌、梁、栋、维、启、克、伦、翔、旭、鹏、泽、晨、辰、士、以、建、家、致、树、炎、德、行、时、泰、盛、雄、琛、钧、冠、策、腾、伟、刚、勇、毅、俊、峰、强、军、平、保、东、文、辉、力、明、永、健、世、广、志、义、兴、良、海、山、仁、波、宁、贵、福、生、龙、元、全、国、胜、学、祥、才、发、成、康、星、光、天、达、安、岩、中、茂、武、新、利、清、飞、彬、富、顺、信、子、杰、楠、榕、风、航、弘"
local familyNameItemsSin = "赵,钱,孙,李,周,吴,郑,王,冯,陈,褚,卫,蒋,沈,韩,杨,朱,秦,尤,许,何,吕,施,张,孔,曹,严,华,金,魏,陶,姜,戚,谢,邹,喻,柏,水,窦,章,云,苏,潘,葛,奚,范,彭,郎,鲁,韦,昌,马,苗,凤,花,方,俞,任,袁,柳,酆,鲍,史,唐,费,廉,岑,薛,雷,贺,倪,汤,滕,殷,罗,毕,郝,邬,安,常,乐,于,时,傅,皮,卞,齐,康,伍,余,元,卜,顾,孟,平,黄,和,穆,萧,尹,姚,邵,湛,汪,祁,毛,禹,狄,米,贝,明,臧,计,伏,成,戴,谈,宋,茅,庞,熊,纪,舒,屈,项,祝,董,梁,杜,阮,蓝,闵,席,季,麻,强,贾,路,娄,危,江,童,颜,郭,梅,盛,林,刁,钟,徐,丘,骆,高,夏,蔡,田,樊,胡,凌,霍,虞,万,支,柯,昝,管,卢,莫,经,房,裘,缪,干,解,应,宗,丁,宣,贲,邓,郁,单,杭,洪,包,诸,左,石,崔,吉,钮,龚,程,嵇,邢,滑,裴,陆,荣,翁,荀,羊,于,惠,甄,曲,家,封,芮,羿,储,靳,汲,邴,糜,松,井,段,富,巫,乌,焦,巴,弓,牧,隗,山,谷,车,侯,宓,蓬,全,郗,班,仰,秋,仲,伊,宫,宁,仇,栾,暴,甘,钭,厉,戎,祖,武,符,刘,景,詹,束,龙,叶,幸,司,韶,郜,黎,蓟,薄,印,宿,白,怀,蒲,邰,从,鄂,索,咸,籍,赖,卓,蔺,屠,蒙,池,乔,阴,郁,胥,能,苍,双,闻,莘,党,翟,谭,贡,劳,逄,姬,申,扶,堵,冉,宰,郦,雍,嘤,璩,桑,桂,濮,牛,寿,通,边,扈,燕,冀,郏,浦,尚,农,柴,瞿,阎,充,慕,连,茹,习,宦,艾,鱼,容,向,古,易,慎,戈,廖,庾,终,暨,居,衡,步,都,耿,满,弘,匡,国,文,寇,广,禄,阙,东,欧,殳,沃,利,蔚,越,夔,隆,师,巩,厍,聂,晁,勾,敖,融,冷,訾,辛,阚,那,简,饶,空,曾,毋,沙,乜,养,鞠,须,丰,巢,关,蒯,相,查,后,荆,红,游,竺,权,逯,盖,益,桓,公,万,俟,司,马,上,官,欧,阳,夏,候,诸,葛,闻,人,东,方,赫,连,皇,甫,尉,迟,公,羊,澹,台,公,治,宗,政,濮,阳,淳,于,单,于,太,叔,申,屠,公,孙,仲,孙"

local namesFemal = split(femaleNameItems,'、')
local namesmal = split(maleNameItems,'、')
local sexs = split(familyNameItemsSin,',')

function getPedRandomName(sex)
	return sexs[math.random(1, #sexs)] .. 
	(sex == 1 and namesmal[math.random(1, #namesmal)]or namesFemal[math.random(1, #namesFemal)]) .. 
	(math.random(1, 10)%2 == 0 and '' or (sex == 1 and namesmal[math.random(1, #namesmal)] or namesFemal[math.random(1, #namesFemal)]))
end


 function pedSit(pedId,index,translate)
		ClearPedTasksImmediately(pedId)
		 
		local chairItem = Config.POS[index]
		local posChair = chairItem.chairPos
		local headingChair = chairItem.chairHeading
		print('ped sit chair ',pedId,posChair,index)
		if(posChair ~= nil) then
			print('ped ist ',pedId,translate)
			TaskStartScenarioAtPosition(pedId, Config.Script_Sit , posChair.x, posChair.y, posChair.z - 0.145, headingChair + 180,-1,true,translate) 
		end
		
end

 function pedStand(pedId)
	
	
	if(not DoesEntityExist(pedId) or GetEntityHealth(pedId) == 0 or IsPedUsingScenario(pedId,Config.Script_Sit) ~= 1) then return end
	
	
	local nowPos  = GetEntityCoords(pedId)
	
	local index = getNearPosIndexByCoords(nowPos)
	if(not index or (not Config.POS[index].isChair and not Config.POS[index].isMeetingChair)) then ClearPedTasksImmediately(pedId) return end
		
	local pos = Config.POS[index]
	SetEntityCollision(pedId,false,true)
	local coords = GetOffsetFromEntityInWorldCoords(pedId, 0.0, 0.5, 0.0)
	SetEntityCoords(pedId, coords.x, coords.y,nowPos.z - 0.5, false, false, false, false)
	ClearPedTasksImmediately(pedId)
	SetEntityCollision(pedId,true,true)	
	
end

 function pedDismiss(pedId)
	if(not pedId or not DoesEntityExist(pedId)) then return end
	pedStand(pedId)
	local indexStart = getNearPosIndexByCoords(GetEntityCoords(pedId))
	local path  = Mesh.getPath(Config.MESHPOINT, indexStart, Config.SwapPoints[math.random(1,#Config.SwapPoints)])
	addMeshRoute(pedId,path,Config.Default_speed,{{script = Config.Script_DISMISS}})	
	
end

 function isPedSitEnable(pedId,seatId)

	return #(GetEntityCoords(pedId) - Config.POS[seatId].position) < Config.SitDistance
	
end

 function isPedNearPos(pedId,posIndex)

	--print('isPedNearPos',pedId,posIndex,#(GetEntityCoords(pedId) - Config.POS[posIndex].position))
	return 	pedId and DoesEntityExist(pedId) and #(GetEntityCoords(pedId) - Config.POS[posIndex].position) < 1.4								
											
end


 function getNearPosIndexByCoords(coordPos)
	local lastDistance = 10000
	local indexTarget = Config.POS_120
	for index,pos in pairs(Config.POS) do
		if(index ~= coordPos) then
			local distance = #(coordPos - pos.position)
			if(distance < lastDistance) then
				indexTarget = index
				lastDistance = distance
			end
		end
		
	end
	return indexTarget,lastDistance
end

 function isPedBusyRequest(pedId)
	if(not company.requests) then return false end
	for j = 1,#company.requests do
		if(company.requests[j].responseId == pedId and company.requests[j].localStart and company.requests[j].status == 0) then
			return true
		end
	end
	return false
end


 function pedGoPosition(pedId,targetIndex,script)
	local indexStart = getNearPosIndexByCoords(GetEntityCoords(pedId))
	local path  = Mesh.getPath(Config.MESHPOINT, indexStart, targetIndex)
	addMeshRoute(pedId,path,Config.Default_speed,script)
end


 function pedSitSofa(pedId,sofaIndex)
		ClearPedTasksImmediately(pedId)
		TaskStartScenarioAtPosition(pedId, Config.Script_Sit , Config.SofaPositions[sofaIndex].position.x, Config.SofaPositions[sofaIndex].position.y, Config.SofaPositions[sofaIndex].position.z - 0.55,Config.SofaPositions[sofaIndex].heading ,-1,true,false) 
		
		
end