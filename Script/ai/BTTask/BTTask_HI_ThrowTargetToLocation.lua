require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_TryActiveAbility = require("ai.BTTask.BTTask_TryActiveAbility")
local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_ThrowTargetToLocation = Class(BTTask_Base)


-- 将目标投掷到指定目标点
-- ThrowDestination - 投掷目标点
-- SkillID - 投掷技能ID
-- ArcParam - 投掷曲线，值越大越接近直线，取值范围为[0.1, 0.9]
function BTTask_ThrowTargetToLocation:Execute(Controller, Pawn)
    Pawn.ThrowDestination = self.ThrowDestination
    if self.ArcParam > 0.9 then
        Pawn.ArcParam = 0.9
    else
        Pawn.ArcParam = self.ArcParam
    end
    self.BTTask_TryActiveAbility = BTTask_TryActiveAbility.new()
    self.BTTask_TryActiveAbility.SkillID = self.SkillID
    self.BTTask_TryActiveAbility:Execute(Controller, Pawn)
end

function BTTask_ThrowTargetToLocation:Tick(Controller, Pawn, DeltaSeconds)
    return self.BTTask_TryActiveAbility:Tick(Controller, Pawn, DeltaSeconds)
end


return BTTask_ThrowTargetToLocation
