--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"
local MissionGroupDataTable = require ("common.data.mission_group_data")
local MissionActDataTable = require ("common.data.mission_act_data")
local MissionDataTable = require("common.data.mission_data")


---@type NewFunctionLibrary_C
local DataLibrary = UnLua.Class()

function DataLibrary:GetMissionGroupTableData(ID)
    local DataStruct = LoadObject('/Game/Blueprints/Mission/MissionTableData/BPS_MissionGroupTableData.BPS_MissionGroupTableData')
    local Data = DataStruct()
    local TableData = MissionGroupDataTable.data[ID]
    if (TableData ~= nil) then
        Data.ID = ID
        Data.Name = TableData.Name
        Data.Descript = TableData.Descript
    else
        Data.ID = 0
    end
    return Data
end

function DataLibrary:GetMissionActTableData(ID)
    local DataStruct = LoadObject(
        '/Game/Blueprints/Mission/MissionTableData/BPS_MissionActTableData.BPS_MissionActTableData')
    local Data = DataStruct()
    local TableData = MissionActDataTable.data[ID]
    if (TableData ~= nil) then
        Data.ID = ID
        Data.Name = TableData.Name
        Data.Descript = TableData.Descript
    else
        Data.ID = 0
    end
    return Data
end

function DataLibrary:GetMissionTableData(ID)
    local DataStruct = LoadObject(
        '/Game/Blueprints/Mission/MissionTableData/BPS_MissionTableData.BPS_MissionTableData')
    local Data = DataStruct()
    local TableData = MissionDataTable.data[ID]
    if (TableData ~= nil) then
        Data.ID = ID
        Data.Name = TableData.Name
        Data.Descript = TableData.Descript
    else
        Data.ID = 0
    end
    return Data
end



return DataLibrary