--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')


---@class WBP_Firm_MapHeadline_Item : WBP_Firm_MapHeadline_Item_C

---@type WBP_Firm_MapHeadline_Item_C
---@field OwnerWidget WBP_Firm_MapHeadline
local WBP_Firm_MapHeadline_Item = Class(UIWindowBase)
--function M:Initialize(Initializer)
--end

--function M:PreConstruct(IsDesignTime)
--end
---@param self WBP_Firm_MapHeadline_Item
local function OnClickedSelectItem(self)
    if self.OwnerWidget.OnClickedSelectItem then
        self.OwnerWidget:OnClickedSelectItem(self)
    end
end

function WBP_Firm_MapHeadline_Item:Construct()
    self.Img_Selected:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.WBP_Btn_DropDown.Button.OnClicked:Add(self, OnClickedSelectItem)
end

function WBP_Firm_MapHeadline_Item:Destruct()
    self.WBP_Btn_DropDown.Button.OnClicked:Remove(self, OnClickedSelectItem)
end
--function M:Tick(MyGeometry, InDeltaTime)
--end

function WBP_Firm_MapHeadline_Item:OnListItemObjectSet(ListItemObject)
    self.OwnerWidget = ListItemObject.OwnerWidget
end

return WBP_Firm_MapHeadline_Item
