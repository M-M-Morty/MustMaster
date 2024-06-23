--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local GA_GH_CommonBase = require('CP0032305_GH.Script.skill.ability.GA_GH_CommonBase')

---@type GA_Snail_Skill_03_C
local GA_Snail_Skill_03_C = Class(GA_GH_CommonBase)

function GA_Snail_Skill_03_C:StartAction()
    self.move_stoped = false
end
function GA_Snail_Skill_03_C:TickAction()
    if self.move_stoped then
        return
    end

    local selfActor = self:GetAvatarActorFromActorInfo()
    local tarActor = self.skillTarget
    local selfLocation = selfActor:K2_GetActorLocation()
    local selfRotation = selfActor:K2_GetActorRotation()
    local tarLocation = tarActor:K2_GetActorLocation()
    local dist = selfActor:GetDistanceTo(tarActor)
    local lookAt = self:GetAvatarLookat(selfActor, tarActor)
    local deltaRot = UE.UKismetMathLibrary.NormalizedDeltaRotator(selfRotation, lookAt)
    if math.abs(deltaRot.Yaw) < 90 then
        selfActor:GetController():StopMovement()
        self:EndAction()

        local tag = UE.UHiGASLibrary.RequestGameplayTag('StateGH.Ability.Common.a')
        local Payload = UE.FGameplayEventData()
        Payload.EventTag = tag
        Payload.Instigator = selfActor
        UE.UAbilitySystemBlueprintLibrary.SendGameplayEventToActor(selfActor, tag, Payload)
    else
        if dist > self.FAR_DISTANCE then
            local selfYaw = selfRotation.Yaw
            local tarYaw = lookAt.Yaw
            selfRotation.Yaw = UE.UKismetMathLibrary.ClampAngle(tarYaw, selfYaw - self.MOVE_DELTA_MAX, selfYaw + self.MOVE_DELTA_MAX)
            selfActor:K2_SetActorRotation(selfRotation, true)
            local forward = UE.UKismetMathLibrary.GetForwardVector(selfRotation)
            tarLocation = forward * 1000 + selfLocation

            if selfActor.CustomMoveToStart then
                selfActor:CustomMoveToStart(tarLocation, self.MOVE_DURATION)
            end
        else
            local selfYaw = selfRotation.Yaw
            local tarYaw = lookAt.Yaw
            selfRotation.Yaw = UE.UKismetMathLibrary.ClampAngle(tarYaw, selfYaw - self.STAND_DELTA_MAX, selfYaw + self.STAND_DELTA_MAX)
            selfActor:K2_SetActorRotation(selfRotation, true)
            local forward = UE.UKismetMathLibrary.GetForwardVector(selfRotation)
            tarLocation = forward * 1000 + selfLocation
        end
        --UE.UKismetSystemLibrary.DrawDebugLine(self, selfLocation, tarLocation, UE.FLinearColor(1, 0, 0), 10)
    end
end
function GA_Snail_Skill_03_C:EndAction()
    if self.move_stoped then
        return
    end
    self.move_stoped = true
    local selfActor = self:GetAvatarActorFromActorInfo()
    if selfActor.CustomMoveToStop then
        selfActor:CustomMoveToStop()
        selfActor:SetCustomMoveCollisionCB(nil)
    end
end

--重写这个方法，改为背向方式
function GA_Snail_Skill_03_C:GetAvatarLookat(selfActor, tarActor)
    return UE.UKismetMathLibrary.FindLookAtRotation(tarActor:K2_GetActorLocation(), selfActor:K2_GetActorLocation())
end


return GA_Snail_Skill_03_C

