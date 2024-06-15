require "UnLua"
local G = require("G")
local Component = require("common.component")
local ComponentBase = require("common.componentbase")
local SkillKnock = Component(ComponentBase)
local decorator = SkillKnock.decorator

--[[
Component for handle skill KnockBack and KnockFly
]]

function SkillKnock:Start()
    Super(SkillKnock).Start(self)

    self.is_enable_ragdoll = false

    self.CharacterMovement = self.actor.CharacterMovement

    self.HitPartMap = { Head = Enum.EPhysicsBodyPart.Head, Hand_R = Enum.EPhysicsBodyPart.HandRight, Hand_L = Enum.EPhysicsBodyPart.HandLeft,  }
    self.KnockActors = {}

    --G.log:debug("devin", "SkillKnock:Start")

    -- self.actor.CapsuleComponent:SetCollisionEnabled(UE.ECollisionEnabled.QueryOnly)
    -- self.actor.Mesh:SetCollisionObjectType(UE.ECollisionChannel.ECC_PhysicsBody)
    -- self.actor.Mesh:SetCollisionEnabled(UE.ECollisionEnabled.PhysicsOnly)

    -- self.actor.Mesh:SetAllBodiesBelowSimulatePhysics("neck_02", true, true)

    -- self.actor.Mesh:SetAllBodiesBelowPhysicsBlendWeight("neck_02", 1.0, false, true)
end

function SkillKnock:ReceiveBeginPlay()
    Super(SkillKnock).ReceiveBeginPlay(self)
    self.__TAG__ = string.format("SkillKnock(actor: %s, server: %s)", G.GetObjectName(self.actor), self.actor:IsServer())
end

function SkillKnock:Stop()

    --G.log:debug("devin", "SkillKnock:Stop")

    Super(SkillKnock).Stop(self)

    for k, actor in pairs(self.KnockActors) do
        actor:K2_DestroyActor()
    end

    self.KnockActors = {}

end

function SkillKnock:OnKnockActivated(KnockBehavior)
    self.ActiveBehaviors:Add(KnockBehavior)
end

function SkillKnock:OnKnockDeactivated(KnockBehavior)
    self.ActiveBehaviors:RemoveItem(KnockBehavior)
end

decorator.message_receiver()
function SkillKnock:BreakHitTail(reason)
    G.log:debug(self.__TAG__, "BreakHitTail reason: %s", utils.ActionToStr(reason))
    self:CopyBehaviors()
    for BehaviorIndex = 1, self.ActiveBehaviorsCopy:Length() do
        local ActiveBehavior = self.ActiveBehaviorsCopy:Get(BehaviorIndex)

        if ActiveBehavior and ActiveBehavior:IsHitTail() then
            ActiveBehavior:K2_EndAbility(true)
        end
    end
end

decorator.message_receiver()
function SkillKnock:OnBreakHit(reason)
    G.log:debug(self.__TAG__, "OnBreakHit reason: %s", utils.ActionToStr(reason))
    self:CopyBehaviors()
    for BehaviorIndex = 1, self.ActiveBehaviorsCopy:Length() do
        local ActiveBehavior = self.ActiveBehaviorsCopy:Get(BehaviorIndex)

        if ActiveBehavior then
            ActiveBehavior:K2_EndAbility(true)
        end
    end
end

function SkillKnock:OnKnockBack(KnockParams)

    local KnockInfo = KnockParams.KnockInfo
    self:InitKnock(KnockParams)

    if (not self.actor:IsStandalone()) or (self.actor:IsStandalone() and self:IsServerComponent()) then
        
        local HitResult = KnockParams.HitResult

        local ComponentName = HitResult and HitResult.Component and HitResult.Component.ComponentTags and HitResult.Component.ComponentTags:Length() > 0 and HitResult.Component.ComponentTags:Get(1)

        if ComponentName and self.HitPartMap[ComponentName] then
            self:DoKnockComponent(KnockParams)
        else

        end
    end
end

function SkillKnock:DoKnockComponent(KnockParams)

    local HitResult = KnockParams.HitResult
    local ComponentName = HitResult and HitResult.Component and HitResult.Component.ComponentTags[1]

    local PartType = self.HitPartMap[ComponentName]

    G.log:error("devin", "SkillKnock:DoKnockComponent %s %s", ComponentName, tostring(PartType))

    if PartType == nil then
        return
    end

    local HitConfig = self:GetHitConfig(PartType)

    local KnockActor = self.KnockActors[PartType]

    if not KnockActor then

        local SpawnParameters = UE.FActorSpawnParameters()
        -- SpawnParameters.ObjectFlags = SpawnParameters.ObjectFlags | UE.EObjectFlags.RF_Transient
        local Class = HitConfig.PhysicsHitExecuter
        local ExtraData = { SkeletalMesh = self.actor.Mesh, DefaultBone = HitConfig.DefaultBone, PhysicsBones = HitConfig.PhysicsBones, Delay = HitConfig.Delay }

        local SpawnTransform = UE.FTransform(self.actor:K2_GetActorRotation():ToQuat(), self.actor:K2_GetActorLocation())
        KnockActor = GameAPI.SpawnActor(self.actor:GetWorld(), Class, SpawnTransform, SpawnParameters, ExtraData)

        self.KnockActors[PartType] = KnockActor
    end

    --G.log:error("devin", "SkillKnock:DoKnockComponent %s", ComponentName)

    local HitDirection = -HitResult.ImpactNormal

    KnockActor:HitPart(nil, HitResult.ImpactPoint, HitDirection * KnockParams.KnockImpulse)
end


function SkillKnock:BeginRagdoll()
    self.actor.CapsuleComponent:SetCollisionEnabled(UE.ECollisionEnabled.QueryOnly)
    self.actor.Mesh:SetCollisionObjectType(UE.ECollisionChannel.ECC_PhysicsBody)
    self.actor.Mesh:SetCollisionEnabled(UE.ECollisionEnabled.PhysicsOnly)

    local PhysicsBones = self.HitFlyPhysicsBones
    for PhyicsBonesIndex = 1, PhysicsBones:Length() do
        local PhysicsBone = PhysicsBones:Get(PhyicsBonesIndex)
        self.actor.Mesh:SetAllBodiesBelowSimulatePhysics(PhysicsBone.BoneName, PhysicsBone.EnableSimulate, PhysicsBone.IncludeSelf)
    end

    PhysicsBones = self.HitFlyPhysicsBlendWeights
    for PhyicsBonesIndex = 1, PhysicsBones:Length() do
        local PhysicsBone = PhysicsBones:Get(PhyicsBonesIndex)
        self.actor.Mesh:SetAllBodiesBelowPhysicsBlendWeight(PhysicsBone.BoneName, PhysicsBone.BlendWeight, false, PhysicsBone.IncludeSelf)
    end

    self.is_enable_ragdoll = true
end

function SkillKnock:EndRagdoll()
    self.actor.CapsuleComponent:SetCollisionEnabled(UE.ECollisionEnabled.QueryAndPhysics)
    self.actor.Mesh:SetCollisionObjectType(UE.ECollisionChannel.ECC_Pawn)
    self.actor.Mesh:SetCollisionEnabled(UE.ECollisionEnabled.QueryOnly)
    self.actor.Mesh:SetAllBodiesSimulatePhysics(false)

    self.is_enable_ragdoll = false
end

decorator.message_receiver()
function SkillKnock:ReceiveMoveBlockedBy(HitResult)
    self:CopyBehaviors()
    for BehaviorIndex = 1, self.ActiveBehaviorsCopy:Length() do
        local ActiveBehavior = self.ActiveBehaviorsCopy:Get(BehaviorIndex)

        if ActiveBehavior and ActiveBehavior.ReceiveMoveBlockedBy then
            ActiveBehavior:ReceiveMoveBlockedBy(HitResult)
        end
    end
end

function SkillKnock:OnGrounded()
    if self.is_enable_ragdoll then
        self:EndRagdoll()
    end
end

function SkillKnock:OnHitFlyLand()
    self:SendMessage("OnHitFlyLand")
    self:CopyBehaviors()
    for BehaviorIndex = 1, self.ActiveBehaviorsCopy:Length() do
        local ActiveBehavior = self.ActiveBehaviorsCopy:Get(BehaviorIndex)

        if ActiveBehavior and ActiveBehavior.OnHitFlyLand then
            ActiveBehavior:OnHitFlyLand()
        end
    end
end

decorator.message_receiver()
function SkillKnock:OnLand()
end

decorator.message_receiver()
function SkillKnock:BreakHitFly()
    self:EndHitFly()
end

decorator.message_receiver()
function SkillKnock:BeginHitFly()
    G.log:debug(self.__TAG__, "BeginHitFly")
    self.actor.CharacterStateManager:SetHitFly(true)
end

decorator.message_receiver()
function SkillKnock:EndHitFly()
    G.log:debug(self.__TAG__, "EndHitFly")
    self.actor.CharacterStateManager:SetHitFly(false)
end

function SkillKnock:CopyBehaviors()
    self.ActiveBehaviorsCopy:Clear()
    for Ind = 1, self.ActiveBehaviors:Length() do
        self.ActiveBehaviorsCopy:Add(self.ActiveBehaviors:Get(Ind))
    end
end

decorator.message_receiver()
function SkillKnock:OnBeginNoHit()
    local Tag = UE.UHiGASLibrary.RequestGameplayTag("Ability.Skill.Immunity.Hit")
    local ASC = self.actor.AbilitySystemComponent

    local TagContainer = UE.FGameplayTagContainer()
    TagContainer.GameplayTags:Add(Tag)
    if not ASC:HasGameplayTag(Tag) then
        UE.UAbilitySystemBlueprintLibrary.AddLooseGameplayTags(self.actor, TagContainer, true)
    end
end

decorator.message_receiver()
function SkillKnock:OnEndNoHit()
    local Tag = UE.UHiGASLibrary.RequestGameplayTag("Ability.Skill.Immunity.Hit")
    local ASC = self.actor.AbilitySystemComponent

    local TagContainer = UE.FGameplayTagContainer()
    TagContainer.GameplayTags:Add(Tag)

    if ASC:HasGameplayTag(Tag) then
        UE.UAbilitySystemBlueprintLibrary.RemoveLooseGameplayTags(self.actor, TagContainer, true)
    end
end

decorator.message_receiver()
function SkillKnock:OnBeginRide(vehicle)
    local Tag = UE.UHiGASLibrary.RequestGameplayTag("Ability.Skill.Immunity")
    local ASC = self.actor.AbilitySystemComponent

    local TagContainer = UE.FGameplayTagContainer()
    TagContainer.GameplayTags:Add(Tag)
    if not ASC:HasGameplayTag(Tag) then
        UE.UAbilitySystemBlueprintLibrary.AddLooseGameplayTags(self.actor, TagContainer, true)
    end
end

decorator.message_receiver()
function SkillKnock:OnEndRide(vehicle)
    local Tag = UE.UHiGASLibrary.RequestGameplayTag("Ability.Skill.Immunity")
    local ASC = self.actor.AbilitySystemComponent

    local TagContainer = UE.FGameplayTagContainer()
    TagContainer.GameplayTags:Add(Tag)

    if ASC:HasGameplayTag(Tag) then
        UE.UAbilitySystemBlueprintLibrary.RemoveLooseGameplayTags(self.actor, TagContainer, true)
    end
end

decorator.message_receiver()
function SkillKnock:OnBeginBeHugThrow()
    self.InKnockHandle = self.actor.BuffComponent:AddInKnockHitFlyBuff()

    -- Cancel all hit ga.
    self:CancelAllAbilities()
    UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.actor.Mesh, self.BeHugThrowMontage, 1.0)
end

decorator.message_receiver()
function SkillKnock:OnEndBeHugThrow()
    if self.InKnockHandle then
        self.actor.BuffComponent:RemoveInKnockHitFlyBuff(self.InKnockHandle)
    end

    self.actor:StopAnimMontage(self.BeHugThrowMontage)
end

decorator.message_receiver()
function SkillKnock:CancelAllAbilities()
    self.actor.AbilitySystemComponent:BP_CancelAbilities()
end

decorator.message_receiver()
function SkillKnock:OnHitEvent(Instigator, Causer, Hit)
    self:SendMessage("OnHit", Instigator, Causer, Hit)
end

---Handle Hit and defend, output behavior.
decorator.message_receiver()
function SkillKnock:HandleHitEvent(HitPayload)
    if self.actor:IsDead() then
        return
    end
    
    local HitTag = HitPayload.EventTag
    local KnockInfo = HitPayload.OptionalObject
    local HitTagsConfig = KnockInfo.HitTagsConfig
    G.log:debug(self.__TAG__, "HandleHitEvent with tag: %s", GetTagName(HitTag))

    -- MissionNdoe
    if self.actor.Event_MonsterHit then
        self.actor.Event_MonsterHit:Broadcast(HitTag)
    end

    -- Use KnockInfo (from GA montage) specified HitTagsConfig, if exists.
    if self:HandleHitAndDefendTags(HitTagsConfig, HitTag, HitPayload) then
        return
    end

    -- Use HitTagsConfig in hit component, default.
    if self:HandleHitAndDefendTags(self.HitTagsConfig, HitTag, HitPayload) then
        return
    end

    G.log:error(self.__TAG__, "Hit tag: %s not config in HitTagsConfig", GetTagName(HitTag))
    -- Not config hit tag mapping, send directly.
    local KnockInfoStruct = SkillUtils.KnockInfoObjectToReplicatedStruct(KnockInfo)
    if self.actor.HitComponent then
        self.actor.HitComponent:Multicast_SyncKnockInfo(KnockInfoStruct)
    end
    UE.UAbilitySystemBlueprintLibrary.SendGameplayEventToActor(self.actor, HitTag, HitPayload)
end

function SkillKnock:HandleHitAndDefendTags(HitTagsConfig, HitTag, HitPayload)
    local TagsConfig = HitTagsConfig:Find(HitTag)
    if TagsConfig then
        -- Assume DefendTags TagContainer already arranged from low to high defend level.
        local DefendTags = TagsConfig.DefendTags
        local BehaviorTags = TagsConfig.BehaviorTags
        local TagCount = UE.UBlueprintGameplayTagLibrary.GetNumGameplayTagsInContainer(DefendTags)
        assert(TagCount > 0, "DefendTags count must not be zero")
        assert(TagCount == BehaviorTags:Length(), "DefendTags length must same to BehaviorTags length")

        -- Check hit defend from high to low level.
        -- Default is lowest defend tag (Level-0)
        local DefendInd = 1
        for i = 1, TagCount do
            local CurDefendTag = DefendTags.GameplayTags[i]
            if self.actor:GetAbilitySystemComponent():HasGameplayTag(CurDefendTag) then
                DefendInd = i
            end
        end

        local CurBehaviorTags = BehaviorTags:Get(DefendInd)
        if CurBehaviorTags.GameplayTags:Length() > 0 then
            local KnockInfoStruct = SkillUtils.KnockInfoObjectToReplicatedStruct(HitPayload.OptionalObject)
            if self.actor.HitComponent then
                self.actor.HitComponent:Multicast_SyncKnockInfo(KnockInfoStruct)
            end
        end

        for j = 1, CurBehaviorTags.GameplayTags:Length() do
            local SendTag = CurBehaviorTags.GameplayTags:Get(j)
            G.log:debug(self.__TAG__, "HandleHitAndDefendTags send hit behavior tag: %s", GetTagName(SendTag))
            UE.UAbilitySystemBlueprintLibrary.SendGameplayEventToActor(self.actor, SendTag, HitPayload)
        end

        return true
    end

    return false
end

-- Used to sync KnockInfo, before send hit event.
-- TODO as FGameplayEventPayload cant not capsule KnockInfo(Previously use OptionalObject, but OptionalObject not replicated, or replicated not instantly)
function SkillKnock:Multicast_SyncKnockInfo_RPC(KnockInfo)
    self.KnockInfo = SkillUtils.KnockInfoReplicatedToNormal(KnockInfo)
end

return SkillKnock
