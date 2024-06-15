require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_ClearFocus = Class(BTTask_Base)


function BTTask_ClearFocus:Execute(Controller, Pawn)

    -- G.log:debug("yj", "BTTask_ClearFocus %s", Target)
    Controller:K2_ClearFocus()

    return ai_utils.BTTask_Succeeded
end


return BTTask_ClearFocus
