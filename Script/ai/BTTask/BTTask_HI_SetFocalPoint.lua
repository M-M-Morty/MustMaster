require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_SetFocalPoint = Class(BTTask_Base)


function BTTask_SetFocalPoint:Execute(Controller, Pawn)

    G.log:debug("yj", "BTTask_SetFocalPoint %s", self.Point)
    
    Controller:K2_SetFocalPoint(self.Point)


    return ai_utils.BTTask_Succeeded
end


return BTTask_SetFocalPoint
