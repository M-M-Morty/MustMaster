require "UnLua"

local G = require("G")
local utils = require("common.utils")

local BTDecorator_RatioJudge = Class()

-- 配合BTDecorator_RatioLimit使用
function BTDecorator_RatioJudge:PerformConditionCheckAI(Controller, Pawn)

    local AIControl = Pawn:GetAIServerComponent()

    if utils.dict_find(AIControl.RatioLimits, self.RatioKey) == true then
        return true
    end

    return false
end


return BTDecorator_RatioJudge
