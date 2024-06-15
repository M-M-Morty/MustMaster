local G = require("G")

local BaseAttributeSet = require("actors.common.attribute.BasicAttributeSet")
local SkillUtils = require("common.skill_utils")
local AvatarCommonAttributeSet = Class(BaseAttributeSet)

function AvatarCommonAttributeSet:OnPreAttributeChange(Attribute, NewValue)
    Super(AvatarCommonAttributeSet).OnPreAttributeChange(self, Attribute, NewValue)

    -- Clamp current value.
    if Attribute.AttributeName == SkillUtils.AttrNames.Stamina then
        local MaxStamina = self.MaxStamina.CurrentValue
        NewValue = UE.UKismetMathLibrary.FClamp(NewValue, 0, MaxStamina)
    end

    if Attribute.AttributeName == SkillUtils.AttrNames.Power then
        local MaxPower = self.MaxPower.CurrentValue
        NewValue = UE.UKismetMathLibrary.FClamp(NewValue, 0, MaxPower)
    end

    return NewValue
end

function AvatarCommonAttributeSet:OnPostGameplayEffectExecute(EffectSpec, EvaluatedData, TargetASC)
    Super(AvatarCommonAttributeSet).OnPostGameplayEffectExecute(self, EffectSpec, EvaluatedData, TargetASC)

    -- Clamp base value here.
    if EvaluatedData.Attribute == TargetASC:FindAttributeByName(SkillUtils.AttrNames.Stamina) then
        self.Stamina.BaseValue = UE.UKismetMathLibrary.FClamp(self.Stamina.BaseValue, 0, self.MaxStamina.CurrentValue)
    end

    if EvaluatedData.Attribute == TargetASC:FindAttributeByName(SkillUtils.AttrNames.Power) then
        self.Power.BaseValue = UE.UKismetMathLibrary.FClamp(self.Power.BaseValue, 0, self.MaxPower.CurrentValue)
    end
end

return AvatarCommonAttributeSet
