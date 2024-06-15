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

---@type BP_MissionEventLogicTrigger_C
local MissionEventLogicTrigger = Class(MissionEventOnActorBase)

function MissionEventLogicTrigger:GenerateEventRegisterParam()
    local Param = {
        TriggerID = self.TriggerID
    }
    return json.encode(Param)
end

function MissionEventLogicTrigger:OnEvent(EventParamStr)
    Super(MissionEventLogicTrigger).OnEvent(self, EventParamStr)
    local Param = json.decode(EventParamStr)
    if Param.bStart then
        self:HandleOnceComplete(EventParamStr)
    else
        self:HandleFail(EventParamStr)
    end
end

function MissionEventLogicTrigger:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventLogicTrigger).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    -- Actor是GroupActor
    local Param = json.decode(EventRegisterParamStr)
    self.TriggerID = Param.TriggerID
    Actor.LogicTriggerComponent.OnTriggerStart:Add(self, self.HandleTriggerStart)
    Actor.LogicTriggerComponent.OnTriggerEnd:Add(self, self.HandleTriggerEnd)
end

function MissionEventLogicTrigger:UnregisterOnTarget(Actor)
    Super(MissionEventLogicTrigger).UnregisterOnTarget(self, Actor)
    Actor.LogicTriggerComponent.OnTriggerStart:Remove(self, self.HandleTriggerStart)
    Actor.LogicTriggerComponent.OnTriggerEnd:Remove(self, self.HandleTriggerEnd)
end

function MissionEventLogicTrigger:HandleTriggerStart(TriggerID)
    if TriggerID ~= self.TriggerID then
        return
    end
    self:DispatchEvent(self:GenerateEventParam(true))
end

function MissionEventLogicTrigger:HandleTriggerEnd(TriggerID)
    if TriggerID ~= self.TriggerID then
        return
    end
    self:DispatchEvent(self:GenerateEventParam(false))
end

function MissionEventLogicTrigger:GenerateEventParam(bStart)
    local Param = {
        bStart = bStart
    }
    return json.encode(Param)
end


return MissionEventLogicTrigger