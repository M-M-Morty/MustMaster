--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require("G")
local json = require("thirdparty.json")
local EdUtils = require("common.utils.ed_utils")
local BPConst = require("common.const.blueprint_const")
local MissionConst = require("mission.mission_const")

local MissionNodeEventBase = require("mission.mission_node.mission_node_event_base")

---@type BP_MissionNode_PlayDialogueFlow_C
local MissionNodePlayDialogueFlow = Class(MissionNodeEventBase)

function MissionNodePlayDialogueFlow:K2_InitializeInstance()
    Super(MissionNodePlayDialogueFlow).K2_InitializeInstance(self)
    self.EventName = "PlayDialogue"
    local EventClass = EdUtils:GetUE5ObjectClass(BPConst.MissionEventPlayDialogueFlow)
    if EventClass then
        local Event = NewObject(EventClass)
        Event.Name = self.EventName
        if self.BaseNpc.ID ~= "" then
            Event.TargetActorID = self.BaseNpc.ID
        else
            Event.TargetTag = "HiGamePlayer"
        end
        Event.DialogueFlow = self.DialogueFlow
        Event.DialogueID = tonumber(self.DialogueFlow.DialogueCustomParameter)
        Event.TriggerType = self.TriggerType
        Event.TriggerRadius = self.TriggerRadius
        for i = 1, self.NpcList:Length() do
            local ActorID = self.NpcList[i].ID
            Event.NpcActorIdList:Add(ActorID)
        end
        self:RegisterEvent(Event)
    end
end

function MissionNodePlayDialogueFlow:K2_ExecuteInput(PinName)
    Super(MissionNodePlayDialogueFlow).K2_ExecuteInput(self, PinName)
    self:StartWaitEvent()
end

function MissionNodePlayDialogueFlow:OnEventResume(Event)
    if Event.Name == self.EventName then
        self:StartWaitEvent()
    end
end

function MissionNodePlayDialogueFlow:StartWaitEvent()
    local AsyncAction = UE.UHiWaitMissionEventAction.WaitMissionEventByName(self, self.EventName)
    if AsyncAction then
        AsyncAction.Complete:Add(self, self.OnComplete)
        AsyncAction:Activate()
    end

    local TrackTargetClass = EdUtils:GetUE5ObjectClass(BPConst.MissionTrackTarget, true)
    local TrackTarget = TrackTargetClass()
    TrackTarget.TrackTargetType = Enum.ETrackTargetType.Actor
    TrackTarget.ActorID = self.BaseNpc.ID
    self:UpdateMissionEventTrackTarget(TrackTarget, self.EventName)
end

function MissionNodePlayDialogueFlow:OnComplete(ParamStr)
    UE.UHiWaitMissionEventAction.StopWaitMissionEventByName(self, self.EventName)
    local Param = json.decode(ParamStr)
    local ResultID = Param.ResultID
    if 0 <= ResultID and ResultID <= MissionConst.MAX_EXIT_DIALOGUE_ID then
        -- [0, 9]属于Exit分支输出的参数, 特殊处理
        local OutputPin = "Exit" .. ResultID
        self:TriggerOutput(OutputPin, true, false)
    else
        self:TriggerOutput(tostring(ResultID), true, false)
    end
end

return MissionNodePlayDialogueFlow
