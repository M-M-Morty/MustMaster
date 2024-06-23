
------------------------------------------
--- IRPC Client/Server管理
--- 1: 提供Lua IRPC Client/Server的管理
--- 2：Lua层IRPC Client/Server和IRPCCore(C++)层对接
--- 3：提供基于lua层的协程、回调等异步能力
------------------------------------------
---@class IRPCLite

local IRPCCore = require "irpc_core"
local IRPCLog = require "micro_service.irpc.irpc_log"
local IRPCDefine = require "micro_service.irpc.irpc_define"

local IRPCLite = {}

IRPCLite.mID = 1
IRPCLite.mIRPCClients = {}
IRPCLite.mIRPCServices = {}

-- 这里不支持DS，DS建议用Entity那一套提供服务
function GetClientTransName()
	return "G6Connector"
end

function IRPCLite:Open()
	return IRPCCore.Open()
end

function IRPCLite:Close()
	return IRPCCore.Close()
end

--- IRPCClient Define begin
local IRPCClient = {}

function IRPCClient.New(CallerName)
	local tIRPCClient = {}
	tIRPCClient.mCallInfo = {}
	tIRPCClient.mIRPCClient = IRPCCore.NewRPCClient(CallerName)
	setmetatable(tIRPCClient, {__index = IRPCClient})
	return tIRPCClient
end

--- @brief 同步调用
function IRPCClient:Invoke(ClientContext, PackedRequest)
	if (not coroutine.isyieldable()) then
		IRPCLog.LogError("Sync invoke should call in coroutine")
		return nil, false
	end
	local ok, seq = self.mIRPCClient:InvokeAsync(ClientContext, PackedRequest)
	if ok and seq then
		self.mCallInfo[seq] = coroutine.running()
		return coroutine.yield(), true
	end
	return nil, ok
end

--- @brief 异步调用
function IRPCClient:AsyncInvoke(ClientContext, PackedRequest, CallbackFunc)
	local ok, seq = self.mIRPCClient:InvokeAsync(ClientContext, PackedRequest)
	if ok and seq then
		self.mCallInfo[seq] = CallbackFunc
	end
	return ok
end

--- @brief 取消指定调用
function IRPCClient:Cancel(ClientContext)
	self.mIRPCClient:Cancel(ClientContext)
end

--- @brief 取消所有调用
function IRPCClient:CancelAll()
	self.mIRPCClient:CancelAll()
end
--- IRPCClient Define end

--- @brief IRPCCore层对IRPCClient的回调接口
function IRPCLite:ClientAsyncCallback(IRPCClientID, ClientContext, PackedResponse)
	--- 查找IRPCClient
	local tIRPCClient = self.mIRPCClients[IRPCClientID]
	if (tIRPCClient == nil) then
		return false
	end
	--- 查找CallInfo并调用Callback
	local ReqID = ClientContext:GetRequestId()
	local CallInfo = tIRPCClient.mCallInfo[ReqID]
	tIRPCClient.mCallInfo[ReqID] = nil -- erase request info
	if (type(CallInfo) == "function") then
		CallInfo(ClientContext, PackedResponse)
		return true
	end
	if (type(CallInfo) == "thread") then
		local ok, err = coroutine.resume(CallInfo, PackedResponse)
		if not ok then
			IRPCLog.LogError("coroutine err:", err)
		end
		return ok
	end
	return false
end

--- @brief 获取IRPC客户端
function IRPCLite:InitIRPCClient(CallerName)
	local tIRPCClient = IRPCClient.New(CallerName or GetClientTransName())
	tIRPCClient.mID = self.mID
	tIRPCClient.mIRPCClient:SetResponseCallback(self.mID, "IRPCLite:ClientAsyncCallback")
	self.mIRPCClients[self.mID] = tIRPCClient
	self.mID = self.mID + 1
	return tIRPCClient
end

--- IRPCServer Define begin
local IRPCServer = {}

function IRPCServer.New(ServiceName)
	local tIRPCServer = {}
	tIRPCServer.mIRPCService = IRPCCore.NewRPCService(ServiceName)
	setmetatable(tIRPCServer, {__index = IRPCServer})
	return tIRPCServer
end

--- @brief 添加处理器
function IRPCServer:AddRPCServiceHandler(HandlerName, tRPCServiceHandler, IsCreateCoroutine)
	self.mRPCServiceHandler = tRPCServiceHandler
	self.mIsCreateCoroutine = IsCreateCoroutine
	return self.mIRPCService:AddRPCServiceHandler(HandlerName, self.mID, "IRPCLite:ServiceRequestHandler")
end

-- 发送响应
function IRPCServer:SendResponse(ServerContext, PackedResponse)
	return self.mIRPCService:SendResponse(ServerContext, PackedResponse)
end
--- IRPCService Define end

--- 协程处理函数
local function ServiceCorFunc(Server, ServerContext, PackedRequest)
	local ok, err = xpcall(Server.mRPCServiceHandler.HandleRequest,
		function (errobj)
			return errobj .. debug.traceback("\n", 1)
		end,
		Server.mRPCServiceHandler,
		ServerContext,
		PackedRequest
	)
	if not ok then
		IRPCLog.LogError("handle rpc req err:", err)
	end
end

--- @brief IRPCCore层对IRPCService的回调接口
function IRPCLite:ServiceRequestHandler(IRPCServerID, ServerContext, PackedRequest)
	--- 查找IRPCClient
	local tIRPCServer = self.mIRPCServices[IRPCServerID]
	if (tIRPCServer == nil) then
		IRPCLog.LogError("cannot find RPCServer: ", IRPCServerID)
		return false
	end
	--- 协程模式
	if (tIRPCServer.mIsCreateCoroutine == true) then
		local co = coroutine.create(ServiceCorFunc)
		local ok, err = coroutine.resume(co, tIRPCServer, ServerContext, PackedRequest)
		if not ok then
			IRPCLog.LogError("RPCServer coroutine err: ", err)
		end
		return ok
	end
	--- 非协程直接回调上层Handler
	return tIRPCServer.mRPCServiceHandler:HandleRequest(ServerContext, PackedRequest)
end

--- @brief 获取IRPC服务端transport
function IRPCLite:InitIRPCServer()
	local tIRPCServer = IRPCServer.New(GetClientTransName())
	tIRPCServer.mID = self.mID
	self.mIRPCServices[self.mID] = tIRPCServer
	self.mID = self.mID + 1
	return tIRPCServer
end

_G.IRPCLite = IRPCLite

return IRPCLite
