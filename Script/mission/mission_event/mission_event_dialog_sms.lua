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

---@type BP_MissionEventDialogSMS_C
local MissionEventDialogSMS = Class(MissionEventOnActorBase)

function MissionEventDialogSMS:GenerateEventRegisterParam()
    local Param = {
        DialogueID = self.DialogueID,
        NpcID = self.NpcID,
        MissionActID = self:GetMissionActID()
    }
    return json.encode(Param)
end

function MissionEventDialogSMS:OnEvent(EventParamStr)
    Super(MissionEventDialogSMS).OnEvent(self, EventParamStr)
    local Param = json.decode(EventParamStr)
    local bIsSuccess = Param.IsSuccess
    if not bIsSuccess then
        self:HandleFail(EventParamStr)
    else
        self:HandleComplete(EventParamStr)
    end
end

function MissionEventDialogSMS:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventDialogSMS).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    if Actor.MissionAvatarComponent == nil then
        G.log:error("hangyuewang", "MissionEventDialogSMS:RegisterOnTarget Actor %s not has MissionAvatarComponent", Actor:GetName())
        return
    end
    local Param = json.decode(EventRegisterParamStr)
    self.DialogueID = Param.DialogueID
    self.NpcID = Param.NpcID
    self.MissionActID = Param.MissionActID
    local Ret = Actor.MissionAvatarComponent:StartSmsDialogue(self.DialogueID, self.NpcID, self.MissionActID)
    if not Ret then
        -- 注册失败进行处理
        self:DispatchEvent(self:GenerateEventParam(0, false))
        return
    end
    Actor.MissionAvatarComponent.SmsDialogueFinished:Add(self, self.OnDialogFinished)
end

function MissionEventDialogSMS:UnregisterOnTarget(Actor)
    Super(MissionEventDialogSMS).UnregisterOnTarget(self, Actor)
    Actor.MissionAvatarComponent.SmsDialogueFinished:Remove(self, self.OnDialogFinished)
end

function MissionEventDialogSMS:OnDialogFinished(NpcID, DialogueID, ResultID)
    if NpcID == self.NpcID and DialogueID == self.DialogueID then
        self:DispatchEvent(self:GenerateEventParam(ResultID, true))
    end
end

function MissionEventDialogSMS:GenerateEventParam(ResultID, bIsSuccess)
    local Param = {
        ResultID = ResultID,
        IsSuccess = bIsSuccess
    }
    return json.encode(Param)
end

return MissionEventDialogSMS
