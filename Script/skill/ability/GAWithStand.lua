-- Charge GA.
local G = require("G")
local GAPlayerSkillBase = require("skill.ability.GAPlayerBase")
local GAWithStand = Class(GAPlayerSkillBase)


function GAWithStand:K2_ActivateAbility()
    Super(GAWithStand).K2_ActivateAbility(self)
    if self.bEnd then
        return
    end
    
    local GEClass = UE.UObject.Load("/Game/Blueprints/Skill/GE/GE_WithStand.GE_WithStand_C")
    self:BP_ApplyGameplayEffectToOwner(GEClass)

    GEClass = UE.UObject.Load("/Game/Blueprints/Skill/GE/GE_ExtremeWithStand.GE_ExtremeWithStand_C")
    self:BP_ApplyGameplayEffectToOwner(GEClass)

	self.ExtremeTimer = self:GetOwner():SetTimerDelegate({self, self.OnExtremeWithStandEnd}, self.ExtremeWithStandTime, false)

    local Owner = self:GetOwner()
    Owner:SendMessage("EnterWithStand", self)
end

function GAWithStand:OnExtremeWithStandEnd()

    local GEClass = UE.UObject.Load("/Game/Blueprints/Skill/GE/GE_SetDamageScale_001.GE_SetDamageScale_001_C")
    self:BP_ApplyGameplayEffectToOwner(GEClass)
end

function GAWithStand:K2_OnEndAbility(bWasCancelled)
    Super(GAWithStand).K2_OnEndAbility(self, bWasCancelled)

    if self.ExtremeTimer then
		self:GetOwner():ClearAndInvalidateTimerHandle(self, self.ExtremeTimer)
	end

    local Tag = UE.UHiGASLibrary.RequestGameplayTag("Ability.Skill.Defend.WithStand")
    local TagContainer = UE.FGameplayTagContainer()
    TagContainer.GameplayTags:Add(Tag)
    self:BP_RemoveGameplayEffectFromOwnerWithGrantedTags(TagContainer)

    local GEClass = UE.UObject.Load("/Game/Blueprints/Skill/GE/GE_SetDamageScale_100.GE_SetDamageScale_100_C")
    self:BP_ApplyGameplayEffectToOwner(GEClass)

    local Owner = self:GetOwner()
    if Owner then
        Owner:SendMessage("EndWithStand", self)
	end
end

function GAWithStand:GetOwner()
    local OwnerActor = self:GetOwningActorFromActorInfo()
    return OwnerActor
end

return GAWithStand
