---------------------------------------------------------------------
--- @copyright Copyright (c) 2022 Tencent Inc. All rights reserved.
--- @author shiboshen
--- @brief 脚本初始化(Unlua框架初始化完成后会require此文件)
---------------------------------------------------------------------


require("luajit")

local switches = require("switches")

if switches.CloseLuaGC then
    collectgarbage("stop")
end

local rawget = rawget
local rawset = rawset
local type = type
local getmetatable = getmetatable
local require = require

local GetUProperty = UnLua.GetUProperty
local SetUProperty = UnLua.SetUProperty

local NotExist = {}

UnLua.PackagePath = "/Content/?.lua;"..UnLua.PackagePath
UnLua.PackagePath = "/Content/Data/?.lua;"..UnLua.PackagePath
UnLua.PackagePath = "/Content/Data/?.luac;"..UnLua.PackagePath

local GameAPI = require("common.game_api")
local decorator = require("common.decorator")

local function Index(t, k)
    local mt = getmetatable(t)

    local p = mt[k]
    if p ~= nil then
        if type(p) == "userdata" then
            return GetUProperty(t, p)
        elseif type(p) == "function" then
            rawset(t, k, p)
        elseif rawequal(p, NotExist) then
            return nil
        end
    else
        rawset(mt, k, NotExist)
    end

    return p
end

local function NewIndex(t, k, v)
    v = t.decorator:Execute(t, k, v)

    local mt = getmetatable(t)
    local p = mt[k]
    if type(p) == "userdata" then
        return SetUProperty(t, p, v)
    end

    rawset(t, k, v)
end

local class_unique_id = 0
local function gen_class_unique_id()
    class_unique_id = class_unique_id + 1
    return class_unique_id
end

local function Class(super_class, forbid_super_cache)
    local new_class = {}
    new_class.__index = Index
    new_class.__newindex = NewIndex
    new_class.Super = super_class
    new_class.is_class = true
    new_class.unique_id = gen_class_unique_id()
    new_class.decorator = decorator.new()

    setmetatable(new_class, {__index = super_class, __newindex = NewIndex})

    if not forbid_super_cache and super_class ~= nil then
        for k, v in pairs(super_class) do
            if rawget(new_class, k) == nil then
                rawset(new_class, k, v)
            end
        end
    end

    if super_class ~= nil then
        new_class.decorator:Merge(super_class.decorator)
    end

    new_class.new = function(...)
        local obj = {}
        obj.__index = Index
        obj.__class__ = new_class
        setmetatable(obj, {__index = new_class})
        if new_class.ctor then
            obj:ctor(...)
        end
        return obj
    end

    return new_class
end

local function Super(cls)
    return cls.Super
end

local function SuperCache(cls)
    local super_class = rawget(cls, "Super")
    while super_class do
        for k, v in pairs(super_class) do
            if rawget(cls, k) == nil then
                rawset(cls, k, v)
            end
        end

        super_class = rawget(super_class, "Super")
    end

    return cls
end

local function RawFindEnum(t, k)
    local path = UE.UHiUtilsFunctionLibrary.GetEnumPathFromName(k)
    if not path or path == "" then
        -- TODO Hardcode enum full package path here.
        path = 	"/Game/Blueprints/Common/"..k.."."..k
    end
    if path then
        local ret = UE.UObject.Load(path)
        if ret then
            return ret
        end
    end
end

local function FindEnum(t, k)
    local G = require("G")
    if G.GameInstance then
        return G.GameInstance:FindEnum(t, k, RawFindEnum)
    else
        return RawFindEnum(t, k)
    end
end
local EnumTable = setmetatable({}, {__index = FindEnum})

local function RawFindStruct(t, k)
    local path = UE.UHiUtilsFunctionLibrary.GetStructPathFromName(k)
    if path then
        local ret = UE.UObject.Load(path)
        if ret then
            return ret
        end
    end

end

local function FindStruct(t, k)
    local G = require("G")
    if G.GameInstance then
        return G.GameInstance:FindStruct(t, k, RawFindStruct)
    else
        return RawFindStruct(t, k)
    end
end
local StructTable = setmetatable({}, {__index = FindStruct})

function GetTagName(Tag)
    return UE.UBlueprintGameplayTagLibrary.GetTagName(Tag)
end

_G.Enum = EnumTable
_G.Struct = StructTable
_G.Class = Class
_G.Super = Super
_G.SuperCache = SuperCache
_G.UObjectNewIndex = NewIndex
_G.UObjectIndex = Index
_G.GetTagName = GetTagName
UnLua.Class = Class

-- For IDE only.
local function Dummy()
    UE = {}
end

local G = require("G")

-- 兼容lua5.1
function compat_lua5_1()
    if table.unpack ~= nil then
        -- lua5.4 return
        return
    end

    -- unpack && pack
    table.unpack = unpack
    table.pack = function( ... )
        local ret = {...}
        ret.n = #ret
        return ret
    end

    -- string.format
    string.origin_format = string.format
    string.format = function (format, ...)
        if select("#", ...) > 0 then
            str_args = {}
            for i = 1, select("#", ...) do
                local t = select(i, ...)
                table.insert(str_args, tostring(t))
            end
            return string.origin_format(format, table.unpack(str_args))
        else
            return string.origin_format(format)
        end
    end

    -- coroutine
    coroutine.isyieldable = function ()
        return coroutine.running() ~= nil
    end
end

function InitGlobal()
    G.log = require("debug.logger").Logger.new()
    G.log:info("shibo", "InitGlobal here")

    -- 启动lua debug
    -- require("debug.LuaPanda").start("127.0.0.1", 8818);

    compat_lua5_1()
end

InitGlobal()


return {}
 