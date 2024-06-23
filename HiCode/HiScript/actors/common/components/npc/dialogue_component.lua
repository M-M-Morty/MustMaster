--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")

local Component = require("common.component")
local ComponentBase = require("common.componentbase")
local NpcInteractItemModule = require("mission.npc_interact_item")
local DialogueObjectModule = require("mission.dialogue_object")
local SubsystemUtils = require("common.utils.subsystem_utils")
local BPConst = require("common.const.blueprint_const")

---@type DialogueComponent_C
local DialogueComponent = Component(ComponentBase)
local decorator = DialogueComponent.decorator

function DialogueComponent:Initialize(Initializer)
    Super(DialogueComponent).Initialize(self, Initializer)
    self.bLocalHasBeenTalked = false
    self.CurrentRunningDialogue = nil
    self.DialogingPlayer = nil
    self.DialogueFlowTrigger = nil  -- client
end

function DialogueComponent:GetNpcId()
    return self:GetOwner():GetNpcId()
end

function DialogueComponent:GetNpcDisplayName()
    return self:GetOwner():GetNpcDisplayName()
end

-- server
function DialogueComponent:AppendMissionDialogueByEvent(EventID, MissionEventID, DialogueID, DialogueType)
    for i = 1, self.MissionDialogues:Length() do
        local MissionDialogueItem = self.MissionDialogues:GetRef(i)
        if MissionDialogueItem.EventID == EventID then
            MissionDialogueItem.MissionEventID = MissionEventID
            MissionDialogueItem.DialogueID = DialogueID
            MissionDialogueItem.DialogueType = DialogueType
            return
        end
    end
    local MissionDialogueItemClass = BPConst.GetMissionDialogueItemClass()
    local MissionDialogueItem = MissionDialogueItemClass()
    MissionDialogueItem.EventID = EventID
    MissionDialogueItem.MissionEventID = MissionEventID
    MissionDialogueItem.DialogueID = DialogueID
    MissionDialogueItem.DialogueType = DialogueType
    self.MissionDialogues:Add(MissionDialogueItem)
end

-- server
function DialogueComponent:RemoveMissionDialogueByEvent(EventID, MissionEventID, DialogueID)
    for i = 1, self.MissionDialogues:Length() do
        local MissionDialogueItem = self.MissionDialogues:GetRef(i)
        if MissionDialogueItem.EventID == EventID then
            self.MissionDialogues:Remove(i)
            return
        end
    end
end

-- client
function DialogueComponent:CreateDialogueEntranceItems(Player)
    local Items = {}
    if not self:HasAnyDialogue() then
        return Items
    end

    for Index = 1, self.MissionDialogues:Length() do
        local MissionDialogueItem = self.MissionDialogues:GetRef(Index)
        local DialogueID = MissionDialogueItem.DialogueID
        local DialogueObject = self:CreateMissionDialogueObject(Player, DialogueID)
        local ItemSelectecCallback = nil
        if MissionDialogueItem.DialogueType == Enum.EDialogueType.Normal then
            ItemSelectecCallback = function()
                self:OnSelectDialogueEntrance(Player, DialogueObject)
            end
        elseif MissionDialogueItem.DialogueType == Enum.EDialogueType.DialogueFlow then
            ItemSelectecCallback = function()
                Player.PlayerUIInteractComponent:FroceCloseSituation()
                local DialogueFlowItem = self:GetDialogueFlowItem(DialogueID)
                local Controller = UE.UGameplayStatics.GetPlayerController(self, 0)
                Controller.ControllerDialogueFlowComponent:StartDialogueFlow(DialogueID, self:GetOwner(), 
                    DialogueFlowItem.DialogueFlowAsset, DialogueFlowItem.NpcActorIdList)
            end
        end
        local Item = NpcInteractItemModule.MissionDialogueItem.new(DialogueID, MissionDialogueItem.MissionEventID, ItemSelectecCallback)
        table.insert(Items, Item)
    end

    return Items
end

-- client
function DialogueComponent:OnSelectDialogueEntrance(Player, DialogueObject)
    G.log:debug("xaelpeng", "DialogueComponent:OnSelectDialogueEntrance %s", DialogueObject)
    if DialogueObject == nil then
        return
    end
    
    if Player and Player.PlayerUIInteractComponent ~= nil then
        self.DialogingPlayer = Player
        self.CurrentRunningDialogue = DialogueObject
        Player.PlayerUIInteractComponent:StartDialogue(DialogueObject)
    end
end

-- client
function DialogueComponent:HasAnyDialogue()
    if self.MissionDialogues:Length() == 0 then
        -- 策划需求：当NPC没有默认对话，且没有任务对话时，不弹交互框
        return false
    end
    return true
end

-- client
function DialogueComponent:CreateMissionDialogueObject(Player, DialogueID)
    -- local Talkers = {}
    -- Talkers[0] = "Player"
    -- Talkers[1] = self:GetNpcDisplayName()

    local DialogueObject = DialogueObjectModule.Dialogue.new(DialogueID, self)
    DialogueObject:SetEnableSaveHistory(true)
    if self:GetOwner().NpcID then
        DialogueObject:SetNpcID(self:GetOwner().NpcID)
    end

    local FinishCallback = function()
        local StartDialogueID = DialogueObject:GetStartDialogueID()
        local FinishDialogueID = DialogueObject:GetFinishDialogueID()

        self.DialogueObject = nil
        self:OnMissionDialogFinish(DialogueID, FinishDialogueID, Player, DialogueObject.HistoryRecord)
    end
    DialogueObject:SetFinishCallback(FinishCallback)
    return DialogueObject
end

-- client
function DialogueComponent:CreateMissionDialogueInteractItem(MissionEventID, DialogueID, Player)
    local MissionFlowSubsystem = SubsystemUtils.GetMissionFlowSubsystem(self:GetOwner())
    local Identifier = MissionFlowSubsystem:GetMissionEventIdentifier(MissionEventID)
    local ItemSelectecCallback = function()
        self:OnSelectStartMissionDialogue(DialogueID, Player)
    end
    G.log:debug("xaelpeng", "DialogueComponent:CreateMissionDialogueInteractItem MissionID:%d MissionEventID:%d DialogueID:%d", Identifier.MissionID, MissionEventID, DialogueID)
    local Item = NpcInteractItemModule.MissionDialogueItem.new(DialogueID, MissionEventID, ItemSelectecCallback)
    return Item
end

-- client
function DialogueComponent:OnSelectStartMissionDialogue(DialogueID, Player)
    G.log:debug("xaelpeng", "DialogueComponent:OnSelectStartMissionDialogue %s DialogueID:%d", self.actor:GetName(), DialogueID)
    local DialogueObject = self:CreateMissionDialogueObject(Player, DialogueID)
    if Player and Player.PlayerUIInteractComponent ~= nil then
        self.DialogingPlayer = Player
        self.CurrentRunningDialogue = DialogueObject
        Player.PlayerUIInteractComponent:StartDialogue(DialogueObject)
    end
end

-- client
function DialogueComponent:GetTalkerName(TalkerID)
    if TalkerID == DialogueObjectModule.DialogueStepOwnerType.PLAYER then
        return "Player"
    end
    if TalkerID == DialogueObjectModule.DialogueStepOwnerType.NPC then
        return self:GetNpcDisplayName()
    end
    local Actor = SubsystemUtils.GetMutableActorSubSystem(self:GetOwner()):GetClientMutableActor(tostring(TalkerID))
    if Actor ~= nil then
        if Actor.GetNpcDisplayName ~= nil then
            return Actor:GetNpcDisplayName()
        end
    end
end

-- client
function DialogueComponent:GetDefaultTalkerName()
    return self:GetNpcDisplayName()
end

-- client
function DialogueComponent:OnMissionDialogFinish(DialogueID, ResultID, Player, DialogueRecord)
    G.log:debug("xaelpeng", "DialogueComponent:OnMissionDialogFinish %d ResultID:%d", DialogueID, ResultID)
    self.DialogingPlayer = nil
    self.CurrentRunningDialogue = nil
    if Player == nil then
        G.log:debug("xaelpeng", "DialogueComponent:OnMissionDialogFinish Player is nil")
        return
    end
    if Player.PlayerState.MissionAvatarComponent == nil then
        G.log:debug("xaelpeng", "DialogueComponent:OnMissionDialogFinish Player %s has not MissionAvatarComponent", Player:GetName())
        return
    end

    Player.PlayerState.MissionAvatarComponent:Server_FinishMissionDialogueWithNpc(self.actor, DialogueID, ResultID, DialogueRecord)
    self:SendMessage("MissionDialogueFinish", Player, DialogueID)
end

-- client
function DialogueComponent:OnDefaultDialogFinish(Player)
    self.DialogingPlayer = nil
    self.CurrentRunningDialogue = nil
    self.bLocalHasBeenTalked = true
    Player.PlayerState.MissionAvatarComponent:Server_FinishDefaultDialogueWithNpc(self.actor)
    self:SendMessage("DefaultDialogueFinish", Player)
end

-- client
function DialogueComponent:OnRep_MissionDialogues()
    if self.enabled then
        self:SendMessage("OnMissionDialoguesUpdate")
    end
end

-- server
function DialogueComponent:Server_OnMissionDialogueFinish_RPC(DialogueID, ResultID, DialogueRecord)
    G.log:debug("xaelpeng", "DialogueComponent:Server_OnMissionDialogueFinish %d ResultID:%d", DialogueID, ResultID)
    self.MissionDialogFinished:Broadcast(DialogueID, ResultID, DialogueRecord)
end

-- server
function DialogueComponent:Server_OnDefaultDialogueFinish_RPC()
    G.log:debug("xaelpeng", "DialogueComponent:Server_OnDefaultDialogueFinish")
    self.bHasBeenTalked = true
end

-- client
decorator.message_receiver()
function DialogueComponent:OnClientUpdateGameplayVisibility()
    if self.CurrentRunningDialogue ~= nil and self.DialogingPlayer ~= nil then
        G.log:debug("xaelpeng", "DialogueComponent:OnClientUpdateGameplayVisibility close dialouge %s", self:GetName())
        local Player = self.DialogingPlayer
        local DialougeObject = self.CurrentRunningDialogue
        self.DialogingPlayer = nil
        self.CurrentRunningDialogue = nil
        Player.PlayerUIInteractComponent:ForceFinishDialogue(DialougeObject)
    end
end

-- server
function DialogueComponent:AddDialogueFlow(DialogueID, DialogueFlow, ActorIdArray)
    local DialogueFlowItem = Struct.BPS_DialogueFlowItem()
    DialogueFlowItem.DialogueID = DialogueID
    DialogueFlowItem.DialogueFlowAsset = DialogueFlow
    DialogueFlowItem.NpcActorIdList = ActorIdArray
    self.DialogueFlowList:Add(DialogueFlowItem)
end

-- server
function DialogueComponent:RemoveDialogueFlow(DialogueID)
    for Index = 1, self.DialogueFlowList:Num() do
        local DialogueFlowItem = self.DialogueFlowList:GetRef(Index)
        if DialogueFlowItem.DialogueID == DialogueID then
            self.DialogueFlowList:Remove(Index)
            return
        end
    end
end

-- server
function DialogueComponent:GetDialogueFlowItem(DialogueID)
    for Index = 1, self.DialogueFlowList:Num() do
        local DialogueFlowItem = self.DialogueFlowList:GetRef(Index)
        if DialogueFlowItem.DialogueID == DialogueID then
            return DialogueFlowItem
        end
    end
    return nil
end

-- server
function DialogueComponent:AddDialogueFlowTrigger(Radius, DialogueID, DialogueFlowAsset, NpcActorIdList)
    self.DialogueFlowTriggerData.DialogueFlowAsset = DialogueFlowAsset
    self.DialogueFlowTriggerData.NpcActorIdList = NpcActorIdList
    self.DialogueFlowTriggerData.TriggerRadius = Radius
    self.DialogueFlowTriggerData.DialogueID = DialogueID
end

-- server
function DialogueComponent:RemoveDialogueFlowTrigger(DialogueID)
    if self.DialogueFlowTriggerData.DialogueID == DialogueID then
        self.DialogueFlowTriggerData.DialogueFlowAsset = nil
        self.DialogueFlowTriggerData.NpcActorIdList:Clear()
        self.DialogueFlowTriggerData.TriggerRadius = 0
        self.DialogueFlowTriggerData.DialogueID = 0
    end
end

function DialogueComponent:OnRep_DialogueFlowTriggerData()
    G.log:debug("DialogueComponent", "OnRep_DialogueFlowTriggerData %s %s %s %s", self.DialogueFlowTriggerData.DialogueID, 
        self.DialogueFlowTriggerData.DialogueFlowAsset, self.DialogueFlowTriggerData.NpcActorIdList:Num(),
        self.DialogueFlowTriggerData.TriggerRadius)
    if self.DialogueFlowTriggerData.DialogueID == 0 then
        -- 清空trigger
        if self.DialogueFlowTrigger ~= nil then
            UE.UHiUtilsFunctionLibrary.DestroyComponent(self.DialogueFlowTrigger)
            self.DialogueFlowTrigger = nil
        end
    else
        -- 创建trigger
        if self.DialogueFlowTrigger ~= nil then
            G.log:error("DialogueComponent", "OnRep_DialogueFlowTriggerData DialogueFlowTrigger exist")
            UE.UHiUtilsFunctionLibrary.DestroyComponent(self.DialogueFlowTrigger)
            self.DialogueFlowTrigger = nil
        end
        self:CreateDialogueFlowTrigger()
    end
end

-- client
function DialogueComponent:CreateDialogueFlowTrigger()
    local Radius = self.DialogueFlowTriggerData.TriggerRadius
    self.DialogueFlowTrigger = self:GetOwner():AddComponentByClass(UE.USphereComponent, false, UE.FTransform.Identity, false)
    self.DialogueFlowTrigger:SetCollisionProfileName("TrapActor", true)
    self.DialogueFlowTrigger:SetSphereRadius(Radius, true)
    self.DialogueFlowTrigger.OnComponentBeginOverlap:Add(self, self.OnDialogueFlowTriggerBeginOverlap)
    G.log:debug("DialogueComponent", "CreateDialogueFlowTrigger, Radius=%s", Radius)
    -- 手动触发一次, Avatar可能已经在Trigger范围内
    local OverlapActors = UE.TArray(UE.AActor)
    self.actor:GetOverlappingActors(OverlapActors)
    for Index=1, OverlapActors:Length() do
        local OverlapActor = OverlapActors:Get(Index)
        if OverlapActor.IsPlayer and OverlapActor:IsPlayer() then
            self:PlayDialogueFlow()
            return
        end
    end
end

-- client
function DialogueComponent:OnDialogueFlowTriggerBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if OtherActor.IsPlayer == nil or not OtherActor:IsPlayer() then
        return
    end
    self:PlayDialogueFlow()
end

-- client
function DialogueComponent:PlayDialogueFlow()
    G.log:debug("DialogueComponent", "PlayDialogueFlow %s, %s", self.DialogueFlowTriggerData.DialogueID, self.DialogueFlowTriggerData.DialogueFlowAsset)
    if not self.DialogueFlowTriggerData.DialogueFlowAsset then
        G.log:error("DialogueComponent", "PlayDialogueFlow No DialogueFlowAsset, %s", self.DialogueFlowTriggerData.DialogueFlowAsset)
    end
    if self.DialogueFlowTrigger then
        -- 关闭trigger
        UE.UHiUtilsFunctionLibrary.DestroyComponent(self.DialogueFlowTrigger)
        self.DialogueFlowTrigger = nil
    end
    if self.DialogueFlowTriggerData.DialogueFlowAsset then
        -- 播放叙事
        local Controller = UE.UGameplayStatics.GetPlayerController(self, 0)
        Controller.ControllerDialogueFlowComponent:StartDialogueFlow(self.DialogueFlowTriggerData.DialogueID, self:GetOwner(), 
            self.DialogueFlowTriggerData.DialogueFlowAsset, self.DialogueFlowTriggerData.NpcActorIdList)
    end
end

-- server
function DialogueComponent:OnDialogueBegin()
    if self.actor.NpcIntentionComponent:InNormal() then
        self.actor.NpcStateMachineComponent:ChangeState(Enum.BPE_NpcAiState.Dialogue)
    end
end

-- server
function DialogueComponent:OnDialogueEnd()
    if self.actor.NpcIntentionComponent:InNormal() then
        self.actor.NpcStateMachineComponent:ChangeToPrevState()
    end
end

return DialogueComponent
