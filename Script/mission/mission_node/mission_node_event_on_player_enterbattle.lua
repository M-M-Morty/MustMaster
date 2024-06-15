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

local EventName = "PlayerEnterBattle"

local MissionNodeEventOnPlayerBeginPlay = Class(MissionNodeEventBase)

function MissionNodeEventOnPlayerBeginPlay:K2_InitializeInstance()
    Super(MissionNodeEventOnPlayerBeginPlay).K2_InitializeInstance(self)
    local EventClass = EdUtils:GetUE5ObjectClass(BPConst.MissionEventPlayerEnterBattle)
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
    if not self.bCanReTrigger then
        UE.UHiWaitMissionEventAction.StopWaitMissionEventByName(self, EventName)
    end
    self:TriggerOutput(self.SuccessPin, true, false)
end


return MissionNodeEventOnPlayerBeginPlay