--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local GA_GH_CommonBase = require('CP0032305_GH.Script.skill.ability.GA_GH_CommonBase')

---@type GA_Mecha_Skill_05_C
local GA_Mecha_Skill_05_C = Class(GA_GH_CommonBase)


function GA_Mecha_Skill_05_C:K2_ActivateAbility()
    self:K2_CommitAbility()

    self.move_state = 0

    local PlayTask = UE.UAbilityTask_PlayMontageAndWait.CreatePlayMontageAndWaitProxy(self, nil, self.MontageToPlay, 1.0, nil, true, 1.0, 0)
    self:RefTask(PlayTask)
    --PlayTask.OnCompleted:Add(self, self.OnCompleted_Default)
    --PlayTask.OnBlendOut:Add(self, self.OnBlendOut)
    --PlayTask.OnInterrupted:Add(self, self.OnInterrupted_Default)
    PlayTask.OnCancelled:Add(self, self.OnCancelled_Default)
    PlayTask:ReadyForActivation()

    self:WaitHandleDamage()
    self:WaitHandleTurn()
    self:WaitHandleWarning()

    local delayTask = UE.UAbilityTask_WaitDelay.WaitDelay(self, self.TIME_DURATION)
    self:RefTask(delayTask)
    delayTask.OnFinish:Add(self, self.OnFinish_WaitFinish)
    delayTask:ReadyForActivation()

    local moveTag = UE.UHiGASLibrary.RequestGameplayTag('StateGH.Ability.MoveStart')
    local moveTask = UE.UAbilityTask_WaitGameplayEvent.WaitGameplayEvent(self, moveTag, nil, true, true)
    self:RefTask(moveTask)
    moveTask.EventReceived:Add(self, self.OnEventReceived_MoveStart)
    moveTask:ReadyForActivation()

    local crashTag = UE.UHiGASLibrary.RequestGameplayTag('StateGH.Ability.Crash')
    local crashTask = UE.UAbilityTask_WaitGameplayEvent.WaitGameplayEvent(self, crashTag, nil, false, true)
    self:RefTask(crashTask)
    crashTask.EventReceived:Add(self, self.OnEventReceived_MoveCrash)
    crashTask:ReadyForActivation()

    local stopTag = UE.UHiGASLibrary.RequestGameplayTag('StateGH.Ability.MoveStop')
    local stopTask = UE.UAbilityTask_WaitGameplayEvent.WaitGameplayEvent(self, stopTag, nil, false, true)
    self:RefTask(stopTask)
    stopTask.EventReceived:Add(self, self.OnEventReceived_MoveStop)
    stopTask:ReadyForActivation()
end
function GA_Mecha_Skill_05_C:OnCompleted_Default()
    self:K2_EndAbility(false)
end
function GA_Mecha_Skill_05_C:OnInterrupted_Default()
    self:K2_EndAbility(false)
end
function GA_Mecha_Skill_05_C:OnCancelled_Default()
    self:K2_EndAbility(false)
end
function GA_Mecha_Skill_05_C:OnFinish_WaitFinish()
    local eventTag = UE.UHiGASLibrary.RequestGameplayTag('StateGH.Ability.MoveStop')
    self:SendGameplayEvent(eventTag, nil)
end
function GA_Mecha_Skill_05_C:OnEventReceived_MoveStart()
    self:setMoveTarget(self:GetSkillTarget())
    self:StartMove()

    local tickTask = UE.UAbilityTask_Repeat.RepeatAction(self, 0.03, 999999)
    self:RefTask(tickTask)
    tickTask.OnPerformAction:Add(self, self.OnPerformAction_MoveUpdate)
    tickTask:ReadyForActivation()
end
function GA_Mecha_Skill_05_C:OnPerformAction_MoveUpdate()
    if self.move_state ~= 1 then
        return
    end

    if self:updateMoveTarget() then
        self:UpdateMove()
    end
end
function GA_Mecha_Skill_05_C:OnEventReceived_MoveCrash()
    if self.move_state ~= 1 then
        return
    end

    self:StopMove(2)

    local PlayTask = UE.UAbilityTask_PlayMontageAndWait.CreatePlayMontageAndWaitProxy(self, nil, self.MontageToPlay, 1.0, 'crash', true, 1.0, 0)
    self:RefTask(PlayTask)
    PlayTask.OnCompleted:Add(self, self.OnCompleted_Default)
    --PlayTask.OnBlendOut:Add(self, self.OnBlendOut)
    PlayTask.OnInterrupted:Add(self, self.OnInterrupted_Default)
    PlayTask.OnCancelled:Add(self, self.OnCancelled_Default)
    PlayTask:ReadyForActivation()
end
function GA_Mecha_Skill_05_C:OnEventReceived_MoveStop()
    if self.move_state ~= 1 then
        return
    end

    self:StopMove(3)

    local PlayTask = UE.UAbilityTask_PlayMontageAndWait.CreatePlayMontageAndWaitProxy(self, nil, self.MontageToPlay, 1.0, 'end', true, 1.0, 0)
    self:RefTask(PlayTask)
    PlayTask.OnCompleted:Add(self, self.OnCompleted_Default)
    --PlayTask.OnBlendOut:Add(self, self.OnBlendOut)
    PlayTask.OnInterrupted:Add(self, self.OnInterrupted_Default)
    PlayTask.OnCancelled:Add(self, self.OnCancelled_Default)
    PlayTask:ReadyForActivation()
end

--技能冲刺的脚本处理
function GA_Mecha_Skill_05_C:StartMove()
    self.move_state = 1

    local selfActor = self:GetAvatarActorFromActorInfo()
    selfActor.ChararacteStateManager:NotifyEvent('AbilityRushingStart')

    if selfActor.CustomMoveToStart then
        selfActor:CustomMoveToStart(self.moveTarget, self.MOVE_DURATION)
        selfActor:SetCustomMoveCollisionCB(function() self:ApplyCrash() end)
    end
end
function GA_Mecha_Skill_05_C:StopMove(state)
    self.move_state = state

    local selfActor = self:GetAvatarActorFromActorInfo()
    selfActor.ChararacteStateManager:NotifyEvent('AbilityRushingStop')

    if selfActor.CustomMoveToStop then
        selfActor:CustomMoveToStop()
        selfActor:SetCustomMoveCollisionCB(nil)
    end
end
function GA_Mecha_Skill_05_C:UpdateMove()
    local selfActor = self:GetAvatarActorFromActorInfo()
    if selfActor.CustomMoveToStart then
        selfActor:CustomMoveToStart(self.moveTarget, self.MOVE_DURATION)
    end
end

function GA_Mecha_Skill_05_C:OnSkillBlockedBy(tarActor)
    self:ApplyCrash()
end
function GA_Mecha_Skill_05_C:ApplyCrash()
    local avatar = self:GetAvatarActorFromActorInfo()
    local tag = UE.UHiGASLibrary.RequestGameplayTag("StateGH.Ability.Crash")
    UE.UAbilitySystemBlueprintLibrary.SendGameplayEventToActor(avatar, tag, nil)
end

function GA_Mecha_Skill_05_C:GetRushTarget(selfActor, tarActor)
    local selfLocation = selfActor:K2_GetActorLocation()
    local tarLocation = tarActor:K2_GetActorLocation()
    local selfRotation = selfActor:K2_GetActorRotation()
    local lookAt = UE.UKismetMathLibrary.FindLookAtRotation(selfLocation, tarLocation)
    local deltaRot = UE.UKismetMathLibrary.NormalizedDeltaRotator(selfRotation, lookAt)
    local rushRotation = selfRotation
    if math.abs(deltaRot.Yaw) < 90 and selfActor:GetDistanceTo(tarActor) > 100 then
        local selfYaw = selfRotation.Yaw
        rushRotation.Yaw = UE.UKismetMathLibrary.ClampAngle(lookAt.Yaw, selfYaw - self.UPDATE_DELTA, selfYaw + self.UPDATE_DELTA)
    end

    local forward = UE.UKismetMathLibrary.GetForwardVector(rushRotation)
    tarLocation = forward * 1000 + selfLocation

    --UE.UKismetSystemLibrary.DrawDebugLine(self, selfLocation, tarLocation, UE.FLinearColor(1, 0, 0), 2)
    return tarLocation
end
function GA_Mecha_Skill_05_C:setMoveTarget(tarActor)
    self.moveTargetActor = tarActor
    local selfActor = self:GetAvatarActorFromActorInfo()
    self.moveTarget = self:GetRushTarget(selfActor, tarActor)
end
function GA_Mecha_Skill_05_C:updateMoveTarget()
    local selfActor = self:GetAvatarActorFromActorInfo()
    local tarActor = self.moveTargetActor
    self.moveTarget = self:GetRushTarget(selfActor, tarActor)
    return true
end


function GA_Mecha_Skill_05_C:K2_OnEndAbility(bWasCancelled)
    Super(GA_Mecha_Skill_05_C).K2_OnEndAbility(self, bWasCancelled)

    self:StopMove(4)

    local selfActor = self:GetAvatarActorFromActorInfo()
    if selfActor.ChararacteStateManager then
        selfActor.ChararacteStateManager:NotifyEvent('StopMontageGroup', 'DefaultGroup')
    end

    --reset Tag
    local strTag = 'StateGH.AbilityState.Crashing'
    if FunctionUtil:HasGameplayTag(selfActor, strTag) then
        FunctionUtil:RemoveGameplayTag(selfActor, strTag)
    end
end


return GA_Mecha_Skill_05_C

