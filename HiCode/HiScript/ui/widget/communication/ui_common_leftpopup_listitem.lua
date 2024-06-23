
local ItemUtil = require("common.item.ItemUtil")
local PicConst = require("CP0032305_GH.Script.common.pic_const")
local G = require("G")
local UIWidgetListItemBase = require('CP0032305_GH.Script.framework.ui.ui_widget_listitem_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ConstTextTable = require("common.data.const_text_data").data

local ui_common_leftpropup_listitem = Class(UIWidgetListItemBase)

function ui_common_leftpropup_listitem:OnListItemObjectSet(ListItemObject)
    local PropItem = ListItemObject.ItemValue
    self:SetItem(PropItem)
    self.itemData.ownedWidget.WBP_Common_LeftPopupWindow:AddListItem(self)
end

function ui_common_leftpropup_listitem:SetItem(itemData)
    if not itemData then
        return
    end
    local itemName
    self.bSelected = false
    self.itemData = itemData
    local PropItem = {}
    local ItemConfig = ItemUtil.GetItemConfigByExcelID(self.itemData.itemId)
    PropItem.Number = self.itemData.ownedCount
    PropItem.Quality = ItemConfig.quality
    PropItem.ID = self.itemData.itemId
    if self.itemData.itemName then
        local textName = ConstTextTable[self.itemData.itemName]
        if textName.Content then
            itemName = textName.Content
        end
    end
    if self.itemData.ownedCount ~= 0 then
        self.Switch_PropListItem:SetActiveWidgetIndex(0)
        self.WBP_PropItem:SetItemData(PropItem, true)
        self.Txt_PropName:SetText(itemName)
        self.WBP_PropItem.ButtonProp.OnClicked:Add(self, self.ShowItemDetails)
    else
        self.Switch_PropListItem:SetActiveWidgetIndex(1)
        self.WBP_PropItem_Translucent:SetItemData(PropItem, true)
        self.Txt_PropName_Translucent:SetText(itemName)
        self.WBP_PropItem_Translucent.ButtonProp.OnClicked:Add(self, self.ShowItemDetails)
    end

    self:SetSelected(self.itemData.isSelected)
    self.WBP_Btn_PropListItem.OnClicked:Add(self, self.SelectItem)

    self.WBP_Btn_PropListItem.OnHovered:Add(self, self.HoverBtn)
    self.WBP_Btn_PropListItem.OnUnhovered:Add(self, self.UnHoverBtn)
end

function ui_common_leftpropup_listitem:HoverBtn()
    if not self.bSelected then
        self.Switch_PropList:SetActiveWidgetIndex(0)
        self.Canvas_PropListItem_Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
end

function ui_common_leftpropup_listitem:UnHoverBtn()
    self.Switch_PropList:SetActiveWidgetIndex(1)
    if not self.bSelected then
        self.Img_PropListItem_Selected:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end

function ui_common_leftpropup_listitem:SetSelected(bSelected)
    self.bSelected = bSelected
    if bSelected then
        self.Switch_PropList:SetActiveWidgetIndex(1)
        self.Img_PropListItem_Selected:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.Switch_PropList:SetActiveWidgetIndex(0)
        self.Img_PropListItem_Selected:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end

function ui_common_leftpropup_listitem:SelectItem()
    self.itemData.ownedWidget:SelectOwnedItem(self.itemData.itemId)
end

function ui_common_leftpropup_listitem:ShowItemDetails()
    local WBPCommonPropTips = UIManager:OpenUI(UIDef.UIInfo.UI_Common_PropTips_Main)
    WBPCommonPropTips:InitByItemExcelID(self.itemData)
end

return ui_common_leftpropup_listitem
