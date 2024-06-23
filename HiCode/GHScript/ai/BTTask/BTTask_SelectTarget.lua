--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


local G = require("G")
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local ai_utils = require("common.ai_utils")
local BTTask_Base = require("ai.BTCommon.BTTask_Base")

---@type BTTask_SelectTarget_C
local BTTask_SelectTarget_C = Class(BTTask_Base)


function BTTask_SelectTarget_C:Execute(Controller, Pawn)
    local selectEnum = FunctionUtil:GlobalEnum('selectEnum')
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local resultActor = nil
    local TargetActors = UE.TArray(UE.AActor)

    if self.tarKind == selectEnum.Player then
        UE.UGameplayStatics.GetAllActorsOfClass(Pawn, FunctionUtil:IndexRes('BPA_AvatarBase_C'), TargetActors)
    elseif self.tarKind == selectEnum.InVisionTarget then
        TargetActors = Pawn.BP_PerceptionComponent.vSightActors
    end

    local minDist
    for i, obj in pairs(TargetActors) do
        if obj and ((not obj.IsDead) or (not obj:IsDead())) then
            local dist = obj:GetDistanceTo(Pawn)
            if (not minDist) or dist < minDist then
                minDist = dist
                resultActor = obj
            end
        end
    end

    Pawn.ChararacteStateManager:ClearLookAtTarget()
    if resultActor then
        BB:SetValueAsObject(self.saveKey.SelectedKeyName, resultActor)
        if self.bLookAtTarget then
            Pawn.ChararacteStateManager:SetLookAtTarget(resultActor, UE.FVector(0,0,0))
        end
        return ai_utils.BTTask_Succeeded
    else
        return ai_utils.BTTask_Failed
    end
end

return BTTask_SelectTarget_C