require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_MoveToLocation = Class(BTTask_Base)


-- 移动到目标位置
function BTTask_MoveToLocation:Execute(Controller, Pawn)
    local TargetLocation = self:GetTargetLocation(Controller, Pawn)

    local SelfLocation = Pawn:K2_GetActorLocation()
    local Dis = UE.UKismetMathLibrary.Vector_Distance(SelfLocation, TargetLocation)
    if self.IgnoreZ then
        Dis = UE.UKismetMathLibrary.Vector_Distance2D(SelfLocation, TargetLocation)
    end
    if Dis < self.Tolerance then
        -- G.log:debug("yj", "BTTask_MoveToLocation:Execute 1 %s %s", Dis, self.Tolerance)
        return ai_utils.BTTask_Succeeded
    end
end

function BTTask_MoveToLocation:Tick(Controller, Pawn, DeltaSeconds)
    local TargetLocation = self:GetTargetLocation(Controller, Pawn)
    local SelfLocation = Pawn:K2_GetActorLocation()
    local Dis = UE.UKismetMathLibrary.Vector_Distance(SelfLocation, TargetLocation)
    if self.IgnoreZ then
        Dis = UE.UKismetMathLibrary.Vector_Distance2D(SelfLocation, TargetLocation)
    end

    if Dis > self.Tolerance then
        ai_utils.EvMoveToLocation(Controller, Pawn, TargetLocation)
    else
        Controller:StopMovement()
        return ai_utils.BTTask_Succeeded
    end

end

function BTTask_MoveToLocation:GetTargetLocation(Controller, Pawn)
    if (self.TargetLocation - UE.FVector(0, 0, 0)):Size() < 0.0000001 then
        local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
        return BB:GetValueAsVector("MoveToLocation")
    end

    return self.TargetLocation
end


return BTTask_MoveToLocation
