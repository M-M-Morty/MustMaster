--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local UIWidgetListItemBase = require('CP0032305_GH.Script.framework.ui.ui_widget_listitem_base')

---@type WBP_Task_Desc_Item_C
local UITaskDescItem = Class(UIWidgetListItemBase)

--function UITaskDescItem:Initialize(Initializer)
--end

--function UITaskDescItem:PreConstruct(IsDesignTime)
--end

---@param ListItemObject UICommonItemObj_C
function UITaskDescItem:OnListItemObjectSet(ListItemObject)
    self.RichTextBlock_TaskDesc:SetText(ListItemObject.ItemValue)
end

--function UITaskDescItem:Tick(MyGeometry, InDeltaTime)
--end

return UITaskDescItem
