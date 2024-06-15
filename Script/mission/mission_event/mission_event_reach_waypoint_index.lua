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
local MissionEventOnActorBase = require("mission.mission_event.mission_event_onactor_base")

---@type MissionEventKillMonster_C
local MissionEventReachWayPointIndex = Class(MissionEventOnActorBase)


function MissionEventReachWayPointIndex:GenerateEventRegisterParam()
    local Param = {
        iWayPointIndex = self.iWayPointIndex,
        WayPointID = self.WayPointID
    }
    G.log:debug("zsf", "[mission_event_waypoint_index] %s %s", self.iWayPointIndex, self.WayPointID)
    return json.encode(Param)
end

function MissionEventReachWayPointIndex:OnEvent(EventParamStr)
    Super(MissionEventReachWayPointIndex).OnEvent(self, EventParamStr)
    self:HandleOnceComplete(EventParamStr)
    self:HandleComplete(EventParamStr)
end

function MissionEventReachWayPointIndex:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventReachWayPointIndex).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    local Param = self:ParseActionParam(EventRegisterParamStr)
    G.log:debug("zsf", "[mission_event_waypoint_index] %s %s %s %s %s", G.GetDisplayName(Actor), EventRegisterParamStr, Param.iWayPointIndex, Param.WayPointID, Param)
    if Actor and Actor.TriggerAtWayPointIndexByMission then
        Actor:TriggerAtWayPointIndexByMission(Param.WayPointID, Param.iWayPointIndex)
    end
end

function MissionEventReachWayPointIndex:ParseActionParam(ActionParamStr)
    return json.decode(ActionParamStr)
end

function MissionEventReachWayPointIndex:UnregisterOnTarget(Actor)
    Super(MissionEventReachWayPointIndex).UnregisterOnTarget(self, Actor)
end

function MissionEventReachWayPointIndex:GenerateEventParam()
    local Param = {
        iWayPointIndex = self.iWayPointIndex,
        WayPointID = self.WayPointID
    }
    return json.encode(Param)
end

return MissionEventReachWayPointIndex
