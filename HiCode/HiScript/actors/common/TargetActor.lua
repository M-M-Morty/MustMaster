require "UnLua"

-- TargetActor implement in lua.
local G = require("G")
local HiCollisionLibrary = require("common.HiCollisionLibrary")

local TargetActorBase = require("actors.common.TargetActorBase")

local TargetActor = Class(TargetActorBase)

local DefaultDeltaSocketSeconds = 0.05
local DefaultSweepDis = 10

function TargetActor:Initialize(...)
    Super(TargetActor).Initialize(self, ...)
end

function TargetActor:UserConstructionScript()
end

function TargetActor:ReceiveBeginPlay()
    Super(TargetActor).ReceiveBeginPlay(self)

    self.ShouldProduceTargetDataOnServer = true
end

function TargetActor:OnStartTargeting(Ability)
    Super(TargetActor).OnStartTargeting(self, Ability)

    -- Init skill target.
    self:_InitSkillTarget(Ability)

    -- Init start location.
    self:_InitStartLocationAndRotation()

    -- Init calc for hits.
    self:SendMessage("InitCalcForHits", self.SourceActor, self.SourceActor, 
        self.Spec, self.KnockInfo, self.GameplayEffectsHandle, self.HitSceneTargetConfig, self.StartLocation, self.SelfGameplayEffectsHandle)
end

function TargetActor:_InitSkillTarget(Ability)
    local UserData = Ability:GetCurrentUserData()

    if UserData then
        self.SkillTarget = UserData.SkillTarget
        self.SkillTargetTransform = UserData.SkillTargetTransform
    end
end

function TargetActor:_InitStartLocationAndRotation()
    self.StartLocation.LocationType = UE.EGameplayAbilityTargetingLocationType.LiteralTransform
    self.StartLocation.SourceActor = self.SourceActor
    self.StartLocation.SourceAbility = self.OwningAbility

    local StartPos = self:_InitStartLocation()
    local StartRot = self:_InitStartRotation(StartPos)
    self.StartLocation.LiteralTransform = UE.UKismetMathLibrary.MakeTransform(StartPos, StartRot, UE.FVector(1, 1, 1))
end

function TargetActor:_InitStartLocation()
    local StartPos = UE.FVector(0, 0, 0)
    local StartPosOffset = self.Spec.StartPosOffset
    if self.Spec.StartPosType == Enum.Enum_StartPosType.Source then
        -- Start pos refer to source actor.
        if self.SourceActor then
            StartPos = UE.UKismetMathLibrary.TransformLocation(utils.GetCorrectTransform(self.SourceActor), StartPosOffset)
        end
    elseif self.Spec.StartPosType == Enum.Enum_StartPosType.Target then
        -- Start pos refer to target actor.
        if self.SkillTarget then
            StartPos = UE.UKismetMathLibrary.TransformLocation(utils.GetCorrectTransform(self.SkillTarget), StartPosOffset)
        elseif self.SkillTargetTransform then
            StartPos = UE.UKismetMathLibrary.TransformLocation(self.SkillTargetTransform, StartPosOffset)
        end
    elseif self.Spec.StartPosType == Enum.Enum_StartPosType.BoneOffset then
        -- Start pos refer to source actor bone.
        if self.SourceActor then
            -- Bone的Rotation不一定是对的，所以先用Actor来做TransformLocation，然后再加上Bone相对于Actor的位置偏移
            StartPos = UE.UKismetMathLibrary.TransformLocation(self.SourceActor:GetTransform(), StartPosOffset)
            StartPos = StartPos + (self.SourceActor:GetSocketLocation(self.Spec.StartPosBoneName) - self.SourceActor:K2_GetActorLocation())
            -- G.log:debug("yj", "TargetActor:_InitStartLocation Offset.%s Transform(%s) StartPos.%s", StartPosOffset, self.SourceActor:GetBoneTransform(self.Spec.StartPosBoneName), StartPos)
        end
    elseif self.Spec.StartPosType == Enum.Enum_StartPosType.BurstPoint then
        -- client particle effect burst point
        if self.SourceActor and self.SourceActor.BurstPointComponent and self.SourceActor.BurstPointComponent:GetBurstPointsNum() > 0 then
            StartPos = self.SourceActor.BurstPointComponent:GetBurstPoint()
        end
    end

    -- G.log:debug("yj", "TargetActor:_InitStartLocation %s StartPosType.%s SourceActor.%s", StartPos, self.Spec.StartPosType, self.SourceActor)

    return StartPos
end

function TargetActor:_InitStartRotation(StartPos)
    local StartRot = UE.FRotator(0, 0, 0)
    if self.Spec.StartRotType == Enum.Enum_StartRotType.Source then
        -- Start rot refer to source actor.
        if self.SourceActor then
            StartRot = self.SourceActor:K2_GetActorRotation()
        end
    elseif self.Spec.StartRotType == Enum.Enum_StartRotType.Target then
        -- Start rot refer to target actor.
        if self.SkillTarget then
            StartRot = self.SkillTarget:K2_GetActorRotation()
        elseif self.SkillTargetTransform then
            UE.UKismetMathLibrary.BreakTransform(self.SkillTargetTransform, UE.FVector(), StartRot, UE.FVector())
        end
    elseif self.Spec.StartRotType == Enum.Enum_StartRotType.Aim then
        -- Start rot to aim rotation.
        if self.SourceActor and self.SourceActor.GetCameraRotation then
            StartRot = self.SourceActor:GetCameraRotation()
        end
    elseif self.Spec.StartRotType == Enum.Enum_StartRotType.TowardTarget then
        -- Start rot toward target.
        if self.SkillTarget then
            StartRot = UE.UKismetMathLibrary.Conv_VectorToRotator(self.SkillTarget:K2_GetActorLocation() - StartPos)
        end
    end

    StartRot = StartRot + self.Spec.StartRotOffset
    -- G.log:debug("yj", "TargetActor:_InitStartRotation %s StartRotOffset.%s StartRotType.%s SourceActor.%s SkillTarget.%s", StartRot, self.Spec.StartRotOffset, self.Spec.StartRotType, self.SourceActor, self.SkillTarget)

    return StartRot
end

function TargetActor:OnConfirmTargetingAndContinue()
    local IsClient = (not self.SourceActor:HasAuthority()) or (self.MasterPC and self.MasterPC:IsLocalPlayerController())
    G.log:debug(self.__TAG__, "TargetActor OnConfirmTargetingAndContinue, IsServer: %s", not IsClient)

    -- 统一下 debug 字段.
    if not self.bDebug then
        self.DebugType = UE.EDrawDebugTrace.None
    else
        self.DebugType = UE.EDrawDebugTrace.ForDuration
    end

    -- For Projectile calc type, spawn projectile.
    if self.Spec.CalcType == Enum.Enum_CalcType.Projectile then
        if self:HasAuthority() and not IsClient then
            self:_SpawnProjectile()
        end
        return
    end


    -- For Chain calc type, spawn projectile.
    if self.Spec.CalcType == Enum.Enum_CalcType.Chain then
        if self:HasAuthority() and not IsClient then
            self:_SpawnChain()
        end
        return
    end

    -- For Chain calc type, spawn projectile.
    if self.Spec.CalcType == Enum.Enum_CalcType.Summons then
        if self:HasAuthority() and not IsClient then
            self:_SpawnSummons()
        end
        return
    end

    if IsClient and not self:IsShouldProduceTargetDataOnServer() then
        self:ClientExecCalc()
    elseif (not IsClient) and self:IsShouldProduceTargetDataOnServer() then
        self:ServerExecCalc()
    end
end

-- Run on server.
function TargetActor:OnTargetDataReceived(TargetDataHandle)
    G.log:debug(self.__TAG__, "Receive target data from client, need cheat check.")

    -- check cheat from client.
    self.TargetDataHandle = TargetDataHandle

    -- TODO Knock info capsuled in TargetDataHandle which send from client, cant replicate correctly. So use local update.
    UE.UHiUtilsFunctionLibrary.UpdateKnockInfoOfTargetData(TargetDataHandle, self.KnockInfo)

    --self:SendMessage("TargetDataCheatCheck", self.TargetDataHandle)
    --
    ---- check fail
    --local OldTargetCount = UE.UAbilitySystemBlueprintLibrary.GetDataCountFromTargetData(TargetDataHandle)
    --local NewTargetCount = UE.UAbilitySystemBlueprintLibrary.GetDataCountFromTargetData(self.TargetDataHandle)
    ---- G.log:debug("yj", "TargetActor:OnTargetDataReceived %s %s", OldTargetCount, NewTargetCount)
    --if OldTargetCount ~= NewTargetCount then
    --    return false
    --end

    -- In client predict mode, server handle hits from client here.
    local Hits = UE.TArray(UE.FHitResult)
    UE.UAbilitySystemBlueprintLibrary.GetAllHitResultsFromTargetData(TargetDataHandle, Hits)
    self:SendMessage("HandleCalcFromClientPredictOnServer", Hits)

    return true
end

-- Run on client.
function TargetActor:ClientExecCalc()
    G.log:debug(self.__TAG__, "Exec calc on client")
    self:PerformOverlap()
end

-- Run on server.
function TargetActor:ServerExecCalc()
    G.log:debug(self.__TAG__, "Exec calc on server")
    self:PerformOverlap()
end

function TargetActor:PerformOverlap()
    if self.SourceActor and self.SourceActor.TimeDilationComponent and self.SourceActor.TimeDilationComponent.bWitchTime then
        return
    end

    local OriginLocation = UE.FVector()
    local OriginRotation = UE.FRotator()
    UE.UKismetMathLibrary.BreakTransform(self.StartLocation.LiteralTransform, OriginLocation, OriginRotation, UE.FVector())
    local ForwardVector = UE.UKismetMathLibrary.Conv_RotatorToVector(OriginRotation)

    -- A small sweep step in forward direction, instead of overlap(without hit points).
    local Hits = UE.TArray(UE.FHitResult)
    local ActorsToIgnore = UE.TArray(UE.AActor)
    ActorsToIgnore:AddUnique(self.SourceActor)
    if self.SourceActor and self.SourceActor:IsPlayerComp() then
        HiCollisionLibrary.PerformSweep(self, self.Spec, OriginLocation, OriginRotation, nil, ForwardVector, self.Spec.HitTypes, ActorsToIgnore, Hits, self.DebugType)
    else
        HiCollisionLibrary.PerformOverlapComponents(self, self.Spec, OriginLocation, ForwardVector, self.Spec.HitTypes, ActorsToIgnore, Hits, self.bDebug)
    end

    if Hits:Length() > 0 then
        self:SendMessage("ExecCalcForHits", Hits, self, true, true)
    end
end

function TargetActor:_SpawnProjectile()
    if not UE.UKismetSystemLibrary.IsValidClass(self.ProjectileClass) then
        G.log:error("santi", "TargetActor: %s spawn projectile but projectile class not valid.", G.GetDisplayName(self))
        return
    end

    local SpawnTransform = self.StartLocation.LiteralTransform
    local ProjectileActor = UE.UGameplayStatics.BeginDeferredActorSpawnFromClass(self, self.ProjectileClass, SpawnTransform)

    ProjectileActor.Spec = self.Spec
    ProjectileActor.HitSceneTargetConfig = self.HitSceneTargetConfig
    ProjectileActor.HitSceneSelfConfig = self.HitSceneSelfConfig
    ProjectileActor.StartLocation = self.StartLocation
    ProjectileActor.ApplicationTag = self.ApplicationTag
    ProjectileActor.ReboundRotOffset = self.ReboundRotOffset
    ProjectileActor.bDebug = self.bDebug
    ProjectileActor.DebugType = self.DebugType
    -- Set SourceActor info.
    ProjectileActor.SourceActor = self.SourceActor
    if self.SourceActor then
        ProjectileActor.CharCamp = self.SourceActor.CharCamp
        ProjectileActor.SourceActorTransform = self.SourceActor:GetTransform()
    end
    -- Set skill target info.
    ProjectileActor.SkillTarget,ProjectileActor.SkillTargetController,ProjectileActor.SkillTargetTransform = self:OnUseNewProjectileFollowTarget()
    -- Set GEs spec
    ProjectileActor.GameplayEffectsHandle = self.GameplayEffectsHandle
    ProjectileActor.SelfGameplayEffectsHandle = self.SelfGameplayEffectsHandle

    -- Set KnockInfo
    ProjectileActor.KnockInfo = self.KnockInfo
    ProjectileActor.Spec.ProjectType = self.KnockInfo.ProjectType

    ProjectileActor:Init()

    if self.KnockInfo.bIsBindType and self.KnockInfo.bBind and self.OwningAbility then
        self.OwningAbility:OnBindProjectile(self.ApplicationTag, ProjectileActor)
        ProjectileActor:RegisterHitCallback(self.OwningAbility, self.OwningAbility.OnHitTarget)
    end

    UE.UGameplayStatics.FinishSpawningActor(ProjectileActor, SpawnTransform)
    --G.log:info("yb", "TargetFilter:_SpawnProjectile %s %s", G.GetObjectName(ProjectileActor), ProjectileActor.CharCamp)
    --G.log:debug(self.__TAG__, "Spawn projectile: %s success.", G.GetObjectName(ProjectileActor))
end


function TargetActor:_SpawnChain()
    --目前可以复用子弹的信息
    self:_SpawnProjectile()
end

function TargetActor:_SpawnSummons()
    local AbilityCDO = self.StartLocation.SourceAbility
    local SummonsClass = AbilityCDO.ActorClass
    if not UE.UKismetSystemLibrary.IsValidClass(SummonsClass) then
        G.log:error("yb", "TargetActor: %s spawn summons but summons class not valid.", G.GetDisplayName(self))
        return
    end
    local SpawnLocation = AbilityCDO:GetSpawnLocation()
    local SpawnRot = self.SourceActor:K2_GetActorRotation()
    local SpawnTransform = UE.UKismetMathLibrary.MakeTransform(SpawnLocation, SpawnRot, UE.FVector(1, 1, 1))
    local SummonsActor = UE.UGameplayStatics.BeginDeferredActorSpawnFromClass(self, SummonsClass, SpawnTransform)
    SummonsActor.SourceActor = self.SourceActor
    UE.UGameplayStatics.FinishSpawningActor(SummonsActor, SpawnTransform)
    G.log:debug(self.__TAG__, "Spawn projectile: %s success.", G.GetObjectName(SummonsActor))
end

--当移动类型为跟随目标时,可修改 SkillTarget
function TargetActor:OnUseNewProjectileFollowTarget()
    local Spec = self.Spec;
    local SkillTargetTransform = self.SkillTargetTransform;

    -- 这里需要更改为目标的controller，再通过controller来获取目标
    -- 因为我们有换角的逻辑
    -- 后面如果再有类似的问题，再去看实际问题解决
    local SkillTarget = self.SkillTarget;
    local SkillTargetController = nil;
    
    if SkillTarget then
        SkillTargetController = self.SkillTarget:GetController();
    end

    if not Spec.bUseNewProjectileFollowTarget then return SkillTarget,SkillTargetController,SkillTargetTransform end
    local Actors = GameAPI.GetActorsWithTag(self.SourceActor, Spec.NewProjectileFollowTargetTag)
    if not Actors or #Actors == 0 then 
        G.log:error("yj", "OnUseNewProjectileFollowTarget tag.%s error", Spec.NewProjectileFollowTargetTag)
        assert(false)
    end
    for _, RouteActor in ipairs(Actors) do
        if RouteActor then
            SkillTarget = RouteActor
            SkillTargetController = nil;
            SkillTargetTransform = SkillTarget:GetTransform()
            return SkillTarget,SkillTargetController,SkillTargetTransform 
        end
    end
end

return RegisterActor(TargetActor)
