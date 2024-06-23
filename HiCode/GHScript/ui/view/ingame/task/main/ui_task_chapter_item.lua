--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local UIWidgetListItemBase = require('CP0032305_GH.Script.framework.ui.ui_widget_listitem_base')
local MissionConst = require('Script.mission.mission_const')
local ConstTextData = require('common.data.const_text_data')
local IconUtility = require('CP0032305_GH.Script.common.utils.icon_util')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')

---@class WBP_Task_Chapter_Item_C
local UITaskChapterItem = Class(UIWidgetListItemBase)

--function UITaskChapterItem:Initialize(Initializer)
--end

--function UITaskChapterItem:PreConstruct(IsDesignTime)
--end

function UITaskChapterItem:OnConstruct()
    self:InitWidget()
    self:BuildWidgetProxy()
end

---@param ListItemObject UICommonItemObj_C
function UITaskChapterItem:OnListItemObjectSet(ListItemObject)
    ---@type ViewmodelField
    local VMField = ListItemObject.ItemValue

    ---@type ChapterTreeNode
    self.ChapterTreeNode = VMField:GetFieldValue()
    self:SetChapterHide()
    self.Text_Title:SetText(self.ChapterTreeNode.TaskChapterName)
    self.Text_Chapter:SetText(self.ChapterTreeNode.TaskChapterActIndex)
    -- IconUtility:SetTaskIcon(self.WBP_HUD_Task_Icon, self.ChapterTreeNode.TaskChapterType, MissionConst.EMissionTrackIconType.None)
    ViewModelBinder:BindViewModel(self.ListView_TaskTitleProxy.ListField, self.ChapterTreeNode.TaskListField,
        ViewModelBinder.BindWayToWidget)
end

function UITaskChapterItem:AddHideChapterId(Type, ActID)
    ---@type TaskMainVM
    local TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
    TaskMainVM:SetChapterNodeHide(Type, ActID)
end

function UITaskChapterItem:UnHideChapterId(ActID)
    ---@type TaskMainVM
    local TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
    TaskMainVM:SetChapterNodeShow(ActID)
end

function UITaskChapterItem:AddHideMissionId(ActID, MissionID)
    ---@type TaskMainVM
    local TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
    TaskMainVM:SetMissionNodeHide(ActID, MissionID)
end

function UITaskChapterItem:UnHideMissionId(MissionID)
    ---@type TaskMainVM
    local TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
    TaskMainVM:SetMissionNodeHide(MissionID)
end

function UITaskChapterItem:GetMissionHideListNum(ActID)
    ---@type TaskMainVM
    local TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
    local MissionList = TaskMainVM:GetMissionHideListByActID(ActID)
    if MissionList then
        return #MissionList
    end
end

function UITaskChapterItem:GetTaskList(ActID)
    ---@type TaskMainVM
    local TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
    local MissionList = TaskMainVM:GetChapterList(ActID)
    if MissionList then
        return MissionList
    end
end

function UITaskChapterItem:OnMissionIsHide(GetAllTask)
    for _, missionObj in pairs(GetAllTask) do
        if missionObj:IsHide() then
            self:AddHideMissionId(missionObj:GetMissionID())
        else
            self:UnHideMissionId(missionObj:GetMissionID())
        end
    end
end

function UITaskChapterItem:SetChapterHide()
    local ChapterTaskNum = self.ChapterTreeNode.TaskListField:GetItemNum()
    local GetAllTask = self:GetTaskList(self.ChapterTreeNode.TaskChapterID)
    self:OnMissionIsHide(GetAllTask)
    local HideMissionNum = self:GetMissionHideListNum(self.ChapterTreeNode.TaskChapterActIndex)
    if not HideMissionNum or not ChapterTaskNum then
        return
    end
    if ChapterTaskNum <= HideMissionNum then
        self:SetVisibility(UE.ESlateVisibility.Collapsed)
        self:AddHideChapterId(self.ChapterTreeNode.ListType, self.ChapterTreeNode.TaskChapterActIndex)
    else
        self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self:UnHideChapterId(self.ChapterTreeNode.TaskChapterActIndex)
    end
end

function UITaskChapterItem:InitWidget()
    self.ComBtn_TaskType.OnClicked:Add(self, self.ComBtn_TaskType_OnClicked)
    self.ComBtn_TaskType.OnHovered:Add(self, self.ComBtn_TaskType_OnHovered)
    self.ComBtn_TaskType.OnUnhovered:Add(self, self.ComBtn_TaskType_OnUnhovered)

    self.Image_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function UITaskChapterItem:BuildWidgetProxy()
    ---@type UListViewProxy
    self.ListView_TaskTitleProxy = WidgetProxys:CreateWidgetProxy(self.ListView_TaskTitle)

    ---@type UButtonProxy
    self.ComBtn_TaskTypeProxy = WidgetProxys:CreateWidgetProxy(self.ComBtn_TaskType)
    -- self.ComBtn_TaskTypeProxy:EnableButtonInteractVision()
end

function UITaskChapterItem:ComBtn_TaskType_OnClicked()
    if self.ListView_TaskTitle:GetVisibility() ~= UE.ESlateVisibility.Collapsed then
        self.ListView_TaskTitle:SetVisibility(UE.ESlateVisibility.Collapsed)
        self:PlayAnimation(self.DX_fold, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
        self.Image_Drop:SetRenderTransformAngle(-90)
    else
        self.ListView_TaskTitle:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Image_Drop:SetRenderTransformAngle(0)
        self:PlayAnimation(self.DX_Unfold, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    end
end

function UITaskChapterItem:ComBtn_TaskType_OnHovered()
    self.Image_Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function UITaskChapterItem:ComBtn_TaskType_OnUnhovered()
    self.Image_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
end

return UITaskChapterItem
