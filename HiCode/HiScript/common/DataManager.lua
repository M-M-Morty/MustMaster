local G = require("G")
local json = require("thirdparty.json")
local IoUtils = require("common.utils.io_utils")

local DataManager = {}

function DataManager:Init()
    self.MiniMapData = {}  -- MiniMap.json缓存
    self:LoadMiniMapData()
end

function DataManager:LoadMiniMapData()
    local EditorDataFolder = UE.UKismetSystemLibrary.GetProjectContentDirectory() .. "Data/EditorData/"
    
    -- 遍历EditorDataFolder下面的文件夹，加载MiniMap json文件
    for _, LevelName in ipairs(IoUtils:GetSubDirectories(EditorDataFolder)) do
        local MapDataFile = EditorDataFolder .. LevelName .. "/MiniMap/MiniMap.json"
        local FileString = UE.UHiEdRuntime.LoadFileToString(MapDataFile)
        if FileString:len() == 0 then
            G.log:warn("[LoadMiniMapData]", "No MapData found, MapDataFile=%s", MapDataFile)
        else
            local MapData = json.decode(FileString)
            self.MiniMapData[LevelName] = MapData
        end
    end
end

function DataManager:GetMiniMapData(LevelName)
    return self.MiniMapData[LevelName]
end

return DataManager