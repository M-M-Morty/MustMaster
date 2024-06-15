--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")
local PicConst = require("CP0032305_GH.Script.common.pic_const")
local G = require("G")
local UIWidgetListItemBase = require('CP0032305_GH.Script.framework.ui.ui_widget_listitem_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')

---@type WBP_Common_PropSlot_C
local ui_common_propslot = Class(UIWidgetListItemBase)

function ui_common_propslot:OnListItemObjectSet(ListItemObject)
    local PropItem = ListItemObject.ItemValue
    self:SetItem(PropItem)
    self.itemData.ownedWidget:AddPropItem(self)
end

function ui_common_propslot:SetItem(itemData)
    self.itemData = itemData
    self.itemId = self.itemData.itemId
    self.ownedCount = self.itemData.ownedCount
    self.submitCount = self.itemData.needCount
    self.submitType = itemData.submitType
    self.bEnough = self.ownedCount >= self.submitCount
    self.Txt_PropNumber_Total:SetText(self.submitCount)

    self:RefreshIcon()
    self:RefreshOwnedNumState()
    self:SetDeleteBtnVisible()

    self.WBP_Btn_PropDelete.OnClicked:Add(self, self.DeleteSubmitItem)
    self.WBP_Btn_DeliveryField.OnClicked:Add(self, self.ClickItem)

    if self.itemId ~= 0 then
        self:PlayAnimation(self.DX_BtnDeleteIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    end
end

function ui_common_propslot:RefreshOwnedNumState()
    if self.bEnough then
        self.Switch_PropNumber:SetActiveWidgetIndex(1)
        self.Txt_PropNumber_Full:SetText(self.ownedCount)
        self.Switch_DeliveryField:SetRenderOpacity(1.0)
    else
        self.Switch_PropNumber:SetActiveWidgetIndex(0)
        self.Txt_PropNumber_NotFull:SetText(self.ownedCount)
        self.Switch_DeliveryField:SetRenderOpacity(0.5)
    end
end

function ui_common_propslot:SetDeleteBtnVisible()
    if self.submitType ~= Enum.ESubmitType.SpecificItem and self.itemId ~= 0 then
        self.WBP_Btn_PropDelete:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.WBP_Btn_PropDelete:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end

function ui_common_propslot:RefreshIcon()
    if self.itemId ~= 0 then
        self.Switch_DeliveryField:SetActiveWidgetIndex(1)
        local ItemConfig = ItemUtil.GetItemConfigByExcelID(self.itemId)
        if ItemConfig == nil then
            G.log:warn("ui_common_propslot", "cant find ItemConfig by %s", self.itemId)
        else
            PicConst.SetImageBrush(self.Img_Prop, ItemConfig.icon_reference)
            Quality = ItemConfig.quality
            local QualityConfig = ItemUtil.GetItemQualityConfig(Quality)
            PicConst.SetImageBrush(self.Img_PropQualityBox, QualityConfig.icon_reference_small)
        end
        self.WBP_Btn_DeliveryField.OnClicked:Add(self, self.ClickItem)
    else
        self.Switch_DeliveryField:SetActiveWidgetIndex(0)
    end
end

function ui_common_propslot:ShowDeleteBtn()
end

function ui_common_propslot:HideDeleteBtn()
end

function ui_common_propslot:ClickItem()
    if self.itemId ~= 0 then
        local WBPCommonPropTips = UIManager:OpenUI(UIDef.UIInfo.UI_Common_PropTips_Main)
        WBPCommonPropTips:InitByItemExcelID(self.itemId)
    end
end

function ui_common_propslot:DeleteSubmitItem()
    self.itemData.ownedWidget:DeleteSubmitItem(self.itemData.index)
    if self.itemId ~= 0 then
        self:PlayAnimation(self.DX_BtnDeleteOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    end
end

return ui_common_propslot
