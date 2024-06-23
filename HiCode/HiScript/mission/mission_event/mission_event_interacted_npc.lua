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
local BPConst = require("common.const.blueprint_const")

---@type BP_MissionEventInteractedNPC_C
local MissionEventInteractedNPC = Class(MissionEventOnActorBase)

function MissionEventInteractedNPC:GenerateEventRegisterParam()
    local Param = {
        InteractID = self.InteractID
    }
    return json.encode(Param)
end

function MissionEventInteractedNPC:OnEvent(EventParamStr)
    Super(MissionEventInteractedNPC).OnEvent(self, EventParamStr)
    self:HandleOnceComplete(EventParamStr)
    self:HandleComplete(EventParamStr)
end

function MissionEventInteractedNPC:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventInteractedNPC).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    if Actor.NpcBehaviorComponent == nil then
        G.log:error("xaelpeng", "MissionEventDialogNPC:RegisterOnTarget Actor %s not has NpcBehaviorComponent", Actor:GetName())
        return
    end
    local Param = json.decode(EventRegisterParamStr)
    self.InteractID = Param.InteractID
    Actor.NpcBehaviorComponent:AppendMissionInteractByEvent(self.EventID, self.MissionEventID, self.InteractID)
    Actor.NpcBehaviorComponent.MissionInteractFinished:Add(self, self.OnInteractFinished)
end

function MissionEventInteractedNPC:UnregisterOnTarget(Actor)
    Super(MissionEventInteractedNPC).UnregisterOnTarget(self, Actor)
    Actor.NpcBehaviorComponent:RemoveMissionInteractByEvent(self.EventID, self.MissionEventID, self.InteractID)
    Actor.NpcBehaviorComponent.MissionInteractFinished:Remove(self, self.OnInteractFinished)
end

function MissionEventInteractedNPC:OnInteractFinished(InteractID)
    G.log:debug("xaelpeng", "MissionEventInteractedNPC:OnInteractFinished InteractID:%d", InteractID)
    if InteractID == self.InteractID then
        self:DispatchEvent(self:GenerateEventParam())
    end
end

function MissionEventInteractedNPC:GenerateEventParam()
    local Param = {}
    return json.encode(Param)
end

return MissionEventInteractedNPC
