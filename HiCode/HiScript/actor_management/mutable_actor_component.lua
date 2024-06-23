--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require("G")
local SubsystemUtils = require ("common.utils.subsystem_utils")
local BPConst = require ("common.const.blueprint_const")
local GlobalActorConst = require("common.const.global_actor_const")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

---@type BP_MutableActorComponent_C
local MutableActorComponent = Component(ComponentBase)
local decorator = MutableActorComponent.decorator



function MutableActorComponent:Initialize(Initializer)
    Super(MutableActorComponent).Initialize(self, Initializer)
    self.ActionRecords = {}
    self.RemoveTimer = nil
    self.AutoDestroyTimer = nil
end

function MutableActorComponent:OnInitializeComponent()
    if UE.UKismetSystemLibrary.IsServer(self:GetOwner()) then
        if self:GetOwner():HasAuthority() then
            local HiEditorDataCompClass = UE.UClass.Load(BPConst.HiEditorDataComp)
            local HiEditorDataComp = self:GetOwner():GetComponentByClass(HiEditorDataCompClass)
            G.log:debug("xaelpeng", "MutableActorComponent:OnInitializeComponent %s", HiEditorDataComp)
            if HiEditorDataComp ~= nil then
                local InitializeCallback = function ()
                    -- 初始化存盘属性
                    self:LoadActorPropertiesFromEntity()
                end
                -- 等待初始化关卡铺设工具配置的默认属性
                HiEditorDataComp:AddInitializeCallback(InitializeCallback)
            else
                self:LoadActorPropertiesFromEntity()
            end
        end
    end
end

function MutableActorComponent:InitializeActorTags()
    local Actor = self:GetOwner()
    -- EditorTags will be deprecated in the future, replaced by EditorGameplayTags
    if Actor.EditorTags ~= nil then
        local RuntimeTags = self:GetRuntimeTags()
        for i = 1, RuntimeTags:Length() do
            Actor.EditorTags:Add(RuntimeTags:Get(i))
        end
    end
    if Actor.EditorGameplayTags ~= nil then
        local RuntimeTags = self:GetRuntimeTags()
        for i = 1, RuntimeTags:Length() do
            local GameplayTag = UE.UHiEdRuntime.RequestGameplayTag(RuntimeTags:Get(i))
            if GameplayTag.TagName ~= "None" then
                Actor.EditorGameplayTags:Add(GameplayTag)
            end
        end
    end
end


function MutableActorComponent:OnUninitializeComponent()
    G.log:debug("xaelpeng", "MutableActorComponent:OnUninitializeComponent %s ActorID:%s", self:GetOwner():GetName(), self:GetActorID())
    if self.RemoveTimer ~= nil then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.RemoveTimer)
        self.RemoveTimer = nil
    end
    if self.AutoDestroyTimer ~= nil then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.AutoDestroyTimer)
        self.AutoDestroyTimer = nil
    end
end

function MutableActorComponent:ReceiveBeginPlay()
    G.log:debug("xaelpeng", "MutableActorComponent:ReceiveBeginPlay %s %s", self:GetOwner():GetName(), self:GetActorID())
    Super(MutableActorComponent).ReceiveBeginPlay(self)
    if UE.UKismetSystemLibrary.IsServer(self:GetOwner()) then
        self:RegisterMutableActor()
        self:UpdateRemoveTimer()
    else
        SubsystemUtils.GetMutableActorSubSystem(self:GetOwner()):RegisterClientMutableActor(self:GetActorID(), self:GetOwner())
        -- self:UpdateActiveClientEvents()
    end
end

function MutableActorComponent:ReceiveEndPlay(EndPlayReason)
    if UE.UKismetSystemLibrary.IsServer(self:GetOwner()) then
        self:UnregisterMutableActor()
    else
        SubsystemUtils.GetMutableActorSubSystem(self:GetOwner()):UnregisterClientMutableActor(self:GetActorID(), self:GetOwner())
    end

    G.log:debug("xaelpeng", "MutableActorComponent:ReceiveEndPlay %s %s EndPlayReason:%d", self:GetOwner():GetName(), self:GetActorID(), EndPlayReason)
    Super(MutableActorComponent).ReceiveEndPlay(self, EndPlayReason)
end

function MutableActorComponent:RegisterMutableActor()
    SubsystemUtils.GetMutableActorSubSystem(self:GetOwner()):RegisterMutableActor(self:GetActorID(), self:GetOwner())
end

function MutableActorComponent:UnregisterMutableActor()
    SubsystemUtils.GetMutableActorSubSystem(self:GetOwner()):UnregisterMutableActor(self:GetActorID())
end

function MutableActorComponent:OnActorPropertiesLoadedFromEntity()
    self:InitializeActorTags()
    local GameplayProperties = self:GetEntityGameplayProperties()
    if GameplayProperties ~= nil then 
        G.log:debug("xaelpeng", "OnActorPropertiesLoadedFromEntity ActorID:%s %s", self.ActorID, GameplayProperties:DebugString())
    else
        G.log:debug("xaelpeng", "OnActorPropertiesLoadedFromEntity ActorID:%s nil", self.ActorID)
    end
    if self:GetOwner().OnLoadFromDatabase then
        self:GetOwner():OnLoadFromDatabase(GameplayProperties)
    end
    local Components = self:GetOwner():K2_GetComponentsByClass(UE.UActorComponent)
    for Index = 1, Components:Length() do
        local Component = Components:Get(Index)
        if Component and Component.OnLoadFromDatabase then
            Component:OnLoadFromDatabase(GameplayProperties)
        end
    end
end

function MutableActorComponent:OnActorLoadedFinish()
    if self:GetOwner().GetSaveStrategy then
        self:SetSaveStrategy(self:GetOwner():GetSaveStrategy())
    else
        self:SetSaveStrategy(UE.EActorSaveStrategy.Strategy_SaveOnDestroy)
    end
end

function MutableActorComponent:OnActorPropertiesSavedToEntity()
    local GameplayProperties = self:GetEntityGameplayProperties()
    if self:GetOwner().OnSaveToDatabase then
        self:GetOwner():OnSaveToDatabase(GameplayProperties)
    end
    local Components = self:GetOwner():K2_GetComponentsByClass(UE.UActorComponent)
    for Index = 1, Components:Length() do
        local Component = Components:Get(Index)
        if Component and Component.OnSaveToDatabase then
            Component:OnSaveToDatabase(GameplayProperties)
        end
    end
end

function MutableActorComponent:OnActorSavedFinish()
    local Properties = self:GetEntityProperties()
    if Properties ~= nil then
        G.log:debug("xaelpeng", "OnActorSavedFinish Actor:%s SaveData %s", self.ActorID, Properties:DebugString())
    else
        G.log:error("xaelpeng", "OnActorSavedFinish Actor:%s Properties not found", self.ActorID)
    end
end


function MutableActorComponent:GetActorID()
    return self.ActorID
end

function MutableActorComponent:GetActorTypeID()
    return self.ActorTypeID
end

function MutableActorComponent:GetEntityProperties()
    local Entity = self:GetEntity()
    if Entity ~= nil then
        return Entity:GetProperties()
    end
    return nil
end

function MutableActorComponent:GetEntityGameplayProperties()
    local Entity = self:GetEntity()
    if Entity ~= nil then
        return Entity:GetGameplayProperties()
    end
    return nil
end

function MutableActorComponent:GetRuntimeTags()
    local Tags = UE.TArray(UE.FString)
    local Properties = self:GetEntityProperties()
    if Properties ~= nil then
        local PropertyTags = Properties.Tags
        for i = 1, PropertyTags:Size() do
            Tags:Add(PropertyTags:Get(i))
        end
    end
    return Tags
end


function MutableActorComponent:UpdateRemoveTimer()
    if self.RemoveTimer ~= nil then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.RemoveTimer)
        self.RemoveTimer = nil
    end

    local Properties = self:GetEntityProperties()
    if Properties ~= nil then
        local RemoveTime = Properties.RemoveTime
        if RemoveTime > 0 then
            local DeltaTime = RemoveTime - os.time()
            G.log:debug("xaelpeng", "MutableActorComponent:UpdateRemoveTimer %s DeltaTime:%s", self:GetActorID(), DeltaTime)
            if DeltaTime > 0 then
                self.RemoveTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.DoRemove}, DeltaTime, false)
            else
                self.RemoveTimer = UE.UKismetSystemLibrary.K2_SetTimerForNextTickDelegate({self, self.DoRemove})
            end
        end
    end
end

function MutableActorComponent:DoRemove()
    self.RemoveTimer = nil
    SubsystemUtils.GetMutableActorSubSystem(self:GetOwner()):DestroyLocalRuntimeActor(self:GetActorID(), self:GetOwner())
end


function MutableActorComponent:NotifyAutoDestroyByLimit()
    self.AutoDestroyTimer = UE.UKismetSystemLibrary.K2_SetTimerForNextTickDelegate({self, self.DoAutoDestroyByLimit})
end

function MutableActorComponent:DoAutoDestroyByLimit()
    self.AutoDestroyTimer = nil
    G.log:debug("xaelpeng", "MutableActorComponent:DoAutoDestroyByLimit %s %s", self:GetOwner():GetName(), self:GetActorID())
    self:SendMessage("OnAutoDestroy")
    SubsystemUtils.GetMutableActorSubSystem(self:GetOwner()):DestroyLocalRuntimeActor(self:GetActorID(), self:GetOwner())
end

function MutableActorComponent:RegisterEvent(EventID, EventRegisterInfo)
    if self.Events:Find(EventID) ~= nil then
        G.log:error("xaelpeng", "MutableActorComponent:RegisterEvent %s EventID:%s EventType:%s has registered",
            self:GetOwner():GetName(), EventID, EventRegisterInfo.EventType)
        return
    end
    local EventClass = UE.UObject.Load(EventRegisterInfo.EventType)
    local Event = NewObject(EventClass, self)
    Event:InitializeOnTarget(EventID, EventRegisterInfo.MissionEventID)
    self.Events:Add(EventID, Event)
    G.log:debug("xaelpeng", "MutableActorComponent:RegisterEvent %s EventID:%s EventType:%s %s", self:GetOwner():GetName(),
        EventID, EventRegisterInfo.EventType, Event:GetName())

    Event:RegisterOnTarget(self:GetOwner(), EventRegisterInfo.Param)

    -- if Event:IsActiveOnClient() then
    --     self.ClientEvents:Add(EventRegisterInfo)
    -- end
end

function MutableActorComponent:UnregisterEvent(EventID)
    G.log:debug("xaelpeng", "MutableActorComponent:UnregisterEvent %s EventID:%s", self:GetOwner():GetName(), EventID)
    if self.Events:Find(EventID) == nil then
        G.log:error("xaelpeng", "MutableActorComponent:UnregisterEvent %s EventID:%s has not registered",
            self:GetOwner():GetName(), EventID)
        return
    end
    local Event = self.Events:Find(EventID)
    Event:UnregisterOnTarget(self:GetOwner())
    self.Events:Remove(EventID)

    -- if Event:IsActiveOnClient() then
    --     for i = 1, self.ClientEvents:Length() do
    --         local EventRegisterInfo = self.ClientEvents:GetRef(i)
    --         if EventRegisterInfo.EventID == EventID then
    --             self.ClientEvents:Remove(i)
    --             break
    --         end
    --     end
    -- end
end

function MutableActorComponent:RunAction(ActionID, ActionInfo)
    G.log:debug("xaelpeng", "MutableActorComponent:RunAction %s ActionID:%s ActionType:%s", self:GetOwner():GetName(),
        ActionID, ActionInfo.ActionType)
    if self.ActionRecords[ActionID] ~= nil then
        G.log:error("xaelpeng", "MutableActorComponent:RunAction %s ActionID:%s has already run",
            self:GetOwner():GetName(), ActionID)
    else
        local ActionClass = UE.UObject.Load(ActionInfo.ActionType)
        local Action = NewObject(ActionClass, self)
        Action:Run(self:GetOwner(), ActionInfo.Param)
        self.ActionRecords[ActionID] = true
    end

    local MutableActorManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MutableActorManager)
    MutableActorManager:ConfirmActionOnMutableActorByID(self:GetActorID(), ActionID)
end

-- client
decorator.message_receiver()
function MutableActorComponent:NotifyServerClientActorReady()
    G.log:debug("xaelpeng", "MutableActorComponent:NotifyServerClientActorReady %s", self.actor:GetName())
    local PlayerState = SubsystemUtils.GetMutableActorSubSystem(self):GetHostPlayerState()
    if PlayerState then
        local MutableActorComponentClass = UE.UClass.Load(BPConst.MutableActorComponent)
        local PlayerComponent = PlayerState:GetComponentByClass(MutableActorComponentClass)
        if PlayerComponent then
            PlayerComponent:Server_NotifyClientActorReady(self.actor)
        else
            G.log:debug("xaelpeng", "MutableActorComponent:NotifyServerClientActorReady PlayerPawn has no MutableActorComponent")
        end
    else
        G.log:debug("xaelpeng", "MutableActorComponent:NotifyServerClientActorReady PlayerPawn not found")
    end
end

-- server
-- function MutableActorComponent:Server_NotifyClientActorReady_RPC(Actor)
--     G.log:debug("xaelpeng", "MutableActorComponent:Server_NotifyClientActorReady %s", Actor:GetName())
--     if Actor then
--         local MutableActorComponentClass = UE.UClass.Load(BPConst.MutableActorComponent)
--         local MutableComponent = Actor:GetComponentByClass(MutableActorComponentClass)
--         if MutableComponent then
--             MutableComponent:OnNotifyClientActorReady()
--         else
--             G.log:debug("xaelpeng", "MutableActorComponent:NotifyServerClientActorReady Actor %s has no MutableActorComponent", Actor:GetName())
--         end
--     end
-- end

-- server
function MutableActorComponent:OnClientReadyScript(Actor)
    if Actor then
        G.log:debug("xaelpeng", "MutableActorComponent:OnClientReadyScript %s", Actor:GetName())
        local MutableActorComponentClass = UE.UClass.Load(BPConst.MutableActorComponent)
        local MutableComponent = Actor:GetComponentByClass(MutableActorComponentClass)
        if MutableComponent then
            MutableComponent:OnNotifyClientActorReady()
        else
            G.log:debug("xaelpeng", "MutableActorComponent:OnClientReadyScript Actor %s has no MutableActorComponent", Actor:GetName())
        end
    end

end

-- server
function MutableActorComponent:OnNotifyClientActorReady()
    self.bClientReady = true
    if self.actor.OnClientActorReady then
        self.actor:OnClientActorReady()
    end
    -- self:SendMessage("OnClientActorReady")
end

-- server
function MutableActorComponent:IsClientReady()
    return self.bClientReady
end

decorator.message_receiver()
function MutableActorComponent:OnDead(SourceActor, DeadReason)
    self.DeadDelegate:Broadcast()
end

-- client
-- function MutableActorComponent:OnRep_ClientEvents()
--     self:UpdateActiveClientEvents()
-- end

-- client
-- function MutableActorComponent:UpdateActiveClientEvents()
--     local CurrentEventIDs = {}
--     for i = 1, self.ClientEvents:Length() do
--         local EventRegisterInfo = self.ClientEvents:GetRef(i)
--         CurrentEventIDs[EventRegisterInfo.EventID] = true
--         if self.ClientLocalEvents:Find(EventRegisterInfo.EventID) == nil then
--             local EventClass = UE.UObject.Load(EventRegisterInfo.EventType)
--             local Event = NewObject(EventClass, self)
--             Event:InitializeOnTarget(EventRegisterInfo.EventID, EventRegisterInfo.MissionEventID)
--             self.ClientLocalEvents:Add(EventRegisterInfo.EventID, Event)
--             G.log:debug("xaelpeng", "MutableActorComponent:UpdateActiveClientEvents %s Add EventID:%s EventType:%s %s", self:GetOwner():GetName(),
--                 EventRegisterInfo.EventID, EventRegisterInfo.EventType, Event:GetName())
--             Event:RegisterOnTargetClient(self:GetOwner(), EventRegisterInfo.Param)
--         end
--     end
--     local LocalEventIDs = self.ClientLocalEvents:Keys()
--     for i = 1, LocalEventIDs:Length() do
--         local LocalEventID = LocalEventIDs:Get(i)
--         if CurrentEventIDs[LocalEventID] == nil then
--             local Event = self.ClientLocalEvents:Find(LocalEventID)
--             Event:UnregisterOnTargetClient(self:GetOwner())
--             self.ClientLocalEvents:Remove(LocalEventID)
--         end
--     end
-- end

-- function M:ReceiveTick(DeltaSeconds)
-- end

return MutableActorComponent
