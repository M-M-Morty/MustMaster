-- Charge GA.
local G = require("G")
local GASkillBase = require("skill.ability.GASkillBase")
local GACallShield = Class(GASkillBase)


function GACallShield:K2_ActivateAbility()
    Super(GACallShield).K2_ActivateAbility(self)

    -- local OwnerActor = self:GetOwningActorFromActorInfo()  -- ALS_Controller_MonsterAI_C_0
    local OwnerActor = self:GetAvatarActorFromActorInfo()  -- BPA_Monster_Shield
    local AIComponent = UE.UHiAIComponent.FindAIComponent(OwnerActor)

    local MountActorClass = UE.UObject.Load("/Game/Blueprints/Mount/BPA_MountActor_Shield.BPA_MountActor_Shield_C")
    AIComponent:CreateMountActor(MountActorClass, "lowerarm_lSocket")

    Blueprint'/Game/Blueprints/Skill/GE/GE_Shield.GE_Shield'
    local GEClass = UE.UObject.Load("/Game/Blueprints/Skill/GE/GE_Shield.GE_Shield_C")
    self:BP_ApplyGameplayEffectToOwner(GEClass)
end

return GACallShield
