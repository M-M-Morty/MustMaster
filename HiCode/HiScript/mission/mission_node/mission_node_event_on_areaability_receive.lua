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

---@type BP_MissionNode_EventOnAreaAbilityReceive_C
local MissionNodeEventOnAreaAbilityReceive = Class(MissionNodeEventBase)

function MissionNodeEventOnAreaAbilityReceive:K2_InitializeInstance()
    Super(MissionNodeEventOnAreaAbilityReceive).K2_InitializeInstance(self)
    self.StatusEventName = "AreaAbilityReceive"
    local EventClass = EdUtils:GetUE5ObjectClass(BPConst.MissionEventAreaAbilityReceive)
    if EventClass then
        local Event = NewObject(EventClass)
        Event.Name = self.StatusEventName
        Event.rAreaAbility = self.rAreaAbility
        Event.TargetActorIDList:Add(self.BaseItemRef.ID)
        self:RegisterEvent(Event)
    end
end

function MissionNodeEventOnAreaAbilityReceive:K2_ExecuteInput(PinName)
    Super(MissionNodeEventOnAreaAbilityReceive).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.SuccessPin, false, false)
    self:StartWaitEvent()
end

function MissionNodeEventOnAreaAbilityReceive:OnEventResume(Event)
    if Event.Name == self.StatusEventName then
        self:StartWaitEvent()
    end
end

function MissionNodeEventOnAreaAbilityReceive:StartWaitEvent()
    local AsyncAction = UE.UHiWaitMissionEventAction.WaitMissionEventByName(self, self.StatusEventName)
    if AsyncAction then
        AsyncAction.OnceComplete:Add(self, self.OnOnceComplete)
        AsyncAction.Complete:Add(self, self.OnComplete)

        AsyncAction:Activate()
    end
end

function MissionNodeEventOnAreaAbilityReceive:OnOnceComplete(ParamStr)
end

function MissionNodeEventOnAreaAbilityReceive:OnComplete(ParamStr)
    UE.UHiWaitMissionEventAction.StopWaitMissionEventByName(self, self.StatusEventName)
    self:TriggerOutput(self.CompletePin, true, false)
end


return MissionNodeEventOnAreaAbilityReceive