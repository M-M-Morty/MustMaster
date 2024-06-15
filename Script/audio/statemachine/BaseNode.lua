--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"

local G = require("G")
---@type BaseNode
local BaseNode = UnLua.Class()

function BaseNode:GetBlackBoard()
    local Blackboard = self:GetContext():GetComponentByClass(UE.UHiSoundBackboardComponent)
    return Blackboard
end

return BaseNode