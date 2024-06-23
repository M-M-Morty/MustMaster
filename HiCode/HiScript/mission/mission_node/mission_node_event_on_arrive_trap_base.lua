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


---@type BP_MissionNode_EventOnArriveTrapBase_C
local MissionNodeEventOnArriveTrapBase = Class(MissionNodeEventBase)

function MissionNodeEventOnArriveTrapBase:K2_InitializeInstance()
    Super(MissionNodeEventOnArriveTrapBase).K2_InitializeInstance(self)
    self.ArriveRegionEventName = "ArriveTrapBase"
    local EventClass = EdUtils:GetUE5ObjectClass(BPConst.MissionEventArriveTrapBase)
    if EventClass then
        local Event = NewObject(EventClass)
        Event.Name = self.ArriveRegionEventName
        Event.TargetActorID = self.TargetReference.ID
        self:RegisterEvent(Event)
    end
end

function MissionNodeEventOnArriveTrapBase:K2_ExecuteInput(PinName)
    Super(MissionNodeEventOnArriveTrapBase).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.SuccessPin, false, false)
    self:StartWaitEvent()
end

function MissionNodeEventOnArriveTrapBase:OnEventResume(Event)
    if Event.Name == self.ArriveRegionEventName then
        self:StartWaitEvent()
    end
end

function MissionNodeEventOnArriveTrapBase:StartWaitEvent()
    local AsyncAction = UE.UHiWaitMissionEventAction.WaitMissionEventByName(self, self.ArriveRegionEventName)
    if AsyncAction then
        AsyncAction.Complete:Add(self, self.OnComplete)
        AsyncAction:Activate()
    end

    local TrackTargetClass = EdUtils:GetUE5ObjectClass(BPConst.MissionTrackTarget, true)
    local TrackTarget = TrackTargetClass()
    TrackTarget.TrackTargetType = Enum.ETrackTargetType.Actor
    TrackTarget.ActorID = self.TargetReference.ID
    self:UpdateMissionEventTrackTarget(TrackTarget, self.ArriveRegionEventName)
end

function MissionNodeEventOnArriveTrapBase:OnComplete()
    if not self.CanReTrigger then
        UE.UHiWaitMissionEventAction.StopWaitMissionEventByName(self, self.ArriveRegionEventName)
    end
    self:TriggerOutput(self.TriggerPin, true, false)
end


return MissionNodeEventOnArriveTrapBase