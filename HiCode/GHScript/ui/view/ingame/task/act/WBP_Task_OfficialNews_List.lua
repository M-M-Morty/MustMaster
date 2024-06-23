--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local PicConst = require("CP0032305_GH.Script.common.pic_const")
local ConstText = require("CP0032305_GH.Script.common.text_const")

---@class WBP_Task_OfficialNews_List : WBP_Task_OfficialNews_List_C

---@type WBP_Task_OfficialNews_List
local WBP_Task_OfficialNews_List = UnLua.Class()

---Called when this entry is assigned a new item object to represent by the owning list view
---@param ListItemObject BP_TaskOfficialNew_C
---@return void
function WBP_Task_OfficialNews_List:OnListItemObjectSet(ListItemObject)
    PicConst.SetImageBrush(self.Icon_NewsIcon, ListItemObject.IconKey)
    self.Txt_NewsTitle:SetText(ConstText.GetConstText(ListItemObject.TitleKey))
    self.Txt_NewsComment:SetText(ConstText.GetConstText(ListItemObject.ContentKey))
    ListItemObject.OwnerWidget:SetOfficialWidgets(ListItemObject.Index, self)
    self:PlayAnimation(self.DX_MsgIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end

return WBP_Task_OfficialNews_List
