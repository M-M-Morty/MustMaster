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

---@type BP_MissionNode_EventOnAreaAbilityDarkThronsLight_C
local MissionNodeEventOnAreaAbilityDarkThronsLight = Class(MissionNodeEventBase)

function MissionNodeEventOnAreaAbilityDarkThronsLight:K2_InitializeInstance()
    Super(MissionNodeEventOnAreaAbilityDarkThronsLight).K2_InitializeInstance(self)
    self.StatusEventName = "AreaAbilityDarkThronsLighting"
    local EventClass = EdUtils:GetUE5ObjectClass(BPConst.MissionEventAreaAbilityDarkThronsLighting)
    if EventClass then
        local Event = NewObject(EventClass)
        Event.Name = self.StatusEventName
        for i = 1, self.AreaAbilityDarkThronsLightingRef:Length() do
            local Target = self.AreaAbilityDarkThronsLightingRef:GetRef(i)
            Event.TargetActorIDList:Add(Target.ID)
        end
        self:RegisterEvent(Event)
    end
end

function MissionNodeEventOnAreaAbilityDarkThronsLight:K2_ExecuteInput(PinName)
    Super(MissionNodeEventOnAreaAbilityDarkThronsLight).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.SuccessPin, false, false)
    self:StartWaitEvent()
end

function MissionNodeEventOnAreaAbilityDarkThronsLight:OnEventResume(Event)
    if Event.Name == self.StatusEventName then
        self:StartWaitEvent()
    end
end

function MissionNodeEventOnAreaAbilityDarkThronsLight:StartWaitEvent()
    local AsyncAction = UE.UHiWaitMissionEventAction.WaitMissionEventByName(self, self.StatusEventName)
    if AsyncAction then
        AsyncAction.OnceComplete:Add(self, self.OnOnceComplete)
        AsyncAction.Complete:Add(self, self.OnComplete)

        AsyncAction:Activate()
    end
end

function MissionNodeEventOnAreaAbilityDarkThronsLight:OnOnceComplete(ParamStr)
end

function MissionNodeEventOnAreaAbilityDarkThronsLight:OnComplete(ParamStr)
    UE.UHiWaitMissionEventAction.StopWaitMissionEventByName(self, self.StatusEventName)
    self:TriggerOutput(self.CompletePin, true, false)
end


return MissionNodeEventOnAreaAbilityDarkThronsLight