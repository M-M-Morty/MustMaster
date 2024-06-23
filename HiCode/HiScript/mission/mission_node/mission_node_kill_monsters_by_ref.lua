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


---@type BP_MissionNode_KillMonstersByRef_C
local MissionNodeKillMonstersByRef = Class(MissionNodeEventBase)

function MissionNodeKillMonstersByRef:K2_InitializeInstance()
    Super(MissionNodeKillMonstersByRef).K2_InitializeInstance(self)
    self.KillEventName = "Kill"
    local EventClass = EdUtils:GetUE5ObjectClass(BPConst.MissionEventKillMultiMonster)
    if EventClass then
        local Event = NewObject(EventClass)
        Event.Name = self.KillEventName
        Event.TargetNum = self.TargetList:Length()
        for i = 1, self.TargetList:Length() do
            local Target = self.TargetList:GetRef(i)
            Event.TargetActorIDList:Add(Target.ID)
        end
        self:RegisterEvent(Event)
    end
end

function MissionNodeKillMonstersByRef:K2_ExecuteInput(PinName)
    Super(MissionNodeKillMonstersByRef).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.Success_Pin, false, false)
    self:StartWaitEvent()
end

function MissionNodeKillMonstersByRef:OnEventResume(Event)
    if Event.Name == self.KillEventName then
        self:StartWaitEvent()
    end
end

function MissionNodeKillMonstersByRef:OnResetEvents()
    Super(MissionNodeKillMonstersByRef).OnResetEvents(self)
    local Event = self:GetEvent(self.KillEventName)
    self:UpdateMissionEventProgress(Event.CurrentNum)
end

function MissionNodeKillMonstersByRef:StartWaitEvent()
    local AsyncAction = UE.UHiWaitMissionEventAction.WaitMissionEventByName(self, self.KillEventName)
    if AsyncAction then
        AsyncAction.OnceComplete:Add(self, self.OnOnceComplete)
        AsyncAction.Complete:Add(self, self.OnComplete)

        AsyncAction:Activate()
    end
end

function MissionNodeKillMonstersByRef:OnOnceComplete()
    local Event = self:GetEvent(self.KillEventName)
    self:UpdateMissionEventProgress(Event.CurrentNum)
end

function MissionNodeKillMonstersByRef:OnComplete()
    UE.UHiWaitMissionEventAction.StopWaitMissionEventByName(self, self.KillEventName)
    self:TriggerOutput(self.Killed_Pin, true, false)
end


return MissionNodeKillMonstersByRef