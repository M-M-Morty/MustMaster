require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_ObserveTarget = Class(BTTask_Base)


function BTTask_ObserveTarget:Execute(Controller, Pawn)

    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local Target = BB:GetValueAsObject("TargetActor")
    if nil == Target then
        G.log:error("yj", "BTTask_ObserveTarget Target nil")
        return ai_utils.BTTask_Failed
    end

    local AIControl = Pawn:GetAIServerComponent()
    local ObserveIndex = BB:GetValueAsInt("ObserveIndex")
    if ObserveIndex > #AIControl.ObservePath or 0 == ObserveIndex then
        G.log:error("yj", "BTTask_ObserveTarget ObserveIndex.%s ObservePath.%s", ObserveIndex, #AIControl.ObservePath)
        BB:SetValueAsInt("ObserveIndex", 0)
        return ai_utils.BTTask_Failed
    end

    -- G.log:debug("yjj", "BTTask_ObserveTarget %s %s", ObserveIndex, #AIControl.ObservePath)

    local Offset = AIControl.ObservePath[ObserveIndex]
    local OffsetLocation = UE.FVector()
    OffsetLocation:Set(Offset[1], Offset[2], Offset[3])

    BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local ObserveHeight = BB:GetValueAsFloat("ObserveHeight")
    OffsetLocation.Z = ObserveHeight
    -- G.log:debug("yj", "BTTask_ObserveTarget ObserveHeight.%s", ObserveHeight)

    local TargetLocation = Target:K2_GetActorLocation()
    local Location = UE.UKismetMathLibrary.Add_VectorVector(TargetLocation, OffsetLocation)
    BB:SetValueAsVector("MoveToLocation", Location)

    if self.DrawDebugTraceType ~= 0 then
        local CollisionObjectTypes = UE.TArray(UE.EObjectTypeQuery)
        CollisionObjectTypes:Add(UE.EObjectTypeQuery.Pawn)
        local ActorsToIgnore = UE.TArray(UE.AActor)
        local OutHits = UE.TArray(UE.FHitResult)
        UE.UKismetSystemLibrary.SphereTraceMultiForObjects(Pawn:GetWorld(), Location, Location, 50, CollisionObjectTypes, true, ActorsToIgnore, self.DrawDebugTraceType, OutHits, true)
    end

    return ai_utils.BTTask_Succeeded
end

return BTTask_ObserveTarget
