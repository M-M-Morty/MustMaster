
local G = require("G")
local BPConst = require("common.const.blueprint_const")
local switches = require("switches")

_G.HiBlueprintFunctionLibrary = UE.UClass.Load("/Game/Blueprints/HiBlueprintFunctionLibrary.HiBlueprintFunctionLibrary_C")
_G.HiAudioFunctionLibrary = UE.UClass.Load('/Game/Blueprints/FunctionLibrary/BL_AudioLibrary.BL_AudioLibrary_C')


function LoadBPSubsystems()
    G.log:info("xaelpeng", "LoadBPSubsystems")
    BPConst.GetMutableActorSubsystemClass()
    BPConst.GetGameplayEntitySubsystemClass()
    BPConst.GetUILogicSubsystemClass()
    BPConst.GetOfficeSubsystemClass()
end

LoadBPSubsystems()

-- 兼容lua5.1.1
function compat_lua5_1()
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

    -- unpack && pack
    table.unpack = unpack
    table.pack = function( ... )
        local ret = {...}
        ret.n = #ret
        return ret
    end

    -- coroutine
    coroutine.isyieldable = function ()
        return coroutine.running() ~= nil
    end
end

-- bit lib
function compat_bit_lib()
    _G.bit = {}
    _G.bit.bnot = UE.UHiUtilsUnLuaLibrary.bnot
    _G.bit.band = UE.UHiUtilsUnLuaLibrary.band
    _G.bit.bor = UE.UHiUtilsUnLuaLibrary.bor
    _G.bit.lshift = UE.UHiUtilsUnLuaLibrary.lshift
    _G.bit.rshift = UE.UHiUtilsUnLuaLibrary.rshift
end

function PostGameInitForLua()
    if UE.UHiUtilsUnLuaLibrary.GetLuaVersion() == 501 then
        compat_lua5_1()
    end

    compat_bit_lib()

    local configs = require("configs")
    if UE.UHiUtilsFunctionLibrary.WithEditor() then
        collectgarbage("setpause", configs.LuaGCPauseInPIE)
    end

    if jit and switches.LuaJitLog then
        local v = require("jit.v")
        local JitLogPath = string.format("%s/%s", UE.UUnLuaFunctionLibrary.GetScriptRootPath(), "jit.log")
        v.start(JitLogPath)
    end
end

PostGameInitForLua()

return {}
