--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
-- 
local DataTableUtils = require("common.utils.data_table_utils")

local EMonoLogueType = {}
EMonoLogueType.Random = 1

local MonologueBasicTable = require("common.data.monologue_basic_data").data
local MonologueContentTable = require("common.data.monologue_content_data").data

local _M = {}

function _M.GenerateMonologueData(MonoLogueID)
    local MonologueData = MonologueBasicTable[MonoLogueID]
    local MonologueType = MonologueData.type
    if MonologueType == EMonoLogueType.Random then
        local Index = math.random(1, #MonologueData.contents)
        local ContentID = MonologueData.contents[Index]
        return _M.GenerateMonologueContents(ContentID), ContentID
    end
end

function _M.GenerateMonologueContents(ContentID)
    local Contents = {}
    local ContentDataList = MonologueContentTable[ContentID]
    for _, ContentData in ipairs(ContentDataList) do
        local Content = {
            TalkName = ContentData.character_name,
            Duration = ContentData.interval,
            TalkContent = ContentData.content,
            Audio = DataTableUtils.GetAudioPathByDataTableID(ContentData.audio_id)
        }
        table.insert(Contents, Content)
    end
    return Contents
end

_M.EMonoLogueType = EMonoLogueType
return _M
