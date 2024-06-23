require "UnLua"

local G = require("G")
local utils = require("common.utils")

local BTService_SetCounter = Class()

-- 添加次数
-- 配合BTDecorator_JudgeCounter使用
function BTService_SetCounter:ReceiveActivation(Actor)
    local Pawn = Actor:GetInstigator()
    local AIControl = Pawn:GetAIServerComponent()
    local FullCounterName = AIControl.BTName..self.CounterName
    local Counter = utils.dict_find(AIControl.BTCounters, FullCounterName)

    AIControl.BTCounters[FullCounterName][1] = self.Count

    -- G.log:debug("yj", "BTService_SetCounter %s", AIControl.BTCounters[FullCounterName])
end


return BTService_SetCounter
