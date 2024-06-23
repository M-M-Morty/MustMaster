--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local ConstText = require("CP0032305_GH.Script.common.text_const")

---@class WBP_Task_NPCComment : WBP_Task_NPCComment_C

---@type WBP_Task_NPCComment
local WBP_Task_NPCComment = UnLua.Class()

local FORMAT_STRING = "%s: %s"

---Called when this entry is assigned a new item object to represent by the owning list view
---@param ListItemObject BP_NpcComment_C
---@return void
function WBP_Task_NPCComment:OnListItemObjectSet(ListItemObject)
    self.WBP_Firm_Visitor_Item:SetIconByPicKey(ListItemObject.NpcIconKey)
    local Comment = string.format(FORMAT_STRING, ListItemObject.NpcName, ConstText.GetConstText(ListItemObject.CommentKey))
    self.Txt_Comment:SetText(Comment)
end

return WBP_Task_NPCComment
