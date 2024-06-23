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
local SubsystemUtils = require("common.utils.subsystem_utils")

---@type BP_MissionEvent_DialogueSubmitItem_C
local MissionEventDialogueSubmitItem = Class(MissionEventOnActorBase)

function MissionEventDialogueSubmitItem:GenerateEventRegisterParam()
    local Param = {
        DialogueID = self.DialogueID,
        SubmitItemInfo = self.SubmitItemInfo:ExportText()
    }
    return json.encode(Param) 
end

function MissionEventDialogueSubmitItem:OnEvent(EventParamStr)
    Super(MissionEventDialogueSubmitItem).OnEvent(self, EventParamStr)
    self:HandleComplete(EventParamStr)
end

function MissionEventDialogueSubmitItem:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventDialogueSubmitItem).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    local Param = json.decode(EventRegisterParamStr)
    self.DialogueID = Param.DialogueID
    self.SubmitItemInfo:ImportText(Actor, Param.SubmitItemInfo)
    local PlayerState = SubsystemUtils.GetMutableActorSubSystem(Actor):GetHostPlayerState()
    Actor.DialogueComponent:AppendMissionDialogueByEvent(self.EventID, self.MissionEventID, self.DialogueID, Enum.EDialogueType.Normal)
    PlayerState.MissionAvatarComponent:AddDialogueSubmitItemInfo(self.DialogueID, self.SubmitItemInfo)
    PlayerState.MissionAvatarComponent.EventOnDialogueSubmitItems:Add(self, self.HandleSubmitItems)
end

function MissionEventDialogueSubmitItem:UnregisterOnTarget(Actor)
    Super(MissionEventDialogueSubmitItem).UnregisterOnTarget(self, Actor)
    Actor.DialogueComponent:RemoveMissionDialogueByEvent(self.EventID, self.MissionEventID, self.DialogueID)
    local PlayerState = SubsystemUtils.GetMutableActorSubSystem(Actor):GetHostPlayerState()
    PlayerState.MissionAvatarComponent.EventOnDialogueSubmitItems:Remove(self, self.HandleSubmitItems)
end

function MissionEventDialogueSubmitItem:HandleSubmitItems(DialogueID)
    if DialogueID ~= self.DialogueID then
        return
    end
    self:DispatchEvent(self:GenerateEventParam())
end

function MissionEventDialogueSubmitItem:GenerateEventParam()
    local Param = {}
    return json.encode(Param)
end

return MissionEventDialogueSubmitItem
