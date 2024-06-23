require "UnLua"

local G = require("G")

local BTDecorator_CheckDisToTargetLocation = Class()

function BTDecorator_CheckDisToTargetLocation:PerformConditionCheck(Actor)

    local Controller = UE.UAIBlueprintHelperLibrary.GetAIController(Actor)
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local TargetLocation = BB:GetValueAsVector("MoveToLocation")

    -- actor得location是初始的摆放位置，实时的location要从pawn身上取
    local Pawn = Actor:GetInstigator()
    local Dis = UE.UKismetMathLibrary.Vector_Distance(Pawn:K2_GetActorLocation(), TargetLocation)
    if self.IgnoreZ then
        Dis = UE.UKismetMathLibrary.Vector_Distance2D(Pawn:K2_GetActorLocation(), TargetLocation)
    end

    if Dis > self.Distance then
        -- G.log:debug("yj", "BTDecorator_CheckDisToTargetLocation %s > %s", Dis, self.Distance)
        return false
    end

    -- G.log:debug("yj", "BTDecorator_CheckDisToTargetLocation %s < %s", Dis, self.Distance)
    return true
end


return BTDecorator_CheckDisToTargetLocation
