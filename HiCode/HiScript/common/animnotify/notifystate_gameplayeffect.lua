require "UnLua"

local G = require("G")

local NotifyState_GameplayEffect = Class()


function NotifyState_GameplayEffect:Received_NotifyBegin(MeshComp, Animation, TotalDuration, EventReference)
    local Owner = MeshComp:GetOwner()
    if not Owner:IsServer() then
        return true
    end
    local TargetASC = UE.UAbilitySystemBlueprintLibrary.GetAbilitySystemComponent(Owner)
    if TargetASC then
        for Ind = 1, self.GEList:Length() do
            local GE = self.GEList:Get(Ind)
           TargetASC:BP_ApplyGameplayEffectToSelf(GE, 0.0, nil)
        end
    end
    return true
end

function NotifyState_GameplayEffect:Received_NotifyEnd(MeshComp, Animation, EventReference)
    local Owner = MeshComp:GetOwner()
    if not Owner:IsServer() then
        return true
    end
    local TargetASC = UE.UAbilitySystemBlueprintLibrary.GetAbilitySystemComponent(Owner)
    if TargetASC then
        for Ind = 1, self.GEList:Length() do
            TargetASC:RemoveActiveGameplayEffectBySourceEffect(self.GEList:Get(Ind))
        end
    end
    return true
end

return NotifyState_GameplayEffect
