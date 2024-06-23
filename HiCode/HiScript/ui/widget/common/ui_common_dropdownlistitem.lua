
local UIWidgetListItemBase = require('CP0032305_GH.Script.framework.ui.ui_widget_listitem_base')
local PicConst = require("CP0032305_GH.Script.common.pic_const")
local ui_common_dropdownlistitem = Class(UIWidgetListItemBase)

function ui_common_dropdownlistitem:OnListItemObjectSet(ListItemObject)
    self.itemData = ListItemObject.ItemValue
    self:InitWidget(self.itemData)
end

function ui_common_dropdownlistitem:InitWidget(item)
    self.Txt_Dropdown_Normal_1:SetText(item.itemText)
    self.Txt_Dropdown_Selected_1:SetText(item.itemText)
    if item.itemIcon then
        PicConst.SetImageBrush(self.Img_ItemIcon, item.itemIcon, true)
        PicConst.SetImageBrush(self.Img_ItemIcon_Selected, item.itemIcon, true)
    else
        self.Img_ItemIcon:SetVisibility(UE.ESlateVisibility.Hidden)
        self.Img_ItemIcon_Selected:SetVisibility(UE.ESlateVisibility.Hidden)
    end
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
        self.Switch_DropdownText_1:SetActiveWidgetIndex(1)
    else
        self.Canvas_DropDown_Selected:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Switch_DropdownText_1:SetActiveWidgetIndex(0)
    end
end

return ui_common_dropdownlistitem
