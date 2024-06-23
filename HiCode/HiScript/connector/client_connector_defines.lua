--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local M = {}

M.ConnectionState = {
    NoConnection = 0,
    Connecting = 1,
    Connected = 2,
    Reconnecting = 3,
}

M.G6Channel = {
    kChannelNone = 0,
    kChannelTWChat = 1,
    kChannelTQChat = 2,
    kChannelGuest = 3,
    kChannelFacebook = 4,
    kChannelGameCenter = 5,
    kChannelGooglePlay = 6,
    kChannelTwitter = 9,
    kChannelGarena = 10,
    kChannelLine = 14,
    kChannelApple = 15,
    kChannelKwai = 17,
    kChannelWeGame = 101,   -- 非MSDK的channel，当G6AuthType为Wegame时务必设置为此值
}

M.G6AuthType = {
    kG6Auth_None = 0,
    kG6Auth_MSDK = 1,       -- MSDKv5，当前仅支持MSDKv5
    kG6Auth_DAW = 2,
    kG6Auth_Wegame = 3,
    kG6Auth_INTL = 4,       -- IntlSDK
    kG6Auth_Plugin = 5,     -- 自定义鉴权
}

M.G6PlatformType = {
    kInvaildPlatform = 0,
    kAndroid = 1,           -- 安卓
    kIOS = 2,               -- 苹果
    kWeb = 3,               -- Web
    kLinux = 4,             -- Linux
    kWindows = 5,           -- Windows
    kSwitch = 6             -- Nintendo switch
}

M.G6ConnectorState = {
    kConnectorStateRunning = 0,
    kConnectorStateReconnecting = 1,
    kConnectorStateReconnected = 2,
    kConnectorStateStayInQueue = 3,
    kConnectorStateError = 4,
}

M.G6ErrorCode = {
    kSuccess = 0,
    kErrorInnerError = 1,
    kErrorNetworkException = 2,
    kErrorTimeout = 3,
    kErrorInvalidArgument = 4,
    kErrorLengthError = 5,
    kErrorUnknown = 6,
    kErrorEmpty = 7,
    
    kErrorNotInitialized = 9,
    kErrorNotSupported = 10,
    kErrorNotInstalled = 11,
    kErrorSystemError = 12,
    kErrorNoPermission = 13,
    kErrorInvalidGameId = 14,
    
    kErrorInvalidToken = 100,
    kErrorNoToken = 101,
    kErrorAccessTokenExpired = 102,
    kErrorRefreshTokenExpired = 103,
    kErrorPayTokenExpired = 104,
    kErrorLoginFailed = 105,
    kErrorUserCancel = 106,
    kErrorUserDenied = 107,
    kErrorChecking = 108,
    kErrorNeedRealNameAuth = 109,
    
    kErrorNoConnection = 200,
    kErrorConnectFailed = 201,
    kErrorIsConnecting = 202,
    kErrorGcpError = 203,
    kErrorPeerCloseConnection = 204,
    kErrorPeerStopSession = 205,
    kErrorPkgNotCompleted = 206,
    kErrorSendError = 207,
    kErrorRecvError = 208,
    kErrorStayInQueue = 209,
    kErrorSvrIsFull = 210,
    kErrorTokenSvrError = 211,
    kErrorAuthFailed = 212,
    kErrorOverflow = 213,
    kErrorDNS = 214,
}

return M