require "UnLua"

local G = require("G")
local GameEventBus = require("common.GameEventBus")

local utils = require("common.utils")

local decorator = require("common.decorator")

local GameAPI = require("common.game_api")

local RoleType = UE.ENetRole

---@class Actor
local Actor = Class()


function Actor:Initialize(...)

    self.__client_components__ = {}

    self.__client_components_message_receivers__ = {}

    self.__server_components__ = {}

    self.__server_components_message_receivers__ = {}

    self.__server_entity_request_handler__ = {}

    self.__hook_func__ = {}

    self.bHasBegunPlay = false
end

function Actor:BP_OnRep_PlayerState()
    -- refresh cache when switch player
    self:RefreshDataCache()
end

function Actor:ReceiveTick(DeltaSeconds)
    self.Overridden.ReceiveTick(self, DeltaSeconds)

    if self.TickCallbackList then
        for _, Item in ipairs(self.TickCallbackList) do
            local Owner, Callback = table.unpack(Item)
            Callback(Owner, DeltaSeconds)
        end
    end
end

---Register tick func.
---@return number callback handle
function Actor:RegisterTickCallback(Owner, Func)
    if not self.TickCallbackList then
        self.TickCallbackList = {}
    end

    table.insert(self.TickCallbackList, {Owner, Func})
    return #self.TickCallbackList
end

---UnRegister tick func.
---@param Handle number tick handle.
function Actor:UnRegisterTickCallback(Handle)
    if Handle <= 0 then
        return
    end

    table.remove(self.TickCallbackList, Handle)
end

function Actor:ReceiveBeginPlay()
    self.Overridden.ReceiveBeginPlay(self)

    GameAPI.__AddActor__(self)
    self.bHasBegunPlay = true
end

function Actor:ReceiveEndPlay(EndPlayReason)
    GameAPI.__RemoveActor__(self)
    --G.log:debug("devin", "ReceiveEndPlay", EndPlayReason)
    GameEventBus.GetEventBusInstance(self):UnregisterByListenerObj(self)

    self.Overridden.ReceiveEndPlay(self, EndPlayReason)
    self:Destroy()
end

function Actor:__AddComponent__(component, start)

    self:AddMessageReceivers(component)
    
    component:__OnAdded__(self)

    for hook_func_type, hook_func in pairs(self.__hook_func__) do
        component:SetHookFunc(hook_func_type, hook_func)
    end

    if start == true then
        component:__Start__()
    end
end

function Actor:EnableComponent(component_name, enable)
    local component = self.__server_components__[component_name]

    if component then
        if enable == true and not component:IsEnable() then
            component:__Start__()
        elseif enable == false and component:IsEnable() then
            component:__Stop__()
        end
    end

    local component = self.__client_components__[component_name]

    if component then
        if enable == true and not component:IsEnable() then
            component:__Start__()
        elseif enable == false and component:IsEnable() then
            component:__Stop__()
        end
    end
end

function Actor:AddMessageReceivers(component)
    local isserver = component:IsServerComponent()

    local message_receivers = self.__client_components_message_receivers__

    if isserver then
        message_receivers = self.__server_components_message_receivers__
    end

    local message_receiver = component:GetDecorator(decorator.decorator_type_message_receiver)
    local decorated_vars = message_receiver:GetDecoratedVars()
    for method_name, v in pairs(decorated_vars) do
        local components = message_receivers[method_name]
        if not components then
            components = {}
            message_receivers[method_name] = components
        end
        table.insert(components, component)
    end
end

function Actor:ClearClientComponentMessageReceivers(component)
    local message_receiver = component:GetDecorator(decorator.decorator_type_message_receiver)
    local decorated_vars = message_receiver:GetDecoratedVars()
    for method_name, v in pairs(decorated_vars) do
        local components = self.__client_components_message_receivers__[method_name]
        if components then
            for k, v in ipairs(components) do
                if v == component then
                    table.remove(components, k)
                end
            end
        end
        if not components then
            self.__client_components_message_receivers__[method_name] = nil
        end
    end
end

function Actor:ClearServerComponentMessageReceivers(component)
    local message_receiver = component:GetDecorator(decorator.decorator_type_message_receiver)
    local decorated_vars = message_receiver:GetDecoratedVars()
    for method_name, v in pairs(decorated_vars) do
        local components = self.__server_components_message_receivers__[method_name]
        if components then
            for k, v in ipairs(components) do
                if v == component then
                    table.remove(components, k)
                end
            end
        end
        if not components then
            self.__server_components_message_receivers__[method_name] = nil
        end
    end
end

function Actor:AddServerComponentIRPCHandlers(component, component_name)
    local isserver = component:IsServerComponent()
    if not isserver then
        return
    end
    --local meta_table = getmetatable(self)
    local irpc_handler_decorator = component:GetDecorator(decorator.decorator_type_entity_service_handler)
    local decorated_vars = irpc_handler_decorator:GetDecoratedVars()

    local mt = getmetatable(self)
    if not mt.__server_entity_request_handler__ then
        mt.__server_entity_request_handler__ = {}
    end
    if not component_name then
        component_name = component:GetName()
    end

    for method_name, v in pairs(decorated_vars) do
        if self.__server_entity_request_handler__[method_name] then
            G.log:error("Actor IRPC Handler", "AddServerComponentIRPCHandlers Duplicated IRPC handler for method:%s", method_name)
        else
            if mt[method_name] then
                G.log:error("Actor IRPC Handler", "AddServerComponentIRPCHandlers IRPC method name:%s is existed in actor", method_name)
            else
                mt.__server_entity_request_handler__[method_name] = component_name
                local function EntityRequestHandler(self, ServerContext, Request)
                    local mt = getmetatable(self)
                    local component_name = mt.__server_entity_request_handler__[method_name]
                    local EntityServiceHandlerComponent = self.__server_components__[component_name]
                    if EntityServiceHandlerComponent:IsEnable() then
                        return EntityServiceHandlerComponent[method_name](EntityServiceHandlerComponent, ServerContext, Request)
                    else
                        -- 服务端没有调用相应的接口实现
                        -- IRPC_SERVER_NOFUNC_ERR = 11,
                        ServerContext:SetStatus(11, "dispatch failed")
                        return {}
                    end
                end
                mt[method_name] = EntityRequestHandler
            end
        end
    end
end

function Actor:ClearServerComponentIRPCHandlers(component)
    local isserver = component:IsServerComponent()
    if not isserver then
        return
    end

    local irpc_handler_decorator = component:GetDecorator(decorator.decorator_type_entity_service_handler)
    local decorated_vars = irpc_handler_decorator:GetDecoratedVars()
    for method_name, v in pairs(decorated_vars) do
        if self.__server_entity_request_handler__[method_name] == component then
            self.__server_entity_request_handler__[method_name] = nil
            rawset(self, method_name, nil)
        end
    end
end

function Actor:AddBlueprintComponent(component, start)
    local standalone = UE.UKismetSystemLibrary.IsStandalone(self)
    local server = UE.UKismetSystemLibrary.IsDedicatedServer(self)
    local client = not UE.UKismetSystemLibrary.IsServer(self)
    
    local component_name = component:GetName()

    if standalone or server then
        if self.__server_components__[component_name] ~= nil then
            assert(false)
        end

        self.__server_components__[component_name] = component

        component:SetIsServer(true)
    end

    if standalone or client then
        if self.__client_components__[component_name] ~= nil then
            assert(false)
        end

        self.__client_components__[component_name] = component
    end
    self:__AddComponent__(component, start)
    if self:IsServerAuthority() then
        self:AddServerComponentIRPCHandlers(component)
    end

end

function Actor:RemoveBlueprintComponent(component)
    local component_name = component:GetName()

    if self.__server_components__[component_name] then
        self.__server_components__[component_name] = nil
        self:ClearServerComponentMessageReceivers(component)

        if self:IsServerAuthority() then
            self:ClearServerComponentIRPCHandlers(component)
        end
    end

    if self.__client_components__[component_name] then
        self.__client_components__[component_name] = nil
        self:ClearClientComponentMessageReceivers(component)
    end

    component:__OnRemoved__(self)
end

function Actor:GetBlueprintComponents()
    local standalone = UE.UKismetSystemLibrary.IsStandalone(self)
    local server = UE.UKismetSystemLibrary.IsDedicatedServer(self)
    local client = not UE.UKismetSystemLibrary.IsServer(self)

    if standalone or server then
        return self.__server_components__
    end

    if standalone or client then
        return self.__client_components__
    end
end

function Actor:AddServerComponent(component_name, start)
    local module_name = self.__all_server_components_map__[component_name]
    if module_name then
        if self.__server_components__[component_name] ~= nil then
            assert(false)
        end

        local component = self:_AddComponentByModule(module_name, start, true)
        self.__server_components__[component_name] = component
    end
end

function Actor:RemoveServerComponent(component_name)
    local component = self.__server_components__[component_name]
    if component then
        component:__OnRemoved__(self)
        self.__server_components__[component_name] = nil
        self:ClearServerComponentMessageReceivers(component)

        if self:IsServerAuthority() then
            self:ClearServerComponentIRPCHandlers(component)
        end
    end
    
end

function Actor:AddClientComponent(component_name, start)
    local module_name = self.__all_client_components_map__[component_name]
    if module_name then

        if self.__client_components__[component_name] ~= nil then
            assert(false, component_name)
        end

        local component = self:_AddComponentByModule(module_name, start, false)
        self.__client_components__[component_name] = component
    end
end

function Actor:RemoveClientComponent(component_name)
    local component = self.__client_components__[component_name]
    if component then
        component:__OnRemoved__(self)
        self.__client_components__[component_name] = nil
        self:ClearClientComponentMessageReceivers(component)
    end
end

function Actor:AddScriptComponent(component_name, start)

    local standalone = UE.UKismetSystemLibrary.IsStandalone(self)
    local server = UE.UKismetSystemLibrary.IsDedicatedServer(self)
    local client = not UE.UKismetSystemLibrary.IsServer(self)

     --G.log:info("devin", "Actor:AddScriptComponent %s %s %s %s %s", tostring(self), component_name, tostring(standalone), tostring(server), tostring(client))

    if standalone or server then
        self:AddServerComponent(component_name, start)
    end

    if standalone or client then
        self:AddClientComponent(component_name, start)
    end
end

function Actor:RemoveScriptComponent(component_name, start)

    local standalone = UE.UKismetSystemLibrary.IsStandalone(self)
    local server = UE.UKismetSystemLibrary.IsDedicatedServer(self)
    local client = not UE.UKismetSystemLibrary.IsServer(self)

    if standalone or server then
        self:RemoveServerComponent(component_name)
    end

    if standalone or client then
        self:RemoveClientComponent(component_name)
    end
end

function Actor:_AddComponentByModule(module_name, start, server)

    local component_class = require(module_name)

    local component = component_class.new()

    component:SetIsServer(server)

    self:__AddComponent__(component, start)
    if self:IsServerAuthority() then
        self:AddServerComponentIRPCHandlers(component, module_name)
    end
    return component
end

function Actor:Destroy()
    for k, component in pairs(self.__client_components__) do
        component:Destroy()
    end
    self.__client_components__ = {}

    for k, component in pairs(self.__server_components__) do
        component:Destroy()
    end
    self.__server_components__ = {}
end

function Actor:_GetComponent(component_name, is_server)
    if is_server == nil then
        local standalone = UE.UKismetSystemLibrary.IsStandalone(self)
        local server = UE.UKismetSystemLibrary.IsDedicatedServer(self)
        local client = not UE.UKismetSystemLibrary.IsServer(self)
        if server then
            return self.__server_components__[component_name]
        elseif client then
            return self.__client_components__[component_name]
        else
            assert(false, "is_server == nil is invalid in standalone version")
        end
    elseif is_server == true then
        return self.__server_components__[component_name]
    elseif is_server == false then
        return self.__client_components__[component_name]
    end
end

function Actor:SetHookFunc(hook_func_type, hook_func)
    if self.__hook_func__[hook_func_type] ~= hook_func then
        local standalone = UE.UKismetSystemLibrary.IsStandalone(self)
        local server = UE.UKismetSystemLibrary.IsDedicatedServer(self)
        local client = not UE.UKismetSystemLibrary.IsServer(self)

        self.__hook_func__[hook_func_type] = hook_func
        if server or standalone then
            for k, component in pairs(self.__server_components__) do
                component:SetHookFunc(hook_func_type, hook_func)
            end
        end
        if client or standalone then
            for k, component in pairs(self.__client_components__) do
                component:SetHookFunc(hook_func_type, hook_func)
            end
        end 
    end
end

function Actor:GetHookFunc(hook_func_type)
    return self.__hook_func__[hook_func_type]
end

function Actor:SendMessage(method_name, ...)
   self:SendClientMessage(method_name, ...)
   self:SendServerMessage(method_name, ...)
end

function Actor:SendServerMessage(method_name, ...)
    assert(method_name ~= nil)

    local message_receivers = self.__server_components_message_receivers__[method_name]
    if not message_receivers then
        return
    end

    for index = #message_receivers, 1, -1 do
        local component = message_receivers[index]
        if component:IsEnable() then
            component[method_name](component, ...)
        end
    end
end

function Actor:SendClientMessage(method_name, ...)
    assert(method_name ~= nil)

    local message_receivers = self.__client_components_message_receivers__[method_name]
    if not message_receivers then
        return
    end

    for index = #message_receivers, 1, -1 do
        local component = message_receivers[index]
        if component:IsEnable() then
            component[method_name](component, ...)
        end
    end
end

function Actor:RefreshDataCache()
    self.__IsServer = nil
    self.__IsClient = nil
    self.__IsPlayer = nil
    self.__IsPlayerNotStandalone = nil
    self.__IsSimulated = nil
    self.__IsServerAuthority = nil
    self.__IsServerGhost = nil
end

function Actor:IsServer()
    if self.__IsServer == nil then
        self.__IsServer = UE.UKismetSystemLibrary.IsDedicatedServer(self)
    end
    return self.__IsServer
end

-- dds 模式下 server 端存在两种 role: ROLE_Authority 和 Role_ServerSimulatedProxy，要做区分.
function Actor:IsServerAuthority()
    if self.__IsServerAuthority == nil then
        self.__IsServerAuthority = self:IsServer() and self:GetLocalRole() == RoleType.ROLE_Authority
    end
    return self.__IsServerAuthority
end

-- dds 模式下 ghost role，只在 dds 模式下才允许调用该函数.
function Actor:IsServerGhost()
    if self.__IsServerGhost == nil then
        self.__IsServerGhost = self:IsServer() and self:GetLocalRole() == RoleType.Role_ServerSimulatedProxy
    end
    return self.__IsServerGhost
end

function Actor:IsClient()
    if self.__IsClient == nil then
        self.__IsClient = not UE.UKismetSystemLibrary.IsServer(self)
    end
    return self.__IsClient
end

function Actor:IsAvatar()
    -- 是否是角色
    if self.__IsAvatar == nil then
        self.__IsAvatar = SkillUtils.IsAvatar(self)
    end
    return self.__IsAvatar
end

function Actor:IsBakAvatar()
    -- 是否是后台角色
    if self.__IsBakAvatar == nil then
        self.__IsBakAvatar = SkillUtils.IsBakAvatar(self)
    end
    return self.__IsBakAvatar
end

function Actor:IsPlayer()
    -- 是否是客户端主控
    if self.__IsPlayer == nil then
        self.__IsPlayer = self:GetLocalRole() == RoleType.ROLE_AutonomousProxy
    end
    return self.__IsPlayer
end

function Actor:IsPlayerNotStandalone()
    if self.__IsPlayerNotStandalone == nil then
        local LocalRole = self:GetLocalRole() == RoleType.ROLE_AutonomousProxy
        local StandAlone = UE.UKismetSystemLibrary.IsStandalone(self)
        self.__IsPlayerNotStandalone = LocalRole and not StandAlone
    end
    return self.__IsPlayerNotStandalone
end

function Actor:IsSimulated()
    if self.__IsSimulated == nil then
        self.__IsSimulated = self:GetLocalRole() <= RoleType.ROLE_SimulatedProxy
    end
    return self.__IsSimulated
end

function Actor:HasCalcAuthority()
    if self.IsPlayerControlled and self:IsPlayerControlled() then
        return self:IsPlayer()
    else
        return self:IsServer()
    end
end

function Actor:GetName()
    return self:GetDisplayName()
end

function Actor:GetDisplayName()
    if self.__Name == nil then
        self.__Name = G.GetDisplayName(self)
    end
    return self.__Name
end

function Actor.__GenerateEngineCall__(cls, method_name)

    local prev_call = rawget(cls, method_name)
    if prev_call then
        rawset(cls, "__prev__" .. method_name .. "__", prev_call)
    end

    rawset(cls, method_name, function(obj, ...)
            obj.__EngineCall__(obj, method_name, ...)
                        end)
end

function Actor:__EngineCall__(method_name, ...)

    local actor_func = self["__prev__" .. method_name .. "__"]

    if actor_func ~= nil then
        actor_func(self, ...)
    end

    local engine_calls = self.__server_engine_callback__[method_name]

    if engine_calls then
        for component_name, _ in pairs(engine_calls) do
            local component = self.__server_components__[component_name]
            if component and component:IsEnable() then
                component[method_name](component, ...)
            end
        end
    end

    engine_calls = self.__client_engine_callback__[method_name]
    if engine_calls then
        for component_name, _ in pairs(engine_calls) do
            local component = self.__client_components__[component_name]
            if component and component:IsEnable() then
                component[method_name](component, ...)
            end
        end
    end
end

function Actor.__RemoveEngineCall__(cls, method_name)

    local engine_calls = self.__server_engine_callback__[method_name]

    if engine_calls then
        local actor_func = rawget(cls, "__prev__" .. method_name .. "__")

        rawset(cls, method_name, actor_func)

        cls.__server_engine_callback__[method_name] = nil
    end

    engine_calls = self.__client_engine_callback__[method_name]

    if engine_calls then
        local actor_func = rawget(cls, "__prev__" .. method_name .. "__")

        rawset(cls, method_name, actor_func)

        cls.__client_engine_callback__[method_name] = nil
    end
end

function Actor.registerComponent(cls, component_name, component_cls, engine_callback)
    local engine_callback_index = decorator.decorator_type_engine_callback
    local engine_callbacks = component_cls:GetDecorator(engine_callback_index)
    local decorated_vars = engine_callbacks:GetDecoratedVars()
    for method_name, v in pairs(decorated_vars) do
        local components = engine_callback[method_name]
        if components == nil then
            components = {}
            engine_callback[method_name] = components
            if not cls.__generated_engine_callback__[method_name] then
                Actor.__GenerateEngineCall__(cls, method_name)
                cls.__generated_engine_callback__[method_name] = true
            end
        end
        
        components[component_name] = true
    end
end

function Actor.registerComponents(cls, components_map, engine_callback)
    for component_name, module_name in pairs(components_map) do
        local component_cls = require(module_name)
        Actor.registerComponent(cls, component_name, component_cls, engine_callback)
    end
end

local function InheritComponents(cls, component_set_name)
    local __all_components_set__ = {}
    local parent = cls
    while parent ~= nil do
        local __all_components__ = parent[component_set_name]
        if __all_components__ then
            for component_name, module_name in pairs(__all_components__) do
                if __all_components_set__[component_name] == nil then
                    __all_components_set__[component_name] = module_name
                end
            end
        end
        parent = Super(parent)
    end
    return __all_components_set__
end

local function RegisterActor(cls)
    cls.__generated_engine_callback__ = {}
    cls.__server_engine_callback__ = {}
    cls.__all_server_components_map__ = InheritComponents(cls, "__all_server_components__")
    if cls.__all_server_components_map__ then
        Actor.registerComponents(cls, cls.__all_server_components_map__, cls.__server_engine_callback__)
    end
    cls.__client_engine_callback__ = {}
    cls.__all_client_components_map__ = InheritComponents(cls, "__all_client_components__")
    if cls.__all_client_components_map__ then
        Actor.registerComponents(cls, cls.__all_client_components_map__, cls.__client_engine_callback__)
    end
	return cls
end

function Actor:LogError(...)
    G.log:error_obj(self, ...)
end

function Actor:LogWarn(...)
    G.log:warn_obj(self, ...)
end

function Actor:LogInfo(...)
    G.log:info_obj(self, ...)
end

function Actor:LogDebug(...)
    G.log:debug_obj(self, ...)
end


_G.RegisterActor = RegisterActor

return Actor
