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
local SubsystemUtils = require("common.utils.subsystem_utils")
local MissionUtil = require("mission.mission_utils")

---@type BP_MissionEventCheckMissionStartCondition_C
local MissionEventCheckMissionStartCondition = Class(MissionEventOnActorBase)

function MissionEventCheckMissionStartCondition:GenerateEventRegisterParam()
    local Param = {
        MissionID = self:GetMissionID(),
    }
    return json.encode(Param)
end

function MissionEventCheckMissionStartCondition:OnEvent(EventParamStr)
    Super(MissionEventCheckMissionStartCondition).OnEvent(self, EventParamStr)
    local Param = json.decode(EventParamStr)
    self:HandleComplete(EventParamStr)
end

function MissionEventCheckMissionStartCondition:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventCheckMissionStartCondition).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    local Param = json.decode(EventRegisterParamStr)
    self.MissionID = Param.MissionID
    self.Actor = Actor

    local Reason = MissionUtil.GetBlockReason(self.MissionID, Actor.MissionAvatarComponent)
    if Reason == 0 then
        -- 不被阻塞
        self:DispatchEvent(self:GenerateEventParam())
        return
    end

    Actor.MissionAvatarComponent.OnMissionStateChange:Add(self, self.HandleMissionComplete)
    Actor.MissionAvatarComponent.OnMissionActStateChange:Add(self, self.HandleMissionActComplete)
end

function MissionEventCheckMissionStartCondition:HandleMissionComplete(MissionID, NewState)
    if NewState == Enum.EHiMissionState.Complete then
        local Reason = MissionUtil.GetBlockReason(self.MissionID, self.Actor.MissionAvatarComponent)
        if Reason == 0 then
            -- 不被阻塞
            self:DispatchEvent(self:GenerateEventParam())
            return
        end
    end
end

function MissionEventCheckMissionStartCondition:HandleMissionActComplete(MissionActID, NewState, MissionObjectID)
    if NewState == Enum.EMissionActState.Complete then
        local Reason = MissionUtil.GetBlockReason(self.MissionID, self.Actor.MissionAvatarComponent)
        if Reason == 0 then
            -- 不被阻塞
            self:DispatchEvent(self:GenerateEventParam())
            return
        end
    end
end

function MissionEventCheckMissionStartCondition:UnregisterOnTarget(Actor)
    Super(MissionEventCheckMissionStartCondition).UnregisterOnTarget(self, Actor)
    Actor.MissionAvatarComponent.OnMissionStateChange:Remove(self, self.HandleMissionComplete)
    Actor.MissionAvatarComponent.OnMissionActStateChange:Remove(self, self.HandleMissionActComplete)
end

function MissionEventCheckMissionStartCondition:GenerateEventParam()
    local Param = {}
    return json.encode(Param)
end

return MissionEventCheckMissionStartCondition
