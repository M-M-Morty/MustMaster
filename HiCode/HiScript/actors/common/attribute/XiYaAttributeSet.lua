---
---西雅角色特有的属性集
---
local G = require("G")

local BaseAttributeSet = require("actors.common.attribute.BasicAttributeSet")
local XiYaAttributeSet = Class(BaseAttributeSet)

function XiYaAttributeSet:OnPreAttributeChange(Attribute, NewValue)
    Super(XiYaAttributeSet).OnPreAttributeChange(self, Attribute, NewValue)

    if Attribute.AttributeName == SkillUtils.AttrNames.Bullet then
        NewValue = UE.UKismetMathLibrary.FClamp(NewValue, 0, self.MaxBullet.CurrentValue)
    end

    return NewValue
end

function XiYaAttributeSet:OnPostGameplayEffectExecute(EffectSpec, EvaluatedData, TargetASC)
    Super(XiYaAttributeSet).OnPostGameplayEffectExecute(self, EffectSpec, EvaluatedData, TargetASC)

    if EvaluatedData.Attribute == TargetASC:FindAttributeByName(SkillUtils.AttrNames.Bullet) then
        self.Bullet.BaseValue = UE.UKismetMathLibrary.FClamp(self.Bullet.BaseValue, 0, self.MaxBullet.CurrentValue)
    end
end

return XiYaAttributeSet
