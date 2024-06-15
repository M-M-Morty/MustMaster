require "UnLua"

local G = require("G")
local utils = require("common.utils")

local BTDecorator_HI_AutomicRun = Class()

function BTDecorator_HI_AutomicRun:PerformConditionCheckAI(Controller, Pawn)
    G.log:error("yj", "BTDecorator_HI_AutomicRun:PerformConditionCheckAI")
    return true
end

function BTDecorator_HI_AutomicRun:ReceiveExecutionStartAI(Controller, Pawn)
    G.log:error("yj", "BTDecorator_HI_AutomicRun:ReceiveActivationAI")
    Pawn:GetAIServerComponent().bForbiddenBTSwitch = true
end

function BTDecorator_HI_AutomicRun:ReceiveExecutionFinishAI(Controller, Pawn)
    G.log:error("yj", "BTDecorator_HI_AutomicRun:ReceiveDeactivationAI")
    Pawn:GetAIServerComponent().bForbiddenBTSwitch = false
end


return BTDecorator_HI_AutomicRun
