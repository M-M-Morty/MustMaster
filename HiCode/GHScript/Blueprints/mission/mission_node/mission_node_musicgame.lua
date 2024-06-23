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


---@type BP_MusicNode_C
local MissionNodeMusicGame = Class(MissionNodeEventBase)

function MissionNodeMusicGame:K2_InitializeInstance()
    Super(MissionNodeMusicGame).K2_InitializeInstance(self)
    self.MusicGameEvent = Enum.E_MiniGame.MusicGame
    local EventClass = EdUtils:GetUE5ObjectClass(BPConst.MissionEventMusicGameComplete)
    G.log:warn("xmj", "MissionNodeMusicGame:K2_InitializeInstance")
    if self.ScoreMode == false then
        self.Score = -1
    end
    if EventClass then
        local Event = NewObject(EventClass)
        Event.Name = self.MusicGameEvent
        Event.TargetTag = "HiGamePlayer"
        Event.ID = self.ID
        Event.Score = self.Score
        G.log:warn("xmj", "MissionNodeMusicGame:K2_InitializeInstance ID: %s, Score: %s", tostring(self.ID), tostring(self.Score))
        self:RegisterEvent(Event)
    end
end

function MissionNodeMusicGame:K2_ExecuteInput(PinName)
    G.log:warn("xmj", "MissionNodeMusicGame:K2_ExecuteInput")
    Super(MissionNodeMusicGame).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.SuccessPin, false, false)
    self:StartWaitEvent()
end

function MissionNodeMusicGame:OnEventResume(Event)
    G.log:warn("xmj", "MissionNodeMusicGame:OnEventResume")
    if Event.Name == self.MusicGameEvent then
        self:StartWaitEvent()       
    end
end

function MissionNodeMusicGame:StartWaitEvent()
    G.log:warn("xmj", "MissionNodeMusicGame:StartWaitEvent")
    local AsyncAction = UE.UHiWaitMissionEventAction.WaitMissionEventByName(self, self.MusicGameEvent)
    if AsyncAction then
        AsyncAction.Complete:Add(self, self.OnComplete)
        AsyncAction:Activate()
    end


    local TrackTargetClass = EdUtils:GetUE5ObjectClass(BPConst.MissionTrackTarget, true)
    local NPCTrackTarget = TrackTargetClass()
    local ItemTrackTarget = TrackTargetClass()
    NPCTrackTarget.TrackTargetType = Enum.ETrackTargetType.Actor
    ItemTrackTarget.TrackTargetType = Enum.ETrackTargetType.Actor
    NPCTrackTarget.ActorID = self.NPCTargetReference.ID
    ItemTrackTarget.ActorID = self.ItemTargetReference.ID
    if self.NPCTargetReference.ID ~= "" then
        self:UpdateMissionEventTrackTarget(NPCTrackTarget, self.MusicGameEvent)
    end
    if self.ItemTargetReference.ID ~= "" then
        self:UpdateMissionEventTrackTarget(ItemTrackTarget, self.MusicGameEvent)
    end
end
function MissionNodeMusicGame:OnComplete()
    G.log:warn("xmj", "MissionNodeMusicGame:OnComplete")
    UE.UHiWaitMissionEventAction.StopWaitMissionEventByName(self, self.MusicGameEvent)
    self:TriggerOutput(self.CompletePin, true, false)
end     

return MissionNodeMusicGame