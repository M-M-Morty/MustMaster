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


---@type BP_MissionNode_TimeCapsule_C
local MissionNodeTimeCapsule = Class(MissionNodeEventBase)

function MissionNodeTimeCapsule:K2_InitializeInstance()
    Super(MissionNodeTimeCapsule).K2_InitializeInstance(self)
    self.CompleteEventName = "Complete"
    local EventClass = EdUtils:GetUE5ObjectClass(BPConst.MissionEventTimeCapsule)
    if EventClass then
        local Event = NewObject(EventClass)
        Event.Name = self.CompleteEventName
        Event.TargetActorID = self.TimeCapsuleRef.ID
        self:RegisterEvent(Event)
    end
end

function MissionNodeTimeCapsule:K2_ExecuteInput(PinName)
    Super(MissionNodeTimeCapsule).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.SuccessPin, false, false)
    self:StartWaitEvent()
end

function MissionNodeTimeCapsule:OnEventResume(Event)
    if Event.Name == self.CompleteEventName then
        self:StartWaitEvent()
    end
end

function MissionNodeTimeCapsule:StartWaitEvent()
    local AsyncAction = UE.UHiWaitMissionEventAction.WaitMissionEventByName(self, self.CompleteEventName)
    if AsyncAction then
        AsyncAction.OnceComplete:Add(self, self.OnOnceComplete)
        AsyncAction.Fail:Add(self, self.OnFail)
        AsyncAction:Activate()
    end
end

function MissionNodeTimeCapsule:OnOnceComplete()
    self:TriggerOutput(self.OpenPin, false, false)
end

function MissionNodeTimeCapsule:OnFail()
    -- UE.UHiWaitMissionEventAction.StopWaitMissionEventByName(self, self.CompleteEventName)
    self:TriggerOutput(self.ClosePin, false, false)
end


return MissionNodeTimeCapsule