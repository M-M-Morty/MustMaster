--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

-- ListView的数据基类，可以塞入任何类型

local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')

---@type UICommonItemObj_C
---@field ItemValue any@对不同的ListItemObject有不同的含义
local M = Class()

function M.GetItemObjClass()
    local UICommonItemObjClass = FunctionUtil:IndexRes('UICommonItemObj')
    return UICommonItemObjClass
end

return M
