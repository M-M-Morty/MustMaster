--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWidgetBase = require('CP0032305_GH.Script.framework.ui.ui_widget_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')

---@class WBP_HUD_Hurt_Target_C
local UIHudHurtTargetItem = Class(UIWidgetBase)

--function UIHudHurtTargetItem:Initialize(Initializer)
--end

--function UIHudHurtTargetItem:PreConstruct(IsDesignTime)
--end

-- function UIHudHurtTargetItem:Construct()
-- end

function UIHudHurtTargetItem:OnDestruct()
end

-- function UIHudHurtTargetItem:Tick(MyGeometry, InDeltaTime)
-- end

function UIHudHurtTargetItem:OnConstruct()
end

---@param TrackActorNode TrackActorNode
function UIHudHurtTargetItem:InitTrackItem(TrackActorNode)
    self.TrackActorNode = TrackActorNode
    self:OnPlayStartAnimation()
end

function UIHudHurtTargetItem:OnPlayStartAnimation()
    self:StopAnimationsAndLatentActions()

    self:UnbindAllFromAnimationFinished(self.DX_chuxian)
    self:PlayAnimation(self.DX_chuxian, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
    self:BindToAnimationFinished(self.DX_chuxian,{self, function ()
        self:PlayAnimation(self.DX_xunhuan, 0, 0, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    end})
end

function UIHudHurtTargetItem:OnPlayEndAnimation()
    self:PlayAnimation(self.DX_xiaoshi, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function UIHudHurtTargetItem:GetTrackItem()
    return self.TrackActorNode
end

---@param UIHudTrackObj WBP_HUD_Hurt_Target_C
function UIHudHurtTargetItem:UpdateTrackItem(UIHudTrackObj, InDeltaTime)
    if not self.TrackActorNode then
        return
    end
    if not self.TrackActorNode.TrackedTarget:IsValid() then
        return
    end
    local TaskType, WorldLocation, Distance, isBoss = self.TrackActorNode:GetObjTrackInfo()
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
            if DotValue < 0 then -- 玩家视野后
                local ReflectionVector = UE.UKismetMathLibrary.GetReflectionVector(TrackObjToCamera, CameraFwd)
                WorldLocation = CameraLocation + ReflectionVector
                bInBack = true
            end
            if not isBoss then
                bIsOcclused = self:GetOcclusionCount(CameraLocation, WorldLocation + (CameraLocation - WorldLocation) * 0.2) > 0
            end
        end
        -- if bInBack == false then 
        --     self.CanvasPanel_Pointer:SetVisibility(UE.ESlateVisibility.Hidden)
        --     return
        -- end

        local UEPlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
        local ViewPortLocation = UE.FVector2D()
        UE.UWidgetLayoutLibrary.ProjectWorldLocationToWidgetPosition(UEPlayerController, WorldLocation, ViewPortLocation,
            true)

        local bClamped, ClampedLocation, ToCenterDirection2D = UIHudTrackObj:ClampUITrackItemLocation(ViewPortLocation,
            bInBack, UIHudTrackObj.CheckHurtArea, bIsOcclused)
        if bClamped then
            self.Slot:SetPosition(ClampedLocation)
            self.CanvasPanel_Pointer:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

            local Rot = UE.FVector(ToCenterDirection2D.X, ToCenterDirection2D.Y, 0):ToRotator()
            local UITransformAngle = Rot.Yaw + 90
            self.CanvasPanel_Pointer:SetRenderTransformAngle(UITransformAngle)
        else
            -- self:StopAnimationsAndLatentActions()
            -- self.TrackActorNode.TrackedTarget:SetExpired()
            -- self.Slot:SetPosition(ViewPortLocation)
            self.CanvasPanel_Pointer:SetVisibility(UE.ESlateVisibility.Hidden)
        end
    end
end

return UIHudHurtTargetItem
