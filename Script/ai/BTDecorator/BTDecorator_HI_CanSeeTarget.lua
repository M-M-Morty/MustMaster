require "UnLua"

local G = require("G")
local utils = require("common.utils")

local BTDecorator_CanSeeTarget = Class()

function BTDecorator_CanSeeTarget:PerformConditionCheck(Controller)

    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local Target = BB:GetValueAsObject("TargetActor")
    if nil == Target then
        return false
    end

    local Pawn = Controller:GetInstigator()
    local SelfLocation = utils.GetActorLocation_Up(Pawn)
    local TargetLocation = utils.GetActorLocation_Up(Target)


    local Hits = UE.TArray(UE.FHitResult)
    local ObjectTypes = UE.TArray(UE.EObjectTypeQuery)
    ObjectTypes:Add(UE.EObjectTypeQuery.WorldStatic)
    local ActorsToIgnore = UE.TArray(UE.AActor)
    ActorsToIgnore:Add(Target)
    ActorsToIgnore:Add(Pawn)
    UE.UKismetSystemLibrary.LineTraceMultiForObjects(Pawn, SelfLocation, TargetLocation, ObjectTypes, true, ActorsToIgnore, self.DrawDebugTraceType, Hits, true)

    -- G.log:debug("yj", "BTDecorator_CanSeeTarget Hits.%s", Hits:Length())

    if Hits:Length() > 0 then
        return false
    end

    return true
end


return BTDecorator_CanSeeTarget
