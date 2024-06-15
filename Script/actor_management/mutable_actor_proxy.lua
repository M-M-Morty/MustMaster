--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require("G")


---@type BP_MutableActorProxy_C
local MutableActorProxy = UnLua.Class()
local BPConst = require("common.const.blueprint_const")
local EdUtils = require("common.utils.ed_utils")

function MutableActorProxy:OnInitialize(Key)
    self.ActorProxyKey = Key
end

function MutableActorProxy:AddEvent(EventID, EventRegisterInfo)
    self.Events:Add(EventRegisterInfo)
end

function MutableActorProxy:DelEvent(EventID)
    for i = 1, self.Events:Length() do
        local Event = self.Events:Get(i)
        if Event.EventID == EventID then
            self.Events:Remove(i)
            break
        end
    end
end

function MutableActorProxy:GetEvents()
    return self.Events
end

function MutableActorProxy:GetEventsClone()
    local MissionEventRegisterInfoCls = EdUtils:GetUE5ObjectClass(BPConst.MissionEventRegisterInfo, true)
    local CloneList = UE.TArray(MissionEventRegisterInfoCls)
    for i = 1, self.Events:Length() do
        local EventInfo = self.Events:Get(i)
        CloneList:Add(EventInfo)
    end
    return CloneList
end

function MutableActorProxy:AddAction(ActionID, ActionParam)
    self.Actions:Add(ActionParam)
end

function MutableActorProxy:DelAction(ActionID)
    for i = 1, self.Actions:Length() do
        local Action = self.Actions:Get(i)
        if Action.ActionID == ActionID then
            self.Actions:Remove(i)
            break
        end
    end
end

function MutableActorProxy:GetActions()
    return self.Actions
end

function MutableActorProxy:GetActionsClone()
    local MissionActionInfoCls = EdUtils:GetUE5ObjectClass(BPConst.MissionActionInfo, true)
    local CloneList = UE.TArray(MissionActionInfoCls)
    for i = 1, self.Actions:Length() do
        local ActionInfo = self.Actions:Get(i)
        CloneList:Add(ActionInfo)
    end
    return CloneList
end

function MutableActorProxy:AddOperation(OperationID, Operation)
    self.Operations:Add(Operation)
end

function MutableActorProxy:DelOperation(OperationID)
    for i = 1, self.Operations:Length() do
        local Operation = self.Operations:Get(i)
        if Operation.OperationID == OperationID then
            self.Operations:Remove(i)
            break
        end
    end
end

function MutableActorProxy:GetOperations()
    return self.Operations
end


function MutableActorProxy:GenerateOperationsToRun()
    local result = {}
    local LoadOp = nil
    for i = self.Operations:Length(), 1, -1 do
        local Operation = self.Operations:Get(i)
        if Operation.OpType == Enum.Enum_MutableActorOperationType.Load or Operation.OpType == Enum.Enum_MutableActorOperationType.Unload then
            if LoadOp == nil then
                LoadOp = Operation
                table.insert(result, Operation)
            else
                self.Operations:Remove(i)
            end
        else
            table.insert(result, Operation)
        end
    end
    return result
end

function MutableActorProxy:NeedSave()
    if self.Actions:Length() > 0 then
        return true
    end
    if self.Operations:Length() > 0 then
        return true
    end
    return false
end

function MutableActorProxy:GetSaveData()
    local SaveDataClass = UE.UObject.Load(BPConst.MutableActorProxySaveData)
    local SaveData = SaveDataClass()
    SaveData.ActorID = self.ActorProxyKey
    SaveData.Actions = self.Actions
    SaveData.Operations = self.Operations
    return SaveData
end

function MutableActorProxy:LoadFromSaveData(SaveData)
    self.ActorProxyKey = SaveData.ActorID
    self.Actions = SaveData.Actions
    self.Operations = SaveData.Operations
end

return MutableActorProxy