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


---@type BP_MissionNode_EventOnChestStatus_C
local MissionNodeEventOnChestStatus = Class(MissionNodeEventBase)

function MissionNodeEventOnChestStatus:K2_InitializeInstance()
    Super(MissionNodeEventOnChestStatus).K2_InitializeInstance(self)
    self.StatusEventName = "ChestStatus"
    local EventClass = EdUtils:GetUE5ObjectClass(BPConst.MissionEventChestStatus)
    if EventClass then
        local Event = NewObject(EventClass)
        Event.Name = self.StatusEventName
        Event.TargetActorID = self.ChestRef.ID
        self:RegisterEvent(Event)
    end
end

function MissionNodeEventOnChestStatus:K2_ExecuteInput(PinName)
    Super(MissionNodeEventOnChestStatus).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.SuccessPin, false, false)
    self:StartWaitEvent()
end

function MissionNodeEventOnChestStatus:OnEventResume(Event)
    if Event.Name == self.StatusEventName then
        self:StartWaitEvent()
    end
end

function MissionNodeEventOnChestStatus:StartWaitEvent()
    local AsyncAction = UE.UHiWaitMissionEventAction.WaitMissionEventByName(self, self.StatusEventName)
    if AsyncAction then
        AsyncAction.Complete:Add(self, self.OnComplete)
        AsyncAction:Activate()
    end

    --local TrackTargetClass = EdUtils:GetUE5ObjectClass(BPConst.MissionTrackTarget, true)
    --local TrackTarget = TrackTargetClass()
    --TrackTarget.TrackTargetType = Enum.ETrackTargetType.Actor
    --TrackTarget.ActorID = self.TargetReference.ID
    --self:UpdateMissionEventTrackTarget(TrackTarget, self.CompleteEventName)
end

function MissionNodeEventOnChestStatus:OnComplete(EventParamStr)
    if not self.CanReTrigger then
        UE.UHiWaitMissionEventAction.StopWaitMissionEventByName(self, self.StatusEventName)
    end
    local json = require("thirdparty.json")
    local Data = json.decode(EventParamStr)
    local ChestStatus = Data.ChestStatuss
    G.log:info("zsf", "dougzhang88 --- 99 %s %s", Data, ChestStatus)

    -- 1. Spawned  2.Unlocked 3.Opened 4. Fake
    if ChestStatus == Enum.E_ChestStatus.Spawned then
        self:TriggerOutput(self.SpawnedPin, true, false)
    elseif ChestStatus == Enum.E_ChestStatus.Unlocked then
        self:TriggerOutput(self.UnlockedPin, true, false)
    elseif ChestStatus == Enum.E_ChestStatus.Opened then
        self:TriggerOutput(self.OpenedPin, true, false)
    elseif ChestStatus == Enum.E_ChestStatus.Fake then
        self:TriggerOutput(self.FakePin, true, false)
    end
end


return MissionNodeEventOnChestStatus