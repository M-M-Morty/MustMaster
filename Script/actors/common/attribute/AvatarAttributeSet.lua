local G = require("G")

local BaseAttributeSet = require("actors.common.attribute.BasicAttributeSet")
local AvatarAttributeSet = Class(BaseAttributeSet)

function AvatarAttributeSet:OnPreAttributeChange(Attribute, NewValue)
    Super(AvatarAttributeSet).OnPreAttributeChange(self, Attribute, NewValue)

    if Attribute.AttributeName == SkillUtils.AttrNames.SuperPower then
        NewValue = UE.UKismetMathLibrary.FClamp(NewValue, 0, self.MaxSuperPower.CurrentValue)
    end

    return NewValue
end

function AvatarAttributeSet:OnPostGameplayEffectExecute(EffectSpec, EvaluatedData, TargetASC)
    local AbilityActorInfo = TargetASC:GetAbilityActorInfo()

    local TargetActor = AbilityActorInfo.AvatarActor
    if not UE.UKismetSystemLibrary.IsValid(TargetActor) then
        G.log:warn("AvatarAttributeSet", "OnPostGameplayEffectExecute target actor not valid.")
        return
    end

    local OldHealth = self.Health.CurrentValue
    Super(AvatarAttributeSet).OnPostGameplayEffectExecute(self, EffectSpec, EvaluatedData, TargetASC)
    if EvaluatedData.Attribute == TargetASC:FindAttributeByName(SkillUtils.AttrNames.SuperPower) then
        self.SuperPower.BaseValue = UE.UKismetMathLibrary.FClamp(self.SuperPower.BaseValue, 0, self.MaxSuperPower.CurrentValue)
    end
end

return AvatarAttributeSet