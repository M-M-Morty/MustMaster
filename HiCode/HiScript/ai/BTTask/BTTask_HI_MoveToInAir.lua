require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_MoveToInAir = Class(BTTask_Base)


function BTTask_MoveToInAir:Execute(Controller, Pawn)

    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local MoveToLocation = BB:GetValueAsVector("MoveToLocation")

    local Forward = MoveToLocation - Pawn:K2_GetActorLocation()
    Forward = UE.UKismetMathLibrary.Normal(Forward)
    Forward = Forward * self.Speed

    local MovementComponent = Pawn.AppearanceComponent:GetMyMovementComponent()
    MovementComponent:RequestDirectMove(Forward, false)
end


function BTTask_MoveToInAir:Tick(Controller, Pawn, DeltaSeconds)

    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local MoveToLocation = BB:GetValueAsVector("MoveToLocation")
    local SelfLocation = Pawn:K2_GetActorLocation()

    local MovementComponent = Pawn.AppearanceComponent:GetMyMovementComponent()

    local Dis = UE.UKismetMathLibrary.Vector_Distance(SelfLocation, MoveToLocation)
    if Dis < self.TolerateDis then
        -- MovementComponent:RequestDirectMove(UE.FVector(1, 1, 1) * 0.0001, false)
        -- MovementComponent:StopActiveMovement()
        return ai_utils.BTTask_Succeeded
    end

    -- G.log:debug("yj", "BTTask_MoveToInAir %s - %s", MoveToLocation, Pawn:K2_GetActorLocation())

    local ActorsToIgnore = UE.TArray(UE.AActor)
    Pawn:GetAttachedActors(ActorsToIgnore);

    ActorsToIgnore:Add(Pawn)
    local HitResult = UE.FHitResult()
    local IsHit = UE.UKismetSystemLibrary.LineTraceSingle(Pawn:GetWorld(), Pawn:K2_GetActorLocation(), MoveToLocation, UE.ETraceTypeQuery.WorldStatic, true, ActorsToIgnore, self.DrawDebugTraceType, HitResult, true)

    -- G.log:debug("yj", "BTTask_MoveToInAir %s", IsHit)
    if IsHit then
        return ai_utils.BTTask_Succeeded
    end

    local Forward = MoveToLocation - Pawn:K2_GetActorLocation()
    Forward = UE.UKismetMathLibrary.Normal(Forward)
    Forward = Forward * self.Speed

    MovementComponent:RequestDirectMove(Forward, false)
end


return BTTask_MoveToInAir
