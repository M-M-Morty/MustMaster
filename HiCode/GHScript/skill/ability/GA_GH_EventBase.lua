--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


---@type GA_GH_EventBase_C
local GA_GH_EventBase_C = Class()


function GA_GH_EventBase_C:K2_ActivateAbilityFromEvent(EventData)
    --UnLua.LogWarn('GA_GH_EventBase_C:K2_ActivateAbilityFromEvent', UE.UKismetSystemLibrary.GetDisplayName(self:GetClass()))

    local PlayTask = UE.UAbilityTask_PlayMontageAndWait.CreatePlayMontageAndWaitProxy(self, nil, self.MontageToPlay, 1.0, nil, true, 1.0, 0)
    self.Tasks:Add(PlayTask)
    PlayTask.OnCompleted:Add(self, self.OnCompleted_Default)
    --PlayTask.OnBlendOut:Add(self, self.OnBlendOut)
    PlayTask.OnInterrupted:Add(self, self.OnInterrupted_Default)
    PlayTask.OnCancelled:Add(self, self.OnCancelled_Default)
    PlayTask:ReadyForActivation()
end

function GA_GH_EventBase_C:OnCompleted_Default()
    self:K2_EndAbility(false)
end
function GA_GH_EventBase_C:OnInterrupted_Default()
    self:K2_EndAbility(false)
end
function GA_GH_EventBase_C:OnCancelled_Default()
    self:K2_EndAbility(false)
end

function GA_GH_EventBase_C:K2_OnEndAbility(bWasCancelled)
    --UnLua.LogWarn('GA_GH_EventBase_C:K2_OnEndAbility', UE.UKismetSystemLibrary.GetDisplayName(self:GetClass()), bWasCancelled)

    self.Tasks:Clear()
end

return GA_GH_EventBase_C

