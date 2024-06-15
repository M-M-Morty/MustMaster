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


---@type BP_MissionNode_CheckMissionStartCondition_C
local MissionNodeCheckMissionStartCondition = Class(MissionNodeEventBase)

function MissionNodeCheckMissionStartCondition:K2_InitializeInstance()
    Super(MissionNodeCheckMissionStartCondition).K2_InitializeInstance(self)
    self.CheckStartEvent = "CheckStart"
    local EventClass = EdUtils:GetUE5ObjectClass(BPConst.MissionEventCheckMissionStart)
    if EventClass then
        local Event = NewObject(EventClass)
        Event.Name = self.CheckStartEvent
        Event.TargetTag = "HiGamePlayer"
        self:RegisterEvent(Event)
    end
end

function MissionNodeCheckMissionStartCondition:K2_ExecuteInput(PinName)
    Super(MissionNodeCheckMissionStartCondition).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.SuccessPin, false, false)
    self:StartWaitEvent()
end

function MissionNodeCheckMissionStartCondition:OnEventResume(Event)
    if Event.Name == self.CheckStartEvent then
        self:StartWaitEvent()
    end
end

function MissionNodeCheckMissionStartCondition:StartWaitEvent()
    local AsyncAction = UE.UHiWaitMissionEventAction.WaitMissionEventByName(self, self.CheckStartEvent)
    if AsyncAction then
        AsyncAction.Complete:Add(self, self.OnComplete)
        AsyncAction:Activate()
    end
end

function MissionNodeCheckMissionStartCondition:OnComplete()
    UE.UHiWaitMissionEventAction.StopWaitMissionEventByName(self, self.CheckStartEvent)
    self:TriggerOutput(self.CompletePin, true, false)
end

return MissionNodeCheckMissionStartCondition