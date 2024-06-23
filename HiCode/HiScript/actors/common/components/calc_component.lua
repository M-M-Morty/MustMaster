require "UnLua"

local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local SkillUtils = require("common.skill_utils")
local TargetFilter = require("actors.common.TargetFilter")
local ComponentUtils = require("common.component_utils")


local CalcComponent = Component(ComponentBase)
local decorator = CalcComponent.decorator

function CalcComponent:Initialize(...)
    Super(CalcComponent).Initialize(self, ...)

    -- Mark whether current component has authority to calc.
    -- This will be true only on predict client or server.
    self.bCanCalc = false
end

function CalcComponent:Start()
    Super(CalcComponent).Start(self)
end

function CalcComponent:ReceiveBeginPlay()
    Super(CalcComponent).ReceiveBeginPlay(self)

    self.__TAG__ = string.format("CalcComponent(actor: %s, server: %s)", G.GetObjectName(self.actor), self.actor:IsServer())
end

decorator.message_receiver()
---@param Instigator AActor 施法者
---@param DamageCauser AActor 直接来源
---@param Spec TargetActorSpec 结算参数
---@param KnockInfo UD_KnockInfo 受击参数
---@param GameplayEffectsHandle TArray<FGameplayEffectSpecHandle> 施加给目标的 GE 列表
---@param HitSceneTargetConfig 击中场景配置
---@param SourceLocation FGameplayAbilityTargetingLocationInfo
---@param SelfGameplayEffectsHandle TArray<FGameplayEffectSpecHandle> 施加给自身的 GE 列表
function CalcComponent:InitCalcForHits(Instigator, DamageCauser, Spec, KnockInfo, GameplayEffectsHandle, HitSceneTargetConfig, SourceLocation, SelfGameplayEffectsHandle)
    G.log:debug(self.__TAG__, "InitCalcForHits")

    self.Instigator = Instigator
    self.DamageCauser = DamageCauser
    self.bCanCalc = true

    self.HitActors = UE.TArray(UE.AActor)
    self.HitComponents = UE.TArray(UE.UPrimitiveComponent)

    self.Spec = Spec
    self.bAOE = self.Spec.bAOE
    self.KnockInfo = KnockInfo
    self.GameplayEffectsHandle = GameplayEffectsHandle
    self.SelfGameplayEffectsHandle = SelfGameplayEffectsHandle
    self.HitSceneTargetConfig = HitSceneTargetConfig
    self.SourceLocation = SourceLocation

    if self.Spec.CalcCountLimit > 0 then
        self.bUseCalcCountLimit = true
        self.LeftCalcCount = self.Spec.CalcCountLimit
    else
        self.bUseCalcCountLimit = false
        self.LeftCalcCount = 0
    end

    if self.Spec.CalcTargetLimit > 0 then
        self.bUseCalcCountLimitPerFrame = true
    else
        self.bUseCalcCountLimitPerFrame = false
    end

    self.TargetFilter = TargetFilter.new(self.Instigator, self.Spec.CalcFilterType, self.Spec.CalcFilterIdentity)
end

decorator.message_receiver()
function CalcComponent:RegisterHitCallback(CallbackFunction, CallbackTarget)
    self.HitCallbackFunction = CallbackFunction
    self.HitCallbackTarget = CallbackTarget
end

decorator.message_receiver()
function CalcComponent:RegisterReachTargetLimitCallback(CallbackFunction, CallbackTarget)
    self.ReachTargetLimitCallbackFunction = CallbackFunction
    self.ReachTargetLimitCallbackTarget = CallbackTarget
end

decorator.message_receiver()
---TODO: Param TargetActor and bNeedBroadcast for broadcast target data to apply GE in blueprint.
---TargetActor bNeedBroadcast default to true.
---@param Hits TArray<FHitResult>
---@param TargetActor AGameplayAbilityTargetActor
---@param bNeedBroadcast boolean 是否需要广播消息
---@param bCanDefend boolean 是否可防御
---@param bOnDestroy boolean 是否为销毁时结算(抛射物)
function CalcComponent:ExecCalcForHits(Hits, TargetActor, bNeedBroadcast, bCanDefend, bOnDestroy)
    self.TargetActor = TargetActor
    self.bNeedBroadcast = bNeedBroadcast
    self.bCanDefend = bCanDefend
    self.bTriggeredFS = false
    if not self.TargetActor then
        self.bNeedBroadcast = false
    end
    self.bOnDestroy = bOnDestroy
    
    -- 结算目标过滤（包括结算次数限制、唯一性限制等）
    Hits = self:HandleCalcForHits(Hits)

    -- 根据对象类型处理受击效果.
    self:HandleHitByTypes(Hits)
end

function CalcComponent:HandleCalcForHits(Hits)
    local LeftCalcCountPerFrame = self.Spec.CalcTargetLimit
    local ResHits = UE.TArray(UE.FHitResult)
    local bHitDamageable = false
    -- TODO temp limit hit destructible count.
    local LeftDestructibleCount = 5

    -- 同一帧结算，击中同一个 actor 多个 components 时，只对 actor 结算一次.
    -- TODO 是否要区分 component 优先级？
    local HitActorsSameFrame = UE.TArray(UE.AActor)

    for Ind = 1, Hits:Length() do
        local CurHit = Hits:Get(Ind)
        local ObjectType = CurHit.Component:GetCollisionObjectType()
        local CurComp = CurHit.Component
        local CurActor = CurHit.HitObjectHandle.Actor

         G.log:debug(self.__TAG__, "HandleCalcForHits actor: %s, component: %s, objectType: %d",
                 G.GetObjectName(CurActor), G.GetObjectName(CurComp), ObjectType)
        if SkillUtils.IsObjectTypeDamageable(ObjectType) then
            -- 击中 Pawn 类型的对象.
            local bSkipCalc = self.Spec.CalcType == Enum.Enum_CalcType.Projectile and self.Spec.ProjectileLifetimeCalcType == Enum.Enum_ProjectileLifetimeCalcType.OnlyOnDestroy and not self.bOnDestroy
            -- Damageable actor if enabled bHitUnique, only hit actors once a time.
            if not bSkipCalc then
                if (not self.Spec.bHitUnique or self.HitActors:Find(CurActor) == 0) and HitActorsSameFrame:Find(CurActor) == 0 then
                    if self:IsDamageableCanCalc(CurActor, CurComp, LeftCalcCountPerFrame) then
                        if self.bUseCalcCountLimitPerFrame then
                            LeftCalcCountPerFrame = LeftCalcCountPerFrame - 1
                        end

                        ResHits:AddUnique(CurHit)
                        self.HitActors:AddUnique(CurActor)
                        HitActorsSameFrame:AddUnique(CurActor)

                        bHitDamageable = true
                    end
                end
            end
        elseif not self.Spec.bHitUnique or self.HitComponents:Find(CurComp) == 0 then
            -- Non-damageable actor can hit multi components of same actor one time, (large building .etc.)
            if ObjectType == UE.ECollisionChannel.ECC_Destructible then
                local Path = "/Game/Blueprints/TreeDestructionBase.TreeDestructionBase_C"
                local TreeDestructionClass = UE.UClass.Load(Path)
                if LeftDestructibleCount > 0 and CurComp:IsA(UE.UGeometryCollectionComponent) or
                        CurActor:IsA(UE.ABlastMultiplePiecesBuildingActor) or CurActor:IsA(UE.ABlastSimpleBuildingActor)  or
                        CurActor:IsA(TreeDestructionClass) or CurComp:IsA(UE.UStaticMeshComponent) or CurComp:IsA(UE.USkeletalMeshComponent) or
                        CurActor:IsA(UE.AStaticMeshActor) or CurActor:IsA(UE.AFieldSystemActor) then
                    local bCanDestruct = true
                    if CurActor._GetComponent then
                        local InteractCMP = CurActor:_GetComponent('InteractionComponent', true)
                        if InteractCMP then
                            bCanDestruct = InteractCMP:IsInteractable()
                        end
                    else
                        local ParentActor =CurActor:GetAttachParentActor()
                        if ParentActor and ParentActor._GetComponent then
                            local InteractCMP = ParentActor:_GetComponent('InteractionComponent', true)
                            if InteractCMP then
                                bCanDestruct = InteractCMP:IsInteractable()
                            end
                        end
                        
                    end
                    
                    if bCanDestruct then
                            LeftDestructibleCount = LeftDestructibleCount - 1
                            ResHits:AddUnique(CurHit)
                            self.HitComponents:AddUnique(CurComp)
                    end
                end     
            else
                if not ComponentUtils.ComponentUnHitable(CurComp) then
                    ResHits:AddUnique(CurHit)
                    self.HitComponents:AddUnique(CurComp)
                end
            end
        end
    end

    if self.bUseCalcCountLimit and bHitDamageable then
        self.LeftCalcCount = self.LeftCalcCount - 1
    end
    
    return ResHits
end

-- Handle hit on predict client or server.
function CalcComponent:HandleHitByTypes(Hits)
    local HitActors = UE.TArray(UE.AActor)
    local bServer = self.actor:IsServer()
    local bHitDamageable = false

    for Ind = 1, Hits:Length() do
        local CurHit = Hits:Get(Ind)
        local ObjectType = CurHit.Component:GetCollisionObjectType()
        local CurComp = CurHit.Component
        local CurActor = CurHit.HitObjectHandle.Actor

        if CurActor then
            HitActors:AddUnique(CurActor)
        end

         G.log:debug(self.__TAG__, "HandleHitByTypes actor: %s, component: %s, type: %s", G.GetObjectName(CurActor), G.GetObjectName(CurComp), ObjectType)

        if SkillUtils.IsObjectTypeDamageable(ObjectType) then
            -- TODO: HandleHitDamageable call at here not in HandleHitEffects, as CanKnock decided by calc side(predicted client or server), may not all sides can call.
            local bCanDamage, bCanKnock = self:CheckDamageAndKnock(self.Instigator, self.DamageCauser, CurHit)
            if bCanDamage then
                if not self.bNeedBroadcast then
                    -- 不广播结算目标
                    if bServer and not self.bClientPredicted then
                        -- 服务器结算(比如抛射物)，直接在这里结算
                        -- In client predict mode, both client and server apply ge on GASkillBase's OnValidDataCallback, no need do here.
                        -- Right now only used in projectile calculation on server, as Projectile damage calc should not in GA, as GA may be ended but projectile still can cause damage.
                        self:HandleHitDamageableApplyGE(CurHit)
                    end
                end
            end

            bHitDamageable = true
        end

        -- 对绑定的自身目标造成结算（比如被投掷的目标，碰撞时对自身造成伤害）
        local BindActor = self.actor.BindActor
        if self.Spec.bHitSelfOnCollision and BindActor then
            if self.HitActors:Find(BindActor) == 0 then
                G.log:debug(self.__TAG__, "Apply damage to self on collision")
                -- TODO: Only apply damage not knock to self.
                self:ApplyEffectToTarget(BindActor, CurHit, self.GameplayEffectsHandle)
                self.HitActors:AddUnique(BindActor)
            end
        end
    end

    -- 击中目标后，SourceActor 获得一些增益效果（比如普攻击中目标积攒能量）
    if bHitDamageable then
        self:ApplyEffectToSourceActor()
    end

    -- Handle knock time dilation.
    self.Instigator:SendMessage("HandleKnockTargets", HitActors, self.KnockInfo)

    -- FGameplayAbilityTargetDataHandle 限制单次最大 TargetData 数量为 32，配置 AOE
    if Hits:Length() > 32 and not self.bAOE then
        G.log:warn(self.__TAG__, "Too many targets but not set to AOE")
    end

    local TargetDataHandle
    if self.bAOE then
        TargetDataHandle = UE.UHiUtilsFunctionLibrary.AbilityAOETargetDataFromHitResultsWithKnockInfo(Hits, self.KnockInfo, self.SourceLocation)
    else
        TargetDataHandle = UE.UHiUtilsFunctionLibrary.AbilityTargetDataFromHitResultsWithKnockInfo(Hits, self.KnockInfo)
    end

    -- 分发受击目标，处理受击效果.
    if Hits:Length() > 0 then
        self:Multicast_HandleHitEffects(TargetDataHandle)
    end

    -- 广播目标给 GA，如果是客户端预测模式会发送到服务器做校验.
    if self.bNeedBroadcast then
        self.TargetActor:BroadcastTargetDataHandle(TargetDataHandle)
    end

    -- 结算次数用尽的回调.
    if self.bUseCalcCountLimit and self.LeftCalcCount <= 0 and self.ReachTargetLimitCallbackFunction then
        self.ReachTargetLimitCallbackFunction(self.ReachTargetLimitCallbackTarget)
    end
end

function CalcComponent:Multicast_HandleHitEffects_RPC(TargetDataHandle)
    local Count = UE.UAbilitySystemBlueprintLibrary.GetDataCountFromTargetData(TargetDataHandle)
    for Ind = 1, Count do
        local DataInd = Ind - 1
        if UE.UHiUtilsFunctionLibrary.IsSingleHitResult(TargetDataHandle, DataInd) then
            local Hits = UE.TArray(UE.FHitResult)
            local HitResult = UE.UAbilitySystemBlueprintLibrary.GetHitResultFromTargetData(TargetDataHandle, DataInd)
            Hits:Add(HitResult)
            self:HandleHitEffects(Hits, false)
        else
            -- AOE target data array.
            local Hits = UE.UHiUtilsFunctionLibrary.GetHitsFromTargetData(TargetDataHandle, DataInd)
            local SourceLocation = UE.FGameplayAbilityTargetingLocationInfo()
            UE.UHiUtilsFunctionLibrary.GetSourceLocationFromTargetData(TargetDataHandle, DataInd, SourceLocation)
            self:HandleHitEffects(Hits, true, SourceLocation)
        end
    end
end

-- Handle hit effects(受击表现), run on server and all client(include simulated)
function CalcComponent:HandleHitEffects(Hits, bAOE, SourceLocation)
    for Ind = 1, Hits:Length() do
        local CurHit = Hits:Get(Ind)
        local CurComp = CurHit.Component
        if CurComp then
            local ObjectType = CurComp:GetCollisionObjectType()
            local CurActor = CurComp:GetOwner()
            self:SendMessage("OnHitEvent", CurHit)
             G.log:debug(self.__TAG__, "HandleHitEffects actor: %s, component: %s, type: %s",
                     G.GetObjectName(CurActor), G.GetObjectName(CurComp), ObjectType)

            if CurActor and CurActor.SendMessage then
                CurActor:SendMessage("OnHitEvent", self.Instigator, self.DamageCauser, CurHit)
            end

            if ObjectType == UE.ECollisionChannel.ECC_Destructible then
                self:HandleHitDestructible(CurHit)
            elseif ObjectType == UE.ECollisionChannel.ECC_WorldStatic then
                self:HandleHitStaticMesh(CurHit)
            elseif ObjectType == UE.ECollisionChannel.ECC_WorldDynamic then
                self:HandleHitDynamicMesh(CurHit)
            end

            if CurActor and CurActor:GetComponentByClass(UE.UInstaDeformComponent) then
                local InstaDeformComponent = CurActor:GetComponentByClass(UE.UInstaDeformComponent)
                local Location = CurHit.Location
                local Direction = CurHit.Normal
                InstaDeformComponent:OnHitByLine(Location, Direction)
            end

            if self.HitCallbackFunction then
                self.HitCallbackFunction(self.HitCallbackTarget, ObjectType, CurHit)
            end
        end
    end
end

function CalcComponent:IsDamageableCanCalc(CurActor, CurComp, LeftCalcCountPerFrame)
    if self.bUseCalcCountLimit and self.LeftCalcCount <= 0 then
        return false
    end

    if self.bUseCalcCountLimitPerFrame and LeftCalcCountPerFrame <= 0 then
        return false
    end

    if not CurActor or not self.TargetFilter:FilterActor(CurActor)
            or ComponentUtils.ComponentUnHitable(CurComp) then
        return false
    end

    -- 金身无敌
    if CurActor.LifetimeComponent and CurActor.LifetimeComponent.IsGoldenBody then
        return false
    end

    -- 后台角色无敌
    if SkillUtils.IsBakAvatar(CurActor) then
        return false
    end

    return true
end


---Check whether CanDamage and CanKnock.
---@return (bCanDamage, bCanKnock)
function CalcComponent:CheckDamageAndKnock(Instigator, DamageCauser, HitResult)
    local CurActor = HitResult.Component:GetOwner()

    -- TODO implement in hit actors.
    -- Check defend.
    if self.bCanDefend and (UE.UHiGASLibrary.IsDefendFrontDamage(Instigator, CurActor) or UE.UHiGASLibrary.IsDefendBackDamage(Instigator, CurActor)) then
        return false, true
    end

    return true, true
end

function CalcComponent:HandleHitDamageableApplyGE(Hit)
    local Target = Hit.Component:GetOwner()
    Target:SendMessage("BeforeHandleHitDamageableApplyGE", self.actor)

    self:ApplyEffectToTarget(Target, Hit, self.GameplayEffectsHandle)
    self:ApplyKnockToTarget(Target, Hit)

    Target:SendMessage("AfterHandleHitDamageableApplyGE", self.actor)
end

function CalcComponent:ApplyEffectToTarget(Target, Hit, EffectsHandle)
    local TargetASC = UE.UAbilitySystemBlueprintLibrary.GetAbilitySystemComponent(Target)
    if TargetASC then
        for SpecInd = 1, EffectsHandle:Length() do
            local CurSpecHandle = EffectsHandle:Get(SpecInd)
            if UE.UHiGASLibrary.IsGameplayEffectSpecHandleValid(CurSpecHandle) then
                local ContextHandle = UE.UAbilitySystemBlueprintLibrary.GetEffectContext(CurSpecHandle)
                UE.UAbilitySystemBlueprintLibrary.EffectContextAddHitResult(ContextHandle, Hit, true)
                TargetASC:BP_ApplyGameplayEffectSpecToSelf(CurSpecHandle)
            end
        end
    end
end

function CalcComponent:ApplyEffectToSourceActor()
    if not self.actor.SourceActor or not UE.UKismetSystemLibrary.IsValid(self.actor.SourceActor) then
        return
    end

    -- TODO 增益效果暂时不区分自身和队伍中其他玩家，等后续出规则。
    local PlayerController = utils.GetPlayerController(self.actor.SourceActor)
    if PlayerController then
        for Ind = 1, PlayerController.SwitchPlayers:Length() do
            local Char = PlayerController.SwitchPlayers:Get(Ind)
            G.log:debug(self.__TAG__, "Apply self effects to source (and team) actor: %s", G.GetObjectName(Char))
            self:ApplyEffectToTarget(Char, UE.FHitResult(), self.SelfGameplayEffectsHandle)
        end
    end
end

function CalcComponent:ApplyKnockToTarget(Target, Hit)
    local TargetASC = UE.UAbilitySystemBlueprintLibrary.GetAbilitySystemComponent(Target)
    if TargetASC then
        local KnockInfo = self.KnockInfo
        if KnockInfo and KnockInfo.HitTags then
            local HitTags = KnockInfo.HitTags.GameplayTags

            for TagInd = 1, HitTags:Length() do
                local HitPayload = UE.FGameplayEventData()
                HitPayload.EventTag = HitTags:Get(TagInd)
                HitPayload.Instigator = self.Instigator
                HitPayload.Target = Target

                KnockInfo.Hit = Hit
                HitPayload.OptionalObject = KnockInfo
                Target:SendMessage("HandleHitEvent", HitPayload)
            end
        end
    end
end

function CalcComponent:HandleHitDestructible(HitResult)
    if not self.actor:IsServer() then
        self:ShowHitEffect(HitResult)
        return
    end

    --G.log:debug("CalcComponent", "HandleDamageDestructible hit config: %d, IsServer: %s", self.HitSceneTargetConfig.HitDestructibleResult, self.actor:IsServer())
    if self.HitSceneTargetConfig.HitDestructibleResult == Enum.Enum_HitDestructibleResult.Ignore then
        return

    elseif self.HitSceneTargetConfig.HitDestructibleResult == Enum.Enum_HitDestructibleResult.Break then
        local HitValue = self.HitSceneTargetConfig.HitDestructible_Value
        local HitActor = HitResult.HitObjectHandle.Actor

        local ParentActor = HitActor:GetAttachParentActor()
        local CheckActors = {HitActor, ParentActor}
        for _,TargetActor in ipairs(CheckActors) do
            if TargetActor and TargetActor.DestructComponent then
                TargetActor.DestructComponent:Hit(self.Instigator, self.DamageCauser, HitResult, HitValue)
            end
        end
    end
end

function CalcComponent:HandleHitStaticMesh(HitResult)
    if not self.bCanCalc then
        return
    end

    if self.actor.SourceActor then
        local HitTransform = UE.UKismetMathLibrary.MakeTransform(HitResult.Location, self.actor:K2_GetActorRotation(), UE.FVector(1, 1, 1))
        local bBlockingHit, bInitialOverlap, Time, Distance, Location, ImpactPoint,
                Normal, ImpactNormal, PhysMat, HitActor, HitComponent, HitBoneName, BoneName,
                HitItem, ElementIndex, FaceIndex, TraceStart, TraceEnd = UE.UGameplayStatics.BreakHitResult(HitResult)
        if HitActor and HitActor.TriggerInteractedItem then
            HitActor:TriggerInteractedItem(self.actor.SourceActor, 100, Location, true)
        end
        self.actor.SourceActor:SendMessage("HandleHitStaticMesh", HitResult, HitTransform)
    end

    if self.HitSceneTargetConfig.HitStaticMeshResult == Enum.Enum_HitStaticMeshResult.Ignore then
        return
    end

    if self.actor:IsClient() then
        self:HandleHitStaticMeshOnClient(HitResult)
    end
end

function CalcComponent:HandleHitDynamicMesh(HitResult)
    if not self.bCanCalc then
        return
    end

    if self.HitSceneTargetConfig.HitDynamicResult == Enum.Enum_HitDynamicMeshResult.Ignore then
        return
    elseif self.HitSceneTargetConfig.HitDynamicResult == Enum.Enum_HitDynamicMeshResult.HitFly then
        G.log:warn("skilllog", "HandleHitDynamicMesh hit fly result not implemented")
    end
end

function CalcComponent:ShowHitEffect(HitResult)
    local OwnerSpec = self.actor.Spec
    if OwnerSpec and OwnerSpec.HitEffect then
        local CurActor = HitResult.HitObjectHandle.Actor
        local Rotation = UE.UKismetMathLibrary.Conv_VectorToRotator(UE.UKismetMathLibrary.Subtract_VectorVector(HitResult.TraceEnd, HitResult.TraceStart))
        --UE.UKismetSystemLibrary.DrawDebugArrow(CurActor:GetWorld(), HitResult.TraceStart, HitResult.TraceEnd, 10, UE.FLinearColor(0, 1, 0), 10, 2)
        Rotation = UE.UKismetMathLibrary.MakeRotFromZ(UE.UKismetMathLibrary.Subtract_VectorVector(HitResult.TraceEnd, HitResult.TraceStart))
        UE.UNiagaraFunctionLibrary.SpawnSystemAtLocation(CurActor:GetWorld(), OwnerSpec.HitEffect, HitResult.ImpactPoint, Rotation)
    end
end

function CalcComponent:GetActorsFromHitResults(HitResults)
    local HitActors = UE.TArray(UE.AActor)
    for Ind = 1, HitResults:Length() do
        local CurHit = HitResults:Get(Ind)
        local CurActor = CurHit.Component:GetOwner()
        HitActors:AddUnique(CurActor)
    end

    return HitActors
end

--[[
Run on client
]]
function CalcComponent:HandleHitStaticMeshOnClient(HitResult)
    local CurComp = HitResult.Component
    local CompClass = UE.UGameplayStatics.GetClass(CurComp)
    G.log:debug("hycoldrain", "component class %s", tostring(CompClass))
    if UE.UKismetMathLibrary.ClassIsChildOf(CompClass, UE.UProceduralMeshComponent) then
        self:SliceProceduralMeshOnClient(CurComp, HitResult.Location)
    end
end

function CalcComponent:SliceProceduralMeshOnClient(ProceduralMesh, Location)
    G.log:debug("hycoldrain", "CalcClientComponent:SliceProceduralMesh")
    local PrimComp = self.TargetActor.KnockInfo.PrimComp
    if PrimComp then
        local SweepDir = PrimComp:GetForwardVector()
        local CurActor = ProceduralMesh:GetOwner()
        if CurActor.Cut then
            CurActor:Cut(Location, SweepDir, ProceduralMesh)
        end
    end
end

--[[
Run on server
]]
-- Used in client predict calculation, in this case client TargetActor generate hits, server validate hits and handle replication.
-- Server receive client hits data in TargetActor's OnTargetDataReceived, then call this to handle replication.
decorator.message_receiver()
function CalcComponent:HandleCalcFromClientPredictOnServer(Hits)
    --G.log:debug("CalcComponent", "HandleCalcFromClientPredictOnServer with hits count: %d", Hits:Length())
    self.bNeedBroadcast = false
    self.bClientPredicted = true

    -- Handle damage according object types.
    self:HandleHitByTypes(Hits)
end

function CalcComponent:Stop()
    Super(CalcComponent).Stop(self)
end

return CalcComponent
