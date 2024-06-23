require "UnLua"

local G = require("G")
local utils = require("common.utils")

local BTDecorator_JudgeCounter = Class()

-- 当次数 >= self.Cnt时返回false
-- 配合BTService_SetCounter使用
function BTDecorator_JudgeCounter:PerformConditionCheckAI(Controller, Pawn)
    local AIControl = Pawn:GetAIServerComponent()
    local FullCounterName = AIControl.BTName..self.CounterName
    local Counter = utils.dict_find(AIControl.BTCounters, FullCounterName)
    if Counter == nil then
        AIControl.BTCounters[FullCounterName] = {0, self.bResetOnBTSwitch}
    end

    -- G.log:debug("yj", "################ BTDecorator_JudgeCounter %s", utils.FormatTable(AIControl.BTCounters))

    if AIControl.BTCounters[FullCounterName][1] >= self.Cnt then
        return false
    end

    if self.bSuccessAdd then
        AIControl.BTCounters[FullCounterName][1] = AIControl.BTCounters[FullCounterName][1] + 1
    end

    return true
end


return BTDecorator_JudgeCounter
