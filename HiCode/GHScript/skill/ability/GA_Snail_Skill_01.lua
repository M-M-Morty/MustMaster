--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local GA_GH_CommonBase = require('CP0032305_GH.Script.skill.ability.GA_GH_CommonBase')

---@type GA_Snail_Skill_01_C
local GA_Snail_Skill_01_C = Class(GA_GH_CommonBase)

function GA_Snail_Skill_01_C:StartAction()
    -- body
end
function GA_Snail_Skill_01_C:TickAction()
    local selfActor = self:GetAvatarActorFromActorInfo()
    local tarActor = self.fireTarget
    local selfLocation = selfActor:K2_GetActorLocation()
    local selfRotation = selfActor:K2_GetActorRotation()
    local tarLocation = tarActor:K2_GetActorLocation()
    local dist = selfActor:GetDistanceTo(tarActor)
    if dist > self.FAR_DISTANCE or self.NORMAL_DISTANCE >= self.FAR_DISTANCE then
        selfActor:GetController():StopMovement()

        if selfActor.CustomMoveToStop then
            selfActor:CustomMoveToStop()
            selfActor:SetCustomMoveCollisionCB(nil)
        end
    else
        local r
        if dist > self.NORMAL_DISTANCE then
            r = 0.5 + (dist - self.NORMAL_DISTANCE) / (self.FAR_DISTANCE - self.NORMAL_DISTANCE) * 0.5
        else
            r = dist / self.NORMAL_DISTANCE * 0.5
        end
        local tarYawDelta = self.yawCurve:GetFloatValue(r)
        local lookAt = UE.UKismetMathLibrary.FindLookAtRotation(selfLocation, tarLocation)
        local deltaRot = UE.UKismetMathLibrary.NormalizedDeltaRotator(selfRotation, lookAt)
        if deltaRot.Yaw < 0 then
            tarYawDelta = -tarYawDelta
        end
        local tarYaw = lookAt.Yaw + tarYawDelta
        local selfYaw = selfRotation.Yaw
        selfRotation.Yaw = UE.UKismetMathLibrary.ClampAngle(tarYaw, selfYaw - self.DELTA_MAX, selfYaw + self.DELTA_MAX)
        selfActor:K2_SetActorRotation(selfRotation, true)

        local forward = UE.UKismetMathLibrary.GetForwardVector(selfRotation)
        tarLocation = forward * 1000 + selfLocation
        --UE.UKismetSystemLibrary.DrawDebugLine(self, selfLocation, tarLocation, UE.FLinearColor(1, 0, 0), 10)

        if selfActor.CustomMoveToStart then
            selfActor:CustomMoveToStart(tarLocation, self.MOVE_DURATION)
        end
    end
end
function GA_Snail_Skill_01_C:EndAction()
    local selfActor = self:GetAvatarActorFromActorInfo()
    if selfActor.CustomMoveToStop then
        selfActor:CustomMoveToStop()
        selfActor:SetCustomMoveCollisionCB(nil)
    end
end

function GA_Snail_Skill_01_C:K2_OnEndAbility(bWasCancelled)
    Super(GA_Snail_Skill_01_C).K2_OnEndAbility(self, bWasCancelled)
    self.Overridden.K2_OnEndAbility(self, bWasCancelled)
end


return GA_Snail_Skill_01_C

