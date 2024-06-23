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

---@type BTTask_RandPosAroundActor_C
local BTTask_RandPosAroundActor_C = Class(BTTask_Base)

function BTTask_RandPosAroundActor_C:Execute(Controller, Pawn)
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local tarLocation
    local objClass = UE.UClass.Load("/Script/AIModule.BlackboardKeyType_Object")
    local isActor = UE.UKismetMathLibrary.ClassIsChildOf(self.referTargetKey.SelectedKeyType, objClass)
    if isActor then
        local tarActor = BB:GetValueAsObject(self.referTargetKey.SelectedKeyName) or Pawn
        tarLocation = tarActor:K2_GetActorLocation()
    else
        local tarPoint = BB:GetValueAsVector(self.referTargetKey.SelectedKeyName)
        tarLocation = tarPoint
    end

    local pos = UE.FVector()
    UE.UNavigationSystemV1.K2_GetRandomReachablePointInRadius(Pawn, tarLocation, pos, self.radius, nil, nil)
    BB:SetValueAsVector(self.savePosKey.SelectedKeyName, pos)
    return ai_utils.BTTask_Succeeded
end

return BTTask_RandPosAroundActor_C