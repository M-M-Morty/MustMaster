require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_HI_ReturnBattleSignal = Class(BTTask_Base)


function BTTask_HI_ReturnBattleSignal:Execute(Controller, Pawn)
    Pawn:SendMessage("ReturnBattleSignal")
    return ai_utils.BTTask_Succeeded
end

return BTTask_HI_ReturnBattleSignal
