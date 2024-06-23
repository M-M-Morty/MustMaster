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
local SubsystemUtils = require("common.utils.subsystem_utils")
local MissionEventOnActorBase = require("mission.mission_event.mission_event_onactor_base")

---@type BP_MissionEvent_PlayDialogueFlow_C
local MissionEventPlayDialogueFlow = Class(MissionEventOnActorBase)

function MissionEventPlayDialogueFlow:GenerateEventRegisterParam()
    local DialogueFlowPath = UE.UKismetSystemLibrary.GetPathName(self.DialogueFlow)
    local ActorIdList = self.NpcActorIdList:ToTable()
    local Param = {
        DialogueID = self.DialogueID,
        DialogueFlowPath = DialogueFlowPath,
        TriggerType = self.TriggerType,
        TriggerRadius = self.TriggerRadius,
        ActorIdList = ActorIdList
    }
    return json.encode(Param)
end

function MissionEventPlayDialogueFlow:OnEvent(EventParamStr)
    Super(MissionEventPlayDialogueFlow).OnEvent(self, EventParamStr)
    self:HandleComplete(EventParamStr)
end

function MissionEventPlayDialogueFlow:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventPlayDialogueFlow).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    local PlayerController = SubsystemUtils.GetMutableActorSubSystem(self):GetHostPlayerController()
    if PlayerController == nil or PlayerController.ControllerDialogueFlowComponent == nil then
        G.log:error("MissionEventPlayDialogueFlow:RegisterOnTarget", "PlayerController doesn't have ControllerDialogueFlowComponent")
        return
    end
    local Param = json.decode(EventRegisterParamStr)
    self.DialogueID = Param.DialogueID
    self.TriggerType = Param.TriggerType
    self.TriggerRadius = Param.TriggerRadius
    local DialogueFlow = UE.UObject.Load(Param.DialogueFlowPath)
    if DialogueFlow == nil then
        -- 未配置DialogueFlow, 直接返回
        G.log:error("MissionEventPlayDialogueFlow:RegisterOnTarget", "DialogueFlow is nil")
        self:DispatchEvent(self:GenerateEventParam(0))
        return
    end

    local ActorIdList = Param.ActorIdList
    local ActorIdArray = UE.TArray(UE.FString)
    for _, ActorId in ipairs(ActorIdList) do
        ActorIdArray:Add(ActorId)
    end

    PlayerController.ControllerDialogueFlowComponent.OnDialogueFlowEnd:Add(self, self.HandleDialogueFinished)

    if PlayerController.PlayerState == Actor then
        -- 玩家单人叙事，仅支持自动播放
        self.TriggerType = Enum.EDialogueFlowTriggerType.AutoStart
        PlayerController.ControllerDialogueFlowComponent:Client_StartDialogueFlow(self.DialogueID, nil, DialogueFlow, ActorIdArray)
        return
    end

    if self.TriggerType == Enum.EDialogueFlowTriggerType.DialogueStart then
        Actor.DialogueComponent:AddDialogueFlow(self.DialogueID, DialogueFlow, ActorIdArray)
        Actor.DialogueComponent:AppendMissionDialogueByEvent(self.EventID, self.MissionEventID, self.DialogueID, Enum.EDialogueType.DialogueFlow)
    elseif self.TriggerType == Enum.EDialogueFlowTriggerType.AutoStart then
        PlayerController.ControllerDialogueFlowComponent:Client_StartDialogueFlow(self.DialogueID, Actor, DialogueFlow, ActorIdArray)
    elseif self.TriggerType == Enum.EDialogueFlowTriggerType.TriggerStart then
        Actor.DialogueComponent:AddDialogueFlowTrigger(self.TriggerRadius, self.DialogueID, DialogueFlow, ActorIdArray)
    end
end

function MissionEventPlayDialogueFlow:UnregisterOnTarget(Actor)
    Super(MissionEventPlayDialogueFlow).UnregisterOnTarget(self, Actor)
    local PlayerController = SubsystemUtils.GetMutableActorSubSystem(self):GetHostPlayerController()
    PlayerController.ControllerDialogueFlowComponent.OnDialogueFlowEnd:Remove(self, self.HandleDialogueFinished)
    if self.TriggerType == Enum.EDialogueFlowTriggerType.DialogueStart then
        Actor.DialogueComponent:RemoveDialogueFlow(self.DialogueID)
        Actor.DialogueComponent:RemoveMissionDialogueByEvent(self.EventID, self.MissionEventID, self.DialogueID)
    elseif self.TriggerType == Enum.EDialogueFlowTriggerType.TriggerStart then
        Actor.DialogueComponent:RemoveDialogueFlowTrigger(self.DialogueID)
    end
end

function MissionEventPlayDialogueFlow:HandleDialogueFinished(StartDialogueID, ResultID)
    G.log:debug("MissionEventPlayDialogueFlow", "HandleDialogueFinished, StartDialogueID=%s, ResultID=%s", StartDialogueID, ResultID)
    if self.DialogueID ~= StartDialogueID then
        return
    end

    self:DispatchEvent(self:GenerateEventParam(ResultID))
end

function MissionEventPlayDialogueFlow:GenerateEventParam(ResultID)
    local Param = {
        ResultID = ResultID
    }
    return json.encode(Param)
end

return MissionEventPlayDialogueFlow
