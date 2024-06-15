require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_MoveToLocation = require("ai.BTTask.BTTask_MoveToLocation")
local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_MoveToTargetLocation = Class(BTTask_Base)

-- 移动到目标的位置，不会随着目标移动而变化目标点
function BTTask_MoveToTargetLocation:Execute(Controller, Pawn)

    local TargetLocation = self:GetTargetActorLocation(Controller, Pawn)
    if TargetLocation == nil then
        return ai_utils.BTTask_Failed
    end

    self.BTTask_MoveToLocation = BTTask_MoveToLocation.new() 
    self.BTTask_MoveToLocation.TargetLocation = TargetLocation
    self.BTTask_MoveToLocation.Tolerance = self.Tolerance
    self.BTTask_MoveToLocation.IgnoreZ = self.IgnoreZ
    self.BTTask_MoveToLocation.TurnBeforeMove = self.TurnBeforeMove
    self.BTTask_MoveToLocation.NeedWalkStop = self.NeedWalkStop
    self.BTTask_MoveToLocation:Execute(Controller, Pawn)
end

function BTTask_MoveToTargetLocation:Tick(Controller, Pawn, DeltaSeconds)
    return self.BTTask_MoveToLocation:Tick(Controller, Pawn, DeltaSeconds)
end

function BTTask_MoveToTargetLocation:GetTargetActorLocation(Controller, Pawn)
    if self.TargetActorName ~= "" then
        local TargetActors = GameAPI.GetActorsWithTag(Pawn, self.TargetActorTag)
        if #TargetActors > 0 then
            -- G.log:error("yj", "TargetActors %s", TargetActors[1]:K2_GetActorLocation())
            return TargetActors[1]:K2_GetActorLocation()
        end
    else
        local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
        local Target = BB:GetValueAsObject("TargetActor")
        if Target ~= nil then
            return Target:K2_GetActorLocation()
        end
    end

    return nil
end


return BTTask_MoveToTargetLocation
