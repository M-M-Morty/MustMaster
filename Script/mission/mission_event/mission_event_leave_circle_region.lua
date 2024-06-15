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

---@type BP_MissionEventLeaveCircleRegion_C
local MissionEventLeaveCircleRegion = Class(MissionEventOnActorBase)

function MissionEventLeaveCircleRegion:GenerateEventRegisterParam()
    local Param = {}
    return json.encode(Param)
end

function MissionEventLeaveCircleRegion:OnEvent(EventParamStr)
    Super(MissionEventLeaveCircleRegion).OnEvent(self, EventParamStr)
    self:HandleOnceComplete(EventParamStr)
    self:HandleComplete(EventParamStr)
end

function MissionEventLeaveCircleRegion:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventLeaveCircleRegion).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    Actor.Sphere.OnComponentEndOverlap:Add(self, self.OnEndOverlap)
end

function MissionEventLeaveCircleRegion:UnregisterOnTarget(Actor)
    Super(MissionEventLeaveCircleRegion).UnregisterOnTarget(self, Actor)
    Actor.Sphere.OnComponentEndOverlap:Remove(self, self.OnEndOverlap)
end

function MissionEventLeaveCircleRegion:OnEndOverlap(OverlappedComp, Other, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if Other.IsAvatar ~= nil and Other:IsAvatar() then
        G.log:debug("xaelpeng", "MissionEventLeaveCircleRegion:OnEndOverlap %s", Other:GetName())
        self:DispatchEvent(self:GenerateEventParam())
    end
end

function MissionEventLeaveCircleRegion:GenerateEventParam()
    local Param = {}
    return json.encode(Param)
end


return MissionEventLeaveCircleRegion