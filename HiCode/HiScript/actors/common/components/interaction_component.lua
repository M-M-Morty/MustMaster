local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

local InteractionComponent = Component(ComponentBase)
local decorator = InteractionComponent.decorator

GravityConst = -980
CalcLinearSpeedThreshold = 200
CalcAngularSpeedThreshold = 100

function InteractionComponent:Initialize(...)
    Super(InteractionComponent).Initialize(self, ...)
end

function InteractionComponent:Start()
    Super(InteractionComponent).Start(self)
end

function InteractionComponent:ReceiveBeginPlay()
    Super(InteractionComponent).ReceiveBeginPlay(self)
    self.__TAG__ = string.format("InteractionComponent(%s, server: %s)", G.GetObjectName(self.actor), self.actor:IsServer())

    self.bThrowing = false
    self.ThrowingBeginTime = -1
    self.bStarted = false
    self.MaxStartedCheckTime = 3

    -- Auto rotate
    self.bAutoRotate = false
    self.bAutoRotateInAbsorb = false
    self.CurAngularSpeed = 0
    self.AngularAcc = 0
    self.RotateAxis = UE.FVector()

    self.Mass = 0
    local TargetComponent = self:GetMainComponent()
    if TargetComponent:IsSimulatingPhysics() then
        self.Mass = self:GetMass()
    end
end

decorator.message_receiver()
function InteractionComponent:PostBeginPlay()
    if self.CaptureGA then
        self.actor.SkillComponent:GiveAbility(self.CaptureGA, -1, utils.MakeUserData())
    end

    if self.ThrowGA then
        self.actor.SkillComponent:GiveAbility(self.ThrowGA, -1, utils.MakeUserData())
    end

    if self.CaptureAndThrowGA then
        self.actor.SkillComponent:GiveAbility(self.CaptureAndThrowGA, -1, utils.MakeUserData())
    end
end

function InteractionComponent:ReceiveEndPlay(EndPlayReason)
    if self.Timeline then
        self.Timeline.Timeline:Stop()
        self.Timeline:K2_DestroyActor()
    end

    if self.Spline then
        self.Spline:K2_DestroyActor()
    end

    -- Clear blueprint refers.
    if self.CalcEffectsRef then
        self.CalcEffectsRef:Clear()
    end

    if self.CalcEffectsHandle then
        self.CalcEffectsHandle:Clear()
    end

    Super(InteractionComponent).ReceiveEndPlay(self)
end

---Capture target with process, target will absorbed to location in specified duration.
---@param Target AActor this actor want capture.
---@param Duration number capture process duration.
---@param TargetLocation FVector capture target position.
---@param TargetSocketName string capture target socket
---@param bDynamicFollow boolean whether dynamic change target position to socket current position.
function InteractionComponent:AbsorbTargetWithProcess(Target, Duration, TargetLocation, TargetSocketName, bDynamicFollow)
    Target = Target or self:GetUpTargetBeSelected()
    G.log:debug(self.__TAG__, "AbsorbTargetWithProcess target: %s, to: %s, duration: %f", G.GetObjectName(Target), TargetLocation, Duration)
    self:Multicast_AbsorbTargetWithProcess(Target, Duration, TargetLocation, TargetSocketName, bDynamicFollow)
end

function InteractionComponent:Multicast_AbsorbTargetWithProcess_RPC(Target, Duration, TargetLocation, TargetSocketName, bDynamicFollow)
    if not Target then
        return
    end

    G.log:debug(self.__TAG__, "Multicast_AbsorbTargetWithProcess target: %s, to: %s, duration: %f", G.GetObjectName(Target), TargetLocation, Duration)

    -- Record captured target.
    self.Capture = Target

    -- Notify target OnAbsorb
    self.Capture.InteractionComponent:OnAbsorb(self.actor, Duration, TargetLocation, TargetSocketName, bDynamicFollow)
end

function InteractionComponent:CancelAbsorbTarget()
    if not self.Capture then
        return
    end

    G.log:debug(self.__TAG__, "Multicast cancel absorb target: %s", G.GetObjectName(self.Capture))
    self:Multicast_CancelAbsorbTarget()
end

function InteractionComponent:Multicast_CancelAbsorbTarget_RPC()
    self.Capture.InteractionComponent:OnAbsorbCancel()
    self.Capture = nil
end

function InteractionComponent:ThrowTarget(TargetLocation, ThrowMoveSpeed, EThrowType, ImpulseMag, ThrowRotateInfo)
    if not self.Capture then
        return
    end

    self:Multicast_OnThrowTarget(TargetLocation, self.Capture:K2_GetActorLocation(), ThrowMoveSpeed , EThrowType, ImpulseMag, ThrowRotateInfo)
end

function InteractionComponent:Multicast_OnThrowTarget_RPC(TargetLocation, StartLocation, ThrowMoveSpeed, EThrowType, ImpulseMag, ThrowRotateInfo)
    -- Notify capture OnThrow
    if self.Capture then
        self.Capture.InteractionComponent:OnThrow(self.actor, TargetLocation, StartLocation, ThrowMoveSpeed, EThrowType, ImpulseMag, ThrowRotateInfo)
    end
    self.Capture = nil --扔完目标后立刻清空引用(行为树进抓取会判断一次是否正在抓)
end

function InteractionComponent:InitTimeLineAndSpline(Instigator, bAbsorb, TargetLocation, ThrowMoveSpeed)
    if self.DrawDebug then
        UE.UKismetSystemLibrary.DrawDebugPoint(self.actor:GetWorld(), TargetLocation, 50, UE.FLinearColor(0, 1, 1), 60)
    end

    local TimeLineClass, SplineClass
    if bAbsorb then
        TimeLineClass = self.AbsorbTimeLineClass
        SplineClass = self.AbsorbSplineClass
    else
        TimeLineClass = self.ThrowTimelineClass
        SplineClass = self.ThrowSplineClass
    end

    if not TimeLineClass or not SplineClass then
        G.log:error(self.__TAG__, "Must config TimeLine and Spline class, bAbsorb: %s.", bAbsorb)
        return
    end

    -- Init timeline actor.
    if self.Timeline ~= nil then
        self.Timeline:K2_DestroyActor()
    end

    local SpawnParameters = UE.FActorSpawnParameters()
    self.Timeline = GameAPI.SpawnActor(self.actor:GetWorld(), self.ThrowTimelineClass, self.actor:GetTransform(), SpawnParameters, {})
    self.Timeline:RegisterTimelineUpdateCallback(self, self.OnTimelineUpdate)
    self.Timeline:RegisterTimelineEndCallback(self, self.OnTimelineEnd)

    local MinValue, MaxValue = UE.UHiUtilsFunctionLibrary.GetTimelineValueRange(self.Timeline.Timeline)
    self.TimelineMaxValue = MaxValue

    -- Init spline actor.
    if self.Spline ~= nil then
        self.Spline:K2_DestroyActor()
    end

    local SpawnParameters = UE.FActorSpawnParameters()
    self.Spline = GameAPI.SpawnActor(self.actor:GetWorld(), self.ThrowSplineClass, self.actor:GetTransform(), SpawnParameters, {})

    -- 设置Spline的朝向
    local SplineRotation = Instigator:K2_GetActorRotation()
    SplineRotation.Pitch, SplineRotation.Roll = 0, 0
    self.Spline.Spline:K2_SetWorldRotation(SplineRotation, true, UE.FHitResult(), false)

    self:InitDynamicSpline(Instigator, TargetLocation)

    -- 设置播放倍率
    local MoveTime = 1.0
    if self.bAbsorb then
        MoveTime = self.MoveTime
    else
        MoveTime = self.Spline:GetSplineLength() / ThrowMoveSpeed
    end
    local TimelinePlayRate = self.Timeline.Timeline:GetTimelineLength() / MoveTime
    self.Timeline.Timeline:SetPlayRate(TimelinePlayRate)
    self.Timeline.Timeline:PlayFromStart()
end

function InteractionComponent:CaptureTarget(Target)
    Target = Target or self:GetUpTargetBeSelected()
    G.log:debug(self.__TAG__, "CaptureTarget %s", G.GetObjectName(Target))
    self:Multicast_OnCaptureTarget(Target)
end

function InteractionComponent:Multicast_OnCaptureTarget_RPC(Target)
    if not Target then
        return
    end

    G.log:debug(self.__TAG__, "Capture target: %s, IsServer: %s CaptureBoneName.%s", G.GetDisplayName(Target), self.actor:IsServer(), self.CaptureBoneName)

    -- Record captured target.
    self.Capture = Target

    -- Notify target OnCapture
    self.Capture.InteractionComponent:OnCapture(self.actor)
end

--[[
    Implement interface BPI_Interactable
]]
function InteractionComponent:OnCapture(Instigator)
    -- Run On Server And Client
    G.log:debug(self.__TAG__, "%s capture by instigator %s, IsServer: %s", G.GetDisplayName(self.actor), G.GetDisplayName(Instigator), self.actor:IsServer())

    -- Handle when still throwing.
    if self.CalcProjectile then
        self:UnbindCalc()
    end
    self.bThrowing = false
    self.ThrowingBeginTime = UE.UKismetMathLibrary.Now()
    self.bStarted = false

    self.CaptureBy = Instigator
    self.bThrowEnded = false

    if self.actor.OnCapture then
        self.actor:OnCapture(Instigator)
    end

    self:SendMessage("OnCapture", Instigator)

    -- TODO diff one or two hand according target type.
    local SnapToTarget = UE.EAttachmentRule.SnapToTarget
    local KeepWorld = UE.EAttachmentRule.KeepWorld
    self.actor:K2_AttachToComponent(Instigator.Mesh, Instigator.InteractionComponent.CaptureBoneName, SnapToTarget, SnapToTarget, KeepWorld)
end

function InteractionComponent:OnAbsorb(Instigator, Duration, TargetLocation, TargetSocketName, bDynamicFollow)
    self.CaptureBy = Instigator
    self.bThrowEnded = false
    self.bAbsorb = true
    self.MoveTime = Duration
    self.TargetSocketName = TargetSocketName
    self.bDynamicFollow = bDynamicFollow
    self:InitTimeLineAndSpline(Instigator, true, TargetLocation)

    self:SetInteractable(false)

    if self.AbsorbRotateInfo.bEnabled then
        self:StartAutoRotate(self.AbsorbRotateInfo, Instigator, true)
    end

    if self.actor.OnCapture then
        self.actor:OnCapture(Instigator)
    end
end

function InteractionComponent:OnAbsorbCancel()
    G.log:debug(self.__TAG__, "OnAbsorbCancel")

    if self.actor.OnAbsorbCancel then
        self.actor:OnAbsorbCancel()
    end

    self:OnAbsorbEnd()

    local TargetComponent = self:GetMainComponent()
    TargetComponent:SetPhysicsLinearVelocity(UE.FVector())
    TargetComponent:SetPhysicsAngularVelocityInDegrees(UE.FVector())

    self:OnThrowEnd(false)
end

function InteractionComponent:OnThrow(Instigator, TargetLocation, StartLocation, ThrowMoveSpeed, EThrowType, ImpulseMag, ThrowRotateInfo)
    -- Run On Server And Client
    G.log:debug(self.__TAG__, "OnThrow by instigator %s, TargetLocation: %s, StartLocation: %s", G.GetObjectName(Instigator), TargetLocation, StartLocation)

    -- Detach capture from instigator.
    self.actor:K2_DetachFromActor(UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld)

    local TargetComponent = self:GetMainComponent()
    TargetComponent:SetPhysicsLinearVelocity(UE.FVector())
    TargetComponent:SetPhysicsAngularVelocityInDegrees(UE.FVector())

    if self.actor:IsServer() then
        self:BindCalc()
    else
        self.actor:K2_SetActorLocation(StartLocation, false, nil, true) --客户端被投掷之前修正一次位置,确保起始位置与服务端一致
    end

    self.CaptureBy = nil
    self.bAbsorb = false
    self.ThrowType = EThrowType
    if self.actor.OnThrow then
        self.actor:OnThrow(Instigator, TargetLocation, StartLocation, EThrowType, ImpulseMag, ThrowRotateInfo)
    end

    self:SendMessage("OnThrow", Instigator)

    if EThrowType == Enum.Enum_ThrowType.Spline then
        self:OnThrowUseSpline(Instigator, TargetLocation, ThrowMoveSpeed)
    elseif EThrowType == Enum.Enum_ThrowType.Physics then
        self:OnThrowUsePhysics(Instigator, TargetLocation, ImpulseMag)
    elseif EThrowType == Enum.Enum_ThrowType.Projectile then
        self:OnThrowUseProjectile(Instigator, TargetLocation)
    end

    self.bThrowing = true

    self:StartAutoRotate(ThrowRotateInfo, Instigator, false)
end

function InteractionComponent:OnThrowUseSpline(Instigator, TargetLocation, ThrowMoveSpeed)
    self:InitTimeLineAndSpline(Instigator, false, TargetLocation, ThrowMoveSpeed)
end

function InteractionComponent:StartAutoRotate(RotateInfo, Instigator, bAbsorb)
    if not RotateInfo or not RotateInfo.bEnabled then return end
    self.bAutoRotate = true
    self.bAutoRotateInAbsorb = bAbsorb
    self.RotateAxis = RotateInfo.Axis
    self.CurAngularSpeed = RotateInfo.AngularSpeed
    self.AngularAcc = RotateInfo.AngularAcc

    if RotateInfo.bInitRotation and Instigator then
        local TargetRotation = UE.UKismetMathLibrary.TransformRotation(Instigator:GetTransform(), RotateInfo.InitRelativeRotation)
        self.actor:K2_SetActorRotation(TargetRotation, true)
    end

    -- Convert rotate axis to world space.
    local SelfTransform = self.actor:GetTransform()
    self.RotateAxis = UE.UKismetMathLibrary.TransformDirection(SelfTransform, self.RotateAxis)
end

function InteractionComponent:EndAutoRotate(bAbsorb)
    if self.bAutoRotateInAbsorb ~= bAbsorb then
        return
    end

    self.bAutoRotate = false
    self.CurAngularSpeed = 0
    self.AngularAcc = 0
end

---Throw use physics, plenty issues right now. not recommended.
function InteractionComponent:OnThrowUsePhysics(Instigator, TargetLocation, ImpulseMag)
    G.log:debug(self.__TAG__, "OnThrowUsePhysics, TargetLocation: %s", TargetLocation)

    local ThrowDir = TargetLocation - self.actor:K2_GetActorLocation()
    UE.UKismetMathLibrary.Vector_Normalize(ThrowDir)
    local TargetComponent = self:GetMainComponent()
    local Mass = self:GetMass()
    local SelfLocation = self.actor:K2_GetActorLocation()

    local _, Extent = self.actor:GetActorBounds()
    local MinExtent = math.min(math.min(Extent.Z, Extent.Y), Extent.X)
    local DeltaHeight = TargetLocation.Z - SelfLocation.Z
    if DeltaHeight < 0 then
        DeltaHeight = DeltaHeight + MinExtent
    else
        DeltaHeight = DeltaHeight - MinExtent
    end

    local Dis2D = UE.UKismetMathLibrary.Vector_Distance2D(TargetLocation, SelfLocation)
    -- local ImpulseMag = self.ImpulseMag
    ImpulseMag = ImpulseMag or 1
    local Velocity2D = ImpulseMag / Mass
    local DeltaTime = Dis2D / Velocity2D

    -- v0 * t + a * t * t / 2 = height
    local Acc = GravityConst
    local VelocityVertical = (DeltaHeight - Acc * DeltaTime * DeltaTime / 2) / DeltaTime
    local ImpulseVertical = VelocityVertical * Mass

    if DeltaHeight < 0 and ImpulseVertical > 0 then
        ImpulseVertical = 0
    elseif DeltaHeight > 0 and ImpulseVertical < 0 then
        ImpulseVertical = 0
    end

    local ThrowDirIgnoreZ = UE.UKismetMathLibrary.Vector_Normal2D(ThrowDir)
    local ResImpulse = UE.FVector(ThrowDirIgnoreZ.X * ImpulseMag, ThrowDirIgnoreZ.Y * ImpulseMag, ImpulseVertical)
    if self.DrawDebug then
        UE.UKismetSystemLibrary.DrawDebugLine(self.actor, self.actor:K2_GetActorLocation(), self.actor:K2_GetActorLocation() + ThrowDir * 10000, UE.FLinearColor(0, 0, 1), 20, 5)
        UE.UKismetSystemLibrary.DrawDebugPoint(self.actor, TargetComponent:GetCenterOfMass(), 20, UE.FLinearColor(1, 1, 0), 20)
    end

    -- TODO Must add a delay before impulse, otherwise move dir not correct. Maybe caused by sync order that changed the move dir after add impulse.
    utils.DoDelay(self.actor, 0.1, function()
        -- Add offset to make torque and cause rotation.
        TargetComponent:AddImpulseAtLocation(ResImpulse, TargetComponent:GetCenterOfMass() + UE.FVector(0, 0, 50))
    end)
end

function InteractionComponent:OnThrowUseProjectile(Instigator, TargetLocation)
    G.log:debug(self.__TAG__, "OnThrowUseProjectile")
    local MainComp = self:GetMainComponent()
    local ProjectileMovement = self.actor.ProjectileMovementComponent
    ProjectileMovement:SetUpdatedComponent(MainComp)
    MainComp:SetPhysicsLinearVelocity(UE.FVector())
    MainComp:SetPhysicsAngularVelocityInDegrees(UE.FVector())

    ProjectileMovement.bIsHomingProjectile = true
    ProjectileMovement.bUseHomingTargetLocation = true
    ProjectileMovement.HomingTargetLocation = TargetLocation

    local ThrowDir = TargetLocation - self.actor:K2_GetActorLocation()
    UE.UKismetMathLibrary.Vector_Normalize(ThrowDir)
    ProjectileMovement.Velocity = ThrowDir

    local SelfLocation = self.actor:K2_GetActorLocation()
    local DeltaHeight = TargetLocation.Z - SelfLocation.Z

    local Gravity = GravityConst * ProjectileMovement.ProjectileGravityScale
    if DeltaHeight < 0 then
        local Acc = Gravity - ThrowDir.Z * ThrowDir.Z * ProjectileMovement.HomingAccelerationMagnitude
        local DeltaTime = math.sqrt(2 * DeltaHeight / Acc)
        local Dis2D = UE.UKismetMathLibrary.Vector_Distance2D(TargetLocation, SelfLocation)
        local InitSpeed = (Dis2D - 0.5 * ProjectileMovement.HomingAccelerationMagnitude * (ThrowDir.X * ThrowDir.X + ThrowDir.Y * ThrowDir.Y) * DeltaTime * DeltaTime) / DeltaTime
        ProjectileMovement.Velocity = UE.FVector(ThrowDir.X, ThrowDir.Y, 0) * InitSpeed
    else
        local Acc = math.max(math.abs(ThrowDir.Z * ThrowDir.Z * ProjectileMovement.HomingAccelerationMagnitude), -GravityConst)
        local DeltaTime = math.sqrt(2 * DeltaHeight / Acc)
        local Dis2D = UE.UKismetMathLibrary.Vector_Distance2D(TargetLocation, SelfLocation)
        local InitSpeed = (Dis2D - 0.5 * ProjectileMovement.HomingAccelerationMagnitude * (ThrowDir.X * ThrowDir.X + ThrowDir.Y * ThrowDir.Y) * DeltaTime * DeltaTime) / DeltaTime
        local InitVerticalSpeed = (DeltaHeight - 0.5 * Gravity * DeltaTime * DeltaTime) / DeltaTime
        ProjectileMovement.Velocity = UE.FVector(ThrowDir.X * InitSpeed, ThrowDir.Y * InitSpeed, InitVerticalSpeed)
    end

    ProjectileMovement.OnProjectileBounce:Add(self, self.OnProjectileBounce)
    ProjectileMovement.OnProjectileStop:Add(self, self.OnProjectileStop)
end

function InteractionComponent:OnProjectileBounce(Hit, Velocity)
    local ProjectileMovement = self.actor.ProjectileMovementComponent

    -- Stop homing to target position.
    ProjectileMovement.bIsHomingProjectile = false
end

function InteractionComponent:OnProjectileStop(Hit)
    G.log:debug(self.__TAG__, "OnProjectileStop hit: %s", G.GetObjectName(Hit.Component))

    local ProjectileMovement = self.actor.ProjectileMovementComponent
    ProjectileMovement.OnProjectileBounce:Remove(self, self.OnProjectileBounce)
    ProjectileMovement.OnProjectileStop:Remove(self, self.OnProjectileStop)

    self:EndThrow()
end

function InteractionComponent:GetMass()
    local TargetComponent = self:GetMainComponent()
    local Mass = TargetComponent:GetMass()
    local BI = TargetComponent.BodyInstance
    if BI.bOverrideMass then
        Mass = BI.MassInKgOverride
    end

    return Mass
end

function InteractionComponent:InitStaticSpline()
    local NewPoints = UE.TArray(UE.FVector)
    local PointsNum = self.Spline.Spline:GetNumberOfSplinePoints()
    local StartLocation = self.actor:K2_GetActorLocation()
    local LocationOffset = StartLocation - self.Spline.Spline:GetLocationAtSplinePoint(0, UE.ESplineCoordinateSpace.World)
    for i = 1, PointsNum do
        local OldPoint = self.Spline.Spline:GetLocationAtSplinePoint(i - 1, UE.ESplineCoordinateSpace.World)
        local NewPoint = OldPoint + LocationOffset
        NewPoints:Add(NewPoint)
    end

    self.Spline.Spline:SetSplinePoints(NewPoints, UE.ESplineCoordinateSpace.World)
end

function InteractionComponent:InitDynamicSpline(Instigator, TargetLocation)
    self:InitStaticSpline()

    local NewPoints = UE.TArray(UE.FVector)
    local PointsNum = self.Spline.Spline:GetNumberOfSplinePoints()

    -- 拉伸
    local FirstPoint = self.Spline.Spline:GetLocationAtSplinePoint(0, UE.ESplineCoordinateSpace.World)
    local LastPoint = self.Spline.Spline:GetLocationAtSplinePoint(PointsNum - 1, UE.ESplineCoordinateSpace.World)

    local LS_Forward = TargetLocation - LastPoint
    local Max_Dis = UE.UKismetMathLibrary.Vector_Distance(LastPoint, FirstPoint)

    for i = 1, PointsNum do
        local OldPoint = self.Spline.Spline:GetLocationAtSplinePoint(i - 1, UE.ESplineCoordinateSpace.World)
        local NewPoint = OldPoint
        local Forward_Scale = UE.UKismetMathLibrary.Vector_Distance(OldPoint, FirstPoint) / Max_Dis

        if i > 1 then
            NewPoint = OldPoint + LS_Forward * Forward_Scale
        end

        NewPoints:Add(NewPoint)

        if self.DrawDebug then
             UE.UKismetSystemLibrary.DrawDebugPoint(self.actor, NewPoint, 10, UE.FLinearColor(1, 0, 0), 60)
        end
    end

    self.Spline.Spline:SetSplinePoints(NewPoints, UE.ESplineCoordinateSpace.World)
end

function InteractionComponent:ThrowTargetByParabolaSpline(Instigator, TargetLocation)
    local StartLocation = self.actor:K2_GetActorLocation()
    local MidLocation = (StartLocation + TargetLocation) / 2
    MidLocation.Z = MidLocation.Z + math.abs(TargetLocation.Z - StartLocation.Z) / 4

    if self.actor:IsServer() and self.DrawDebug then
        UE.UKismetSystemLibrary.DrawDebugPoint(self.actor, StartLocation, 20, UE.FLinearColor(1, 1, 1), 10)
        UE.UKismetSystemLibrary.DrawDebugPoint(self.actor, MidLocation, 20, UE.FLinearColor(1, 1, 1), 10)
        UE.UKismetSystemLibrary.DrawDebugPoint(self.actor, TargetLocation, 20, UE.FLinearColor(1, 0, 0), 10)
    end

    local NewPoints = UE.TArray(UE.FVector)
    NewPoints:Add(StartLocation)
    NewPoints:Add(MidLocation)
    NewPoints:Add(TargetLocation)
    self.Spline.Spline:SetSplinePoints(NewPoints, UE.ESplineCoordinateSpace.World)
end

function InteractionComponent:OnThrowEnd(bIsOnFloor)
    -- Run On Server And Client
    if self.bThrowEnded then
        return
    end
    self.bThrowEnded = true
    
    G.log:debug(self.__TAG__, "OnThrowEnd")
    if self.Timeline then
        self.Timeline.Timeline:Stop()
        self.Timeline:K2_DestroyActor()
        self.Timeline = nil
    end

    if self.Spline then
        self.Spline:K2_DestroyActor()
        self.Spline = nil
    end

    if self.actor:IsServer() then
        self:UnbindCalc()
    end
    self.bThrowing = false

    self:EndAutoRotate(false)
    if self.actor and self.actor.OnThrowEnd then
        self.actor:OnThrowEnd()
    end

    if self.actor and self.bDestroyAfterCalc then
        if self.actor.OnDestroy then
            self.actor:OnDestroy()
        end
    else
        self:SetInteractable(true)
    end

    self:SendMessage("OnThrowEnd")
end

function InteractionComponent:OnTimelineUpdate(Value)
    if self.bAbsorb and self.bDynamicFollow then
        local TargetLocation = self.CaptureBy:GetSocketLocation(self.TargetSocketName)
        self:SetSplineEndToTargetLocation(TargetLocation)
    end

    local SplineDistance = Value / self.TimelineMaxValue * self.Spline:GetSplineLength()
    self:SetLocationBySplineDistance(SplineDistance)
end

function InteractionComponent:SetSplineEndToTargetLocation(TargetLocation)
    local NewPoints = UE.TArray(UE.FVector)
    NewPoints:Add(self.Spline.Spline:GetLocationAtSplinePoint(0, UE.ESplineCoordinateSpace.World))
    NewPoints:Add(TargetLocation)
    self.Spline.Spline:SetSplinePoints(NewPoints, UE.ESplineCoordinateSpace.World)
end

function InteractionComponent:SetLocationBySplineDistance(SplineDistance)
    local Transform = self.Spline:GetTransformAtDistanceAlongSpline(SplineDistance, UE.ESplineCoordinateSpace.World, false)

    local OriginLocation, OriginRotation, _ = UE.UKismetMathLibrary.BreakTransform(Transform)
    local LocationOffset = UE.FVector(0, 0, utils.GetCapsuleHalfHeight(self.actor))
    self.actor:K2_SetActorLocation(OriginLocation + LocationOffset, true, UE.FHitResult(), false)

    -- Update attached calc projectile rotation.
    if self.CalcProjectile then
        self.CalcProjectile:K2_SetActorRotation(OriginRotation, false)
    end

    if self.DrawDebug then
        local DrawColor = UE.FLinearColor(1, 0, 0)
        if self.actor:IsServer() then
            DrawColor = UE.FLinearColor(0, 1, 0)
        end
        UE.UKismetSystemLibrary.DrawDebugSphere(self.actor,OriginLocation,15,15,DrawColor,5,1)
    end
end

--function InteractionComponent:Multicast_SetOwnerLocation_RPC(Location)
--    self.actor:K2_SetActorLocation(Location, true, UE.FHitResult(), false)
--end

function InteractionComponent:OnTimelineEnd()
    if self.actor:IsClient() then
        return
    end

    if self.bAbsorb then
        self:Multicast_OnAbsorbEnd()
    else
        self:EndThrow()
    end
end

-- End absorb process.
function InteractionComponent:Multicast_OnAbsorbEnd_RPC()
    self:OnAbsorbEnd()
end

function InteractionComponent:OnAbsorbEnd()
    if not self.bAbsorb then
        return
    end
    self.bAbsorb = false
    self:EndAutoRotate(true)
    -- self.CaptureBy.InteractionComponent:CaptureTarget(self.actor)   --吸附完不应该是抓到嘛
end

function InteractionComponent:EndThrow()
    --默认传Flase,在InteractionComponentCharacter中会根据IsOnFloor()重新判断
    self:Multicast_OnThrowEnd(false)
end

function InteractionComponent:Multicast_OnThrowEnd_RPC(bIsOnFloor)
    self:OnThrowEnd(bIsOnFloor)
end

function InteractionComponent:SetUpTargetBeSelected(Value)
    self.TargetBeSelected = Value
end

function InteractionComponent:GetUpTargetBeSelected()
    return self.TargetBeSelected
end

function InteractionComponent:SetUpThrowTargetLocation(Value)
    self.ThrowTargetLocation = Value
end

function InteractionComponent:GetUpThrowTargetLocation()
    return self.ThrowTargetLocation
end

function InteractionComponent:BindCalc()
    if not UE.UKismetSystemLibrary.IsValidClass(self.CalcProjectileClass) then
        G.log:error(self.__TAG__, "Not config CalcProjectileClass, no calc.")
        return
    end

    local SourceActor = self.CaptureBy
    local StartLocation = UE.FGameplayAbilityTargetingLocationInfo()
    StartLocation.SourceActor = SourceActor
    StartLocation.LiteralTransform = self.actor:GetTransform()

    local SpawnTransform = StartLocation.LiteralTransform
    local ProjectileActor = UE.UGameplayStatics.BeginDeferredActorSpawnFromClass(self, self.CalcProjectileClass, SpawnTransform)
    ProjectileActor.StartLocation = StartLocation

    -- Set SourceActor info.
    ProjectileActor.SourceActor = SourceActor
    if SourceActor then
        ProjectileActor.SourceActorTransform = SourceActor:GetTransform()
    end
    ProjectileActor.BindActor = self.actor

    -- Set GEs spec
    self.CalcEffectsHandle:Clear()
    for Ind = 1, self.GameplayEffects:Length() do
        local ASC = self.actor.AbilitySystemComponent
        self.CalcEffectsHandle:AddUnique(ASC:MakeOutgoingSpec(self.GameplayEffects:Get(Ind), 1, UE.FGameplayEffectContextHandle()))
    end
    ProjectileActor.GameplayEffectsHandle = self.CalcEffectsHandle

    -- Set KnockInfo
    ProjectileActor.KnockInfo = SkillUtils.KnockInfoStructToObject(self.KnockInfo)

    ProjectileActor:Init()
    UE.UGameplayStatics.FinishSpawningActor(ProjectileActor, SpawnTransform)

    self.CalcProjectile = ProjectileActor
    self.CalcProjectile:RegisterDestroyCallback(self, self.OnCalcProjectileDestroy)
    self.CalcProjectile:RegisterHitCallback(self, self.OnHitTarget)
end

function InteractionComponent:UnbindCalc()
    if self.CalcProjectile then
        self.CalcProjectile:DestroySelf()
        self.CalcProjectile = nil
    end
end

function InteractionComponent:OnCalcProjectileDestroy()
    self.CalcProjectile = nil
    self:EndThrow()

    if self.actor.DestructComponent then
        self.actor.DestructComponent:Multicast_OnBreak(nil , nil, UE.FHitResult(), 0)
    end
end

function InteractionComponent:OnHitTarget(ObjectType, Hit, ApplicationTag, bDestroy)
    self:Multicast_OnHitTarget(Hit, bDestroy)
end

function InteractionComponent:Multicast_OnHitTarget_RPC(Hit, bDestroy)
    if Hit then
        G.log:debug(self.__TAG__, "Multicast_OnHitTarget actor: %s, bDestroy: %s", G.GetObjectName(Hit.HitObjectHandle.Actor), bDestroy)
    end

    if self.actor.OnHit then
        self.actor:OnHit(nil, nil, Hit, 0, 0)
    end
end

function InteractionComponent:SetInteractable(bInteractable)
    self.bInteractable = bInteractable
end

function InteractionComponent:IsInteractable()
    return self.bInteractable
end

function InteractionComponent:ReceiveTick(DeltaSeconds)
    if self.actor.RushBy then
        self.actor:K2_SetActorLocation(UE.UKismetMathLibrary.TransformLocation(self.actor.RushBy:GetTransform(), self.actor.RushByRelativeLocation), true, nil, false)
    end

    --  started when speed not zero, and ended when speed nearly zero.
    if self:IsStopCalcWhenZeroSpeed() and self.CalcProjectile and self.bThrowing then
        local MainComponent = self:GetMainComponent()
        local LinearVelocity = MainComponent:GetPhysicsLinearVelocity()
        local AngularVelocity = MainComponent:GetPhysicsAngularVelocityInDegrees()
        if UE.UKismetMathLibrary.VSize(LinearVelocity) < CalcLinearSpeedThreshold and UE.UKismetMathLibrary.VSize(AngularVelocity) < CalcAngularSpeedThreshold then
            if self.bStarted or utils.GetSecondsElapsed(self.ThrowingBeginTime, UE.UKismetMathLibrary.Now()) > self.MaxStartedCheckTime then
                self:UnbindCalc()
                self.bThrowing = false

                -- Call destroy on ended.
                self:OnHitTarget(nil, UE.FHitResult(), "", true)
            end
        else
            self.bStarted = true
        end
    end

    if self.bAutoRotate then
        local DeltaAngular = self.CurAngularSpeed * DeltaSeconds
        local SelfRotation = self.actor:K2_GetActorRotation()
        local DeltaRotator = UE.UKismetMathLibrary.RotatorFromAxisAndAngle(self.RotateAxis, DeltaAngular)
        local NewRotation = UE.UKismetMathLibrary.ComposeRotators(SelfRotation, DeltaRotator)
        self.actor:K2_SetActorRotation(NewRotation, true)

        local PrevSpeed = self.CurAngularSpeed
        self.CurAngularSpeed = self.CurAngularSpeed + self.AngularAcc * DeltaSeconds
        if self.CurAngularSpeed * PrevSpeed < 0 then
            self:EndAutoRotate(self.bAbsorb)
        end
    end
end

function InteractionComponent:IsStopCalcWhenZeroSpeed()
    return self.ThrowType == Enum.Enum_ThrowType.Physics
end

decorator.message_receiver()
function InteractionComponent:ReceiveAsyncPhysicsTick(DeltaSeconds, SimSeconds)

end

function InteractionComponent:GetMainComponent()
    local TargetComponent = self.actor:K2_GetRootComponent()
    if self.actor.GetTargetComponent then
        TargetComponent = self.actor:GetTargetComponent()
    end

    return TargetComponent
end

--[[
    Rush attach
]]
function InteractionComponent:OnRushAttach(Instigator)
    self:Multicast_OnRushAttach(Instigator)
end

function InteractionComponent:Multicast_OnRushAttach_RPC(Instigator)
    G.log:debug(self.__TAG__, "OnRushAttach IsServer: %s, self: %s, instigator: %s", self.actor:IsServer(), G.GetDisplayName(self.actor), G.GetDisplayName(Instigator))

    self.actor.CharacterStateManager:SetRushAttach(true)
    self.actor.RushBy = Instigator
    self.actor.RushByRelativeLocation = UE.UKismetMathLibrary.InverseTransformLocation(Instigator:GetTransform(), self.actor:K2_GetActorLocation())
end

function InteractionComponent:OnEndRushAttach(Instigator)
    self:Multicast_OnEndRushAttach(Instigator)
end

function InteractionComponent:Multicast_OnEndRushAttach_RPC(Instigator)
    G.log:debug(self.__TAG__, "OnEndRushAttach IsServer: %s, self: %s, instigator: %s", self.actor:IsServer(), G.GetDisplayName(self.actor), G.GetDisplayName(Instigator))

    self:TryEndRushAttach()
end

decorator.engine_callback()
function InteractionComponent:OnLand()
    G.log:debug(self.__TAG__, "Actor: %s OnLand IsServer: %s", G.GetObjectName(self.actor), self.actor:IsServer())

    self:TryEndRushAttach()
end

function InteractionComponent:TryEndRushAttach()
    if not self.actor.RushBy then
        return
    end

    if self.actor.CharacterStateManager and self.actor.CharacterStateManager:IsRushAttach() then
        self.actor.CharacterStateManager:SetRushAttach(false)
    end

    self.actor.RushBy = nil
end

decorator.message_receiver()
function InteractionComponent:OnEnterTrap(TrapActor)
end

decorator.message_receiver()
function InteractionComponent:OnLeaveTrap(TrapActor)
end


decorator.message_receiver()
function InteractionComponent:Client_OnEnterTrap(TrapActor)
end

decorator.message_receiver()
function InteractionComponent:Client_OnLeaveTrap(TrapActor)
end

return InteractionComponent
