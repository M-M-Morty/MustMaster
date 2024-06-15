
local UIWidgetListItemBase = require('CP0032305_GH.Script.framework.ui.ui_widget_listitem_base')


local ui_common_dropdownlistitem = Class(UIWidgetListItemBase)

function ui_common_dropdownlistitem:OnListItemObjectSet(ListItemObject)
    self.itemData = ListItemObject.ItemValue
    self:InitWidget(self.itemData)
end

function ui_common_dropdownlistitem:InitWidget(item)
   self.Txt_DropDown:SetText(item.itemText)
   self:SetSelectedState(item.bSelected)
   if item.bSelected then
        self.itemData.ownerWidget:SelectedItem(self)
   end
end

function ui_common_dropdownlistitem:OnConstruct()
    self.WBP_Btn_DropDown.OnClicked:Add(self, self.ClickSelectItemBtn)
end

function ui_common_dropdownlistitem:ClickSelectItemBtn()
    self:SetSelectedState(true)
    self:SelectItem()
end

function ui_common_dropdownlistitem:SelectItem()
    self.itemData.ownerWidget:OnClickedSelectItem(self)
end

function ui_common_dropdownlistitem:SetSelectedState(bSelected)
    self.bSelected = bSelected
    if bSelected then
        self.Canvas_DropDown_Selected:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.Canvas_DropDown_Selected:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

return ui_common_dropdownlistitem
