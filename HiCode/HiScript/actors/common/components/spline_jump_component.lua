local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

local SplineJumpComponent = Component(ComponentBase)
local decorator = SplineJumpComponent.decorator

function SplineJumpComponent:Initialize(...)
    Super(SplineJumpComponent).Initialize(self, ...)
end

function SplineJumpComponent:Start()
    Super(SplineJumpComponent).Start(self)
end

function SplineJumpComponent:ReceiveBeginPlay()
    Super(SplineJumpComponent).ReceiveBeginPlay(self)
    G.log:debug("SplineJumpComponent", "ReceiveBeginPlay.%s", self.actor:GetDisplayName())

    if self.ThrowTimeline == nil then
        local SpawnParameters = UE.FActorSpawnParameters()
        self.ThrowTimeline = GameAPI.SpawnActor(self.actor:GetWorld(), self.ThrowTimelineClass, self.actor:GetTransform(), SpawnParameters, {})
        self.ThrowTimeline.InteractionComponent = self

        local MinValue, MaxValue = UE.UHiUtilsFunctionLibrary.GetTimelineValueRange(self.ThrowTimeline.Timeline)
        self.TimelineMaxValue = MaxValue
    end

    if self.ThrowSpline == nil then
        local SpawnParameters = UE.FActorSpawnParameters()
        self.ThrowSpline = GameAPI.SpawnActor(self.actor:GetWorld(), self.ThrowSplineClass, self.actor:GetTransform(), SpawnParameters, {})
    end
end

function SplineJumpComponent:ReceiveEndPlay(EndPlayReason)
    G.log:debug("SplineJumpComponent", "ReceiveEndPlay.%s", self.actor:GetDisplayName())

    if self.ThrowTimeline then
        self.ThrowTimeline.Timeline:Stop()
        self.ThrowTimeline:K2_DestroyActor()
    end

    if self.ThrowSpline then
        self.ThrowSpline:K2_DestroyActor()
    end

    Super(SplineJumpComponent).ReceiveEndPlay(self)
end

function SplineJumpComponent:OnTimelineUpdate(Value)
    -- Call From BP

    if self.SplineTargetActor then
        self:FollowTarget()
    end

    local SplineDistance = Value / self.TimelineMaxValue * self.ThrowSpline:GetSplineLength()
    self:SetLocationBySplineDistance(SplineDistance)
end

function SplineJumpComponent:SetLocationBySplineDistance(SplineDistance)

    local Transform = self.ThrowSpline:GetTransformAtDistanceAlongSpline(SplineDistance, UE.ESplineCoordinateSpace.World, false)

    local OriginLocation, OriginRotation, _ = UE.UKismetMathLibrary.BreakTransform(Transform)
    self.actor:K2_SetActorLocationAndRotation(OriginLocation, OriginRotation, false, UE.FHitResult(), true)

    if self.DrawDebug then
        UE.UKismetSystemLibrary.DrawDebugPoint(self.actor, OriginLocation, 5, UE.FLinearColor(0, 0, 1), 10)
        -- G.log:debug("yj", "SetLocationBySplineDistance OriginLocation.%s SplineLocation.%s", OriginLocation, OriginLocation + self.ThrowStart)
    end
end

function SplineJumpComponent:OnTimelineEnd()
    self:OnThrowEnd()
end

function SplineJumpComponent:OnThrowEnd()
    self.ThrowTimeline.Timeline:Stop()

    if self.actor and self.actor.OnThrowEnd then
        self.actor:OnThrowEnd()
    end
end

function SplineJumpComponent:Server_JumpToTarget_RPC(TargetActor)
    if TargetActor == nil then
        local t = require("t")
        TargetActor = t.MovePlatformActor or t.ms
    end
    self:JumpToTarget(TargetActor)
end

function SplineJumpComponent:JumpToTarget(TargetActor)
    -- 定点跳跃
    self.SplineTargetActor = TargetActor

    local NewPoints = UE.TArray(UE.FVector)
    local StartLocation = self.actor:K2_GetActorLocation()
    local TargetLocation = TargetActor.StaticMesh:K2_GetComponentLocation()
    local MidX = (StartLocation.X + TargetLocation.X) / 2
    local MidY = (StartLocation.Y + TargetLocation.Y) / 2
    local MidZ = (StartLocation.Z + TargetLocation.Z) / 2 + (TargetLocation - StartLocation):Size() / 5
    local MidLocation = UE.FVector(MidX, MidY, MidZ)

    NewPoints:Add(StartLocation)
    NewPoints:Add(MidLocation)
    NewPoints:Add(TargetLocation + UE.FVector(0, 0, 20))

    self.ThrowSpline.Spline:SetSplinePoints(NewPoints, UE.ESplineCoordinateSpace.World)

    self.actor:OnCapture(self.actor)

    -- 定点跳跃不能设置朝向
    -- self.ThrowSpline.Spline:K2_SetWorldRotation(Instigator:K2_GetActorRotation(), true, UE.FHitResult(), false)

    -- 设置播放倍率
    local TimelinePlayRate = self.ThrowTimeline.Timeline:GetTimelineLength() / self.MoveTime
    self.ThrowTimeline.Timeline:SetPlayRate(TimelinePlayRate)
    self.ThrowTimeline.Timeline:PlayFromStart()

    self.actor:OnThrow(self.actor)
end

function SplineJumpComponent:FollowTarget()
    local StartLocation = self.ThrowSpline.Spline:GetLocationAtSplinePoint(0, UE.ESplineCoordinateSpace.World)

    local NewPoints = UE.TArray(UE.FVector)
    local TargetLocation = self.SplineTargetActor.StaticMesh:K2_GetComponentLocation()
    local MidX = (StartLocation.X + TargetLocation.X) / 2
    local MidY = (StartLocation.Y + TargetLocation.Y) / 2
    local MidZ = (StartLocation.Z + TargetLocation.Z) / 2 + (TargetLocation - StartLocation):Size() / 5
    local MidLocation = UE.FVector(MidX, MidY, MidZ)

    NewPoints:Add(StartLocation)
    NewPoints:Add(MidLocation)
    NewPoints:Add(TargetLocation + UE.FVector(0, 0, 20))

    self.ThrowSpline.Spline:SetSplinePoints(NewPoints, UE.ESplineCoordinateSpace.World)
end

return SplineJumpComponent
