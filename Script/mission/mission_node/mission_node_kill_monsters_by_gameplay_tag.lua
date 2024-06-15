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


---@type BP_MissionNode_KillMonsterByGameplayTag_C
local MissionNodeKillMonstersByGameplayTag = Class(MissionNodeEventBase)

function MissionNodeKillMonstersByGameplayTag:K2_InitializeInstance()
    Super(MissionNodeKillMonstersByGameplayTag).K2_InitializeInstance(self)
    local EventClass = EdUtils:GetUE5ObjectClass(BPConst.MissionEventKillMultiMonster)
    if EventClass then
        local Event = NewObject(EventClass)
        Event.Name = self.KillEventName
        Event.TargetNum = self.TargetNumber
        Event.TargetGameplayTag = self.GameplayTag
        self:RegisterEvent(Event)
    end
end

function MissionNodeKillMonstersByGameplayTag:K2_ExecuteInput(PinName)
    Super(MissionNodeKillMonstersByGameplayTag).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.SuccessPin, false, false)
    self:StartWaitEvent()
end

function MissionNodeKillMonstersByGameplayTag:OnEventResume(Event)
    if Event.Name == self.KillEventName then
        self:StartWaitEvent()
    end
end

function MissionNodeKillMonstersByGameplayTag:OnResetEvents()
    Super(MissionNodeKillMonstersByGameplayTag).OnResetEvents(self)
    local Event = self:GetEvent(self.KillEventName)
    self:UpdateMissionEventProgress(Event.CurrentNum)
end

function MissionNodeKillMonstersByGameplayTag:StartWaitEvent()
    local AsyncAction = UE.UHiWaitMissionEventAction.WaitMissionEventByName(self, self.KillEventName)
    if AsyncAction then
        AsyncAction.OnceComplete:Add(self, self.OnOnceComplete)
        AsyncAction.Complete:Add(self, self.OnComplete)

        AsyncAction:Activate()
    end
end

function MissionNodeKillMonstersByGameplayTag:OnOnceComplete()
    local Event = self:GetEvent(self.KillEventName)
    self:UpdateMissionEventProgress(Event.CurrentNum)
end

function MissionNodeKillMonstersByGameplayTag:OnComplete()
    UE.UHiWaitMissionEventAction.StopWaitMissionEventByName(self, self.KillEventName)
    self:TriggerOutput(self.KilledPin, true, false)
end


return MissionNodeKillMonstersByGameplayTag