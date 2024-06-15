require "UnLua"

local G = require("G")

local BTDecorator_IsBeDodge = Class()

function BTDecorator_IsBeDodge:PerformConditionCheck(Actor)
    local Pawn = Actor:GetInstigator()
    local ServerAIComp = Pawn:GetAIServerComponent()
    if not ServerAIComp then
        return false
    end

    -- G.log:debug("yj", "BTDecorator_IsBeDodge:PerformConditionCheck bBeWithStand.%s", ServerAIComp.bBeDodge)
    return ServerAIComp.bBeDodge
end


return BTDecorator_IsBeDodge
