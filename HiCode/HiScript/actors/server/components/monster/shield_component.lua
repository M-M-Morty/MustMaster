require "UnLua"

local G = require("G")
local Component = require("common.component")
local ComponentBase = require("common.componentbase")
local check_table = require("common.data.state_conflict_data")

local ShieldServerComponent = Component(ComponentBase)
local decorator = ShieldServerComponent.decorator


function ShieldServerComponent:Initialize(...)
    Super(ShieldServerComponent).Initialize(self, ...)
end

function ShieldServerComponent:Start()
    Super(ShieldServerComponent).Start(self)

    self.WithStandSuccessWithGA = nil
end

function ShieldServerComponent:ReceiveBeginPlay()
    Super(ShieldServerComponent).ReceiveBeginPlay(self)

    if self.actor:IsClient() then
        self.actor:RemoveBlueprintComponent(self)
        return
    end
end

function ShieldServerComponent:Stop()
    Super(ShieldServerComponent).Stop(self)
end

decorator.message_receiver()
function ShieldServerComponent:PostReceivePossessed()
    -- Run on Server
    -- Component ReceivePossessed的顺序是不固定的...所以用PostReceivePossessed


    -- G.log:debug("yj", "PostReceivePossessed %s - %s", G.GetDisplayName(self.actor), G.GetHiAbilitySystemComponent(self.actor))
    self:RegisterGameplayTagCB("Ability.Skill.Defend.ImmuneFront", UE.EGameplayTagEventType.NewOrRemoved, "OnImuneFrontTagNewOrRemoved")
end

function ShieldServerComponent:OnImuneFrontTagNewOrRemoved(Tag, NewCount)

    -- G.log:debug("yj", "ShieldServerComponent:OnImuneFrontTagNewOrRemoved TagName.%s", Tag.TagName)

    local MountActors = self.actor.AIComponent.MountActors
    for i = 1, MountActors:Length() do
        if MountActors[i].OnOwnerImuneFrontTagNewOrRemoved then
            MountActors[i]:OnOwnerImuneFrontTagNewOrRemoved(NewCount)
        end
    end
end

return ShieldServerComponent
