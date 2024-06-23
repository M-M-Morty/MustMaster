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

---@type MissionEventAreaAbilityReceive_C
local MissionEventAreaAbilityReceive = Class(MissionEventOnActorBase)


function MissionEventAreaAbilityReceive:GenerateEventRegisterParam()
    local Param = {
        rAreaAbility = self.rAreaAbility
    }
    return json.encode(Param)
end

function MissionEventAreaAbilityReceive:OnEvent(EventParamStr)
    Super(MissionEventAreaAbilityReceive).OnEvent(self, EventParamStr)
    self:HandleOnceComplete(EventParamStr)
    self:HandleComplete(EventParamStr)
end

function MissionEventAreaAbilityReceive:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventAreaAbilityReceive).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    local Param = self:ParseActionParam(EventRegisterParamStr)
    self.rAreaAbility = Param["rAreaAbility"]
    if Actor and Actor.Event_AreaAbilityReceive then
        Actor.Event_AreaAbilityReceive:Add(self, self.HandleAreaAbilityReceive)
    end
end

function MissionEventAreaAbilityReceive:HandleAreaAbilityReceive(rAreaAbility)
    if self.rAreaAbility ~= rAreaAbility then
        return
    end
    self:DispatchEvent(self:GenerateEventParam())
end

function MissionEventAreaAbilityReceive:GenerateEventParam()
    local Param = {
        rAreaAbility=self.rAreaAbility
    }
    return json.encode(Param)
end

function MissionEventAreaAbilityReceive:ParseActionParam(ActionParamStr)
    return json.decode(ActionParamStr)
end

function MissionEventAreaAbilityReceive:UnregisterOnTarget(Actor)
    if Actor and Actor.Event_AreaAbilityReceive then
        Actor.Event_AreaAbilityReceive:Remove(self, self.HandleAreaAbilityReceive)
    end
    Super(MissionEventAreaAbilityReceive).UnregisterOnTarget(self, Actor)
end

return MissionEventAreaAbilityReceive
