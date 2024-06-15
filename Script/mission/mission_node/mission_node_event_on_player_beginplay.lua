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

local EventName = "PlayerBeginPlay"

local MissionNodeEventOnPlayerBeginPlay = Class(MissionNodeEventBase)

function MissionNodeEventOnPlayerBeginPlay:K2_InitializeInstance()
    Super(MissionNodeEventOnPlayerBeginPlay).K2_InitializeInstance(self)
    local EventClass = EdUtils:GetUE5ObjectClass(BPConst.MissionEventPlayerBeginPlay)
    if EventClass then
        local Event = NewObject(EventClass)
        Event.Name = EventName
        Event.TargetTag = "HiGamePlayer"
        self:RegisterEvent(Event)
    end
end

function MissionNodeEventOnPlayerBeginPlay:K2_ExecuteInput(PinName)
    Super(MissionNodeEventOnPlayerBeginPlay).K2_ExecuteInput(self, PinName)
    self:StartWaitEvent()
end

function MissionNodeEventOnPlayerBeginPlay:StartWaitEvent()
    local AsyncAction = UE.UHiWaitMissionEventAction.WaitMissionEventByName(self, EventName)
    if AsyncAction then
        AsyncAction.Complete:Add(self, self.OnComplete)
        AsyncAction:Activate()
    end
end

function MissionNodeEventOnPlayerBeginPlay:OnComplete()
    UE.UHiWaitMissionEventAction.StopWaitMissionEventByName(self, EventName)
    self:TriggerOutput(self.SuccessPin, true, false)
end


return MissionNodeEventOnPlayerBeginPlay