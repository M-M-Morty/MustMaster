require "UnLua"

local G = require("G")

local BTDecorator_IsHitTheTarget = Class()

function BTDecorator_IsHitTheTarget:PerformConditionCheck(Actor)
    local Pawn = Actor:GetInstigator()
    local ServerAIComp = Pawn:GetAIServerComponent()
    if not ServerAIComp then
        return false
    end

    return ServerAIComp.bHitTheTarget
end


return BTDecorator_IsHitTheTarget
