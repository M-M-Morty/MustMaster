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

---@type BP_MissionNode_EventOnActorHit_C
local MissionNodeEventOnActorHit = Class(MissionNodeEventBase)

function MissionNodeEventOnActorHit:K2_InitializeInstance()
    Super(MissionNodeEventOnActorHit).K2_InitializeInstance(self)
    self.StatusEventName = "ActorHit"
    local EventClass = EdUtils:GetUE5ObjectClass(BPConst.MissionEventActorHit)
    if EventClass then
        local Event = NewObject(EventClass)
        Event.Name = self.StatusEventName
        Event.HitTag = self.HitTag
        Event.TargetActorIDList:Add(self.ActorRef.ID)
        self:RegisterEvent(Event)
    end
end

function MissionNodeEventOnActorHit:K2_ExecuteInput(PinName)
    Super(MissionNodeEventOnActorHit).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.SuccessPin, false, false)
    self:StartWaitEvent()
end

function MissionNodeEventOnActorHit:OnEventResume(Event)
    if Event.Name == self.StatusEventName then
        self:StartWaitEvent()
    end
end

function MissionNodeEventOnActorHit:StartWaitEvent()
    local AsyncAction = UE.UHiWaitMissionEventAction.WaitMissionEventByName(self, self.StatusEventName)
    if AsyncAction then
        AsyncAction.OnceComplete:Add(self, self.OnOnceComplete)
        AsyncAction.Complete:Add(self, self.OnComplete)

        AsyncAction:Activate()
    end
end

function MissionNodeEventOnActorHit:OnOnceComplete(ParamStr)
end

function MissionNodeEventOnActorHit:OnComplete(ParamStr)
    UE.UHiWaitMissionEventAction.StopWaitMissionEventByName(self, self.StatusEventName)
    self:TriggerOutput(self.CompletePin, true, false)
end


return MissionNodeEventOnActorHit