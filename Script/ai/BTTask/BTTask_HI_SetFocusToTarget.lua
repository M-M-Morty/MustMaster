require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_SetFocusToTarget = Class(BTTask_Base)


function BTTask_SetFocusToTarget:Execute(Controller, Pawn)

    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local Target = BB:GetValueAsObject("TargetActor")

    -- G.log:debug("yj", "BTTask_SetFocusToTarget %s", Target)
    Controller:K2_SetFocus(Target)

    return ai_utils.BTTask_Succeeded
end


return BTTask_SetFocusToTarget
