require "UnLua"

local G = require("G")
local HiCollisionLibrary = require("common.HiCollisionLibrary")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local SkillUtils = require("common.skill_utils")
local TargetFilter = require("actors.common.TargetFilter")

local CheatCheckComponent = Component(ComponentBase)
local decorator = CheatCheckComponent.decorator

function CheatCheckComponent:Initialize(...)
    Super(CheatCheckComponent).Initialize(self, ...)
end

function CheatCheckComponent:Start()
    Super(CheatCheckComponent).Start(self)
end

decorator.message_receiver()
function CheatCheckComponent:TargetDataCheatCheck(TargetDataHandle)

    G.log:debug("skilllog", "CheatCheckComponent:TargetDataCheatCheck %s", self.actor.CheatCheck)

    if not self.actor.CheatCheck then
        self.actor.TargetDataHandle = TargetDataHandle
    	return
    end

    -- TODO handle KnockInfo in TargetData.
    if self.actor.bDebug then
        local Count = UE.UAbilitySystemBlueprintLibrary.GetDataCountFromTargetData(TargetDataHandle)
        for Ind = 1, Count do
            local HitResult = UE.UAbilitySystemBlueprintLibrary.GetHitResultFromTargetData(TargetDataHandle, Ind - 1)
            local CurActor = HitResult.Component:GetOwner()
            local TargetLocation = CurActor:K2_GetActorLocation()
            -- 中心点
            UE.UKismetSystemLibrary.DrawDebugPoint(self.actor, TargetLocation, 20, UE.FLinearColor(0, 0, 1), 2)
            -- 胶囊体
            if CurActor.CapsuleComponent then
                UE.UKismetSystemLibrary.DrawDebugSphere(self.actor:GetWorld(), TargetLocation, CurActor.CapsuleComponent.CapsuleRadius, 10, UE.FLinearColor.White, 2, 3.0)
            end
        end
    end

    TargetDataHandle = self:TargetDataCheatCheck_CollisionType(TargetDataHandle)

    if self.actor.Spec.CalcRangeType == Enum.Enum_CalcRangeType.Circle then
        TargetDataHandle = self:TargetDataCheatCheck_Circle(TargetDataHandle)
    elseif self.actor.Spec.CalcRangeType == Enum.Enum_CalcRangeType.Section then
        TargetDataHandle = self:TargetDataCheatCheck_Section(TargetDataHandle)
    elseif self.actor.Spec.CalcRangeType == Enum.Enum_CalcRangeType.Rect then
        TargetDataHandle = self:TargetDataCheatCheck_Rect(TargetDataHandle)
    end

    self.actor.TargetDataHandle = TargetDataHandle
end

function CheatCheckComponent:TargetDataCheatCheck_CollisionType(TargetDataHandle)
    -- Check collision type
    local HitResults = UE.TArray(UE.FHitResult)
    local Count = UE.UAbilitySystemBlueprintLibrary.GetDataCountFromTargetData(TargetDataHandle)
    for Ind = 1, Count do
        local HitResult = UE.UAbilitySystemBlueprintLibrary.GetHitResultFromTargetData(TargetDataHandle, Ind - 1)
        local CurActor = HitResult.Component:GetOwner()

        if CurActor.CapsuleComponent then
            local CollisionType = CurActor.CapsuleComponent:GetCollisionObjectType()
            for Ind = 1, HiCollisionLibrary.CollisionObjectTypes:Length() do
                if CollisionType == HiCollisionLibrary.CollisionObjectTypes:Get(Ind) then
                    HitResults:AddUnique(HitResult)
                    break
                end
            end
        end
    end
    
    TargetDataHandle = UE.UHiUtilsFunctionLibrary.AbilityTargetDataFromHitResults(HitResults)

    return TargetDataHandle
end

function CheatCheckComponent:TargetDataCheatCheck_Circle(TargetDataHandle)
    local TargetActorSpec = self.actor.Spec

    local OriginLocation = UE.FVector()
    local OriginRotation = UE.FRotator()
    UE.UKismetMathLibrary.BreakTransform(self.actor.StartLocation.LiteralTransform, OriginLocation, OriginRotation, UE.FVector())

    -- Check in radius.
    local HitResults = UE.TArray(UE.FHitResult)
    local Count = UE.UAbilitySystemBlueprintLibrary.GetDataCountFromTargetData(TargetDataHandle)
    for Ind = 1, Count do
        local HitResult = UE.UAbilitySystemBlueprintLibrary.GetHitResultFromTargetData(TargetDataHandle, Ind - 1)
        local CurActor = HitResult.Component:GetOwner()
        local TargetLocation = CurActor:K2_GetActorLocation()
        local Distance = UE.UKismetMathLibrary.Vector_Distance(TargetLocation, OriginLocation)
        
        local Radius = TargetActorSpec.Radius
        if CurActor.CapsuleComponent then
            Radius = Radius + CurActor.CapsuleComponent.CapsuleRadius
        end

        if Distance < Radius then
            HitResults:AddUnique(HitResult)
        end
    end

    -- Check in height.
    local Ind = 1
    while Ind <= HitResults:Length() do
        local HitResult = HitResults:Get(Ind)
        local TargetLocation = HitResult.Component:GetOwner():K2_GetActorLocation()
        if not UE.UHiCollisionLibrary.CheckInHeight(TargetLocation, OriginLocation, TargetActorSpec.UpHeight, TargetActorSpec.DownHeight) then
            HitResults:Remove(Ind)
        else
            Ind = Ind + 1
        end
    end

    TargetDataHandle = UE.UHiUtilsFunctionLibrary.AbilityTargetDataFromHitResults(HitResults)

    return TargetDataHandle
end

function CheatCheckComponent:TargetDataCheatCheck_Section(TargetDataHandle)

    local TargetActorSpec = self.actor.Spec

    local OriginLocation = UE.FVector()
    local OriginRotation = UE.FRotator()
    UE.UKismetMathLibrary.BreakTransform(self.actor.StartLocation.LiteralTransform, OriginLocation, OriginRotation, UE.FVector())
    local ForwardVector = UE.UKismetMathLibrary.Conv_RotatorToVector(OriginRotation)

    -- Check in angle.
    local HitResults = UE.TArray(UE.FHitResult)
    TargetDataHandle = self:TargetDataCheatCheck_Circle(TargetDataHandle)
    local Count = UE.UAbilitySystemBlueprintLibrary.GetDataCountFromTargetData(TargetDataHandle)
    for Ind = 1, Count do
        local HitResult = UE.UAbilitySystemBlueprintLibrary.GetHitResultFromTargetData(TargetDataHandle, Ind - 1)
        local TargetLocation = HitResult.Component:GetOwner():K2_GetActorLocation()
        if UE.UHiCollisionLibrary.CheckInSection(TargetLocation, OriginLocation, ForwardVector, UE.UKismetMathLibrary.DegreesToRadians(TargetActorSpec.Angle)) then
            HitResults:AddUnique(HitResult)
        end
    end

    TargetDataHandle = UE.UHiUtilsFunctionLibrary.AbilityTargetDataFromHitResults(HitResults)

    return TargetDataHandle
end

function CheatCheckComponent:TargetDataCheatCheck_Rect(TargetDataHandle)

    local TargetActorSpec = self.actor.Spec

    local OriginLocation = UE.FVector()
    local OriginRotation = UE.FRotator()
    UE.UKismetMathLibrary.BreakTransform(self.actor.StartLocation.LiteralTransform, OriginLocation, OriginRotation, UE.FVector())
    local ForwardVector = UE.UKismetMathLibrary.Conv_RotatorToVector(OriginRotation)

    local HalfX = TargetActorSpec.Length / 2
    local HalfY = TargetActorSpec.HalfWidth
    local HalfZ = math.max(TargetActorSpec.UpHeight, TargetActorSpec.DownHeight)

    local BoxExtent = UE.FVector(HalfX, HalfY, HalfZ)

    local NewOrigin = OriginLocation
    local KeepOrigin = false
    if not KeepOrigin then
        NewOrigin = OriginLocation + ForwardVector * TargetActorSpec.Length / 2
    end

    -- check in box - BoxOverlapComponents
    local HitResults = UE.TArray(UE.FHitResult)
    local Count = UE.UAbilitySystemBlueprintLibrary.GetDataCountFromTargetData(TargetDataHandle)

    local AA = NewOrigin + UE.FVector(-BoxExtent.X, -BoxExtent.Y, -BoxExtent.Z)
    local BB = NewOrigin + UE.FVector(BoxExtent.X, BoxExtent.Y, BoxExtent.Z)

    for Ind = 1, Count do
        local HitResult = UE.UAbilitySystemBlueprintLibrary.GetHitResultFromTargetData(TargetDataHandle, Ind - 1)
        local CurActor = HitResult.Component:GetOwner()

        local RealAA, RealBB = AA, BB
        if CurActor.CapsuleComponent then
            local CR = CurActor.CapsuleComponent.CapsuleRadius
            RealAA = UE.FVector(AA.X - CR, AA.Y - CR, AA.Z - CR)
            RealBB = UE.FVector(BB.X + CR, BB.Y + CR, BB.Z + CR)
        end

        local P = CurActor:K2_GetActorLocation()
        local Condition1 = P.X > RealAA.X and P.Y > RealAA.Y and P.Z > RealAA.Z
        local Condition2 = P.X < RealBB.X and P.Y < RealBB.Y and P.Z < RealBB.Z
        if Condition1 and Condition2 then
            HitResults:AddUnique(HitResult)
        end
    end

    TargetDataHandle = UE.UHiUtilsFunctionLibrary.AbilityTargetDataFromHitResults(HitResults)

    return TargetDataHandle
end

return CheatCheckComponent
