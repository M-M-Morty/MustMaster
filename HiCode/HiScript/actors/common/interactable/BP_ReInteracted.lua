--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"
local ActorBase = require("actors.common.interactable.base.interacted_item")
local MonoBasicData = require("common.data.monologue_basic_data").data
local MonoContentData = require("common.data.monologue_content_data").data

---@type BP_ReInteracted_C
local M = Class(ActorBase)

function M:GetTotalTime(MonologueID, ContentID)
    local MonologueData = MonoBasicData[MonologueID]
    local ContentDataList = MonoContentData[ContentID]
    local TotalTime = 0
    if MonologueData ~= nil and ContentDataList ~= nil then 
        for i = 1,#ContentDataList do
            TotalTime = TotalTime + ContentDataList[i].interval
        end
        return TotalTime
    else
        return 0
    end
end


return M
