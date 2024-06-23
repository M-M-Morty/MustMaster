--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

-- lua table的一些简单封装

local G = require('G')

local TableUtil = {}

-- 浅拷贝，只拷贝一层数据
function TableUtil:ShallowCopy(tbTarget)
	local tbCopyed = {}
	if type(tbTarget) == 'table' then
		for k, v in pairs(tbTarget) do
			tbCopyed[k] = v
		end
	else
		G.log:warn('gh_utils', 'TableUtil:ShallowCopy Fail, invalid params.')
	end

	return tbCopyed
end

function TableUtil:ArrayRemoveValue(tbTarget, Value)
	local RemoveCount = 0
	if type(tbTarget) == 'table' then
		for nIndex = #tbTarget, 1, -1 do
			if Value == tbTarget[nIndex] then
				table.remove(tbTarget, nIndex)
				RemoveCount = RemoveCount + 1
			end
		end
	else
		G.log:warn('gh_utils', 'TableUtil:ArrayRemoveIf Fail, invalid params.')
	end
	return RemoveCount
end

function TableUtil:ArrayRemoveIf(tbTarget, fnCall)
	local RemoveCount = 0
	if type(tbTarget) == 'table' and type(fnCall) == 'function' then
		for nIndex = #tbTarget, 1, -1 do
			if fnCall(tbTarget[nIndex]) then
				table.remove(tbTarget, nIndex)
				RemoveCount = RemoveCount + 1
			end
		end
	else
		G.log:warn('gh_utils', 'TableUtil:ArrayRemoveIf Fail, invalid params.')
	end
	return RemoveCount
end

function TableUtil:FindIf(tbTarget, fnCall)
	if type(tbTarget) == 'table' and type(fnCall) == 'function' then
		for k, v in pairs(tbTarget) do
			if fnCall(v) then
				return v, k
			end
		end
	else
		G.log:warn('gh_utils', 'TableUtil:FindIf Fail, invalid params.')
	end
end

function TableUtil:Contains(tbTarget, Value)
	if type(tbTarget) ~= 'table' then
		G.log:warn('gh_utils', 'TableUtil:Contains Fail, invalid params.')
		return
	end

	for k, v in pairs(tbTarget) do
		if v == Value then
			return true
		end
	end
end

--带权值的随机
local function weight_random(tbWeight)
    local total = 0;
    for k, v in pairs(tbWeight) do
        total = total + v;
    end
    total = math.floor(total * 100); --support float
    if total < 1 then
        return;
    end

    local randVal = math.random(total) / 100;
    total = 0;
    for k, v in pairs(tbWeight) do
        total = total + v;
        if randVal <= total then
            return k;
        end
    end
end
function TableUtil:WeightRandom(tbTable, pfGetWeight, count)
    local bEmpty = (next(tbTable) and {false} or {true})[1];
    if bEmpty then
        return {};
    end
    count = count or 1;
    if count < 1 then
        return {};
    end

    local tbWeight = {};
    for k, v in pairs(tbTable) do
        tbWeight[k] = pfGetWeight(k, v);
    end

    local tbRet = {};
    for i = 1, count do
        local k = weight_random(tbWeight);
        if k then
            tbWeight[k] = 0;
            table.insert(tbRet, {k, tbTable[k]});
        end
    end
    return tbRet;
end

--以key作为分段区间的table，返回指定值（key）的匹配bound的key
function TableUtil:GetBoundElementOfMap(tb, key)
    tb = tb or {}
    local upperKey
    local maxKey
    local lowerKey
    local minKey
    for k, v in pairs(tb) do
        if not maxKey or maxKey < k then
            maxKey = k
        end
        if not minKey or minKey > k then
            minKey = k
        end
        if k >= key and (not upperKey or upperKey > k) then
            upperKey = k
        end
        if k <= key and (not lowerKey or lowerKey < k) then
            lowerKey = k
        end
    end
    return lowerKey, upperKey, minKey, maxKey
end
--以value作为分段的table（可以无序），返回指定值（val）的匹配bound的index
function TableUtil:GetBoundElementOfAry(tb, val)
    tb = tb or {}
    local upperIndex
    local maxIndex
    local lowerIndex
    local minIndex
    for i, v in ipairs(tb) do
        if not maxIndex or tb[maxIndex] < v then
            maxIndex = i
        end
        if not minIndex or tb[minIndex] > v then
            minIndex = i
        end
        if v >= val and (not upperIndex or tb[upperIndex] > v) then
            upperIndex = i
        end
        if v <= val and (not lowerIndex or tb[lowerIndex] < v) then
            lowerIndex = i
        end
    end
    return lowerIndex, upperIndex, minIndex, maxIndex
end


function TableUtil:DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[self:DeepCopy(orig_key)] = self:DeepCopy(orig_value)
        end
        setmetatable(copy, self:DeepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
return TableUtil
