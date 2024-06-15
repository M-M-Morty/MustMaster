local G = require('G')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local InputDef = require('CP0032305_GH.Script.common.input_define')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local MissionConst = require('Script.mission.mission_const')
local IconUtility = require('CP0032305_GH.Script.common.utils.icon_util')
local UIEventDef = require('CP0032305_GH.Script.ui.ui_event.ui_event_def')
local UIConstData = require("common.data.ui_const_data").data

---@class WBP_HUD_Task_Track_C
local HUDTaskTrack = Class(UIWindowBase)

local akNames =
{
    NewTaskPopsUp = "Play_UI_General_NewTaskPopsUp",
    MssionCompleted = "Play_UI_General_MssionCompleted",
    TaskNodeCompleted = "Play_UI_General_TaskNodeCompleted",
}
--function HUDTaskTrack:Initialize(Initializer)
--end

--function HUDTaskTrack:PreConstruct(IsDesignTime)
--end

function HUDTaskTrack:OnConstruct()
    self:InitWidget()
    self:BuildWidgetProxy()
    self:InitViewModel()
end

function HUDTaskTrack:OnDestruct()
end

function HUDTaskTrack:OnDestroy()
    self:UnRegisterTaskVMNotification()
end

function HUDTaskTrack:InitWidget()
    self.WidgetSwitcher_TaskInfo:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.ComBtn_GetTask.OnClicked:Add(self, self.Button_GetTask_OnClicked)
    self.ComBtn_Task.OnClicked:Add(self, self.ComBtn_OnClicked)
    self:StopAnimationsAndLatentActions()
    self:PlayAnimation(self.DX_in, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function HUDTaskTrack:RegisterTaskVMNotification()
    local PlayerState = UE.UGameplayStatics.GetPlayerState(G.GameInstance:GetWorld(), 0)
    local MissionAvatarComponent = PlayerState.MissionAvatarComponent
    MissionAvatarComponent.OnMissionStateChange:Add(self, self.OnMissionStateChange)
    MissionAvatarComponent.OnMissionEventStateChange:Add(self, self.OnMissionEventStateChange)
end

function HUDTaskTrack:UnRegisterTaskVMNotification()
    local PlayerState = UE.UGameplayStatics.GetPlayerState(G.GameInstance:GetWorld(), 0)
    local MissionAvatarComponent = PlayerState.MissionAvatarComponent
    MissionAvatarComponent.OnMissionStateChange:Remove(self, self.OnMissionStateChange)
    MissionAvatarComponent.OnMissionEventStateChange:Remove(self, self.OnMissionEventStateChange)
end

function HUDTaskTrack:OnMissionStateChange(MissionID, State)
    if self.TaskMainVM then
        self.TaskMainVM:OnMissionStateChange(MissionID, State)
    end
end

function HUDTaskTrack:OnMissionEventStateChange(MissionEventID, State, MissionID)
    if self.TaskMainVM then
        self.TaskMainVM:OnMissionEventStateChange(MissionEventID, State, MissionID)
    end
end

function HUDTaskTrack:BuildWidgetProxy()
    ---@type UIWidgetField
    self.TrackStateField = self:CreateUserWidgetField(self.UpdateTrackState)
    self.CurrentTrackingMissionField = self:CreateUserWidgetField(self.UpdateTrackingMissionInfo)
    self.TrackingMissionDataChangedField = self:CreateUserWidgetField(self.UpdateTrackingMissionData)
    UIManager.UINotifier:BindNotification(UIEventDef.LoadPlayerState, self, self.RegisterTaskVMNotification)
end

function HUDTaskTrack:InitViewModel()
    ---@type TaskMainVM
    self.TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
    ---@type HudTrackingMission
    self.HudTrackingMission = self.TaskMainVM.HudTrackingMission

    ViewModelBinder:BindViewModel(self.TrackStateField, self.HudTrackingMission.HudTrackStateField, ViewModelBinder.BindWayToWidget)
    ViewModelBinder:BindViewModel(self.CurrentTrackingMissionField, self.HudTrackingMission.HudTrackingMissionField, ViewModelBinder.BindWayToWidget)
    ViewModelBinder:BindViewModel(self.TrackingMissionDataChangedField, self.HudTrackingMission.HudTrackingMissionNotifyField, ViewModelBinder.BindWayToWidget)
end

---@param TrackState HudTrackingState
function HUDTaskTrack:UpdateTrackState(TrackState)

    self.TrackState = TrackState
    if TrackState == self.TaskMainVM.HudTrackingState.Hidden then
        self.WidgetSwitcher_TaskInfo:SetVisibility(UE.ESlateVisibility.Hidden)
        self:StopAnimationsAndLatentActions()
        return
    end

    self:ResetWaitHandler()
    self.WidgetSwitcher_TaskInfo:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.WidgetSwitcher_TaskInfo:SetRenderOpacity(1.0)
    if TrackState == self.TaskMainVM.HudTrackingState.Interact then
        self.WidgetSwitcher_TaskInfo:SetActiveWidgetIndex(1)
        self:WaitInteract(UIConstData.MISSION_TRACK_TIP_DURATION.FloatValue)
    elseif TrackState == self.TaskMainVM.HudTrackingState.PreMissionUnfinished then
        self.WidgetSwitcher_TaskInfo:SetActiveWidgetIndex(2)
        self:WaitInteract(UIConstData.MISSION_TRACK_TIP_DURATION.FloatValue)
    elseif TrackState == self.TaskMainVM.HudTrackingState.Finished then
        self.WidgetSwitcher_TaskInfo:SetActiveWidgetIndex(3)
    else
        self.WidgetSwitcher_TaskInfo:SetActiveWidgetIndex(0)
    end
    self:Emphasize(TrackState)
end

function HUDTaskTrack:UpdateTrackingMissionProgress(MissionObject)
    local EventDesc = MissionObject:GetMissionName()
    local MissionType = MissionObject:GetMissionType()
    local MissionEventDescribe = MissionObject:GetMissionEventDesc()
    local MissionTrackIconType = MissionObject:GetMissionTrackIconType()
    self.Text_TaskDesc:SetText(EventDesc)
    self.Text_TaskDesc_1:SetText(EventDesc)
    self.Text_TaskDesc_2:SetText(EventDesc)
    self.Text_TaskDesc_3:SetText(EventDesc)
    if self.TrackState == self.TaskMainVM.HudTrackingState.Tracked then
        self.Text_TaskDesc:SetText(MissionEventDescribe)
    end
    if MissionTrackIconType then
        IconUtility:SetTaskIcon(self.WBP_HUD_Task_Icon, MissionType, MissionTrackIconType - 1)
    end
end

function HUDTaskTrack:UpdateTrackingMissionDistance(MissionObject)
    local DistanceText = self.HudTrackingMission:GetTrackingMissionDistanceText(MissionObject, self.MissionDirection)
    if DistanceText then
        self.Text_Distance:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Text_Distance:SetText(DistanceText)
    else
        self.Text_Distance:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function HUDTaskTrack:GetMissionObject()
    local UIMissionNode = self.TaskMainVM:GetUIMissionNode(self.CurrentTrackingMissionID)
    if UIMissionNode then
        return UIMissionNode.MissionObject
    end
end

function HUDTaskTrack:UpdateTrackingMissionData(NotifyEvent)
    local MissionObject = self:GetMissionObject()
    if not MissionObject then
        ---任务完成动画，但是没有取到MissionObject,说明remove数据先于finish动画
        ---从data中单独取数据
        if self.TrackState == self.TaskMainVM.HudTrackingState.Finished
         and NotifyEvent == 'all' and self.TaskMainVM.finishMissionObjectCache then
            --完成只需要标题，不需要进度、距离等
            self:UpdateTrackingMissionProgress(self.TaskMainVM.finishMissionObjectCache)
            return
        else
            return
        end
    end

    if NotifyEvent == 'all' then
        self:UpdateTrackingMissionProgress(MissionObject)
        self:UpdateTrackingMissionDistance(MissionObject)
    elseif NotifyEvent == 'Progress' then
        self:UpdateTrackingMissionProgress(MissionObject)
    elseif NotifyEvent == 'Distance' then
        self:UpdateTrackingMissionDistance(MissionObject)
    end
end

function HUDTaskTrack:PlayMissionIconAnimation(MissionObject)
    local MissionType = MissionObject:GetMissionType()
    local MissionTrackIconType = MissionObject:GetMissionTrackIconType()
    local animName
    if MissionType == MissionConst.EMissionType.Main then -- 主线
        animName = self.DX_IconTrackMain
    elseif MissionType == MissionConst.EMissionType.Activity then -- 活动
        animName = self.DX_IconTrackActivity
    elseif MissionType == MissionConst.EMissionType.Daily then -- 日常
        animName = self.DX_IconTrackDaily
    elseif MissionType == MissionConst.EMissionType.Guide then -- 引导
        animName = self.DX_IconTrackGuide
    end
    if animName == nil then
        return
    end
    IconUtility:SetTaskIcon(self.WBP_HUD_Task_Icon, MissionType, MissionTrackIconType - 1)
    self:PlayAnimation(animName, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function HUDTaskTrack:UpdateTrackingMissionInfo(TrackingMissionID)
    self.CurrentTrackingMissionID = TrackingMissionID
    self:UpdateTrackingMissionData('all')
end

function HUDTaskTrack:TrackInteractMission()
    local MissionObject = self:GetMissionObject()
    if not MissionObject then
        return
    end

    if MissionObject:IsTrackable() then
        if MissionObject:IsTracking() then
            self:PlayMissionIconAnimation(MissionObject)
            if self.TaskMainVM and self.TaskMainVM.HudTrackingMission then
                self.HudTrackingMission:OnReTrackingMission()
            end
            local PlayerController = UE.UGameplayStatics.GetPlayerController(G.GameInstance:GetWorld(), 0)
            PlayerController.PlayerState.MissionAvatarComponent:StartScreenTrack()
        end
        if not MissionObject:IsTracking() then
            self.TaskMainVM:SetTaskTracking(MissionObject, true)
            return true
        end
    end
end

function HUDTaskTrack:Button_GetTask_OnClicked()
    self:TrackInteractMission()
end

--动画结束后回调
function HUDTaskTrack:SwitcherTaskAnimFinish(type)
    if type == self.TaskMainVM.HudTrackingState.Interact or type == self.TaskMainVM.HudTrackingState.PreMissionUnfinished then
        self:NewTaskAnimPlayEnd()
    elseif type == self.TaskMainVM.HudTrackingState.Finished then
        self:FinishAnimPlayEnd()
    else
        self:StartTrackingAnimPlayEnd()
    end
end

--这是新任务停留时长结束后的回调，并不是新任务动画播放完毕回调
function HUDTaskTrack:InteractWaitEnd()
    if self.TaskMainVM and self.TaskMainVM.HudTrackingMission then
        self.HudTrackingMission:OnInteractWaitEnd()
    end
end

function HUDTaskTrack:NewTaskAnimPlayEnd()
    if self.TaskMainVM and self.TaskMainVM.HudTrackingMission then
        self.HudTrackingMission:OnNewTaskAnimPlayEnd()
    end
end

function HUDTaskTrack:StartTrackingAnimPlayEnd()
    if self.TaskMainVM and self.TaskMainVM.HudTrackingMission then
        self.HudTrackingMission:OnStartTrackingAnimPlayEnd()
    end
end

function HUDTaskTrack:FinishAnimPlayEnd()
    if self.TaskMainVM and self.TaskMainVM.HudTrackingMission then
        self.HudTrackingMission:OnFinishAnimPlayEnd()
    end
end

function HUDTaskTrack:Emphasize(type)
    local animName, akName
    local playerActor = UE.UGameplayStatics.GetPlayerPawn(self, 0)
    if type == self.TaskMainVM.HudTrackingState.Interact then
        akName = akNames.NewTaskPopsUp
        animName = self.DX_NewTaskIn
    elseif type == self.TaskMainVM.HudTrackingState.Finished then
        akName = akNames.MssionCompleted
        animName = self.DX_TaskFinish
    else
        akName = akNames.TaskNodeCompleted
        animName = self.DX_OngoingTaskIn
    end
    if animName == nil then
        return
    end
    -- self:StopAnimationsAndLatentActions()
    if akName and playerActor then
        HiAudioFunctionLibrary.PlayAKAudio(akName, playerActor)
    end
    self:PlayAnimation(animName, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function HUDTaskTrack:OnShow()

    local missionId = self.TaskMainVM.HudTrackingMission.TrackingMissionID
    if missionId ~= 0 then
        self:UpdateTrackState(self.TaskMainVM.HudTrackingState.Tracked)
        self:UpdateTrackingMissionInfo(missionId)
    end

    self:PlayAnimation(self.DX_in, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)    
end

function HUDTaskTrack:OnHide()
    G.log:error('HUDTaskTrackOnHide', 'UIManager can not Init twice.')
    self:StopAnimationsAndLatentActions()
    self.TaskMainVM:ResetTaskTrackList()
    self:PlayAnimation(self.DX_Out, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

---使用mainHUD的imc进行追踪
function HUDTaskTrack:ClickMissionTrack()
    self:ComBtn_OnClicked()
end

-- 如果当前存在前置任务未完成，则打开任务界面，否则走正常追踪逻辑
function HUDTaskTrack:ComBtn_OnClicked()
    local MissionObject = self:GetMissionObject()
    if MissionObject then
        if MissionObject:IsBlock() then
            self:OpenTaskMainAndShowDetails(MissionObject)
        else
            self:TrackInteractMission()
        end
    end
end

-- 打开任务界面并显示前置任务详情弹窗
function HUDTaskTrack:OpenTaskMainAndShowDetails(MissionObject)
    local taskMainPanel = UIManager:OpenUI(UIDef.UIInfo.UI_TaskMain)
    taskMainPanel:OnOpenDetailPanel(MissionObject, true)
end

-- function HUDTaskTrack:Tick(MyGeometry, InDeltaTime)
-- end

return HUDTaskTrack
