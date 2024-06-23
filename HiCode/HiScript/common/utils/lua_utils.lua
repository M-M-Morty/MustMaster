local LuaUtils = {}

function LuaUtils.DeepCopy(Orig)
    local OrigType = type(Orig)
    local Copy
    if OrigType == "table" then
        Copy = {}
        for OrigKey, OrigValue in pairs(Orig) do
            Copy[LuaUtils.DeepCopy(OrigKey)] = LuaUtils.DeepCopy(OrigValue)
        end
        -- setmetatable(Copy, LuaUtils.DeepCopy(getmetatable(Orig)))
    else -- number, string, boolean, etc
        Copy = Orig
    end
    return Copy
end

return LuaUtils