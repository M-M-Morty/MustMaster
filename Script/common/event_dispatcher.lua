local EventDispatcher = {}

function EventDispatcher:Initialize(...)
    self.listeners = {}
end

function EventDispatcher:AddListener(event_type, listener, callback_obj)
    local listener_info = self.listeners[event_type]
    if listener_info == nil then
        self.listeners[event_type] = {}
        listener_info = self.listeners[event_type]
    end

    local callbacks = listener_info[listener]

    if callbacks == nil then
        listener_info[listener] = {}
        callbacks = listener_info[listener]
    end

    table.insert(callbacks, callback_obj)
end

function EventDispatcher:RemoveListener(event_type, listener, callback_identity)
    local listener_info = self.listeners[event_type]
    if not listener_info then
        return
    end

    local callbacks = listener_info[listener]

    if not callbacks then
        return
    end

    for index, v in ipairs(callbacks) do
        if v.identity == callback_identity then
            table.remove(callbacks, index)
            break
        end
    end
    if #callbacks == 0 then
        listener_info[listener] = nil
    end
end

function EventDispatcher:Broadcast(event_type, ...)
    local listener_info = self.listeners[event_type]
    if not listener_info then
        return
    end

    local temp_listener_dict = {}
    for listener, callbacks in pairs(listener_info) do
        temp_listener_dict[listener] = callbacks
    end
    
    for listener, callbacks in pairs(temp_listener_dict) do
        for index, callback_obj in ipairs(callbacks) do
            callback_obj.callback(...)
        end
    end
end


EventDispatcher.new = function(...)
    local obj = {}
    setmetatable(obj, {__index = EventDispatcher})
    if EventDispatcher.Initialize then
        obj:Initialize(...)
    end
    return obj
end

-- local obj = {}

-- obj.foo = function()
--     print ("123")
-- end

-- local dispatcher = EventDispatcher.new()

-- dispatcher:AddListener(1, obj, obj.foo)

-- dispatcher:AddListener(1, obj, obj.foo)

-- dispatcher:RemoveListener(1, obj, obj.foo)

-- dispatcher:Broadcast(1)


return EventDispatcher