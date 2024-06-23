--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
---@class WBP_Task_Thumbtack : WBP_Task_Thumbtack_C
---@field bThumbtack boolean

---@type WBP_Task_Thumbtack
local WBP_Task_Thumbtack = UnLua.Class()

function WBP_Task_Thumbtack:Construct()
    self.bIsThumbtack = true
end

return WBP_Task_Thumbtack
