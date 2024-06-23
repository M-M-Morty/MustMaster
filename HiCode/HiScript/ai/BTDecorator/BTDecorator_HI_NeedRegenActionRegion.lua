require "UnLua"

local G = require("G")
local os = require("os")
local ai_utils = require("common.ai_utils")

local BTDecorator_NeedRegenActionRegion = Class()

function BTDecorator_NeedRegenActionRegion:PerformConditionCheck(Controller)
	local Pawn = Controller:GetInstigator()
    return Pawn.ClusterMasterComponent:NeedRegenActionRegions()
end


return BTDecorator_NeedRegenActionRegion
