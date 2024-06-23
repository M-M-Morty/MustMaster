--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")
local PicText = require("CP0032305_GH.Script.common.pic_const")

---@class WBP_Task_Main
local UITaskMain = Class(UIWindowBase)

--function UITaskMain:Initialize(Initializer)
--end

--function UITaskMain:PreConstruct(IsDesignTime)
--end

function UITaskMain:OnConstruct()
    self:InitWidget()
    self:BuildWidgetProxy()
    self:InitViewModel()
end

function UITaskMain:OnDestruct()
end

function UITaskMain:OnShow()
    self:InitData()
    self:PlayAnimation(self.DX_in, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    self:PlayAnimation(self.DX_ChangeMission, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    self.WBP_Common_BG_01:PlayAnimation(self.WBP_Common_BG_01.DX_in, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function UITaskMain:OnCreate()
    -- 第一次打开页面选择当前追踪的任务

    local CurrentTrackMissionId = self.TaskMainVM.CurrentTrackingTaskField:GetFieldValue()
    if CurrentTrackMissionId > 0 then
        self.TaskMainVM.CurrentSelectTaskField:SetFieldValue(CurrentTrackMissionId)
    end
end

---@param self WBP_Task_Main
local function OnClickCaseWallButton(self)
    UIManager:OpenUI(UIDef.UIInfo.UI_Task_CaseWall)
end

function UITaskMain:InitWidget()
    self.WPB_TopContent.CommonButton_Close.OnClicked:Add(self, self.ButtonClose_OnClicked)

    self.WBP_ComBtn_Track.OnClicked:Add(self, self.CommonButton_Track_OnClicked)
    self.WBP_ComBtn_Track.OnHovered:Add(self, self.CommonButton_Track_OnHovered)
    self.WBP_ComBtn_Track.OnPressed:Add(self, self.CommonButton_Track_OnPressed)
    self.WBP_ComBtn_Track.OnReleased:Add(self, self.CommonButton_Track_OnReleased)
    self.WBP_ComBtn_Track.OnUnhovered:Add(self, self.CommonButton_Track_OnUnhovered)

    self.WBP_ComBtn_CancelTracking.OnClicked:Add(self, self.CommonButton_Track_OnClicked)
    self.WBP_ComBtn_CancelTracking.OnHovered:Add(self, self.CommonButton_Track_OnHovered)
    self.WBP_ComBtn_CancelTracking.OnPressed:Add(self, self.CommonButton_Track_OnPressed)
    self.WBP_ComBtn_CancelTracking.OnReleased:Add(self, self.CommonButton_Track_OnReleased)
    self.WBP_ComBtn_CancelTracking.OnUnhovered:Add(self, self.CommonButton_Track_OnUnhovered)

    self.WBP_ComBtn_Detail.OnClicked:Add(self, self.CommonButton_Detail_OnClicked)
    self.WBP_ComBtn_Detail.OnHovered:Add(self, self.CommonButton_Detail_OnHovered)

    self.RetainerBox:GetEffectMaterial():SetScalarParameterValue('progress', 80)
    self.RetainerBox:GetEffectMaterial():SetScalarParameterValue('Rotation', 90)
    self.WBP_Btn_Complete.OnClicked:Add(self, OnClickCaseWallButton)
end

function UITaskMain:BuildWidgetProxy()
    -- <<< auto gen proxy by editor begin >>>
    -- 基础控件的ViewModelProxy生成可以由Editor自动完成，目前还未实现，计划中
    ---@type UListViewProxy
    self.ListView_TypeProxy = WidgetProxys:CreateWidgetProxy(self.ListView_Type)

    ---@type UListViewProxy
    self.ListView_TaskNodeProxy = WidgetProxys:CreateWidgetProxy(self.ListView_TaskNode)

    ---@type UTileViewProxy
    self.TileView_PropProxy = WidgetProxys:CreateWidgetProxy(self.TileView_Prop)

    -- <<< auto gen proxy by editor end >>>

    ---@type UIWidgetField
    self.SelectedTaskField = self:CreateUserWidgetField(self.SetTaskSelected)

    ---@type UIWidgetField
    self.TaskTrackedField = self:CreateUserWidgetField(self.UpdateTaskTracked)

    ---@type UIWidgetField
    self.MissionDataChangedField = self:CreateUserWidgetField(self.UpdateTrackingMissionData)
end

function UITaskMain:InitViewModel()
    ---@type TaskMainVM
    self.TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
    if self.TaskMainVM then
        ---@type HudTrackingMission
        self.HudTrackingMission = self.TaskMainVM.HudTrackingMission

        ViewModelBinder:BindViewModel(self.ListView_TypeProxy.ListField, self.TaskMainVM.MissionTypeListField,
            ViewModelBinder.BindWayToWidget)
        ViewModelBinder:BindViewModel(self.SelectedTaskField, self.TaskMainVM.CurrentSelectTaskField,
            ViewModelBinder.BindWayToWidget)
        ViewModelBinder:BindViewModel(self.TaskTrackedField, self.TaskMainVM.CurrentTrackingTaskField,
            ViewModelBinder.BindWayToWidget)
        ViewModelBinder:BindViewModel(self.MissionDataChangedField, self.HudTrackingMission
            .HudTrackingMissionNotifyField, ViewModelBinder.BindWayToWidget)
    end
end

function UITaskMain:InitData()
    if self.TaskMainVM then
        self.TaskMainVM:InitMissionNodeTree()
    end
end

function UITaskMain:ButtonClose_OnClicked()
    self:AddCloseWaitAniamtionEvent({ self.WBP_Common_BG_01.DX_out, self.DX_out })
    self:CloseMyself()
    ---@type WBP_TaskPopUp_Window_C
    local PopUpWindowInstance = UIManager:GetUIInstance(UIDef.UIInfo.UI_Task_PopUp_Window.UIName)
    UIManager:CloseUI(PopUpWindowInstance, true)
end

function UITaskMain:CommonButton_Track_OnClicked()
    if self.TaskMainVM and self.SelectedUITaskNode then
        self.TaskMainVM:ToggleTaskTrack(self.SelectedUITaskNode.MissionObject)
    end
end

---@param SelectMissionObject MissionObject
function UITaskMain:OnOpenDetailPanel(SelectMissionObject)
    if self.TaskMainVM then
        ---@type WBP_TaskPopUp_Window_C
        local PopUpWindowInstance = UIManager:GetUIInstance(UIDef.UIInfo.UI_Task_PopUp_Window.UIName)
        ---@type MissionItem
        local MissionItem = self.TaskMainVM:GetPopUpMissionNode(SelectMissionObject)
        PopUpWindowInstance:AddPopUpWindow(MissionItem)
    end
end

function UITaskMain:CommonButton_Detail_OnClicked()
    if self.SelectedUITaskNode then
        UIManager:OpenUI(UIDef.UIInfo.UI_Task_PopUp_Window)
        self:OnOpenDetailPanel(self.SelectedUITaskNode.MissionObject)
    end
end

function UITaskMain:UpdateTrackingMissionData(NotifyEvent)
    local MissionID = self.TaskMainVM.CurrentTrackingTaskField:GetFieldValue()
    local CurrentUpdateMissionID = self.TaskMainVM:GetCurrentUpdateMissionId()
    if MissionID == self.TaskMainVM.INVALID_TASK_ID then
        if self.SelectedUITaskNode and self.SelectedUITaskNode.MissionObject:GetMissionID() == CurrentUpdateMissionID then
            MissionID = CurrentUpdateMissionID
        else
            return
        end
    end
    local TaskNode = self.TaskMainVM:GetUIMissionNode(MissionID)
    local MissionObject = TaskNode.MissionObject
    if not MissionObject then
        return
    end

    if NotifyEvent == 'Progress' then
        self:UpdateMissionDataProgress(MissionObject)
    end
end

function UITaskMain:SetTaskSelected(MissionID)
    ---@type UIMissionNode
    self.SelectedUITaskNode = nil

    if not self.TaskMainVM then
        ---@type TaskMainVM
        self.TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
    end
    if self.TaskMainVM then
        self.SelectedUITaskNode = self.TaskMainVM:GetUIMissionNode(MissionID)
    end

    if self.SelectedUITaskNode then
        local MissionObject = self.SelectedUITaskNode.MissionObject
        self.Canvas_TaskNode:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self:PlayAnimation(self.DX_ChangeMission, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)

        self:UpdateMissionDataProgress(MissionObject)
        self:UpdateTaskTracked(self.TaskMainVM.CurrentTrackingTaskField:GetFieldValue())
    else
        self.Canvas_TaskNode:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end

---@param MissionObject MissionObject
function UITaskMain:UpdateMissionDataProgress(MissionObject)
    local LocalMissionObject
    if self.SelectedUITaskNode.MissionObject ~= MissionObject then
        LocalMissionObject = self.SelectedUITaskNode.MissionObject
    else
        LocalMissionObject = MissionObject
    end
    self.Text_TaskTitle:SetText(LocalMissionObject:GetMissionName())
    self.Text_Task_RegionTitle:SetText(LocalMissionObject:GetMissionRegion())
    self.ListView_TaskNodeProxy:SetListItems({ LocalMissionObject })
    self.TileView_PropProxy:SetListItems(self:GetPropItemData(LocalMissionObject))
end

function UITaskMain:GetPropItemData(MissionObject)
    local RewardList = ItemUtil.ItemSortFunctionByList(MissionObject:GetMissionAwards())
    for _, v in pairs(RewardList) do
        local rewardItem = ItemUtil.GetItemConfigByExcelID(v.ID)
        v.IconResourceObject = PicText.GetPicResource(rewardItem.icon_reference)
    end
    return RewardList
end

function UITaskMain:UpdateTaskTracked(TrackingMissionID)
    if self.SelectedUITaskNode then
        local MissionObject = self.SelectedUITaskNode.MissionObject
        if MissionObject:IsTrackable() then
            self.WBP_ComBtn_Track:SetIsEnabled(true)
            self.Switcher_Track:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.WBP_Task_ProhibitTips:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.WBP_ComBtn_Detail:SetVisibility(UE.ESlateVisibility.Collapsed)
            if MissionObject:GetMissionID() == TrackingMissionID then
                self.Switcher_Track:SetActiveWidgetIndex(1)
                if self.WBP_ComBtn_CancelTracking.Button:IsHovered() then
                    self.WBP_ComBtn_CancelTracking.Img_Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                else
                    self.WBP_ComBtn_CancelTracking.Img_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
                end
            else
                self.Switcher_Track:SetActiveWidgetIndex(0)
                if self.WBP_ComBtn_Track.Button:IsHovered() then
                    self.WBP_ComBtn_Track.Img_Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                else
                    self.WBP_ComBtn_Track.Img_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
                end
            end
        else
            self.Switcher_Track:SetActiveWidgetIndex(0)
            self.WBP_ComBtn_Track:SetIsEnabled(false)
            self.WBP_ComBtn_Track.Img_Line:SetColorAndOpacity(self.DisableColor)
            if MissionObject:IsBlock() then
                self.Switcher_Track:SetVisibility(UE.ESlateVisibility.Collapsed)
                self.WBP_Task_ProhibitTips:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                self.WBP_ComBtn_Detail:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            end
        end
    end
end

-- function UITaskMain:Tick(MyGeometry, InDeltaTime)
-- end

function UITaskMain:CommonButton_Detail_OnHovered()
    local MissionObject = self.SelectedUITaskNode.MissionObject
    if not MissionObject:IsTrackable() then
        self.WBP_ComBtn_Detail.Img_Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
end

function UITaskMain:CommonButton_Track_OnHovered()
    local MissionObject = self.SelectedUITaskNode.MissionObject
    if MissionObject:IsTrackable() then
        if MissionObject:GetMissionID() == self.TaskMainVM.CurrentTrackingTaskField:GetFieldValue() then
            self.WBP_ComBtn_CancelTracking.Img_Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            self.WBP_ComBtn_Track.Img_Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        end
    end
end

function UITaskMain:CommonButton_Track_OnPressed()
    local MissionObject = self.SelectedUITaskNode.MissionObject
    if MissionObject:IsTrackable() then
        if MissionObject:GetMissionID() == self.TaskMainVM.CurrentTrackingTaskField:GetFieldValue() then
            self.WBP_ComBtn_CancelTracking.Img_Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            self.WBP_ComBtn_Track.Img_Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        end
    end
end

function UITaskMain:CommonButton_Track_OnReleased()
    local MissionObject = self.SelectedUITaskNode.MissionObject
    if MissionObject:IsTrackable() then
        if MissionObject:GetMissionID() == self.TaskMainVM.CurrentTrackingTaskField:GetFieldValue() then
            self.WBP_ComBtn_CancelTracking.Img_Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            self.WBP_ComBtn_Track.Img_Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        end
    end
end

function UITaskMain:CommonButton_Track_OnUnhovered()
    local MissionObject = self.SelectedUITaskNode.MissionObject
    if MissionObject:IsTrackable() then
        if MissionObject:GetMissionID() == self.TaskMainVM.CurrentTrackingTaskField:GetFieldValue() then
            self.WBP_ComBtn_CancelTracking.Img_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
        else
            self.WBP_ComBtn_Track.Img_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

return UITaskMain
