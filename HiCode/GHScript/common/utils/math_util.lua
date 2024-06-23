local _M = {}

---@param num float
function _M.rounding(num)
    return math.floor(num + 0.5)
end

return _M