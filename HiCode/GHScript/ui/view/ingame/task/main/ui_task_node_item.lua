--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local UIWidgetListItemBase = require('CP0032305_GH.Script.framework.ui.ui_widget_listitem_base')

---@type WBP_Task_Node_Item_C
local UITaskNodeItem = Class(UIWidgetListItemBase)

function UITaskNodeItem:OnConstruct()
    self:BuildWidgetProxy()
end

function UITaskNodeItem:BuildWidgetProxy()
    ---@type UListViewProxy
    self.ListView_TaskNodeDescProxy = WidgetProxys:CreateWidgetProxy(self.ListView_TaskNodeDesc)
end

---@param ListItemObject UICommonItemObj_C
function UITaskNodeItem:OnListItemObjectSet(ListItemObject)
    ---@type MissionObject
    self.MissionObject = ListItemObject.ItemValue

    self.Text_Info:SetText(self.MissionObject:GetMissionEventDesc())
    self.ListView_TaskNodeDescProxy:SetListItems({ self.MissionObject:GetMissionEventDetailDesc() })
end

return UITaskNodeItem
