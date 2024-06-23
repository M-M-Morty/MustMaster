--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"

local G = require("G")
local json = require("thirdparty.json")
local MissionEventOnActorBase = require("mission.mission_event.mission_event_onactor_base")
local BPConst = require("common.const.blueprint_const")
local GlobalActorConst = require("common.const.global_actor_const")

---@type BP_MissionEventDialogNPC_C
local MissionEventDialogNPC = Class(MissionEventOnActorBase)

function MissionEventDialogNPC:GenerateEventRegisterParam()
    local Param = {
        DialogueID = self.DialogueID,
        MissionActID = self:GetMissionActID()
    }
    return json.encode(Param)
end

function MissionEventDialogNPC:OnEvent(EventParamStr)
    Super(MissionEventDialogNPC).OnEvent(self, EventParamStr)
    self:HandleOnceComplete(EventParamStr)
    self:HandleComplete(EventParamStr)
end

function MissionEventDialogNPC:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventDialogNPC).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    if Actor.DialogueComponent == nil then
        G.log:error("xaelpeng", "MissionEventDialogNPC:RegisterOnTarget Actor %s not has DialogueComponent", Actor:GetName())
        return
    end
    local Param = json.decode(EventRegisterParamStr)
    self.DialogueID = Param.DialogueID
    self.MissionActID = Param.MissionActID
    self.NpcID = Actor:GetNpcId()
    Actor.DialogueComponent:AppendMissionDialogueByEvent(self.EventID, self.MissionEventID, self.DialogueID, Enum.EDialogueType.Normal)
    Actor.DialogueComponent.MissionDialogFinished:Add(self, self.OnDialogFinished)
end

function MissionEventDialogNPC:UnregisterOnTarget(Actor)
    Super(MissionEventDialogNPC).UnregisterOnTarget(self, Actor)
    Actor.DialogueComponent:RemoveMissionDialogueByEvent(self.EventID, self.MissionEventID, self.DialogueID)
    Actor.DialogueComponent.MissionDialogFinished:Remove(self, self.OnDialogFinished)
end

function MissionEventDialogNPC:OnDialogFinished(DialogueID, ResultID, DialogueRecord)
    G.log:debug("xaelpeng", "MissionEventDialogNPC:OnDialogFinished DialogueID:%d ResultID:%d", DialogueID, ResultID)
    if DialogueID == self.DialogueID then
        self:DispatchEvent(self:GenerateEventParam(ResultID))
    end
    if ResultID >= 0 then
        -- 保存对话记录
        local MissionManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MissionManager)
        if not MissionManager then
            G.log:error("[MissionEventDialogNPC:OnDialogFinished]", "Can't find MissionManager")
            return
        end
        DialogueRecord.MissionActID = self.MissionActID
        DialogueRecord.NpcID = self.NpcID
        MissionManager:GetDataBPComponent():AddMissionActDialogueRecord(self.MissionActID, DialogueRecord)
    end
end

function MissionEventDialogNPC:GenerateEventParam(ResultID)
    local Param = {
        ResultID = ResultID
    }
    return json.encode(Param)
end

return MissionEventDialogNPC
