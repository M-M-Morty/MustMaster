

local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local UIWidgetListItemBase = require('CP0032305_GH.Script.framework.ui.ui_widget_listitem_base')

---@type WBP_GMPanel_TaskTest_C
local M = Class(UIWidgetListItemBase)

--function M:Initialize(Initializer)
--end

--function M:PreConstruct(IsDesignTime)
--end

function M:OnConstruct()
    
    self.ButtonClose.OnClicked:Add(self, self.ButtonClose_OnClicked)

    ---@type UListViewProxy
    self.ListView_NpcProxy = WidgetProxys:CreateWidgetProxy(self.ListView_Npc)

    ---@type UListViewProxy
    self.ListView_TaskProxy = WidgetProxys:CreateWidgetProxy(self.ListView_Task)
end

--function M:Tick(MyGeometry, InDeltaTime)
--end

---@param NpcTestData ViewmodelField
---@param TaskTestData ViewmodelField
function M:BindViewModelField(NpcTestData, TaskTestData)
    ViewModelBinder:BindViewModel(self.ListView_NpcProxy.ListField, NpcTestData, ViewModelBinder.BindWayToWidget)
    ViewModelBinder:BindViewModel(self.ListView_TaskProxy.ListField, TaskTestData, ViewModelBinder.BindWayToWidget)
end

function M:ButtonClose_OnClicked()
    self:RemoveFromParent()
end

return M
