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


---@type BP_MissionNode_ListenDestroyActor_C
local MissionNodeListenDestroyActor = Class(MissionNodeEventBase)

function MissionNodeListenDestroyActor:K2_InitializeInstance()
    Super(MissionNodeListenDestroyActor).K2_InitializeInstance(self)
    local EventClass = EdUtils:GetUE5ObjectClass(BPConst.MissionEventDestroyActorByTags)
    if EventClass then
        local Event = NewObject(EventClass)
        Event.Name = self.DestroyEventName
        Event.Num = self.Num
        Event.Tag = self.Tag
        self:RegisterEvent(Event)
    end
end

function MissionNodeListenDestroyActor:K2_ExecuteInput(PinName)
    Super(MissionNodeListenDestroyActor).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.SuccessPin, false, false)
    self:StartWaitEvent()
end

function MissionNodeListenDestroyActor:OnEventResume(Event)
    if Event.Name == self.DestroyEventName then
        self:StartWaitEvent()
    end
end

function MissionNodeListenDestroyActor:StartWaitEvent()
    local AsyncAction = UE.UHiWaitMissionEventAction.WaitMissionEventByName(self, self.DestroyEventName)
    if AsyncAction then
        AsyncAction.Complete:Add(self, self.OnComplete)
        AsyncAction:Activate()
    end
end

function MissionNodeListenDestroyActor:OnComplete()
    UE.UHiWaitMissionEventAction.StopWaitMissionEventByName(self, self.DestroyEventName)
    self:TriggerOutput(self.CompletePin, true, false)
end


return MissionNodeListenDestroyActor