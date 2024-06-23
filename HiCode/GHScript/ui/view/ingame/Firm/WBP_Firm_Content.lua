--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local FirmMapTable = require("common.data.firm_map_data").data
local MiniMapShowTable = require("common.data.minimap_show_data").data
local FirmMapLegendTypeTableConst = require("common.data.firm_map_legend_type_data")
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local PicConst = require("CP0032305_GH.Script.common.pic_const")
local ConstText = require("CP0032305_GH.Script.common.text_const")
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
local FirmUtil = require("CP0032305_GH.Script.ui.view.ingame.Firm.FirmUtil")
local IconUtility = require('CP0032305_GH.Script.common.utils.icon_util')
local G = require("G")

local json = require("thirdparty.json")

---@class WBP_Firm_Content : WBP_Firm_Content_C
---@field Parent WBP_Firm_Map
---@field MapId  string
---@field LabelClickCallback fun() @图标点击回调
---@field CustomUIClickCallback fun()@自定义图标点击回调
---@field FloatUIClickCallback fun()@浮标点击回调
---@field LabelOnHoverCallback fun()@浮标悬停回调
---@field LabelOnUnHoverCallback fun()@浮标未悬停回调
---@field ChildImages ChildGridType[][] @切图信息
---@field ViewBegin FVector2D @当前地图视距左上角
---@field ViewEnd FVector2D @当前地图视距右下角
---@field InitViewCentrePosition FVector2D @初始化时当前视距中心点坐标
---@field ViewCentrePosition FVector2D @当前视距中心点坐标，以CurrentScale==1为基准
---@field BaseScaleBaseScale float @基础缩放
---@field CurrentScale float @当前缩放率
---@field bMouseDown boolean @鼠标是否下按
---@field MoveRate float @移动速率
---@field ImageSize FVector2D @获取地图区域大小
---@field Labels WBP_FirmMapLabel[] @图标
---@field PlayerLabel WBP_FirmMapLabel @主角图标
---@field bIsOnClickedBlank boolean
---@field bDrag boolean @是否正在拖拽
---@field MarkerPointsItems table<number,MapsCustomData>
---@field MultipleSelectionIndex table<string,MarkerItem>
---@field PlayerFloatLabel MapsCustomData
---@field FunctionalLandmark MapsCustomData
---@field MapIconData table
---@field AnchorNum integer
---@field LegendTypeData table<string,FirmMapLegendType>
---@field GridSize FVector2D 格子大小
---@field AnchorUpperLimit integer 锚点上限数量
---@field IconMergeDistance integer 锚点上限数量
---@field FirmAnchorData table 锚点配置数据
---@field GridIndexRow integer 格子行索引
---@field GridIndexColumn integer 格子列索引
---@field ZoomClicked integer 点击的次数
---@field DefaultScaleValue float 默认缩放值
---@field RangeDistance int 目标点n米范围
---@field PreSetScale number 预设缩放
---@field LabelCount int
---@field CurTraceItem 当前追踪的任务item
---@field bIsImportComplete boolean 锚点是否导入完毕
---@type WBP_Firm_Content
local WBP_Firm_Content = Class(UIWindowBase)

---@class ChildGridType
---@field Image UUserWidget
---@field Labels WBP_FirmMapLabel[]

---@class FirmMapData
---@field map_name string
---@field split_row integer
---@field split_column integer
---@field location_begin float[]
---@field location_end float[]
---@field view_range float[]
---@field scale_max float[]


---@class FirmMapLegendType
---@field LegendType integer
---@field Legend_Priority integer
---@field Legend_Scale integer[]
---@field Legend_Name string
---@field Legend_Icon string

---@class FirmMapLegendData
---@field id string
---@field Legend_Name string
---@field Legend_ID string
---@field OwningMap string
---@field Legend_Positon string

---@class MiniMapShowData
---@field Type integer
---@field ShowTempIds integer[]
---@field ExtraActionType integer

---@class LocationType
---@field x float
---@field y float
---@field z float

---@class MiniMapJsonUnit
---@field id string
---@field ShowId string
---@field translation LocationType

---@class MapIconData
---@field Icon string
---@field ShowIcon string
---@field bIsSelected boolean
---@field bIsRewards boolean
---@field bIsTrace boolean

---@class MapsCustomData
---@field TempId integer
---@field AnchorItem WBP_FirmMapLabel
---@field SelectIconIndex string
---@field PositionX number
---@field PositionY number
---@field AnchorName string
---@field bIsChecked boolean
---@field bIsTrace boolean

---@class MarkerItem
---@field PicKey string
---@field bIsChecked boolean
---@field TotalNum integer
---@field CheckedNum integer
---@field SelectIconIndex string
---@field PositionX number
---@field PositionY number
---@field AnchorName string

---@param Id string
---@return FirmMapData
local function GetFirmMapData(Id)
    return FirmMapTable[Id]
end

---@param Id integer
---@return MiniMapShowData
local function GetMiniMapData(Id)
    return MiniMapShowTable[tonumber(Id)]
end


--function WBP_Firm_Content:Initialize(Initializer)
--end

--function WBP_Firm_Content:PreConstruct(IsDesignTime)
--end
---配置读取 行列
local Row = 10
local Column = 10
---配置读取 缩放范围
local MinScale = 1
local MaxScale = 4
---固定鼠标滚轮缩放比率
local BaseRate = 0.1

---校正偏移量
local ReviseOffset = 0.1

---真实场景中坐标范围
local LocationBegin = UE.FVector(-2000.0, -1000.0, 0)
local LocationEnd = UE.FVector(4000.0, 4000.0, 0)

---初始参考坐标A,B
local InitLocBegin = UE.FVector(1000, 1500, 0)
local InitLocEnd = UE.FVector(4000, 4000, 0)

function WBP_Firm_Content:OnConstruct()

end

---@param MiniMap WBP_HUD_MiniMap
function WBP_Firm_Content:GetMiniMap(MiniMap)
    self.MiniMap = MiniMap
    if self.MiniMap == nil then
        G.log:error('gh_game', 'MiniMap is nil')
    end
end

---@param ShowId string
---@return FirmMapLegendType
function WBP_Firm_Content:GetFirmMapLegendTypeData (ShowId)
    return FirmUtil.GetMapLegendTypeDataById(ShowId)
end

---@param ShowId string
---@return FirmMapLegendData
function WBP_Firm_Content:GetFirmMapLegendData (ShowId)
    return FirmUtil.GetMapLegendOnlyDataById(self.MapId, ShowId)
end

function WBP_Firm_Content:GetMapLegendData ()
    return FirmUtil.GetMapLegendDataByMapId(self.MapId)
end

function WBP_Firm_Content:ResetAnchorData()
    if self.MarkerPointsItems and self.MultipleSelectionIndex then
        for i, v in pairs(self.MarkerPointsItems) do
            if v then
                v.bIsChecked = false
                v.AnchorItem.DX_Target_Selected:SetVisibility(UE.ESlateVisibility.Collapsed)
                self.MultipleSelectionIndex[v.SelectIconIndex].CheckedNum = 0
                self.MultipleSelectionIndex[v.SelectIconIndex].bIsChecked = false
            end
        end
    end
end

---@param Parent WBP_Firm_Map
---@param MapId string
function WBP_Firm_Content:Init(Parent, MapId)
    self.Parent = Parent
    self.LabelClickCallback = Parent.LabelClick
    self.FloatUIClickCallback = Parent.FloatLabelClick
    self.CustomUIClickCallback = self.Parent.OnClickMarkerPointsItem
    self.LabelOnHoverCallback = self.Parent.OnHoveredLabel
    self.LabelOnUnHoverCallback = self.Parent.OnUnHoveredLabel
    self.MapId = MapId
    self.LabelCount = 0
    if self:CurrentMapIdExists() then
        self.AnchorData = self:GetFirmAnchorData()
        self.MarkerPointsItems = {}
        self.MultipleSelectionIndex = {}
        Parent.Slider_round:SetValue(0)
        ---浮标相关预设
        self.PlayerFloatLabel = {}
        self.FloatLabelsUI = {}
        self.FloatKey = 0
        self.OutScreenPlayer = false
        self.bIsImportComplete = false
        local Data = GetFirmMapData(MapId)
        if Data then
            Row = Data.split_row
            Column = Data.split_column
            InitLocBegin.X = Data.location_begin[1]
            InitLocBegin.Y = Data.location_begin[2]
            InitLocEnd.X = Data.location_end[1]
            InitLocEnd.Y = Data.location_end[2]
            MinScale = Data.scale_max[1]
            MaxScale = Data.scale_max[2]
            self.GridIndexRow = Data.gridindex[1]
            self.GridIndexColumn = Data.gridindex[2]
            self.IconMergeDistance = Data.merging_distance
            self.AnchorUpperLimit = Data.anchor_limit
            self.ZoomClicked = Data.scale_number
            self.DefaultScaleValue = Data.default_scale
            self.RangeDistance = Data.range_target
        end
        self.Key = 0
        self.AnchorNum = 0
        self.ChildImages = {}
        self.MoveRate = 1
        self.GridsIndex = {}
        self.bShowMapOptions = false
        if self.DefaultScaleValue < MinScale or self.DefaultScaleValue > MaxScale then
            self.DefaultScaleValue = UE.UKismetMathLibrary.FClamp(self.DefaultScaleValue, MinScale, MaxScale)
        end
        ---3D场景中格子映射的大小
        local GridSizeX = math.abs(InitLocEnd.X - InitLocBegin.X)
        local GridSizeY = math.abs(InitLocEnd.Y - InitLocBegin.Y)
        local SceneSizeX = GridSizeX * Row
        local SceneSizeY = GridSizeY * Column

        local DifferNumRow = Row - self.GridIndexRow
        local DifferNumColumn = Column - self.GridIndexColumn

        local LocBeginX = InitLocEnd.X - self.GridIndexRow * GridSizeX
        local LocBeginY = InitLocEnd.Y - self.GridIndexColumn * GridSizeY
        local LocEndX = InitLocEnd.X + DifferNumRow * GridSizeX
        local LocEndY = InitLocEnd.Y + DifferNumColumn * GridSizeY
        LocationBegin = UE.FVector(LocBeginX, LocBeginY, 0)
        LocationEnd = UE.FVector(LocEndX, LocEndY, 0)
        for i = 1, Row do
            table.insert(self.ChildImages, {})
            for j = 1, Column do
                table.insert(self.ChildImages[i], {
                    Image = nil,
                    Labels = {}
                })
            end
        end
        for r = 1, Row do
            self.GridPanel_Image:SetRowFill(r - 1, 1)
        end
        for c = 1, Column do
            self.GridPanel_Image:SetColumnFill(c - 1, 1)
        end
        for r = 1, Row do
            for c = 1, Column do
                self:LoadChildImage(r, c)
                self.ChildImages[r][c].Labels = {}
            end
        end

        local ViewScale = UE.UWidgetLayoutLibrary.GetViewportScale(self)
        local ViewSize = UE.UWidgetLayoutLibrary.GetViewportSize(self)
        local ScreenSize = ViewSize / ViewScale
        self.ScreenSize = ScreenSize
        self.InitScreenCenterPos = UE.FVector2D(ScreenSize.X / 2, ScreenSize.Y / 2)
        self.ScreenPosCenter = UE.FVector2D(ScreenSize.X / 2, ScreenSize.Y / 2)
        local ContentSize = UE.FVector2D(ScreenSize.X, ScreenSize.Y)
        if ScreenSize.X > ScreenSize.Y then
            ContentSize.Y = ScreenSize.X * ((LocationEnd.Y - LocationBegin.Y) / (LocationEnd.X - LocationBegin.X))
        else
            ContentSize.X = ScreenSize.Y * ((LocationEnd.X - LocationBegin.X) / (LocationEnd.Y - LocationBegin.Y))
        end
        local Slot = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.ScaleBox_Content)
        Slot:SetSize(ContentSize)

        ---默认用屏幕大小
        self.ImageSize = ContentSize
        self.DifferY = self.ImageSize.Y - ScreenSize.Y
        ---初始视距范围是全地图
        self.ViewBegin = UE.FVector2D(0, 0)
        self.ViewEnd = UE.FVector2D(self.ImageSize.X, self.ImageSize.Y)
        self.InitViewCentrePosition = UE.FVector2D(self.ImageSize.X / 2, self.ImageSize.Y / 2)
        self.ViewCentrePosition = UE.FVector2D(self.ImageSize.X / 2, self.ImageSize.Y / 2)
        self.DifferCenter = self.InitViewCentrePosition - self.InitScreenCenterPos

        local PreSetScale = (LocationEnd.X - LocationBegin.X) / self.ImageSize.X
        self.MapScale=PreSetScale
        ---@type UTexture2D
        local ImageTexture = PicConst.GetPicResource(string.format("UI_Firm_%s_%d_%d", tostring(self.MapId), 0, 0))
        local WorldDistance = LocationEnd - LocationBegin
        self.PreSetScale = PreSetScale * (ImageTexture.ImportedSize.X * Row / WorldDistance.X)

        ---计算基础缩放率
        --self.BaseScale = (LocationEnd.X - LocationBegin.X) / ViewRange.X
        --self.CurrentScale = self.BaseScale
        local Scale = UE.FVector2D(1, 1) * PreSetScale
        self.ScaleBox_Content:SetRenderScale(Scale)
        self.BaseScale = self.PreSetScale * self.DefaultScaleValue
        self.CurrentScale = self.BaseScale
        local ScaleAfter = UE.FVector2D(1, 1) * self.BaseScale
        self.ScaleBox_Content:SetRenderScale(ScaleAfter)

        local DefaultSliderValue = (self.DefaultScaleValue * self.PreSetScale - MinScale * self.PreSetScale) / (MaxScale * self.PreSetScale - MinScale * self.PreSetScale)
        Parent.Slider_round:SetValue(DefaultSliderValue)
        local Value = Parent.Slider_round:GetValue()
        local SetSliderValue = function(Delta)
            if not self.bShowMapOptions then
                local Value = Parent.Slider_round:GetValue()
                if Delta < 0 then
                    if Value <= 0 then
                        return
                    end
                end
                Value = Value + Delta * (((MaxScale * self.PreSetScale - MinScale * self.PreSetScale) / self.ZoomClicked) / (MaxScale * self.PreSetScale - MinScale * self.PreSetScale))
                Value = UE.UKismetMathLibrary.FClamp(Value, 0, 1)
                Parent.Slider_round:SetValue(Value)
                self:BeginScale(Delta, nil, Value)
            end
        end
        Parent.Slider_round.OnValueChanged:Add(self, self.OnScaleValueChanged)
        Parent.WBP_CommonButton.OnClicked:Add(self, function()
            SetSliderValue(1)
        end)
        Parent.WBP_CommonButton_1.OnClicked:Add(self, function()
            SetSliderValue(-1)
        end)
        self.Labels = {}

        local Controller = UE.UGameplayStatics.GetPlayerController(self, 0)
        local PlayerLocation = Controller:K2_GetPawn():K2_GetActorLocation()
        local PlayerLegendId = FirmUtil.GetMapLegendIdByType(FirmMapLegendTypeTableConst.PlayerPosition)
        self:AddLabel(PlayerLocation, PlayerLegendId, FirmMapLegendTypeTableConst.PlayerPosition, true)
       
        self:InitLabel()
        SetSliderValue(0)
    end
end

function WBP_Firm_Content:InitLabel()
    self:AddLegendData()
end

---获取图标所属ActorId 便于传送
---@param ShowId string
function WBP_Firm_Content:GetLegendOwingActorId(ShowId)
    return FirmUtil.GetJsonActorIdByLegendId(self.MapId, ShowId)
end

function WBP_Firm_Content:AddLegendData()
    local MapLegendData = FirmUtil.GetMapLegendDataByMapId(self.MapId)
    for i, Legend in pairs(MapLegendData) do
        local Type = FirmUtil.GetMapLegendTypeDataById(Legend.Legend_ID).LegendType
        local ActorId = FirmUtil.GetJsonActorIdByLegendId(self.MapId, Legend.Legend_ID)
        local Location = UE.FVector(Legend.Legend_Positon[1], Legend.Legend_Positon[2], Legend.Legend_Positon[3])
        if Location then
            local Position = self:Location2Map2D(Location)
            if Position then
                self:AddLabel(Location, i, Type, false, nil, nil, ActorId)
              
            end
        end
    end
end
---打开地图播放区域名图标
function WBP_Firm_Content:PlayMapAreaLegends()
    if self.Labels then
        for i, v in ipairs(self.Labels) do
            if v.Type == FirmMapLegendTypeTableConst.BigAreaName or v.Type == FirmMapLegendTypeTableConst.SmallAreaName then
                if v.bIsVisible then
                    v:PlayAnimation(v.DX_DomainNameIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
                    v.IsPlayingAnim = true
                end
            end
        end
    end
end

---判断当前的地图Id是否有效
---@return boolean
function WBP_Firm_Content:CurrentMapIdExists()
    for i, v in pairs(FirmMapTable) do
        if self.MapId == i then
            return true
        end
    end
end

function WBP_Firm_Content:GetLeftIconPosition()
    local IconSlot = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.Parent.WBP_Common_TopContent.CanvasPanel_61)
    local IconPosition = IconSlot:GetPosition()
    if IconPosition then
        local AnchorPos = self:Location2Map2D(self.Location)
        if AnchorPos then
            local ViewPosX = (AnchorPos.X - self.ViewBegin.X) * self.CurrentScale
            local ViewPosY = (AnchorPos.Y - self.ViewBegin.Y) * self.CurrentScale
            local RelativeLocation = UE.FVector2D(IconPosition.X, IconPosition.Y)
            local IconSize = IconSlot:GetSize()
            local IconLeftPos = RelativeLocation
            local IconRightPos = UE.FVector2D(RelativeLocation.X + IconSize.X, RelativeLocation.Y + IconSize.Y)
            if ViewPosX >= IconLeftPos.X and ViewPosX <= IconRightPos.X and ViewPosY >= IconLeftPos.Y and ViewPosY <= IconRightPos.Y then
                return true
            else
                return false
            end
        end
    end
end

---@param Value float
function WBP_Firm_Content:OnScaleValueChanged(Value)
    self:BeginScale(nil, nil, Value)
end

function WBP_Firm_Content:OnHide()

end

function WBP_Firm_Content:OnShow()
    if self:CurrentMapIdExists() then
        --local Scale = UE.FVector2D(1, 1)*self.BaseScale
        --self.ScaleBox_Content:SetRenderScale(Scale)
        if self.PlayerLabel then
            local Controller = UE.UGameplayStatics.GetPlayerController(self, 0)
            local PlayerLocation = Controller:K2_GetPawn():K2_GetActorLocation()
            local Player = UE.UGameplayStatics.GetPlayerCharacter(self, 0)
            local PlayerRotation = Player:K2_GetActorRotation().Yaw
            self.PlayerLabel.Location2D = self:Location2Map2D(Controller:K2_GetPawn():K2_GetActorLocation())
            self.PlayerLabel:SetRenderTransformAngle(PlayerRotation + 90)
            self.PlayerLabel.Switch_Positioning:SetActiveWidgetIndex(2)

            self.PlayerLabel:PlayAnimation(self.PlayerLabel.DX_IconOnScreenLoop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1, false)
            
            self:MoveToLocation2D(self:Location2Map2D(PlayerLocation))
            self.PlayerIcon=self.PlayerLabel
        end
        self:CheckIconInZoomRange()
        --self:TrimLabel()
        self:PlayMapAreaLegends()
    end
end

---@param R integer
---@param C integer
function WBP_Firm_Content:LoadChildImage(R, C)
    local Child = self.ChildImages[R][C]
    if Child and Child.Image then
        return
    end
    ---@type WBP_FirmMapChildImage_C
    local ChildImage = UE.UWidgetBlueprintLibrary.Create(self, self.ChildImageClass)
    PicConst.SetImageBrush(ChildImage.Img_Map, string.format("UI_Firm_%s_%d_%d", tostring(self.MapId), R - 1, C - 1))
    ChildImage.TextBlock_Grid:SetText(string.format("%d , %d", R, C))
    ChildImage.TextBlock_Grid:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.GridPanel_Image:AddChildToGrid(ChildImage, R - 1, C - 1)
    self.ChildImages[R][C] = {
        Image = ChildImage,
        --Labels = {}
    }
end

---@param Location FVector
---@param ShowId string
---@param Type integer
---@param IsPlayer boolean @optional
---@param PicKey string
---@param AnchorName string
---@param ActorId string
---@param Mission MissionObject
function WBP_Firm_Content:AddLabel(Location, ShowId, Type, IsPlayer, PicKey, AnchorName, ActorId, Mission)
    local TempId = self.Key + 1
    self.Key = self.Key + 1
    ---@type WBP_FirmMapLabel
    local Label = nil
   
    if self.bIsOnClickedBlank and Type == FirmMapLegendTypeTableConst.Anchor then

        ---@type WBP_FirmMapLabel
        self.CustomUI = UE.UWidgetBlueprintLibrary.Create(self, self.LabelClass)
        Label = self.CustomUI
        self.CustomUI:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        local Location2D = self:Location2Map2D(Location)
        self.CustomUI:SetRenderTranslation(Location2D)
        self.CustomUI.TempId = TempId
        self.CustomUI.Location2D = Location2D
        self.CustomUI.IsTrace = false
        self.CustomUI.OutScreen = false
        self.CustomUI.GridLocation = self:CalcIconIsInTheGrid(self.CustomUI)
        self.CustomUI.ShowId = ShowId
        self.CustomUI.PicKey = PicKey
        self.CustomUI.bIsAdd = false
        self.CustomUI.bIsVisible = true
        self.CustomUI.IsAnchor = true
        self.CustomUI.Type = Type
        self.CustomUI.Location = Location
        self.CustomUI.Switch_Positioning:SetActiveWidgetIndex(0)
        self.CustomUI.Switch_TeleportIcon:SetActiveWidgetIndex(1)
        self.CustomUI.Img_PositioningBG:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.CustomUI.Img_TargetArrow:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.CustomUI.Canvas_DomainName:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.CustomUI.WBP_HUD_Task_Icon:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.CustomUI.EFF_1:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.CustomUI.EFF_4:SetVisibility(UE.ESlateVisibility.Collapsed)
        PicConst.SetImageBrush(self.CustomUI.Icon_CustomMark, tostring(PicKey))
        table.insert(self.Labels, self.CustomUI)

        self.CanvasPanel_Content:AddChildToCanvas(self.CustomUI)

        local CustomUISlot = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.CustomUI)
        CustomUISlot:SetPosition(-CustomUISlot:GetSize() / 2)

        self.CustomUI.WBP_Map_PositioningTeleport.OnClicked:Add(self, function()
            if self.CustomUIClickCallback then
                self.CustomUIClickCallback(self.Parent, self.Labels, TempId)
            end
        end)
    else
      
        ---@type WBP_FirmMapLabel
        local LabelUI = UE.UWidgetBlueprintLibrary.Create(self, self.LabelClass)
        Label = LabelUI
        LabelUI:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        local Location2D = self:Location2Map2D(Location)
        LabelUI:SetRenderTranslation(Location2D)
        LabelUI.Location2D = Location2D
        LabelUI.GridLocation = self:CalcIconIsInTheGrid(LabelUI)
        LabelUI.bIsVisible = true
        LabelUI.IsTrace = false
        LabelUI.OutScreen = false
        LabelUI.ShowId = ShowId
        LabelUI.TempId = TempId
        LabelUI.IsAnchor = false
        LabelUI.Mission = Mission
        LabelUI.ActorId = ActorId
        LabelUI.Type = Type
        LabelUI.Location = Location
        LabelUI.IsPlayingAnim = false
        LabelUI.WBP_HUD_Task_Icon:SetVisibility(UE.ESlateVisibility.Collapsed)
        LabelUI.EFF_4:SetVisibility(UE.ESlateVisibility.Collapsed)
        LabelUI.EFF_1:SetVisibility(UE.ESlateVisibility.Collapsed)

        if ShowId ~= nil then
            
            self.MapIconData = self:GetMapIconData()
            LabelUI.Switch_Positioning:SetActiveWidgetIndex(0)
            LabelUI.Switch_TeleportIcon:SetActiveWidgetIndex(0)
            LabelUI.Switch_TeleportState:SetActiveWidgetIndex(0)
            LabelUI.Img_PositioningBG:SetVisibility(UE.ESlateVisibility.Collapsed)
            LabelUI.Img_TargetArrow:SetVisibility(UE.ESlateVisibility.Collapsed)
            LabelUI.Canvas_DomainName:SetVisibility(UE.ESlateVisibility.Collapsed)
            if Mission then
                self.CurTraceItem = LabelUI
                LabelUI.IsTrace = nil
                local TrackType = Mission:GetMissionType()
                local TrackState = Mission:GetMissionTrackIconType()
                LabelUI.WBP_HUD_Task_Icon:SetVisibility(UE.ESlateVisibility.Visible)
                LabelUI.Canvas_DomainName:SetVisibility(UE.ESlateVisibility.Collapsed)
                LabelUI.Switch_Positioning:SetVisibility(UE.ESlateVisibility.Collapsed)
                LabelUI.Img_PositioningBG:SetVisibility(UE.ESlateVisibility.Collapsed)
                LabelUI.Img_TargetArrow:SetVisibility(UE.ESlateVisibility.Collapsed)
                IconUtility:SetTaskIcon(LabelUI.WBP_HUD_Task_Icon, TrackType, TrackState - 1)
                self:RenderLabel(LabelUI)
                
            end
            local TypeId = FirmUtil.GetMapLegendIdByType(Type)
            if self.MapIconData[tonumber(TypeId)].Icon == nil then
                if Type == FirmMapLegendTypeTableConst.BigAreaName or Type == FirmMapLegendTypeTableConst.SmallAreaName then
                    LabelUI:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
                    local NameData = FirmUtil.GetMapLegendOnlyDataById(self.MapId, ShowId).Legend_Name
                    if NameData == "" or NameData == nil then
                        --NameData = self:GetFirmMapLegendTypeData(TypeId).Legend_Name
                        NameData = FirmUtil.GetMapLegendTypeDataById(TypeId).Legend_Name
                    end
                    local TitleName = ConstText.GetConstText(NameData)
                    if TitleName then
                        LabelUI.Txt_DomainName:SetText(TitleName)
                        LabelUI.Img_TargetArrow:SetVisibility(UE.ESlateVisibility.Collapsed)
                        LabelUI.Img_PositioningBG:SetVisibility(UE.ESlateVisibility.Collapsed)
                        LabelUI.Txt_ExploratoryDegree:SetVisibility(UE.ESlateVisibility.Collapsed)
                        LabelUI.Canvas_DomainName:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                        LabelUI.Switch_Positioning:SetVisibility(UE.ESlateVisibility.Collapsed)
                    end
                end
                
            else
                PicConst.SetImageBrush(LabelUI.Icon_Teleport, self.MapIconData[tonumber(TypeId)].Icon)
               
            end
           
            table.insert(self.Labels, LabelUI)
            self.CanvasPanel_Content:AddChildToCanvas(LabelUI)
           

            local LabelUISlot = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(LabelUI)
            LabelUISlot:SetPosition(-LabelUISlot:GetSize() / 2)
            local LabelButtonSlot = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(LabelUI.WBP_Map_PositioningTeleport)

            if IsPlayer then
                self.PlayerLabel = LabelUI
                
            end
            LabelUI.WBP_Map_PositioningTeleport.OnClicked:Add(self, function()
                if self.LabelClickCallback then
                    self.LabelClickCallback(self.Parent, LabelUI, self.MapIconData, ShowId, self.Labels, ActorId, IsPlayer)
                end
            end)
            LabelUI.WBP_Map_PositioningTeleport.OnHovered:Add(self, function()
                if self.LabelOnHoverCallback then
                    self.LabelOnHoverCallback(self.Parent, LabelUI, Type)
                end
            end)
            LabelUI.WBP_Map_PositioningTeleport.OnUnhovered:Add(self, function()
                if self.LabelOnUnHoverCallback then
                    self.LabelOnUnHoverCallback(self.Parent, LabelUI, Type)
                end
            end)
        end
    end
    if Label then
        self.LabelCount = self.LabelCount + 1
        ---@type UCanvasPanelSlot
        local Slot = Label.Slot
        local ZOrder = FirmUtil.GetZOrder(Label, self.LabelCount)
        Slot:SetZOrder(ZOrder)
    
        if Label.Type == FirmMapLegendTypeTableConst.PlayerPosition then
            Label:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
         
        end
    end
--self.Testlhj()
    self:CheckLabelInScreen()
end

---@param R integer
---@param C integer
function WBP_Firm_Content:UnLoadChildImage(R, C)
    local Child = self.ChildImages[R][C]
    if not Child then
        return
    end
    self.GridPanel_Image:RemoveChild(Child.Image)
    self.ChildImages[R][C] = {
        Image = nil,
        Labels = {}
    }

end

function WBP_Firm_Content:OnMouseWheel(MyGeometry, MouseEvent)
    local Delta = UE.UKismetInputLibrary.PointerEvent_GetWheelDelta(MouseEvent)
    if not self.bShowMapOptions then
        self:BeginScale(Delta, BaseRate)
        self:ReviseTranslation()
    end
    
    return UE.UWidgetBlueprintLibrary.Handled()
end

---The system calls this method to notify the widget that a mouse button was release within it. This event is bubbled.
---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
---@return FEventReply
function WBP_Firm_Content:OnMouseButtonUp(MyGeometry, MouseEvent)
    self.bMouseDown = false
    if not self.bDrag then
        local Key = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)
        if Key.KeyName == "LeftMouseButton" then
            self:ClickBlank()
        end
        
    end
    
    self.bDrag = false
    return UE.UWidgetBlueprintLibrary.Handled()
end

---The system calls this method to notify the widget that a mouse button was pressed within it. This event is bubbled.
---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
---@return FEventReply
function WBP_Firm_Content:OnMouseButtonDown(MyGeometry, MouseEvent)
    self.bMouseDown = true
    return UE.UWidgetBlueprintLibrary.Handled()
   
end

---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
---@return FEventReply
function WBP_Firm_Content:OnMouseMove(MyGeometry, MouseEvent)
    if not self.bMouseDown then
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    local Delta = UE.UKismetInputLibrary.PointerEvent_GetCursorDelta(MouseEvent)
    local MoveRate = 0.8
    if not self.bShowMapOptions then
        self:BeginMove(Delta, MoveRate)
       
    end
    
    return UE.UWidgetBlueprintLibrary.Handled()
end

---获取地图图标显示数据
function WBP_Firm_Content:GetMapIconData()
    ---@type MapIconData[]
    local MapIconData = {}
    local MapTypeData = FirmUtil.GetMapLegendTypeData()
    for i, j in pairs(MapTypeData) do
        local LegendElement = {
            Icon = j.Legend_Icon,
            bIsSelected = false,
            bIsRewards = (j.LegendType == FirmMapLegendTypeTableConst.Playpoint or j.LegendType == FirmMapLegendTypeTableConst.Task),
            bIsTrace = (j.LegendType == FirmMapLegendTypeTableConst.Playpoint or j.LegendType == FirmMapLegendTypeTableConst.Task)
        }
        MapIconData[i] = LegendElement
    end
    return MapIconData
end

function WBP_Firm_Content:GetFirmAnchorData()
    local Type = nil
    local AnchorShowId = nil
    local Data = GetFirmMapData(self.MapId)
    if Data then
        self.FirmAnchorData = Data.icon_index
        Type = FirmMapLegendTypeTableConst.Anchor
    end
    local MapTypeData = FirmUtil.GetMapLegendTypeData()
    for i, v in pairs(MapTypeData) do
        if v.LegendType == Type then
            AnchorShowId = i
            break
        end
    end
    ---@type FirmAnchorData[]
    local AnchorDataList = {}
    for i, v in ipairs(self.FirmAnchorData) do
        local Element = { PicKey = v, bIsSelected = (i == 1), ShowId = AnchorShowId }
        table.insert(AnchorDataList, Element)
    end
    return AnchorDataList
end

function WBP_Firm_Content:IsAllValuesEmpty()
    for key, value in pairs(self.MarkerPointsItems) do
        if value then
            return false
        end
    end
    return true
end

---点击空白地方，非拖拽
function WBP_Firm_Content:ClickBlank()
    local Location2D = self:GetMap2DByMouse()
    self:OnClickedPosition(Location2D, self:Map2D2Location(Location2D))
end

---@param Location2D FVector2D
---@param Location FVector
function WBP_Firm_Content:OnClickedPosition(Location2D, Location)
    
    self.Location2D = Location2D
    self.Location = Location
    self.bIsOnClickedBlank = true
    if self.Parent.WBP_Firm_MapHeadline.bIsClicked then
        self.Parent.WBP_Firm_MapHeadline.Canvas_MapHeadline:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Parent.WBP_Firm_MapHeadline.bIsClicked = false
    end
    if self.bIsOpenCustomInterface then
        self.Parent:HideRightPopupWindow()
        self.bIsOpenCustomInterface = false
    end
    G.log:debug("xuexiaoyu", "WBP_Firm_Content:ClickBlank %s %s %s",tostring(self.Parent.IsRightPopupVisible),tostring(self.Parent.bIsDetailPopup),tostring(self.Parent.bIsAnchorPopup))
    if self.Parent.IsRightPopupVisible == false and self.Parent.bIsDetailPopup == false and self.Parent.bIsAnchorPopup == false then
        G.log:debug("xuexiaoyu", "WBP_Firm_Content:ClickBlank %s %s",tostring(self:GetLeftIconPosition()),tostring(self.bIsImportComplete))
        if self:GetLeftIconPosition() ~= true and self.bIsImportComplete == false then
            UE.UAkGameplayStatics.PostEvent(self.OnClickBlankAkEvent, UE.UGameplayStatics.GetPlayerPawn(self, 0), nil, nil, true)
            self.Parent:ShowRightPopupWindow()
            self.bIsOpenCustomInterface = true
            self.Parent.WBP_Firm_SidePopupWindow.bIsOnClickedAnchor = false
            local SwitcherIndex = 1
            self.Parent.WBP_Firm_SidePopupWindow:InitPopupWindowData(SwitcherIndex, self)
        end
        
    else
        self.Parent:HideRightPopupWindow()
        self:ResetAnchorData()
        self.Parent.bIsDetailPopup = false
        self.Parent.IsRightPopupVisible = false
        self.Parent.bIsAnchorPopup = false
        self.Parent.bIsTransmitOffice = false
        if self.Parent.WBP_Firm_SidePopupWindow.PreviousAnchor ~= nil then
            self.Parent.WBP_Firm_SidePopupWindow.PreviousAnchor.DX_Target_Selected:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
        
    end
    self.Pos = self.Location2D
    if self.Parent.Firm_MapOptions ~= nil then
        self.Parent.Firm_MapOptions:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.bShowMapOptions = false
       
    end
    local bIsChecked = false
    local TotalNum = 0
    local CheckedNum = 0
    if self:IsAllValuesEmpty() then
        for i, v in ipairs(self.AnchorData) do
            local MarkerItem = {}
            MarkerItem.PicKey = self.AnchorData[i].PicKey
            MarkerItem.bIsChecked = bIsChecked
            MarkerItem.TotalNum = TotalNum
            MarkerItem.CheckedNum = CheckedNum
            self.MultipleSelectionIndex[MarkerItem.PicKey] = MarkerItem
        end
       
    end
   
end

---@param FirmMarkerPointsItem WBP_FirmMapLabel
---@param CurrentSelectedAnchorItemPicKey string
---@param Position FVector2D
---@param AnchorName string
---@param ShowId integer
function WBP_Firm_Content:OnClickedCommit(FirmMarkerPointsItem, CurrentSelectedAnchorItemPicKey, Position, AnchorName, ShowId)
    local MapData = {}
    MapData.TempId = FirmMarkerPointsItem.TempId
    MapData.ShowId = ShowId
    MapData.AnchorItem = FirmMarkerPointsItem
    MapData.SelectIconIndex = CurrentSelectedAnchorItemPicKey
    MapData.PositionX = Position.X
    MapData.PositionY = Position.Y
    MapData.AnchorName = AnchorName
    MapData.bIsChecked = false
    MapData.bIsTrace = false
    self.MarkerPointsItems[MapData.TempId] = MapData
    for i, v in ipairs(self.Labels) do
        if MapData.TempId == v.TempId then
            v.AnchorName = AnchorName
            v.bIsAdd = true
        end
    end
    self.Parent.WBP_Firm_SidePopupWindow.bKeepMarkerVisible = true
    self.bIsOpenCustomInterface = false
    self.Parent.bIsAnchorPopup = false
   
end

---获取相邻的格子
---@param CurRow integer
---@param CurColumn integer
function WBP_Firm_Content:GetAdjacentCells(CurRow, CurColumn)
    local AdjacentCells = {}
    -- 左边的格子
    if CurColumn > 1 then
        table.insert(AdjacentCells, { CurRow, CurColumn - 1 })
    end
    -- 右边的格子
    if CurColumn < Column then
        table.insert(AdjacentCells, { CurRow, CurColumn + 1 })
    end
    -- 上面的格子
    if CurRow > 1 then
        table.insert(AdjacentCells, { CurRow - 1, CurColumn })
    end
    -- 下面的格子
    if CurRow < Row then
        table.insert(AdjacentCells, { CurRow + 1, CurColumn })
    end
    -- 左上角的格子
    if CurColumn > 1 and CurRow > 1 then
        table.insert(AdjacentCells, { CurRow - 1, CurColumn - 1 })
    end
    -- 右上角的格子
    if CurColumn < Column and CurRow > 1 then
        table.insert(AdjacentCells, { CurRow - 1, CurColumn + 1 })
    end
    -- 左下角的格子
    if CurColumn > 1 and CurRow < Row then
        table.insert(AdjacentCells, { CurRow + 1, CurColumn - 1 })
    end
    -- 右下角的格子
    if CurColumn < Column and CurRow < Row then
        table.insert(AdjacentCells, { CurRow + 1, CurColumn + 1 })
    end
    return AdjacentCells
end

---计算图标在格子范围内
---@param Label WBP_FirmMapLabel
function WBP_Firm_Content:CalcIconIsInTheGrid(Label)
    
    local GridIconData = {}
    if Label ~= nil then
        local LabelLocation = Label.Location2D
        if LabelLocation ~= nil then
            ---缩放时的格子大小
            local GridWidth = self.ImageSize.X / Column
            local GridHeight = self.ImageSize.Y / Row
            for r = 1, Row do
                for c = 1, Column do
                    local GridLeftPosX = ((c - 1) * GridWidth)
                    local GridLeftPosY = ((r - 1) * GridHeight)
                    if LabelLocation.X >= GridLeftPosX and LabelLocation.X < GridLeftPosX + GridWidth and LabelLocation.Y >= GridLeftPosY and LabelLocation.Y < GridLeftPosY + GridHeight then
                        table.insert(self.ChildImages[r][c].Labels, Label)
                        return UE.FIntPoint(r, c)
                    end
                end
            end
        end
    end
    
end

---按照图标的所在的缩放范围显示
function WBP_Firm_Content:CheckIconInZoomRange()
    local UniqueCells = self.UniqueCells
    if UniqueCells and #UniqueCells > 0 then
        for i = 1, #UniqueCells do
            local row = self.UniqueCells[i][1]
            local column = self.UniqueCells[i][2]
            self:CheckIconInGridData(row, column)
        end
    end

end

---@param Row integer
---@param Column integer
function WBP_Firm_Content:CheckIconInGridData(Row, Column)
    local Labels = self.ChildImages[Row][Column].Labels
    if Labels ~= nil then
        for j, value in ipairs(Labels) do
            if value.Type ~= FirmMapLegendTypeTableConst.PlayerPosition and value.Mission == nil then
                local LegendTypeData
                if value.Type == FirmMapLegendTypeTableConst.Anchor then
                    LegendTypeData = FirmUtil.GetMapLegendTypeDataById(value.ShowId)
                else
                    local LegendData = FirmUtil.GetMapLegendOnlyDataById(self.MapId, value.ShowId)
                    if LegendData then
                        local LegendId = LegendData.Legend_ID
                        LegendTypeData = FirmUtil.GetMapLegendTypeDataById(LegendId)
                    end
                end
                local ScaleMin = LegendTypeData.Legend_Scale[1]
                local ScaleMax = LegendTypeData.Legend_Scale[2]
                local bIsScaleInRange = self.CurrentScale >= ScaleMin * self.PreSetScale and self.CurrentScale <= ScaleMax * self.PreSetScale
                if bIsScaleInRange then
                    value.bIsVisible = true
                    if value.Type == FirmMapLegendTypeTableConst.BigAreaName or value.Type == FirmMapLegendTypeTableConst.SmallAreaName then
                        if value.IsPlayingAnim == false then
                            value:StopAnimation(value.DX_DomainNameOut)
                            if self.Parent.Slider_round:GetValue() > 0 then
                                value:PlayAnimation(value.DX_DomainNameIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
                                value:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
                                value.IsPlayingAnim = true
                            end 
                        end
                        value:StopAnimation(value.DX_DomainNameOut)
                        value:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
                    else
                        if value.Type == FirmMapLegendTypeTableConst.Anchor then
                            value.Icon_CustomMark:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                        end
                        value:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                    end
                else
                    if value.Type == FirmMapLegendTypeTableConst.BigAreaName or value.Type == FirmMapLegendTypeTableConst.SmallAreaName then
                        if value.IsPlayingAnim == true then
                            value:StopAnimation(value.DX_DomainNameIn)
                            value:PlayAnimation(value.DX_DomainNameOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
                            value:SetVisibility(UE.ESlateVisibility.Collapsed)
                            value.IsPlayingAnim = false
                        end
                        value:SetVisibility(UE.ESlateVisibility.Collapsed)
                    else
                        value:SetVisibility(UE.ESlateVisibility.Collapsed)
                    end
                    value.bIsVisible = false
                end
            end
        end
    else
        return
    end
end

-- ---检查地图上的图标是否重叠
-- ---@param Icon1 WBP_FirmMapLabel
-- ---@param Icon2 WBP_FirmMapLabel
-- ---@return boolean
-- function WBP_Firm_Content:CheckOverlap(Icon1, Icon2)
--     ---图标大小
--     local CanvasSlot = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(Icon1.WBP_Map_PositioningTeleport)
--     local SizeX = CanvasSlot:GetSize().X
--     local SizeY = CanvasSlot:GetSize().Y

--     local Icon1X = tonumber(string.format("%.3f", ((Icon1.Location2D.X - self.ViewBegin.X) * self.CurrentScale)))
--     local Icon1Y = tonumber(string.format("%.3f", ((Icon1.Location2D.Y - self.ViewBegin.Y) * self.CurrentScale)))
--     local Icon2X = tonumber(string.format("%.3f", ((Icon2.Location2D.X - self.ViewBegin.X) * self.CurrentScale)))
--     local Icon2Y = tonumber(string.format("%.3f", ((Icon2.Location2D.Y - self.ViewBegin.Y) * self.CurrentScale)))
--     if Icon1X < (Icon2X + SizeX) and (Icon1X + SizeX) > Icon2X and Icon1Y < (Icon2Y + SizeY) and Icon1Y > (Icon2Y - SizeY) then
--         return true
--     else
--         return false
--     end
-- end

-- ---重叠之后的显示逻辑,已废弃
-- ---@param Row integer
-- ---@param Column integer
-- function WBP_Firm_Content:CheckIconOverlapOnMap(Row, Column)
--     local function compareLabels(a, b)
--         return tonumber(a.ShowId) < tonumber(b.ShowId)
--     end
--     if Row ~= nil and Column ~= nil then
--         if self.ChildImages[Row][Column].Labels ~= nil then
--             table.sort(self.ChildImages[Row][Column].Labels, compareLabels)
--             for i = 1, #self.ChildImages[Row][Column].Labels do
--                 local Icon1 = self.ChildImages[Row][Column].Labels[i]
--                 if Icon1 and Icon1.bIsVisible then
--                     for j = i + 1, #self.ChildImages[Row][Column].Labels do
--                         local Icon2 = self.ChildImages[Row][Column].Labels[j]
--                         if Icon2 and Icon2.bIsVisible then
--                             if self:CheckOverlap(Icon1, Icon2) then
--                                 self:ProcessingIconDisplay(Icon1, Icon2)
--                             end
--                         end
--                     end
--                 end
--             end
--         end
--     end
-- end

---@param Icon WBP_FirmMapLabel
function WBP_Firm_Content:GetIconTypeData(Icon)
    if Icon then
        if Icon.Type == FirmMapLegendTypeTableConst.PlayerPosition or Icon.Type == FirmMapLegendTypeTableConst.Anchor then
            return self:GetFirmMapLegendTypeData(Icon.ShowId)
        else
            local IconData = self:GetFirmMapLegendData(Icon.ShowId)
            if IconData then
                local IconId = IconData.Legend_ID
                return self:GetFirmMapLegendTypeData(IconId)
            end

        end
    end
end

-- ---@param Icon1 WBP_FirmMapLabel
-- ---@param Icon2 WBP_FirmMapLabel
-- function WBP_Firm_Content:ProcessingIconDisplay(Icon1, Icon2)
--     if Icon1 ~= nil and Icon2 ~= nil then
--         if Icon1.Type ~= FirmMapLegendTypeTableConst.PlayerPosition and Icon2.Type ~= FirmMapLegendTypeTableConst.PlayerPosition and Icon1.Mission == nil and Icon2.Mission == nil then
--             local Icon1Data = self:GetIconTypeData(Icon1)
--             local Icon2Data = self:GetIconTypeData(Icon2)
--             if Icon1Data and Icon2Data then
--                 if (not Icon1Data.Legend_Priority or Icon1Data.Legend_Priority == 0) and (not Icon2Data.Legend_Priority or Icon2Data.Legend_Priority == 0) then
--                 elseif not Icon1Data.Legend_Priority or Icon1Data.Legend_Priority == 0 then
--                     Icon1:SetVisibility(UE.ESlateVisibility.Collapsed)
--                     Icon2:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
--                     Icon1.bIsVisible = false
--                     Icon2.bIsVisible = true
--                 elseif not Icon2Data.Legend_Priority or Icon2Data.Legend_Priority == 0 then
--                     Icon1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
--                     Icon2:SetVisibility(UE.ESlateVisibility.Collapsed)
--                     Icon1.bIsVisible = true
--                     Icon2.bIsVisible = false
--                 elseif Icon1Data.Legend_Priority < Icon2Data.Legend_Priority then
--                     Icon1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
--                     Icon2:SetVisibility(UE.ESlateVisibility.Collapsed)
--                     Icon1.bIsVisible = true
--                     Icon2.bIsVisible = false
--                 elseif Icon1Data.Legend_Priority == Icon2Data.Legend_Priority then
--                     Icon1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
--                     Icon2:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
--                     Icon1.bIsVisible = true
--                     Icon2.bIsVisible = true
--                 else
--                     Icon1:SetVisibility(UE.ESlateVisibility.Collapsed)
--                     Icon2:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
--                     Icon1.bIsVisible = false
--                     Icon2.bIsVisible = true
--                 end
--             end
--         end

--     end
-- end
---@param AxisValue float
---@param ScaleRate float @optional
---@param CurrentScaleProgress float @optional
function WBP_Firm_Content:BeginScale(AxisValue, ScaleRate, CurrentScaleProgress)
    if CurrentScaleProgress then
        local CurrentMaxScale = MaxScale * self.PreSetScale
        local InitProgressValue = (self.DefaultScaleValue * self.PreSetScale - MinScale * self.PreSetScale) / (MaxScale * self.PreSetScale - MinScale * self.PreSetScale)
        self.CurrentScale = MinScale * self.PreSetScale + CurrentScaleProgress * (MaxScale * self.PreSetScale - MinScale * self.PreSetScale)
        if self.CurrentScale < 1 then
            self.CurrentScale = UE.UKismetMathLibrary.FClamp(self.CurrentScale, 1, CurrentMaxScale)
        end
    else
        local CurrentMaxScale = MaxScale * self.PreSetScale
        local CurrentMinScale = MinScale * self.PreSetScale
        if CurrentMinScale < 1 then
            CurrentMinScale = 1
        end
        ScaleRate = ScaleRate or BaseRate
        local OldScale = self.CurrentScale
        local ScaleSpan = CurrentMaxScale - CurrentMinScale
        self.CurrentScale = self.CurrentScale + AxisValue * ScaleRate * ScaleSpan
        self.CurrentScale = UE.UKismetMathLibrary.FClamp(self.CurrentScale, CurrentMinScale, CurrentMaxScale)
        local SliderValue = (self.CurrentScale - CurrentMinScale) / ScaleSpan
        self.Parent.Slider_round:SetValue(SliderValue)
    end
    local OldScreenCentrePosition = UE.FVector2D(self.ScreenPosCenter.X, self.ScreenPosCenter.Y)

    local Scale = UE.FVector2D(1, 1) * self.CurrentScale
    self.ScaleBox_Content:SetRenderScale(Scale)
    self:CalcViewRange()
    self:CheckTranslate()
    ---围绕ViewCentrePosition来缩放，所以需要计算偏移量
    local Delta = self.ScreenPosCenter - OldScreenCentrePosition
    Delta = Delta * self.CurrentScale
    local Translation = self.ScaleBox_Content.RenderTransform.Translation
    Translation = Translation + Delta
    local Min, Max = self:GetTranslationRange()

    Translation.X = UE.UKismetMathLibrary.FClamp(Translation.X, Min.X, Max.X)
    Translation.Y = UE.UKismetMathLibrary.FClamp(Translation.Y, Min.Y, Max.Y)

    self.ScaleBox_Content:SetRenderTranslation(Translation)

    self:CalcViewRange()
    self:CalcGridLoad()
    self:CheckLabelInScreen()
    self:CheckIconInZoomRange()
    if CurrentScaleProgress and CurrentScaleProgress > 0 then
        self:ReviseTranslation()
    end
    
end

---校正缝隙问题
---@private
function WBP_Firm_Content:ReviseTranslation()
    local Self = self
    UE.UKismetSystemLibrary.K2_SetTimerForNextTickDelegate({ self, function()
        if not UE.UKismetSystemLibrary.IsValid(Self) then
            return
        end
        local Translation = Self.ScaleBox_Content.RenderTransform.Translation
        Translation.X = Translation.X + ReviseOffset
        Translation.Y = Translation.Y + ReviseOffset
        Self.ScaleBox_Content:SetRenderTranslation(Translation)
    end })
end

---计算视觉范围
---@private
function WBP_Firm_Content:CalcViewRange()
    ---计算中心点
    local Translation = self.ScaleBox_Content.RenderTransform.Translation

    self.ViewCentrePosition = self.InitViewCentrePosition - Translation / self.CurrentScale
    self.ViewBegin = UE.FVector2D(math.abs(self.ViewCentrePosition.X - self.ImageSize.X / (2 * self.CurrentScale)), math.abs(self.ViewCentrePosition.Y - self.ImageSize.Y / (2 * self.CurrentScale)))
    self.ViewEnd = UE.FVector2D(math.abs(self.ViewCentrePosition.X + self.ImageSize.X / (2 * self.CurrentScale)), math.abs(self.ViewCentrePosition.Y + self.ImageSize.Y / (2 * self.CurrentScale)))
    local ScreenPosX = math.abs(self.ViewBegin.X + self.ScreenSize.X / (2 * self.CurrentScale))
    local ScreenPosY = math.abs(self.ViewBegin.Y + self.ScreenSize.Y / (2 * self.CurrentScale))
    self.ScreenPosCenter = UE.FVector2D(ScreenPosX, ScreenPosY)
end

---@param AxisValue FVector2D
---@param MoveRate float @optional
---@return void
function WBP_Firm_Content:BeginMove(AxisValue, MoveRate)
    if math.abs(AxisValue.X) < self.ClickOffset and math.abs(AxisValue.Y) < self.ClickOffset then
        return
    end
    self.bDrag = true
    if self.Parent.WBP_Firm_MapHeadline.bIsClicked then
        self.Parent.WBP_Firm_MapHeadline.Canvas_MapHeadline:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Parent.WBP_Firm_MapHeadline.bIsClicked = false
    end
    MoveRate = MoveRate or 1
    MoveRate = self.MoveRate * MoveRate
    local Translation = self.ScaleBox_Content.RenderTransform.Translation
    local OldTranslation = UE.FVector2D(Translation.X, Translation.Y)
    Translation.X = Translation.X + AxisValue.X * MoveRate
    Translation.Y = Translation.Y + AxisValue.Y * MoveRate

    local Min, Max = self:GetTranslationRange()

    Translation.X = UE.UKismetMathLibrary.FClamp(Translation.X, Min.X, Max.X)
    Translation.Y = UE.UKismetMathLibrary.FClamp(Translation.Y, Min.Y, Max.Y)

    if Translation.X == OldTranslation.X and Translation.Y == OldTranslation.Y then
        return
    end

    self.ScaleBox_Content:SetRenderTranslation(Translation)

    self:CalcViewRange()
    self:CalcGridLoad()
    self:ReviseTranslation()
    self:CheckLabelInScreen()


end



---检查图标是否在视口之外
function WBP_Firm_Content:CheckLabelInScreen()
    
    ---检查玩家图标位置
    if self.PlayerLabel then
        if self:IfOutScreen(self.PlayerLabel.Location2D) then
            local PlayerLabel = self.PlayerFloatLabel
            self:AddFloat(self.PlayerLabel.Location2D, self.PlayerLabel)
           
        else
            if self.PlayerLabel and self.PlayerLabel.FloatUI ~= nil then
                if self.OutScreenPlayer then
                    self.OutScreenPlayer = false
                    self.PlayerLabel.FloatUI:StopAnimation(self.PlayerLabel.FloatUI.DX_IconIn)
                    self.PlayerLabel.FloatUI:PlayAnimation(self.PlayerLabel.FloatUI.DX_IconOffScreenLoopStop, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
                    self.PlayerLabel.FloatUI:PlayAnimation(self.PlayerLabel.FloatUI.DX_IconOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
                    if self.DelayTimer == nil then
                        local DelayTime = self.PlayerLabel.FloatUI.DX_IconOut:GetEndTime()
                        UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, function()
                            self.PlayerLabel.FloatUI:SetVisibility(UE.ESlateVisibility.Collapsed)
                        end }, DelayTime, false)
                    end
                end
                self.PlayerLabel.FloatUI.Location2D = nil
                
            end
        end
      
    end

    ---功能性地标
    local LandMark = self.Labels

    for i, v in ipairs(self.Labels) do
        local Item = LandMark[i]
        local MarkPos = Item.Location2D
        if Item.IsTrace then
          
            if self:IfOutScreen(MarkPos) then
                self:AddFloat(MarkPos, Item)
            else
                if Item.FloatUI ~= nil then
                    if Item.OutScreen then
                        Item.OutScreen = false
                        Item.FloatUI:StopAnimation(Item.FloatUI.DX_IconIn)
                        Item.FloatUI:PlayAnimation(Item.FloatUI.DX_IconOffScreenLoopStop, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
                        Item.FloatUI:PlayAnimation(Item.FloatUI.DX_IconOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
                        if self.DelayTimer_Normal == nil then
                            local DelayTime = Item.FloatUI.DX_IconOut:GetEndTime()
                            UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, function()
                                Item.FloatUI:SetVisibility(UE.ESlateVisibility.Collapsed)
                            end }, DelayTime, false)
                        end
                    end
                    Item.FloatUI.Location2D = nil
                end
            end
        elseif Item.Mission then
           
            if self:IfOutScreen(MarkPos) then
                self:AddFloat(MarkPos, Item)
                
            else
               
                if Item.FloatUI ~= nil then
                    if Item.OutScreen then
                        Item.OutScreen = false
                        Item.FloatUI:StopAnimation(Item.FloatUI.DX_IconIn)
                        Item.FloatUI:PlayAnimation(Item.FloatUI.DX_IconOffScreenLoopStop, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
                        Item.FloatUI:PlayAnimation(Item.FloatUI.DX_IconOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
                        if self.DelayTimer_Normal == nil then
                            local DelayTime = Item.FloatUI.DX_IconOut:GetEndTime()
                            UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, function()
                                Item.FloatUI:SetVisibility(UE.ESlateVisibility.Collapsed)
                            end }, DelayTime, false)
                        end
                    end
                    Item.FloatUI.Location2D = nil
                end
            end
        end
       
    end

end

---@param Loc FVector2D
function WBP_Firm_Content:IfOutScreen(Loc)
    if Loc then
        local Location = Loc
        local RelPosX = (Location.X - self.ViewBegin.X) * self.CurrentScale
        local RelPosY = (Location.Y - self.ViewBegin.Y) * self.CurrentScale
        if RelPosX < 0 or RelPosY < 0 or RelPosX > self.ScreenSize.X or RelPosY > self.ScreenSize.Y then
            return true
        end
        return false
    end
end

---@return FVector2D,FVector2D @Min,Max
function WBP_Firm_Content:GetTranslationRange()
    local ViewScale = UE.UWidgetLayoutLibrary.GetViewportScale(self)
    local ViewSize = UE.UWidgetLayoutLibrary.GetViewportSize(self)
    local ScreenSize = ViewSize / ViewScale
    local ImageSize = self.ImageSize
    local MaxX = (ImageSize.X * self.CurrentScale - ImageSize.X) / 2
    local MaxY = (ImageSize.Y * self.CurrentScale - ImageSize.Y) / 2
    local Max2Y = (ImageSize.Y * self.CurrentScale - ImageSize.Y) / 2 + self.DifferY
    local MinX = ImageSize.X - ImageSize.X + MaxX
    local MinY = ImageSize.Y - ImageSize.Y + MaxY

    return UE.FVector2D(-MinX, -Max2Y), UE.FVector2D(MaxX, MaxY)
end

---添加浮标并计算位置
---@param Loc FVector2D
---@param Item MapsCustomData
---@return FVector2D
function WBP_Firm_Content:AddFloat(Loc, Item)
  
    self.Loc2D = Loc

    if Item ~= nil then
        if Item.FloatUI == nil then
            ---@type WBP_FirmMapLabel
            Item.FloatUI = UE.UWidgetBlueprintLibrary.Create(self, self.LabelClass)
            if Item.FloatUI ~= nil then
                --Item.FloatUI:PlayAnimation(Item.FloatUI.DX_IconIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
                Item.FloatUI.Canvas_DomainName:SetVisibility(UE.ESlateVisibility.Collapsed)
                Item.FloatUI.WBP_HUD_Task_Icon:SetVisibility(UE.ESlateVisibility.Collapsed)
                Item.FloatUI.EFF_1:SetVisibility(UE.ESlateVisibility.Collapsed)
                Item.FloatUI.EFF_2:SetVisibility(UE.ESlateVisibility.Collapsed)
                Item.FloatUI.EFF_3:SetVisibility(UE.ESlateVisibility.Collapsed)
                Item.FloatUI.EFF_4:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                Item.FloatUI:PlayAnimation(Item.FloatUI.DX_IconOffScreenLoop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1, false)
                Item.FloatUI.Img_TargetArrow:SetRenderTransformPivot(UE.FVector2D(0.5, 3.2))
                if self.PlayerLabel then
                    if Item.Type == FirmMapLegendTypeTableConst.PlayerPosition then
                        Item.FloatUI.Switch_Positioning:SetActiveWidgetIndex(3)
                        PicConst.SetImageBrush(Item.FloatUI.Img_Target, tostring(self.MapIconData[tonumber(self.PlayerLabel.ShowId)].Icon))
                        Item.FloatUI.ShowId = self.PlayerLabel.ShowId

                    else
                        Item.FloatUI.Switch_Positioning:SetActiveWidgetIndex(1)
                        Item.FloatUI.Switch_Positioning:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                        --Item.WBP_HUD_Task_Icon:SetVisibility(UE.ESlateVisibility.Collapsed)
                        if Item.IsAnchor then
                            Item.WBP_HUD_Task_Icon:SetVisibility(UE.ESlateVisibility.Collapsed)
                            PicConst.SetImageBrush(Item.FloatUI.Img_Target, tostring(Item.PicKey))
                            Item.FloatUI.PicKey = Item.PicKey
                        elseif Item.Mission ~= nil then
                            local TrackType = Item.Mission:GetMissionType()
                            local TrackState = Item.Mission:GetMissionTrackIconType()
                            Item.FloatUI.Switch_Positioning:SetVisibility(UE.ESlateVisibility.Collapsed)
                            Item.FloatUI.WBP_HUD_Task_Icon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                            IconUtility:SetTaskIcon(Item.FloatUI.WBP_HUD_Task_Icon, TrackType, TrackState - 1)
                        else
                            Item.WBP_HUD_Task_Icon:SetVisibility(UE.ESlateVisibility.Collapsed)
                            local ItemData = FirmUtil.GetMapLegendOnlyDataById(self.MapId, Item.ShowId)
                            if ItemData then
                                local ItemId = ItemData.Legend_ID
                                PicConst.SetImageBrush(Item.FloatUI.Img_Target, tostring(self.MapIconData[tonumber(ItemId)].Icon))
                                Item.FloatUI.ShowId = Item.ShowId
                            end
                        end
                    end
                end

                local TempId = self.FloatKey + 1
                self.FloatKey = self.FloatKey + 1
                ---获得UI大小
                local CanvasSlot = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(Item.FloatUI.WBP_Map_PositioningTeleport)
                local FloatUISize = CanvasSlot:GetSize()
                Item.FloatUI.IsAnchor = Item.IsAnchor
                Item.FloatUI.OldLocation = self.Loc2D
                Item.FloatUI.TempId = TempId
                Item.FloatUI.Type = Item.Type
                Item.FloatUI.ShowId = Item.ShowId
                Item.FloatUI.IsTrace = Item.IsTrace
                Item.FloatUI.Mission = Item.Mission
                ---获得所有创建出来的图标
                table.insert(self.FloatLabelsUI, Item.FloatUI)
                self.FloatUI = Item.FloatUI

                self.CanvasPanel_Content:AddChildToCanvas(Item.FloatUI)

                local FloatUISlot = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(Item.FloatUI)
                self.LabelCount = self.LabelCount + 1
                local ZOrder = FirmUtil.GetZOrder(Item.FloatUI, self.LabelCount)
                FloatUISlot:SetZOrder(ZOrder)
                FloatUISlot:SetPosition(-FloatUISlot:GetSize() / 2)

                ---绑定点击回调

                Item.FloatUI.WBP_Map_PositioningTeleport.OnClicked:Add(self, function()
                    if self.FloatUIClickCallback then
                        self.FloatUIClickCallback(self.Parent, TempId, self.FloatLabelsUI, FloatUISize)
                    end
                end)
            end
        end
        if Item.FloatUI ~= nil and self.PlayerLabel then
            if Item.Type == FirmMapLegendTypeTableConst.PlayerPosition then
                if not self.OutScreenPlayer then
                    self.OutScreenPlayer = true
                    Item.FloatUI:StopAnimation(Item.FloatUI.DX_IconOut)
                    Item.FloatUI:PlayAnimation(Item.FloatUI.DX_IconIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
                    local DelayTime = Item.FloatUI.DX_IconIn:GetEndTime()
                    UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, function()
                        Item.FloatUI:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                    end }, DelayTime, false)
                end
            else
                if not Item.OutScreen then
                    Item.OutScreen = true
                    Item.FloatUI:StopAnimation(Item.FloatUI.DX_IconOut)
                    Item.FloatUI:PlayAnimation(Item.FloatUI.DX_IconIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
                    local DelayTime = Item.FloatUI.DX_IconIn:GetEndTime()
                    UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, function()
                        Item.FloatUI:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                    end }, DelayTime, false)
                end
            end
        end

        local RadiusX = 800
        local RadiusY = 500
        local CenterPointX = self.ImageSize.X / 2
        local CenterPointY = self.ScreenSize.Y / 2
        ---求全局图标和全局圆心的直线方程的斜率
        local K = (self.Loc2D.Y - self.ViewCentrePosition.Y) / (self.Loc2D.X - self.ViewCentrePosition.X)
        local M = self.Loc2D.Y - K * self.Loc2D.X

        local RelPosX = (self.Loc2D.X - self.ViewBegin.X) * self.CurrentScale
        local RelPosY = (self.Loc2D.Y - self.ViewBegin.Y) * self.CurrentScale
        ---求相对位置的坐标
        self.XRel = RelPosX
        self.YRel = RelPosY
        ---求直线方程的斜率
        local m = (self.YRel - CenterPointY) / (self.XRel - CenterPointX)
        ---将直线方程带入到椭圆方程中
        ---Ax^2+Bx+C=0
        local A = RadiusY * RadiusY + RadiusX * RadiusX * m * m
        local B = -2 * CenterPointX * RadiusY * RadiusY - 2 * CenterPointX * RadiusX * RadiusX * m * m
        local C = RadiusY * RadiusY * CenterPointX * CenterPointX + RadiusX * RadiusX * m * m * CenterPointX * CenterPointX - RadiusY * RadiusY * RadiusX * RadiusX
        ---判断是否有交点
        local discriminant = B * B - 4 * A * C
        if discriminant < 0 then
            return
        end
        local sqrtdiscriminant = math.sqrt(discriminant)
        local X1 = (-B + sqrtdiscriminant) / (2 * A)
        local X2 = (-B - sqrtdiscriminant) / (2 * A)
        ---带回直线方程算出Y的坐标
        local Y1 = m * (X1 - CenterPointX) + CenterPointY
        local Y2 = m * (X2 - CenterPointX) + CenterPointY
        local Distance1 = math.sqrt((X1 - self.XRel) * (X1 - self.XRel) + (Y1 - self.YRel) * (Y1 - self.YRel))
        local Distance2 = math.sqrt((X2 - self.XRel) * (X2 - self.XRel) + (Y2 - self.YRel) * (Y2 - self.YRel))
        ---两个点比较最小距离
        if Distance1 < Distance2 then
            self.FloatLoc = UE.FVector2D(X1, Y1)
        else
            self.FloatLoc = UE.FVector2D(X2, Y2)
        end

        if Item.FloatUI ~= nil then
            Item.FloatUI:SetRenderTranslation(self.FloatLoc)
            Item.FloatUI.Location2D = self.FloatLoc
            ---相对坐标转换为绝对坐标
            local NewLoc = UE.FVector2D(Item.FloatUI.Location2D.X / self.CurrentScale + self.ViewBegin.X, Item.FloatUI.Location2D.Y / self.CurrentScale + self.ViewBegin.Y)
            if self.PlayerLabel then
                if self.Loc2D == self.PlayerLabel.Location2D then
                    Item.FloatUI.OldLocation = self.Loc2D
                end
            end

            local Vector = Item.FloatUI.OldLocation - NewLoc
            local VecX = Vector.X
            local VecY = Vector.Y
            local Radians = math.atan2(VecY, VecX)
            local Degrees = math.abs(Radians * (180 / math.pi))
            if Item.FloatUI.Location2D.Y > CenterPointY then
                Item.FloatUI.Img_TargetArrow:SetRenderTransformAngle(-(270 - Degrees))
            end
            if Item.FloatUI.Location2D.Y < CenterPointY then
                Item.FloatUI.Img_TargetArrow:SetRenderTransformAngle(90 - Degrees)
            end

        end
    end
end


---@param Context FPaintContext
---@param Location FVector2D
local function DrawPoint(Context, Location)
    UE.UWidgetBlueprintLibrary.DrawLine(Context, Location, Location + UE.FVector2D(3, 3), UE.FLinearColor(1, 0, 0), false, 5)
end

--@param Context FPaintContext
--function WBP_Firm_Content:OnPaint(Context)
--    local RadiusX = 800
--    local RadiusY = 500
--    local Segments = 256
--    local CenterPointX = self.ImageSize.X / 2
--    local CenterPointY = self.ImageSize.Y / 2
--    local PI = UE.UKismetMathLibrary.GetPI()
--    for i = 1, Segments do
--        local Angle = 2 * PI * i / Segments
--        self.X = CenterPointX + RadiusX * UE.UKismetMathLibrary.Cos(Angle)
--        self.Y = CenterPointY + RadiusY * UE.UKismetMathLibrary.Sin(Angle)
--        local Point = UE.FVector2D(self.X, self.Y)
--        DrawPoint(Context, Point)
--    end
--    local Center = UE.FVector2D(CenterPointX, CenterPointY)
--
--    DrawPoint(Context, Center)
--    print("self.View", Center, self.ViewCentrePosition)
--    local PlayerLoc2D = self.PlayerLabel.Location2D
--    local FloatPoint = UE.FVector2D(self.FloatX, self.FloatY)
--    local A = PlayerLoc2D.X
--    local B = PlayerLoc2D.Y
--    print("<<<<<<<<PlayerLoc2D", A, B, self.ViewCentrePosition.X, self.ViewCentrePosition.Y)
--    if self.XRel and self.YRel then
--        local Rel = UE.FVector2D(self.XRel, self.YRel)
--        UE.UWidgetBlueprintLibrary.DrawLine(Context, self.ImageSize / 2, Rel)
--    end
--end

---检测移动时是否超框了
---@private
---@return boolean
function WBP_Firm_Content:CheckTranslate()
    local Translation = self.ScaleBox_Content.RenderTransform.Translation
    local OldTranslation = UE.FVector2D(Translation.X, Translation.Y)
    local Min, Max = self:GetTranslationRange()

    local NewTranslation = UE.FVector2D(0, 0)
    NewTranslation.X = UE.UKismetMathLibrary.FClamp(OldTranslation.X, Min.X, Max.X)
    NewTranslation.Y = UE.UKismetMathLibrary.FClamp(OldTranslation.Y, Min.Y, Max.Y)
    if NewTranslation.X ~= OldTranslation.X or NewTranslation.Y ~= OldTranslation.Y then
        self.ScaleBox_Content:SetRenderTranslation(NewTranslation)
        self:CalcViewRange()
        return true
    end
    return false
end

---3D坐标转2D坐标，基于CurrentScale为1时的转换
---@param Location FVector
---@return FVector2D
function WBP_Firm_Content:Location2Map2D(Location)
    if Location == nil then
        return nil
    end
    if Location.X < LocationBegin.X or Location.X > LocationEnd.X or Location.Y < LocationBegin.Y or Location.Y > LocationEnd.Y then
        G.log:error("ghgame", "Error! Location not in Map,LocationX:%f,LocationY:%f,LocationBeginX:%f,LocationBeginY:%f,LocationEndX:%f,LocationEndY:%f", Location.X, Location.Y,
        LocationBegin.X, LocationBegin.Y, LocationEnd.X, LocationEnd.Y)
        return nil
    end
    return UE.FVector2D((Location.X - LocationBegin.X) / (LocationEnd.X - LocationBegin.X) * self.ImageSize.X, (Location.Y - LocationBegin.Y) / (LocationEnd.Y - LocationBegin.Y) * self.ImageSize.Y)
    
end
---2D坐标转3D坐标，基于CurrentScale为1时的转换
---@param Location2D FVector2D
---@return FVector
function WBP_Firm_Content:Map2D2Location(Location2D)
    if Location2D == nil then
        return nil
    end
    if Location2D.X < 0 or Location2D.X > self.ImageSize.X or Location2D.Y < 0 or Location2D.Y > self.ImageSize.Y then
        return nil
    end
    return UE.FVector((Location2D.X / self.ImageSize.X) * (LocationEnd.X - LocationBegin.X) + LocationBegin.X, (Location2D.Y / self.ImageSize.Y) * (LocationEnd.Y - LocationBegin.Y) + LocationBegin.Y, 0)
end

---移动到制定2D坐标
---@param Location2D FVector2D
function WBP_Firm_Content:MoveToLocation2D(Location2D)
    if Location2D == nil then
        return
    end
    local Translation = (self.InitViewCentrePosition - Location2D) * self.CurrentScale
    local Min, Max = self:GetTranslationRange()
    Translation.X = UE.UKismetMathLibrary.FClamp(Translation.X, Min.X, Max.X)
    Translation.Y = UE.UKismetMathLibrary.FClamp(Translation.Y - self.DifferCenter.Y, Min.Y, Max.Y)
    self.ScaleBox_Content:SetRenderTranslation(Translation)
    self:CalcViewRange()
    self:CalcGridLoad()
    self:CheckLabelInScreen()
    self:ReviseTranslation()
    if self.Parent.Firm_MapOptions ~= nil then
        self.Parent.Firm_MapOptions:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.bShowMapOptions = false
    end
end

---获取当前鼠标的Map2D坐标
---@return FVector2D
function WBP_Firm_Content:GetMap2DByMouse()
    local MousePosition = UE.UWidgetLayoutLibrary.GetMousePositionOnViewport(self)

    local X = (MousePosition.X / self.ImageSize.X) * (self.ViewEnd.X - self.ViewBegin.X) + self.ViewBegin.X
    local Y = (MousePosition.Y / self.ImageSize.Y) * (self.ViewEnd.Y - self.ViewBegin.Y) + self.ViewBegin.Y
    return UE.FVector2D(X, Y)
end

---计算需要Load的格子范围
function WBP_Firm_Content:CalcGridLoad()
    local High = self.ImageSize.Y / Row
    local Width = self.ImageSize.X / Column

    local BeginX = math.floor(self.ViewBegin.X / Width)
    local BeginY = math.floor(self.ViewBegin.Y / High)
    local EndX = math.floor(self.ViewEnd.X / Width) + 2
    local EndY = math.floor(self.ViewEnd.Y / High) + 2

    BeginX = UE.UKismetMathLibrary.Clamp(BeginX, 1, Column)
    BeginY = UE.UKismetMathLibrary.Clamp(BeginY, 1, Row)
    EndX = UE.UKismetMathLibrary.Clamp(EndX, 1, Column)
    EndY = UE.UKismetMathLibrary.Clamp(EndY, 1, Row)

    self.UniqueCells = {}
    local Visited = {}
    local GridData = nil
    for r = 1, Row do
        for c = 1, Column do
            if (r >= BeginY and r <= EndY) and (c >= BeginX and c <= EndX) then
                self:LoadChildImage(r, c)
                table.insert(self.UniqueCells, { r, c })
                self.ChildImages[r][c].Labels = {}
            else
                self:UnLoadChildImage(r, c)
            end
        end
    end
    --local UniqueCells = self.UniqueCells
    --if UniqueCells and #UniqueCells > 0 then
    --    for i = 1, #UniqueCells do
    --        local row = self.UniqueCells[i][1]
    --        local column = self.UniqueCells[i][2]
    --        local Labels = self.ChildImages[row][column].Labels
    --        for _, Label in ipairs(Labels) do
    --            if Label ~= nil then
    --                if Label.Location2D == nil then
    --                    return
    --                end
    --            end
    --        end
    --    end
    --end
    for i, v in ipairs(self.Labels) do
        self:CalcIconIsInTheGrid(v)
        self:TrimLabel(v)
    end

end

---@param Label WBP_FirmMapLabel
function WBP_Firm_Content:RenderLabel(Label)
    if Label then
        local BeginTranslation = self.ScaleBox_Content.RenderTransform.Translation
        local BeginLocationX = BeginTranslation.X - (self.CurrentScale - 1) * self.ImageSize.X / 2
        local BeginLocationY = BeginTranslation.Y - (self.CurrentScale - 1) * self.ImageSize.Y / 2
        local X = self.CurrentScale * Label.Location2D.X + BeginLocationX
        local Y = self.CurrentScale * Label.Location2D.Y + BeginLocationY
        Label:SetRenderTranslation(UE.FVector2D(X, Y))
    end
end

---整理图标
---@param Label WBP_FirmMapLabel
function WBP_Firm_Content:TrimLabel(Label)
    local BeginTranslation = self.ScaleBox_Content.RenderTransform.Translation
    local BeginLocationX = BeginTranslation.X - (self.CurrentScale - 1) * self.ImageSize.X / 2
    local BeginLocationY = BeginTranslation.Y - (self.CurrentScale - 1) * self.ImageSize.Y / 2

    local EndLocationX = self.ImageSize.X + BeginTranslation.X + (self.CurrentScale - 1) * self.ImageSize.X / 2
    local EndLocationY = self.ImageSize.Y + BeginTranslation.Y + (self.CurrentScale - 1) * self.ImageSize.Y / 2

    if Label then
        local X = self.CurrentScale * Label.Location2D.X + BeginLocationX
        local Y = self.CurrentScale * Label.Location2D.Y + BeginLocationY
        Label:SetRenderTranslation(UE.FVector2D(X, Y))
    end
end

return WBP_Firm_Content