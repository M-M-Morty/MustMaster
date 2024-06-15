require "UnLua"
local G = require("G")

local IoUtils = {}

function IoUtils:GetSubDirectories(Directory)
    if not UE.UHiEdRuntime.FindFiles then
        return {}
    end
    local Directories = UE.UHiEdRuntime.FindFiles(Directory .. "*", false, true)
    local DirectoryNames = {}
    for i = 1, Directories:Num() do
        table.insert(DirectoryNames, Directories[i])
    end

    return DirectoryNames
end

return IoUtils
