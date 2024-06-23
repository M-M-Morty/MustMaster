require "UnLua"

local G = require("G")

local utils = require("common.utils")

local decorator = require("common.decorator")

local function ComponentNewIndex(t, k, v)
    UObjectNewIndex(t, k, v)
end

local function Component(super_class, forbid_super_cache)
    local new_component = {}

    new_component.decorator = decorator.new()
    new_component.Super = super_class
    new_component.__index = UObjectIndex
	new_component.__newindex = ComponentNewIndex

    G.log:info("lizhao", "Component %s", tostring(super_class))

    if not forbid_super_cache and super_class ~= nil then
        for k, v in pairs(super_class) do
            if rawget(new_component, k) == nil then
                rawset(new_component, k, v)
            end
        end
    end

    if super_class ~= nil then
        new_component.decorator:Merge(super_class.decorator)
    end

    setmetatable(new_component, {__newindex = ComponentNewIndex, __index = super_class})

    new_component.new = function(...)
		local obj = {}
        obj.__index = UObjectIndex
        obj.__class__ = new_component
		setmetatable(obj, {__index = new_component})
		if new_component.Initialize then
			obj:Initialize(...)
		end
		return obj
	end

    return new_component

end

return Component
