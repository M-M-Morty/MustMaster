--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


local GA_GH_EventBase = require('CP0032305_GH.Script.skill.ability.GA_GH_EventBase')

---@type GA_Snail_Tenacity_Zero_C
local GA_Snail_Tenacity_Zero_C = Class(GA_GH_EventBase)


function GA_Snail_Tenacity_Zero_C:K2_OnEndAbility(bWasCancelled)
    --UnLua.LogWarn('GA_Snail_Tenacity_Zero_C:K2_OnEndAbility', UE.UKismetSystemLibrary.GetDisplayName(self:GetClass()), bWasCancelled)

    Super(GA_Snail_Tenacity_Zero_C).K2_OnEndAbility(bWasCancelled)

    if not bWasCancelled then
        self:BP_ApplyGameplayEffectToOwner(self.restoreGE, 1, 1)
    end
end

return GA_Snail_Tenacity_Zero_C

