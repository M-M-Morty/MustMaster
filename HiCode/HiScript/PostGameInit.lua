
local G = require("G")
local BPConst = require("common.const.blueprint_const")
local switches = require("switches")

_G.HiBlueprintFunctionLibrary = UE.UClass.Load("/Game/Blueprints/HiBlueprintFunctionLibrary.HiBlueprintFunctionLibrary_C")
_G.HiAudioFunctionLibrary = UE.UClass.Load('/Game/Blueprints/FunctionLibrary/BL_AudioLibrary.BL_AudioLibrary_C')


function LoadBPSubsystems()
    G.log:info("xaelpeng", "PostGameInit LoadBPSubsystems")
    BPConst.GetMutableActorSubsystemClass()
    BPConst.GetGameplayEntitySubsystemClass()
    BPConst.GetUILogicSubsystemClass()
    BPConst.GetOfficeSubsystemClass()
end

LoadBPSubsystems()

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
