local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local check_table = require("common.data.state_conflict_data")
local G = require("G")

local SplineTimelineComponent = Component(ComponentBase)

local decorator = SplineTimelineComponent.decorator

function SplineTimelineComponent:Initialize(...)
    Super(SplineTimelineComponent).Initialize(self, ...)
end

function SplineTimelineComponent:ReceiveBeginPlay()
    Super(SplineTimelineComponent).ReceiveBeginPlay(self)
end

function SplineTimelineComponent:ReceiveEndPlay(EndPlayReason)
	self:DestroySplineAndTimeline()
    Super(SplineTimelineComponent).ReceiveEndPlay(self, EndPlayReason)
end

decorator.message_receiver()
function SplineTimelineComponent:CreateSplineAndTimeline(Transform, IsRebound)
	self:DestroySplineAndTimeline()

    local TimelineClass = self.MoveTimelineClass
    if IsRebound then
        TimelineClass = self.MoveTimelineClass_Rebound
    end

    if TimelineClass ~= nil then
        local SpawnParameters = UE.FActorSpawnParameters()
        self.Timeline = GameAPI.SpawnActor(self.actor:GetWorld(), TimelineClass, Transform, SpawnParameters, {})
        self.Timeline:RegisterTimelineUpdateCallback(self, self.OnTimelineUpdate)
        self.Timeline:RegisterTimelineEndCallback(self, self.OnTimelineEnd)

        local MinValue, MaxValue = UE.UHiUtilsFunctionLibrary.GetTimelineValueRange(self.Timeline.Timeline)
        self.TimelineMaxValue = MaxValue
    end

    local SplineClass = self.MoveSplineClass
    if IsRebound then
        SplineClass = self.MoveSplineClass_Rebound
    end

    if SplineClass ~= nil then
        local SpawnParameters = UE.FActorSpawnParameters()
        self.Spline = GameAPI.SpawnActor(self.actor:GetWorld(), SplineClass, Transform, SpawnParameters, {})
    end

    self:MoveSplineToOwner()

    self.LastTimelineUpdateMs = G.GetNowTimestampMs()

    -- 设置播放倍率
    local MoveTime = self.Spline:GetSplineLength() / self.MoveSpeed
    local TimelinePlayRate = self.Timeline.Timeline:GetTimelineLength() / MoveTime
    self.Timeline.Timeline:SetPlayRate(TimelinePlayRate)
    self.Timeline.Timeline:PlayFromStart()
end

function SplineTimelineComponent:DestroySplineAndTimeline()
    if self.Timeline ~= nil then
        self.Timeline.Timeline:Stop()
        self.Timeline:K2_DestroyActor()
        self.Timeline = nil
    end

    if self.Spline ~= nil then
        self.Spline:K2_DestroyActor()
        self.Spline = nil
    end
end

function SplineTimelineComponent:OnTimelineUpdate(Value)
    -- Call From BP
    local SplineDistance = Value / self.TimelineMaxValue * self.Spline:GetSplineLength()
    self:SetLocationBySplineDistance(SplineDistance)
end

function SplineTimelineComponent:SetLocationBySplineDistance(SplineDistance)
    local Transform = self.Spline:GetTransformAtDistanceAlongSpline(SplineDistance, UE.ESplineCoordinateSpace.World, false)
    local TargetLocation, _, _ = UE.UKismetMathLibrary.BreakTransform(Transform)

    local NowMs = G.GetNowTimestampMs()
    local DeltaSeconds = (NowMs - self.LastTimelineUpdateMs) / 1000
    utils.SmoothActorLocation(self.actor, TargetLocation, 30000, DeltaSeconds)
    self.LastTimelineUpdateMs = NowMs

    if self.DrawDebug then
        local DrawColor = UE.FLinearColor(1, 0, 0)
        if self.actor:IsServer() then
            DrawColor = UE.FLinearColor(0, 1, 0)
        end
        UE.UKismetSystemLibrary.DrawDebugPoint(self.actor, TargetLocation, 20, DrawColor, 5)
    end
end

function SplineTimelineComponent:OnTimelineEnd()
end

decorator.message_receiver()
function SplineTimelineComponent:UpdateSplineTargetLocation(TargetLocation)
	-- if self.LastTargetLocation ~= nil and UE.UKismetMathLibrary.Vector_Distance(self.LastTargetLocation, TargetLocation) < 50 then
	-- 	return
	-- end
	self:ZoomSplineByTargetLocation(TargetLocation)
	-- self.LastTargetLocation = TargetLocation
end

function SplineTimelineComponent:MoveSplineToOwner()

    -- 坐标转换（初始位置+偏移）
    local NewPoints = UE.TArray(UE.FVector)
    local PointsNum = self.Spline.Spline:GetNumberOfSplinePoints()
    local StartLocation = self.actor:K2_GetActorLocation()
    local LocationOffset = StartLocation - self.Spline.Spline:GetLocationAtSplinePoint(0, UE.ESplineCoordinateSpace.World)
    for i = 1, PointsNum do
        local OldPoint = self.Spline.Spline:GetLocationAtSplinePoint(i - 1, UE.ESplineCoordinateSpace.World)
        local NewPoint = OldPoint + LocationOffset
        NewPoints:Add(NewPoint)

        if self.actor:IsServer() and self.DrawDebug then
            G.log:debug("yj", "==============================================================================")
            G.log:debug("yj", "111 ### X - OldPoint.%s -> NewPoint.%s", OldPoint, NewPoint)
            -- UE.UKismetSystemLibrary.DrawDebugPoint(self.actor, NewPoints:Get(i), 20, UE.FLinearColor(1, 1, 1), 60)
        end
    end

    self.Spline.Spline:SetSplinePoints(NewPoints, UE.ESplineCoordinateSpace.World)
end

function SplineTimelineComponent:ZoomSplineByTargetLocation(TargetLocation)
	-- G.log:debug("yj", "SplineTimelineComponent:ZoomSplineByTargetLocation %s", TargetLocation)
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

        if self.actor:IsServer() and self.DrawDebug then
            G.log:debug("yj", "==============================================================================")
            G.log:debug("yj", "111 @@@ X - FX.%s OX.%s %s -> NX.%s", FirstPoint.X, OldPoint.X, Forward_Scale, NewPoint.X)
            G.log:debug("yj", "222 @@@ Y - FY.%s OY.%s %s -> NY.%s", FirstPoint.Y, OldPoint.Y, Forward_Scale, NewPoint.Y)
            G.log:debug("yj", "333 @@@ Z - FZ.%s OZ.%s %s -> NZ.%s", FirstPoint.Z, OldPoint.Z, Forward_Scale, NewPoint.Z)
            -- UE.UKismetSystemLibrary.DrawDebugPoint(self.actor, NewPoint, 20, UE.FLinearColor(1, 0, 0), 10)
        end
    end

    self.Spline.Spline:SetSplinePoints(NewPoints, UE.ESplineCoordinateSpace.World)
    local MoveTime = self.Spline:GetSplineLength() / self.MoveSpeed
    local TimelinePlayRate = self.Timeline.Timeline:GetTimelineLength() / MoveTime
    self.Timeline.Timeline:SetPlayRate(TimelinePlayRate)
end


return SplineTimelineComponent
