require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_StopMove = Class(BTTask_Base)

function BTTask_StopMove:Execute(Controller, Pawn)
    Controller:StopMovement()
    return ai_utils.BTTask_Succeeded
end


return BTTask_StopMove
