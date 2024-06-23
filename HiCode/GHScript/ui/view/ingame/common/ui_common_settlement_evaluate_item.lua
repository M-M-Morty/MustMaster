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

---@class WBP_Common_MiniGames_SettlementPopUp_Evaluate_Item_C
local UICommonSettlementEvaluateItem = Class(UIWidgetListItemBase)

function UICommonSettlementEvaluateItem:OnConstruct()
end

---@param ListItemObject UICommonItemObj_C
function UICommonSettlementEvaluateItem:OnListItemObjectSet(ListItemObject)
    ---@type MusicEvaluate
    self.MusicEvaluate = ListItemObject.ItemValue
    self:SetItemData()
end

function UICommonSettlementEvaluateItem:SetItemData()
    self.Txt_Evaluate:SetText(self.MusicEvaluate.desc)
    self.Txt_EvaluateNum:SetText(self.MusicEvaluate.value)
end

return UICommonSettlementEvaluateItem
