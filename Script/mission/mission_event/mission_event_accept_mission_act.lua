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

---@type BP_MissionEventAcceptMissionAct_C
local MissionEventAcceptMissionAct = Class(MissionEventOnActorBase)

function MissionEventAcceptMissionAct:GenerateEventRegisterParam()
    local Param = {
        MissionActID = self:GetMissionActID()
    }
    return json.encode(Param)
end

function MissionEventAcceptMissionAct:OnEvent(EventParamStr)
    Super(MissionEventAcceptMissionAct).OnEvent(self, EventParamStr)
    self:HandleComplete(EventParamStr)
end

function MissionEventAcceptMissionAct:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventAcceptMissionAct).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    if Actor.MissionAvatarComponent == nil then
        G.log:error("[MissionEventAcceptMissionAct:RegisterOnTarget]", "Actor %s not has MissionAvatarComponent", Actor:GetName())
        return
    end
    local Param = json.decode(EventRegisterParamStr)
    self.MissionActID = Param.MissionActID
    Actor.MissionAvatarComponent.OnAcceptMissionAct:Add(self, self.HandleOnAcceptMissionAct)
end

function MissionEventAcceptMissionAct:UnregisterOnTarget(Actor)
    Super(MissionEventAcceptMissionAct).UnregisterOnTarget(self, Actor)
    Actor.MissionAvatarComponent.OnAcceptMissionAct:Remove(self, self.HandleOnAcceptMissionAct)
end

function MissionEventAcceptMissionAct:HandleOnAcceptMissionAct(MissionActID)
    if MissionActID ~= self.MissionActID then
        return
    end
    self:DispatchEvent(self:GenerateEventParam())
end

function MissionEventAcceptMissionAct:GenerateEventParam()
    local Param = {}
    return json.encode(Param)
end

return MissionEventAcceptMissionAct
