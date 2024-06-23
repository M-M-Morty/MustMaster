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
local MissionConst = require('Script.mission.mission_const')
local ConstTextData = require('Data.common.data.const_text_data')
local IconUtility = require('CP0032305_GH.Script.common.utils.icon_util')

---@type WBP_ScreenCreditList_Item_C
local M = Class(UIWidgetListItemBase)

local function BuildWidgetProxy(self)
    ---@type UTileViewProxy
    self.List_NameProxy = WidgetProxys:CreateWidgetProxy(self.List_Name)
end

--function M:Initialize(Initializer)
--end

--function M:PreConstruct(IsDesignTime)
--end

function M:OnConstruct()
    BuildWidgetProxy(self)
end

--function M:Tick(MyGeometry, InDeltaTime)
--end

---@param ListItemObject UICommonItemObj_C
function M:OnListItemObjectSet(ListItemObject)
    if ListItemObject.ItemValue.isEnd then
        ListItemObject.ItemValue.Content[#ListItemObject.ItemValue.Content].isEnd = true
    end
    self.Txt_Title:SetText(ListItemObject.ItemValue.GroupName)
    self.List_NameProxy:SetListItems(ListItemObject.ItemValue.Content)
end

return M
