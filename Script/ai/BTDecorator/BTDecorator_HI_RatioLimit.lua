require "UnLua"

local G = require("G")
local utils = require("common.utils")

local BTDecorator_RatioLimit = Class()

-- 分支概率 - 配合BTDecorator_RatioJudge使用
-- self.RatioCfg - 30:30:40，表示Branch1/Branch2/Branch3命中的概率分别为30/30/40
function BTDecorator_RatioLimit:PerformConditionCheckAI(Controller, Pawn)

    local AIControl = Pawn:GetAIServerComponent()
    AIControl.RatioLimits = {}

    for idx = 1, 10 do
        AIControl.RatioLimits["Branch"..idx] = false
    end

    -- G.log:debug("yj", "BTDecorator_RatioLimit - %s", self.RatioCfg)

    local Ratios = utils.StrSplit(self.RatioCfg, ":")

    -- check
    local TotalRatio = 0
    for idx, Ratio in ipairs(Ratios) do
        TotalRatio = TotalRatio + tonumber(Ratio)
    end
    
    local r = math.random(1, TotalRatio)

    -- local r = math.random(1, 100)
    -- assert(TotalRatio == 100, "TotalRatio must be 100")

    -- set
    for idx, Ratio in ipairs(Ratios) do
        r = r - tonumber(Ratio)
        if r <= 0 then
            AIControl.RatioLimits["Branch"..idx] = true
            return true
        end
    end


    return true
end


return BTDecorator_RatioLimit
