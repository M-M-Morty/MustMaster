require "UnLua"

local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

local StiffnessComponent = Component(ComponentBase)

local decorator = StiffnessComponent.decorator


decorator.message_receiver()
function StiffnessComponent:HandleBeWithStand(TargetActor) 
    local ASC = G.GetHiAbilitySystemComponent(self.actor)
    local GASpec = SkillUtils.FindAbilitySpecFromSkillID(ASC, self.actor.SkillInUse)
    if GASpec == nil then
        return
    end
    
    -- G.log:debug("yj", "StiffnessComponent:HandleBeWithStand %s StiffnessMontage.%s", G.GetDisplayName(GASpec.Ability), G.GetDisplayName(GASpec.Ability.StiffnessMontage))

    -- if GASpec.Ability.StiffnessMontage then
    --     self:SendMessage("StopSkillAndBT")

    --     local Locomotion = self.actor.AppearanceComponent
    --     Locomotion:Multicast_PlayMontage(GASpec.Ability.StiffnessMontage, 1.0)
    --     Locomotion.OnMontageEnded:Add(self.actor, function()
    --         -- G.log:debug("yj", "StiffnessComponent:OnMontageEnded %s", G.GetDisplayName(self.actor))
    --         self:SendMessage("ResumeBT")
    --     end)
    -- end

    if GASpec.Ability.StiffnessGE then
        local AbilitySystemComponent = G.GetHiAbilitySystemComponent(self.actor)
        AbilitySystemComponent:BP_ApplyGameplayEffectToSelf(GASpec.Ability.StiffnessGE, 0.0, nil)
    end
end

decorator.message_receiver()
function StiffnessComponent:HandleBeImmunityBlockGameplayEffect(TargetActor, ImmunityGE)
    local ASC = G.GetHiAbilitySystemComponent(self.actor)
    local GASpec = SkillUtils.FindAbilitySpecFromSkillID(ASC, self.actor.SkillInUse)
    if self.actor:IsServer() and GASpec.Ability.StiffnessGE then
        local AbilitySystemComponent = G.GetHiAbilitySystemComponent(self.actor)
        AbilitySystemComponent:BP_ApplyGameplayEffectToSelf(GASpec.Ability.StiffnessGE, 0.0, nil)
    end
end

return StiffnessComponent
