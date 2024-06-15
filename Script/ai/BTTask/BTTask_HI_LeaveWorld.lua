--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")
local ai_utils = require("common.ai_utils")
local BTTask_Base = require("ai.BTCommon.BTTask_Base")
---@type BTTask_LeaveWorld_C
local BTTask_LeaveWorld = Class(BTTask_Base)

function BTTask_LeaveWorld:Execute(Controller, Pawn)
    Pawn:K2_DestroyActor()
    return ai_utils.BTTask_Succeeded
end

return BTTask_LeaveWorld
