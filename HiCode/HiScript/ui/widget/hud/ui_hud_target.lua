--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWidgetBase = require('CP0032305_GH.Script.framework.ui.ui_widget_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local MissionConst = require('Script.mission.mission_const')
local InputDef = require('CP0032305_GH.Script.common.input_define')
local IconUtility = require('CP0032305_GH.Script.common.utils.icon_util')

---@class WBP_HUD_Target_C
local UIHudTargetItem = Class(UIWidgetBase)

--function UIHudTargetItem:Initialize(Initializer)
--end

--function UIHudTargetItem:PreConstruct(IsDesignTime)
--end

-- function UIHudTargetItem:Construct()
-- end

--function UIHudTargetItem:Tick(MyGeometry, InDeltaTime)
--end

function UIHudTargetItem:OnConstruct()
    ---@type HudTrackVM
    self.HudTrackVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudTrackVM.UniqueName)
    self:BuildWidgetProxy()
    self:InitViewModel()
end

---@param TrackActorNode TrackActorNode
function UIHudTargetItem:InitTrackItem(TrackActorNode)
    self.TrackActorNode = TrackActorNode
    self:InitAnimation()
end

function UIHudTargetItem:BuildWidgetProxy()
    ---@type UIWidgetField
    self.TargetStateField = self:CreateUserWidgetField(self.UpdateTargetState)
    self.CurrentTrackingMissionField = self:CreateUserWidgetField(self.UpdateTrackingMissionInfo)
end

function UIHudTargetItem:InitViewModel()
    ---@type TaskMainVM
    self.TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
    ---@type HudTrackingMission
    self.HudTrackingMission = self.TaskMainVM.HudTrackingMission

    ViewModelBinder:BindViewModel(self.TargetStateField, self.HudTrackingMission.HudTrackingMissionNotifyField, ViewModelBinder.BindWayToWidget)
    ViewModelBinder:BindViewModel(self.CurrentTrackingMissionField, self.HudTrackingMission.HudTrackingMissionField, ViewModelBinder.BindWayToWidget)
end

function UIHudTargetItem:UpdateTargetState(NotifyEvent)
    if NotifyEvent == 'ReTracking' and self.TrackActorNode then
        self:RefreshAnimation()
    end
end

function UIHudTargetItem:UpdateTrackingMissionInfo(TrackingMissionID)
    self.CurrentTrackingMissionID = TrackingMissionID
end

function UIHudTargetItem:InitAnimation()
    local TrackType, WorldLocation, Distance, MissionObject, isBoss = self.TrackActorNode:GetObjTrackInfo()
    local TaskType
    local TaskState
    if not MissionObject then
        if TrackType == self.HudTrackVM.TrackTargetType.SpecialIcon then
            self.WBP_HUD_Task_Icon.Task_Icon_Switcher:SetActiveWidgetIndex(TrackType)
            local icon = self.TrackActorNode.TrackedTarget.Icon
            self.WBP_HUD_Task_Icon.SpecialIcon:SetBrushResourceObject(icon)
        else
            IconUtility:SetTaskIcon(self.WBP_HUD_Task_Icon, TrackType, MissionConst.EMissionTrackIconType.None)
        end
        self:Emphasize(TrackType)
        return
    end
    TaskType = MissionObject:GetMissionType()
    TaskState = MissionObject:GetMissionTrackIconType()
    IconUtility:SetTaskIcon(self.WBP_HUD_Task_Icon, TaskType, TaskState - 1)
    self:Emphasize(TaskType)
end

function UIHudTargetItem:RefreshAnimation()
    local TrackType, WorldLocation, Distance, MissionObject, isBoss  = self.TrackActorNode:GetObjTrackInfo()
    local TaskType
    local TaskState
    if not MissionObject then
        return
    end
    if self.CurrentTrackingMissionID ~= MissionObject:GetMissionID() then
        return
    end
    TaskType = MissionObject:GetMissionType()
    TaskState = MissionObject:GetMissionTrackIconType()
    IconUtility:SetTaskIcon(self.WBP_HUD_Task_Icon, TaskType, TaskState - 1)
    self:Emphasize(TaskType)
end

function UIHudTargetItem:GetTrackItem()
    return self.TrackActorNode
end

---@param UIHudTrackObj WBP_HUD_Track_C
function UIHudTargetItem:UpdateTrackItem(UIHudTrackObj,InDeltaTime)
    local TaskType, WorldLocation, Distance, MissionObject, isBoss = self.TrackActorNode:GetObjTrackInfo()
    local bIsTrackIconVisibility = true
    if MissionObject ~= nil then
        bIsTrackIconVisibility = self:SetTrackIconVisibility(MissionObject)
    end
    if not bIsTrackIconVisibility then
        return
    end

    if WorldLocation then

        -- 判断是否在玩家视野背后
        local bIsOcclused = false
        local bInBack = false
        local PlayerCameraManager = UE.UGameplayStatics.GetPlayerCameraManager(self, 0)
        if PlayerCameraManager then
            local CameraLocation = PlayerCameraManager:GetCameraLocation()
            local CameraRot = PlayerCameraManager:GetCameraRotation()
            local CameraFwd = UE.UKismetMathLibrary.GetForwardVector(UE.FRotator(0, CameraRot.Yaw, 0))
            local TrackObjToCamera = WorldLocation - CameraLocation

            local DotValue = UE.UKismetMathLibrary.Dot_VectorVector(CameraFwd, TrackObjToCamera)
            if DotValue < 0 then    -- 玩家视野后
                local ReflectionVector = UE.UKismetMathLibrary.GetReflectionVector(TrackObjToCamera, CameraFwd)
                WorldLocation = CameraLocation + ReflectionVector
                bInBack = true
            end
            -- TODO 取消射线检测, 后续试验IsShown
            -- bIsOcclused = self:GetOcclusionCount(CameraLocation, WorldLocation) > 0
        end

        local ViewPortLocation = UE.FVector2D()
        -- UE.UWidgetLayoutLibrary.ProjectWorldLocationToWidgetPosition(UIHudTrackObj.UEPlayerController, WorldLocation, ViewPortLocation, true)
        local UEPlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
        UE.UWidgetLayoutLibrary.ProjectWorldLocationToWidgetPosition(UEPlayerController, WorldLocation, ViewPortLocation, true)

        local bClamped, ClampedLocation, ToCenterDirection2D = UIHudTrackObj:ClampUITrackItemLocation(ViewPortLocation, bInBack, UIHudTrackObj.CheckTaskArea, bIsOcclused)
        if bClamped then
            self.Slot:SetPosition(ClampedLocation)
            self.Text_Distance:SetVisibility(UE.ESlateVisibility.Hidden)
            self.Box_Rotate:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

            local Rot = UE.FVector(ToCenterDirection2D.X, ToCenterDirection2D.Y, 0):ToRotator()
            local UITransformAngle = Rot.Yaw + 90
            self.Box_Rotate:SetRenderTransformAngle(UITransformAngle)
        else
            self.Slot:SetPosition(ViewPortLocation)
            self.Box_Rotate:SetVisibility(UE.ESlateVisibility.Hidden)
            if Distance < 150 then
                self.Text_Distance:SetVisibility(UE.ESlateVisibility.Hidden)
            elseif Distance == 0 then
                self.Text_Distance:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                self.Text_Distance:SetVisibility(UE.ESlateVisibility.Collapsed)
            else
                self.Text_Distance:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                Distance = UE.UKismetMathLibrary.FFloor(Distance * 0.01)
                self.Text_Distance:SetText(Distance .. 'm')
            end
        end
    end
end

function UIHudTargetItem:SetTrackIconVisibility(MissionObject)
    local MissionItem = MissionObject:GetFirstTrackTarget()
    local MissionDistance = MissionObject:GetMissionDistance()
    if MissionItem and MissionDistance then
        if MissionDistance * 100 < MissionItem.Radius then
            self.Target_Icon:SetVisibility(UE.ESlateVisibility.Hidden)
            self.Box_Rotate:SetVisibility(UE.ESlateVisibility.Hidden)
            return false
        else
            self.Target_Icon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            return true
        end
    end
end

-- function UIHudTargetItem:Tick(MyGeometry, InDeltaTime)
-- end

function UIHudTargetItem:Emphasize(type)
    local animName
    if type == self.HudTrackVM.TrackTargetType.TreasureBox or type == self.HudTrackVM.TrackTargetType.Badieta 
    or type == self.HudTrackVM.TrackTargetType.SpecialIcon then
        animName = self.DX_IconTrackNormal
    elseif type == MissionConst.EMissionType.Main then -- 主线
        animName = self.DX_IconTrackMain
    elseif type == MissionConst.EMissionType.Activity then -- 活动
        animName = self.DX_IconTrackActivity
    elseif type == MissionConst.EMissionType.Daily then -- 日常
        animName = self.DX_IconTrackDaily
    elseif type == MissionConst.EMissionType.Guide then -- 引导
        animName = self.DX_IconTrackGuide
    end
    if animName == nil then
        return
    end
    self:StopAnimationsAndLatentActions()
    HiAudioFunctionLibrary.PlayAKAudio("Play_UI_General_PointerFocus", UE.UGameplayStatics.GetPlayerPawn(self, 0))
    self:PlayAnimation(animName, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function UIHudTargetItem:OnShow()
    UIManager:RegisterPressedKeyDelegate(self, self.OnPressKeyEvent)
end

function UIHudTargetItem:OnHide()
    UIManager:UnRegisterPressedKeyDelegate(self)
end

function UIHudTargetItem:OnPressKeyEvent(KeyName)
    local TrackType, WorldLocation, Distance, MissionObject, isBoss = self.TrackActorNode:GetObjTrackInfo()
    if not MissionObject then
        return
    end
    if KeyName == InputDef.Actions.TrackMissionAction then
        return self:RefreshAnimation()
    end
end

function UIHudTargetItem:StopAnim()
end

return UIHudTargetItem
