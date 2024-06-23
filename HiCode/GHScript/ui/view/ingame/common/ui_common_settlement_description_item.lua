--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require('G')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local UIWidgetListItemBase = require('CP0032305_GH.Script.framework.ui.ui_widget_listitem_base')

---@class WBP_Common_MiniGames_SettlementPopUp_Description_Item_C
local UICommonSettlementDescriptionItem = Class(UIWidgetListItemBase)

-- function UICommonSettlementDescriptionItem:OnConstruct()
-- end

---@param ListItemObject UICommonItemObj_C
function UICommonSettlementDescriptionItem:OnListItemObjectSet(ListItemObject)
    ---@type MusicDescription
    self.MusicDescription = ListItemObject.ItemValue
    self:SetItemData()
end

function UICommonSettlementDescriptionItem:SetItemData()
    self.Txt_Evaluate:SetText(self.MusicDescription.desc)
    self.Txt_EvaluateNum:SetText(self.MusicDescription.value)
end

return UICommonSettlementDescriptionItem
