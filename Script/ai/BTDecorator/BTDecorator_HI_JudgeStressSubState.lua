require "UnLua"

local G = require("G")
local utils = require("common.utils")

local BTDecorator_JudgeStressSubState = Class()

function BTDecorator_JudgeStressSubState:PerformConditionCheckAI(Controller, Pawn)
    return Pawn.BattleStateComponent.StressSubState == self.StreeSubState
end


return BTDecorator_JudgeStressSubState
