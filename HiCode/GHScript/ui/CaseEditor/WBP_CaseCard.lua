--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
---@class WBP_CaseCard : WBP_CaseCard_C
---@field OwnerWidget UUserWidget
---@field ID integer

---@type WBP_CaseCard
local WBP_CaseCard = UnLua.Class()

-- function M:Construct()
-- end

---Called when this entry is assigned a new item object to represent by the owning list view
---@param ListItemObject BP_CaseEditorCaseItem_C
---@return void
function WBP_CaseCard:OnListItemObjectSet(ListItemObject)
    self.OwnerWidget = ListItemObject.OwnerWidget
    self.ID = ListItemObject.ID
    self.WBP_CaseCardOnWall:SetDataByObject(ListItemObject)
    self.WBP_CaseCardOnWall:SetOwnerWidget(self)
end

return WBP_CaseCard
