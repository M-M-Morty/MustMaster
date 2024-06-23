--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@class WBP_Task_ChapterOnWall : WBP_Task_ChapterOnWall_C
---@field IsChapterOnWall boolean

---@type WBP_Task_ChapterOnWall
local WBP_Task_ChapterOnWall = UnLua.Class()

function WBP_Task_ChapterOnWall:Construct()
    self.IsChapterOnWall = true
end

return WBP_Task_ChapterOnWall
