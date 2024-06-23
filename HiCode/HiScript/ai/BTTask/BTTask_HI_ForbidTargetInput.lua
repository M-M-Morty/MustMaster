require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_ForbidTargetInput = Class(BTTask_Base)


function BTTask_ForbidTargetInput:Execute(Controller, Pawn)
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local TargetActor = BB:GetValueAsObject("TargetActor")

    if TargetActor.CharIdentity == Enum.Enum_CharIdentity.Avatar then
        if self.IsForbid then
            TargetActor:Client_SendMessage("BanInput")
        else
            TargetActor:Client_SendMessage("UnbanInput")
        end
    end


    return ai_utils.BTTask_Succeeded
end

return BTTask_ForbidTargetInput
