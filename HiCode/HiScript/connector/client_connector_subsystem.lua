--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require('G')
local ClientConnctorDefines = require("connector.client_connector_defines")
local ConnectionState = ClientConnctorDefines.ConnectionState
local G6Channel = ClientConnctorDefines.G6Channel
local G6AuthType = ClientConnctorDefines.G6AuthType
local G6PlatformType = ClientConnctorDefines.G6PlatformType
local G6ErrorCode = ClientConnctorDefines.G6ErrorCode
local G6ConnectorState = ClientConnctorDefines.G6ConnectorState

---@type BP_ClientConnectorSubsystem_C
local ClientConnectorSubsystem = UnLua.Class()

function ClientConnectorSubsystem:K2_Initialize()
    G.log:debug("xaelpeng", "ClientConnectorSubsystem:K2_Initialize %s", self:GetName())
    self.GSConnectionState = ConnectionState.NoConnection
    self.DSConnectionState = ConnectionState.NoConnection
    self.CurrentGateUrl = nil
    self.GSReconnectTimer = nil
    self.GSReconnectInterval = 1.0
    self.GSReconnectCount = 0
    self.GSReconnectMaxCount = 10
    self:InitConnectorBasicInfo(772782741)
    self:InitConnectorChannelInfo(G6Channel.kChannelTWChat, G6AuthType.kG6Auth_MSDK, G6PlatformType.kAndroid)
    self:InitConnectorSSLInfo(0, "")
end

function ClientConnectorSubsystem:Login(GateUrl, RealmUrl, OpenID, Token)
    if self.GSConnectionState ~= ConnectionState.NoConnection then
        G.log:error("xaelpeng", "ClientConnectorSubsystem:Login State:%s error", self.GSConnectionState)
        return false
    end
    self:InitConnectorUrlInfo(RealmUrl)
    self:InitConnectorUserInfo(0, OpenID, Token, 1600000)
    self.CurrentGateUrl = GateUrl
    self.GSConnectionState = ConnectionState.Connecting
    local Result = self:K2_Connect(GateUrl)
    if not Result then
        self.GSConnectionState = ConnectionState.NoConnection
    end
    return Result
end

function ClientConnectorSubsystem:Logout()
    self:K2_Disconnect()
end

function ClientConnectorSubsystem:OnConnectResult(InResult)
    G.log:debug("xaelpeng", "ClientConnectorSubsystem:OnConnectResult State:%s InResult:%s", self.GSConnectionState, InResult)
    if self.GSConnectionState == ConnectionState.Connecting then
        if InResult == G6ErrorCode.kSuccess then
            self.GSConnectionState = ConnectionState.Connected
            self.ConnectSuccessDelegate:Broadcast()
        else
            self.GSConnectionState = ConnectionState.NoConnection
            self.ConnectFailDelegate:Broadcast()
        end
    else
        G.log:error("xaelpeng", "ClientConnectorSubsystem:OnConnectResult State:%s error", self.GSConnectionState)
    end
end

function ClientConnectorSubsystem:OnDisconnectResult(InResult)
    G.log:debug("xaelpeng", "ClientConnectorSubsystem:OnDisconnectResult State:%s InResult:%s", self.GSConnectionState, InResult)
    self.GSConnectionState = ConnectionState.NoConnection
    if InResult == G6ErrorCode.kSuccess then
    elseif InResult == G6ErrorCode.kErrorPeerStopSession then
        -- todo. maybe we should disconnect DS
    end
end

function ClientConnectorSubsystem:OnConnectionStateChange(InState, InResult)
    G.log:debug("xaelpeng", "ClientConnectorSubsystem:OnConnectionStateChange State:%s ConnectionState:%s Result:%s", self.GSConnectionState, InState, InResult)
    if self.GSConnectionState == ConnectionState.Connected then
        self.GSConnectionState = ConnectionState.Reconnecting
        self:StartReconnect()
    else
        G.log:warn("xaelpeng", "ClientConnectorSubsystem:OnConnectionStateChange State:%s mismatch", self.GSConnectionState)
    end
end

function ClientConnectorSubsystem:StartReconnect()
    self.GSReconnectCount = 0
    self.GSReconnectTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.OnDelayReconnect}, self.GSReconnectInterval, false)
end

function ClientConnectorSubsystem:OnDelayReconnect()
    self.GSReconnectTimer = nil
    self.GSReconnectCount = self.GSReconnectCount + 1
    
    if self.GSReconnectCount > self.GSReconnectMaxCount then
        G.log:debug("xaelpeng", "ClientConnectorSubsystem:OnDelayReconnect Stopped State:%s Count:%s", self.GSConnectionState, self.GSReconnectCount)
        self.DisconnectDelegate:Broadcast()
        -- goto /Game/Maps/LV_Login/LoginMap?Name=Player
        return
    end

    G.log:debug("xaelpeng", "ClientConnectorSubsystem:OnDelayReconnect State:%s Count:%s", self.GSConnectionState, self.GSReconnectCount)
    if self:K2_CanReconnect() then
        if not self:K2_Reconnect() then
            self.GSReconnectTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.OnDelayReconnect}, self.GSReconnectInterval, false)
        end
    else
        self.DisconnectDelegate:Broadcast()
        -- goto /Game/Maps/LV_Login/LoginMap?Name=Player
    end
end

function ClientConnectorSubsystem:OnReconnectResult(InResult)
    G.log:debug("xaelpeng", "ClientConnectorSubsystem:OnReconnectResult State:%s InResult:%s", self.GSConnectionState, InResult)
    if self.GSConnectionState == ConnectionState.Reconnecting then
        if InResult == G6ErrorCode.kSuccess then
            self.GSConnectionState = ConnectionState.Connected
        else
            self.GSReconnectTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.OnDelayReconnect}, self.GSReconnectInterval, false)
        end
    else
        G.log:error("xaelpeng", "ClientConnectorSubsystem:OnReconnectResult State:%s mismatch", self.GSConnectionState)
    end
end

function ClientConnectorSubsystem:OnLoginSucc(InGuid, InAvatarProxyID, InAvatarGid)
    G.log:debug("xaelpeng", "ClientConnectorSubsystem:OnLoginSucc State:%s InGuid:%s InAvatarProxyID:%s InAvatarGid:%s", self.GSConnectionState, InGuid, 
        InAvatarProxyID, InAvatarGid)
    self.Guid = InGuid
    self.AvatarProxyID = InAvatarProxyID
    self.AvatarGid = InAvatarGid
    self.LoginSuccDelegate:Broadcast()
end

function ClientConnectorSubsystem:OnLoginFail(InGuid, InErrorCode)
    G.log:debug("xaelpeng", "ClientConnectorSubsystem:OnLoginFail State:%s InGuid:%s InErrorCode:%s", self.GSConnectionState, InGuid, InErrorCode)
    self:Logout()
    self.LoginFailDelegate:Broadcast()
end

function ClientConnectorSubsystem:OnNotifyChooseWorld()
    G.log:debug("xaelpeng", "ClientConnectorSubsystem:OnNotifyChooseWorld")
    self.ChooseWorldDelegate:Broadcast()
end

function ClientConnectorSubsystem:OnNotifyEnterPartition(InWorldID, InPartitionID, InEntranceUrl, InAuthToken)
    G.log:debug("xaelpeng", "ClientConnectorSubsystem:OnNotifyEnterPartition WorldID:%s PartitionID:%s EntranceUrl:%s AuthToken:%s",
        InWorldID, InPartitionID, InEntranceUrl, InAuthToken)
    self.DSConnectionState = ConnectionState.Connecting
    -- 注意！！！这里的uid和PlayerID都是PlayerProxyID
    local Url = string.format("%s?WorldID=%s?LoginPartID=%s?Guid=%s?PlayerRoleId=%s?uid=%s?PlayerID=%s?token=%s", InEntranceUrl, 
        InWorldID, InPartitionID, self.Guid, self.AvatarGid, self.AvatarProxyID, self.AvatarProxyID, InAuthToken)
    self:ClientTravel(Url)
end

function ClientConnectorSubsystem:OnTravelFailure(FailureType, ErrorString)
    G.log:debug("xaelpeng", "ClientConnectorSubsystem:OnTravelFailure State:%s FailureType:%s ErrorString:%s", self.DSConnectionState, FailureType, ErrorString)
    if self.DSConnectionState == ConnectionState.Connecting or self.DSConnectionState == ConnectionState.Connected then
        self.DSConnectionState = ConnectionState.NoConnection
    end
end

function ClientConnectorSubsystem:OnNetworkFailure(FailureType, ErrorString)
    G.log:debug("xaelpeng", "ClientConnectorSubsystem:OnNetworkFailure State:%s FailureType:%s ErrorString:%s", self.DSConnectionState, FailureType, ErrorString)
    if self.DSConnectionState == ConnectionState.Connecting or self.DSConnectionState == ConnectionState.Connected then
        self.DSConnectionState = ConnectionState.NoConnection
    end
end

function ClientConnectorSubsystem:OnEnterDedicatedServer()
    G.log:debug("xaelpeng", "ClientConnectorSubsystem:OnEnterDedicatedServer State:%s", self.DSConnectionState)
    self.DSConnectionState = ConnectionState.Connected
end

function ClientConnectorSubsystem:OnLeaveDedicatedServer()
    G.log:debug("xaelpeng", "ClientConnectorSubsystem:OnLeaveDedicatedServer State:%s", self.DSConnectionState)
    if self.DSConnectionState == ConnectionState.Connecting or self.DSConnectionState == ConnectionState.Connected then
        self.DSConnectionState = ConnectionState.NoConnection
    end
end

return ClientConnectorSubsystem