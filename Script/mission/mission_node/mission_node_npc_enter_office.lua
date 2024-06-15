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


---@type BP_MissionNode_NpcEnterOffice_C
local MissionNodeNpcEnterOffice = Class(MissionNodeEventBase)

function MissionNodeNpcEnterOffice:K2_InitializeInstance()
    Super(MissionNodeNpcEnterOffice).K2_InitializeInstance(self)
    self.EnterOfficeEvent = "EnterOffice"
    local EventClass = EdUtils:GetUE5ObjectClass(BPConst.MissionEventNpcEnterOffice)
    if EventClass then
        local Event = NewObject(EventClass)
        Event.Name = self.EnterOfficeEvent
        Event.TargetActorID = self.TargetRef.ID
        Event.Sequence = self.Sequence
        self:RegisterEvent(Event)
    end
end

function MissionNodeNpcEnterOffice:K2_ExecuteInput(PinName)
    Super(MissionNodeNpcEnterOffice).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.SuccessPin, false, false)
    self:StartWaitEvent()
end

function MissionNodeNpcEnterOffice:OnEventResume(Event)
    if Event.Name == self.EnterOfficeEvent then
        self:StartWaitEvent()
    end
end

function MissionNodeNpcEnterOffice:StartWaitEvent()
    local AsyncAction = UE.UHiWaitMissionEventAction.WaitMissionEventByName(self, self.EnterOfficeEvent)
    if AsyncAction then
        AsyncAction.Complete:Add(self, self.OnComplete)
        AsyncAction:Activate()
    end
end

function MissionNodeNpcEnterOffice:OnComplete()
    UE.UHiWaitMissionEventAction.StopWaitMissionEventByName(self, self.EnterOfficeEvent)
    self:TriggerOutput(self.CompletePin, true, false)
end

return MissionNodeNpcEnterOffice