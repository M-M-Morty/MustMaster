--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"

local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local SubsystemUtils = require("common.utils.subsystem_utils")
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')

---@type BP_ControllerDialogueFlowComponent_C
local ControllerDialogueFlowComponent = Component(ComponentBase)

function ControllerDialogueFlowComponent:Initialize(Initializer)
    Super(ControllerDialogueFlowComponent).Initialize(self, Initializer)
    self.StartDialogueID = 0  -- client
end

function ControllerDialogueFlowComponent:ReceiveBeginPlay()
    if self:GetOwner():IsClient() then
        SubsystemUtils.GetDialogueRuntimeSubsystem(self).OnFlowEndDelegate:Add(self, self.HandleDialogueFlowEnd)
    end
end

function ControllerDialogueFlowComponent:Client_StartDialogueFlow_RPC(DialogueID, Npc, DialogueFlow, NpcActorIdList)
    self:StartDialogueFlow(DialogueID, Npc, DialogueFlow, NpcActorIdList)
end

-- client
function ControllerDialogueFlowComponent:StartDialogueFlow(DialogueID, Npc, DialogueFlow, NpcActorIdList)
    self.StartDialogueID = DialogueID
    self.DialogueAsset = DialogueFlow

    local CharacterList = UE.TArray(UE.ACharacter)
    local MutableActorSubSystem = SubsystemUtils.GetMutableActorSubSystem(self)
    for i = 1, NpcActorIdList:Length() do
        local NpcActorId = NpcActorIdList[i]
        local NpcActor = MutableActorSubSystem:GetClientMutableActor(NpcActorId)
        if NpcActor then
            CharacterList:Add(NpcActor)
        end
    end
    self:SetCharacterBindingListInLevel(CharacterList)
    self:StartRootFlow(Npc)
    self:StartShowFlowWidget()
end

function ControllerDialogueFlowComponent:StartShowFlowWidget()
    G.log:info("UICommunicationShakeSpeareWidget", "StartShowFlowWidget")
    UIManager:SetOverridenInputMode(UIManager.OverridenInputMode.UIOnly, false)
    UIManager:HideAllHUD()
end

function ControllerDialogueFlowComponent:StopShowFlowWidget()
    G.log:info("UICommunicationShakeSpeareWidget", "StopShowFlowWidget")
    UIManager:SetOverridenInputMode('')
    UIManager:RecoverShowAllHUD()
end

-- client
function ControllerDialogueFlowComponent:HandleDialogueFlowEnd(ParamStr)
    G.log:debug("ControllerDialogueFlowComponent", "HandleDialogueFlowEnd, DialogueID=%s", ParamStr)
    local DialogueID = tonumber(ParamStr)
    if DialogueID == nil then
        G.log:error("ControllerDialogueFlowComponent:HandleDialogueFlowEnd", "ParamStr(%s) Wrong", ParamStr)
        return
    end
    self.OnDialogueFlowEnd:Broadcast(self.StartDialogueID, DialogueID)
    self:Server_FinishDialogueFlow(self.StartDialogueID, DialogueID)
    self.StartDialogueID = 0
    self.DialogueAsset = nil
    self:StopShowFlowWidget()
end

function ControllerDialogueFlowComponent:Server_FinishDialogueFlow_RPC(StartDialogueID, DialogueResultID)
    self.OnDialogueFlowEnd:Broadcast(StartDialogueID, DialogueResultID)
end

-- client
function ControllerDialogueFlowComponent:IsPlayingFlow()
    return self.StartDialogueID ~= 0
end

return ControllerDialogueFlowComponent
