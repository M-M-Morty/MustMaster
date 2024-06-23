--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UIWidgetListItemBase = require('CP0032305_GH.Script.framework.ui.ui_widget_listitem_base')

---@class WBP_Task_TaskTitle_Item_C
local UITaskTitleItem = Class(UIWidgetListItemBase)

--function UITaskTitleItem:Initialize(Initializer)
--end

--function UITaskTitleItem:PreConstruct(IsDesignTime)
--end

function UITaskTitleItem:OnConstruct()
    self:InitWidget()
    self:BuildWidgetProxy()
end

---@param ListItemObject UICommonItemObj_C
function UITaskTitleItem:OnListItemObjectSet(ListItemObject)
    ---@type ViewmodelField
    local VMField = ListItemObject.ItemValue

    ---@type UIMissionNode
    self.UIMissionNode = VMField:GetFieldValue()
    self:GetMissionData()
    self:SetItemData()
    self:InitViewModel()
end

function UITaskTitleItem:InitWidget()
    ---@type TaskMainVM
    self.TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
    ---@type HudTrackingMission
    self.HudTrackingMission = self.TaskMainVM.HudTrackingMission
    -- self.ComBtn_Title.OnClicked:Add(self, self.Button_OnClicked)
    self.WBP_Btn_IndependentMission_01.OnPressed:Add(self, self.Button_OnPressed)
    self.WBP_Btn_IndependentMission_01.OnHovered:Add(self, self.ComBtn_Title_OnHovered)
    self.WBP_Btn_IndependentMission_01.OnUnhovered:Add(self, self.ComBtn_Title_OnUnhovered)
    -- self.ComBtn_Title_1.OnClicked:Add(self, self.Button_OnClicked)
    self.WBP_Btn_IndependentMission_02.OnPressed:Add(self, self.Button_OnPressed)
    self.WBP_Btn_IndependentMission_02.OnHovered:Add(self, self.ComBtn_Title_OnHovered)
    self.WBP_Btn_IndependentMission_02.OnUnhovered:Add(self, self.ComBtn_Title_OnUnhovered)
end

function UITaskTitleItem:BuildWidgetProxy()
    ---@type UIWidgetField
    self.TrackedField = self:CreateUserWidgetField(self.SetTaskTrackState)

    ---@type UIWidgetField
    self.SelectedTaskField = self:CreateUserWidgetField(self.SetTaskSelected)

    ---@type UIWidgetField
    self.TaskNotifyField = self:CreateUserWidgetField(self.TaskDataNotify)
end

function UITaskTitleItem:InitViewModel()
    ViewModelBinder:BindViewModel(self.TrackedField, self.UIMissionNode.OwnerVM.CurrentTrackingTaskField,
        ViewModelBinder.BindWayToWidget)
    ViewModelBinder:BindViewModel(self.SelectedTaskField, self.UIMissionNode.OwnerVM.CurrentSelectTaskField,
        ViewModelBinder.BindWayToWidget)
    ViewModelBinder:BindViewModel(self.TaskNotifyField, self.UIMissionNode.MissionNotifyField,
        ViewModelBinder.BindWayToWidget)
end

function UITaskTitleItem:SetTaskTrackState(TrackingTaskNodeID)
    if self.UIMissionNode then
        local WidgetIndex = TrackingTaskNodeID == self.MissionId and 1 or 0
        self:OnItemShow(WidgetIndex)
    end
end

function UITaskTitleItem:GetMissionData()
    self.IsHide = self.UIMissionNode.MissionObject:IsHide()
    self.MissionName = self.UIMissionNode.MissionObject:GetMissionName()
    self.bCanTrack = self.UIMissionNode.MissionObject:IsTrackable()
    self.MissionId = self.UIMissionNode.MissionObject:GetMissionID()
    self.IsBlock = self.UIMissionNode.MissionObject:IsBlock()
    self.ItemParent = self.UIMissionNode.Parent
    self.IndexName = self:GetIndexName(self.ItemParent)
end

function UITaskTitleItem:SetItemData()
    if self.ItemParent == self.UIMissionNode.OwnerVM.MissionParent.Act then
        self.Canvas_Act_01:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Canvas_Mission_02:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.Canvas_Act_01:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Canvas_Mission_02:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
    if self.IsHide then
        self.TaskTitleCanvas:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.TaskTitleCanvas:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end

    self:SetTitleName()
end

function UITaskTitleItem:GetIndexName(index)
    local IndexName = "_01"
    if index ~= nil and index > 0 then
        IndexName = "_0" .. tostring(index)
    end
    return IndexName
end

function UITaskTitleItem:SetTitleName()
    self["Txt_NormalMissionName" .. self.IndexName]:SetText(self.MissionName)
    self["Txt_TrackMissionName" .. self.IndexName]:SetText(self.MissionName)
    self["Txt_NoTrackMissionName" .. self.IndexName]:SetText(self.MissionName)
end

function UITaskTitleItem:SetDistanceData()
    local DistanceText = self.HudTrackingMission:GetTrackingMissionDistanceText(self.UIMissionNode.MissionObject, self["Img_MissionDirection_Normal" .. self.IndexName])
    DistanceText = self.HudTrackingMission:GetTrackingMissionDistanceText(self.UIMissionNode.MissionObject, self["Img_MissionDirection_Track" .. self.IndexName])

    if DistanceText then
        self["HorizontalBox_Normal" .. self.IndexName]:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self["HorizontalBox_Track" .. self.IndexName]:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self["Txt_NormalMissionDistance" .. self.IndexName]:SetText(DistanceText)
        self["Txt_TrackMissionDistance" .. self.IndexName]:SetText(DistanceText)
        self["Txt_NoTrackMissionDistance" .. self.IndexName]:SetText(DistanceText)
    else
        self["HorizontalBox_Normal" .. self.IndexName]:SetVisibility(UE.ESlateVisibility.Collapsed)
        self["HorizontalBox_Track" .. self.IndexName]:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function UITaskTitleItem:OnItemShow(WidgetIndex)
    if self.bCanTrack then
        self["Switch_IndependentMission" .. self.IndexName]:SetActiveWidgetIndex(WidgetIndex)
    else
        self["Switch_IndependentMission" .. self.IndexName]:SetActiveWidgetIndex(2)
    end
end

function UITaskTitleItem:SetTaskSelected(CurrentSelectMissionID)
    self.CurrentSelectMissionID = CurrentSelectMissionID
    if self.UIMissionNode then
        if self.UIMissionNode.MissionObject:GetMissionID() == CurrentSelectMissionID then
            self["Switch_SelectMission" .. self.IndexName]:SetActiveWidgetIndex(0)
        else
            self["Switch_SelectMission" .. self.IndexName]:SetActiveWidgetIndex(1)
        end
    end
end

function UITaskTitleItem:TaskDataNotify(NotifyEvent)
    if not self.UIMissionNode then
        return
    end
    if NotifyEvent == 'Distance' then
        self:SetDistanceData()
    elseif NotifyEvent == 'all' then
        local WidgetIndex = self.UIMissionNode.OwnerVM.CurrentTrackingTaskField:GetFieldValue() == self.MissionId and 1 or
        0
        self:GetMissionData()
        self:SetItemData()
        self:OnItemShow(WidgetIndex)
        self:SetDistanceData()
    end
end

--function UITaskTitleItem:Tick(MyGeometry, InDeltaTime)
--end

function UITaskTitleItem:Button_OnPressed()
    if self.UIMissionNode then
        self.UIMissionNode.OwnerVM.CurrentSelectTaskField:SetFieldValue(self.UIMissionNode.MissionObject:GetMissionID())
    end
end

function UITaskTitleItem:ComBtn_Title_OnHovered()
    if self.UIMissionNode.MissionObject:GetMissionID() == self.CurrentSelectMissionID then
        self["Switch_SelectMission" .. self.IndexName]:SetActiveWidgetIndex(2)
    else
        self["Switch_SelectMission" .. self.IndexName]:SetActiveWidgetIndex(3)
    end
end

function UITaskTitleItem:ComBtn_Title_OnUnhovered()
    if self.UIMissionNode.MissionObject:GetMissionID() == self.CurrentSelectMissionID then
        self["Switch_SelectMission" .. self.IndexName]:SetActiveWidgetIndex(0)
    else
        self["Switch_SelectMission" .. self.IndexName]:SetActiveWidgetIndex(1)
    end
end

return UITaskTitleItem
