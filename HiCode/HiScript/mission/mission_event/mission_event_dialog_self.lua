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
local MissionEventBase = require("mission.mission_event.mission_event_base")
local BPConst = require("common.const.blueprint_const")

---@type BP_MissionEventDialogSelf_C
local MissionEventDialogSelf = Class(MissionEventBase)

function MissionEventDialogSelf:OnActive()
    Super(MissionEventDialogSelf).OnActive(self)
    self:RegisterEventOnActorByTag("HiGamePlayer", self:GenerateEventRegisterParam())
end

function MissionEventDialogSelf:OnInactive()
    self:UnregisterEventOnActorByTag("HiGamePlayer")
    Super(MissionEventDialogSelf).OnInactive(self)
end


function MissionEventDialogSelf:GenerateEventRegisterParam()
    G.log:debug("xaelpeng", "MissionEventDialogSelf:GenerateEventRegisterParam DialogueID %d", self.DialogueID)
    local Param = {
        DialogueID = self.DialogueID
    }
    return json.encode(Param)
end

function MissionEventDialogSelf:OnEvent(EventParamStr)
    Super(MissionEventDialogSelf).OnEvent(self, EventParamStr)
    self:HandleOnceComplete(EventParamStr)
    self:HandleComplete(EventParamStr)
end

function MissionEventDialogSelf:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventDialogSelf).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    if Actor.MissionAvatarComponent == nil then
        G.log:error("xaelpeng", "MissionEventDialogSelf:RegisterOnTarget Actor %s not has DialogueComponent", Actor:GetName())
        return
    end
    local Param = json.decode(EventRegisterParamStr)
    self.DialogueID = Param.DialogueID
    Actor.MissionAvatarComponent:SetSelfDialogue(self.DialogueID)
    Actor.MissionAvatarComponent.SelfDialogFinished:Add(self, self.OnDialogFinished)
end

function MissionEventDialogSelf:UnregisterOnTarget(Actor)
    Super(MissionEventDialogSelf).UnregisterOnTarget(self, Actor)
    Actor.MissionAvatarComponent:ResetSelfDialogue(self.DialogueID)
    Actor.MissionAvatarComponent.SelfDialogFinished:Remove(self, self.OnDialogFinished)
end

function MissionEventDialogSelf:OnDialogFinished(DialogueID, ResultID)
    G.log:debug("xaelpeng", "MissionEventDialogSelf:OnDialogFinished DialogueID:%d ResultID:%d", DialogueID, ResultID)
    if DialogueID == self.DialogueID then
        self:DispatchEvent(self:GenerateEventParam(ResultID))
    end
end

function MissionEventDialogSelf:GenerateEventParam(ResultID)
    local Param = {
        ResultID = ResultID
    }
    return json.encode(Param)
end

return MissionEventDialogSelf
