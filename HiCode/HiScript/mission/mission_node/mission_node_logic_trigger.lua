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


---@type BP_MissionNode_LogicTrigger_C
local MissionNodeLogicTrigger = Class(MissionNodeEventBase)

function MissionNodeLogicTrigger:K2_InitializeInstance()
    Super(MissionNodeLogicTrigger).K2_InitializeInstance(self)
    self.EventName = "LogicTrigger"
    local EventClass = EdUtils:GetUE5ObjectClass(BPConst.MissionEventLogicTrigger)
    if EventClass then
        local Event = NewObject(EventClass)
        Event.Name = self.EventName
        Event.TargetActorID = self.GroupActor.ID
        Event.TriggerID = self.TriggerID
        self:RegisterEvent(Event)
    end
end

function MissionNodeLogicTrigger:K2_ExecuteInput(PinName)
    Super(MissionNodeLogicTrigger).K2_ExecuteInput(self, PinName)
    self:StartWaitEvent()
end

function MissionNodeLogicTrigger:OnEventResume(Event)
    if Event.Name == self.EventName then
        self:StartWaitEvent()
    end
end

function MissionNodeLogicTrigger:StartWaitEvent()
    local AsyncAction = UE.UHiWaitMissionEventAction.WaitMissionEventByName(self, self.EventName)
    if AsyncAction then
        AsyncAction.OnceComplete:Add(self, self.HandleOnceComplete)
        AsyncAction.Fail:Add(self, self.HandleFail)
        AsyncAction:Activate()
    end
end

function MissionNodeLogicTrigger:HandleOnceComplete()
    self:TriggerOutput(self.ActivatePin, false, false)
end

function MissionNodeLogicTrigger:HandleFail()
    self:TriggerFinishRecursive()
end

return MissionNodeLogicTrigger