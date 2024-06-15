local G = require("G")
local SkillUtils = require("common.skill_utils")
local CustomMovementModes = require("common.event_const").CustomMovementModes
local StateConflictData = require("common.data.state_conflict_data")
local GABase = require("skill.ability.GABase")

local GASkillBase = Class(GABase)
local decorator = GASkillBase.decorator

GASkillBase.__replicates = {
    __TAG__ = "",
    --Projectiles = {}
}

decorator.dds_function()
function GASkillBase:OnCancelled()
    Super(GASkillBase).OnCancelled(self)
    self.bCanceled = true
end
UE.DistributedDSLua.RegisterFunction("OnCancelled", GASkillBase.OnCancelled)

function GASkillBase:K2_PostTransfer()
    --self.__TAG__ = string.format("(%s, server: %s)", G.GetObjectName(self), self:IsServer())
    self.Projectiles = {}
    self.OwnerActor = self:GetAvatarActorFromActorInfo()
end

function GABase:K2_ActivateAbility()
    self:OnActivateAbility()

    G.log:debug(self.__TAG__, "K2_ActivateAbility")

    if not self:K2_CommitAbility() then
        self:K2_EndAbility()
        return
    end
    
    self:SetOwnerBoneServerUpdate(true)

    self:HandleActivateAbility()
end

function GASkillBase:HandleActivateAbility()
    self.Projectiles = {}
    self.ApplyToSelfMap = {}

    -- Check whether enable motion warp (used in normal combo .etc.)
    -- Normal attack default enable motion warp.
    if self.WarpTargetName and (self.bEnableWarp or SkillUtils.IsCommonNormal(self.SkillType)) then
        self:HandleMotionWarp()
    end

    -- Clear Velocity
    self.OwnerActor:ClearVelocityAndAcceleration()

    self:HandleMovementAndStateWhenActivate()

    if self.bPlayMontageForCombo then
        self:HandlePlayMontageForCombo()
    else
        self:HandlePlayMontage()
    end

    -- Handle combo tail.
    self:HandleComboTail()

    -- Handle for exec calculation.
    self:HandleCalc()

    -- Handle apply ge to self calc event.
    self:HandleApplyToSelfCalc()

    -- Handle apply ge to target calc event.
    self:HandleApplyToTargetCalc()
end

function GASkillBase:HandleMovementAndStateWhenActivate()
    if not self.bMovable then
        if self.bMoveOnGround then
            if self.OwnerActor:IsOnFloor() then
                self.OwnerActor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Walking)
            else
                self.OwnerActor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Falling)
            end
        else
            -- TODO Must set movement mode to custom skill mode, otherwise walking mode root motion on axis z ignored.
            self.OwnerActor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Custom, CustomMovementModes.Skill)
        end
    end

    -- Tag owner enter skill state. Needs after SetMovementMode
    self.OwnerActor.CharacterStateManager:SetSkillState(true, self.IdleActingBehavior)
    if self.CameraBehavior ~= Enum.Enum_SkillCameraState.None then
        self.OwnerActor.CharacterStateManager:SetCameraBehaviorState(self.CameraBehavior)
    end    
end

function GASkillBase:HandlePlayMontageForCombo()
    if self.MontageToPlay then
        -- BOSS连招要求上一个技能Cancel之后动画继续播放，不能用CreatePlayMontageAndWaitProxy
        local OwnerActor = self:GetAvatarActorFromActorInfo()
        G.log:debug("yj", "GASkillBase_Monster:HandlePlayMontageForCombo %s", self.ComboBeginSection)
        self.PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(OwnerActor.Mesh, self.MontageToPlay, 1.0, 0.0, self.ComboBeginSection)
        self.PlayMontageCallbackProxy.OnCompleted:Add(self, self.OnMontageCompleted)
        self.PlayMontageCallbackProxy.OnInterrupted:Add(self, self.OnMontageInterrupted)
        self.PlayMontageCallbackProxy.OnBlendOut:Add(self, self.OnMontageBlendOut)
    end
end

function GASkillBase:HandleMotionWarp()
    if self:IsServer() then
        return
    end

    local SkillTarget, _, _, SkillTargetComponent = self:GetSkillTarget()
    if not SkillTarget then
        return
    end

    local CapsuleHalfHeight = self.OwnerActor.CapsuleComponent:GetScaledCapsuleHalfHeight()
    local bNeedWarpZ = true

    -- 检查施法者朝向前方，攻击范围内是否能打中目标。若可以，不做 Z 方向修正。
    local StartLocation = self.OwnerActor:K2_GetActorLocation()
    local EndLocation = StartLocation + self.OwnerActor:K2_GetRootComponent():GetForwardVector() * self.SkillRange
    local SweepRadius = CapsuleHalfHeight / 2
    local ObjectTypes = UE.TArray(UE.EObjectTypeQuery)
    ObjectTypes:Add(UE.EObjectTypeQuery.Pawn)
    ObjectTypes:Add(UE.EObjectTypeQuery.PhysicsBody)
    local ActorsToIgnore = UE.TArray(UE.AActor)
    ActorsToIgnore:Add(self.OwnerActor)
    local OutHits = UE.TArray(UE.FHitResult)
    UE.UKismetSystemLibrary.SphereTraceMultiForObjects(self.OwnerActor:GetWorld(), StartLocation, EndLocation, SweepRadius,
            ObjectTypes, true, ActorsToIgnore, UE.EDrawDebugTrace.None, OutHits, true, UE.FLinearColor(1, 0, 0), UE.FLinearColor(0, 1, 0), 30)
    if OutHits:Length() > 0 then
        bNeedWarpZ = false
    end

    G.log:debug("GASkillBase", "GA: %s enable motion warp: %s to target", G.GetDisplayName(self), tostring(self.WarpTargetName))
    local OwnerLocation = self.OwnerActor:K2_GetActorLocation()
    local _, TargetLocation = utils.GetTargetNearestDistance(OwnerLocation, SkillTarget, SkillTargetComponent)
    local OwnerTransform = self.OwnerActor:GetTransform()
    local WarpTransform = OwnerTransform
    local bNeedWarp = false
    local WarpLocation = UE.FVector(OwnerLocation.X, OwnerLocation.Y, OwnerLocation.Z)
    local TargetDis = UE.UKismetMathLibrary.Vector_Distance2D(TargetLocation, OwnerLocation)
    if TargetDis > self.SkillRange then
        local DeltaDis = TargetDis - self.SkillRange
        if DeltaDis > self.WarpMaxDis then
            DeltaDis = self.WarpMaxDis
        end

        -- Warp to skill range.
        if DeltaDis > 0 then
            WarpLocation = OwnerLocation + (TargetLocation - OwnerLocation) * DeltaDis / TargetDis
            WarpLocation.Z = OwnerLocation.Z
            bNeedWarp = true
        end
    end

    -- Warp z to NearestLocation.Z +/- HalfHeight, ensure we can hit the target component.
    local AttackOffsetFromCenter = CapsuleHalfHeight / 2
    if bNeedWarpZ and ((WarpLocation.Z > TargetLocation.Z and WarpLocation.Z - TargetLocation.Z > self.MinEnableWarpZDistanceDiff - AttackOffsetFromCenter)
        or (WarpLocation.Z < TargetLocation.Z and TargetLocation.Z - WarpLocation.Z > self.MinEnableWarpZDistanceDiff)) then
        if WarpLocation.Z > TargetLocation.Z then
            WarpLocation.Z = TargetLocation.Z - self.OwnerActor.CapsuleComponent:GetScaledCapsuleHalfHeight()
        else
            WarpLocation.Z = TargetLocation.Z + self.OwnerActor.CapsuleComponent:GetScaledCapsuleHalfHeight()
        end

        local WarpDeltaZ = WarpLocation.Z - OwnerLocation.Z
        if math.abs(WarpDeltaZ) > self.MaxWarpZDistance then
            WarpDeltaZ = WarpDeltaZ / math.abs(WarpDeltaZ) * self.MaxWarpZDistance
        end

        WarpLocation.Z = math.max(OwnerLocation.Z + WarpDeltaZ - self.OwnerActor.CapsuleComponent:GetScaledCapsuleHalfHeight(), 0)
        bNeedWarp = true
    end

    -- Attention HiSimpleWarp use capsule bottom position to compare.
    if bNeedWarp then
        WarpLocation.Z = WarpLocation.Z - CapsuleHalfHeight
        WarpTransform = UE.FTransform(OwnerTransform.Rotation, WarpLocation, OwnerTransform.Scale3D)
    else
        WarpTransform = UE.FTransform(OwnerTransform.Rotation, UE.FVector(OwnerLocation.X, OwnerLocation.Y, OwnerLocation.Z - CapsuleHalfHeight), OwnerTransform.Scale3D)
    end

    self.OwnerActor.MotionWarpingModifyComponent:WarpTransform(self.WarpTargetName, WarpTransform)
    self.OwnerActor.MotionWarpingModifyComponent:Server_SetWarpTarget(self.WarpTargetName, WarpTransform)
end

function GASkillBase:ClearMotionWarp()
    if self:IsServer() then
        return
    end

    local MotionWarpingModifyComponent = self.OwnerActor.MotionWarpingModifyComponent

	if MotionWarpingModifyComponent then
		MotionWarpingModifyComponent:ClearWarpTarget(self.WarpTargetName)
		MotionWarpingModifyComponent:Server_ClearWarpTarget(self.WarpTargetName)
	end
end

function GASkillBase:HandleCalc()
    G.log:debug(self.__TAG__, "GASkillBase %s HandleCalc, IsServer: %s.", G.GetDisplayName(self), self:IsServer())

    local WaitCalcTask = UE.UAbilityTask_WaitGameplayEvent.WaitGameplayEvent(self, self.CalcPrefixTag, nil, false, false)
    WaitCalcTask.EventReceived:Add(self, self.OnCalcEvent)
    WaitCalcTask:ReadyForActivation()
    self:AddTaskRefer(WaitCalcTask)
end

function GASkillBase:HandleApplyToSelfCalc()
    local WaitATSCalcTask = UE.UAbilityTask_WaitGameplayEvent.WaitGameplayEvent(self, self.ApplyToSelfCalcPrefixTag, nil, false, false)
    WaitATSCalcTask.EventReceived:Add(self, self.OnApplyToSelfCalcEvent)
    WaitATSCalcTask:ReadyForActivation()
    self:AddTaskRefer(WaitATSCalcTask)
end

function GASkillBase:HandleApplyToTargetCalc()
    local WaitATTCalcTask = UE.UAbilityTask_WaitGameplayEvent.WaitGameplayEvent(self, self.ApplyToTargetCalcPrefixTag, nil, false, false)
    WaitATTCalcTask.EventReceived:Add(self, self.OnApplyToTargetCalcEvent)
    WaitATTCalcTask:ReadyForActivation()
    self:AddTaskRefer(WaitATTCalcTask)
end

decorator.dds_function()
function GASkillBase:OnCalcEvent(Payload)
    local EventTag = Payload.EventTag
    local KnockInfo = Payload.OptionalObject

    -- TODO 打开预测
    if not self:K2_HasAuthority() then
        return
    end

    G.log:debug(self.__TAG__, "OnCalcEvent %s, bIsBindType: %s, bBind: %s", GetTagName(EventTag), KnockInfo.bIsBindType, KnockInfo.bBind)
    if KnockInfo.bIsBindType and not KnockInfo.bBind then
        self:OnUnBindProjectile(EventTag)
        return
    end

    local bFounded, EffectContainer, Specs = self:MakeSpecsByTag(EventTag, self:GetAbilityLevel())
    local bFoundedOfSelf, _, SelfSpecs = self:MakeSelfSpecsByTag(EventTag, self:GetAbilityLevel())
    if not bFounded and not bFoundedOfSelf then
        G.log:warn(self.__TAG__, "OnCalcEvent not found EffectContainer for tag: %s", GetTagName(EventTag))
        return
    end

    if not UE.UKismetSystemLibrary.IsValidClass(EffectContainer.TargetType) then
        G.log:error(self.__TAG__, "OnCalcEvent TargetActor type is invalid for tag: %s", GetTagName(EventTag))
        return
    end

    -- Capsule calc event tag to GE spec for index skill base damage.
    -- TODO here just add to Asset tag.
    for Ind = 1, Specs:Length() do
        UE.UAbilitySystemBlueprintLibrary.AddAssetTag(Specs:Get(Ind), EventTag)
    end

    local ExtraData = {
        GameplayEffectsHandle = Specs,
        SelfGameplayEffectsHandle = SelfSpecs,
        ApplicationTag = EventTag,
        KnockInfo = KnockInfo,
    }
    local OwnerActor = self:GetAvatarActorFromActorInfo()
    local TargetActor = GameAPI.SpawnActor(OwnerActor:GetWorld(), EffectContainer.TargetType, OwnerActor:GetTransform(), UE.FActorSpawnParameters(), ExtraData)

    local ReplaceData = Payload.OptionalObject2
    if ReplaceData and ReplaceData.bReplace then
        TargetActor.Spec.StartPosBoneName = ReplaceData.StartPosBoneName
        TargetActor.Spec.StartRotOffset = ReplaceData.StartRotOffset
        TargetActor.ReboundRotOffset = ReplaceData.ReboundRotOffset
    end

    local WaitTargetDataTask = UE.UAbilityTask_WaitTargetData.WaitTargetDataUsingActor(self, "", EffectContainer.ConfirmationType, TargetActor)
    WaitTargetDataTask.ValidData:Add(self, self.OnValidDataCallback)
    WaitTargetDataTask:ReadyForActivation()
    self:AddTaskRefer(WaitTargetDataTask)
end
UE.DistributedDSLua.RegisterFunction("OnCalcEvent", GASkillBase.OnCalcEvent)

decorator.dds_function()
function GASkillBase:OnApplyToSelfCalcEvent(Payload)
    if not self:CanCalc()  then
        return
    end

    local EventTag = Payload.EventTag
    local bFounded, _, Specs = self:MakeSpecsByTag(EventTag, self:GetAbilityLevel())
    if not bFounded then
        G.log:error(self.__TAG__, "GASkillBase OnApplyToSelfCalcEvent not found EffectContainer for tag: %s", UE.UBlueprintGameplayTagLibrary.GetTagName(EventTag))
        return
    end

    for Ind = 1, Specs:Length() do
        local CurSpec = Specs:Get(Ind)
        self:K2_ApplyGameplayEffectSpecToOwner(CurSpec)
    end
end
UE.DistributedDSLua.RegisterFunction("OnApplyToSelfCalcEvent", GASkillBase.OnApplyToSelfCalcEvent)

function GASkillBase:MakeSpecsByTag(EventTag, Level)
    local EffectContainer = UE.FHiGameplayEffectContainer()
    local Specs = UE.TArray(UE.FGameplayEffectSpecHandle)
    local bFounded = self:MakeEffectContainerSpecByTag(EventTag, Level, EffectContainer, Specs)
    if not bFounded then
        G.log:error(self.__TAG__, "MakeSpecsByTag not found EffectContainer for tag: %s", UE.UBlueprintGameplayTagLibrary.GetTagName(EventTag))
        return false, nil, nil
    end

    -- Capsule calc event tag to GE spec for index skill base damage.
    -- TODO here just add to Asset tag.
    for Ind = 1, Specs:Length() do
        UE.UAbilitySystemBlueprintLibrary.AddAssetTag(Specs:Get(Ind), EventTag)
    end

    return true, EffectContainer, Specs
end

function GASkillBase:MakeSelfSpecsByTag(EventTag, Level)
    local EffectContainer = UE.FHiGameplayEffectContainer()
    local Specs = UE.TArray(UE.FGameplayEffectSpecHandle)
    local bFounded = self:MakeEffectContainerSpecByTagOfSelf(EventTag, self:GetAbilityLevel(), EffectContainer, Specs)
    if not bFounded then
        G.log:error(self.__TAG__, "MakeSelfSpecsByTag not found EffectContainer for tag: %s", GetTagName(EventTag))
        return false, nil, nil
    end

    -- Capsule calc event tag to GE spec for index skill base damage.
    -- TODO here just add to Asset tag.
    for Ind = 1, Specs:Length() do
        UE.UAbilitySystemBlueprintLibrary.AddAssetTag(Specs:Get(Ind), EventTag)
    end

    return true, EffectContainer, Specs
end

decorator.dds_function()
function GASkillBase:OnApplyToTargetCalcEvent(Payload)
    if not self:CanCalc() then
        return
    end

    local PresetTarget = self:GetSkillTarget()
    if not PresetTarget then
        G.log:warn(self.__TAG__, "OnApplyToTargetCalcEvent not preset target found.")
        return
    end

    local EventTag = Payload.EventTag
    local bFounded, _, Specs = self:MakeSpecsByTag(EventTag, self:GetAbilityLevel())
    if not bFounded then
        G.log:error(self.__TAG__, "GASkillBase OnApplyToTargetCalcEvent not found EffectContainer for tag: %s", UE.UBlueprintGameplayTagLibrary.GetTagName(EventTag))
        return
    end

    G.log:debug(self.__TAG__, "Apply to target calc: %s", GetTagName(EventTag))
    local TargetData = UE.UAbilitySystemBlueprintLibrary.AbilityTargetDataFromActor(PresetTarget)
    self:ApplyEffectContainerSpec(Specs, TargetData)
end
UE.DistributedDSLua.RegisterFunction("OnApplyToTargetCalcEvent", GASkillBase.OnApplyToTargetCalcEvent)

function GASkillBase:OnValidDataCallback(TargetDataHandle, EventTag)
    G.log:debug(self.__TAG__, "OnValidDataCallback, tag: %s", GetTagName(EventTag))

    -- Apply ge to target.
    self:ApplyGEToTargetData(TargetDataHandle, EventTag)

    if self:IsServer() then
        local Count = UE.UAbilitySystemBlueprintLibrary.GetDataCountFromTargetData(TargetDataHandle)
        if Count > 0 then
            -- TODO use first KnockInfo, other elems KnockInfo maybe nil.
            local KnockInfo = UE.UHiUtilsFunctionLibrary.GetKnockInfoFromTargetData(TargetDataHandle, 0)
            for Ind = 1, Count do
                local DataInd = Ind - 1

                if UE.UHiUtilsFunctionLibrary.IsSingleHitResult(TargetDataHandle, DataInd) then
                    local Hit = UE.UAbilitySystemBlueprintLibrary.GetHitResultFromTargetData(TargetDataHandle, DataInd)
                    self:SendHitToActor(Hit.HitObjectHandle.Actor, Hit, KnockInfo)
                else
                    -- AOE target data array.
                    local Hits = UE.UHiUtilsFunctionLibrary.GetHitsFromTargetData(TargetDataHandle, DataInd)
                    for Ind = 1, Hits:Length() do
                        local Hit = Hits:Get(Ind)
                        self:SendHitToActor(Hit.HitObjectHandle.Actor, Hit, KnockInfo)
                    end
                end
            end
        end
    end
end
UE.DistributedDSLua.RegisterFunction("OnValidDataCallback", GASkillBase.OnValidDataCallback)

function GASkillBase:SendHitToActor(Target, Hit, KnockInfo)
    if Target and Target.AbilitySystemComponent and KnockInfo and KnockInfo.HitTags then
        local HitTags = KnockInfo.HitTags.GameplayTags

        for TagInd = 1, HitTags:Length() do
            local HitPayload = UE.FGameplayEventData()
            HitPayload.EventTag = HitTags:Get(TagInd)
            HitPayload.Instigator = self.OwnerActor
            HitPayload.Target = Target

            -- Capsule all data into KnockInfo
            -- TODO KnockInfo capsule in OptionalObject cant replicate, as it was dynamic created in calculation AnimNotify or AnimNotifyState.
            -- Right now KnockInfo will write to GameplayAbilitySpec UserData field in c++.
            KnockInfo.Hit = Hit
            HitPayload.OptionalObject = KnockInfo
            Target:SendMessage("HandleHitEvent", HitPayload)
        end
    end
end

function GASkillBase:OnHitTarget(ObjectType, Hit, ApplicationTag)
end

function GASkillBase:ApplyGEToTargetData(Data, EventTag)
    local bFounded, _, Specs = self:MakeSpecsByTag(EventTag, self:GetAbilityLevel())
    if not bFounded then
        G.log:error(self.__TAG__, "GASkillBase ApplyGEToTargetData not found EffectContainer for tag: %s", UE.UBlueprintGameplayTagLibrary.GetTagName(EventTag))
        return
    end

    if Specs:Length() == 0 then
        return
    end

    self:ApplyEffectContainerSpec(Specs, Data)
end

function GASkillBase:ApplyGEToSelfOnHitTargets(EventTag)
    local ASC = G.GetHiAbilitySystemComponent(self.OwnerActor)
    if not ASC then
        G.log:error(self.__TAG__, "ApplyGEToSelf failed: not get asc")
        return
    end

    local bFounded, _, Specs = self:MakeSelfSpecsByTag(EventTag, self:GetAbilityLevel())
    if not bFounded then
        G.log:error(self.__TAG__, "ApplyGEToSelf not found EffectContainer for tag: %s", GetTagName(EventTag))
        return
    end

    if Specs:Length() == 0 then
        return
    end

    -- Only apply once for same event tag calculation.
    -- EventTag is temp variable, different gameplay tag may share same UserData, so use tag name as key
    if self.ApplyToSelfMap[GetTagName(EventTag)] then
        return
    end
    self.ApplyToSelfMap[GetTagName(EventTag)] = true

    G.log:debug(self.__TAG__, "ApplyGEToSelfOnHitTargets tag: %s", GetTagName(EventTag))
    for SpecInd = 1, Specs:Length() do
        local CurSpecHandle = Specs:Get(SpecInd)
        if UE.UHiGASLibrary.IsGameplayEffectSpecHandleValid(CurSpecHandle) then
            ASC:BP_ApplyGameplayEffectSpecToSelf(CurSpecHandle)
        end
    end
end

function GASkillBase:CanCalc()
    if self:K2_HasAuthority() then
        return true
    end

    local ASC = self:GetAbilitySystemComponentFromActorInfo()
    if not ASC then
        return false
    end

    return ASC:CanClientPredict()
end

function GASkillBase:OnBindProjectile(EventTag, ProjectileActor)
    local TagStr = UE.UBlueprintGameplayTagLibrary.GetTagName(EventTag)
    G.log:debug(self.__TAG__, "OnBindProjectile for tag: %s, projectile: %s, IsServer: %s", TagStr,
            G.GetDisplayName(ProjectileActor), self:IsServer())
    self.Projectiles[TagStr] = ProjectileActor
end

function GASkillBase:OnUnBindProjectile(EventTag)
    local TagStr = UE.UBlueprintGameplayTagLibrary.GetTagName(EventTag)
    local CurProjectile = self.Projectiles[TagStr]
    if CurProjectile then
        G.log:debug(self.__TAG__, "OnUnBindProjectile for tag: %s, projectile: %s, IsServer: %s", TagStr, G.GetDisplayName(CurProjectile), self:IsServer())
        CurProjectile:DestroySelf()
    end
    self.Projectiles[TagStr] = nil
end

function GASkillBase:HandleComboTailState(Payload)
    Super(GASkillBase).HandleComboTailState(self, Payload)

    if not self:IsClient() then
        return
    end

    local EventTag = Payload.EventTag
    local bNotMovable = UE.UBlueprintGameplayTagLibrary.EqualEqual_GameplayTag(EventTag, self.ComboTailNotMovableTag)

    -- Attention: ComboTail will end State_Skill, but no need callback to invoke BreakSkill, otherwise skill tail animation will be interrupted.
    -- 不应在这里做技能类型判断，应该放到子类中。但现在蓝图子类的继承实在太乱，需要整理！
    if self:IsNormalSkill() then
        self.OwnerActor:SendMessage("EndState", StateConflictData.State_SkillNormal, false)
    elseif self:IsSuperSkill() then
        self.OwnerActor:SendMessage("EndState", StateConflictData.State_SuperSkill, false)
    else
        self.OwnerActor:SendMessage("EndState", StateConflictData.State_Skill, false)
    end

    if bNotMovable then
        self.OwnerActor:SendMessage("EnterState", StateConflictData.State_SkillTail_NotMovable)
    else
        self.OwnerActor:SendMessage("EndState", StateConflictData.State_SkillTail_NotMovable)
        self.OwnerActor:SendMessage("EnterState", StateConflictData.State_SkillTail)
    end
end

function GASkillBase:IsNormalSkill()
    return SkillUtils.IsNormalSkill(self.SkillType) or SkillUtils.IsInAirNormalSkill(self.SkillType)
end

function GASkillBase:IsSuperSkill()
    return SkillUtils.IsSuperSkill(self.SkillType)
end

--[[
    Buff ability
    换技能区分下两种情况：
    1. 同一个技能，在不同状态下会有不同的表现（GA），并且可能不同状态下的 GA 有交互使用这里的 BuffAbilityTagMap 和 BuffTag 来实现.
    2. 同一个按键，不同状态下释放不同技能，用换技能的 buff 基类 GE_Buff_ModifySkillMap 来实现.
]]
--- Check whether ability can trigger buff ability.
---@return boolean, number, FGameplayTag bCanTrigger, BuffAbilityID, BuffTag
function GASkillBase:CanTriggerBuffAbility(CheckTag)
    local OwnerActor = self:GetAvatarActorFromActorInfo()
    local ASC = G.GetHiAbilitySystemComponent(OwnerActor)


    if not self.BuffAbilityTagMap then
        return false, -1, nil
    end

    local TagKeys = self.BuffAbilityTagMap:Keys()
    for Ind = 1, TagKeys:Length() do
        local CurTag = TagKeys:Get(Ind)

        if (not CheckTag or UE.UBlueprintGameplayTagLibrary.EqualEqual_GameplayTag(CurTag, CheckTag)) and ASC:HasGameplayTag(CurTag) then
            return true, self.BuffAbilityTagMap:Find(CurTag), CurTag
        end
    end

    return false, -1, nil
end

--- Get BuffTag corresponding GameplayEffect remaining time and duration.
function GASkillBase:GetTriggerBuffAbilityRemainingAndDuration(BuffTag)
    local OwnerActor = self:GetAvatarActorFromActorInfo()
    local ASC = G.GetHiAbilitySystemComponent(OwnerActor)
    local QueryTagContainer = UE.FGameplayTagContainer()
    QueryTagContainer.GameplayTags:Add(BuffTag)
    local EffectHandleList = ASC:GetActiveEffectsWithAllTags(QueryTagContainer)
    -- TODO Just return the first one right now.
    for Ind = 1, EffectHandleList:Length() do
        local EffectHandle = EffectHandleList:Get(Ind)
        if EffectHandle.Handle ~= -1 then
            local Remaining, Duration = ASC:GetActiveGameplayEffectRemainingAndDuration(EffectHandle)
            return Remaining, Duration
        end
    end

    return -1, -1
end

--[[
    End ability
    ]]
function GASkillBase:HandleEndAbility(bWasCancelled)
    Super(GASkillBase).HandleEndAbility(self, bWasCancelled)

    self:ClearMotionWarp()

    for _, CurProjectile in pairs(self.Projectiles) do
        if CurProjectile then
            G.log:debug("GASkillBase", "OnAbilityEnded unbind projectile: %s, IsServer: %s", G.GetObjectName(CurProjectile), self:IsServer())
            CurProjectile:DestroySelf()
        end
    end

    if self.PlayMontageCallbackProxy then
        self.PlayMontageCallbackProxy.OnCompleted:Remove(self, self.OnMontageCompleted)
        self.PlayMontageCallbackProxy.OnInterrupted:Remove(self, self.OnMontageInterrupted)
        self.PlayMontageCallbackProxy.OnBlendOut:Remove(self, self.OnMontageBlendOut)
    end

end

function GASkillBase:HandleMovementAndStateWhenEnd(bWasCancelled)
    -- Make sure if skill end up on floor, character can receive OnLand callback.
    if not self.bMovable and not self.bMoveOnGround then
        if self.OwnerActor:IsOnFloor() then
            self.OwnerActor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Walking)
        else
            if self:InSkillMovementMode() then
                -- 防止和零重力的 fly movement mode 冲突
                self.OwnerActor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Falling)
            end
        end
    end

    -- Reset character state, Needs after SetMovementMode
    self.OwnerActor.CharacterStateManager:SetSkillState(false, self.IdleActingBehavior)
    self.OwnerActor.CharacterStateManager:SetCameraBehaviorState(Enum.Enum_SkillCameraState.None)
end

function GASkillBase:InSkillMovementMode()
    local CharacterMovement = self.OwnerActor.CharacterMovement
    return CharacterMovement.MovementMode == UE.EMovementMode.MOVE_Custom and CharacterMovement.CustomMovementMode == CustomMovementModes.Skill
end

 UE.DistributedDSLua.RegisterCustomClass("GASkillBase", GASkillBase)

return GASkillBase
