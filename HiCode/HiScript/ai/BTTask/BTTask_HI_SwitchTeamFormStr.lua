require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_SwitchTeamFormStr = Class(BTTask_Base)


function BTTask_SwitchTeamFormStr:Execute(Controller, Pawn)
	Pawn:SendMessage("SwitchTeamFormStr", self.TeamFormStr)
    return ai_utils.BTTask_Succeeded
end


return BTTask_SwitchTeamFormStr
