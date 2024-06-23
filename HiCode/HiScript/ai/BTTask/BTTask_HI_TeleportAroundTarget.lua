require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_TeleportAroundTarget = Class(BTTask_Base)


function BTTask_TeleportAroundTarget:Execute(Controller, Pawn)
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local Target = BB:GetValueAsObject("TargetActor")

    local SelfLocation = Pawn:K2_GetActorLocation()
    local TargetLocation = Target:K2_GetActorLocation()

    local FoundLocation = self:GetReachablePointAlongNavDir(Controller, Pawn, TargetLocation, self.Radius)
    FoundLocation.Z = SelfLocation.Z

    Pawn:K2_SetActorLocation(FoundLocation, false, nil, true)
    -- self:SetRotation2Target(Controller, Pawn)

    return ai_utils.BTTask_Succeeded
end

function BTTask_TeleportAroundTarget:GetReachablePointAlongNavDir(Controller, Pawn, Origin, Radius)
    local SelfLocation = Pawn:K2_GetActorLocation()

    local OutPath = UE.TArray(UE.FVector)
    UE.UHiUtilsFunctionLibrary.FindNavPath(Controller, Origin, OutPath)

    if OutPath:Length() < 2 then
        -- 容错
        local Ret, ReachableLocation = UE.UHiUtilsFunctionLibrary.GetRandomReachablePointInRadius(Controller, Origin, Radius)
        if Ret then
            return ReachableLocation
        else
            return SelfLocation
        end
    end

    -- UE.UKismetSystemLibrary.DrawDebugSphere(Pawn:GetWorld(), Origin, 5, 20, UE.FLinearColor(1, 0.1, 0.1, 1), 10)
    -- for idx = OutPath:Length(), 1, -1 do
    --     local CurNavPoint = OutPath:Get(idx)
    --     UE.UKismetSystemLibrary.DrawDebugSphere(Pawn:GetWorld(), CurNavPoint, 5, 20, UE.FLinearColor(1, 0.1, 0.1, 1), 10)
    -- end
    -- UE.UKismetSystemLibrary.DrawDebugSphere(Pawn:GetWorld(), ResultLocation, 5, 20, UE.FLinearColor(1, 0.1, 0.1, 1), 10)

    local ResultLocation = UE.FVector(0, 0, 0)
    local LastNavPoint = Origin
    
    for idx = OutPath:Length(), 1, -1 do
        local CurNavPoint = OutPath:Get(idx)

        local DisBetweenNei = self:GetLocationDistance(LastNavPoint, CurNavPoint)
        if Radius < DisBetweenNei then
            local Forward = UE.UKismetMathLibrary.Normal(self:VectorWithoutZ(CurNavPoint) - self:VectorWithoutZ(LastNavPoint))
            ResultLocation = LastNavPoint + Forward * Radius
            -- UE.UKismetSystemLibrary.DrawDebugSphere(Pawn:GetWorld(), ResultLocation, 5, 50, UE.FLinearColor.White, 10)
            break
        else
            Radius = Radius - DisBetweenNei
            ResultLocation = CurNavPoint
            LastNavPoint = CurNavPoint
            -- UE.UKismetSystemLibrary.DrawDebugSphere(Pawn:GetWorld(), ResultLocation, 5, 20, UE.FLinearColor.White, 10)
        end
    end

    return ResultLocation
end

function BTTask_TeleportAroundTarget:GetLocationDistance(Location1, Location2)
    local Dis = UE.UKismetMathLibrary.Vector_Distance(Location1, Location2)
    if self.IgnoreZ then
        Dis = UE.UKismetMathLibrary.Vector_Distance2D(Location1, Location2)
    end

    return Dis
end

function BTTask_TeleportAroundTarget:VectorWithoutZ(Location)
    return UE.FVector(Location.X, Location.Y, 0)
end


return BTTask_TeleportAroundTarget
