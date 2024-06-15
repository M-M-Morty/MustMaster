require "UnLua"

local G = require("G")

local BTDecorator_CheckDisToTarget = Class()

function BTDecorator_CheckDisToTarget:PerformConditionCheck(Controller)

    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local Target = BB:GetValueAsObject("TargetActor")
    if nil == Target then
        G.log:error("yj", "BTDecorator_CheckDisToTarget Target nil")
        return false
    end

    -- actor得location是初始的摆放位置，实时的location要从pawn身上取
    local Pawn = Controller:GetInstigator()
    local Dis = UE.UKismetMathLibrary.Vector_Distance(Pawn:K2_GetActorLocation(), Target:K2_GetActorLocation())
    if self.IgnoreZ then
        Dis = UE.UKismetMathLibrary.Vector_Distance2D(Pawn:K2_GetActorLocation(), Target:K2_GetActorLocation())
    end

    if Dis > self.Distance then
        -- G.log:debug("yj", "BTDecorator_CheckDisToTarget %s > %s", Dis, self.Distance)
        return false
    end

    -- G.log:debug("yj", "BTDecorator_CheckDisToTarget %s < %s", Dis, self.Distance)
    return true
end


return BTDecorator_CheckDisToTarget
