--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local FirmMapTable = require("common.data.firm_map_data").data
local PicConst = require("CP0032305_GH.Script.common.pic_const")
local FirmMapLegendTypeTable = require("common.data.firm_map_legend_type_data").data
local FirmMapLegendTypeTableConst = require("common.data.firm_map_legend_type_data")
local FirmUtil = require("CP0032305_GH.Script.ui.view.ingame.Firm.FirmUtil")
local ConstText = require("CP0032305_GH.Script.common.text_const")
local GameData = require("common.data.game_const_data").data
local G = require("G")

---@field MarkerPointsItems WBP_FirmMapLabel[]
---@field FirmMarkerPointsItem WBP_FirmMapLabel
---@field SelectedMarkerPos FVector2D

---@class WBP_HUD_MiniMap_Content : WBP_HUD_MiniMap_Content_C
---@type WBP_HUD_MiniMap_Content
local WBP_HUD_MiniMap_Content = Class(UIWindowBase)

local Row = 10
local Column = 10

---场景中坐标范围
local LocationBegin = UE.FVector(-2000.0, -1000.0, 0)
local LocationEnd = UE.FVector(4000.0, 4000.0, 0)

---视觉范围
local ViewRange = UE.FVector2D(500, 500)

---目标引导范围
local Target_Guidance_Range = 80

---图标居中配置
local SetCenter = 0.5

---初始参考坐标A,B
local InitLocBegin = UE.FVector(1000, 1500, 0)
local InitLocEnd = UE.FVector(4000, 4000, 0)

local TRACE_ZORDER = 1
local NORMAL_ZORDER = 0

---格子索引
local GridIndex = { 2, 2 }
--function M:Initialize(Initializer)
--end

--function M:PreConstruct(IsDesignTime)
--end

function WBP_HUD_MiniMap_Content:Construct()

end

---@param Id string
---@return FirmMapData
local function GetFirmMapData(Id)
    return FirmMapTable[Id]
end

function WBP_HUD_MiniMap_Content:Tick(MyGeometry, InDeltaTime)
    
    local Controller = UE.UGameplayStatics.GetPlayerController(self, 0)
    if Controller and Controller:K2_GetPawn() then
        local PlayerLocation = Controller:K2_GetPawn():K2_GetActorLocation()

        local Player = UE.UGameplayStatics.GetPlayerCharacter(self, 0)
        if self.Player~=Player then
            self.Player=Player
        end
       
        if Player and PlayerLocation then
            local PlayerRotation = Player:K2_GetActorRotation().Yaw
            local ControllerRotation = Controller:K2_GetActorRotation().Yaw
            if self:CurrentMapIdExists() then
                self.Img_DirectionRange:SetRenderTransformAngle(ControllerRotation + 90)
                if not self.Parent.ChangeMode then
                    if self.PlayerUI then
                        self.PlayerUI:SetRenderTransformAngle(PlayerRotation + 90)
                    end
                else
                    self:CameraRotate()
                end

                self.PlayerLoc2D = self:Location2Map2D(PlayerLocation)
                if self.LastPlayerLocation then
                    if UE.UKismetMathLibrary.NotEqual_Vector2DVector2D(self.PlayerLoc2D, self.LastPlayerLocation) then
                        self:MoveToLocation2D(self.PlayerLoc2D)
                        self:CheckIfOutCircle()
                    end
                    
                end
                self.LastPlayerLocation = self.PlayerLoc2D
            end
        end
    end

    if self.TraceUI ~= nil and self.TraceUI:IsValid() then

        self:EventTraceUI()
    else
        self.TraceUI = nil
    end
end

function WBP_HUD_MiniMap_Content:EventTraceUI()
    if self.TraceUI == nil or not self.TraceUI:IsValid() then
      return  
    end
    if self.TraceUI.ScopeTask ~= nil then
        if self.Player == nil then
         self.Player = UE.UGameplayStatics.GetPlayerCharacter(self, 0)
        end
        if self.TraceUI ~= nil then
            self:CutScopeIcon()
        end
     end
end

function WBP_HUD_MiniMap_Content:CutScopeIcon()

    local Distance=UE.UKismetMathLibrary.Vector_Distance2D(self.TraceUI.WorldLocation,self.Player:K2_GetActorLocation())
        if tonumber(Distance) <= (self.TraceUI.TaskDistance or self.TraceUI.TaskRadius) then
            if not self.TraceUI.ScopeState then
                self.TraceUI:InsidScope()
            end
        else
            if self.TraceUI.ScopeState then
                self.TraceUI:OutScope()
            end
        end
end
function WBP_HUD_MiniMap_Content:CameraRotate()
    local Controller = UE.UGameplayStatics.GetPlayerController(self, 0)
    local Rotation = Controller:K2_GetActorRotation().Yaw
    if self.ChangeMode then
        self.Parent.Img_Decoration:SetRenderTransformAngle(Rotation + 90)
        self.ScaleBox_Content:SetRenderTransformAngle(Rotation + 90)
    end
end

---@param Parent WBP_HUD_MiniMap
---@param MapId string
function WBP_HUD_MiniMap_Content:Init(Parent, MapId)
    
    self.Parent = Parent
    self.MapId = MapId
    self.Error = false
    self.LabelCount = 0
    self.Key = 0
    self.GridIndexRow = GridIndex[1]
    self.GridIndexColumn = GridIndex[2]
    self.DefaultScaleValue = 1

    if self:CurrentMapIdExists() then
        local Data = GetFirmMapData(MapId)
        if Data then
            Row = Data.split_row
            Column = Data.split_column
           
            InitLocBegin.X = Data.location_begin[1]
            InitLocBegin.Y = Data.location_begin[2]
            InitLocEnd.X = Data.location_end[1]
            InitLocEnd.Y = Data.location_end[2]
            
            
            ViewRange.X = Data.small_map_range_stadia
            ViewRange.Y = Data.small_map_range_stadia
            Target_Guidance_Range = Data.target_guidance_range
            self.GridIndexRow = Data.gridindex[1]
            self.GridIndexColumn = Data.gridindex[2]
            self.DefaultScaleValue = Data.default_scale
        end
    end

    self.AnchorNum = 0
    self.ChildImages = {}
    self.MarkerPointsItems = {}
    self.GuideLabels = {}
    for i = 1, Row do
        table.insert(self.ChildImages, {})
        for j = 1, Column do
            table.insert(self.ChildImages[i], {
                Image = nil,
                Labels = {}
            })
        end
    end
    self.GridPanel_Image:ClearChildren()
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

    local MinimapSlot = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.Parent.RetainerBox_Minimap)
    local SmallScreenSize = MinimapSlot:GetSize()
    self.SmallScreenSize = SmallScreenSize
    ---默认用屏幕大小
    self.ImageSize = SmallScreenSize

    ---初始视距范围是全地图
    self.ViewBegin = UE.FVector2D(0, 0)
    self.ViewEnd = UE.FVector2D(self.ImageSize.X, self.ImageSize.Y)
    self.InitViewCentrePosition = UE.FVector2D(self.ImageSize.X / 2, self.ImageSize.Y / 2)
    self.ViewCentrePosition = UE.FVector2D(self.ImageSize.X / 2, self.ImageSize.Y / 2)

    ---3D场景中格子映射的大小
    local GridSizeX = math.abs(InitLocEnd.X - InitLocBegin.X)
    local GridSizeY = math.abs(InitLocEnd.Y - InitLocBegin.Y)

    local DifferNumRow = Row - self.GridIndexRow
    local DifferNumColumn = Column - self.GridIndexColumn

    local LocBeginX = InitLocEnd.X - self.GridIndexRow * GridSizeX
    local LocBeginY = InitLocEnd.Y - self.GridIndexColumn * GridSizeY
    local LocEndX = InitLocEnd.X + DifferNumRow * GridSizeX
    local LocEndY = InitLocEnd.Y + DifferNumColumn * GridSizeY
    LocationBegin = UE.FVector(LocBeginX, LocBeginY, 0)
    LocationEnd = UE.FVector(LocEndX, LocEndY, 0)

    ---计算基础缩放率
    
    local PreSetScale = (LocationEnd.X - LocationBegin.X) / self.ImageSize.X
    
    
    ---@type UTexture2D
    local ImageTexture = PicConst.GetPicResource(string.format("UI_Firm_%s_%d_%d", tostring(self.MapId), 0, 0))
    local WorldDistance = LocationEnd - LocationBegin
    if ImageTexture ~= nil then
        self.PreSetScale = PreSetScale * (ImageTexture.ImportedSize.X * Row / WorldDistance.X)
    else
        self.PreSetScale = PreSetScale
    end
    
    local Scale = UE.FVector2D(1, 1) * self.PreSetScale
    self.ScaleBox_Content:SetRenderScale(Scale)
    self.BaseScale = self.PreSetScale * self.DefaultScaleValue
    
    
    self.CurrentScale = self.BaseScale
    local ScaleAfter = UE.FVector2D(1, 1) * self.BaseScale 
    self.ScaleBox_Content:SetRenderScale(ScaleAfter)

    if ImageTexture~=nil then
        self.MapScale = ImageTexture.ImportedSize.X * Row / WorldDistance.X
    end
    

    --self.Labels = {}
    self.MissionLabels = {}

    local Controller = UE.UGameplayStatics.GetPlayerController(self, 0)
    local PlayerLocation = Controller:K2_GetPawn():K2_GetActorLocation()
    local PlayerLegendId = FirmUtil.GetMapLegendIdByType(FirmMapLegendTypeTableConst.PlayerPosition)

    self:AddPlayerLabel(PlayerLocation, PlayerLegendId)
    self:AddLegendData()

    self:SetRenderTranslation(-self.PlayerSlot:GetSize() / 2)
    local Slot = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.ScaleBox_Content)
    Slot:SetPosition(UE.FVector2D(self.PlayerSlot:GetSize().X / 2, 0))
    self:CalcViewRange()
    self.DifferView = self.ViewCentrePosition - self.ViewBegin
    self.PlayerLoc2D = self:Location2Map2D(PlayerLocation)
    self:MoveToLocation2D(self.PlayerLoc2D)
    self:CheckIfOutCircle()
end

---@return boolean
function WBP_HUD_MiniMap_Content:CurrentMapIdExists()
    for i, v in pairs(FirmMapTable) do
        if self.MapId == i then
            return true
        end
    end
end

---@param FirmMarkerPointsItem WBP_FirmMapLabel
function WBP_HUD_MiniMap_Content:OnClickedCommit(FirmMarkerPointsItem)
    table.insert(self.MarkerPointsItems, FirmMarkerPointsItem)
end

---获取地图图标显示数据
function WBP_HUD_MiniMap_Content:GetMapIconData()
    ---@type MapIconData[]
    local MapIconData = {}
    for i, j in pairs(FirmMapLegendTypeTable) do
        local LegendElement = {
            Icon = j.Legend_Icon,
            bIsSelected = false,
            bIsRewards = (j.LegendType == FirmMapLegendTypeTableConst.Playmethod or j.LegendType == FirmMapLegendTypeTableConst.Task),
            bIsTrace = (j.LegendType == FirmMapLegendTypeTableConst.Playmethod or j.LegendType == FirmMapLegendTypeTableConst.Task)
        }
        MapIconData[i] = LegendElement
    end
    return MapIconData
end




---@field LabelData.Location FVector
---@field LabelData.ShowId integer
---@field LabelData.IsGuide boolean
---@field LabelData.Type integer
---@field LabelData.PicKey integer
---@field LabelData.MissionItem TrackTargetType
---@field LabelData.Mission MissionObject
function WBP_HUD_MiniMap_Content:AddLabel(LabelData)
    
    
        local Scale = UE.FVector2D(SetCenter, SetCenter)
        local TempId = self.Key + 1
        self.Key = self.Key + 1
        ---@type WBP_FirmMapLabel
        self.CustomUI = UE.UWidgetBlueprintLibrary.Create(self, self.LabelClass)
   
        if LabelData.MissionItem then
            if LabelData.MissionItem.Radius>0 then
                self.TraceUI=self.CustomUI
            end
        end
        self.CustomUI.WBP_HUD_Task_Icon:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.CustomUI.EFF_1:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.CustomUI.EFF_2:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.CustomUI.EFF_4:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.CustomUI.Mission = LabelData.Mission
 
    
        if LabelData.Type == FirmMapLegendTypeTableConst.Anchor then
            self.CustomUI.Switch_Positioning:SetActiveWidgetIndex(0)
            self.CustomUI.Switch_TeleportIcon:SetActiveWidgetIndex(1)
            self.CustomUI.Img_PositioningBG:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.CustomUI.Img_TargetArrow:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.CustomUI.Canvas_DomainName:SetVisibility(UE.ESlateVisibility.Collapsed)
            PicConst.SetImageBrush(self.CustomUI.Icon_CustomMark, tostring(LabelData.PicKey))
            self.CustomUI.IsAnchor = true
        else
            self.CustomUI.IsAnchor = false
            self:EventIsShowId(LabelData)
        end
    
        self:SetCustomUIData(LabelData,Scale,TempId)
  
end


function WBP_HUD_MiniMap_Content:EventIsShowId(LabelData)
  
    if LabelData.ShowId ~= nil then
        
        self.CustomUI.Switch_Positioning:SetActiveWidgetIndex(0)
        self.CustomUI.Switch_TeleportIcon:SetActiveWidgetIndex(0)
        self.CustomUI.Switch_TeleportState:SetActiveWidgetIndex(0)
        self.CustomUI.Img_PositioningBG:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.CustomUI.Img_TargetArrow:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.CustomUI.Canvas_DomainName:SetVisibility(UE.ESlateVisibility.Collapsed)
        if LabelData.Mission and LabelData.MissionItem then
          
            local TrackState = LabelData.Mission:GetMissionTrackIconType()
            self.CustomUI.Mission = LabelData.Mission
            self.CustomUI.WBP_HUD_Task_Icon:SetVisibility(UE.ESlateVisibility.Visible)
            self.CustomUI.Canvas_DomainName:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.CustomUI.Switch_Positioning:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.CustomUI.Img_PositioningBG:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.CustomUI.Img_TargetArrow:SetVisibility(UE.ESlateVisibility.Collapsed)
            
            self:IsMissionItemRadius(LabelData.Mission,LabelData.MissionItem)
            if self.MissionLabels ~= nil then
                table.insert(self.MissionLabels, self.CustomUI)
            end
        end
        local TypeId = FirmUtil.GetMapLegendIdByType(LabelData.Type)
       
        
        if self.MapIconData[tonumber(TypeId)].Icon == nil then
           
            self:EventMapLegendData(LabelData.Type,LabelData.ShowId,TypeId)
        else
            PicConst.SetImageBrush(self.CustomUI.Icon_Teleport, self.MapIconData[tonumber(TypeId)].Icon)
        end
    end
    
end

function WBP_HUD_MiniMap_Content:EventMapLegendData (InType,InShowId,InTypeId)
    
   
    if InType == FirmMapLegendTypeTableConst.BigAreaName or InType == FirmMapLegendTypeTableConst.SmallAreaName then
        local NameData = FirmUtil.GetMapLegendOnlyDataById(self.MapId, InShowId).Legend_Name
        if NameData == "" or NameData == nil then
            --NameData = self:GetFirmMapLegendTypeData(TypeId).Legend_Name
            NameData = FirmUtil.GetMapLegendTypeDataById(InTypeId).Legend_Name
        end
        local TitleName = ConstText.GetConstText(NameData)
        if TitleName then
            self.CustomUI.Txt_DomainName:SetText(TitleName)
            self.CustomUI.Img_TargetArrow:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.CustomUI.Img_PositioningBG:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.CustomUI.Txt_ExploratoryDegree:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.CustomUI.Canvas_DomainName:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.CustomUI.Switch_Positioning:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
        
    end
    
end

function WBP_HUD_MiniMap_Content:IsMissionItemRadius(InMission,InMissionItem)
   
    local TrackType = InMission:GetMissionType()
    self.CustomUI.MapScale=self.MapScale
    self.CustomUI.BaseScale = self.BaseScale
    if InMissionItem.Radius == 0 then
        self.CustomUI.ScopeTask=false
        self.CustomUI.WBP_HUD_Task_Icon:SetVisibility(UE.ESlateVisibility.Visible)
        self.CustomUI.WBP_HUD_Task_Icon.Task_Icon_Switcher:SetActiveWidgetIndex(TrackType)
        
    else
        self.CustomUI.ScopeTask=true
        self.CustomUI.TaskRadius=InMissionItem.Radius
        --self.CustomUI.TaskDistance=InMissionItem.Distance
        if GameData.MAP_AREATASK_SHOW_DISTANCE ~= nil then
            self.CustomUI.TaskDistance = GameData.MAP_AREATASK_SHOW_DISTANCE.IntValue
        end
        self.CustomUI.WBP_HUD_Task_Icon.Task_Icon_Switcher:SetActiveWidgetIndex(5)
        self.CustomUI:OutScope()
    end
   
end



function WBP_HUD_MiniMap_Content:SetCustomUIData(LabelData,InScale,InTempId) 

    self.CustomUI:SetRenderScale(UE.FVector2D( SetCenter , SetCenter ))
    local CustomUISlot = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.CustomUI)
    self.CustomUI.WorldLocation=LabelData.Location
    local Location2D = self:Location2Map2D(LabelData.Location)
   
    self.CustomUI:SetRenderTranslation(Location2D)
    self.CustomUI.Location2D = Location2D
    if InTempId then
        self.CustomUI.TempId = InTempId
    end
    self.CustomUI.IsTrace = false
    if LabelData.IsGuide ~= nil then
        self.CustomUI.IsGuide = LabelData.IsGuide
    else
        self.CustomUI.IsGuide = false   
    end
    if LabelData.ShowId then
        self.CustomUI.ShowId = LabelData.ShowId
    end
    if LabelData.PicKey then
        self.CustomUI.PicKey = LabelData.PicKey
    end
    if LabelData.Type then
        self.CustomUI.Type = LabelData.Type
    end
    self.CanvasPanel_Labels:AddChildToCanvas(self.CustomUI)
    self.LabelCount = self.LabelCount + 1
    ---@type UCanvasPanelSlot
    local Slot = self.CustomUI.Slot
    local ZOrder = FirmUtil.GetZOrder(self.CustomUI, self.LabelCount)
    Slot:SetZOrder(ZOrder)

    --table.insert(self.Labels, self.CustomUI)
    local Labels = self.CanvasPanel_Labels:GetAllChildren()
    self.Labels = Labels
    self.Labels = self.CanvasPanel_Labels:GetAllChildren()
  
end

---@param Location FVector
function WBP_HUD_MiniMap_Content:AddPlayerLabel(Location, ShowId)
    local Scale = UE.FVector2D(SetCenter, SetCenter)
    self.MapIconData = self:GetMapIconData()
    ---@type WBP_FirmMapLabel
    self.PlayerUI = UE.UWidgetBlueprintLibrary.Create(self, self.LabelClass)
    --self.PlayerUI:SetRenderScale(Scale)
    if self.PlayerUI then
        self.CanvasPanel_Content:AddChildToCanvas(self.PlayerUI)
        local Anchors = UE.FAnchors()
        Anchors.Minimum = UE.FVector2D(SetCenter, SetCenter)
        Anchors.Maximum = UE.FVector2D(SetCenter, SetCenter)
        local PlayerSlot = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.PlayerUI)
        PlayerSlot:SetAnchors(Anchors)
        self.PlayerUI:SetRenderScale(Scale)
        self.PlayerSlot = PlayerSlot
        self.PlayerUI.Switch_Positioning:SetActiveWidgetIndex(2)
        self.PlayerUI.Canvas_DomainName:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.PlayerUI.Img_PositioningBG:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.PlayerUI.Img_TargetArrow:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.PlayerUI.WBP_HUD_Task_Icon:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.PlayerUI.EFF_3:SetVisibility(UE.ESlateVisibility.Collapsed)
        PicConst.SetImageBrush(self.PlayerUI.Icon_Teleport, self.MapIconData[tonumber(ShowId)].Icon)
    end
end

function WBP_HUD_MiniMap_Content:AddLegendData()
    local AllMapDatas = FirmUtil.GetMapLegendDataByMapId(self.MapId)
    if AllMapDatas == nil then
        return
    end
    for i, v in pairs(AllMapDatas) do
        
        local TypeData = FirmUtil.GetMapLegendTypeDataById(v.Legend_ID)
        local Legend_Positon = v.Legend_Positon
        local Location = UE.FVector(Legend_Positon[1],Legend_Positon[2], Legend_Positon[3])
        if Location then
          
            local LabelData={}
            LabelData.Location=Location
            LabelData.ShowId=i
            LabelData.IsGuide=1--TypeData.Legend_Guid
            LabelData.Type=TypeData.LegendType
            --self:AddLabel(Location, i, TypeData.Legend_Guide, TypeData.LegendType, nil, nil, nil)
            self:AddLabel(LabelData)
        end
    end
end

function WBP_HUD_MiniMap_Content:CheckIfOutCircle()
    self.Labels = self.CanvasPanel_Labels:GetAllChildren()
    if self.Labels then
        for i = 1, self.Labels:Length() do
            local Label = self.Labels:GetRef(i)
            self:EventLabelClassify(Label)
            
        end
    end
end

function WBP_HUD_MiniMap_Content:EventLabelClassify(InLabel)
   
    if InLabel ~= nil then
       
        if InLabel.IsTrace then
          
            self:EventLabelIsTrace(InLabel)
        
        elseif InLabel.IsGuide then
      
            self:EventLabelIsGuide(InLabel)
          
        elseif InLabel.Mission then
         
            self:EventLabelMission(InLabel)
         
        else
            
            self:EventLabelElse(InLabel)
    
        end

    end
   
end

function WBP_HUD_MiniMap_Content:EventLabelIsTrace(InLabel)
    local MarkPointLoc = InLabel.Location2D
    local Item = InLabel
    if self:IfOutCircle(MarkPointLoc) then
        self:AddFloat(MarkPointLoc, Item)
    else
        if Item.FloatUI ~= nil then
            Item.FloatUI:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
   
end
function WBP_HUD_MiniMap_Content:EventLabelIsGuide(InLabel)
    
    local GuideLabelLoc = InLabel.Location2D
   
    local Item = InLabel
   
    if self:IfOutSelfCircle(GuideLabelLoc) and self:IfOutCircle(GuideLabelLoc) then
        self:AddFloat(GuideLabelLoc, Item)
       
    else
        if Item.FloatUI ~= nil then
            Item.FloatUI:SetVisibility(UE.ESlateVisibility.Collapsed)
          
        end
    end
    
   
end

function WBP_HUD_MiniMap_Content:EventLabelMission(InLabel)
    local MissionLabelLoc = InLabel.Location2D
    local Item = InLabel
    if self:IfOutCircle(MissionLabelLoc) then
        self:AddFloat(MissionLabelLoc, Item)
    else
        if Item.FloatUI ~= nil then
            Item.FloatUI:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
 
end

function WBP_HUD_MiniMap_Content:EventLabelElse(InLabel)
    if InLabel.FloatUI ~= nil then
        InLabel.FloatUI:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
   
end


function WBP_HUD_MiniMap_Content:CheckMissionUI()
    local Labels = self.CanvasPanel_Labels:GetAllChildren()
    self.Labels = self.CanvasPanel_Labels:GetAllChildren()
    for i = 1, self.Labels:Length() do
        local Label = self.Labels:GetRef(i)
        if Label.Mission then
            Label.Mission = nil 
            self.CanvasPanel_Labels:RemoveChild(Label)
            if Label.FloatUI then
                self.CanvasPanel_FloatLabels:RemoveChild(Label.FloatUI)
            end
        end
    end
end

---@param Loc FVector2D
---@param Item WBP_FirmMapLabel
function WBP_HUD_MiniMap_Content:AddFloat(Loc, Item)
    self.Loc2D = Loc
   
    if Item.FloatUI == nil then
        local Scale = UE.FVector2D(SetCenter, SetCenter)
        ---@type WBP_FirmMapLabel
        Item.FloatUI = UE.UWidgetBlueprintLibrary.Create(self, self.LabelClass)
        if Item.FloatUI ~= nil then
           
            self:SetFloatUI(Item,Scale)
            
        end
    else

        self:EventIsItemTrace(Item)
        if Item.IsAnchor then
            PicConst.SetImageBrush(Item.FloatUI.Img_Target, tostring(Item.PicKey))
        else
            local TypeId = FirmUtil.GetMapLegendIdByType(Item.Type)
            PicConst.SetImageBrush(Item.FloatUI.Img_Target, tostring(self.MapIconData[tonumber(TypeId)].Icon))
        end
        if not Item.ScopeState then
            Item.FloatUI:SetVisibility(UE.ESlateVisibility.Visible)
            else
            Item.FloatUI:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
        
    end
    self:EventSetFloatUITranslation(Item)
  
end


function WBP_HUD_MiniMap_Content:EventSetFloatUITranslation(InItem)
    local RadiusX = self.SmallScreenSize.X / 2 - 30
    local RadiusY = self.SmallScreenSize.Y / 2 - 30
    local CenterPointX = self.ImageSize.X / 2
    local CenterPointY = self.ImageSize.Y / 2
    ---求全局图标和全局圆心的直线方程的斜率
    local K = (self.Loc2D.Y - self.ViewCentrePosition.Y) / (self.Loc2D.X - self.ViewCentrePosition.X)
    local M = self.Loc2D.Y - K * self.Loc2D.X

    local RelPosX = (self.Loc2D.X - self.ViewCentrePosition.X + self.DifferView.X) * self.CurrentScale
    local RelPosY = (self.Loc2D.Y - self.ViewCentrePosition.Y + self.DifferView.Y) * self.CurrentScale
    ---求相对位置的坐标
    self.XRel = RelPosX
    self.YRel = RelPosY
    ---求直线方程的斜率
    local m = (self.YRel - CenterPointY) / (self.XRel - CenterPointX)
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

    local Y1 = K * (X1 - CenterPointX) + CenterPointY
    local Y2 = K * (X2 - CenterPointX) + CenterPointY
    local Distance1 = math.sqrt((X1 - self.XRel) * (X1 - self.XRel) + (Y1 - self.YRel) * (Y1 - self.YRel))
    local Distance2 = math.sqrt((X2 - self.XRel) * (X2 - self.XRel) + (Y2 - self.YRel) * (Y2 - self.YRel))
    ---两个点比较最小距离
    if Distance1 < Distance2 then
        self.FloatLoc = UE.FVector2D(X1, Y1)
    else
        self.FloatLoc = UE.FVector2D(X2, Y2)
    end
    ---相对坐标转换为绝对坐标
    local NewLoc = UE.FVector2D(self.FloatLoc.X / self.CurrentScale + self.ViewBegin.X, self.FloatLoc.Y / self.CurrentScale + self.ViewBegin.Y)
    if InItem.FloatUI ~= nil then

        InItem.FloatUI:SetRenderTranslation(self.FloatLoc)
        local Vector = InItem.FloatUI.OldLocation - NewLoc
        local VecX = Vector.X
        local VecY = Vector.Y
        local Radians = math.atan(VecY, VecX)
        local Degrees = math.abs(Radians * (180 / math.pi))
       
    end
end

function WBP_HUD_MiniMap_Content:EventIsItemTrace(InItem)
    if InItem.IsTrace then
        if not InItem.FloatUI.WBP_HUD_Task_Icon:IsAnimationPlaying(InItem.FloatUI.WBP_HUD_Task_Icon.DX_IconTrackNormalLoop) then
            ---@type UCanvasPanelSlot
            local Slot = InItem.FloatUI.Slot
            Slot:SetZOrder(TRACE_ZORDER)
            InItem.FloatUI.WBP_HUD_Task_Icon:PlayAnimation(InItem.FloatUI.WBP_HUD_Task_Icon.DX_IconTrackNormalLoop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1, false)
        end
       
    else
        if InItem.FloatUI.WBP_HUD_Task_Icon:IsAnimationPlaying(InItem.FloatUI.WBP_HUD_Task_Icon.DX_IconTrackNormalLoop) then
            ---@type UCanvasPanelSlot
            local Slot = InItem.FloatUI.Slot
            Slot:SetZOrder(NORMAL_ZORDER)
            InItem.FloatUI.WBP_HUD_Task_Icon:StopAnimation(InItem.FloatUI.WBP_HUD_Task_Icon.DX_IconTrackNormalLoop)
        end
        
    end
end


function WBP_HUD_MiniMap_Content:SetFloatUI(InItem,InScale)
    InItem.FloatUI.Canvas_DomainName:SetVisibility(UE.ESlateVisibility.Collapsed)
    InItem.FloatUI.WBP_HUD_Task_Icon.Task_Icon_Switcher:SetVisibility(UE.ESlateVisibility.Collapsed)
    InItem.FloatUI.Img_PositioningBG:SetVisibility(UE.ESlateVisibility.Collapsed)
    InItem.FloatUI.Img_TargetArrow:SetVisibility(UE.ESlateVisibility.Collapsed)
    InItem.FloatUI.EFF_1:SetVisibility(UE.ESlateVisibility.Collapsed)
    InItem.FloatUI.EFF_2:SetVisibility(UE.ESlateVisibility.Collapsed)
    InItem.FloatUI.EFF_3:SetVisibility(UE.ESlateVisibility.Collapsed)
    if InItem.Mission then
        if InItem.Mission:GetMissionType() == 1 then
            InItem.FloatUI.WBP_HUD_Task_Icon:PlayAnimation(InItem.FloatUI.WBP_HUD_Task_Icon.DX_IconTrackMainLoop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1, false)
        end
        if InItem.Mission:GetMissionType() == 2 then
            InItem.FloatUI.WBP_HUD_Task_Icon:PlayAnimation(InItem.FloatUI.WBP_HUD_Task_Icon.DX_IconTrackDailyLoop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1, false)
        end
    else
        if InItem.IsTrace then
            InItem.FloatUI.WBP_HUD_Task_Icon:PlayAnimation(InItem.FloatUI.WBP_HUD_Task_Icon.DX_IconTrackNormalLoop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1, false)
        end
    end
            --Item.FloatUI.Img_TargetArrow:SetRenderTransformPivot(UE.FVector2D(0.5, 3))
    InItem.FloatUI:SetRenderScale(InScale)
    InItem.FloatUI.OldLocation = self.Loc2D

    InItem.FloatUI.Switch_Positioning:SetActiveWidgetIndex(1)
    InItem.FloatUI.Switch_Positioning:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if InItem.IsAnchor then
        PicConst.SetImageBrush(InItem.FloatUI.Img_Target, tostring(InItem.PicKey))
    else
        if InItem.Mission then
            local MissionType = InItem.Mission:GetMissionType()
            InItem.FloatUI.WBP_HUD_Task_Icon:SetVisibility(UE.ESlateVisibility.Visible)
            InItem.FloatUI.WBP_HUD_Task_Icon.Task_Icon_Switcher:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            InItem.FloatUI.WBP_HUD_Task_Icon.Task_Icon_Switcher:SetActiveWidgetIndex(MissionType)
            InItem.FloatUI.Switch_Positioning:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
        local TypeId = FirmUtil.GetMapLegendIdByType(InItem.Type)
        PicConst.SetImageBrush(InItem.FloatUI.Img_Target, tostring(self.MapIconData[tonumber(TypeId)].Icon))
    end
    self.FloatUI = InItem.FloatUI
    self.CanvasPanel_FloatLabels:AddChildToCanvas(InItem.FloatUI)
    if InItem.IsTrace then
        ---@type UCanvasPanelSlot
        local Slot = InItem.FloatUI.Slot
        Slot:SetZOrder(TRACE_ZORDER)
    end
       
end

---@param Loc FVector2D
function WBP_HUD_MiniMap_Content:IfOutCircle(Loc)
    if Loc then
        local Location = Loc
        if Location.X < self.ViewBegin.X or Location.X > self.ViewEnd.X or Location.Y < self.ViewBegin.Y or Location.Y > self.ViewEnd.Y then
            return true
        end
        return false
    end
end

---@param Loc FVector2D
function WBP_HUD_MiniMap_Content:IfOutSelfCircle(Loc)
    if Loc and self.PlayerLoc2D then
        local Distance = math.sqrt((Loc.X - self.PlayerLoc2D.X) * (Loc.X - self.PlayerLoc2D.X) + (Loc.Y - self.PlayerLoc2D.Y) * (Loc.Y - self.PlayerLoc2D.Y))
        if Distance < Target_Guidance_Range then
            return true
        end
        return false
    end
end

---3D坐标转2D坐标，基于CurrentScale为1时的转换
---@param Location FVector
---@return FVector2D
function WBP_HUD_MiniMap_Content:Location2Map2D(Location)
    if Location.X < LocationBegin.X or Location.X > LocationEnd.X or Location.Y < LocationBegin.Y or Location.Y > LocationEnd.Y then
        if not self.Error then
            G.log:error("ghgame", "Error! Location not in MiniMap,LocationX:%f,LocationY:%f,LocationBeginX:%f,LocationBeginY:%f,LocationEndX:%f,LocationEndY:%f", Location.X, Location.Y,
                    LocationBegin.X, LocationBegin.Y, LocationEnd.X, LocationEnd.Y)
            self.Error = true
        end
        return nil
    end
    return UE.FVector2D((Location.X - LocationBegin.X) / (LocationEnd.X - LocationBegin.X) * self.ImageSize.X, (Location.Y - LocationBegin.Y) / (LocationEnd.Y - LocationBegin.Y) * self.ImageSize.Y)
end

---@param Location2D FVector2D
function WBP_HUD_MiniMap_Content:MoveToLocation2D(Location2D)
    if Location2D == nil or Location2D.X == nil or Location2D.Y == nil then
        return
    end
    if type(Location2D.X) == "number"and type(Location2D.Y) == "number" then
        local Translation = (self.InitViewCentrePosition - Location2D) * self.CurrentScale
        local Min, Max = self:GetTranslationRange()
        --Translation.X = UE.UKismetMathLibrary.FClamp(Translation.X, Min.X, Max.X)
        --Translation.Y = UE.UKismetMathLibrary.FClamp(Translation.Y, Min.Y, Max.Y)
    
        self.ScaleBox_Content:SetRenderTranslation(Translation)
    end
    self:CalcViewRange()

    self:CalcGridLoad()
end

function WBP_HUD_MiniMap_Content:CalcGridLoad()
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

    for r = 1, Row do
        for c = 1, Column do
            if (r >= BeginY and r <= EndY) and (c >= BeginX and c <= EndX) then
                self:LoadChildImage(r, c)
                self.ChildImages[r][c].Labels = {}
            else
                self:UnLoadChildImage(r, c)
            end
        end
    end
    self:TrimLabel()
end

---整理图标
function WBP_HUD_MiniMap_Content:TrimLabel()
    local BeginTranslation = self.ScaleBox_Content.RenderTransform.Translation
    local BeginLocationX = BeginTranslation.X - (self.CurrentScale - 1) * self.ImageSize.X / 2
    local BeginLocationY = BeginTranslation.Y - (self.CurrentScale - 1) * self.ImageSize.Y / 2
    self.Labels = self.CanvasPanel_Labels:GetAllChildren()
    for i = 1, self.Labels:Length() do
        local Label = self.Labels:GetRef(i)
        if Label ~= nil then
            if Label.Location2D then
                local X = self.CurrentScale * Label.Location2D.X + BeginLocationX
                local Y = self.CurrentScale * Label.Location2D.Y + BeginLocationY
                Label:SetRenderTranslation(UE.FVector2D(X, Y))
            end
        end
    end
    --for _, Label in ipairs(self.Labels) do
    --    if Label ~= nil then
    --        if Label.Location2D then
    --            local X = self.CurrentScale * Label.Location2D.X + BeginLocationX
    --            local Y = self.CurrentScale * Label.Location2D.Y + BeginLocationY
    --            Label:SetRenderTranslation(UE.FVector2D(X, Y))
    --        end
    --    end
    --end
end

---计算视觉范围
---@private
function WBP_HUD_MiniMap_Content:CalcViewRange()
    ---计算中心点
    local Translation = self.ScaleBox_Content.RenderTransform.Translation
    self.ViewCentrePosition = self.InitViewCentrePosition - Translation / self.CurrentScale

    self.ViewBegin = UE.FVector2D(math.abs(self.ViewCentrePosition.X - self.ImageSize.X / (2 * self.CurrentScale)), math.abs(self.ViewCentrePosition.Y - self.ImageSize.Y / (2 * self.CurrentScale)))
    self.ViewEnd = UE.FVector2D(math.abs(self.ViewCentrePosition.X + self.ImageSize.X / (2 * self.CurrentScale)), math.abs(self.ViewCentrePosition.Y + self.ImageSize.Y / (2 * self.CurrentScale)))

end

---@return FVector2D,FVector2D @Min,Max
function WBP_HUD_MiniMap_Content:GetTranslationRange()
    local ScreenSize = self.SmallScreenSize
    local ImageSize = self.ImageSize
    local MaxX = (ImageSize.X * self.CurrentScale - ImageSize.X) / 2
    local MaxY = (ImageSize.Y * self.CurrentScale - ImageSize.Y) / 2
    local MinX = ImageSize.X - ScreenSize.X + MaxX
    local MinY = ImageSize.Y - ScreenSize.Y + MaxY

    return UE.FVector2D(-MinX, -MinY), UE.FVector2D(MaxX, MaxY)
end

---@param R integer
---@param C integer
function WBP_HUD_MiniMap_Content:LoadChildImage(R, C)
    local Child = self.ChildImages[R][C]
    if Child and Child.Image then
        return
    end
    ---@type WBP_FirmMapChildImage_C
    local ChildImage = UE.UWidgetBlueprintLibrary.Create(self, self.ChildImageClass)
    PicConst.SetImageBrush(ChildImage.Img_Map, string.format("UI_Firm_%s_%d_%d", tostring(self.MapId), R - 1, C - 1))
    ChildImage.TextBlock_Grid:SetText(string.format("%d , %d", R, C))
    ChildImage.TextBlock_Grid:SetVisibility(UE.ESlateVisibility.Hidden)
    self.GridPanel_Image:AddChildToGrid(ChildImage, R - 1, C - 1)
    self.ChildImages[R][C] = {
        Image = ChildImage
    }
end

---@param R integer
---@param C integer
function WBP_HUD_MiniMap_Content:UnLoadChildImage(R, C)
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

return WBP_HUD_MiniMap_Content
