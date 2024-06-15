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

---@type BP_MissionAction_SetActorVisibility_C
local M = Class(MissionActionOnActorBase)

function M:GenerateActionParam()
    local Param = {
        iWayPointIndex = self.iWayPointIndex,
        WayPointID = self.WayPointID
    }
    return json.encode(Param)
end

function M:Run(Actor, ActionParamStr)
    Super(M).Run(self, Actor, ActionParamStr)
    local Param = self:ParseActionParam(ActionParamStr)
    if Actor and Actor.TriggerAtWayPointIndexByMission then
        G.log:debug("zsf", "[action_waypoint_index] %s %s", Param.iWayPointIndex, G.GetDisplayName(Actor))
        Actor:TriggerAtWayPointIndexByMission(Param.WayPointID, Param.iWayPointIndex)
    end
end

function M:ParseActionParam(ActionParamStr)
    return json.decode(ActionParamStr)
end


return M
