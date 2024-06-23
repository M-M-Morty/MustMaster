--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local InputDef = require('CP0032305_GH.Script.common.input_define')



---@class WBP_HUD_Track_C
local UIHudTrack = Class(UIWindowBase)

UIHudTrack.CheckTaskArea = 1
UIHudTrack.CheckHurtArea = 2

--function UIHudTrack:Initialize(Initializer)
--end

--function UIHudTrack:PreConstruct(IsDesignTime)
--end

-- function UIHudTrack:Construct()
-- end

function UIHudTrack:OnConstruct()

    ---@type HudTrackVM
    self.HudTrackVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudTrackVM.UniqueName)

    self.TrackingActorField = self:CreateUserWidgetField(self.TrackingActorFieldChanged)

    ViewModelBinder:BindViewModel(self.TrackingActorField, self.HudTrackVM.TrackActorArrayField, ViewModelBinder.BindWayToWidget)

    self.CheckAreaGeoCache = {}
    self.CheckAreaGeoCache[UIHudTrack.CheckTaskArea] = {}
    self.CheckAreaGeoCache[UIHudTrack.CheckHurtArea] = {}
end

---@param ArrayItemData table
---@param OpCode string
---@param OpValue ViewModelField@Value:TrackActorNode
function UIHudTrack:TrackingActorFieldChanged(ArrayItemData, OpCode, OpValue)
    if OpCode == 'AddItem' then
        self:AddTrackItem(OpValue:GetFieldValue())
    elseif OpCode == 'RemoveItem' then
        for _, v in pairs(OpValue) do
            self:RemoveTrackItem(v:GetFieldValue())
        end
    else
        self:ClearTrackItem()
        for i = 1, #ArrayItemData do
            self:AddTrackItem(ArrayItemData[i]:GetFieldValue())
        end
    end
end

function UIHudTrack:GetTrackClass(TrackActorNode)
    local WidgetClass
    local TrackType = TrackActorNode:GetObjTrackType()
    if TrackType == self.HudTrackVM.TrackTargetType.TrackActor then
        WidgetClass = UIManager:ClassRes("HudTraceItem")
    elseif TrackType == self.HudTrackVM.TrackTargetType.TrackLocation then
        WidgetClass = UIManager:ClassRes("HudHurtTraceItem")
    elseif TrackType == self.HudTrackVM.TrackTargetType.TreasureBox then
        --TODO 添加宝箱的控制类
        WidgetClass = UIManager:ClassRes("HudTraceItem")
    elseif TrackType == self.HudTrackVM.TrackTargetType.Badieta then
        --TODO 添加巴别塔的控制类
        WidgetClass = UIManager:ClassRes("HudTraceItem")
    elseif TrackType == self.HudTrackVM.TrackTargetType.SpecialIcon then
        --添加通用icon
        WidgetClass = UIManager:ClassRes("HudTraceItem")
    end
    return WidgetClass
end

---@param TrackActorNode TrackActorNode
function UIHudTrack:AddTrackItem(TrackActorNode)
    if not TrackActorNode.TrackedTarget:IsValid() then
        return
    end

    local WidgetClass = self:GetTrackClass(TrackActorNode)
    if WidgetClass then
        local NewWidget = UE.NewObject(WidgetClass, self)
        local type = TrackActorNode:GetObjTrackType()
        local NewSlot = self.TrackTargetContainer:AddChildToCanvas(NewWidget)
        NewSlot:SetAutoSize(true)
        NewSlot:SetAlignment(UE.FVector2D(0.5, 0.5))
        if type == self.HudTrackVM.TrackTargetType.TrackActor then
            NewSlot:SetZOrder(1)
        else
            NewSlot:SetZOrder(0)
        end

        NewWidget:InitTrackItem(TrackActorNode)
        self.TrackWidgetArray:Add(NewWidget)
    end
end

---@param TrackActorNode TrackActorNode
function UIHudTrack:RemoveTrackItem(TrackActorNode)
    local Num = self.TrackWidgetArray:Length()
    for i = 1, Num do
        local Widget = self.TrackWidgetArray:Get(i)
        if Widget:GetTrackItem() == TrackActorNode then
            Widget:RemoveFromParent()
            self.TrackWidgetArray:Remove(i)
            break
        end
    end
end

function UIHudTrack:ClearTrackItem()
    local Num = self.TrackWidgetArray:Length()
    for i = 1, Num do
        local Widget = self.TrackWidgetArray:Get(i)
        Widget:RemoveFromParent()
    end
    self.TrackWidgetArray:Clear()
end

function UIHudTrack:Tick(MyGeometry, InDeltaTime)
    local TrackNum = self.TrackWidgetArray:Length()
    if TrackNum > 0 then
        for i = 1, TrackNum do
            local TrackItem = self.TrackWidgetArray:Get(i)
            TrackItem:UpdateTrackItem(self,InDeltaTime)
        end
    end
end

---@param CheckAreaType number
function UIHudTrack:UpdateCachedGeo(CheckAreaType)
    local CheckAreaGeo = nil
    
    if CheckAreaType == self.CheckTaskArea then
        CheckAreaGeo = self.CheckArea:GetCachedGeometry()
    elseif CheckAreaType == self.CheckHurtArea then
        CheckAreaGeo = self.CheckArea_1:GetCachedGeometry()
    end
    if CheckAreaGeo == nil then
        return
    end

    local GeoCache = self.CheckAreaGeoCache[CheckAreaType]
    if not GeoCache then
        return
    end

    local CheckAreaLocalSize = UE.USlateBlueprintLibrary.GetLocalSize(CheckAreaGeo)
    local CheckAreaTopLeft = UE.USlateBlueprintLibrary.GetLocalTopLeft(CheckAreaGeo)

    if GeoCache.CheckAreaLocalSize ~= CheckAreaLocalSize or GeoCache.CheckAreaTopLeft ~= CheckAreaTopLeft then
        GeoCache.CheckAreaLocalSize = CheckAreaLocalSize
        GeoCache.CheckAreaTopLeft = CheckAreaTopLeft

        local ContainerGeo = self.TrackTargetContainer:GetCachedGeometry()
        local CheckAreaBottomRight = CheckAreaTopLeft + CheckAreaLocalSize

        local PixelLocation = UE.FVector2D()
        local ViewPortLocationTopLeft = UE.FVector2D()
        local ViewPortLocationBottomRight = UE.FVector2D()
    
        UE.USlateBlueprintLibrary.LocalToViewport(self, ContainerGeo, CheckAreaTopLeft, PixelLocation, ViewPortLocationTopLeft)
        UE.USlateBlueprintLibrary.LocalToViewport(self, ContainerGeo, CheckAreaBottomRight, PixelLocation, ViewPortLocationBottomRight)

        GeoCache.CheckAreaViewportCenter = (ViewPortLocationTopLeft + ViewPortLocationBottomRight) * 0.5

        GeoCache.OvalHalfWidth = (ViewPortLocationBottomRight.X - ViewPortLocationTopLeft.X) * 0.5
        GeoCache.OvalHalfHeigt = (ViewPortLocationBottomRight.Y - ViewPortLocationTopLeft.Y) * 0.5
    end
    return GeoCache
end

---@param InViewPortLocation FVector2D
---@param bForceClamp boolean
---@param CheckAreaType number
---@param bIsOcclused boolean
function UIHudTrack:ClampUITrackItemLocation(InViewPortLocation, bForceClamp, CheckAreaType, bIsOcclused)

    local GeoCache = self:UpdateCachedGeo(CheckAreaType)
    if not GeoCache then
        return
    end

    -- 椭圆的参数方程 (OvalHalfWidth > OvalHalfHeigt)
    -- x = OvalHalfWidth * cos(angle)
    -- y = OvalHalfHeigt * sin(angle)
    -- angle 为椭圆变为圆后的角度
    local ViewPort = InViewPortLocation
    if bIsOcclused and not bForceClamp then
        InViewPortLocation.X = (InViewPortLocation.X - GeoCache.CheckAreaViewportCenter.X) * 100 + GeoCache.CheckAreaViewportCenter.X
        InViewPortLocation.Y = (InViewPortLocation.Y - GeoCache.CheckAreaViewportCenter.Y) * 100 + GeoCache.CheckAreaViewportCenter.Y
    end

    local ViewSize = UE.UWidgetLayoutLibrary.GetViewportSize(self)
    local ViewScale = UE.UWidgetLayoutLibrary.GetViewportScale(self)
    local ScreenSize = ViewSize / ViewScale
    if not bForceClamp and ViewPort.X < ScreenSize.X and ViewPort.Y < ScreenSize.Y and ViewPort.X > 0 and ViewPort.Y > 0 then
        return false, ViewPort, ScreenSize
    end

    local ToCenter = InViewPortLocation - GeoCache.CheckAreaViewportCenter
    -- local ToCenter = InViewPortLocation
    local ToCenterDir = UE.UKismetMathLibrary.Normal2D(ToCenter)
    local DistanceToCenter2 = UE.UKismetMathLibrary.DistanceSquared2D(ToCenter, UE.FVector2D(0, 0))
    local ScaledToCenter = UE.FVector2D(ToCenter.X, ToCenter.Y * GeoCache.OvalHalfWidth / GeoCache.OvalHalfHeigt)
    local ScaledToCenterDir = UE.UKismetMathLibrary.Normal2D(ScaledToCenter)
    
    local CosValue = ScaledToCenterDir:Dot(UE.FVector2D(1, 0))
    local RotatedRad = UE.UKismetMathLibrary.GetRotated2D(ScaledToCenterDir, -90)    -- sin(x) = cos(x - PI/2)
    local SinValue = RotatedRad:Dot(UE.FVector2D(1, 0))

    local OvalX = GeoCache.OvalHalfWidth * CosValue
    local OvalY = GeoCache.OvalHalfHeigt * SinValue
    local OvalPoint = UE.FVector2D(OvalX, OvalY)

    local DistanceOval2 = UE.UKismetMathLibrary.DistanceSquared2D(OvalPoint, UE.FVector2D(0, 0))
    if not bForceClamp and DistanceToCenter2 < DistanceOval2 then
        return false, InViewPortLocation, ToCenterDir
    end
    local viewP = OvalPoint + GeoCache.CheckAreaViewportCenter
    if bForceClamp then
        if viewP.Y < GeoCache.CheckAreaViewportCenter.Y then
            viewP.Y = GeoCache.CheckAreaViewportCenter.Y * 2 - viewP.Y
        end
        if ToCenterDir.Y < 0 then
            ToCenterDir.Y = -ToCenterDir.Y
        end
    end
    return true, viewP, ToCenterDir
end

function UIHudTrack:EmphasizeTips()
    local Num = self.TrackWidgetArray:Length()
    for i = 1, Num do
        local Widget = self.TrackWidgetArray:Get(i)
        if not Widget.TrackingAnim then
            return
        end
        Widget:TrackingAnim()
    end
end

return UIHudTrack
