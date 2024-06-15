-- Charge GA.
local G = require("G")
local GASkillBase = require("skill.ability.GASkillBase")
local GADefend = Class(GASkillBase)


function GADefend:K2_ActivateAbility()
    Super(GADefend).K2_ActivateAbility(self)

    local GEClass = UE.UObject.Load("/Game/Blueprints/Skill/GE/GE_ImmuneFrontDamage.GE_ImmuneFrontDamage_C")
    self:BP_ApplyGameplayEffectToOwner(GEClass)
end

function GADefend:K2_OnEndAbility(bWasCancelled)
    Super(GADefend).K2_OnEndAbility(self, bWasCancelled)

    local Tag = UE.UHiGASLibrary.RequestGameplayTag("Ability.Skill.Defend.ImmuneFront")
    local TagContainer = UE.FGameplayTagContainer()
    TagContainer.GameplayTags:Add(Tag)
    self:BP_RemoveGameplayEffectFromOwnerWithGrantedTags(TagContainer)
end

return GADefend
