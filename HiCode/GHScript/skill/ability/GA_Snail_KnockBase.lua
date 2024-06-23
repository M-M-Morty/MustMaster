--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


local GA_GH_EventBase = require('CP0032305_GH.Script.skill.ability.GA_GH_EventBase')

---@type GA_Snail_KnockBase_C
local GA_Snail_KnockBase_C = Class(GA_GH_EventBase)


function GA_Snail_KnockBase_C:K2_ActivateAbilityFromEvent(EventData)
    --UnLua.LogWarn('GA_Snail_KnockBase_C:K2_ActivateAbilityFromEvent', UE.UKismetSystemLibrary.GetDisplayName(self:GetClass()))

    Super(GA_Snail_KnockBase_C).K2_ActivateAbilityFromEvent(EventData)

    local selfActor = self:GetAvatarActorFromActorInfo()
    if selfActor.ChararacteStateManager then
        selfActor.ChararacteStateManager:NotifyEvent('BeHitting', EventData.Instigator, EventData.OptionalObject)
    end
end

return GA_Snail_KnockBase_C

