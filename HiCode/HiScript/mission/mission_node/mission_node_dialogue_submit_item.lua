--
-- DESCRIPTION
--gueStepBase
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require("G")
local json = require("thirdparty.json")
local EdUtils = require("common.utils.ed_utils")
local BPConst = require("common.const.blueprint_const")

local MissionNodeEventBase = require("mission.mission_node.mission_node_event_base")

---@type BP_MissionNode_DialogueSubmitItem_C
local MissionNodeDialogueSubmitItem = Class(MissionNodeEventBase)

function MissionNodeDialogueSubmitItem:K2_InitializeInstance()
    Super(MissionNodeDialogueSubmitItem).K2_InitializeInstance(self)
    self.EventName = "DialogueSubmitItem"
    local EventClass = EdUtils:GetUE5ObjectClass(BPConst.MissionEventDialogueSubmitItem)
    if EventClass then
        local Event = NewObject(EventClass)
        Event.Name = self.EventName
        Event.TargetActorID = self.TargetNpc.ID
        Event.SubmitItemInfo = self.SubmitItemInfo
        Event.DialogueID = self.DialogueID
        self:RegisterEvent(Event)
    end
end

function MissionNodeDialogueSubmitItem:K2_ExecuteInput(PinName)
    Super(MissionNodeDialogueSubmitItem).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.SuccessPin, false, false)
    if self.SubmitItemInfo.ItemMapKey:Num() ~= self.SubmitItemInfo.ItemMapValue:Num() then
        G.log:error("MissionNodeDialogueSubmitItem", "K2_ExecuteInput, ItemMapKeyLength=%s, ItemMapValueLength=%s", 
            self.SubmitItemInfo.ItemMapKey:Num(), self.SubmitItemInfo.ItemMapValue:Num())
        return
    end
    self:StartWaitEvent()
end

function MissionNodeDialogueSubmitItem:OnEventResume(Event)
    if Event.Name == self.EventName then
        self:StartWaitEvent()
    end
end

function MissionNodeDialogueSubmitItem:StartWaitEvent()
    local AsyncAction = UE.UHiWaitMissionEventAction.WaitMissionEventByName(self, self.EventName)
    if AsyncAction then
        AsyncAction.Complete:Add(self, self.OnComplete)
        AsyncAction:Activate()
    end

    local TrackTargetClass = EdUtils:GetUE5ObjectClass(BPConst.MissionTrackTarget, true)
    local TrackTarget = TrackTargetClass()
    TrackTarget.TrackTargetType = Enum.ETrackTargetType.Actor
    TrackTarget.ActorID = self.TargetNpc.ID
    self:UpdateMissionEventTrackTarget(TrackTarget, self.EventName)
end

function MissionNodeDialogueSubmitItem:OnComplete(ParamStr)
    UE.UHiWaitMissionEventAction.StopWaitMissionEventByName(self, self.EventName)
    self:TriggerOutput(self.CompletePin, true, false)
end

return MissionNodeDialogueSubmitItem
