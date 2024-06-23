require "UnLua"

local G = require("G")
local GameEventBus = require("common.GameEventBus")

local Component = require("common.component")

local ComponentBase = Component()

function ComponentBase:Initialize(...)
    self.actor = nil
    self.enabled = false
    self.is_server = false

    self.hook_func = {}
end

function ComponentBase:ReceiveBeginPlay()

    self.Overridden.ReceiveBeginPlay(self)
    local actor = self:GetOwner()
    if actor and actor.AddBlueprintComponent then
        actor:AddBlueprintComponent(self, true)
        assert(self.actor)
    end
end

function ComponentBase:ReceiveEndPlay(EndPlayReason)
    self.actor = self:GetOwner()
    if self.actor and self.actor.RemoveBlueprintComponent then
        self.actor:RemoveBlueprintComponent(self)
    end
    GameEventBus.GetEventBusInstance(self):UnregisterByListenerObj(self)

end

function ComponentBase:__Start__()
    if not self.actor then
        return
    end

    if self.enabled then
        return
    end

    self.enabled = true

    self:Start()
end

function ComponentBase:Start()

end

function ComponentBase:__Stop__()
    if not self.enabled then
        return
    end

    self:Stop()

    self.enabled = false
end

function ComponentBase:Stop()
    
end

function ComponentBase:IsEnable()
    return self.enabled
end

function ComponentBase:DisEnable()
    self.enabled = false
end

function ComponentBase:Enable()
    self.enabled = true
end

function ComponentBase:Destroy()
    if self.enabled then
        self:__Stop__()
    end
    if self.actor then
        self:RemoveFromActor()
    end
end

function ComponentBase:RemoveFromActor()
    assert(self.actor)
    self.actor:RemoveScriptComponent(self)
end

function ComponentBase:__OnAdded__(actor)
    assert(actor)

    self.actor = actor
end

function ComponentBase:__OnRemoved__(actor)
    assert(actor == self.actor)

    self.actor = nil
end

function ComponentBase:GetDecorator(type)
    return self.decorator:GetDecorator(type)
end

function ComponentBase:SetHookFunc(hook_func_type, func)
    self.hook_func[hook_func_type] = func
end

function ComponentBase:OnHookFuncCall(hook_func_type, prev_func, ...)
    --G.log:info("lizhao", "ComponentBase:OnHookFuncCall")

    local hook_func = self.hook_func[hook_func_type]
    if hook_func == nil then
        local args = {...}
        table.remove(args, 1)
        table.remove(args, 1)
        return prev_func(self, table.unpack(args))
    else
        return hook_func(self, prev_func, ...)
    end
end

function ComponentBase:SetIsServer(isServer)
    --G.log:info("lizhao", "ComponentBase:OnHookFuncCall")

    self.is_server = isServer
end

-- 用于区分 Standalone 模式下 client 和 server
function ComponentBase:IsServerComponent()
    return self.is_server
end

function ComponentBase:IsClientComponent()
    return not self.is_server
end

--只在自己component广播域上SendMessage，server的component只能发消息给同样是server的component，client只能发消息给同样是client的component
function ComponentBase:SendMessage(method_name, ...)
    if self.enabled and self.actor then
        if self.is_server then
            self.actor:SendServerMessage(method_name, ...)
        else
            self.actor:SendClientMessage(method_name, ...)
        end
    end
end

function ComponentBase:SendServerMessage(method_name, ...)
    if self.enabled and self.actor then
        self.actor:SendServerMessage(method_name, ...)
    end
end

function ComponentBase:SendClientMessage(method_name, ...)
    if self.enabled and self.actor then
        self.actor:SendClientMessage(method_name, ...)
    end
end

function ComponentBase:RegisterGameplayTagCB(TagName, EventType, CbName)
    local Tag = UE.UHiGASLibrary.RequestGameplayTag(TagName)
    local AbilityAsync = UE.UAbilityAsync_WaitGameplayTagChanged.WaitGameplayTagChangedToActor(self.actor, Tag, EventType)
    AbilityAsync.OnChanged = {self, self[CbName]}
    AbilityAsync:Activate()

    -- self.AbilityAsync is a blueprint attribute
    self.actor.AbilityAsync:Add(AbilityAsync)

    return self.actor.AbilityAsync:Length()
end

function ComponentBase:LogError(...)
    G.log:error_obj(self, ...)
end

function ComponentBase:LogWarn(...)
    G.log:warn_obj(self, ...)
end

function ComponentBase:LogInfo(...)
    G.log:info_obj(self, ...)
end

function ComponentBase:LogDebug(...)
    G.log:debug_obj(self, ...)
end


return ComponentBase