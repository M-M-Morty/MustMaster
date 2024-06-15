require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_TeleportToRouteActor = Class(BTTask_Base)


function BTTask_TeleportToRouteActor:Execute(Controller, Pawn)
    local FoundLocation = self:GetTargetActorLocation(Controller, Pawn)
    if not FoundLocation then
        return ai_utils.BTTask_Failed
    end

    if self.bIgnoreZ then
        FoundLocation.Z = Pawn:K2_GetActorLocation().Z
    end

    Pawn:K2_SetActorLocation(FoundLocation, false, nil, true)
    -- self:SetRotation2Target(Controller, Pawn)

    return ai_utils.BTTask_Succeeded
end

function BTTask_TeleportToRouteActor:GetTargetActorLocation(Controller, Pawn)
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local Target = BB:GetValueAsObject("TargetActor")

    local RouteActors = UE.TArray(UE.AActor)
    UE.UGameplayStatics.GetAllActorsWithTag(Pawn:GetWorld(), self.ActorTag, RouteActors)

    local SortByDis = {}

    for i = 1, RouteActors:Length() do
        local RouteActor = RouteActors[i]
        local DisToTarget = RouteActor:GetDistanceTo(Target)

        local RouteActorLocation = RouteActor:K2_GetActorLocation()

        if i == 1 then
            SortByDis[1] = {DisToTarget, RouteActorLocation}
        else
            local FindIdx = 0
            for idx, v in ipairs(SortByDis) do
                if DisToTarget < v[1] then
                    FindIdx = idx
                    break
                end
            end

            if FindIdx > 0 then
                for idx = #SortByDis, FindIdx, -1 do
                    SortByDis[idx + 1] = SortByDis[idx]
                end
                SortByDis[FindIdx] = {DisToTarget, RouteActorLocation}
            else
                SortByDis[#SortByDis + 1] = {DisToTarget, RouteActorLocation}
            end
        end
    end

    self.RouteActorIdx = math.max(1, self.RouteActorIdx)

    if self.RouteActorIdx <= #SortByDis then
        return SortByDis[self.RouteActorIdx][2]
    end

    return nil
end

function BTTask_TeleportToRouteActor:SetRotation2Target(Controller, Pawn)
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local Target = BB:GetValueAsObject("TargetActor")

    local Forward = Target:K2_GetActorLocation() - Pawn:K2_GetActorLocation()
    Forward.Z = 0.0

    local Rotation = UE.UKismetMathLibrary.Conv_VectorToRotator(Forward)
    Pawn:K2_SetActorRotation(Rotation, true)
end


return BTTask_TeleportToRouteActor
