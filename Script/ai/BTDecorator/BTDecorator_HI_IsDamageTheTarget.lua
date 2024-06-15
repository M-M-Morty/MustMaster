require "UnLua"

local G = require("G")

local BTDecorator_IsDamageTheTarget = Class()

function BTDecorator_IsDamageTheTarget:PerformConditionCheck(Actor)
    local Pawn = Actor:GetInstigator()
    local ServerAIComp = Pawn:GetAIServerComponent()
    if not ServerAIComp then
        return false
    end

    return ServerAIComp.bDamageTheTarget
end


return BTDecorator_IsDamageTheTarget
