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


---@type BP_MissionNode_KillMonsterByTag_C
local MissionNodeKillMonstersByTag = Class(MissionNodeEventBase)

function MissionNodeKillMonstersByTag:K2_InitializeInstance()
    Super(MissionNodeKillMonstersByTag).K2_InitializeInstance(self)
    local EventClass = EdUtils:GetUE5ObjectClass(BPConst.MissionEventKillMultiMonster)
    if EventClass then
        local Event = NewObject(EventClass)
        Event.Name = self.KillEventName
        Event.TargetNum = self.TargetNumber
        Event.TargetTag = self.Tag
        self:RegisterEvent(Event)
    end
end

function MissionNodeKillMonstersByTag:K2_ExecuteInput(PinName)
    Super(MissionNodeKillMonstersByTag).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.Success_Pin, false, false)
    self:StartWaitEvent()
end

function MissionNodeKillMonstersByTag:OnEventResume(Event)
    if Event.Name == self.KillEventName then
        self:StartWaitEvent()
    end
end

function MissionNodeKillMonstersByTag:OnResetEvents()
    Super(MissionNodeKillMonstersByTag).OnResetEvents(self)
    local Event = self:GetEvent(self.KillEventName)
    self:UpdateMissionEventProgress(Event.CurrentNum)
end

function MissionNodeKillMonstersByTag:StartWaitEvent()
    local AsyncAction = UE.UHiWaitMissionEventAction.WaitMissionEventByName(self, self.KillEventName)
    if AsyncAction then
        AsyncAction.OnceComplete:Add(self, self.OnOnceComplete)
        AsyncAction.Complete:Add(self, self.OnComplete)

        AsyncAction:Activate()
    end
end

function MissionNodeKillMonstersByTag:OnOnceComplete()
    local Event = self:GetEvent(self.KillEventName)
    self:UpdateMissionEventProgress(Event.CurrentNum)
end

function MissionNodeKillMonstersByTag:OnComplete()
    UE.UHiWaitMissionEventAction.StopWaitMissionEventByName(self, self.KillEventName)
    self:TriggerOutput(self.Killed_Pin, true, false)
end


return MissionNodeKillMonstersByTag