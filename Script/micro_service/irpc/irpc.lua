
------------------------------------------
--- IRPC接口
------------------------------------------
---@class IRPC

local IRPCCore = require "irpc_core"
local IRPCLite = require "micro_service.irpc.irpc_lite"
local IRPCLog = require "micro_service.irpc.irpc_log"
local IRPCDefine = require "micro_service.irpc.irpc_define"
local PB = require "pb"
local PBBuffer= require "pb.Buffer"
local IRPC = {}

--- @brief 内部管理的EntityDispatcher信息
IRPC.mEntityDispatchers = {};
IRPC.mDefaultEntityHandler = nil;
IRPC.mIsCreateCoroutineForEntity = false;

-- 内建irpc/common/irpc_descriptor.proto的元数据，这样不用显式调用load方法
assert(pb.load(
    "\10\185\8\10!irpc/common/irpc_descriptor.proto\18\7g6.irpc\26 google/pro"..
    "tobuf/descriptor.proto\";\10\9RouteMeta\18\11\10\3key\24\1 \1(\9\18\13\10"..
    "\5value\24\2 \1(\9\18\18\10\10value_from\24\3 \1(\9\"\6\10\4Void*\150\1\10"..
    "\19AllowedEndpointType\18\19\10\15DefaultEndpoint\16\0\18\19\10\15Servic"..
    "eEndpoint\16\1\18\19\10\15SessionEndpoint\16\2\18\18\10\14RawTcpEndpoint"..
    "\16\4\18\18\10\14EntityEndpoint\16\8\18\24\10\11AllEndpoint\16\255\255\255"..
    "\255\255\255\255\255\255\1:>\10\20default_service_name\18\31.google.prot"..
    "obuf.ServiceOptions\24\232\7 \1(\9:d\10\28service_caller_endpoint_type\18"..
    "\31.google.protobuf.ServiceOptions\24\144\8 \3(\0142\28.g6.irpc.AllowedE"..
    "ndpointType:1\10\8isOneWay\18\30.google.protobuf.MethodOptions\24\232\7 "..
    "\1(\8:4\10\11isBroadCast\18\30.google.protobuf.MethodOptions\24\233\7 \1"..
    "(\8:0\10\7one_way\18\30.google.protobuf.MethodOptions\24\235\7 \1(\8:2\10"..
    "\9broadcast\18\30.google.protobuf.MethodOptions\24\236\7 \1(\8:6\10\13ro"..
    "ute_int_key\18\30.google.protobuf.MethodOptions\24\252\7 \1(\9:6\10\13ro"..
    "ute_str_key\18\30.google.protobuf.MethodOptions\24\253\7 \1(\9:8\10\15ro"..
    "ute_entity_id\18\30.google.protobuf.MethodOptions\24\254\7 \1(\9:6\10\13"..
    "route_hash_id\18\30.google.protobuf.MethodOptions\24\255\7 \1(\9:H\10\11"..
    "route_metas\18\30.google.protobuf.MethodOptions\24\128\8 \3(\0112\18.g6."..
    "irpc.RouteMeta:b\10\27method_caller_endpoint_type\18\30.google.protobuf."..
    "MethodOptions\24\144\8 \3(\0142\28.g6.irpc.AllowedEndpointTypeb\6proto3"),
     "load irpc_descriptor msg failed")

--- @brief 缺省的schemaless的method访问过滤器，以"__"开头的所有Method默认不允许访问
local function DefaultSchemalessAccessFilter(RPCName, MethodName)
    if (string.find(MethodName, "__") == 1) then
        return false;
    end
    return true;
end

local IRPCInnerFunctions = {
    ["Cancel"] = function (tClient, ClientContext)
        tClient.mIRPCClient:Cancel(ClientContext)
    end,
    ["CancelAll"] = function (tClient)
        tClient.mIRPCClient:CancelAll()
    end
}

local function CreateIRPCClient()
    local tRPCClient = {}
    for name, func in pairs(IRPCInnerFunctions) do
        tRPCClient[name] = func
    end
    return tRPCClient
end

-- schemaless可访问Method的过滤器
IRPC.mSchemalessAccessFilter = DefaultSchemalessAccessFilter

function IRPC:Open()
    return IRPCLite:Open();
end

function IRPC:Close()
    return IRPCLite:Close();
end

--- @brief 设置Schemaless协议的Method访问的filter
--- @param AccessFilter function(RPCName, MethodName) return bool，schemaless名字的过滤规则
--- @note AccessFilter 返回true时，可以访问；返回false时，不允许访问
--- @note 默认规则为不允许方位"__"开始的Method
function IRPC:SetSchemalessAccessFilter(AccessFilter)
    self.mSchemalessAccessFilter = AccessFilter
end

local function SetClientMethod(tClient, MethodName, MethodFunc)
    if MethodFunc then
        rawset(tClient, MethodName, MethodFunc)
    else
        IRPCLog.LogError("Cannot find function ", MethodName)
    end
    return MethodFunc
end

local function GetOptions(uProto, OptionName)
    local options = uProto["options"] or {}
    return options[OptionName]
end

--- @brief 获取RPCClient
--- @param CallerName 调用者的名字，例如："HelloClient"
--- @param RPCServiceName 定义的RPC服务的名字，例如："hello.Greeter"
--- @param AsyncType 异步方式，"coroutine"/"callback"，缺省为"callback"
--- @return RPCClient 成功 - table；失败 - nil
--- @note 同步调用方式为 RPCClient:SayHello(ClientContext, Request) return bool, Response
--- @note 异步调用方式为 RPCClient:SayHello(ClientContext, function (ClientContext, Response), Request) return bool
function IRPC:GetRPCClient(CallerName, RPCServiceName, AsyncType)
    local tRPCClient = CreateIRPCClient()
    -- 获取proto信息
    local uServiceProto = PB.service(RPCServiceName);
    if (not uServiceProto) then
        IRPCLog.LogError("Cannot find proto for service ", RPCServiceName);
        return;
    end
    tRPCClient.mRPCServicePrefix = "/" .. RPCServiceName .. "/";
    tRPCClient.mProto = uServiceProto;
    -- 获取IRPCClient
    local tIRPCClient = IRPCLite:InitIRPCClient(CallerName)
    if (not tIRPCClient) then
        IRPCLog.LogError("Init IRPC Client fail");
        return;
    end
    tRPCClient.mIRPCClient = tIRPCClient;
    -- 所有客户端请求公用一个Pb.Buffer
    tRPCClient.mReqBuffer = PBBuffer.new()

    -- 创建调用元表
    local tClientMt = {}
    tClientMt.__index = function (t, sFuncName)
        local uFunctionProto = uServiceProto.methods[sFuncName]
        local MethodFunc
        if not uFunctionProto then
            uFunctionProto = uServiceProto.methods[sFuncName:sub(0, -8)]
            if uFunctionProto then
                local sFuncNameSuffix = sFuncName:sub(-7)
                local sSizeArgType
                if sFuncNameSuffix == "ReqSize" then
                    sSizeArgType = uFunctionProto.input_type
                elseif sFuncNameSuffix == "RspSize" then
                    sSizeArgType = uFunctionProto.output_type
                end
                if sSizeArgType then
                    MethodFunc = function (tClient, Arg)
                        return PB.encode_size(sSizeArgType, Arg)
                    end
                end
            end
            return SetClientMethod(t, sFuncName, MethodFunc)
        end
        -- if GetOptions(uFunctionProto, "g6.irpc.isBroadCast") then end
        local oneWay = GetOptions(uFunctionProto, "g6.irpc.isOneWay") or GetOptions(uFunctionProto, "g6.irpc.one_way")
        local sFuncFullName = t.mRPCServicePrefix .. sFuncName
        if (AsyncType == "coroutine") then
            -- 基于lua的协程同步
            MethodFunc = function (tClient, ClientContext, Request)
                -- Serialize Request
                local ReqBuffer = tClient.mReqBuffer
                ReqBuffer:reset()
                PB.encode(uFunctionProto.input_type, Request, ReqBuffer)
                -- Invoke
                ClientContext:SetFuncName(sFuncFullName)
                ClientContext:SetEncodeType(IRPCDefine.IrpcContentEncodeType.IRPC_PB_ENCODE)
                if oneWay then
                    ClientContext:SetCallType(IRPCDefine.IrpcCallType.IRPC_ONEWAY_CALL)
                end
                local RspBuffer, ok = tClient.mIRPCClient:Invoke(ClientContext, ReqBuffer);
                if (ok ~= true) then
                    IRPCLog.LogError("Invoke fail: ", sFuncFullName);
                    return false;
                end
                -- Deserialize Response
                if (RspBuffer ~= nil) then
                    return true, PB.decode(uFunctionProto.output_type, RspBuffer);
                end
                return true;
            end
        else
            -- 基于callback的异步
            MethodFunc = function (tClient, ClientContext, Request, Callback)
                -- Serialize Request
                local ReqBuffer = tClient.mReqBuffer
                ReqBuffer:reset()
                PB.encode(uFunctionProto.input_type, Request, ReqBuffer)
                -- Invoke
                ClientContext:SetFuncName(sFuncFullName)
                ClientContext:SetEncodeType(IRPCDefine.IrpcContentEncodeType.IRPC_PB_ENCODE)
                local ok
                if oneWay then
                    ClientContext:SetCallType(IRPCDefine.IrpcCallType.IRPC_ONEWAY_CALL)
                    ok = tClient.mIRPCClient:AsyncInvoke(ClientContext, ReqBuffer)
                else
                    local CallbackWrapper = function (ClientContext, RspBuffer)
                        -- Deserialize Response
                        if Callback ~= nil then
                            Response = PB.decode(uFunctionProto.output_type, RspBuffer);
                            Callback(ClientContext, Response);
                        end
                    end
                    ok = tClient.mIRPCClient:AsyncInvoke(ClientContext, ReqBuffer, CallbackWrapper);
                end
                if (ok ~= true) then
                    IRPCLog.LogError("Invoke fail: ", sFuncFullName);
                    return false;
                end
                return true;
            end
        end
        return SetClientMethod(t, sFuncName, MethodFunc)
    end

    setmetatable(tRPCClient, tClientMt);
    return tRPCClient;
end

--- @brief 获取RPCClient
--- @param CallerName 调用者的名字，例如："HelloClient"
--- @param RPCServiceName 定义的RPC服务的名字，例如："hello.Greeter"
--- @param AsyncType 异步方式，"coroutine"/"callback"，缺省为"callback"
--- @return 成功 - table RPCClient；失败 - nil
--- @note 同步调用方式为 RPCClient:SayHello(ClientContext, Request ...) return bool, Response ...
--- @note 异步调用方式为 RPCClient:SayHello(ClientContext, function (ClientContext, Response ...), Request ...) return bool
function IRPC:GetSchemalessRPCClient(CallerName, RPCServiceName, AsyncType)
    local tRPCClient = CreateIRPCClient()
    tRPCClient.mRPCServicePrefix = "/" .. RPCServiceName .. "/";
    -- 获取IRPCClient
    local tIRPCClient = IRPCLite:InitIRPCClient(CallerName)
    if (not tIRPCClient) then
        IRPCLog.LogError("Init IRPC Client fail");
        return;
    end
    tRPCClient.mIRPCClient = tIRPCClient;
    tRPCClient.GetSerializedSize = function (tClient, ...)
        return IRPCCore.GetSchemalessSerializedSize(...)
    end
    -- 创建调用元表
    local tClientMt = {}
    if (AsyncType == "coroutine") then
        tClientMt.__index = function (t, sFuncName)
            local MethodFunc = function (tClient, ClientContext, ...)
                -- Serialize Request
                local paranum = select('#', ...);
                local tPackedReq;
                if (paranum > 0) then
                    tPackedReq = table.pack(...);
                end
                -- Invoke
                local sFuncFullName = tClient.mRPCServicePrefix .. sFuncName
                ClientContext:SetFuncName(sFuncFullName)
                ClientContext:SetEncodeType(IRPCDefine.IrpcContentEncodeType.IRPC_FLATBUFFER_ENCODE)
                local tPackedRsp, ok = tClient.mIRPCClient:Invoke(ClientContext, tPackedReq);
                if (ok ~= true) then
                    IRPCLog.LogError("Invoke fail: ", sFuncFullName);
                    return false;
                end
                -- Deserialize Response
                if (tPackedRsp ~= nil) then
                    return true, table.unpack(tPackedRsp);
                end
                return true;
            end
            rawset(t, sFuncName, MethodFunc)
            return MethodFunc
        end
    else
        tClientMt.__index = function (t, sFuncName)
            local MethodFunc = function (tClient, ClientContext, Callback, ...)
                -- Serialize Request
                local paranum = select('#', ...);
                local tPackedReq;
                if (paranum > 0) then
                    tPackedReq = table.pack(...);
                end
                -- Invoke
                local sFuncFullName = tClient.mRPCServicePrefix .. sFuncName
                ClientContext:SetFuncName(sFuncFullName)
                ClientContext:SetEncodeType(IRPCDefine.IrpcContentEncodeType.IRPC_FLATBUFFER_ENCODE)
                local CallbackWrapper = function (ClientContext, tPackedRsp)
                    -- Deserialize Response
                    if Callback ~= nil then
                        if (tPackedRsp ~= nil) then
                            Callback(ClientContext, table.unpack(tPackedRsp));
                        else
                            Callback(ClientContext);
                        end
                    end
                end
                local ok = tClient.mIRPCClient:AsyncInvoke(ClientContext, tPackedReq, CallbackWrapper);
                if (ok ~= true) then
                    IRPCLog.LogError("Invoke fail: ", sFuncFullName);
                    return false;
                end
                return true;
            end
            rawset(t, sFuncName, MethodFunc)
            return MethodFunc
        end
    end
    setmetatable(tRPCClient, tClientMt);
    return tRPCClient;
end

local AllowedEndpointTypes = {
    DefaultEndpoint = 0x00,
    ServiceEndpoint = IRPCDefine.EndpointType.SERVICE_ENDPOINT,
    SessionEndpoint = IRPCDefine.EndpointType.SESSION_ENDPOINT,
    RawTcpEndpoint  = IRPCDefine.EndpointType.RAW_TCP_ENDPOINT,
    EntityEndpoint  = IRPCDefine.EndpointType.ENTITY_ENDPOINT,
    AllEndpoint     = -1
}

local function GetAllowedEndpointType(optionValues)
    local option = AllowedEndpointTypes.DefaultEndpoint
    if optionValues ~= nil then
        for _, v in ipairs(optionValues) do
            option = bit.bor(option, AllowedEndpointTypes[v])
        end
    end
    return option
end

--- @brief 绑定RPCService
--- @param RPCServiceName 定义的RPC服务的名字，例如："hello.Greeter"
--- @param RPCServiceImpl RPCService的具体实现
--- @param IsCreateCoroutine 是否创建协程，缺省为否
--- @return 成功 - true；失败 - false
--- @note RPCServiceImpl中Method的实现方式为 RPCServiceImpl:SayHello(ServerContext, Request) return Response
function IRPC:BindRPCService(RPCServiceName, RPCServiceImpl, IsCreateCoroutine)
    -- 获取proto信息
    local uServiceProto = PB.service(RPCServiceName);
    if (not uServiceProto) then
        IRPCLog.LogError("Cannot find proto for service ", RPCServiceName);
        return false;
    end
    local ServiceAllowedEndpointType = GetAllowedEndpointType(GetOptions(uServiceProto, "g6.irpc.service_caller_endpoint_type"))
    if ServiceAllowedEndpointType == AllowedEndpointTypes.DefaultEndpoint then
        ServiceAllowedEndpointType = AllowedEndpointTypes.AllEndpoint
    end
    -- 检查proto定义的method都有实现
    local tServiceMethodInfos = {}
    for MethodName, MethodInfo in pairs(uServiceProto.methods) do
        local MethodFunc = RPCServiceImpl[MethodName]
        if (type(MethodFunc) ~= "function") then
            IRPCLog.LogError("Cannot find function for RPCMethod ", MethodName);
            return false;
        end
        local FullMethodName = "/" .. RPCServiceName .. "/" .. MethodName
        local MethodAllowedEndpointType = GetAllowedEndpointType(GetOptions(MethodInfo, "g6.irpc.method_caller_endpoint_type"))
        if MethodAllowedEndpointType == AllowedEndpointTypes.DefaultEndpoint then
            MethodAllowedEndpointType = ServiceAllowedEndpointType
        end
        tServiceMethodInfos[FullMethodName] = { MethodInfo, MethodFunc, MethodAllowedEndpointType }
    end
    -- 获取IRPCServer
    local tIRPCServer = IRPCLite:InitIRPCServer()
    if (not tIRPCServer) then
        IRPCLog.LogError("Init IRPC Server fail for service");
        return false;
    end
    -- 创建RPCServiceImpl的handler
    local tRPCServiceHandler = {}
    tRPCServiceHandler.mIRPCServer = tIRPCServer;
    tRPCServiceHandler.mMethodInfos = tServiceMethodInfos;
    tRPCServiceHandler.mRPCServiceImpl = RPCServiceImpl;

     -- 处理所有请求的响应公用一个Pb.Buffer
    tRPCServiceHandler.mRespBuffer = PBBuffer.new()
    -- 设置handler的处理方法
    function tRPCServiceHandler:HandleRequest(ServerContext, ReqBuffer)
        -- Check Function Info
        local sFuncName = ServerContext:GetFuncName()
        local uMethodInfo = self.mMethodInfos[sFuncName]
        if (uMethodInfo == nil) then
            -- 检查是否有缺省的处理方法，当缺省处理方法存在时由缺省处理方法处理，缺省方法允许通过元表查找
            local DefaultMethod = self.mRPCServiceImpl["default_handler"]
            if (type(DefaultMethod) == "function") then
                IRPCLog.LogDebug(sFuncName, "handler by default_handler");
                local strPackedRsp = DefaultMethod(self.mRPCServiceImpl, ServerContext, ReqBuffer);
                if (ServerContext:GetCallType() ~= IRPCDefine.IrpcCallType.IRPC_ONEWAY_CALL) then
                    self.mIRPCServer:SendResponse(ServerContext, strPackedRsp);
                end
                return true;
            end
            -- default handler无法编解码，仍然返回失败给客户端
            IRPCLog.LogError("Cannot find function ", sFuncName);
            return false;
        end
        local AllowedEndpointType = uMethodInfo[3]
        if AllowedEndpointType ~= -1 then
            if bit.band(AllowedEndpointType, ServerContext:GetEndpointType()) == 0 then
                IRPCLog.LogDebug(sFuncName, "irpc request by unsupport endpoint type", ServerContext:GetEndpointType())
                return false;
            end
        end
        -- Deserialize Request
        local Request = PB.decode(uMethodInfo[1].input_type, ReqBuffer);
        -- Invoke
        local Resopnse = uMethodInfo[2](self.mRPCServiceImpl, ServerContext, Request);
        -- Serialize Response
        if (ServerContext:GetCallType() ~= IRPCDefine.IrpcCallType.IRPC_ONEWAY_CALL) then
            local RespBuffer = self.mRespBuffer
            RespBuffer:reset()
            PB.encode(uMethodInfo[1].output_type, Resopnse, RespBuffer);
            self.mIRPCServer:SendResponse(ServerContext, RespBuffer);
        end
        return true
    end
    -- 注册Handle到IRPCServer
    local HandlerName = "/" .. RPCServiceName
    return tIRPCServer:AddRPCServiceHandler(HandlerName, tRPCServiceHandler, IsCreateCoroutine)
end

local function SplitMethodName(sFuncName)
    if (type(sFuncName) ~= "string" or #sFuncName == 0) then
        return sFuncName;
    end
    local nSplitPos = string.find(sFuncName, "/", 2);
    if (nSplitPos == nil) then
        return sFuncName;
    end
    return string.sub(sFuncName, nSplitPos + 1)
end

--- @brief 绑定RPCService
--- @param RPCServiceName 定义的RPC服务的名字，例如："hello.Greeter"
--- @param RPCServiceImpl RPCService的具体实现
--- @param IsCreateCoroutine 是否创建协程，缺省为否
--- @return 成功 - true；失败 - false
--- @note RPCServiceImpl中Method的实现方式为 RPCServiceImpl:SayHello(ServerContext, Request ...) return Response ...
function IRPC:BindSchemalessRPCService(RPCServiceName, RPCServiceImpl, IsCreateCoroutine)
    -- 获取IRPCServer
    local tIRPCServer = IRPCLite:InitIRPCServer()
    if (not tIRPCServer) then
        IRPCLog.LogError("Init IRPC Server fail for service");
        return false;
    end
    -- 创建RPCServiceImpl的handler
    local tRPCServiceHandler = {}
    tRPCServiceHandler.mIRPCServer = tIRPCServer;
    tRPCServiceHandler.mRPCServiceName = RPCServiceName;
    tRPCServiceHandler.mRPCServiceImpl = RPCServiceImpl;
    tRPCServiceHandler.mSchemalessAccessFilter = self.mSchemalessAccessFilter;
    -- 设置handler的处理方法
    function tRPCServiceHandler:HandleRequest(ServerContext, tPackedReq)
        tPackedReq = tPackedReq or {}
        -- Check Function Info
        local sFuncName = ServerContext:GetFuncName();
        local sMethodName = SplitMethodName(sFuncName);
        local MethodFunc = nil
        -- 判定是否允许访问Method
        if (self.mSchemalessAccessFilter(self.mRPCServiceName, sMethodName) ~= false) then
            MethodFunc = self.mRPCServiceImpl[sMethodName];
        end
        -- 判定类型
        if (type(MethodFunc) ~= "function") then
            -- 检查是否有缺省的处理方法，当缺省处理方法存在时由缺省处理方法处理，缺省方法允许通过元表查找
            MethodFunc = self.mRPCServiceImpl["default_handler"];
            if (type(MethodFunc) ~= "function") then
                IRPCLog.LogError("Cannot find function ", sFuncName);
                return false;
            end
            IRPCLog.LogDebug(sFuncName, "handler by default_handler");
        end
        -- Deserialize Request & Invoke & Serialize Response
        if (ServerContext:GetCallType() == IRPCDefine.IrpcCallType.IRPC_ONEWAY_CALL) then
            MethodFunc(self.mRPCServiceImpl, ServerContext, table.unpack(tPackedReq));
            return true;
        end
        local tPackedResopnse = { MethodFunc(self.mRPCServiceImpl, ServerContext, table.unpack(tPackedReq)) };
        self.mIRPCServer:SendResponse(ServerContext, tPackedResopnse);
        return true;
    end
    -- 注册Handle到IRPCServer
    local HandlerName = "/" .. RPCServiceName
    return tIRPCServer:AddRPCServiceHandler(HandlerName, tRPCServiceHandler, IsCreateCoroutine)
end

--- @brief 绑定缺省的RPCService，用于接收所有找不到RPCService的RPC请求
--- @param RPCServiceImpl RPCService的具体实现
--- @param IsCreateCoroutine 是否创建协程，缺省为否
--- @return 成功 - true；失败 - false
--- @note RPCServiceImpl中Method的实现方式为 RPCServiceImpl:default_handler(ServerContext, PackedReq) return PackedRsp
---        因为不知道具体协议，所以没有处理协议的打解包，需要使用者自己根据协议类型来处理打解包
function IRPC:BindDefaultService(RPCServiceImpl, IsCreateCoroutine)
    -- 获取IRPCServer
    local tIRPCServer = IRPCLite:InitIRPCServer()
    if (not tIRPCServer) then
        IRPCLog.LogError("Init IRPC Server fail for service");
        return false;
    end
    -- 创建RPCServiceImpl的handler
    local tRPCServiceHandler = {}
    tRPCServiceHandler.mIRPCServer = tIRPCServer;
    tRPCServiceHandler.mRPCServiceImpl = RPCServiceImpl;
    -- 设置handler的处理方法
    function tRPCServiceHandler:HandleRequest(ServerContext, PackedReq)
        PackedReq = PackedReq or {}
        -- Check Function Info
        local MethodFunc = self.mRPCServiceImpl["default_handler"];
        if (type(MethodFunc) ~= "function") then
            IRPCLog.LogError("Cannot find function handler");
            return false;
        end
        -- Deserialize Request & Invoke & Serialize Response
        if (ServerContext:GetCallType() == IRPCDefine.IrpcCallType.IRPC_ONEWAY_CALL) then
            MethodFunc(self.mRPCServiceImpl, ServerContext, PackedReq);
            return true;
        end
        local PackedResopnse = MethodFunc(self.mRPCServiceImpl, ServerContext, PackedReq);
        self.mIRPCServer:SendResponse(ServerContext, PackedResopnse);
        return true;
    end
    -- 注册Handle到IRPCServer
    return tIRPCServer:AddRPCServiceHandler("default", tRPCServiceHandler, IsCreateCoroutine)
end

--- @brief 注册Entity的分发器
--- @param ServiceName RPCService对应的通讯层服务名，例如："HelloService"
--- @param EntityServiceName 定义的Entity的服务名字，例如："PlayerEntity"
--- @param EntityImpl Entity的单个具体实例，用于获取Entity对应的Func信息
--- @param IsCreateCoroutine 是否创建协程，缺省为否
--- @return EntityDispatch
function IRPC:RegisterEntityDispatcher(ServiceName, EntityServiceName, EntityImpl, IsCreateCoroutine)
    -- TODO
    return nil
end

--- @brief 绑定Entity的分发器
--- @param EntityServiceName 定义的Entity的服务名字，例如："PlayerEntity"
--- @param EntityImpl Entity的单个具体实例，用于获取Entity对应的Func信息
--- @param IsCreateCoroutine 是否创建协程，缺省为否
--- @return EntityDispatcher table, 具有 EntityDispatcher:AddEntity(EntityID, EntityImpl)/EntityDispatcher:DelEntity(EntityID)两种方法
function IRPC:BindSchemalessEntityDispatcher(EntityServiceName, IsCreateCoroutine)
    local EntityDispatcher = {}
    EntityDispatcher.mEntities = {};
    EntityDispatcher.mEntityName = EntityServiceName;
    EntityDispatcher.mSchemalessAccessFilter = self.mSchemalessAccessFilter;
    local EntityDispatchFunc = function (tDispatcher, ServerContext, ...)
        local ReqMeta = ServerContext:GetReqMeta();
        local EntityID = -1
        if (ReqMeta.entity_id ~= nil) then
            EntityID = tonumber(ReqMeta.entity_id)
        end
        -- 查找Entity
        local tEntity = rawget(tDispatcher.mEntities, EntityID);
        if (tEntity == nil) then
            -- 检查是否有缺省的处理方法，当缺省处理方法存在时由缺省处理方法处理，缺省方法允许通过元表查找
            local DefaultEntityFunc = tDispatcher["default_entity"];
            if (type(DefaultEntityFunc) ~= "function") then
                IRPCLog.LogError("cannot find entity:", EntityID);
                ServerContext:SetStatus(-1, "cannot find entity");
                return nil;
            end
            IRPCLog.LogDebug(EntityID, "dispatch to default_entity");
            -- 注意：错误信息和返回值都由缺省处理方法中处理
            return DefaultEntityFunc(tDispatcher.mEntityName, ServerContext, ...);
        end
        -- Check Function Info
        local sFuncName = ServerContext:GetFuncName();
        local sMethodName = SplitMethodName(sFuncName);
        local MethodFunc = nil;
        -- 判定是否允许访问Method
        if (tDispatcher.mSchemalessAccessFilter(tDispatcher.mEntityName, sMethodName) ~= false) then
            MethodFunc = tEntity[sMethodName];
        end
        -- 判定类型
        if (type(MethodFunc) ~= "function") then
            -- 检查是否有缺省的处理方法，当缺省处理方法存在时由缺省处理方法处理，缺省方法允许通过元表查找
            MethodFunc = tEntity["default_handler"];
            if (type(MethodFunc) ~= "function") then
                IRPCLog.LogError("cannot find entity method:", EntityID, sFuncName);
                ServerContext:SetStatus(-1, "cannot find entity method");
                return nil;
            end
            IRPCLog.LogDebug(sFuncName, "handler by default_handler");
        end
        -- Invoke
        return MethodFunc(tEntity, ServerContext, ...);
    end
    rawset(EntityDispatcher, "default_handler", EntityDispatchFunc)
    -- 将EntityDispatcher作为RPCService实例注册到底层
    if (not self:BindSchemalessRPCService(EntityServiceName, EntityDispatcher, IsCreateCoroutine)) then
        IRPCLog.LogError("register entity dispatcher fail");
        return nil;
    end
    -- 为EntityDispatcher添加Entity的管理接口
    function EntityDispatcher:AddEntity(EntityID, EntityImpl)
        self.mEntities[EntityID] = EntityImpl;
    end
    function EntityDispatcher:DelEntity(EntityID)
        self.mEntities[EntityID] = nil
    end
    return EntityDispatcher;
end

--- @brief 添加Entity到IRPC
--- @param EntityID 待加入的Entity的ID
--- @param EntityName 待加入的Entity的名字
--- @param EntityImpl 待加入的Entity对象实例
--- @note 使用此接口后EntityDispatch将由IRPC内部管理，外部不需要使用RegisterSchemalessEntityDispatcher接口获取Dispatcher来管理
function IRPC:AddEntity(EntityID, EntityName, EntityImpl)
    local tEntityDispatcher = rawget(self.mEntityDispatchers, EntityName)
    if (tEntityDispatcher == nil) then
        tEntityDispatcher = self:BindSchemalessEntityDispatcher(EntityName, self.mIsCreateCoroutineForEntity)
        if (tEntityDispatcher == nil) then
            IRPCLog.LogError("create dispatcher for entity fail,", EntityID, EntityName);
            return false
        end
        if (self.mDefaultEntityHandler ~= nil) then
            rawset(tEntityDispatcher, "default_entity", self.mDefaultEntityHandler);
        end
        -- 更新到mEntityDispatchers中
        rawset(self.mEntityDispatchers, EntityName, tEntityDispatcher)
        IRPCLog.LogDebug("create dispatcher for entity", EntityName);
    end
    tEntityDispatcher:AddEntity(EntityID, EntityImpl);
    return true;
end

--- @brief 添加Entity到IRPC
--- @param EntityID 待移除的Entity的ID
--- @param EntityName 待移除的Entity的名字
function IRPC:DelEntity(EntityID, EntityName)
    local tEntityDispatcher = rawget(self.mEntityDispatchers, EntityName)
    if (tEntityDispatcher ~= nil) then
        tEntityDispatcher:DelEntity(EntityID);
    end
    return true;
end

--- @brief 添加Entity找不到
--- @param DefaultEntityHandler function(EntityName, ServerContext, Req ...) return Rsp ...
--- @note 此接口用于EntityDispatch内部管理时，为内部管理的EntityDispatch设置DefaultEntity处理方法
function IRPC:SetDefaultEntityHandler(DefaultEntityHandler)
    if ((DefaultEntityHandler == nil) or (type(DefaultEntityHandler) == "function")) then
        self.mDefaultEntityHandler = DefaultEntityHandler;
        for EntityName, tEntityDispatcher in pairs(self.mEntityDispatchers) do
            rawset(tEntityDispatcher, "default_entity", DefaultEntityHandler);
        end
        return true;
    end
    return false;
end

return IRPC;
