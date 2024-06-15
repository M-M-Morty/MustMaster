--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")
local EdUtils = require("common.utils.ed_utils")
local BPConst = require("common.const.blueprint_const")

local MissionNodeEventBase = require("mission.mission_node.mission_node_event_base")


---@type BP_MissionNode_EventOnCompleteCp001_C
local MissionNodeEventOnCompleteCp001 = Class(MissionNodeEventBase)

function MissionNodeEventOnCompleteCp001:K2_InitializeInstance()
    Super(MissionNodeEventOnCompleteCp001).K2_InitializeInstance(self)
    self.CompleteEventName = "ComplteCp001"
    local EventClass = EdUtils:GetUE5ObjectClass(BPConst.MissionEventCompleteCp001)
    if EventClass then
        local Event = NewObject(EventClass)
        Event.Name = self.CompleteEventName
        Event.TargetActorID = self.CP001Ref.ID
        self:RegisterEvent(Event)
    end
end

function MissionNodeEventOnCompleteCp001:K2_ExecuteInput(PinName)
    Super(MissionNodeEventOnCompleteCp001).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.SuccessPin, false, false)
    self:StartWaitEvent()
end

function MissionNodeEventOnCompleteCp001:OnEventResume(Event)
    if Event.Name == self.CompleteEventName then
        self:StartWaitEvent()
    end
end

function MissionNodeEventOnCompleteCp001:StartWaitEvent()
    local AsyncAction = UE.UHiWaitMissionEventAction.WaitMissionEventByName(self, self.CompleteEventName)
    if AsyncAction then
        AsyncAction.Complete:Add(self, self.OnComplete)
        AsyncAction:Activate()
    end

    --local TrackTargetClass = EdUtils:GetUE5ObjectClass(BPConst.MissionTrackTarget, true)
    --local TrackTarget = TrackTargetClass()
    --TrackTarget.TrackTargetType = Enum.ETrackTargetType.Actor
    --TrackTarget.ActorID = self.TargetReference.ID
    --self:UpdateMissionEventTrackTarget(TrackTarget, self.CompleteEventName)
end

function MissionNodeEventOnCompleteCp001:OnComplete(EventParamStr)
    if not self.CanReTrigger then
        UE.UHiWaitMissionEventAction.StopWaitMissionEventByName(self, self.CompleteEventName)
    end
    self:TriggerOutput(self.TriggerPin, true, false)
end


return MissionNodeEventOnCompleteCp001