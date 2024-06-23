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
local MissionEventKillMonster = Class(MissionEventOnActorBase)


function MissionEventKillMonster:GenerateEventRegisterParam()
    local Param = {}
    return json.encode(Param)
end

function MissionEventKillMonster:OnEvent(EventParamStr)
    Super(MissionEventKillMonster).OnEvent(self, EventParamStr)
    self:HandleOnceComplete(EventParamStr)
    self:HandleComplete(EventParamStr)
end

function MissionEventKillMonster:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventKillMonster).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    if Actor.MutableActorComponent then
        Actor.MutableActorComponent.DeadDelegate:Add(self, self.OnTargetDead)
    end
end

function MissionEventKillMonster:UnregisterOnTarget(Actor)
    Super(MissionEventKillMonster).UnregisterOnTarget(self, Actor)
    if Actor.MutableActorComponent then
        Actor.MutableActorComponent.DeadDelegate:Remove(self, self.OnTargetDead)
    end
end

function MissionEventKillMonster:OnTargetDead()
    self:DispatchEvent(self:GenerateEventParam())
end

function MissionEventKillMonster:GenerateEventParam()
    local Param = {}
    return json.encode(Param)
end

return MissionEventKillMonster
