--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


local GA_GH_CommonBase = require('CP0032305_GH.Script.skill.ability.GA_GH_CommonBase')

---@type GA_Mecha_Skill_TinBomb_C
local GA_Mecha_Skill_TinBomb_C = Class(GA_GH_CommonBase)


function GA_Mecha_Skill_TinBomb_C:K2_ActivateAbilityFromEvent(EventData)
    self:K2_CommitAbility()

    local damageTag = UE.UHiGASLibrary.RequestGameplayTag('StateGH.NotifyDamage.Default')
    local payLoad = UE.FGameplayEventData()
    payLoad.EventTag = damageTag
    payLoad.ContextHandle = EventData.ContextHandle
    self:InstantHandleDamage(payLoad)

    self:K2_EndAbility(false)
end

return GA_Mecha_Skill_TinBomb_C

