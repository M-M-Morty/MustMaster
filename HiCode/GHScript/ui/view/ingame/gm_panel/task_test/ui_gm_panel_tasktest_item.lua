
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UIWidgetListItemBase = require('CP0032305_GH.Script.framework.ui.ui_widget_listitem_base')

---@type WBP_GMPanel_TaskTestItem_C
local M = Class(UIWidgetListItemBase)

--function M:Initialize(Initializer)
--end

--function M:PreConstruct(IsDesignTime)
--end

function M:OnConstruct()
    self.TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
    if self.TaskMainVM then
        self.AcceptTask.OnClicked:Add(self, self.AcceptTask_OnClicked)
        self.AbandonTask.OnClicked:Add(self, self.AbandonTask_OnClicked)
    end
end

---@param ListItemObject UICommonItemObj_C
function M:OnListItemObjectSet(ListItemObject)
    ---@type ViewmodelField
    local VMField = ListItemObject.ItemValue

    self.ItemValue = VMField:GetFieldValue()
    self.TaskTitle:SetText(self.ItemValue.MissionName)
end

--function M:Tick(MyGeometry, InDeltaTime)
--end

function M:AcceptTask_OnClicked()
    if self.TaskMainVM then
        self.TaskMainVM:AcceptTask(self.ItemValue.MissionID)
        local MissionObj = self.TaskMainVM:GetUIMissionNode(self.ItemValue.MissionID).MissionObject
        self.TaskMainVM:BindMission(MissionObj, true)
    end
end

function M:AbandonTask_OnClicked()
    if self.TaskMainVM then
        self.TaskMainVM:AbandonTask(self.ItemValue.MissionID)
    end
end

return M
