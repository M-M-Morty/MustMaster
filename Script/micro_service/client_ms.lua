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
        IRPCLog.LogError("Client AsyncCallback fail, frame: %d, func: %d, msg: %s", Status:GetFrameworkRetCode(), Status:GetFuncRetCode(), Status:ErrorMessage())
        return
    end
    IRPCLog.LogInfo("Client AsyncCallback succ")
end

local M = {}

M.AsyncLobbyClient = IRPC:GetRPCClient("G6Connector", "HiGame.Lobby")
M.AsyncWorldManagerClient = IRPC:GetRPCClient("G6Connector", "HiGame.WorldProxyManager")

function M:AsyncCallLobbyFunction(FuncName, FuncRequest, Callback)
    Callback = Callback or AsyncCallback
    local ClientContext = IRPCCore:NewClientContext()
    -- 测试期间设置超时为30秒
    ClientContext:SetTimeout(30 * 1000)
    ClientContext:SetTargetService("LobbyService")
    local bResult = M.AsyncLobbyClient[FuncName](M.AsyncLobbyClient, ClientContext, FuncRequest, Callback)
    return bResult, ClientContext:GetStatus()
end

function M:AsyncCallWorldManagerFunction(FuncName, FuncRequest, Callback)
    Callback = Callback or AsyncCallback
    local ClientContext = IRPCCore:NewClientContext()
    -- 测试期间设置超时为30秒
    ClientContext:SetTimeout(30 * 1000)
    ClientContext:SetTargetService("WorldProxyService")
    local bResult =  M.AsyncWorldManagerClient[FuncName](M.AsyncWorldManagerClient, ClientContext, FuncRequest, Callback)
    return bResult, ClientContext:GetStatus()
end

return M

-- example here
-- local ClientMS = require("micro_service.client_ms")
-- local IRPCLog = require("micro_service.irpc.irpc_log")
-- function AsyncCallback(Context, Response)
--     local Status = Context:GetStatus()
--     if (not Status:OK()) then
--         IRPCLog.LogError("Client AsyncCallback1 fail, frame: %d, func: %d, msg: %s", Status:GetFrameworkRetCode(), Status:GetFuncRetCode(), Status:ErrorMessage())
--         return
--     end
--     IRPCLog.LogInfo("Client AsyncCallback1 succ")
-- end
-- local QueryAvatarRequest = {
--     AvatarProxyID = 1000001
-- }
-- local bResult, ClientStatus = ClientMS:AsyncCallLobbyFunction("QueryAvatar", QueryAvatarRequest, AsyncCallback)
-- if not bResult or not ClientStatus:OK() then
--     IRPCLog.LogError("Client QueryAvatar fail, result: %s, frame: %d, func: %d, msg: %s", bResult, ClientStatus:GetFrameworkRetCode(), ClientStatus:GetFuncRetCode(), ClientStatus:ErrorMessage())
--     return
-- else
--     IRPCLog.LogInfo("Client QueryAvatar succ")
-- end
