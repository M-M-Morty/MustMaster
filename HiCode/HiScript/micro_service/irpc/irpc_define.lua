
local IrpcDefine =
{
    -- irpc协议中的调用类型
    IrpcCallType =
    {
        -- 一应一答调用，包括同步、异步
        IRPC_UNARY_CALL = 0,

        -- 单向调用
        IRPC_ONEWAY_CALL = 1,
    },

    -- irpc协议中的消息透传支持的类型
    IrpcMessageType =
    {
        -- 染色
        IRPC_DYEING_MESSAGE = 0x01,

        -- 调用链
        IRPC_TRACE_MESSAGE = 0x02,
    },

    -- irpc协议中body内容的编码类型
    IrpcContentEncodeType =
    {
        -- pb
        IRPC_PB_ENCODE = 0,

        -- json
        IRPC_JSON_ENCODE = 1,

        -- flatbuffer
        IRPC_FLATBUFFER_ENCODE = 2,

        -- 不序列化
        IRPC_NOOP_ENCODE = 3,
    },

    EndpointType =
    {
        UNKNOWN_ENDPOINT = 0x00,
        -- @brief 服务实例类地址
        -- @note 后台服务之间IRPC调用、前端PC/手机调用后台服务时 指定服务实例地址
        -- @note 服务实例地址通常由 服务名 + 服务实例ID 组成
        --           服务名格式：[game_id.][env_name.]service_name，为后台进程注册到名字服务的名称
        --           服务实例ID用于区分服务名下的不同进程实例
        -- @note 地址的服务名和IRPCService的名字不相同
        --           地址的服务名为IRPCService承载的通讯地址
        --           IRPCService的名字为proto中指定的接口名称"/package.irpc_service"
        SERVICE_ENDPOINT = 0x01,
        -- @brief 前端会话ID类地址
        -- @note 后台服务调用前端PC/手机时 指定前端会话ID地址
        -- @note 前端通过tsf4g 2.0的gate接入后会被分配一个会话ID，此ID用于后台服务指定同前端通讯
        SESSION_ENDPOINT = 0x02,
        RAW_TCP_ENDPOINT = 0x04,
        -- @brief entity对象(路由)地址
        -- @note 后台根据具体的对象的路由地址(名字+ID 或者 全局唯一的路由ID)访问时 指定对象的(路由)地址
        -- @note 对象的路由地址可以有2中形式:
        --           Entity对象的名字 + 使用者保证名字下唯一的ID
        --           全局唯一的路由ID(EntityID)
        ENTITY_ENDPOINT = 0x08,
    },

    IRPC_DYEING_KEY = "irpc-dyeing-key",
}

return IrpcDefine;
