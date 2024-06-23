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
local ConstTextData = require('common.data.const_text_data')
local IconUtility = require('CP0032305_GH.Script.common.utils.icon_util')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')

---@class WBP_Task_Type_Item_C
local UITaskTypeItem = Class(UIWidgetListItemBase)

--function M:Initialize(Initializer)
--end

--function M:PreConstruct(IsDesignTime)
--end

-- function M:Construct()
-- end

--function M:Tick(MyGeometry, InDeltaTime)
--end

function UITaskTypeItem:OnConstruct()
    self:BuildWidgetProxy()
end

---@param ListItemObject UICommonItemObj_C
function UITaskTypeItem:OnListItemObjectSet(ListItemObject)
    ---@type ViewmodelField
    local VMField = ListItemObject.ItemValue

    ---@type MissionTypeNodeClass
    self.TypeTreeNode = VMField:GetFieldValue()
    self:InitViewModel()
    self:SetItemData()
    self:SetTypeHide()
end

function UITaskTypeItem:InitViewModel()
    if self.TypeTreeNode.ChapterListField:GetItemNum() == 0 then
        self.CurrentField = self.TypeTreeNode.MissionListField
        self.FieldType = self.TypeTreeNode.OwnerVM.MissionListType.Mission
        ViewModelBinder:BindViewModel(self.List_MissionListProxy.ListField, self.TypeTreeNode.MissionListField,
            ViewModelBinder.BindWayToWidget)
        ViewModelBinder:BindViewModel(self.MissionListField, self.TypeTreeNode.MissionListField,
            ViewModelBinder.BindWayToWidget)
    else
        self.CurrentField = self.TypeTreeNode.ChapterListField
        self.FieldType = self.TypeTreeNode.OwnerVM.MissionListType.Act
        ViewModelBinder:BindViewModel(self.List_ActListProxy.ListField, self.TypeTreeNode.ChapterListField,
            ViewModelBinder.BindWayToWidget)
        ViewModelBinder:BindViewModel(self.ActListField, self.TypeTreeNode.ChapterListField,
            ViewModelBinder.BindWayToWidget)
    end
end

function UITaskTypeItem:BuildWidgetProxy()
    ---@type UListViewProxy
    self.List_MissionListProxy = WidgetProxys:CreateWidgetProxy(self.List_MissionList)
    ---@type UListViewProxy
    self.List_ActListProxy = WidgetProxys:CreateWidgetProxy(self.List_ActList)

    ---@type UIWidgetField
    self.MissionListField = self:CreateUserWidgetField(self.SetItemShow)
    ---@type UIWidgetField
    self.ActListField = self:CreateUserWidgetField(self.SetItemShow)
end

function UITaskTypeItem:GetChapterHideListNum(Type)
    ---@type TaskMainVM
    local TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
    local ChapterList = TaskMainVM:GetChapterHideListByType(Type)
    if ChapterList then
        return #ChapterList
    end
end

function UITaskTypeItem:UnHideChapterId(ActID)
    ---@type TaskMainVM
    local TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
    TaskMainVM:SetChapterNodeShow(ActID)
end

function UITaskTypeItem:AddHideChapterId(Type, ActID)
    ---@type TaskMainVM
    local TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
    TaskMainVM:SetChapterNodeHide(Type, ActID)
end

function UITaskTypeItem:OnMissionIsHide(GetAllTask)
    for _, missionObj in pairs(GetAllTask) do
        if missionObj:IsHide() then
            self:AddHideChapterId(missionObj:GetMissionType(), missionObj:GetMissionID())
        else
            self:UnHideChapterId(missionObj:GetMissionID())
        end
    end
end

function UITaskTypeItem:GetTaskList(type)
    ---@type TaskMainVM
    local TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
    local MissionList = TaskMainVM:GetTypeList(type)
    if MissionList then
        return MissionList
    end
end

function UITaskTypeItem:SetTypeHide()
    local TaskNum = self.CurrentField:GetItemNum()
    local HideListNum = self:GetChapterHideListNum(self.TypeTreeNode.ListType)
    if self.TypeTreeNode.ChapterListField:GetItemNum() == 0 then
        local GetAllTask = self:GetTaskList(self.TypeTreeNode.ListType)
        self:OnMissionIsHide(GetAllTask)
    end
    if not HideListNum or not TaskNum then
        return
    end
    if TaskNum <= HideListNum then
        self:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
end

function UITaskTypeItem:SetItemShow()
    if self.CurrentField:GetItemNum() == 0 then
        self.Canvas_TaskType:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function UITaskTypeItem:SetItemData()
    self.Canvas_TaskType:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Text_TaskType:SetText(self:GetTaskTypeTitle(self.TypeTreeNode.ListType))
    -- IconUtility: (self.WBP_HUD_Task_Icon, self.ChapterTreeNode.TaskChapterType, MissionConst.EMissionTrackIconType.None)
    self.Switch_List:SetActiveWidgetIndex(self.FieldType - 1)
end

---@param taskType number
function UITaskTypeItem:GetTaskTypeTitle(taskType)
    local TaskTypeText
    if taskType == MissionConst.EMissionType.Main then
        TaskTypeText = ConstTextData.data.MISSION_TYPE_MAIN.Content
    elseif taskType == MissionConst.EMissionType.Activity then
        TaskTypeText = ConstTextData.data.MISSION_TYPE_ACTIVITY.Content
    elseif taskType == MissionConst.EMissionType.Daily then
        TaskTypeText = ConstTextData.data.MISSION_TYPE_DAILY.Content
    elseif taskType == MissionConst.EMissionType.Guide then
        TaskTypeText = ConstTextData.data.MISSION_TYPE_GUIDE.Content
    end
    if not TaskTypeText then
        return
    end
    return TaskTypeText
end

return UITaskTypeItem
