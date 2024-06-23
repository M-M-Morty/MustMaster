local G = require("G")

local BasicAttributeSet = Class()
function BasicAttributeSet:OnPreAttributeChange(Attribute, NewValue)
    self.Overridden.OnPreAttributeChange(self, Attribute, NewValue)

    --G.log:debug("santi", "BasicAttributeSet OnPreAttributeChange Attribute: %s, NewValue: %f", Attribute.AttributeName, NewValue)
end

function BasicAttributeSet:OnPostGameplayEffectExecute(EffectSpec, EvaluatedData, TargetASC)
    local Context = UE.UHiGASLibrary.GetGameplayEffectContextHandle(EffectSpec)
    local AbilityActorInfo = TargetASC:GetAbilityActorInfo()

    -- TODO always false ?
    --if not UE.UKismetSystemLibrary.IsValid(AbilityActorInfo) then
    --    G.log:warn("santi", "BasicAttributeSet OnPostGameplayEffectExecute AbilityActorInfo not valid.")
    --    return
    --end

    local TargetActor = AbilityActorInfo.AvatarActor
    if not UE.UKismetSystemLibrary.IsValid(TargetActor) then
        G.log:warn("santi", "BasicAttributeSet OnPostGameplayEffectExecute target actor not valid.")
        return
    end

    local CurAttr = EvaluatedData.Attribute
    --G.log:debug("santi", "BasicAttributeSet OnPostGameplayEffectExecute target: %s, attribute: %s", G.GetDisplayName(TargetActor), CurAttr.AttributeName)

    if EvaluatedData.Attribute == self:FindAttribute(SkillUtils.AttrNames.Damage) then
        local Instigator = UE.UAbilitySystemBlueprintLibrary.EffectContextGetInstigatorActor(Context)
        local EffectCauser = UE.UAbilitySystemBlueprintLibrary.EffectContextGetEffectCauser(Context)
        local HitResult = UE.UAbilitySystemBlueprintLibrary.EffectContextGetHitResult(Context)

        local LocalDamage = self.Damage.CurrentValue

        if utils.IsWithStandSuccess(EffectCauser, TargetActor) then
            LocalDamage = LocalDamage * self.WithStandDamageScale.CurrentValue
        end

        local OldHealth = self.Health.CurrentValue
        if LocalDamage ~= 0 and OldHealth > 0 then
            local HealthAttr = self:FindAttribute(SkillUtils.AttrNames.Health)
            local ClampedValue = UE.UKismetMathLibrary.FClamp(OldHealth - LocalDamage, 0, self.MaxHealth.CurrentValue)
            -- TODO: 先设置 Health 属性值，每次调用 SetAttributeBaseValue 会清空 ModCallbackData 上下文. 后续考虑加个 set ModCallbackData 的接口
            self:SetAttributeBaseValue(HealthAttr, ClampedValue)
            --AddPower
            local IsPlayerCauser = EffectCauser:IsPlayerSide()
            local IsMonsterTarget = TargetActor:IsMonster()
            if IsPlayerCauser and IsMonsterTarget then
                if EffectCauser and EffectCauser.BuffComponent then
                    -- No buff damage, can accumulate power.
                    if not EffectCauser.BuffComponent:IsBuff(EffectSpec) then
                        EffectCauser:SendMessage("AddPowerOnDamage", LocalDamage)
                    end
                end                
            end
            
            local DamageAttr = TargetASC:FindAttributeByName(SkillUtils.AttrNames.Damage)
            self:SetAttributeBaseValue(DamageAttr, 0)
            TargetActor:SendMessage("HandleDamage", LocalDamage, HitResult, Instigator, EffectCauser, UE.UHiGASLibrary.EffectContextGetAbility(Context), EffectSpec)
        end        
    end
end

function BasicAttributeSet:SetAttributeBaseValue(Attr, Value)
    local OwningASC = self:GetHiAbilitySystemComponent()
    if OwningASC then
        OwningASC:SetAttributeBaseValue(Attr, Value)
    end
end

function BasicAttributeSet:SetAttributeCurrentValue(Attr, Value)
    local OwningASC = self:GetHiAbilitySystemComponent()
    if OwningASC then
        OwningASC:SetAttributeCurrentValue(Attr, Value)
    end
end

function BasicAttributeSet:OnRep_Health(OldAttr)
    self.Overridden.OnRep_Health(self, OldAttr)

    if self:GetAvatarActor() then
        self:GetAvatarActor():SendMessage("OnRep_Health", self.Health, OldAttr)
    end
end

function BasicAttributeSet:OnRep_MaxHealth(OldAttr)
    self.Overridden.OnRep_MaxHealth(self, OldAttr)

    if self:GetAvatarActor() then
        self:GetAvatarActor():SendMessage("OnRep_MaxHealth", self.MaxHealth, OldAttr)
    end
end

function BasicAttributeSet:GetAvatarActor()
    local OwningASC = self:GetHiAbilitySystemComponent()
    if OwningASC then
        local AbilityActorInfo = OwningASC:GetAbilityActorInfo()
        return AbilityActorInfo.AvatarActor
    end
end

return BasicAttributeSet
