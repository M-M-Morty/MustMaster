--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"
local G = require("G")
local MutableActorOperations = require("actor_management.mutable_actor_operations")


---@type BP_MissionNodeBase_C
local MissionNodeBase = UnLua.Class()

-- function MissionNodeBase:AddAction(ActionName, Action)
--     G.log:debug("xaelpeng", "MissionNodeBase:AddAction %s ActionName:%s Action:%s", self:GetName(), ActionName, Action:GetName())
--     Action:OnInitialize(ActionName, self)
--     self.Actions:Add(ActionName, Action)
-- end

-- function MissionNodeBase:GetAction(ActionName)
--     return self.Actions:Find(ActionName)
-- end

-- function MissionNodeBase:AddEvent(EventName, Event)
--     G.log:debug("xaelpeng", "MissionNodeBase:AddEvent %s ActionName:%s Action:%s", self:GetName(), EventName,
--         Event:GetName())
--     self.Events:Add(EventName, Event)
-- end

-- function MissionNodeBase:GetEvent(EventName)
--     return self.Events:Find(EventName)
-- end

function MissionNodeBase:K2_InitializeInstance()
    self.Overridden.K2_InitializeInstance(self)
end

function MissionNodeBase:K2_ExecuteInput(PinName)
    self.Overridden.K2_ExecuteInput(self, PinName)
end


function MissionNodeBase:K2_OnSaveMissionFlowNodeInstance(FlowNodeSaveData)
    G.log:debug("xaelpeng", "MissionNodeBase:OnSave %s", self:GetName())

    -- local ActionNames = self.Actions:Keys()
    -- for i = 1, ActionNames:Length() do
    --     local ActionName = ActionNames:Get(i)
    --     local Action = self.Actions:Find(ActionName)
    --     local ActionSaveData = UE.FMissionFlowNodeActionSaveData()
    --     Action:SaveAction(ActionSaveData)
    --     FlowNodeSaveData.ActionList:Add(ActionSaveData)
    -- end
    self.EventSaveList:Clear()
    local EventNames = self.Events:Keys()
    for i = 1, EventNames:Length() do
        local EventName = EventNames:Get(i)
        local Event = self.Events:Find(EventName)
        local EventSaveData = UE.FMissionFlowNodeEventSaveData()
        Event:SaveEvent(EventSaveData)
        self.EventSaveList:Add(EventSaveData)
    end
end

function MissionNodeBase:K2_OnLoadMissionFlowNodeInstance(FlowNodeSaveData)
    G.log:debug("xaelpeng", "MissionNodeBase:OnLoadMissionFlowNodeInstance %s Data:%s", self:GetName(), FlowNodeSaveData.NodeGuid)
    -- for i = 1, FlowNodeSaveData.ActionList:Length() do
    --     local ActionSaveData = FlowNodeSaveData.ActionList:Get(i)
    --     local Action = self.Actions:Find(ActionSaveData.ActionName)
    --     if Action ~= nil then
    --         Action:LoadAction(ActionSaveData)
    --     end
    -- end
    for i = 1, self.EventSaveList:Length() do
        local EventSaveData = self.EventSaveList:Get(i)
        local Event = self.Events:Find(EventSaveData.EventName)
        if Event ~= nil then
            G.log:debug("xaelpeng", "MissionNodeBase:OnLoad %s %s %s", self:GetName(), Event:GetName(), EventSaveData.EventName)
            Event:LoadEvent(EventSaveData)
        end
    end
end

function MissionNodeBase:LoadMutableActor(ActorIDList)
    G.log:debug("xaelpeng", "MissionNodeBase:LoadMutableActor %s ActorNum:%d", self:GetName(), ActorIDList:Length())
    for i = 1, ActorIDList:Length() do
        local ActorID = ActorIDList:Get(i)
        G.log:debug("xaelpeng", "MissionNodeBase:LoadMutableActor %s ActorID:%s", self:GetName(), ActorID)
        MutableActorOperations.LoadMutableActor(ActorID)
    end
end

function MissionNodeBase:UnloadMutableActor(ActorIDList)
    G.log:debug("xaelpeng", "MissionNodeBase:UnloadMutableActor %s ActorNum:%d", self:GetName(), ActorIDList:Length())
    for i = 1, ActorIDList:Length() do
        local ActorID = ActorIDList:Get(i)
        G.log:debug("xaelpeng", "MissionNodeBase:UnloadMutableActor %s ActorID:%s", self:GetName(), ActorID)
        MutableActorOperations.UnloadMutableActor(ActorID)
    end
end

function MissionNodeBase:DestroyMutableActorByTag(Tag)
    G.log:debug("xaelpeng", "MissionNodeBase:DestroyMutableActorByTag %s Tag:%s", self:GetName(), Tag)
    MutableActorOperations.RemoveMutableActorByTag(Tag)
end

function MissionNodeBase:GetActorIDsByTag(Tag)
    local ActorList = SubsystemUtils.GetMutableActorSubSystem(self:GetManager()):GetTagMutableActors(Tag)
    local Result = UE.TArray(UE.FString)
    if ActorList then
        for _, ActorID in ipairs(ActorList) do
            Result:Add(ActorID)
        end
    end
    return Result
end


return MissionNodeBase
