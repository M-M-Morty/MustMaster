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

---@type BP_MissionEventChestStatus_C
local MissionEventChestStatus = Class(MissionEventOnActorBase)

function MissionEventChestStatus:GenerateEventRegisterParam()
    local Param = {}
    return json.encode(Param)
end

function MissionEventChestStatus:OnActive()
    Super(MissionEventChestStatus).OnActive(self)
    --self:RegisterEventOnActorByTag("HiGamePlayer", self:GenerateEventRegisterParam())
end

function MissionEventChestStatus:OnInactive()
    --self:UnregisterEventOnActorByTag("HiGamePlayer")
    Super(MissionEventChestStatus).OnInactive(self)
end

function MissionEventChestStatus:OnEvent(EventParamStr)
    Super(MissionEventChestStatus).OnEvent(self, EventParamStr)
    self:HandleOnceComplete(EventParamStr)
    self:HandleComplete(EventParamStr)
end

function MissionEventChestStatus:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventChestStatus).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    if Actor and Actor.ChestStatus then
        Actor.ChestStatus:Add(self, self.OnMissionComplete)
    end
end

function MissionEventChestStatus:OnMissionComplete(sData)
    self:DispatchEvent(self:GenerateEventParam(sData))
end

function MissionEventChestStatus:UnregisterOnTarget(Actor)
    if Actor and Actor.ChestStatus then
        Actor.ChestStatus:Remove(self, self.OnMissionComplete)
    end
    Super(MissionEventChestStatus).UnregisterOnTarget(self, Actor)
end

function MissionEventChestStatus:GenerateEventParam(ChestStatus)
    local Param = {
        ChestStatuss=ChestStatus
    }
    return json.encode(Param)
end


return MissionEventChestStatus