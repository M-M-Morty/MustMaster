--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local GA_GH_CommonBase = require('CP0032305_GH.Script.skill.ability.GA_GH_CommonBase')

---@type GA_Snail_Skill_02_C
local GA_Snail_Skill_02_C = Class(GA_GH_CommonBase)

function GA_Snail_Skill_02_C:SetMoveTarget(tarActor)
    self.moveTarget = tarActor

    local selfActor = self:GetAvatarActorFromActorInfo()
    local lookAt = UE.UKismetMathLibrary.FindLookAtRotation(selfActor:K2_GetActorLocation(), tarActor:K2_GetActorLocation())
    local deltaRot = UE.UKismetMathLibrary.NormalizedDeltaRotator(selfActor:K2_GetActorRotation(), lookAt)
    self.forwardMove = math.abs(deltaRot.Yaw) <= 90;
end

function GA_Snail_Skill_02_C:ApplyCrash()
    local selfActor = self:GetAvatarActorFromActorInfo()
    local tag = UE.UHiGASLibrary.RequestGameplayTag("StateGH.Ability.Common.b")
    UE.UAbilitySystemBlueprintLibrary.SendGameplayEventToActor(selfActor, tag, nil)
end
function GA_Snail_Skill_02_C:GetBackwardRotation(rotation)
    local rightVec = UE.UKismetMathLibrary.GetRightVector(rotation)
    local forwardVec = UE.UKismetMathLibrary.GetForwardVector(rotation)
    local backRotation = UE.UKismetMathLibrary.MakeRotFromXY(forwardVec * -1, rightVec * -1)
    return backRotation
end

function GA_Snail_Skill_02_C:GetCustomMoveData()
    local selfActor = self:GetAvatarActorFromActorInfo()
    local tarActor = self.moveTarget
    local selfLocation = selfActor:K2_GetActorLocation()
    local tarLocation = tarActor:K2_GetActorLocation()
    local selfRotation = selfActor:K2_GetActorRotation()
    local moveRotation = self.forwardMove and selfRotation or self:GetBackwardRotation(selfRotation)
    local lookAt = UE.UKismetMathLibrary.FindLookAtRotation(selfLocation, tarLocation)
    local deltaRot = UE.UKismetMathLibrary.NormalizedDeltaRotator(moveRotation, lookAt)
    if math.abs(deltaRot.Yaw) < 90 and selfActor:GetDistanceTo(tarActor) > 100 then
        local selfYaw = moveRotation.Yaw
        moveRotation.Yaw = UE.UKismetMathLibrary.ClampAngle(lookAt.Yaw, selfYaw - self.DELTA_MAX, selfYaw + self.DELTA_MAX)
    end
    selfActor:K2_SetActorRotation((self.forwardMove and moveRotation or self:GetBackwardRotation(moveRotation)), true)

    local forward = UE.UKismetMathLibrary.GetForwardVector(moveRotation)
    tarLocation = forward * 1000 + selfLocation

    --UE.UKismetSystemLibrary.DrawDebugLine(self, selfLocation, tarLocation, UE.FLinearColor(1, 0, 0), 2)
    return tarLocation, self.MOVE_DURATION
end
function GA_Snail_Skill_02_C:StartMove()
    local selfActor = self:GetAvatarActorFromActorInfo()
    self.move_stoped = false
    selfActor.ChararacteStateManager:NotifyEvent('AbilityRushingStart')
    if selfActor.CustomMoveToStart then
        local tarLocation, duration = self:GetCustomMoveData()
        selfActor:CustomMoveToStart(tarLocation, duration)
        selfActor:SetCustomMoveCollisionCB(function() self:ApplyCrash() end)
    end
end
function GA_Snail_Skill_02_C:TickMove()
    if self.move_stoped then
        return
    end
    local selfActor = self:GetAvatarActorFromActorInfo()
    if selfActor.CustomMoveToStart then
        local tarLocation, duration = self:GetCustomMoveData()
        selfActor:CustomMoveToStart(tarLocation, duration)
    end
end
function GA_Snail_Skill_02_C:StopMove()
    if self.move_stoped then
        return false
    end
    self.move_stoped = true
    local selfActor = self:GetAvatarActorFromActorInfo()
    selfActor.ChararacteStateManager:NotifyEvent('AbilityRushingStop')
    if selfActor.CustomMoveToStop then
        selfActor:CustomMoveToStop()
        selfActor:SetCustomMoveCollisionCB(nil)
    end
    return true
end

function GA_Snail_Skill_02_C:K2_OnEndAbility(bWasCancelled)
    Super(GA_Snail_Skill_02_C).K2_OnEndAbility(self, bWasCancelled)
    self.Overridden.K2_OnEndAbility(self, bWasCancelled)
end


return GA_Snail_Skill_02_C

