local _M = {}

---从数组中随机num个数据
---@param list any[]
---@param num integer
---@return any[]
function _M.randomArray(list, num)
    local result = {}
    if list == nil or #list == 0 then
        return result
    end
    if #list <= num then
        return list
    end
    local length = #list
    for i = 1, num do
        local Random = math.random(length - i + 1)
        local Value = list[Random]
        table.insert(result, Value)
        list[Random] = list[length - i + 1]
        list[length - i + 1] = Value
    end
    return result
end

return _M