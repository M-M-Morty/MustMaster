local G = require("G")

local decorator = {}

decorator.decorator_type_engine_callback = 1
decorator.decorator_type_require_check_action = 2
decorator.decorator_type_message_receiver = 3
decorator.decorator_type_lua_console_cmd = 4
decorator.decorator_type_dds_function = 5
decorator.decorator_type_entity_service_handler = 6

decorator.hook_func_type_require_check_action = 1


local function DecoratorNewIndex(t, k, v)
    rawset(t, k, v)
end

local function DecoratorClass(super_class)
	local new_class = {}
	new_class.__newindex = DecoratorNewIndex
	new_class.Super = super_class
	setmetatable(new_class, {__index = super_class, __newindex = DecoratorNewIndex})

	new_class.new = function(...)
		local obj = {}
		obj.__class__ = new_class
		setmetatable(obj, {__index = new_class, __call = new_class.OnCall})
		if new_class.Initialize then
			obj:Initialize(...)
		end
		return obj
	end

	return new_class
end


local sub_decorator = {}

function sub_decorator:Initialize(parent, type)
    self.parent = parent
    self.type = type

    self.decorated_vars = {}
end

function sub_decorator:OnCall(...)
    self.args = {...}
    self.parent:OnCall(self)
end

function merge_table(dst, src)
    for k, v in pairs(src) do
        if dst[k] == nil then
            dst[k] = v
        elseif type(v) == "table" and type(dst[k]) == "table" then
            merge_table(dst[k], v)
        end
    end
end

function sub_decorator:Merge(other_decorator)
    merge_table(self.decorated_vars, other_decorator.decorated_vars)
end

function sub_decorator:GetDecoratedVar(method_name)
    return self.decorated_vars[method_name];
end

function sub_decorator:GetDecoratedVars()
    return self.decorated_vars;
end


local engine_callback_decorator = DecoratorClass(sub_decorator)

function engine_callback_decorator:Initialize(parent)
    Super(engine_callback_decorator).Initialize(self, parent, decorator.decorator_type_engine_callback)
end

function engine_callback_decorator:Hook(t, method_name, func, decorated_func)
    self.decorated_vars[method_name] = func
    return decorated_func
end


local require_check_action_decorator = DecoratorClass(sub_decorator)

function require_check_action_decorator:Initialize(parent)
    Super(require_check_action_decorator).Initialize(self, parent, decorator.decorator_type_require_check_action)
end

function require_check_action_decorator:Hook(t, method_name, func, decorated_func)
    local action_name = self.args[1]
    local cost_cd_check_func
    if #self.args > 1 then
        cost_cd_check_func = self.args[2]
    end
    self.decorated_vars[method_name] = action_name
    self.args = nil

    --G.log:info("lizhao", "require_check_action_decorator:Hook %s", method_name)
    local hooked_func = function(component, ...)
        -- G.log:info("lizhao", "hooked_func %s %s %s", method_name, decorated_func, action_name)
        component:OnHookFuncCall(decorator.hook_func_type_require_check_action, decorated_func, action_name, cost_cd_check_func, ...)
    end
    return hooked_func
end

local message_receiver_decorator = DecoratorClass(sub_decorator)

function message_receiver_decorator:Initialize(parent)
    --G.log:info("lizhao", "message_receiver_decorator %s", tostring(parent))
    Super(message_receiver_decorator).Initialize(self, parent, decorator.decorator_type_message_receiver)
end

function message_receiver_decorator:Hook(t, method_name, func, decorated_func)
    --G.log:info("lizhao", "message_receiver_decorator:Hook component: %s decorator: %s method: %s", t, tostring(self), method_name)
    self.decorated_vars[method_name] = func
    return decorated_func
end


local lua_console_cmd_decorator = DecoratorClass(sub_decorator)

function lua_console_cmd_decorator:Initialize(parent)
    Super(lua_console_cmd_decorator).Initialize(self, parent, decorator.decorator_type_lua_console_cmd)
end

function lua_console_cmd_decorator:Hook(t, method_name, func, decorated_func)
    local side = self.args[1]
    if side == nil then
        G.log:error("yj", "lua cmd.%s should define server or client traceback.%s", method_name, debug.traceback())
    end
    self.decorated_vars[method_name] = {side}
    return decorated_func
end

local dds_function_decorator = DecoratorClass(sub_decorator)

function dds_function_decorator:Initialize(parent)
    Super(dds_function_decorator).Initialize(self, parent, decorator.decorator_type_dds_function)
end

function dds_function_decorator:Hook(t, method_name, func, decorated_func)
    --G.log:info("dds", "dds_function_decorator:Hook func: %s decorator: %s method: %s ",  tostring(self), method_name)
    UE.DistributedDSLua.RegisterFunction(method_name, func)
    self.decorated_vars[method_name] = func
    return decorated_func
end

local entity_service_handler_decorator = DecoratorClass(sub_decorator)

function entity_service_handler_decorator:Initialize(parent)
    Super(entity_service_handler_decorator).Initialize(self, parent, decorator.decorator_type_entity_service_handler)
end

function entity_service_handler_decorator:Hook(t, method_name, func, decorated_func)
    G.log:info("irpc_handler_decorator", "irpc_handler_decorator:Hook func decorator: %s method: %s ",  tostring(self), method_name)

    self.decorated_vars[method_name] = func
    return decorated_func
end

function decorator:Initialize()
    self.callstacks = {}

    self.sub_decorators = {}

    self:CreateSubDecorators()
end

function decorator:GetDecorator(type)
    return self.sub_decorators[type]
end

function decorator:CreateSubDecorators()
    self.engine_callback = engine_callback_decorator.new(self)
    self.sub_decorators[self.engine_callback.type] = self.engine_callback

    self.require_check_action = require_check_action_decorator.new(self)
    self.sub_decorators[self.require_check_action.type] = self.require_check_action

    self.message_receiver = message_receiver_decorator.new(self)
    self.sub_decorators[self.message_receiver.type] = self.message_receiver

    self.lua_console_cmd = lua_console_cmd_decorator.new(self)
    self.sub_decorators[self.lua_console_cmd.type] = self.lua_console_cmd
    
    self.dds_function = dds_function_decorator.new(self)
    self.sub_decorators[self.dds_function.type] = self.dds_function

    self.entity_service_handler = entity_service_handler_decorator.new(self)
    self.sub_decorators[self.entity_service_handler.type] = self.entity_service_handler
end

function decorator:Execute(t, k, v)
    local decorated_func = v
    local callstacks = self.callstacks
    if 'function' == type(v) then
        for i = #callstacks, 1, -1 do
            local sub_decorator = callstacks[i]
            decorated_func = sub_decorator:Hook(t, k, v, decorated_func)
        end
    end
    self.callstacks = {}
    return decorated_func
end

function decorator:OnCall(sub_decorator)
    table.insert(self.callstacks, sub_decorator)
end

function decorator:Merge(other_decorator)
    for k, v in pairs(other_decorator.sub_decorators) do
        if self.sub_decorators[k] == nil then
            self.sub_decorators[k] = v
        else
            self.sub_decorators[k]:Merge(v)
        end
    end
end

decorator.new = function(...)
    local obj = {}
    obj.__class__ = decorator
    setmetatable(obj, {__index = decorator})
    if decorator.Initialize then
        obj:Initialize(...)
    end
    return obj
end

return decorator

