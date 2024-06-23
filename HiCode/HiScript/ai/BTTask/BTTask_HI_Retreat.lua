require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_Retreat = Class(BTTask_Base)


function BTTask_Retreat:Execute(Controller, Pawn)

    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local Target = BB:GetValueAsObject("TargetActor")
    if nil == Target then
        G.log:error("yj", "BTTask_MoveToTarget Target nil")
        return ai_utils.BTTask_Failed
    end

    -- 反向
    local Forward = Pawn:K2_GetActorLocation() - Target:K2_GetActorLocation()

    -- 归一
    local NForward = UE.UKismetMathLibrary.Normal(Forward, 0)

    -- 缩放
    local Offset = UE.UKismetMathLibrary.Multiply_VectorFloat(NForward, self.RetreatDis)
    -- G.log:debug("yjj", "BTTask_Retreat %s %s %s", UE.UKismetMathLibrary.VSize(NForward), Offset, self.RetreatDis)

    -- 偏移
    local Location = UE.UKismetMathLibrary.Add_VectorVector(Target:K2_GetActorLocation(), Offset)
    -- G.log:debug("yjj", "BTTask_Retreat TargetLocation(%s) SelfLocation(%s) RestreatToLocation(%s)", Target:K2_GetActorLocation(), Pawn:K2_GetActorLocation(), Location)
    BB:SetValueAsVector("RestreatToLocation", Location)

    return ai_utils.BTTask_Succeeded
end

return BTTask_Retreat
