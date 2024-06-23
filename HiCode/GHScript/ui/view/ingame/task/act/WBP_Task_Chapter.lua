--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
---@class WBP_Task_Chapter : WBP_Task_Chapter_C
---@field ID integer

local MissionActUtils = require("CP0032305_GH.Script.mission.mission_act_utils")
local G = require("G")

---@type WBP_Task_Chapter
local WBP_Task_Chapter = UnLua.Class()

function WBP_Task_Chapter:SetID(ID)
    self.ID = ID
    local MissionBoardConfig = MissionActUtils.GetMissionBoardConfig(ID)
    if MissionBoardConfig == nil then
        G.log:warn("WBP_Task_Chapter", "MissionBoardConfig nil! ID: %d", ID)
    else
        self.Txt_ChapterDigit:SetText(MissionBoardConfig.Name)
        self.Txt_ChapterContent:SetText(MissionBoardConfig.Content)
    end
end

return WBP_Task_Chapter
