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

---@type BP_MissionNode_EventOnAreaAbilityFlowsLight_C
local MissionNodeEventOnAreaAbilityFlowsLight = Class(MissionNodeEventBase)

function MissionNodeEventOnAreaAbilityFlowsLight:K2_InitializeInstance()
    Super(MissionNodeEventOnAreaAbilityFlowsLight).K2_InitializeInstance(self)
    self.StatusEventName = "AreaAbilityFlowLighting"
    local EventClass = EdUtils:GetUE5ObjectClass(BPConst.MissionEventAreaAbilityFlowLighting)
    if EventClass then
        local Event = NewObject(EventClass)
        Event.Name = self.StatusEventName
        for i = 1, self.AreaAbilityFlowLightingRef:Length() do
            local Target = self.AreaAbilityFlowLightingRef:GetRef(i)
            Event.TargetActorIDList:Add(Target.ID)
        end
        self:RegisterEvent(Event)
    end
end

function MissionNodeEventOnAreaAbilityFlowsLight:K2_ExecuteInput(PinName)
    Super(MissionNodeEventOnAreaAbilityFlowsLight).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.SuccessPin, false, false)
    self:StartWaitEvent()
end

function MissionNodeEventOnAreaAbilityFlowsLight:OnEventResume(Event)
    if Event.Name == self.StatusEventName then
        self:StartWaitEvent()
    end
end

function MissionNodeEventOnAreaAbilityFlowsLight:StartWaitEvent()
    local AsyncAction = UE.UHiWaitMissionEventAction.WaitMissionEventByName(self, self.StatusEventName)
    if AsyncAction then
        AsyncAction.OnceComplete:Add(self, self.OnOnceComplete)
        AsyncAction.Complete:Add(self, self.OnComplete)

        AsyncAction:Activate()
    end
end

function MissionNodeEventOnAreaAbilityFlowsLight:OnOnceComplete(ParamStr)
end

function MissionNodeEventOnAreaAbilityFlowsLight:OnComplete(ParamStr)
    UE.UHiWaitMissionEventAction.StopWaitMissionEventByName(self, self.StatusEventName)
    self:TriggerOutput(self.CompletePin, true, false)
end


return MissionNodeEventOnAreaAbilityFlowsLight