require "UnLua"
local IRPC = require("micro_service.irpc.irpc")
local IRPCDefine = require("micro_service.irpc.irpc_define")
local PROTOC = require("micro_service.irpc.protoc").new()
local IRPCLog = require("micro_service.irpc.irpc_log")
local IRPCCore = require("irpc_core")

IRPC:Open()
PROTOC:addpath(UE.UKismetSystemLibrary.GetProjectContentDirectory() .. "Protos/")
PROTOC:addpath(UE.UKismetSystemLibrary.GetProjectContentDirectory() .. "Protos/Thirdparty/")

PROTOC:loadfile("Services/LobbyService.proto")
PROTOC:loadfile("Services/WorldProxyService.proto")

function AsyncCallback(Context, Response)
    local Status = Context:GetStatus()
    if (not Status:OK()) then
        IRPCLog.LogError("Server AsyncCallback fail, frame: %d, func: %d, msg: %s", Status:GetFrameworkRetCode(), Status:GetFuncRetCode(), Status:ErrorMessage())
        return
    end
    IRPCLog.LogInfo("Server AsyncCallback succ")
end

local M = {}

M.AsyncLobbyClient = IRPC:GetRPCClient("G6Connector_DSSDK", "HiGame.Lobby")
M.AsyncWorldManagerClient = IRPC:GetRPCClient("G6Connector_DSSDK", "HiGame.WorldProxyManager")

function M:AsyncCallLobbyFunction(FuncName, FuncRequest, Callback)
    Callback = Callback or AsyncCallback
    local ClientContext = IRPCCore:NewClientContext()
    -- 测试期间设置超时为30秒
    ClientContext:SetTimeout(30 * 1000)
    ClientContext:SetTargetService("DsaService")
    ClientContext:AddReqMeta("g6_forward_service", "LobbyService")
    local bResult = M.AsyncLobbyClient[FuncName](M.AsyncLobbyClient, ClientContext, FuncRequest, Callback)
    return bResult, ClientContext:GetStatus()
end

function M:AsyncCallWorldManagerFunction(FuncName, FuncRequest, Callback)
    Callback = Callback or AsyncCallback
    local ClientContext = IRPCCore:NewClientContext()
    -- 测试期间设置超时为30秒
    ClientContext:SetTimeout(30 * 1000)
    ClientContext:SetTargetService("DsaService")
    ClientContext:AddReqMeta("g6_forward_service", "WorldProxyService")
    local bResult = M.AsyncWorldManagerClient[FuncName](M.AsyncWorldManagerClient, ClientContext, FuncRequest, Callback)
    return bResult, ClientContext:GetStatus()
end

return M

-- example here
-- local ServerMS = require("micro_service.server_ms")
-- local IRPCLog = require("micro_service.irpc.irpc_log")
-- function AsyncCallback2(Context, Response)
--     local Status = Context:GetStatus()
--     if (not Status:OK()) then
--         IRPCLog.LogError("Server AsyncCallback2 fail, frame: %d, func: %d, msg: %s", Status:GetFrameworkRetCode(), Status:GetFuncRetCode(), Status:ErrorMessage())
--         return
--     end
--     IRPCLog.LogInfo("Server AsyncCallback2 succ")
-- end
-- local QueryAvatarRequest = {
--     AvatarProxyID = 1000001
-- }
-- local bResult, ClientStatus = ServerMS:AsyncCallLobbyFunction("QueryAvatar", QueryAvatarRequest, AsyncCallback2)
-- if not bResult or not ClientStatus:OK() then
--     IRPCLog.LogError("Server QueryAvatar fail, result: %s, frame: %d, func: %d, msg: %s", bResult, ClientStatus:GetFrameworkRetCode(), ClientStatus:GetFuncRetCode(), ClientStatus:ErrorMessage())
--     return
-- else
--     IRPCLog.LogInfo("Server QueryAvatar succ")
-- end
