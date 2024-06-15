require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")
local utils = require("common.utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_TurnToTarget = Class(BTTask_Base)



-- 转向目标（会追踪）
function BTTask_TurnToTarget:Execute(Controller, Pawn)

    -- if not self:NeedTurn(Controller, Pawn) then
    --     return ai_utils.BTTask_Succeeded
    -- end

    -- if self.TurnMontage then
    --     Pawn.AppearanceComponent:Server_PlayMontage(self.TurnMontage, self.MontagePlayRate)
    -- end

    return self:TurnInPlace(Controller, Pawn)
end

function BTTask_TurnToTarget:Tick(Controller, Pawn, DeltaSeconds)

    -- if not self:NeedTurn(Controller, Pawn) then
        
    --     if self.TurnMontage then
    --         Pawn.AppearanceComponent:Server_StopMontage(0.0, self.TurnMontage)
    --     end

    --     return ai_utils.BTTask_Succeeded
    -- end

    -- if self.TurnSpeed < 0.001 then
    --     -- 如果节点没有配TurnSpeed，那么用黑板的TurnSpeed
    --     local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    --     self.TurnSpeed = BB:GetValueAsFloat("TurnSpeed")
    -- end

    -- local AIControl = Pawn:GetAIServerComponent()
    -- AIControl:SetFocusToTargetHead2Head(DeltaSeconds, self.TurnSpeed)

    local AppearanceComponent = Pawn.AppearanceComponent
    if not AppearanceComponent.bPlayingTurnInPlace then
        return self:TurnInPlace(Controller, Pawn)
    end
end

function BTTask_TurnToTarget:TurnInPlace(Controller, Pawn)
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local Target = BB:GetValueAsObject("TargetActor")
    if not Target then
        return ai_utils.BTTask_Failed
    end

    local SelfLocation = Pawn:K2_GetActorLocation()
    local TargetLocation = Target:K2_GetActorLocation()

    local TargetRotation = UE.UKismetMathLibrary.Conv_VectorToRotator(TargetLocation - SelfLocation)
    local AppearanceComponent = Pawn.AppearanceComponent
    local TurnInPlaceValues = AppearanceComponent.TurnInPlaceValues
    local Delta = TargetRotation - Pawn:K2_GetActorRotation()

    Delta = UE.UHiUtilsFunctionLibrary.Rotator_Normalized(Delta)

    if math.abs(Delta.Yaw) >= TurnInPlaceValues.TurnCheckMinAngle then
        AppearanceComponent:TurnInPlace(Delta.Yaw)
        AppearanceComponent:Multicast_TurnInPlace(Delta.Yaw)
    else
        return ai_utils.BTTask_Succeeded
    end
end

function BTTask_TurnToTarget:NeedTurn(Controller, Pawn)
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local Target = BB:GetValueAsObject("TargetActor")

    if not Target then
        return false
    end

    local SelfLocation = Pawn:K2_GetActorLocation()
    local SelfRotation = Pawn:K2_GetActorRotation()
    local TargetLocation = Target:K2_GetActorLocation()
    local VRotation = UE.UKismetMathLibrary.Conv_RotatorToVector(SelfRotation)

    -- utils.LineTraceDebugByLL(TargetLocation, SelfLocation)
    -- utils.LineTraceDebugByLR(SelfLocation, SelfRotation)

    if UE.UHiCollisionLibrary.CheckInDirectionBySection(TargetLocation, SelfLocation, VRotation, 85, 95) then
        return false
    end

    return true
end


return BTTask_TurnToTarget
