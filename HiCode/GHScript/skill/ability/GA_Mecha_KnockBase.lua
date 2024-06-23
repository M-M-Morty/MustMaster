--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


---@type GA_Mecha_KnockBase_C
local GA_Mecha_KnockBase_C = Class()


function GA_Mecha_KnockBase_C:K2_ActivateAbilityFromEvent(EventData)
    --UnLua.LogWarn('GA_Mecha_KnockBase_C:K2_ActivateAbilityFromEvent', UE.UKismetSystemLibrary.GetDisplayName(self:GetClass()))

    local PlayTask = UE.UAbilityTask_PlayMontageAndWait.CreatePlayMontageAndWaitProxy(self, nil, self.MontageToPlay, 1.0, 'start', true, 1.0, 0)
    self.Tasks:Add(PlayTask)
    PlayTask.OnCompleted:Add(self, self.OnCompleted_Default)
    --PlayTask.OnBlendOut:Add(self, self.OnBlendOut)
    PlayTask.OnInterrupted:Add(self, self.OnInterrupted_Default)
    PlayTask.OnCancelled:Add(self, self.OnCancelled_Default)
    PlayTask:ReadyForActivation()

    local selfActor = self:GetAvatarActorFromActorInfo()
    if selfActor.ChararacteStateManager then
        selfActor.ChararacteStateManager:NotifyEvent('BeHitting', EventData.Instigator, EventData.OptionalObject)
    end
end

function GA_Mecha_KnockBase_C:OnCompleted_Default()
    self:K2_EndAbility(false)
end
function GA_Mecha_KnockBase_C:OnInterrupted_Default()
    self:K2_EndAbility(false)
end
function GA_Mecha_KnockBase_C:OnCancelled_Default()
    self:K2_EndAbility(false)
end

function GA_Mecha_KnockBase_C:K2_OnEndAbility(bWasCancelled)
    --UnLua.LogWarn('GA_Mecha_KnockBase_C:K2_OnEndAbility', UE.UKismetSystemLibrary.GetDisplayName(self:GetClass()))

    self.Tasks:Clear()
end

return GA_Mecha_KnockBase_C

