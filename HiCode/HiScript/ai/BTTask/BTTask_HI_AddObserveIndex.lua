require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_AddObserveIndex = Class(BTTask_Base)


function BTTask_AddObserveIndex:Execute(Controller, Pawn)
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local ObserveIndex = BB:GetValueAsInt("ObserveIndex") + 1

    -- G.log:error("yj", "BTTask_AddObserveIndex ObserveIndex.%s", ObserveIndex - 1)
    local AIControl = Pawn:GetAIServerComponent()
    if ObserveIndex > #AIControl.ObservePath then
        BB:SetValueAsInt("ObserveIndex", 0)
        return ai_utils.BTTask_Failed
    end

    BB:SetValueAsInt("ObserveIndex", ObserveIndex)
    return ai_utils.BTTask_Succeeded
end

return BTTask_AddObserveIndex
