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
local BPConst = require("common.const.blueprint_const")
local NpcInteractItemModule = require("mission.npc_interact_item")
local InteractBaseTable = require ("common.data.interact_base_data").data
local NpcBaseData = require("common.data.npc_base_data").data

---@type NpcBehaviorComponent_C
local NpcBehaviorComponent = Component(ComponentBase)
local decorator = NpcBehaviorComponent.decorator

function NpcBehaviorComponent:Initialize(Initializer)
    Super(NpcBehaviorComponent).Initialize(self, Initializer)
    self.bShowingInteractUI = false
    self.DelayResumeInteractUITimer = nil
end


function NpcBehaviorComponent:ReceiveBeginPlay()
    Super(NpcBehaviorComponent).ReceiveBeginPlay(self)
    if self.actor:IsServer() then
        -- server
        local BillboardComponent = self.actor:GetBillboardComponent()
        if BillboardComponent ~= nil then
            BillboardComponent:EnableSelfTalking()
        end
    end

    if self.actor.IdleMontage ~= nil then
        local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.actor.Mesh, self.actor.IdleMontage, 1.0)
    end
end

decorator.message_receiver()
function NpcBehaviorComponent:PostBeginPlay()
    if self.actor:IsClient() then
        self.InteractSphere = self.actor:AddComponentByClass(UE.USphereComponent, false, UE.FTransform.Identity, false)
        self.InteractSphere.OnComponentBeginOverlap:Add(self, self.OnInteractSphereBeginOverlap)
        self.InteractSphere.OnComponentEndOverlap:Add(self, self.OnInteractSphereEndOverlap)
        self.InteractSphere:SetCollisionProfileName("TrapActor", true)
        self.InteractSphere:SetSphereRadius(self.actor.InteractDistance * 100, true)
        if not self.actor:IsGameplayVisible() then
            self.InteractSphere:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
            self.InteractSphere:SetVisibility(false, false)
        end

        -- 手动触发一次, Avatar可能已经在Trigger范围内
        if self:NeedShowInteractUI() then
            local OverlapActors = UE.TArray(UE.AActor)
            self.actor:GetOverlappingActors(OverlapActors)
            for Index=1, OverlapActors:Length() do
                local OverlapActor = OverlapActors:Get(Index)
                if OverlapActor.IsPlayer and OverlapActor:IsPlayer() then
                    self:ShowDefaultInteractUI(OverlapActor)
                    return
                end
            end
        end

    end
end

function NpcBehaviorComponent:IsInteractingWithPlayer()
    return self.InteractPlayer ~= nil
end

-- client
function NpcBehaviorComponent:OnInteractSphereBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if OtherActor.IsPlayer ~= nil and OtherActor:IsPlayer() then
        G.log:debug("xaelpeng", "NpcBehaviorComponent:OnInteractSphereBeginOverlap %s %s %s", self.actor:GetActorID(), OtherActor:GetName(), OtherComp:GetName())
        self.InteractPlayer = OtherActor
        if self:NeedShowInteractUI() then
            self:ShowDefaultInteractUI(OtherActor)
        end
    end
end

-- client
function NpcBehaviorComponent:NeedShowInteractUI()
    if self.DelayResumeInteractUITimer ~= nil then
        return false
    end
    local DialogueComponent = self.actor:GetDialogueComponent()
    if DialogueComponent ~= nil and DialogueComponent:HasAnyDialogue() then
        return true
    end
    if self.MissionInteracts:Length() > 0 then
        return true
    end
    if #self:GetInteractItems() ~= 0 then
        return true
    end

    return false
end

-- client
function NpcBehaviorComponent:GetInteractItems()
    -- 优先返回蓝图上定义的DefaultInteractList，如果没有定义则使用NPC表中定义的数据
    local DialogueComponent = self.actor:GetDialogueComponent()
    if DialogueComponent and DialogueComponent.DefaultInteractList:Num() ~= 0 then
        return DialogueComponent.DefaultInteractList:ToTable()
    end

    if NpcBaseData[self.actor:GetNpcId()].interact then
        return NpcBaseData[self.actor:GetNpcId()].interact
    end

    return {}
end

-- client
function NpcBehaviorComponent:ShowDefaultInteractUI(Player)
    local Items = {}
    local DialogueComponent = self.actor:GetDialogueComponent()
    if DialogueComponent ~= nil then
        local DialogueEntranceItems = DialogueComponent:CreateDialogueEntranceItems(Player)
        for _, NpcDialogueItem in ipairs(DialogueEntranceItems) do
            table.insert(Items, NpcDialogueItem)
        end
    end
    local NpcInteractItems = self:CreateNpcInteractItems()
    for _, NpcInteractItem in ipairs(NpcInteractItems) do
        table.insert(Items, NpcInteractItem)
    end
    self.bShowingInteractUI = true
    if Player.PlayerUIInteractComponent ~= nil then
        Player.PlayerUIInteractComponent:AddNpcInteractItems(self.actor, Items)
    end
end

-- client
function NpcBehaviorComponent:HideDefaultInteractUI(Player)
    if self.bShowingInteractUI then
        if Player.PlayerUIInteractComponent ~= nil then
            Player.PlayerUIInteractComponent:RemoveNpcInteractItems(self.actor:GetActorID())
        end
        self.bShowingInteractUI = false
    end
end



-- client
function NpcBehaviorComponent:OnInteractSphereEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    if self:IsInteractingWithPlayer() and self.InteractPlayer == OtherActor then
        G.log:debug("xaelpeng", "NpcBehaviorComponent:OnInteractSphereEndOverlap %s", OtherActor:GetName())
        local Player = self.InteractPlayer
        self.InteractPlayer = nil
        self:HideDefaultInteractUI(Player)
    end
end

-- client
decorator.message_receiver()
function NpcBehaviorComponent:DefaultDialogueFinish(Player)
    self:DelayResumeInteractUI()
end

-- client
decorator.message_receiver()
function NpcBehaviorComponent:MissionDialogueFinish(Player, DialogueID)
    self:DelayResumeInteractUI()
end

-- client
decorator.message_receiver()
function NpcBehaviorComponent:OnMissionDialoguesUpdate()
    self:UpdateInteractUI()
end

-- client
function NpcBehaviorComponent:UpdateInteractUI()
    if self.InteractPlayer then
        if self.bShowingInteractUI then
            -- refresh
            self:HideDefaultInteractUI(self.InteractPlayer)
            if self:NeedShowInteractUI() then
                self:ShowDefaultInteractUI(self.InteractPlayer)
            end
        else
            -- show
            if self:NeedShowInteractUI() then
                self:ShowDefaultInteractUI(self.InteractPlayer)
            end
        end
    end
end

-- client
function NpcBehaviorComponent:DelayResumeInteractUI()
    if self.DelayResumeInteractUITimer ~= nil then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.DelayResumeInteractUITimer)
        self.DelayResumeInteractUITimer = nil
    end
    self.DelayResumeInteractUITimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.DoResumeInteractUI}, 0.5, false)
    if self.InteractPlayer ~= nil then
        self:HideDefaultInteractUI(self.InteractPlayer)
    end
end

-- client
function NpcBehaviorComponent:DoResumeInteractUI()
    self.DelayResumeInteractUITimer = nil
    if self.InteractPlayer ~= nil then
        if self:NeedShowInteractUI() then
            self:ShowDefaultInteractUI(self.InteractPlayer)
        end
    end
end

-- server
function NpcBehaviorComponent:AppendMissionInteractByEvent(EventID, MissionEventID, InteractID)
    for i = 1, self.MissionInteracts:Length() do
        local MissionInteractItem = self.MissionInteracts:GetRef(i)
        if MissionInteractItem.EventID == EventID then
            MissionInteractItem.MissionEventID = MissionEventID
            MissionInteractItem.InteractID = InteractID
            return
        end
    end
    local MissionInteractItemClass = BPConst.GetMissionInteractItemClass()
    local MissionInteractItem = MissionInteractItemClass()
    MissionInteractItem.EventID = EventID
    MissionInteractItem.MissionEventID = MissionEventID
    MissionInteractItem.InteractID = InteractID
    self.MissionInteracts:Add(MissionInteractItem)
end

-- server
function NpcBehaviorComponent:RemoveMissionInteractByEvent(EventID, MissionEventID, InteractID)
    for i = 1, self.MissionInteracts:Length() do
        local MissionInteractItem = self.MissionInteracts:GetRef(i)
        if MissionInteractItem.EventID == EventID then
            self.MissionInteracts:Remove(i)
            return
        end
    end
end

-- client
function NpcBehaviorComponent:CreateNpcInteractItems()
    local Items = {}
    for i = 1, self.MissionInteracts:Length() do
        local MissionInteractItem = self.MissionInteracts:GetRef(i)
        local InteractID = MissionInteractItem.InteractID
        local ItemSelectecCallback = function()
            self:OnSelectNpcInteractItem(InteractID)
        end
        local Item = NpcInteractItemModule.DefaultInteractEntranceItem.new(self:GetOwner(), InteractBaseTable[InteractID].Name, ItemSelectecCallback, Enum.Enum_InteractType.Normal)
        table.insert(Items, Item)
    end
    return Items
end

-- client
function NpcBehaviorComponent:OnSelectNpcInteractItem(InteractID)
    G.log:debug("xaelpeng", "DialogueComponent:OnSelectNpcInteractItem %d", InteractID)
    if self.InteractPlayer == nil then
        G.log:debug("xaelpeng", "DialogueComponent:OnMissionDialogFinish Player is nil")
        return
    end
    if self.InteractPlayer.PlayerState.MissionAvatarComponent == nil then
        G.log:debug("xaelpeng", "DialogueComponent:OnMissionDialogFinish Player %s has not MissionAvatarComponent", self.InteractPlayer:GetName())
        return
    end

    self.InteractPlayer.PlayerState.MissionAvatarComponent:Server_FinishInteractWithNpc(self.actor, InteractID)
end

-- client
function NpcBehaviorComponent:OnRep_MissionInteracts()
    if self.enabled then
        self:UpdateInteractUI()
    end
end

-- server
function NpcBehaviorComponent:Server_OnPlayerFinishInteract_RPC(InteractID)
    G.log:debug("xaelpeng", "NpcBehaviorComponent:Server_OnPlayerFinishInteract %d", InteractID)
    self.MissionInteractFinished:Broadcast(InteractID)
end

-- client
decorator.message_receiver()
function NpcBehaviorComponent:OnClientUpdateGameplayVisibility()
    if self.InteractSphere ~= nil then
        if self.actor:IsGameplayVisible() then
            self.InteractSphere:SetCollisionEnabled(UE.ECollisionEnabled.QueryAndPhysics)
            self.InteractSphere:SetVisibility(true, false)
        else
            self.InteractSphere:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
            self.InteractSphere:SetVisibility(false, false)
        end
    end
end


-- function M:ReceiveEndPlay()
-- end

-- function M:ReceiveTick(DeltaSeconds)
-- end

return NpcBehaviorComponent
