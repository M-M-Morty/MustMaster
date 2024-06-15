--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local LevelTable = require("common.data.level_data").data

---@type BP_GameplayEntitySubsystem_C
local GameplayEntitySubsystem = UnLua.Class()
local G = require("G")

local DEFAULT_LEVEL_ID = 99999

function GameplayEntitySubsystem:GetDungeonIDFromLevel(WorldPath)
    local ResultLevelID = DEFAULT_LEVEL_ID
    for LevelID, LevelData in pairs(LevelTable) do
        if LevelData.resource_path == WorldPath then
            ResultLevelID = LevelID
            break
        end
    end
    G.log:debug("xaelpeng", "GameplayEntitySubsystem:GetDungeonIDFromLevel WorldPath:%s DungeonID:%s", WorldPath, ResultLevelID)
    return ResultLevelID
end

function GameplayEntitySubsystem:GetDungeonEnableSaveFromLevel()
    local DungeonID = self:K2_GetDungeonID()
    if LevelTable[DungeonID] == nil then
        return false
    end
    if LevelTable[DungeonID].map_type == 1 then
        return true
    end
    return false
end

return GameplayEntitySubsystem