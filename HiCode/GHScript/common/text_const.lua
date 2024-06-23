local _M = {}

---@class ConstTextConfig
---@field Content string

local G = require("G")
local ConstTextTable = require("common.data.const_text_data").data

---@param TextKey string
---@return string
function _M.GetConstText(TextKey)
    ---@type ConstTextConfig
    local ConstTextConfig = ConstTextTable[TextKey]
    if ConstTextConfig == nil then
        G.log:error("TextConst", "Cannot find const text %s", TextKey)
        return ""
    end
    return ConstTextConfig.Content
end

return _M