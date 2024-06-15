require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_SendMessage = Class(BTTask_Base)


function BTTask_SendMessage:Execute(Controller, Pawn)
    Pawn:SendMessage(self.MessageName)
    return ai_utils.BTTask_Succeeded
end

return BTTask_SendMessage
