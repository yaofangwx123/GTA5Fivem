-- 算法思路
-- 1：获取要检测的节点，如果是第一个时，则为第一个节点，否则从待检测的节点列表当中选取(选取之后则进行移除)
-- 2：获取此节点与下一个节点所有可能的字段(下一个节点不包含已经检测过的点)，并把点依次添加到待检测的节点列表(待检测的节点不能包含结束节点)
-- 3：合并所有字段到每一条含有该节点的路径里(尾节点含有该节点的每一条路径)
-- 4：进行筛选(对合并后的字段，对头尾相同的路径进行最优选择)
-- 5：如果检测到最终的节点后，记录当前已经检测的完整路径的最优解（最优路径和最优值），
    -- 对当前所有的路径的总值和最优值进行比较进行筛选;若没有检测最终的节点，则重复第一步，直到没有要检测的节点为止


local function copy(list)
    local newList = {}
    for k,v in pairs(list) do
        newList[k] = v
    end
    return newList
end


local function isContain(list, value)
    local isContain = false
    for k,v in pairs(list) do
        if v == value then
            isContain = true
        end
    end
    return isContain
end


local Greedy = {}


function Greedy:new(lineList, startIndex, endIndex)
    self.lineList   = lineList
    self.startIndex = startIndex
    self.endIndex   = endIndex


    self:init()
    return self
end


function Greedy:init()
    self.curAllPathList = {}
    self.waitCheckList  = {}
    self.checkList      = {}
    self.minValue       = nil -- 最优解
    self.minPathList    = nil -- 最优的路径(不一定只有一条)
end


function Greedy:getValue(index1, index2)
    for k,v in pairs(self.lineList) do
        local line = v.line
        if (line[1] == index1 and line[2] == index2) or (line[1] == index2 and line[2] == index1) then
            return v.value
        end
    end
    return nil
end


function Greedy:printPathList(pathList)
	
    for k,v in pairs(pathList) do
        print(string.format("path = %s, value = %d", table.concat(v.path, "-"), v.value))
    end
end


-- 获取最短的路径
function Greedy:getShortPath()
    
    self:init()


    self.waitCheckList = {self.startIndex}


    local index = self:getNextCheckPoint() 
    while true do
        self:updateNewPath(index)
        self.checkList[#self.checkList+1] = index
        index = self:getNextCheckPoint()


        if not index then
            break
        end
    end
    --self:printPathList(self.curAllPathList)
	return self.curAllPathList[1].path
end


function Greedy:getPathValue(path)
    local sum = 0
    for i=1, #path-1 do
        sum = sum + self:getValue(path[i], path[i+1])
    end
    return sum
end


function Greedy:getAllCurNextPoint(curPoint)
    local pointList = {}
    for k,v in pairs(self.lineList) do
        local p1 = v.line[1]
        local p2 = v.line[2]


        if p1 == curPoint then
            if not isContain(pointList, p2) then
                pointList[#pointList+1] = p2
            end
        end
        if p2 == curPoint then
            if not isContain(pointList, p1) then
                pointList[#pointList+1] = p1
            end
        end
    end


    for k,v in pairs(self.checkList) do
        for k2,v2 in pairs(pointList) do
            if v == v2 then
                table.remove(pointList, k2)
                break
            end
        end
    end


    return pointList
end


function Greedy:updateNewPath(curPoint)


    if #self.curAllPathList == 0 then
        local list = self:getAllCurNextPoint(curPoint)
        for k,v in pairs(list) do
            local path = {curPoint, v}
            self.curAllPathList[#self.curAllPathList+1] = {path=path, value=self:getPathValue(path)}
        end
        self:addToWaitCheckList(list)
    else
        local newList = {}
        local count = #self.curAllPathList
        for i=1, count do
            for k,v in pairs(self.curAllPathList) do
                if v.path[#v.path] == curPoint then
                    local list = self:getAllCurNextPoint(curPoint)
                    self:addToWaitCheckList(list)
                    for _,v2 in pairs(list) do
                        local oneList = copy(v.path)
                        oneList[#oneList+1] = v2
                        newList[#newList+1] = {path=oneList, value=self:getPathValue(oneList)}
                    end
                    table.remove(self.curAllPathList, k)
                    break
                end
            end
        end


        for k,v in pairs(newList) do
            self:updateCurAllPathList(v)
        end
    end


end


function Greedy:updateCurAllPathList(pathList)


    local function isSameEndPath(pathList1, pathList2)
        return pathList1[1] == pathList2[1] and pathList1[#pathList1] == pathList2[#pathList2]
    end


    local function checkAllPathList()


        for k,v in pairs(self.curAllPathList) do
            if v.path[#v.path] == self.endIndex then
                if not self.minValue then
                    self.minValue = v.value
                    self.minPathList = v
                elseif self.minValue > v.value then
                    minValue = v.value
                    self.minPathList = v
                end
            end
        end


        if self.minValue then
            local count = #self.curAllPathList
            for i=1, count do
                for k,v in pairs(self.curAllPathList) do
                    if v.value > self.minValue then
                        table.remove(self.curAllPathList, k)
                        break
                    end
                end
            end
        end
    end


    for k,v in pairs(self.curAllPathList) do
        local path = v.path
        local path2 = pathList.path
        if path[1] == path2[1] and path[#path] == path2[#path2] then
            if v.value > pathList.value then -- 局部最优替换
                table.remove(self.curAllPathList, k)
                self.curAllPathList[#self.curAllPathList+1] = pathList
                checkAllPathList()
                return
            elseif v.value < pathList.value then
                return 
            end
        end
    end


    self.curAllPathList[#self.curAllPathList+1] = pathList
    checkAllPathList()


end


-- 获取下一个检查点(每获取一次列表里就移除一次)
function Greedy:getNextCheckPoint()
    if #self.waitCheckList == 0 then  
        return nil -- 代表已经没有可检查的点了
    end


    local point = self.waitCheckList[1]
    table.remove(self.waitCheckList, 1)
    return point
end


function Greedy:addToWaitCheckList(list)
    for k,v in pairs(list) do
        if not isContain(self.waitCheckList, v) and not isContain(self.checkList, v) and v ~= self.endIndex then
            self.waitCheckList[#self.waitCheckList+1] = v
        end
    end
end


--[[local lineList = {}
lineList[#lineList+1] = {line={1,2}, value = 1}


lineList[#lineList+1] = {line={2,3}, value = 1}


lineList[#lineList+1] = {line={3,4}, value = 1}
lineList[#lineList+1] = {line={3,6}, value = 1}
lineList[#lineList+1] = {line={3,7}, value = 1}



lineList[#lineList+1] = {line={6,5}, value = 1}

lineList[#lineList+1] = {line={7,8}, value = 1}
lineList[#lineList+1] = {line={7,10}, value = 1}
lineList[#lineList+1] = {line={8,9}, value = 1}
lineList[#lineList+1] = {line={10,11}, value = 1}
lineList[#lineList+1] = {line={10,13}, value = 1}
lineList[#lineList+1] = {line={11,12}, value = 1}
lineList[#lineList+1] = {line={13,14}, value = 1}]]



local function getPath(lineList,startIndex,endIndex)
	print('mesh ',startIndex,endIndex)
	if(startIndex == endIndex) then
		return {startIndex}
	end
	local g = Greedy:new(lineList, startIndex, endIndex)
	return g:getShortPath()
end

Mesh = {}
Mesh.getPath = getPath