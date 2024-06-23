require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_Wait = Class(BTTask_Base)


function BTTask_Wait:Execute(Controller, Pawn)
    if math.random(0, 1) == 1 then
        self.RemainTime = self.WaitTime + self.DelayDeviation
    else
        self.RemainTime = self.WaitTime - self.DelayDeviation
    end
end

function BTTask_Wait:Tick(Controller, Pawn, DeltaSeconds)
    self.RemainTime = self.RemainTime - DeltaSeconds
    if self.RemainTime < 0 then
        return ai_utils.BTTask_Succeeded
    end
end


return BTTask_Wait
