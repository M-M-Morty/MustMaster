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
local MissionEventBase = require("mission.mission_event.mission_event_base")

---@type BP_MissionNode_DestroyActorByTags_C
local MissionEventDestroyActorByTags = Class(MissionEventBase)

function MissionEventDestroyActorByTags:OnActive()
    Super(MissionEventDestroyActorByTags).OnActive(self)
    self:RegisterEventOnActorByTag(self.Tag, self:GenerateEventRegisterParam())
end

function MissionEventDestroyActorByTags:OnInactive()
    self:UnregisterEventOnActorByTag(self.Tag)
    Super(MissionEventDestroyActorByTags).OnInactive(self)
end

function MissionEventDestroyActorByTags:GenerateEventRegisterParam()
    local Param = {}
    return json.encode(Param)
end

function MissionEventDestroyActorByTags:OnEvent(EventParamStr)
    Super(MissionEventDestroyActorByTags).OnEvent(self, EventParamStr)
    self.CurNum = self.CurNum + 1
    self:HandleOnceComplete(EventParamStr)
    if self.CurNum >= self.Num then
        self:HandleComplete(EventParamStr)
    end
end

function MissionEventDestroyActorByTags:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventDestroyActorByTags).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    Actor.DestroyActor:Add(self, self.OnTargetDestroy)
end

function MissionEventDestroyActorByTags:UnregisterOnTarget(Actor)
    Super(MissionEventDestroyActorByTags).UnregisterOnTarget(self, Actor)
    Actor.DestroyActor:Remove(self, self.OnTargetDestroy)
end

function MissionEventDestroyActorByTags:OnTargetDestroy()
    self:DispatchEvent(self:GenerateEventParam())
end

function MissionEventDestroyActorByTags:GenerateEventParam()
    local Param = {}
    return json.encode(Param)
end

function MissionEventDestroyActorByTags:ResetEventRecord()
    Super(MissionEventDestroyActorByTags).ResetEventRecord(self)
    self.CurNum = 0
end


return MissionEventDestroyActorByTags
