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

local function Class(super_class)
    local new_class = {}
    new_class.__index = Index
    new_class.__newindex = NewIndex
    new_class.Super = super_class
    new_class.is_class = true
    new_class.unique_id = gen_class_unique_id()
    new_class.decorator = decorator.new()

    setmetatable(new_class, {__index = super_class, __newindex = NewIndex})

    if super_class ~= nil then
        for k, v in pairs(super_class) do
            if rawget(new_class, k) == nil then
                rawset(new_class, k, v)
            end
        end

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
_G.UObjectNewIndex = NewIndex
_G.UObjectIndex = Index
_G.GetTagName = GetTagName
UnLua.Class = Class

-- For IDE only.
local function Dummy()
    UE = {}
end

local G = require("G")

function InitGlobal()
    G.log = require("debug.logger").Logger.new()
    G.log:info("shibo", "InitGlobal here")

    -- 启动lua debug
    -- require("debug.LuaPanda").start("127.0.0.1", 8818);
end

InitGlobal()


return {}
 