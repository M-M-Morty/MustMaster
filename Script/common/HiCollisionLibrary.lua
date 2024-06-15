require "UnLua"

local G = require("G")
local switches = require("switches")

local SkillUtils = require("common.skill_utils")

HiCollisionLibrary = {}

function HiCollisionLibrary:InitCollisionObjectTypes()
     self.DefaultCollisionObjectTypes = UE.TArray(UE.EObjectTypeQuery)
     self.DefaultCollisionObjectTypes:Add(UE.EObjectTypeQuery.Pawn)
     self.DefaultCollisionObjectTypes:Add(UE.EObjectTypeQuery.MountActor)
     self.DefaultCollisionObjectTypes:Add(UE.EObjectTypeQuery.Destructible)
     self.DefaultCollisionObjectTypes:Add(UE.EObjectTypeQuery.PhysicsBody)
     -- self.DefaultCollisionObjectTypes:Add(UE.EObjectTypeQuery.Blast)
end

HiCollisionLibrary:InitCollisionObjectTypes()

-- Perform overlaps with specified target actor spec.
function HiCollisionLibrary.PerformOverlapComponents(WorldContextObject, TargetActorSpec, Origin, ForwardVector, ObjectTypes, ActorsToIgnore, Hits, bDebug)
    if not switches.TraceDebug then
        bDebug = false
    end

    local CalcRangeType = TargetActorSpec.CalcRangeType
    local OutComponents = UE.TArray(UE.UPrimitiveComponent)

    if not ObjectTypes or ObjectTypes:Length() == 0 then
        ObjectTypes = HiCollisionLibrary.DefaultCollisionObjectTypes
    end

    if CalcRangeType == Enum.Enum_CalcRangeType.Circle then
        UE.UHiCollisionLibrary.SphereOverlapComponents(WorldContextObject, ObjectTypes, Origin, TargetActorSpec.Radius, TargetActorSpec.UpHeight, TargetActorSpec.DownHeight, nil, ActorsToIgnore, OutComponents, bDebug)
    elseif CalcRangeType == Enum.Enum_CalcRangeType.Section then
        local SectionRadian = UE.UKismetMathLibrary.DegreesToRadians(TargetActorSpec.Angle)
        UE.UHiCollisionLibrary.SectionOverlapComponents(WorldContextObject, ObjectTypes, Origin, ForwardVector, TargetActorSpec.Radius, SectionRadian, TargetActorSpec.UpHeight, TargetActorSpec.DownHeight, nil, ActorsToIgnore, OutComponents, bDebug)
    elseif CalcRangeType == Enum.Enum_CalcRangeType.Rect then
        UE.UHiCollisionLibrary.BoxOverlapComponents(WorldContextObject, ObjectTypes, Origin, ForwardVector, TargetActorSpec.Length, TargetActorSpec.HalfWidth, TargetActorSpec.UpHeight, TargetActorSpec.DownHeight, nil, ActorsToIgnore, OutComponents, false, bDebug)
    else
        return
    end

    -- Filter and limit single calc count.
    local OutHits = SkillUtils.MakeHitResultsFromComponents(OutComponents, Origin)
    Hits:Append(OutHits)
end

function HiCollisionLibrary.PerformOverlapActors(WorldContextObject, Origin, ForwardVector, RangeType, Radius, Angle, Length, HalfWidth, UpHeight, DownHeight, ObjectTypes, bDebug, LifeTime)
    if not switches.TraceDebug then
        bDebug = false
    end

    local ActorsToIgnore = UE.TArray(UE.AActor)
    local OutActors = UE.TArray(UE.AActor)

    if not ObjectTypes or ObjectTypes:Length() == 0 then
        ObjectTypes = HiCollisionLibrary.DefaultCollisionObjectTypes
    end

    if RangeType == Enum.Enum_CalcRangeType.Circle then
        UE.UHiCollisionLibrary.SphereOverlapActors(WorldContextObject, ObjectTypes, Origin, Radius, UpHeight, DownHeight, nil, ActorsToIgnore, OutActors, bDebug, LifeTime)
    elseif RangeType == Enum.Enum_CalcRangeType.Section then
        local SectionRadian = UE.UKismetMathLibrary.DegreesToRadians(Angle)
        UE.UHiCollisionLibrary.SectionOverlapActors(WorldContextObject, ObjectTypes, Origin, ForwardVector, Radius, SectionRadian, UpHeight, DownHeight, nil, ActorsToIgnore, OutActors, bDebug, LifeTime)
    elseif RangeType == Enum.Enum_CalcRangeType.Rect then
        UE.UHiCollisionLibrary.BoxOverlapActors(WorldContextObject, ObjectTypes, Origin, ForwardVector, Length, HalfWidth, UpHeight, DownHeight, nil, ActorsToIgnore, OutActors, false, bDebug, LifeTime)
    end

    return OutActors
end

function HiCollisionLibrary.PerformSweep(WorldContextObject, TargetActorSpec, OriginLocation, OriginRotation, SweepDis, ForwardVector, ObjectTypes, ActorsToIgnore, Hits, DebugType)
    if not switches.TraceDebug then
        DebugType = UE.EDrawDebugTrace.None
    end
    
    local CalcRangeType = TargetActorSpec.CalcRangeType
    if not ActorsToIgnore then
        ActorsToIgnore = UE.TArray(UE.AActor)
    end
    local OutHits = UE.TArray(UE.FHitResult)
    if not SweepDis or SweepDis <= 0 then
        SweepDis = 20
    end
    local EndLocation = OriginLocation + ForwardVector * SweepDis

    if not ObjectTypes or ObjectTypes:Length() == 0 then
        ObjectTypes = HiCollisionLibrary.DefaultCollisionObjectTypes
    end

    if CalcRangeType == Enum.Enum_CalcRangeType.Circle then
        UE.UKismetSystemLibrary.SphereTraceMultiForObjects(WorldContextObject, OriginLocation, EndLocation, TargetActorSpec.Radius, ObjectTypes, true, ActorsToIgnore, DebugType, OutHits, true)
    elseif CalcRangeType == Enum.Enum_CalcRangeType.Rect then
        local HalfSize = UE.FVector(TargetActorSpec.Length / 2, TargetActorSpec.HalfWidth, (TargetActorSpec.UpHeight + TargetActorSpec.DownHeight) / 2);
        local BoxForwardVector = UE.UKismetMathLibrary.GetForwardVector(OriginRotation)
        BoxForwardVector.Z = 0
        BoxForwardVector = UE.UKismetMathLibrary.Normal(BoxForwardVector)
        local BoxLocation = UE.FVector(OriginLocation.X, OriginLocation.Y, TargetActorSpec.UpHeight + OriginLocation.Z - (TargetActorSpec.UpHeight + TargetActorSpec.DownHeight) / 2) + BoxForwardVector * TargetActorSpec.Length / 2
        EndLocation = BoxLocation + ForwardVector * SweepDis
        if DebugType == UE.EDrawDebugTrace.ForDuration then
            UE.UKismetSystemLibrary.DrawDebugPoint(WorldContextObject, OriginLocation, 30, UE.FLinearColor(1, 0, 0), 30)
            UE.UKismetSystemLibrary.DrawDebugArrow(WorldContextObject, BoxLocation, EndLocation, 5, UE.FLinearColor(0, 1, 0), 30, 5)
        end
        UE.UKismetSystemLibrary.BoxTraceMultiForObjects(WorldContextObject, BoxLocation, EndLocation, HalfSize, OriginRotation, ObjectTypes, true, ActorsToIgnore, DebugType, OutHits, true)
    elseif CalcRangeType == Enum.Enum_CalcRangeType.Section then
        UE.UKismetSystemLibrary.SphereTraceMultiForObjects(WorldContextObject, OriginLocation, EndLocation, TargetActorSpec.Radius, ObjectTypes, true, ActorsToIgnore, DebugType, OutHits, true)

        -- Check in angle.
        local Ind = 1
        while Ind <= OutHits:Length() do
            local HitResult = OutHits:Get(Ind)
            if not UE.UHiCollisionLibrary.CheckInSection(HitResult.ImpactPoint, OriginLocation, ForwardVector, UE.UKismetMathLibrary.DegreesToRadians(TargetActorSpec.Angle)) then
                OutHits:Remove(Ind)
            else
                Ind = Ind + 1
            end
        end
    end

    -- Handle TraceMulti return same components multi times.
    OutHits = UniqueHits(OutHits)

    -- Check in height.
    local Ind = 1
    while Ind <= OutHits:Length() do
        local HitResult = OutHits:Get(Ind)
        local CurComp = HitResult.Component
        local CompLoc, CompBounds = UE.UKismetSystemLibrary.GetComponentBounds(CurComp)
        if not UE.UHiCollisionLibrary.CheckInHeightZ(OriginLocation.Z, CompLoc.Z + CompBounds.Z, CompLoc.Z - CompBounds.Z, TargetActorSpec.UpHeight, TargetActorSpec.DownHeight) then
            OutHits:Remove(Ind)
        else
            Ind = Ind + 1
        end
    end

    Hits:Append(OutHits)
end

function UniqueHits(Hits)
    local OutHits = UE.TArray(UE.FHitResult)
    local Components = UE.TSet(UE.UPrimitiveComponent)
    for Ind = 1, Hits:Length() do
        local CurHit = Hits:Get(Ind)
        -- not check valid blocking hit as calc range may init penetrating with target.
        if CurHit.Component and not Components:Contains(CurHit.Component) then
            OutHits:Add(CurHit)
            Components:Add(CurHit.Component)
        end
    end

    return OutHits
end

-- DEPRECATED! Filter moved to CalcComponent
function HiCollisionLibrary.CheckFilterAndLimit(Hits, TargetFilter, CalcTargetLimit)
    local OutHits = UE.TArray(UE.FHitResult)
    local HitActors = UE.TArray(UE.AActor)
    for Ind = 1, Hits:Length() do
        local CurHit = Hits:Get(Ind)
        local CurComp = CurHit.Component
        local CurActor = CurComp:GetOwner()
        if CalcTargetLimit > 0 and HitActors:Length() >= CalcTargetLimit then
            break
        end

        -- TODO IsDead check should be in TargetFilter.
        if CurActor and TargetFilter:FilterActor(CurActor)
                and HitActors:Find(CurActor) == 0 then
            OutHits:AddUnique(CurHit)
            HitActors:AddUnique(CurActor)
        end
    end

    return OutHits
end

return HiCollisionLibrary
