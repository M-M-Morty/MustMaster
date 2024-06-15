require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_MoveToTarget = Class(BTTask_Base)

-- 移动到目标的位置，会随着目标移动而变化目标点，即一直追踪目标
function BTTask_MoveToTarget:Execute(Controller, Pawn)

    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local Target = BB:GetValueAsObject("TargetActor")
    if nil == Target then
        G.log:error("yj", "BTTask_MoveToTarget Target nil")
        return ai_utils.BTTask_Failed
    end

    local SelfLocation = Pawn:K2_GetActorLocation()
    local TargetLocation = Target:K2_GetActorLocation()
    local Dis = UE.UKismetMathLibrary.Vector_Distance(SelfLocation, TargetLocation)
    if self.IgnoreZ then
        Dis = UE.UKismetMathLibrary.Vector_Distance2D(SelfLocation, TargetLocation)
    end

    if Dis < self.Tolerance then
        return ai_utils.BTTask_Succeeded
    end
end

function BTTask_MoveToTarget:Tick(Controller, Pawn, DeltaSeconds)
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local Target = BB:GetValueAsObject("TargetActor")
    if nil == Target then
        G.log:error("yj", "BTTask_MoveToTarget Target nil")
        return ai_utils.BTTask_Failed
    end

    self.TargetLocation = Target:K2_GetActorLocation()

    local SelfLocation = Pawn:K2_GetActorLocation()
    local Dis = UE.UKismetMathLibrary.Vector_Distance(SelfLocation, self.TargetLocation)
    if self.IgnoreZ then
        Dis = UE.UKismetMathLibrary.Vector_Distance2D(SelfLocation, self.TargetLocation)
    end

    if Dis > self.Tolerance then
        ai_utils.EvMoveToLocation(Controller, Pawn, self.TargetLocation)
    else
        Controller:StopMovement()
        return ai_utils.BTTask_Succeeded
    end
end


return BTTask_MoveToTarget
