--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@type BTDecorator_DeltaRotationInRange
local BTDecorator_DeltaRotationInRange = Class()

function BTDecorator_DeltaRotationInRange:PerformConditionCheckAI(Controller, Pawn)
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local tarLocation
    local objClass = UE.UClass.Load("/Script/AIModule.BlackboardKeyType_Object")
    local isActor = UE.UKismetMathLibrary.ClassIsChildOf(self.target.SelectedKeyType, objClass)
    if isActor then
        local tarActor = BB:GetValueAsObject(self.target.SelectedKeyName)
        if not tarActor then
            return false
        end
        tarLocation = tarActor:K2_GetActorLocation()
    else
        local tarPoint = BB:GetValueAsVector(self.target.SelectedKeyName)
        tarLocation = tarPoint
    end

    local lootAtRot = UE.UKismetMathLibrary.FindLookAtRotation(Pawn:K2_GetActorLocation(), tarLocation)
    local deltaRot = UE.UKismetMathLibrary.NormalizedDeltaRotator(Pawn:K2_GetActorRotation(), lootAtRot)

    local limitRot = self.limitRotation
    if self.fromBoard then
        limitRot = BB:GetValueAsRotator(self.limitKey.SelectedKeyName)
    end

    if not UE.UKismetMathLibrary.NearlyEqual_FloatFloat(limitRot.Pitch, 0, 0.0001) then
        if deltaRot.Pitch > limitRot.Pitch or deltaRot.Pitch < -1 * limitRot.Pitch then
            return false
        end
    end
    if not UE.UKismetMathLibrary.NearlyEqual_FloatFloat(limitRot.Yaw, 0, 0.0001) then
        if deltaRot.Yaw > limitRot.Yaw or deltaRot.Yaw < -1 * limitRot.Yaw then
            return false
        end
    end
    if not UE.UKismetMathLibrary.NearlyEqual_FloatFloat(limitRot.Roll, 0, 0.0001) then
        if deltaRot.Roll > limitRot.Roll or deltaRot.Roll < -1 * limitRot.Roll then
            return false
        end
    end
    return true
end

return BTDecorator_DeltaRotationInRange
