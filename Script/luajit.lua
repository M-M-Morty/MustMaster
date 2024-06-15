
local switches = require("switches")

if jit and switches.UseLuaJitInter then
    jit.off()
    jit.flush()
end

if jit and switches.UseLuaJitFFI then
    _G.ffi = require("ffi")
    _G.FFI = ffi.load(string.format("%s/../../%s", UE.UUnLuaFunctionLibrary.GetScriptRootPath(), "/Binaries/Win64/UnrealEditor-HiGame.dll"))
    ffi.cdef[[
        bool FFI_GetStaticBool();
        double FFI_GetStaticNumber();
        const char* FFI_GetStaticString();

        typedef ptrdiff_t lua_Integer;
        const char* FFI_GetObjName(lua_Integer Obj_Addr);
        const char* FFI_GetDisplayName(lua_Integer Obj_Addr);
        int64_t FFI_GetFrameCount();
        int64_t FFI_GetNowTimestampMs();
        int64_t FFI_GetGameplayAbilityFromSpecHandle(lua_Integer AbilitySystem_Addr, lua_Integer SpecHandle_Addr);
        int64_t FFI_GetHiAbilitySystemComponent(lua_Integer Obj_Addr);
        int64_t FFI_GetPlayerCharacter(lua_Integer Context_Addr, int32_t PlayerIndex);
    ]]

else
	switches.UseLuaJitFFI = false
end


---------------------------------- ffi api define ----------------------------------

function _GetObjectName(Obj)
	if not Obj then
		return nil
	end
	
    if switches.UseLuaJitFFI then
        return ffi.string(FFI.FFI_GetObjName(UnLua.GetCAddr(Obj)))
    else
        return UE.UKismetSystemLibrary.GetObjectName(Obj)
    end
end

function _GetDisplayName(Obj)
    if not Obj then
        return nil
    end

    if switches.UseLuaJitFFI then
        return ffi.string(FFI.FFI_GetDisplayName(UnLua.GetCAddr(Obj)))
    else
        return UE.UKismetSystemLibrary.GetDisplayName(Obj)
    end
end

function _GetFrameCount()
    if switches.UseLuaJitFFI then
        return tonumber(FFI.FFI_GetFrameCount())
    else
        return UE.UKismetSystemLibrary.GetFrameCount()
    end
end

function _GetNowTimestampMs()
    if switches.UseLuaJitFFI then
        return tonumber(FFI.FFI_GetNowTimestampMs())
    else
        return UE.UHiUtilsFunctionLibrary.GetNowTimestampMs()
    end
end

function _GetGameplayAbilityFromSpecHandle(ASC, SpecHandle)
    if switches.UseLuaJitFFI then
        local ASCCAddr = UnLua.GetCAddr(ASC)
        local SpecHandleCAddr = UnLua.GetCAddr(SpecHandle)
        local GACAddr = tonumber(FFI.FFI_GetGameplayAbilityFromSpecHandle(ASCCAddr, SpecHandleCAddr))
        local GA = UnLua.GetLuaObj(GACAddr)
        local bInstanced = FFI.FFI_GetStaticBool()
        return GA, bInstanced
    else
        return UE.UAbilitySystemBlueprintLibrary.GetGameplayAbilityFromSpecHandle(ASC, SpecHandle)
    end
end

function _GetHiAbilitySystemComponent(Character)
    if switches.UseLuaJitFFI then
        local ASCCAddr = tonumber(FFI.FFI_GetHiAbilitySystemComponent(UnLua.GetCAddr(Character)))
        assert(ASCCAddr ~= 0, string.format("Character.%s error", G.GetDisplayName(Character)))
        return UnLua.GetLuaObj(ASCCAddr)
    else
        return Character:GetHiAbilitySystemComponent()
    end
end

function _GetPlayerCharacter(WorldContext, PlayerIndex)
    if switches.UseLuaJitFFI then
        local PlayerCAddr = tonumber(FFI.FFI_GetPlayerCharacter(UnLua.GetCAddr(WorldContext), PlayerIndex))
        assert(PlayerCAddr ~= 0, string.format("WorldContext.%s error", G.GetDisplayName(WorldContext)))
        return UnLua.GetLuaObj(PlayerCAddr)
    else
        return UE.UGameplayStatics.GetPlayerCharacter(WorldContext, PlayerIndex)
    end
end


local G = require("G")
G.GetObjectName = _GetObjectName
G.GetDisplayName = _GetDisplayName
G.GetFrameCount = _GetFrameCount
G.GetNowTimestampMs = _GetNowTimestampMs
G.GetGameplayAbilityFromSpecHandle = _GetGameplayAbilityFromSpecHandle
G.GetHiAbilitySystemComponent = _GetHiAbilitySystemComponent
G.GetPlayerCharacter = _GetPlayerCharacter

_G.G = G

return {}
