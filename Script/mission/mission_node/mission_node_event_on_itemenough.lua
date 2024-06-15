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

---@type BP_MissionNode_EventOnItemEnough_C
local MissionNodeEventOnItemEnough = Class(MissionNodeEventBase)

function MissionNodeEventOnItemEnough:K2_InitializeInstance()
    Super(MissionNodeEventOnItemEnough).K2_InitializeInstance(self)
    self.StatusEventName = "ItemEnough"
    local EventClass = EdUtils:GetUE5ObjectClass(BPConst.MissionEventItemEnough)
    if EventClass then
        local Event = NewObject(EventClass)
        Event.Name = self.StatusEventName
        Event.ItemIds = self.ItemIds
        self:RegisterEvent(Event)
    end
end

function MissionNodeEventOnItemEnough:K2_ExecuteInput(PinName)
    Super(MissionNodeEventOnItemEnough).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.SuccessPin, false, false)
    self:StartWaitEvent()
end

function MissionNodeEventOnItemEnough:OnEventResume(Event)
    if Event.Name == self.StatusEventName then
        self:StartWaitEvent()
    end
end

function MissionNodeEventOnItemEnough:StartWaitEvent()
    local AsyncAction = UE.UHiWaitMissionEventAction.WaitMissionEventByName(self, self.StatusEventName)
    if AsyncAction then
        AsyncAction.OnceComplete:Add(self, self.OnOnceComplete)
        AsyncAction.Complete:Add(self, self.OnComplete)

        AsyncAction:Activate()
    end
end

function MissionNodeEventOnItemEnough:OnOnceComplete(ParamStr)
end

function MissionNodeEventOnItemEnough:OnComplete(ParamStr)
    UE.UHiWaitMissionEventAction.StopWaitMissionEventByName(self, self.StatusEventName)
    local ret = json.decode(ParamStr)
    if ret.bEnough then
        self:TriggerOutput(self.TruePin, true, false)
    else
        self:TriggerOutput(self.FalsePin, true, false)
    end
end


return MissionNodeEventOnItemEnough