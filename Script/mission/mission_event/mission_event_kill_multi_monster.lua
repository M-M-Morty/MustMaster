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

---@type BP_MissionNode_KillMultiMonster_C
local MissionEventKillMultiMonster = Class(MissionEventOnActorBase)

function MissionEventKillMultiMonster:GenerateEventRegisterParam()
    local Param = {}
    G.log:debug("xaelpeng", "GenerateEventRegisterParam %d", self.CurrentNum)
    return json.encode(Param)
end

function MissionEventKillMultiMonster:OnEvent(EventParamStr)
    Super(MissionEventKillMultiMonster).OnEvent(self, EventParamStr)
    self.CurrentNum = self.CurrentNum + 1
    self:HandleOnceComplete(EventParamStr)
    if self.CurrentNum >= self.TargetNum then
        self:HandleComplete(EventParamStr)
    end
end

function MissionEventKillMultiMonster:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventKillMultiMonster).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    if Actor.MutableActorComponent then
        Actor.MutableActorComponent.DeadDelegate:Add(self, self.OnTargetDead)
    end
end

function MissionEventKillMultiMonster:UnregisterOnTarget(Actor)
    Super(MissionEventKillMultiMonster).UnregisterOnTarget(self, Actor)
    if Actor.MutableActorComponent then
        Actor.MutableActorComponent.DeadDelegate:Remove(self, self.OnTargetDead)
    end
end

function MissionEventKillMultiMonster:OnTargetDead()
    self:DispatchEvent(self:GenerateEventParam())
end

function MissionEventKillMultiMonster:GenerateEventParam()
    local Param = {}
    return json.encode(Param)
end

function MissionEventKillMultiMonster:ResetEventRecord()
    Super(MissionEventKillMultiMonster).ResetEventRecord(self)
    self.CurrentNum = 0
end

function MissionEventKillMultiMonster:GetFlowEventSaveFieldName()
    return "KillMultiMonster"
end


return MissionEventKillMultiMonster
