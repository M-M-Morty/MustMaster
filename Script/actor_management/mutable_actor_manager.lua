--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"

local G = require("G")

---@type BP_MutableActorManager_C
local MutableActorManager = UnLua.Class()
local BPConst = require("common.const.blueprint_const")
local GlobalActorConst = require("common.const.global_actor_const")
local SubsystemUtils = require("common.utils.subsystem_utils")


function MutableActorManager:Initialize(Initializer)
    G.log:debug("xaelpeng", "MutableActorManager:Initialize %s", self:GetName())
    self.MutableActorMap = {}
    self.MutableActorDispatcherMap = {}
    self.RuntimeTagMap = {}
end

function MutableActorManager:UserConstructionScript()
    G.log:debug("xaelpeng", "MutableActorManager:UserConstructionScript %s", self:GetName())
end

function MutableActorManager:OnPreInitializeComponents()
    if self:HasAuthority() then
        G.log:debug("xaelpeng", "MutableActorManager:OnPreInitializeComponents %s", self:GetName())
        -- local ActorTypeID = 0
        -- SubsystemUtils.GetMutableActorSubSystem(self):AddMutableActorComponentToActor(self, self.GlobalName, ActorTypeID, UE.EHiActorCreateType.ActorCreateType_Fixed, nil, nil)
    end
end


function MutableActorManager:GetGlobalName()
    return GlobalActorConst.MutableActorManager
end

function MutableActorManager:OnLoadFromDatabase(GameplayProperties)
    -- if bLoaded then
    --     G.log:debug("xaelpeng", "MutableActorManager:OnLoadFromDatabase %s StartActionID:%d StartOperationID:%d ActorNum:%d", self:GetName(),
    --         self.GeneratedActionID, self.GeneratedOperationID, self.MutableActorProxySaveData:Length())
    --     for i = 1, self.MutableActorProxySaveData:Length() do
    --         local SaveData = self.MutableActorProxySaveData:Get(i)
    --         G.log:debug("xaelpeng", "MutableActorManager:OnLoadFromDatabase %s ActorID:%s ActionNum:%d OperationNum:%d", self:GetName(), SaveData.ActorID, 
    --             SaveData.Actions:Length(), SaveData.Operations:Length())
    --         local ActorProxyClass = BPConst.GetMutableActorProxyClass()
    --         local ActorProxy = NewObject(ActorProxyClass, self)
    --         ActorProxy:LoadFromSaveData(SaveData)
    --         self.MutableActorProxyMap:Add(SaveData.ActorID, ActorProxy)
    --     end
    -- end
end

function MutableActorManager:OnSaveToDatabase(GameplayProperties)
    self.MutableActorProxySaveData:Clear()
    local ActorIDList = self.MutableActorProxyMap:Keys()
    local SaveActorNum = 0
    for i = 1, ActorIDList:Length() do
        local ActorID = ActorIDList:Get(i)
        local ActorProxy = self.MutableActorProxyMap:Find(ActorID)
        if ActorProxy:NeedSave() then
            G.log:debug("xaelpeng", "MutableActorManager:OnSaveToDatabase %s ActorID:%s ActionNum:%d OperationNum:%d", self:GetName(), ActorID, ActorProxy:GetActions():Length(),
                ActorProxy:GetOperations():Length())
            local SaveData = ActorProxy:GetSaveData()
            self.MutableActorProxySaveData:Add(SaveData)
            SaveActorNum = SaveActorNum + 1
        end
    end
    G.log:debug("xaelpeng", "MutableActorManager:OnSaveToDatabase %s CurrentActionID:%d CurrentOperationID:%d ActorNum:%d", self:GetName(),
        self.GeneratedActionID, self.GeneratedOperationID, SaveActorNum)
end


function MutableActorManager:GenerateActionID()
    self.GeneratedActionID = self.GeneratedActionID + 1
    return self.GeneratedActionID
end

function MutableActorManager:GenerateOperationID()
    self.GeneratedOperationID = self.GeneratedOperationID + 1
    return self.GeneratedOperationID
end

function MutableActorManager:ReceiveBeginPlay()
    G.log:debug("xaelpeng", "MutableActorManager:ReceiveBeginPlay %s", self:GetName())
end


function MutableActorManager:RegisterMutableActor(ActorID, ActorRegisterInfo)
    if ActorID == "" then
        G.log:error("xaelpeng", "MutableActorManager:RegisterMutableActor ActorID not set")
        return
    end
    if self.MutableActorMap[ActorID] ~= nil then
        G.log:error("xaelpeng", "MutableActorManager:RegisterMutableActor ActorID: %s has already registered", ActorID)
        return
    end
    G.log:debug("xaelpeng", "MutableActorManager:RegisterMutableActor ActorID: %s", ActorID)
    self.MutableActorMap[ActorID] = ActorRegisterInfo

    -- used for runtime tag
    for i = 1, ActorRegisterInfo.Tags:Length() do
        local Tag = ActorRegisterInfo.Tags:Get(i)
        if self.RuntimeTagMap[Tag] == nil then
            self.RuntimeTagMap[Tag] = {}
        end
        self.RuntimeTagMap[Tag][ActorID] = true
    end

    self:RegisterMutableActorDispatcher(ActorID, ActorRegisterInfo.Dispatcher)
    local ActorProxy = self:GetMutableActorProxy(ActorID, false)
    if ActorProxy ~= nil then
        local Events = ActorProxy:GetEventsClone()
        for i = 1, Events:Length() do
            local EventRegisterInfo = Events:Get(i)
            local EventID = EventRegisterInfo.EventID
            ActorRegisterInfo.Dispatcher:DispatchRegisterEventToActor(ActorID, EventID, EventRegisterInfo)
        end
        local Actions = ActorProxy:GetActionsClone()
        for i = 1, Actions:Length() do
            local ActionInfo = Actions:Get(i)
            local ActionID = ActionInfo.ActionID
            ActorRegisterInfo.Dispatcher:DispatchActionToActor(ActorID, ActionID, ActionInfo)
        end
    end
    -- used for runtime tag
     for i = 1, ActorRegisterInfo.Tags:Length() do
        local Tag = ActorRegisterInfo.Tags:Get(i)
        local TagActorProxy = self:GetRuntimeTagActorProxy(Tag, false)
        if TagActorProxy ~= nil then
            local Events = TagActorProxy:GetEventsClone()
            for EventIndex = 1, Events:Length() do
                local EventRegisterInfo = Events:Get(EventIndex)
                local EventID = EventRegisterInfo.EventID
                ActorRegisterInfo.Dispatcher:DispatchRegisterEventToActor(ActorID, EventID, EventRegisterInfo)
            end
        end
    end
end

function MutableActorManager:UnregisterMutableActor(ActorID)
    G.log:debug("xaelpeng", "MutableActorManager:UnregisterMutableActor ActorID: %s", ActorID)
    if self.MutableActorMap[ActorID] == nil then
        G.log:error("xaelpeng", "MutableActorManager:UnregisterMutableActor ActorID: %s not registered", ActorID)
        return
    end
    -- used for runtime tag
    local ActorRegisterInfo = self.MutableActorMap[ActorID]
    for i = 1, ActorRegisterInfo.Tags:Length() do
        local Tag = ActorRegisterInfo.Tags:Get(i)
        if self.RuntimeTagMap[Tag] ~= nil then
            self.RuntimeTagMap[Tag][ActorID] = nil
        end
    end
    self.MutableActorMap[ActorID] = nil
end

function MutableActorManager:RegisterNotLoadedMutableActor(ActionID, Dispatcher)
    self:RegisterMutableActorDispatcher(ActionID, Dispatcher)
end

function MutableActorManager:RegisterMutableActorDispatcher(ActorID, Dispatcher)
    if ActorID == "" then
        G.log:error("xaelpeng", "MutableActorManager:RegisterMutableActorDispatcher ActorID not set")
        return
    end
    G.log:debug("xaelpeng", "MutableActorManager:RegisterMutableActorDispatcher ActorID: %s", ActorID)
    self.MutableActorDispatcherMap[ActorID] = Dispatcher
    local ActorProxy = self:GetMutableActorProxy(ActorID, false)
    if ActorProxy ~= nil then
        local Operations = ActorProxy:GenerateOperationsToRun()
        for _, Operation in ipairs(Operations) do
            self:DispatchOperation(ActorID, Operation)
        end
    end
end

function MutableActorManager:RegisterEventOnMutableActorByID(ActorID, EventID, EventRegisterInfo)
    if ActorID == "" then
        G.log:error("xaelpeng", "MutableActorManager:RegisterEventOnMutableActorByID ActorID not set")
        return
    end
    G.log:debug("xaelpeng", "MutableActorManager:RegisterEventOnMutableActorByID ActorID: %s EventID: %s EventType: %s",
        ActorID, EventID, EventRegisterInfo.EventType)
    local ActorProxy = self:GetMutableActorProxy(ActorID, true)
    ActorProxy:AddEvent(EventID, EventRegisterInfo)
    if self.MutableActorMap[ActorID] ~= nil then
        self.MutableActorMap[ActorID].Dispatcher:DispatchRegisterEventToActor(ActorID, EventID, EventRegisterInfo)
    end
end

function MutableActorManager:UnregisterEventOnMutableActorByID(ActorID, EventID)
    G.log:debug("xaelpeng", "MutableActorManager:UnregisterEventOnMutableActorByID ActorID: %s EventID: %s", ActorID,
        EventID)
    local ActorProxy = self:GetMutableActorProxy(ActorID, false)
    if ActorProxy ~= nil then
        ActorProxy:DelEvent(EventID)
    end
    if self.MutableActorMap[ActorID] ~= nil then
        self.MutableActorMap[ActorID].Dispatcher:DispatchUnregisterEventToActor(ActorID, EventID)
    end
end

function MutableActorManager:RegisterEventOnMutableActorByTag(Tag, EventID, EventRegisterInfo)
    local ActorIDs = SubsystemUtils.GetMutableActorSubSystem(self):GetTagMutableActors(Tag)
    if ActorIDs ~= nil then
        G.log:debug("xaelpeng", "MutableActorManager:RegisterEventOnMutableActorByTag FixedTag: %s EventID: %s EventType: %s", Tag, EventID, EventRegisterInfo.EventType)
        for _, ActorID in ipairs(ActorIDs) do
            local ActorProxy = self:GetMutableActorProxy(ActorID, true)
            ActorProxy:AddEvent(EventID, EventRegisterInfo)
            if self.MutableActorMap[ActorID] ~= nil then
                self.MutableActorMap[ActorID].Dispatcher:DispatchRegisterEventToActor(ActorID, EventID, EventRegisterInfo)
            end
        end
        return
    end
    -- used for runtime tag
    G.log:debug("xaelpeng", "MutableActorManager:RegisterEventOnMutableActorByTag RuntimeTag: %s EventID: %s EventType: %s", Tag, EventID, EventRegisterInfo.EventType)
    local ActorProxy = self:GetRuntimeTagActorProxy(Tag, true)
    ActorProxy:AddEvent(EventID, EventRegisterInfo)
    if self.RuntimeTagMap[Tag] ~= nil then
        for ActorID, _ in pairs(self.RuntimeTagMap[Tag]) do
            local ActorRegisterInfo = self.MutableActorMap[ActorID]
            if ActorRegisterInfo ~= nil then
                ActorRegisterInfo.Dispatcher:DispatchRegisterEventToActor(ActorID, EventID, EventRegisterInfo)
            end
        end
    end
end

function MutableActorManager:UnregisterEventOnMutableActorByTag(Tag, EventID)
    local ActorIDs = SubsystemUtils.GetMutableActorSubSystem(self):GetTagMutableActors(Tag)
    if ActorIDs ~= nil then
        G.log:debug("xaelpeng", "MutableActorManager:UnregisterEventOnMutableActorByTag FixedTag: %s EventID: %s", Tag, EventID)
        for _, ActorID in ipairs(ActorIDs) do
            local ActorProxy = self:GetMutableActorProxy(ActorID, true)
            ActorProxy:DelEvent(EventID)
        end
        return
    end
    -- used for runtime tag
    G.log:debug("xaelpeng", "MutableActorManager:UnregisterEventOnMutableActorByTag RuntimeTag: %s EventID: %s", Tag, EventID)
    local ActorProxy = self:GetRuntimeTagActorProxy(Tag, false)
    if ActorProxy ~= nil then
        ActorProxy:DelEvent(EventID)
    end
    if self.RuntimeTagMap[Tag] ~= nil then
        for ActorID, _ in pairs(self.RuntimeTagMap[Tag]) do
            local ActorRegisterInfo = self.MutableActorMap[ActorID]
            if ActorRegisterInfo ~= nil then
                ActorRegisterInfo.Dispatcher:DispatchUnregisterEventToActor(ActorID, EventID)
            end
        end
    end
end

function MutableActorManager:RunActionOnMutableActorByID(ActorID, ActionInfo)
    local ActionID = self:GenerateActionID()
    ActionInfo.ActionID = ActionID
    G.log:debug("xaelpeng", "MutableActorManager:RunActionOnMutableActorByID ActorID: %s ActionID: %s ActionType: %s",
        ActorID, ActionID, ActionInfo.ActionType)
    local ActorProxy = self:GetMutableActorProxy(ActorID, true)
    ActorProxy:AddAction(ActionID, ActionInfo)
    if self.MutableActorMap[ActorID] ~= nil then
        self.MutableActorMap[ActorID].Dispatcher:DispatchActionToActor(ActorID, ActionID, ActionInfo)
    end
end

function MutableActorManager:RunActionOnMutableActorByTag(Tag, ActionInfo)
    local ActionID = self:GenerateActionID()
    ActionInfo.ActionID = ActionID

    local ActorIDs = SubsystemUtils.GetMutableActorSubSystem(self):GetTagMutableActors(Tag)
    if ActorIDs ~= nil then
        G.log:debug("xaelpeng", "MutableActorManager:RunActionOnMutableActorByTag FixedTag: %s ActionID: %s ActionType: %s", Tag, ActionID, ActionInfo.ActionType)
        for _, ActorID in ipairs(ActorIDs) do
            local ActorProxy = self:GetMutableActorProxy(ActorID, true)
            ActorProxy:AddAction(ActionID, ActionInfo)
            if self.MutableActorMap[ActorID] ~= nil then
                self.MutableActorMap[ActorID].Dispatcher:DispatchActionToActor(ActorID, ActionID, ActionInfo)
            end
        end
        return
    end

    -- used for runtime tag
    G.log:debug("xaelpeng", "MutableActorManager:RunActionOnMutableActorByTag RuntimeTag: %s ActionID: %s ActionType: %s",
        Tag, ActionID, ActionInfo.ActionType)
    if self.RuntimeTagMap[Tag] ~= nil then
        for ActorID, _ in pairs(self.RuntimeTagMap[Tag]) do
            local ActorProxy = self:GetMutableActorProxy(ActorID, true)
            ActorProxy:AddAction(ActionID, ActionInfo)
            if self.MutableActorMap[ActorID] ~= nil then
                self.MutableActorMap[ActorID].Dispatcher:DispatchActionToActor(ActorID, ActionID, ActionInfo)
            end
        end
    end
end

function MutableActorManager:ConfirmActionOnMutableActorByID(ActorID, ActionID)
    G.log:debug("xaelpeng", "MutableActorManager:ConfirmActionOnMutableActorByID ActorID: %s ActionID: %s", ActorID, ActionID)
    local ActorProxy = self:GetMutableActorProxy(ActorID, false)
    if ActorProxy == nil then
        G.log:error("xaelpeng", "MutableActorManager:ConfirmActionOnMutableActorByID ActorID: %s ActorProxy not found", ActorID)
        return
    end
    ActorProxy:DelAction(ActionID)
end

function MutableActorManager:RunOperationOnMutableActorByID(ActorID, Operation)
    local OperationID = self:GenerateOperationID()
    Operation.OperationID = OperationID
    G.log:debug("xaelpeng", "MutableActorManager:RunOperationOnMutableActorByID ActorID: %s OperationID: %s OperationType: %s", ActorID, OperationID, Operation.OpType)
    local ActorProxy = self:GetMutableActorProxy(ActorID, true)
    ActorProxy:AddOperation(OperationID, Operation)
    if self.MutableActorDispatcherMap[ActorID] ~= nil then
        self:DispatchOperation(ActorID, Operation)
    end
end

function MutableActorManager:RunOperationOnMutableActorByTag(Tag, Operation)
    local OperationID = self:GenerateOperationID()
    Operation.OperationID = OperationID

    local ActorIDs = SubsystemUtils.GetMutableActorSubSystem(self):GetTagMutableActors(Tag)
    if ActorIDs ~= nil then
        G.log:debug("xaelpeng", "MutableActorManager:RunOperationOnMutableActorByTag FixedTag: %s OperationID: %s OperationType: %s", Tag, OperationID, Operation.OpType)
        for _, ActorID in ipairs(ActorIDs) do
            local ActorProxy = self:GetMutableActorProxy(ActorID, true)
            ActorProxy:AddOperation(OperationID, Operation)
            if self.MutableActorDispatcherMap[ActorID] ~= nil then
                self:DispatchOperation(ActorID, Operation)
            end
        end
        return
    end

    -- used for runtime tag
    G.log:debug("xaelpeng", "MutableActorManager:RunOperationOnMutableActorByTag RuntimeTag: %s OperationID: %s OperationType: %s", Tag, OperationID, Operation.OpType)
    if self.RuntimeTagMap[Tag] ~= nil then
        for ActorID, _ in pairs(self.RuntimeTagMap[Tag]) do
            local ActorProxy = self:GetMutableActorProxy(ActorID, true)
            ActorProxy:AddOperation(OperationID, Operation)
            if self.MutableActorDispatcherMap[ActorID] ~= nil then
                self:DispatchOperation(ActorID, Operation)
            end
        end
    end
end


function MutableActorManager:DispatchOperation(ActorID, Operation)
    local Dispatcher = self.MutableActorDispatcherMap[ActorID]
    if Operation.OpType == Enum.Enum_MutableActorOperationType.Load then
        Dispatcher:DoMutableActorOp_Load(Operation.OperationID, ActorID)
    elseif Operation.OpType == Enum.Enum_MutableActorOperationType.Unload then
        Dispatcher:DoMutableActorOp_Unload(Operation.OperationID, ActorID)
    elseif Operation.OpType == Enum.Enum_MutableActorOperationType.Remove then
        Dispatcher:DoMutableActorOp_Remove(Operation.OperationID, ActorID)
    end
end

function MutableActorManager:ConfirmOperationOnMutableActorByID(ActorID, OperationID)
    G.log:debug("xaelpeng", "MutableActorManager:ConfirmOperationOnMutableActorByID ActorID: %s OperationID: %s", ActorID, OperationID)
    local ActorProxy = self:GetMutableActorProxy(ActorID, false)
    if ActorProxy == nil then
        G.log:error("xaelpeng", "MutableActorManager:ConfirmOperationOnMutableActorByID ActorID: %s ActorProxy not found", ActorID)
        return
    end
    ActorProxy:DelOperation(OperationID)
end

function MutableActorManager:GetMutableActorProxy(ActorID, bAutoCreate)
    local ActorProxy = self.MutableActorProxyMap:Find(ActorID)
    if ActorProxy == nil then
        if bAutoCreate then
            local ActorProxyClass = BPConst.GetMutableActorProxyClass()
            ActorProxy = NewObject(ActorProxyClass, self)
            ActorProxy:OnInitialize(ActorID)
            self.MutableActorProxyMap:Add(ActorID, ActorProxy)
        else
            return nil
        end
    end
    return ActorProxy
end

function MutableActorManager:GetRuntimeTagActorProxy(Tag, bAutoCreate)
    local ActorProxy = self.RuntimeTagActorProxyMap:Find(Tag)
    if ActorProxy == nil then
        if bAutoCreate then
            local ActorProxyClass = BPConst.GetMutableActorProxyClass()
            ActorProxy = NewObject(ActorProxyClass, self)
            ActorProxy:OnInitialize(Tag)
            self.RuntimeTagActorProxyMap:Add(Tag, ActorProxy)
        else
            return nil
        end
    end
    return ActorProxy
end


-- function M:ReceiveEndPlay()
-- end

-- function M:ReceiveTick(DeltaSeconds)
-- end

-- function M:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
-- end

-- function M:ReceiveActorBeginOverlap(OtherActor)
-- end

-- function M:ReceiveActorEndOverlap(OtherActor)
-- end

return MutableActorManager
