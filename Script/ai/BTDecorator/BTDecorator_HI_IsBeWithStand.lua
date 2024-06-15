require "UnLua"

local G = require("G")

local BTDecorator_IsBeWithStand = Class()

function BTDecorator_IsBeWithStand:PerformConditionCheck(Actor)
    local Pawn = Actor:GetInstigator()
    local ServerAIComp = Pawn:GetAIServerComponent()
    if not ServerAIComp then
        return false
    end

    -- G.log:debug("yj", "BTDecorator_IsBeWithStand:PerformConditionCheck JudgeExtreme.%s bBeWithStand.%s bBeExtremeWithStand.%s", self.JudgeExtreme, ServerAIComp.bBeWithStand, ServerAIComp.bBeExtremeWithStand)
    if not self.JudgeExtreme then
    	return ServerAIComp.bBeWithStand
    else
    	return ServerAIComp.bBeExtremeWithStand
    end
end


return BTDecorator_IsBeWithStand
