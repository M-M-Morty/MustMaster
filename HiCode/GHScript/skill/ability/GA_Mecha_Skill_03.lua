--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


local GA_GH_CommonBase = require('CP0032305_GH.Script.skill.ability.GA_GH_CommonBase')

---@type GA_Mecha_Skill_03_C
local GA_Mecha_Skill_03_C = Class(GA_GH_CommonBase)


function GA_Mecha_Skill_03_C:K2_ActivateAbility()
    self:K2_CommitAbility()

    self.fire_count = 0

    local PlayTask = UE.UAbilityTask_PlayMontageAndWait.CreatePlayMontageAndWaitProxy(self, nil, self.MontageToPlay, 1.0, nil, true, 1.0, 0)
    self:RefTask(PlayTask)
    --PlayTask.OnCompleted:Add(self, self.OnCompleted_Default)
    --PlayTask.OnBlendOut:Add(self, self.OnBlendOut)
    --PlayTask.OnInterrupted:Add(self, self.OnInterrupted_Default)
    PlayTask.OnCancelled:Add(self, self.OnCancelled_Default)
    PlayTask:ReadyForActivation()

    self:WaitHandleDamage()
    self:WaitHandleTurn()

    local fireTag = UE.UHiGASLibrary.RequestGameplayTag('StateGH.NotifyDamage.Default')
    local waitFire = UE.UAbilityTask_WaitGameplayEvent.WaitGameplayEvent(self, fireTag, nil, false, true)
    self:RefTask(waitFire)
    waitFire.EventReceived:Add(self, self.OnEventReceived_Fire)
    waitFire:ReadyForActivation()

    local finishTag = UE.UHiGASLibrary.RequestGameplayTag('StateGH.Ability.Common.a')
    local waitFinish = UE.UAbilityTask_WaitGameplayEvent.WaitGameplayEvent(self, finishTag, nil, false, true)
    self:RefTask(waitFinish)
    waitFinish.EventReceived:Add(self, self.OnEventReceived_Finish)
    waitFinish:ReadyForActivation()
end
function GA_Mecha_Skill_03_C:OnCancelled_Default()
    self:K2_EndAbility(false)
end

function GA_Mecha_Skill_03_C:OnEventReceived_Fire(payLoad)
    self.fire_count = self.fire_count + 1
end
function GA_Mecha_Skill_03_C:OnEventReceived_Finish(payLoad)
    if self.fire_count < self.FIRE_COUNT_MAX then
        return
    end

    local PlayTask = UE.UAbilityTask_PlayMontageAndWait.CreatePlayMontageAndWaitProxy(self, nil, self.MontageToPlay, 1.0, 'end_start', true, 1.0, 0)
    self:RefTask(PlayTask)
    PlayTask.OnCompleted:Add(self, self.OnCompleted_Finish)
    --PlayTask.OnBlendOut:Add(self, self.OnBlendOut)
    PlayTask.OnInterrupted:Add(self, self.OnInterrupted_Finish)
    PlayTask.OnCancelled:Add(self, self.OnCancelled_Finish)
    PlayTask:ReadyForActivation()
end
function GA_Mecha_Skill_03_C:OnCompleted_Finish()
    self:K2_EndAbility(false)
end
function GA_Mecha_Skill_03_C:OnInterrupted_Finish()
    self:K2_EndAbility(false)
end
function GA_Mecha_Skill_03_C:OnCancelled_Finish()
    self:K2_EndAbility(false)
end

function GA_Mecha_Skill_03_C:K2_OnEndAbility(bWasCancelled)
    Super(GA_Mecha_Skill_03_C).K2_OnEndAbility(self, bWasCancelled)

    local selfActor = self:GetAvatarActorFromActorInfo()
    if selfActor.ChararacteStateManager then
        selfActor.ChararacteStateManager:NotifyEvent('StopMontageGroup', 'DefaultGroup')
    end
end


return GA_Mecha_Skill_03_C

