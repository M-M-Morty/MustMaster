require "UnLua"

local G = require("G")
local HiCollisionLibrary = require("common.HiCollisionLibrary")

local Actor = require("common.actor")

local Projectile = Class(Actor)

function Projectile:Initialize(...)
    Super(Projectile).Initialize(self, ...)

    self.FrameCount = 0
    self.bDestroying = false
    self.OverlapActors = {}
    self.bInited = false

    self.__TAG__ = "Projectile"
end

function Projectile:ReceiveBeginPlay()
    self.__TAG__ = string.format("Projectile(%s, server: %s)", G.GetObjectName(self), self:IsServer())
    G.log:debug(self.__TAG__, "ReceiveBeginPlay")

    self:Init()

    self:SendMessage("InitCalcForHits", self.SourceActor, self,
        self.Spec, self.KnockInfo, self.GameplayEffectsHandle, self.HitSceneTargetConfig, nil, self.SelfGameplayEffectsHandle)
    self:SendMessage("RegisterHitCallback", self.HitCallback, self)
    self:SendMessage("RegisterReachTargetLimitCallback", self.ReachTargetLimitCallback, self)

    local TimeDilationActor = HiBlueprintFunctionLibrary.GetTimeDilationActor(self)
    if TimeDilationActor and self.SourceActor then
        TimeDilationActor:AddCustomTimeDilationObject(self.SourceActor, self)
    end

    if (self.Spec.MoveType == Enum.Enum_MoveType.FollowTargetBySpline or 
                            self.Spec.MoveType == Enum.Enum_MoveType.ToTargetBySpline) then
        self:InitSplineTimeline()
    end
    self:SendClientMessage("OnSwitchActivateState", true)

    if self:HasAuthority() then
        self:AddBuffToSourceActor()

        -- For period calc, trigger once immediately.
        if self.Spec.ProjectileCalcType == Enum.Enum_ProjectileCalcType.Period then
            if self.Spec.CalcPeriod > 0 then
                self:ExecCalcInPeriod()
            end
        end
    end
end

function Projectile:AddBuffToSourceActor()
    if not self.SourceActor or not UE.UKismetSystemLibrary.IsValid(self.SourceActor) then
        return
    end

    if self.BuffTags then
        local Tags = self.BuffTags.GameplayTags
        for Ind = 1, Tags:Length() do
            self.SourceActor:SendMessage("AddBuffByTag", Tags:Get(Ind))
        end
    end
end

function Projectile:RemoveBuffFromSourceActor()
    if not self.SourceActor or not UE.UKismetSystemLibrary.IsValid(self.SourceActor) then
        return
    end

    if self.BuffTags then
        local Tags = self.BuffTags.GameplayTags
        for Ind = 1, Tags:Length() do
            self.SourceActor:SendMessage("RemoveBuffByTag", Tags:Get(Ind))
        end
    end
end

function Projectile:Init()
    if self.bInited then
        return
    end
    self.bInited = true

    G.log:debug("santi", "Init projectile")

    self.CurHSpeed = self.Spec.HSpeed
    self.CurVSpeed = self.Spec.VSpeed

    -- Left calculation count.
    self.LeftCalcCount = self.Spec.CalcCountLimit

    if self:HasAuthority() then
        -- Init period calculation timer
        if self.Spec.ProjectileCalcType == Enum.Enum_ProjectileCalcType.Period then
            -- Assume period calc always not unique hit.
            self.Spec.bHitUnique = false
            self:InitCalculationTimer()
        end

        -- Init duration timer
        self:InitLifetimeTimer()

        -- Init collision component for pre attack.
        self.RootComponent = NewObject(UE.USceneComponent, self)
        if self.Spec.ProjectileType ~= Enum.Enum_ProjectileType.Calc then
            self:InitPreAttackCollisionComponent()
        end
    end

    self:ResetLocation()

    -- Bind projectile to SkillTarget.
    if self.BindActor then
        self:BindToTarget(self.BindActor)
    elseif self.Spec.MoveType == Enum.Enum_MoveType.BindTarget then
        -- 这一快现在有bug，当怪物技能瞄准玩家，玩家换角，这时候skillTarget就不是当前
        -- 玩家的角色，这时候就要仿照 moveToTarget的逻辑，用SkillTargetController来判断
        -- TODO
        self:BindToTarget(self.SkillTarget);
    elseif self.Spec.MoveType == Enum.Enum_MoveType.BindSource then
        self:BindToTarget(self.SourceActor)
    end

    self.LastSweepPos = self:K2_GetActorLocation()
end

function Projectile:InitPreAttackCollisionComponent()
    local CollisionComp = nil
    if self.Spec.CalcRangeType == Enum.Enum_CalcRangeType.Circle
            or self.Spec.CalcRangeType == Enum.Enum_CalcRangeType.Section then
        CollisionComp = self:InitSphereComponent()
    else
        CollisionComp = self:InitBoxComponent()
    end

    if CollisionComp then
        CollisionComp:SetGenerateOverlapEvents(true)
        CollisionComp:SetCollisionEnabled(UE.ECollisionEnabled.QueryOnly)
        CollisionComp:SetCollisionObjectType(UE.ECollisionChannel.Projectile)
        CollisionComp:SetCollisionProfileName("Projectile")
        -- CollisionComp:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_Destructible, UE.ECollisionResponse.ECR_Overlap)
        CollisionComp.OnComponentBeginOverlap:Add(self, self.OnPreAttackBeginOverlap)
        CollisionComp.OnComponentEndOverlap:Add(self, self.OnPreAttackEndOverlap)
        -- TODO replicated box extent show on client not right ?
        CollisionComp:SetIsReplicated(true)
        CollisionComp:K2_AttachToComponent(self:K2_GetRootComponent(), "", UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative)
    end

    self.PreAttackCollisionComp = CollisionComp
end

function Projectile:InitSphereComponent()
    local Comp = NewObject(UE.USphereComponent, self)

    local Radius = self.Spec.Radius
    if self.Spec.ProjectileType == Enum.Enum_ProjectileType.PreAttackAndCalc then
        Radius = self.Spec.PreAttackRadius
    end
    Comp:SetSphereRadius(Radius)
    return Comp
end

function Projectile:InitBoxComponent()
    local Length = self.Spec.Length
    if self.Spec.ProjectileType == Enum.Enum_ProjectileType.PreAttackAndCalc then
        Length = self.Spec.PreAttackRadius
    end

    local Comp = NewObject(UE.UBoxComponent, self)
    local HalfExtent = UE.FVector(Length / 2, self.Spec.HalfWidth, (self.Spec.UpHeight + self.Spec.DownHeight) / 2)
    Comp:SetBoxExtent(HalfExtent)
    Comp:K2_SetRelativeLocation(UE.FVector(self.Spec.Length / 2, 0, 0), false, UE.FHitResult(), true)
    return Comp
end

function Projectile:InitCalculationTimer()
    if self.Spec.CalcPeriod > 0 then
        self.CalcTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.ExecCalcInPeriod}, self.Spec.CalcPeriod, true)
    end
end

function Projectile:InitLifetimeTimer()
    if self.Spec.Duration > 0 then
        self.LifetimeTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.DestroySelf}, self.Spec.Duration, false)
    end
end

function Projectile:ResetLocation()
    local OriginLocation = UE.FVector()
    local OriginRotation = UE.FRotator()
    UE.UKismetMathLibrary.BreakTransform(self.StartLocation.LiteralTransform, OriginLocation, OriginRotation, UE.FVector())

    self:K2_SetActorLocation(OriginLocation, false, UE.FHitResult(), true)
    self:K2_SetActorRotation(OriginRotation, true)
end

function Projectile:BindToTarget(Target)
    if Target then
        self.BindActor = Target
    end
    -- BOSS天降流星技能，不能Attach到胶囊体上，因为动画不带RootMotion，但Attach到Mesh上却无法正常触发Overlap -> 改成每帧改位置
    -- TODO add socket.
    -- self.RootComponent:K2_SetRelativeLocation(self.Spec.StartPosOffset, false, UE.FHitResult(), true)
    -- self.RootComponent:K2_AttachToComponent(self.SourceActor.Mesh, self.Spec.BindSocketName, UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative)
end

function Projectile:InitSplineTimeline()
    self:SendMessage("CreateSplineAndTimeline", self:GetTransform(), false)
    self:SendMessage("UpdateSplineTargetLocation", self:GetSkillTargetLocation("Down"))
end

function Projectile:ReceiveTick(DeltaSeconds)
    if self.bDestroying or not UE.UKismetSystemLibrary.IsValid(self) or not UE.UKismetSystemLibrary.IsValid(self:K2_GetRootComponent()) then
        return
    end

    if self.BP_ReceiveTick then
        self:BP_ReceiveTick(DeltaSeconds)
    end

    self.FrameCount = self.FrameCount + 1

    -- Only run on server, as projectile only init on server.
    if self:HasAuthority() then
        if self.Spec.ProjectileCalcType ~= Enum.Enum_ProjectileCalcType.Period
                and self.FrameCount % self.CalcFrameInterval == 0
                and self.CalcComponent.bCanCalc then
            self:ExecCalcInstant(false)
        end
    end

    if self.CanMove then    --蓝图布尔参数
        if self.Spec.MoveType == Enum.Enum_MoveType.SourceForward then
            self:MoveSourceForward(DeltaSeconds)
        elseif self.Spec.MoveType == Enum.Enum_MoveType.FollowTarget then
            self:MoveFollowTarget(DeltaSeconds)
        elseif self.Spec.MoveType == Enum.Enum_MoveType.FollowTargetBySpline then
            self:MoveFollowTargetBySpline()
        elseif self.Spec.MoveType == Enum.Enum_MoveType.BindActor then
            self:MoveBindActor()
        elseif self.Spec.MoveType == Enum.Enum_MoveType.BindSource then
            self:MoveBindSource()
        elseif self.Spec.MoveType == Enum.Enum_MoveType.BindTarget then
            self:MoveBindTarget()
        end
    end
end

function Projectile:OnBeExtremeWithStand(WithStandActor)
    local CurrentTargetActor = nil;
    if self.SkillTargetController ~= nil then
        CurrentTargetActor = self.SkillTargetController:K2_GetPawn();
    else
        CurrentTargetActor = self.SkillTarget;
    end

    if CurrentTargetActor ~= WithStandActor then
        return
    end

    -- 被目标极限招架
    self.SkillTarget = self.SourceActor
    self.SourceActor = WithStandActor

    if self.Spec.MoveType == Enum.Enum_MoveType.SourceForward then
        local ReboundDir = self.SkillTarget:K2_GetActorLocation() - self.SourceActor:K2_GetActorLocation()
        self:K2_SetActorRotation(UE.UKismetMathLibrary.Conv_VectorToRotator(ReboundDir), true)
    elseif self.Spec.MoveType == Enum.Enum_MoveType.FollowTargetBySpline then
        self:SendMessage("ReboundByExtremeWithStand", self.SkillTarget)
    end

    self:SendMessage("InitCalcForHits", self.SourceActor, self,
        self.Spec, self.KnockInfo, self.GameplayEffectsHandle, self.HitSceneTargetConfig, nil, self.SelfGameplayEffectsHandle)
end

function Projectile:MoveSourceForward(DeltaSeconds)
    if not UE.UKismetSystemLibrary.IsValid(self) then
        return
    end

    local HDelta = self:K2_GetRootComponent():GetForwardVector() * self.CurHSpeed * DeltaSeconds
    local VDelta = self:K2_GetRootComponent():GetUpVector() * self.CurVSpeed * DeltaSeconds
    self:K2_SetActorLocation(self:K2_GetActorLocation() + HDelta + VDelta, true, UE.FHitResult(), true)
    self:UpdateSpeed(DeltaSeconds)
end

function Projectile:MoveFollowTarget(DeltaSeconds)
    if not UE.UKismetSystemLibrary.IsValid(self) then
        return
    end

    local MoveDir = self:K2_GetRootComponent():GetForwardVector()
    if self.SkillTargetController then
        MoveDir = self.SkillTargetController:K2_GetPawn():K2_GetActorLocation() - self:K2_GetActorLocation()
    elseif self.SkillTarget then
        MoveDir = self.SkillTarget:K2_GetActorLocation() - self:K2_GetActorLocation()
    elseif self.SkillTargetTransform then
        local SkillTargetLocation = UE.FVector()
        UE.UKismetMathLibrary.BreakTransform(self.SkillTargetTransform, SkillTargetLocation, UE.FRotator(), UE.FVector())
        MoveDir = SkillTargetLocation - self:K2_GetActorLocation()
    end
    MoveDir = UE.UKismetMathLibrary.Normal(MoveDir)

    -- 要先改朝向再改位置，因为SetActorLocation会触发Hit，Hit中有可能触发极限招架
    -- 1.极限招架会将Projectile反弹，如果朝向不对就无法命中下一个目标
    -- 2.极限招架也会改Projectile朝向，SetActorLocation之后再改就覆盖了
    self:K2_SetActorRotation(UE.UKismetMathLibrary.Conv_VectorToRotator(MoveDir), true)

    -- Follow target use HSpeed.
    local Delta = MoveDir * self.CurHSpeed * DeltaSeconds
    self:K2_SetActorLocation(self:K2_GetActorLocation() + Delta, false, UE.FHitResult(), true)

    self:UpdateSpeed(DeltaSeconds)
end

function Projectile:MoveFollowTargetBySpline()
    if not UE.UKismetSystemLibrary.IsValid(self) then
        return
    end

    self:SendMessage("UpdateSplineTargetLocation", self:GetSkillTargetLocation())
end

function Projectile:GetSkillTargetLocation(Part)
    local SkillTargetLocation = UE.FVector()
    local CurrentSkillTarget = nil;
    if self.SkillTargetController ~= nil then
        CurrentSkillTarget = self.SkillTargetController:K2_GetPawn();
    else
        CurrentSkillTarget = self.SkillTarget;
    end

    if CurrentSkillTarget then
        if Part == "Up" then
            SkillTargetLocation = utils.GetActorLocation_Up(CurrentSkillTarget)
        elseif Part == "Down" then
            SkillTargetLocation = utils.GetActorLocation_Down(CurrentSkillTarget)
        else
            SkillTargetLocation = CurrentSkillTarget:K2_GetActorLocation()
        end
    elseif self.SkillTargetTransform then
        SkillTargetLocation, _, _ = UE.UKismetMathLibrary.BreakTransform(self.SkillTargetTransform)
    end

    return SkillTargetLocation
end

function Projectile:MoveBindActor()
    if not UE.UKismetSystemLibrary.IsValid(self) then
        return
    end

    if self.BindActor then
        self:K2_SetActorLocation(self:GetBindLocation(self.BindActor), false, nil, true)
    end
end

function Projectile:MoveBindSource()
    if not UE.UKismetSystemLibrary.IsValid(self) then
        return
    end

    if self.SourceActor then
        self:K2_SetActorLocation(self:GetBindLocation(self.SourceActor), false, nil, true)
    end
end

function Projectile:MoveBindTarget()
    if not UE.UKismetSystemLibrary.IsValid(self) then
        return
    end

    if self.SkillTarget then
        self:K2_SetActorLocation(self:GetBindLocation(self.SkillTarget), false, nil, true)
    end
end

function Projectile:GetBindLocation(BindTarget)
    if BindTarget.Mesh and self.Spec.BindSocketName ~= "" then
        return BindTarget.Mesh:GetSocketLocation(self.Spec.BindSocketName)
    else
        return BindTarget:K2_GetActorLocation()
    end
end

function Projectile:UpdateSpeed(DeltaSeconds)
    self.CurHSpeed = self.CurHSpeed + self.Spec.HAccSpeed * DeltaSeconds
    if self.CurHSpeed * self.Spec.HAccSpeed < 0 then
        self.CurHSpeed = 0
    end

    self.CurVSpeed = self.CurVSpeed + self.Spec.VAccSpeed * DeltaSeconds
end

function Projectile:OnPreAttackBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if OtherActor == self or OtherActor == self.SourceActor or OtherActor == self.BindActor then
        return
    end

    local SelfLocation = OverlappedComponent:K2_GetComponentLocation()

    -- Section calculation type also use SphereComponent to overlap, so check in section here again.
    if self.Spec.CalcRangeType == Enum.Enum_CalcRangeType.Section then
        if not UE.UHiCollisionLibrary.CheckInSection(OtherActor:K2_GetActorLocation(), self:K2_GetActorLocation(), self:GetActorForwardVector(), UE.UKismetMathLibrary.DegreesToRadians(self.Spec.Angle)) then
            return
        end
    end

    local CompLoc, CompBounds = UE.UKismetSystemLibrary.GetComponentBounds(OtherComp)
    if not UE.UHiCollisionLibrary.CheckInHeightZ(SelfLocation.Z, CompLoc.Z + CompBounds.Z, CompLoc.Z - CompBounds.Z, self.Spec.UpHeight, self.Spec.DownHeight) then
        return
    end

    self:HandleOverlapActor(OtherActor, false)
end

function Projectile:OnPreAttackEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    --G.log:debug(self.__TAG__, "OnPreAttackEndOverlap component: %s", G.GetObjectName(OtherComp))

    -- TODO 策划要求只触发一次...
    --self:HandleOverlapActor(OtherActor, true)
end

function Projectile:HandleOverlapActor(HitActor, bEnd)
    if bEnd then
        if self.OverlapActors[HitActor] then
            if HitActor.SendMessage then
                HitActor:SendMessage("AddPreAttackBuff")
            end
            self.OverlapActors[HitActor] = nil
        end
    else
        if not self.OverlapActors[HitActor] then
            if HitActor.SendMessage then
                HitActor:SendMessage("RemovePreAttackBuff")
            end
            self.OverlapActors[HitActor] = true
        end
    end
end

function Projectile:ExecCalcInPeriod()
    if self.SourceActor and self.SourceActor.TimeDilationComponent and self.SourceActor.TimeDilationComponent.bWitchTime then
        return
    end
    if self.CanTraceCollision == false then --限制碰撞检测开关
        return 
    end
    local Hits = UE.TArray(UE.FHitResult)
    local ActorsToIgnore = UE.TArray(UE.AActor)
    ActorsToIgnore:AddUnique(self.SourceActor)
    ActorsToIgnore:AddUnique(self.BindActor)
    if self.SourceActor and self.SourceActor:IsPlayer() then
        HiCollisionLibrary.PerformSweep(self, self.Spec, self:K2_GetActorLocation(), self:K2_GetActorRotation(), nil, self:GetActorForwardVector(), self.Spec.HitTypes, ActorsToIgnore, Hits, self.DebugType)
    else
        HiCollisionLibrary.PerformOverlapComponents(self, self.Spec, self:K2_GetActorLocation(), self:GetActorForwardVector(), self.Spec.HitTypes, ActorsToIgnore, Hits, self.bDebug)
    end

    self:ExecCalc(Hits, false)
end

function Projectile:ExecCalcInstant(bOnDestroy, HitPoint)
    if self.SourceActor and self.SourceActor.TimeDilationComponent and self.SourceActor.TimeDilationComponent.bWitchTime then
        self.LastSweepPos = nil
        return
    end
    if self.CanTraceCollision == false then --限制碰撞检测开关
        return 
    end
    if self.LastSweepPos then
        local SweepDis = UE.UKismetMathLibrary.Vector_Distance(self.LastSweepPos, self:K2_GetActorLocation())
        local Hits = UE.TArray(UE.FHitResult)
        local ActorsToIgnore = UE.TArray(UE.AActor)
        ActorsToIgnore:AddUnique(self.SourceActor)
        ActorsToIgnore:AddUnique(self.BindActor)
        -- 销毁时结算半径区别于飞行时结算半径
        if bOnDestroy and self.Spec.CalcRadiusOnDestroy > 0 then
            self.Spec.Radius = self.Spec.CalcRadiusOnDestroy
            self.Spec.CalcRangeType = Enum.Enum_CalcRangeType.Circle
        end

        if not HitPoint then
            HitPoint = self:K2_GetActorLocation()
        end

        HitPoint = UE.FVector(HitPoint.X, HitPoint.Y, HitPoint.Z)
        if self.SourceActor and self.SourceActor:IsPlayerComp() then
            HiCollisionLibrary.PerformSweep(self, self.Spec, HitPoint, self:K2_GetActorRotation(), SweepDis, self:GetActorForwardVector(), self.Spec.HitTypes, ActorsToIgnore, Hits, self.DebugType)
        else
            HiCollisionLibrary.PerformOverlapComponents(self, self.Spec, HitPoint, self:GetActorForwardVector(), self.Spec.HitTypes, ActorsToIgnore, Hits,  self.bDebug)
        end

        self:ExecCalc(Hits, bOnDestroy)
    end
    self.LastSweepPos = self:K2_GetActorLocation()
end

function Projectile:ExecCalc(Hits, bOnDestroy)

    -- 这个地方需要排除一下一个同PlayState
    -- 否则会出现一巴掌拍死多个角色的现象
    if self.HitPlayerStates == nil then
        self.HitPlayerStates = UE.TArray(UE.APlayerState)
    end

    local FilterHits = UE.TArray(UE.FHitResult)

    for Index = 1, Hits:Length() do
        local actor = Hits:Get(Index).HitObjectHandle.Actor;
        if actor.PlayerState == nil then
            FilterHits:AddUnique(Hits:Get(Index))
        elseif actor.PlayerState ~= nil and self.HitPlayerStates:Contains(actor.PlayerState) == false then
            FilterHits:AddUnique(Hits:Get(Index))
        end
    end 

    for Index = 1, FilterHits:Length() do
        local actor = FilterHits:Get(Index).HitObjectHandle.Actor;
        if actor.PlayerState then
            self.HitPlayerStates:AddUnique(actor.PlayerState);
        end
    end

    if FilterHits:Length() > 0 then
        -- Non moving type projectile (MagicField .etc.) can not be defended.
        local bCanDefend = self:IsMovingType()
        self:SendMessage("ExecCalcForHits", FilterHits, nil, self.Spec.bNeedBroadcast, bCanDefend, bOnDestroy)
    end
end

function Projectile:IsMovingType()
    return self.Spec.MoveType == Enum.Enum_MoveType.SourceForward or self.Spec.MoveType == Enum.Enum_MoveType.FollowTarget
end

function Projectile:HitCallback(ChannelType, Hit)
    local bDestroy = false
    if ChannelType == UE.ECollisionChannel.ECC_WorldStatic then
        if self.HitSceneSelfConfig.HitStaticMeshResult == Enum.Enum_HitSceneSelfResult.Destroy then
            bDestroy = true
            self:DestroySelf(Hit)
        end
    elseif ChannelType == UE.ECollisionChannel.ECC_WorldDynamic then
        if self.HitSceneSelfConfig.HitDynamicResult == Enum.Enum_HitSceneSelfResult.Destroy then
            bDestroy = true
            self:DestroySelf(Hit)
        end
    elseif ChannelType == UE.ECollisionChannel.ECC_Destructible then
        if self.HitSceneSelfConfig.HitDestructibleResult == Enum.Enum_HitSceneSelfResult.Destroy then
            bDestroy = true
            self:DestroySelf(Hit)
        end
    else
        if self.HitSceneSelfConfig.DefaultHitResult == Enum.Enum_HitSceneSelfResult.Destroy then
            bDestroy = true
            self:DestroySelf(Hit)
        end
    end

    if self.HitCallbackFunc then
        self.HitCallbackFunc(self.HitCallbackOwner, ChannelType, Hit, self.ApplicationTag, bDestroy)
    end
end

function Projectile:ReachTargetLimitCallback()
    if self.Spec.CalcDestroyType == Enum.Enum_CalcDestroyType.DestroyAfterCalc then
        G.log:debug("santi", "Destroy projectile after reach calculation count limit.")
        self:DestroySelf()
    end
end

function Projectile:RegisterDestroyCallback(CallbackOwner, CallbackFunc)
    self.DestroyCallbackOwner = CallbackOwner
    self.DestroyCallbackFunc = CallbackFunc
end

function Projectile:RegisterHitCallback(CallbackOwner, CallbackFunc)
    self.HitCallbackOwner = CallbackOwner
    self.HitCallbackFunc = CallbackFunc
end

-- function Projectile:SpawnHitDecals(Location)
--     for idx = 1, self.HitSceneTargetConfig.HitStaticMesh_SpawnDecal:Length() do
--         local HitSpawnDecalConfig = self.HitSceneTargetConfig.HitStaticMesh_SpawnDecal:Get(idx)
--         if HitSpawnDecalConfig.SpawnFrames:Length() == 0 or HitSpawnDecalConfig.SpawnFrames:Contains(self.FrameCount) then
--             -- G.log:debug("yj", "Projectile:SpawnHitDecals FrameCount.%s Location.%s", self.FrameCount, Location)
--             self:SpawnDecalAtLocation(Location, HitSpawnDecalConfig)
--         end
--     end
-- end

---@param Value boolean 是否启用碰撞检测
function Projectile:SetUpCanTraceCollision(Value)
    Value = Value and true or false
    self.CanTraceCollision = Value
    local CollisionComp = self.PreAttackCollisionComp
    if not CollisionComp then return end
    CollisionComp:SetGenerateOverlapEvents(Value)
    CollisionComp:SetCollisionEnabled(Value and UE.ECollisionEnabled.QueryOnly or UE.ECollisionEnabled.NoCollision)
end

--- @param Hit UE.FHitResult 指定受击点销毁，包括销毁特效和销毁结算.
function Projectile:DestroySelf(Hit)
    if self.bDestroying then
        return
    end

    self.bDestroying = true

    if self.Spec.ProjectileLifetimeCalcType ~= Enum.Enum_ProjectileLifetimeCalcType.AllNotDestroy and self:IsServer() then
        self:ExecCalcInstant(true, Hit and Hit.ImpactPoint or nil)
    end

    if self.PreAttackCollisionComp then
        self.PreAttackCollisionComp.OnComponentBeginOverlap:Remove(self, self.OnPreAttackBeginOverlap)
        self.PreAttackCollisionComp.OnComponentEndOverlap:Remove(self, self.OnPreAttackEndOverlap)
    end

    if self.DestroyCallbackOwner and self.DestroyCallbackFunc then
        self.DestroyCallbackFunc(self.DestroyCallbackOwner)
    end

    for HitActor, _ in pairs(self.OverlapActors) do
        self:HandleOverlapActor(HitActor, true)
    end

    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.CalcTimer)
    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.LifetimeTimer)

    self:RemoveBuffFromSourceActor()

    self:Multicast_DestroySelf(Hit)

    self:K2_DestroyActor()
end

function Projectile:Multicast_DestroySelf_RPC(Hit)
    -- Show destroy effect
    if self.Spec.DestroyEffect and not self:HasAuthority() then
        local SpawnLocation = Hit and Hit.Component and Hit.ImpactPoint or self:K2_GetActorLocation()
        UE.UNiagaraFunctionLibrary.SpawnSystemAtLocation(self, self.Spec.DestroyEffect, SpawnLocation, self:K2_GetActorRotation())
    end
end

function Projectile:ReceiveDestroyed()
    self.Overridden.ReceiveDestroyed(self)

    G.log:debug(self.__TAG__, "Receive destroyed %s, IsServer: %s", G.GetDisplayName(self), self:IsServer())

    self:SendClientMessage("OnSwitchActivateState", false)
end

return RegisterActor(Projectile)
