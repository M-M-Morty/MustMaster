--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"
local G = require("G")
local GlobalActorConst = require("common.const.global_actor_const")
local BPConst = require("common.const.blueprint_const")

local _M = {}

function _M.LoadMutableActor(ActorID)
    local OperationClass = UE.UObject.Load(BPConst.MutableActorOperation)
    local Operation = OperationClass()
    Operation.OperationID = 0
    Operation.Timestamp = os.time()
    Operation.OpType = Enum.Enum_MutableActorOperationType.Load

    local MutableActorManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MutableActorManager)
    MutableActorManager:RunOperationOnMutableActorByID(ActorID, Operation)
end


function _M.UnloadMutableActor(ActorID)
    local OperationClass = UE.UObject.Load(BPConst.MutableActorOperation)
    local Operation = OperationClass()
    Operation.OperationID = 0
    Operation.Timestamp = os.time()
    Operation.OpType = Enum.Enum_MutableActorOperationType.Unload

    local MutableActorManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MutableActorManager)
    MutableActorManager:RunOperationOnMutableActorByID(ActorID, Operation)
end

function _M.RemoveMutableActor(ActorID)
    local OperationClass = UE.UObject.Load(BPConst.MutableActorOperation)
    local Operation = OperationClass()
    Operation.OperationID = 0
    Operation.Timestamp = os.time()
    Operation.OpType = Enum.Enum_MutableActorOperationType.Remove

    local MutableActorManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MutableActorManager)
    MutableActorManager:RunOperationOnMutableActorByID(ActorID, Operation)
end

function _M.RemoveMutableActorByTag(Tag)
    local OperationClass = UE.UObject.Load(BPConst.MutableActorOperation)
    local Operation = OperationClass()
    Operation.OperationID = 0
    Operation.Timestamp = os.time()
    Operation.OpType = Enum.Enum_MutableActorOperationType.Remove

    local MutableActorManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MutableActorManager)
    MutableActorManager:RunOperationOnMutableActorByTag(Tag, Operation)
end

function _M.GetMutableActorID(Actor)
    local MutableActorComponentClass = UE.UClass.Load(BPConst.MutableActorComponent)
    local MutableActorComponent = Actor:GetComponentByClass(MutableActorComponentClass)
    if MutableActorComponent ~= nil then
        return MutableActorComponent:GetActorID()
    end
end

return _M
