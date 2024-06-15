require "UnLua"

local G = require("G")

local Actor = require("common.actor")

local MountActor = Class(Actor)


MountActor.__all_client_components__ = {
    UIComponentMountActor = "actors.client.components.ui_component_mountactor",
}

MountActor.__all_server_components__ = {
    -- CaptureComponent = "actors.server.components.capture_component",
    MountActorCaptureComponent = "actors.server.components.mountactor_capture_component",
}


function MountActor:Initialize(...)
    Super(MountActor).Initialize(self, ...)

    self:InitBasicAttribute()
    self.DeadDelay = 0.1
end

function MountActor:InitBasicAttribute()
    local AttributeSetClass = UE.UClass.Load("/Game/Blueprints/Skill/Attributes/BP_MonsterAttributeSet.BP_MonsterAttributeSet_C")
    self.AttributeSet = NewObject(AttributeSetClass, self)
end

function MountActor:ReceiveBeginPlay()
    self.AttributeComponent:InitializeWithAbilitySystem(self:GetAbilitySystemComponent())
    self.AttributeComponent:InitAttributeListener()

    if self:IsClient() or UE.UKismetSystemLibrary.IsStandalone(self) then
        self:AddScriptComponent("UIComponentMountActor", true)
    else
        -- self:AddScriptComponent("CaptureComponent", true)
        self:AddScriptComponent("MountActorCaptureComponent", true)
    end

    if self.BP_ReceiveBeginPlay ~= nil then
        self:BP_ReceiveBeginPlay()
    end
end

function MountActor:ReceiveTick(DeltaSeconds)
    self:SendMessage("OnReceiveTick", DeltaSeconds)
end

function MountActor:ReceiveDestroyed()
    G.log:debug("yj", "MountActor ReceiveDestroyed %s", self:IsClient())

    if self.BP_ReceiveDestroyed ~= nil then
        self:BP_ReceiveDestroyed()
    end
end

function MountActor:GetName()
    return "MountActor"
end

function MountActor:IsDead()
    return self.bDead
end

function MountActor:SetDead(bDead)
    self.bDead = bDead
end

function MountActor:OnAttributeChanged(Attribute, NewValue, OldValue)
    G.log:debug("yj", "MountActor OnAttributeChanged: %s, %f, %f", Attribute.AttributeName, NewValue, OldValue)
    local AttributeName = Attribute.AttributeName
    local MessageTopic = "On"..AttributeName.."Changed"
    self:SendMessage(MessageTopic, NewValue, OldValue)
end

function MountActor:FindAbilitySpecHandleFromSkillID(SkillID)
    local AbilitySystemComponent = G.GetHiAbilitySystemComponent(self)
    local ActivatableAbilities = AbilitySystemComponent.ActivatableAbilities.Items
    local Count = ActivatableAbilities:Length()
    for ind = 1, Count do
        local Spec = ActivatableAbilities:Get(ind)
        if Spec.UserData and SkillID == Spec.UserData.SkillID then
            return Spec.Handle
        end
    end
end

-- Overide By Blueprints
-- function MountActor:OnOwnerGamePlayTagNewOrRemove(Tag, NewCount)
--     -- G.log:debug("yj", "MountActor OnOwnerGamePlayTagNewOrRemove %s - %s", Tag.TagName, NewCount)

--     if Tag.TagName ~= "Ability.Skill.Defend.ImmuneFront" then
--         return
--     end
    
--     local ASC = self:GetAbilitySystemComponent()

--     if NewCount > 0 then
--         -- add ImmuneBack
--         local RaiseShieldGEClass = UE.UClass.Load("/Game/Blueprints/Skill/Player/GE/GE_ImmuneBackDamage.GE_ImmuneBackDamage_C")
--         local RaiseShieldGESpecHandle = ASC:MakeOutgoingSpec(RaiseShieldGEClass, 1, UE.FGameplayEffectContextHandle())
--         ASC:BP_ApplyGameplayEffectSpecToSelf(RaiseShieldGESpecHandle)
--     else
--         -- add Block
--         local BlockGEClass = UE.UClass.Load("/Game/Blueprints/Skill/Player/GE/GE_Block.GE_Block_C")
--         local BlockGESpecHandle = ASC:MakeOutgoingSpec(BlockGEClass, 1, UE.FGameplayEffectContextHandle())
--         ASC:BP_ApplyGameplayEffectSpecToSelf(BlockGESpecHandle)
--     end
-- end

return RegisterActor(MountActor)
