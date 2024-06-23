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

---@type BP_MissionEventArriveCircleRegion_C
local MissionEventArriveCircleRegion = Class(MissionEventOnActorBase)

local t = nil

function MissionEventArriveCircleRegion:GenerateEventRegisterParam()
    local Param = {
        Score = self.Score,
        ID = self.ID
    }
    return json.encode(Param)
end

function MissionEventArriveCircleRegion:OnActive()
    Super(MissionEventArriveCircleRegion).OnActive(self)
    self:RegisterEventOnActorByTag("HiGameplayer",self:GenerateEventRegisterParam())
end


function MissionEventArriveCircleRegion:OnInactive()
    self:UnregisterEventOnActorByTag("HiGameplayer")
    Super(MissionEventArriveCircleRegion).OnInactive(self)
end

function MissionEventArriveCircleRegion:OnEvent(EventParamStr)
    Super(MissionEventArriveCircleRegion).OnEvent(self, EventParamStr)
    self:HandleOnceComplete(EventParamStr)
    self:HandleComplete(EventParamStr)
end

function MissionEventArriveCircleRegion:RegisterOnTarget(Actor, EventRegisterParamStr)
    local data = json.decode(EventRegisterParamStr)
    self.Score = data.Score
    self.ID = data.ID
    Super(MissionEventArriveCircleRegion).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    if not Actor:IsA(UE.APlayerState) then
        return
    end
    local PlayerState = Actor
    PlayerState.Event_MissionComplete:Add(self,self.OnMissionComplete)
end

function MissionEventArriveCircleRegion:OnMissionComplete(sData)
    local rawdata = json.decode(sData).sData
    local data = json.decode(rawdata)
    if tostring(data.ID) == tostring(self.ID) then 
        if data.Score >= self.Score then
            self:DispatchEvent()
        end
    end
end


function MissionEventArriveCircleRegion:UnregisterOnTarget(Actor)
    Super(MissionEventArriveCircleRegion).UnregisterOnTarget(self, Actor)
end


return MissionEventArriveCircleRegion