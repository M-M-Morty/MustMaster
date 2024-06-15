local G = require("G")
local GASequenceBase = require("skill.ability.GASequence")
local GAJudge = Class(GASequenceBase)

function GAJudge:HandleActivateAbility()
    local TargetActor = self:GetSkillTarget()
    if not TargetActor then
        G.log:error("GAJudge", "HandleActivateAbility no target actor found!")
        self:K2_EndAbility()
        return
    end

    Super(GAJudge).HandleActivateAbility(self)
end

function GAJudge:InitBindings()
    local Bindings = UE.TArray(UE.FAbilityTaskSequenceBindings)

    -- Player binding.
    local PlayerBinding = UE.FAbilityTaskSequenceBindings()
    PlayerBinding.BindingTag = self.PlayerBindingTag .. tostring(self.OwnerActor.CharType)
    PlayerBinding.Actors = _MakeActorArray(self.OwnerActor)
    Bindings:Add(PlayerBinding)

    -- Monster binding.
    local TargetActor = self:GetSkillTarget()
    local MonsterBinding = UE.FAbilityTaskSequenceBindings()
    MonsterBinding.BindingTag = self.MonsterBindingTag
    MonsterBinding.Actors = _MakeActorArray(TargetActor)
    Bindings:Add(MonsterBinding)

    return Bindings
end

function GAJudge:HandleEndAbility(bWasCancelled)
    self.OwnerActor:SendMessage("OnEndJudge")

    local TargetActor = self:GetSkillTarget()

    if TargetActor then
        if self.BeJudgedTriggerTag.TagName then
            if self:IsServer() then
                local HitPayload = UE.FGameplayEventData()
                HitPayload.EventTag = self.BeJudgedTriggerTag
                HitPayload.Instigator = self.Instigator
                HitPayload.Target = TargetActor

                UE.UAbilitySystemBlueprintLibrary.SendGameplayEventToActor(TargetActor, HitPayload.EventTag, HitPayload)
            end
        else
            TargetActor:SendMessage("OnEndBeJudge")
        end
    else
        G.log:error("GAJudge", "HandleActivateAbility no target actor found!")
    end

    Super(GAJudge).HandleEndAbility(self, bWasCancelled)
end

return GAJudge
