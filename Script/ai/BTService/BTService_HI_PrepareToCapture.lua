require "UnLua"

local G = require("G")
local utils = require("common.utils")

local GameAPI = require("common.game_api")

local BTService_PrepareToCapture = Class()

-- 抓取准备
-- 
function BTService_PrepareToCapture:ReceiveActivation(Controller)
    local Pawn = Controller:GetInstigator()
    G.log:debug("BTService_PrepareToCapture", "ReceiveActivation %s", G.GetDisplayName(Pawn))

    Pawn.InteractionComponent.TargetBeSelected = self:ChoiceTarget(Controller, Pawn)
    Pawn.InteractionComponent.ThrowTargetLocation = self:GetTargetLocation(Controller, Pawn)
end

function BTService_PrepareToCapture:ChoiceTarget(Controller, Pawn)

    local InteractTargets = GameAPI.GetActorsWithTag(Pawn, self.Tag)
    if not InteractTargets then
        G.log:error("BTService_PrepareToCapture", "GetActorsWithTag.%s empty", self.Tag)

    end
    G.log:debug("BTService_PrepareToCapture", "Find capture actor count: %d", #InteractTargets)

    if #InteractTargets > 0 then
        local MinDis
        local CaptureTarget

        for Ind = 1, #InteractTargets do
            local CurTarget = InteractTargets[Ind]
            while true do
                if not SkillUtils.IsInteractable(CurTarget) or CurTarget == Pawn then
                    break
                end
                if not CaptureTarget then
                    CaptureTarget = CurTarget
                    MinDis = utils.GetDisSquare(CurTarget:K2_GetActorLocation(), Pawn:K2_GetActorLocation())
                else
                    local CurDis = utils.GetDisSquare(CurTarget:K2_GetActorLocation(), Pawn:K2_GetActorLocation())
                    if CurDis < MinDis then
                        MinDis = CurDis
                        CaptureTarget = CurTarget
                    end
                end

                break
            end
        end
        
        return CaptureTarget
    end
end

function BTService_PrepareToCapture:GetTargetLocation(Controller, Pawn)
    if self.TargetLocationType == Enum.Enum_InteractTargetLocationType.FixLocation then
        return self.TargetLocation

    elseif self.TargetLocationType == Enum.Enum_InteractTargetLocationType.TargetActor then
        local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
        local TargetActor = BB:GetValueAsObject("TargetActor")
        return utils.GetActorLocation_Down(TargetActor)

    elseif self.TargetLocationType == Enum.Enum_InteractTargetLocationType.RouteActor then
        local RouteActors = GameAPI.GetActorsWithTag(Pawn, self.RouteActorTag)
        if #RouteActors > 0 then
            -- G.log:error("yj", "RouteActors %s", RouteActors[1]:K2_GetActorLocation())
            return RouteActors[1]:K2_GetActorLocation()
        end

    elseif self.TargetLocationType == Enum.Enum_InteractTargetLocationType.SelfOffset then
        return UE.UKismetMathLibrary.TransformLocation(utils.GetCorrectTransform(Pawn), self.LocationOffset)
    end

    G.log:error("yj", "BTService_PrepareToCapture:GetTargetLocation error TargetLocationType.%s TargetLocation.%s RouteActorName.%s", self.TargetLocationType, self.TargetLocation, self.RouteActorName)
    assert(false)
end


return BTService_PrepareToCapture
