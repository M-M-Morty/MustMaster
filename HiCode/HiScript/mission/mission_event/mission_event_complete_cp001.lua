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

---@type BP_MissionEventCompleteCp001_C
local MissionEventCompleteCp001 = Class(MissionEventOnActorBase)

function MissionEventCompleteCp001:GenerateEventRegisterParam()
    local Param = {}
    return json.encode(Param)
end

function MissionEventCompleteCp001:OnActive()
    Super(MissionEventCompleteCp001).OnActive(self)
    --self:RegisterEventOnActorByTag("HiGamePlayer", self:GenerateEventRegisterParam())
end

function MissionEventCompleteCp001:OnInactive()
    --self:UnregisterEventOnActorByTag("HiGamePlayer")
    Super(MissionEventCompleteCp001).OnInactive(self)
end

function MissionEventCompleteCp001:OnEvent(EventParamStr)
    Super(MissionEventCompleteCp001).OnEvent(self, EventParamStr)
    self:HandleOnceComplete(EventParamStr)
    self:HandleComplete(EventParamStr)
end

function MissionEventCompleteCp001:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventCompleteCp001).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    if Actor and Actor.Event_MissionComplete then
        Actor.Event_MissionComplete:Add(self, self.OnMissionComplete)
    end
    --if not Actor:IsA(UE.APlayerState) then
    --    return
    --end
    --local PlayerState = Actor
    --PlayerState.Event_MissionComplete:Add(self, self.OnMissionComplete)
    --local PlayerController = PlayerState:GetPlayerController()
    --local Pawn = PlayerController:K2_GetPawn()
    --local MissionCompleteEvent = Pawn.EdRuntimeComponent.Event_MissionComplete
    --MissionCompleteEvent:Add(self, self.OnMissionComplete)
end

function MissionEventCompleteCp001:OnMissionComplete(sData)
    self:DispatchEvent(self:GenerateEventParam())
end

function MissionEventCompleteCp001:UnregisterOnTarget(Actor)
    if Actor and Actor.Event_MissionComplete then
        Actor.Event_MissionComplete:Remove(self, self.OnMissionComplete)
    end
    Super(MissionEventCompleteCp001).UnregisterOnTarget(self, Actor)
end

function MissionEventCompleteCp001:GenerateEventParam()
    local Param = {}
    return json.encode(Param)
end


return MissionEventCompleteCp001