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

---@type BP_MissionNode_TimeCapsule_C
local MissionEventTimeCapsule = Class(MissionEventOnActorBase)

function MissionEventTimeCapsule:GenerateEventRegisterParam()
    local Param = {}
    return json.encode(Param)
end

function MissionEventTimeCapsule:OnEvent(EventParamStr)
    Super(MissionEventTimeCapsule).OnEvent(self, EventParamStr)
    if EventParamStr == "Open" then
        self:HandleOnceComplete(EventParamStr)
    elseif EventParamStr == "Close" then
        self:HandleFail(EventParamStr)
    end
end

function MissionEventTimeCapsule:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventTimeCapsule).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    Actor.TimeCapsuleOpen:Add(self, self.OnTargetOpen)
    Actor.TimeCapsuleClose:Add(self, self.OnTargetClose)
end

function MissionEventTimeCapsule:UnregisterOnTarget(Actor)
    Super(MissionEventTimeCapsule).UnregisterOnTarget(self, Actor)
    Actor.TimeCapsuleOpen:Remove(self, self.OnTargetOpen)
    Actor.TimeCapsuleClose:Remove(self, self.OnTargetClose)
end

function MissionEventTimeCapsule:OnTargetClose()
    self:DispatchEvent("Close")
end

function MissionEventTimeCapsule:OnTargetOpen()
    self:DispatchEvent("Open")
end

function MissionEventTimeCapsule:GenerateEventParam()
    local Param = {}
    return json.encode(Param)
end


return MissionEventTimeCapsule
