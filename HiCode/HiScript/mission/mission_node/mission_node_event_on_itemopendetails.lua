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
local json = require("thirdparty.json")

local MissionNodeEventBase = require("mission.mission_node.mission_node_event_base")

---@type BP_MissionNode_EventOnItemOpenDetails_C
local MissionNodeEventOnItemOpenDetails = Class(MissionNodeEventBase)

function MissionNodeEventOnItemOpenDetails:K2_InitializeInstance()
    Super(MissionNodeEventOnItemOpenDetails).K2_InitializeInstance(self)
    self.StatusEventName = "ItemOpenDetails"
    local EventClass = EdUtils:GetUE5ObjectClass(BPConst.MissionEventItemOpenDetails)
    if EventClass then
        local Event = NewObject(EventClass)
        Event.Name = self.StatusEventName
        --Event.ItemId = self.ItemId
        Event.ItemDetailsOpen = self.ItemDetailsOpen
        self:RegisterEvent(Event)
    end
end

function MissionNodeEventOnItemOpenDetails:K2_ExecuteInput(PinName)
    Super(MissionNodeEventOnItemOpenDetails).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.SuccessPin, false, false)
    self:StartWaitEvent()
end

function MissionNodeEventOnItemOpenDetails:OnEventResume(Event)
    if Event.Name == self.StatusEventName then
        self:StartWaitEvent()
    end
end

function MissionNodeEventOnItemOpenDetails:StartWaitEvent()
    local AsyncAction = UE.UHiWaitMissionEventAction.WaitMissionEventByName(self, self.StatusEventName)
    if AsyncAction then
        AsyncAction.OnceComplete:Add(self, self.OnOnceComplete)
        AsyncAction.Complete:Add(self, self.OnComplete)

        AsyncAction:Activate()
    end
end

function MissionNodeEventOnItemOpenDetails:OnOnceComplete(ParamStr)
end

function MissionNodeEventOnItemOpenDetails:OnComplete(ParamStr)
    UE.UHiWaitMissionEventAction.StopWaitMissionEventByName(self, self.StatusEventName)
    self:TriggerOutput(self.CompletePin, true, false)
end


return MissionNodeEventOnItemOpenDetails