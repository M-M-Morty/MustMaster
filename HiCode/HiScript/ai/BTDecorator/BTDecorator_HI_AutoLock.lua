require "UnLua"

local G = require("G")
local utils = require("common.utils")

local BTDecorator_AutoLock = Class()

-- 当成功一次则锁定
-- 本质还是计数器，最大计数是1，成功一次则计数加1
function BTDecorator_AutoLock:PerformConditionCheckAI(Controller, Pawn)
    local AIControl = Pawn:GetAIServerComponent()
    local FullCounterName = AIControl.BTName..self.CounterName
    local Counter = utils.dict_find(AIControl.BTCounters, FullCounterName)
    if Counter == nil then
        AIControl.BTCounters[FullCounterName] = {0, self.bResetOnBTSwitch}
    end

    -- G.log:debug("yj", "################ BTDecorator_AutoLock %s", utils.FormatTable(AIControl.BTCounters))

    if AIControl.BTCounters[FullCounterName][1] >= 1 then
        return false
    end

    AIControl.BTCounters[FullCounterName][1] = AIControl.BTCounters[FullCounterName][1] + 1

    return true
end


return BTDecorator_AutoLock
