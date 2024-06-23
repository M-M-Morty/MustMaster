require "UnLua"

local G = require("G")
local os = require("os")
local ai_utils = require("common.ai_utils")

local BTDecorator_NeedRetreat = Class()

function BTDecorator_NeedRetreat:PerformConditionCheck(Actor)

	local Pawn = Actor:GetInstigator()
    if 0 == self.RetreatDis then
    	return false
    end

    local Controller = Pawn:GetController()
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local Target = BB:GetValueAsObject("TargetActor")
    if nil == Target then
        G.log:error("yj", "BTTask_MoveToTarget Target nil")
        return false
    end

    local TargetLocation = Target:K2_GetActorLocation()
    local SelfLocation = Pawn:K2_GetActorLocation()
    local Dis = UE.UKismetMathLibrary.Vector_Distance(SelfLocation, TargetLocation)

    -- G.log:debug("yjj", "BTDecorator_NeedRetreat(%s < %s = %s)", Dis, RetreatDis, Dis < self.RetreatDis)
    return Dis < self.RetreatDis
end


return BTDecorator_NeedRetreat
