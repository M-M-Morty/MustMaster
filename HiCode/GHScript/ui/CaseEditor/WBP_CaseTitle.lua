--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
---@class WBP_CaseTitle : WBP_CaseTitle_C
---@field ID integer
---@field OwnerWidget WBP_CaseEditor

---@type WBP_CaseTitle_C
local WBP_CaseTitle = UnLua.Class()

-- function M:Construct()
-- end

---Called when this entry is assigned a new item object to represent by the owning list view
---@param ListItemObject BP_CaseEditorBoardItem_C
---@return void
function WBP_CaseTitle:OnListItemObjectSet(ListItemObject)
    self.ID = ListItemObject.ID
    self.OwnerWidget = ListItemObject.OwnerWidget
    ---@type WBP_CaseTitleOnWall
    local WBP_CaseTitleOnWall = self.WBP_CaseTitleOnWall
    WBP_CaseTitleOnWall:SetDataByObject(ListItemObject)
    WBP_CaseTitleOnWall:SetOwnerWidget(self)
end

return WBP_CaseTitle
