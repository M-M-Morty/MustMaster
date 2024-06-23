local G = require("G")

local BaseAttributeSet = require("actors.common.attribute.BasicAttributeSet")
local MonsterAttributeSet = Class(BaseAttributeSet)

function MonsterAttributeSet:OnPreAttributeChange(Attribute, NewValue)
    Super(MonsterAttributeSet).OnPreAttributeChange(self, Attribute, NewValue)

    if Attribute.AttributeName == SkillUtils.AttrNames.Tenacity then
        local MaxTenacity = SkillUtils.GetAttribute(self:GetHiAbilitySystemComponent(), SkillUtils.AttrNames.MaxTenacity).BaseValue
        NewValue = UE.UKismetMathLibrary.FClamp(NewValue, 0, MaxTenacity)
    end

    return NewValue
end

return MonsterAttributeSet
