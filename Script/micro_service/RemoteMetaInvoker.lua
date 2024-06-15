---------------------------------------------------------------------
--- @copyright Copyright (c) 2024 Tencent Inc. All rights reserved.
--- @author yongzyzhang
--- @brief RemoteMetaInvoker
---------------------------------------------------------------------

local PB = require "pb"
local IRPCCore = require "irpc_core"
local MsConfig = require("micro_service.ms_config")
local G = require("G")


---@class RemoteMetaInvoker
---@field public GetMetaType function
---@field public GetMetaUID function
local RemoteMetaInvoker = {}

local RemoteMetaInvokerMeta = {}
RemoteMetaInvokerMeta.ServiceProtoCache = {}
local CoroPrefix = "Coro_"
local CoroPrefixLength = string.len(CoroPrefix)

local function CreateRemoteMetaInvokeClientContext(RemoteMetaDataInvoker)
    local RemoteMetaData = rawget(RemoteMetaDataInvoker, "MetaData")

    if RemoteMetaData.MetaType == nil or RemoteMetaData.MetaType == "" or RemoteMetaData.MetaUID == nil or RemoteMetaData.MetaUID == 0 then
        -- 直接抛异常
        assert(false, string.format("RemoteMetaData invalid meta_type:%s meta_uid:%s", RemoteMetaData.MetaType or "", 
                RemoteMetaData.MetaUID and tostring(RemoteMetaData.MetaUID) or "0"))
        return nil
    end
    
    local ClientContext = IRPCCore:NewClientContext()
    ClientContext:SetTimeout(30 * 1000)
    if UE.UHiUtilsFunctionLibrary.IsServerWorld() then
        --DS 调用TSF4G2微服务需要通过DSA转发
        ClientContext:SetTargetService("DsaService")
        ClientContext:SetReqMeta({
            g6_forward_service = MsConfig.NameOfAgentServer, -- 通过AgentServer代理发给具体的服务
            meta_type = RemoteMetaData.MetaType,
            meta_uid = RemoteMetaData.MetaUID,
            g6_forward_hash_key = RemoteMetaData.MetaUID  --G6 DSA转发请求时， 一致性hash需要req元数据数据
        })
        
        --DS服务端，统一在reqMeta中注入角色ID，TSF4G2 服务，统一读取role_id进行操作权限判断。
        --若没有PlayerRoleId，则涉及到权限验证服务接口，应该需要拒绝访问。
        local PlayerRoleId = rawget(RemoteMetaDataInvoker, "PlayerRoleId")
        if PlayerRoleId then
            if type(PlayerRoleId) == "number" then
                ClientContext:AddReqMeta("role_id", tostring(PlayerRoleId))
            elseif type(PlayerRoleId) == "string" then
                ClientContext:AddReqMeta("role_id", PlayerRoleId)
            end
        end

        local PlayerGuid = rawget(RemoteMetaDataInvoker, "PlayerGuid")
        if PlayerGuid then
            if type(PlayerGuid) == "number" then
                ClientContext:AddReqMeta("guid", tostring(PlayerRoleId))
            elseif type(PlayerGuid) == "string" then
                ClientContext:AddReqMeta("guid", PlayerRoleId)
            end
        end
    else
        -- Gate直接使用 AppRouter路由
        ClientContext:SetTargetEntityAddr(RemoteMetaData.MetaType, RemoteMetaData.MetaUID)
        ClientContext:SetReqMeta({
            meta_type = RemoteMetaData.MetaType,
            meta_uid = RemoteMetaData.MetaUID
        })
    end
    
    return ClientContext

end

local IRPC = require("micro_service.irpc.irpc")
IRPC:Open()

local RPCStubFactory = require("micro_service.rpc_stub_factory")

RemoteMetaInvokerMeta.__index = function(RemoteMetaInvoker, FuncName)
    local bCoro = false
    if string.sub(FuncName, 1, CoroPrefixLength) == CoroPrefix then
        bCoro = true
        FuncName = string.sub(FuncName, CoroPrefixLength + 1)
    end
    local MetaData = rawget(RemoteMetaInvoker, "MetaData")
    local MetaType = MetaData.MetaType
    local ServiceProto = RemoteMetaInvokerMeta.ServiceProtoCache[MetaType]
    if ServiceProto == nil then
        --MetaType 本质上就是Entity提供的服务名
        RPCStubFactory:LoadEntityServiceProto(MetaType)
        ServiceProto = PB.service(MetaType)
        if ServiceProto == nil then
            G.log:error("EntityMailboxMeta MetaType:%s not exist in irpc protos", MetaType)
        end
        RemoteMetaInvokerMeta.ServiceProtoCache[MetaType] = ServiceProto
    end
    if ServiceProto.methods[FuncName] == nil then
        G.log:error("yongzyzhang", "EntityMailboxMeta MetaType:%s do not has function %s", MetaType, FuncName)
        return nil
    end

    -- no tsf4g service
    if UE.UHiUtilsFunctionLibrary.IsLocalAdapter() then
        local LocalAdapterFunction = function(...)
            G.log:error("yongzyzhang", "Current in Local Adaptor mode can't invoke tsf4g2 service rpc method")
            local ClientContext = IRPCCore:NewClientContext()
            return ClientContext, {}
        end
        return LocalAdapterFunction
    end
    
    if bCoro then
        local RPCFunction = function(RemoteMetaInvoker, Request)
            local ClientContext = CreateRemoteMetaInvokeClientContext(RemoteMetaInvoker)
            local Result, Response

            local RPCClient = IRPC:GetRPCClient(RPCStubFactory:GetCallName(), MetaData.MetaType, "coroutine")
            Result, Response = RPCClient[FuncName](RPCClient, ClientContext, Request)
            if not Result then
                -- TODO maybe should update ClientContext?
            end
            return ClientContext, Response
        end
        return RPCFunction
    else
        local RPCFunction = function(RemoteMetaInvoker, Request, Callback)
            local ClientContext = CreateRemoteMetaInvokeClientContext(RemoteMetaInvoker)
            if Callback == nil then
                Callback = function(ClientCtx, Response)
                    RemoteMetaInvokerMeta.DefaultCallback(RemoteMetaInvoker, FuncName, ClientCtx, Response)
                end
            end

            local Result

            local RPCClient = IRPC:GetRPCClient(RPCStubFactory:GetCallName(), MetaData.MetaType)
            Result = RPCClient[FuncName](RPCClient, ClientContext, Request, Callback)
            if not Result then
                Callback(ClientContext, {})
            end
            return Result
        end
        return RPCFunction
    end
end

RemoteMetaInvokerMeta.__tostring = function(RemoteMetaDataInvoker)
    return string.format(
            "(%s:%d %s:%s)",
            RemoteMetaDataInvoker.MetaData.ServiceName,
            RemoteMetaDataInvoker.MetaData.ServiceInstID,
            RemoteMetaDataInvoker.MetaData.MetaType, 
            RemoteMetaDataInvoker.MetaData.MetaUID
    )
end

RemoteMetaInvokerMeta.__eq = function(OneRemoteMetaInvoker, OtherRemoteMetaInvoker)
    if OneRemoteMetaInvoker == nil and OtherRemoteMetaInvoker == nil then
        return true
    end
    if OneRemoteMetaInvoker == nil or OtherRemoteMetaInvoker == nil then
        return false
    end
    return OneRemoteMetaInvoker.MetaData.MetaUID == OtherRemoteMetaInvoker.MetaData.MetaUID and OneRemoteMetaInvoker.MetaData.MetaType == OtherRemoteMetaInvoker.MetaData.MetaType
end

local function StatusString(Status)
    local utils = require("common.utils")
    return utils.IRPCStatusString(Status)
end

function RemoteMetaInvokerMeta.DefaultCallback(RemoteMetaDataInvoker, FuncName, ClientCtx, Response)
    local Status = ClientCtx:GetStatus()
    if not Status:OK() then
        G.log:error("yongzyzhang",
                "RemoteMetaInvoker: %s default callback of %s. error:%s", RemoteMetaDataInvoker,
                FuncName,
                StatusString(Status)
        )
    end
end

local function NewRemoteMetaInvoker(MetaType, MetaUID)
    local MetaInvoker = {}
    local RemoteMetaData = {
        MetaType = MetaType,
        MetaUID = MetaUID
    }
    MetaInvoker.MetaData = RemoteMetaData

    MetaInvoker.GetMetaType = function(M)
        return M.MetaType
    end
    MetaInvoker.GetMetaUID = function(M)
        return M.MetaUID
    end

    setmetatable(MetaInvoker, RemoteMetaInvokerMeta)
    return MetaInvoker
end


---@return RemoteMetaInvoker
---@param PlayerContext any 目前支持PlayerController和PlayerState
--- 创建自动携带请求方玩家信息元数据的Invoker， 适合用于请求需要验证玩家读写权限的接口
---Warning!!! 哪个玩家创建的，哪个玩家使用，尽量不要把这个创建出来的对象引用向外传递，防止误用
function RemoteMetaInvoker.CreatePlayerContextInvoker(MetaType, MetaUID, PlayerContext)
    local MetaInvoker = NewRemoteMetaInvoker(MetaType, MetaUID)
    assert(PlayerContext ~= nil)
    
    assert(PlayerContext.GetPlayerGuidAsString, "PlayerContext has no method GetPlayerGuidAsString")
    assert(PlayerContext.GetPlayerRoleIdAsString, "PlayerContext has no method GetPlayerRoleIdAsString")

    rawset(MetaInvoker, "PlayerGuid", PlayerContext:GetPlayerGuidAsString())
    rawset(MetaInvoker, "PlayerRoleId", PlayerContext:GetPlayerRoleIdAsString())
    
    return MetaInvoker
end

---@return RemoteMetaInvoker
--- 创建通用的，无请求方玩家信息元数据的Invoker
function RemoteMetaInvoker.CreateGenericInvoker(MetaType, MetaUID)
    local MetaInvoker = NewRemoteMetaInvoker(MetaType, MetaUID)

    return MetaInvoker
end

return RemoteMetaInvoker
