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


---@type BP_MissionNode_InteractedNPC_C
local MissionNodeInteractedNPC = Class(MissionNodeEventBase)

function MissionNodeInteractedNPC:K2_InitializeInstance()
    Super(MissionNodeInteractedNPC).K2_InitializeInstance(self)
    self.InteractedEventName = "Interacted"
    local EventClass = EdUtils:GetUE5ObjectClass(BPConst.MissionEventInteractedNPC)
    if EventClass then
        local Event = NewObject(EventClass)
        Event.Name = self.InteractedEventName
        Event.TargetActorID = self.TargetReference.ID
        Event.InteractID = self.InteractID
        self:RegisterEvent(Event)
    end
end

function MissionNodeInteractedNPC:K2_ExecuteInput(PinName)
    Super(MissionNodeInteractedNPC).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.SuccessPin, false, false)
    self:StartWaitEvent()
end

function MissionNodeInteractedNPC:OnEventResume(Event)
    if Event.Name == self.InteractedEventName then
        self:StartWaitEvent()
    end
end

function MissionNodeInteractedNPC:StartWaitEvent()
    local AsyncAction = UE.UHiWaitMissionEventAction.WaitMissionEventByName(self, self.InteractedEventName)
    if AsyncAction then
        AsyncAction.Complete:Add(self, self.OnComplete)
        AsyncAction:Activate()
    end

    local TrackTargetClass = EdUtils:GetUE5ObjectClass(BPConst.MissionTrackTarget, true)
    local TrackTarget = TrackTargetClass()
    TrackTarget.TrackTargetType = Enum.ETrackTargetType.Actor
    TrackTarget.ActorID = self.TargetReference.ID
    self:UpdateMissionEventTrackTarget(TrackTarget, self.InteractedEventName)
end

function MissionNodeInteractedNPC:OnComplete()
    UE.UHiWaitMissionEventAction.StopWaitMissionEventByName(self, self.InteractedEventName)
    self:TriggerOutput(self.Interacted, true, false)
end


return MissionNodeInteractedNPC