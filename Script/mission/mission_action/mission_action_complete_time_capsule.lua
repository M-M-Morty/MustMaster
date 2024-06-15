--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"

local G = require("G")
local json = require("thirdparty.json")
local MissionActionOnActorBase = require("mission.mission_action.mission_action_onactor_base")

---@type BP_MissionAction_CompleteTimeCapsule_C
local MissionActionCompleteTimeCapsule = Class(MissionActionOnActorBase)

function MissionActionCompleteTimeCapsule:GenerateActionParam()
    local Param = {}
    return json.encode(Param)
end

function MissionActionCompleteTimeCapsule:Run(Actor, ActionParamStr)
    Super(MissionActionCompleteTimeCapsule).Run(self, Actor, ActionParamStr)
    Actor:Multicast_Complete()
end

function MissionActionCompleteTimeCapsule:ParseActionParam(ActionParamStr)
    return json.decode(ActionParamStr)
end

return MissionActionCompleteTimeCapsule
