--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
---@alias AnchorItemSelectedCallBackT fun(Owner:UObject, AnchorItem:string)

local G = require('G')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local ConstText = require("CP0032305_GH.Script.common.text_const")
local FirmMapLegendTypeTableConst = require("common.data.firm_map_legend_type_data")
local FirmUtil = require("CP0032305_GH.Script.ui.view.ingame.Firm.FirmUtil")

---@class MapIconsData
---@field Icon string
---@field ShowIcon string
---@field bIsSelected boolean
---@field bIsRewards boolean


---@class WBP_Firm_Map : WBP_Firm_Map_C
---@field IsRightPopupVisible boolean
---@field WBP_Firm_Content WBP_Firm_Content
---@field bIsTransmitOffice boolean
---@field bIsTransmitOffice boolean 是否是传送事务所
---@field bIsDetailPopup boolean 是否是详情弹窗
---@field bIsAnchorPopup boolean 是否是锚点弹窗
---@field CurMissionObject MissionObject

---@type WBP_Firm_Map
local WBP_Firm_Map = Class(UIWindowBase)

---@param self WBP_Firm_Map
local function PlayOutMapAreaAnim(self)
    if self.WBP_Firm_Content.Labels then
        for i, v in ipairs(self.WBP_Firm_Content.Labels) do
            if v.Type == FirmMapLegendTypeTableConst.BigAreaName or v.Type == FirmMapLegendTypeTableConst.SmallAreaName then
                if v.bIsVisible then
                    v:PlayAnimation(v.DX_DomainNameOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
                    v.IsPlayingAnim = false
                end
            end
        end
    end
end

---@param self WBP_Firm_Map
local function OnClickTopCloseButton(self)
    self:PlayAnimation(self.DX_BtnEnterOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    PlayOutMapAreaAnim(self)
    local DelayTime = self.DX_BtnEnterOut:GetEndTime()
    UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, function()
        UIManager:CloseUI(self)
    end }, DelayTime, false)
    if self.Firm_MapOptions ~= nil then
        self.Firm_MapOptions:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.WBP_Firm_Content.bShowMapOptions = false
    end
    local MiniMap = self.WBP_Firm_Content.MiniMap
    if MiniMap then
        local PlayerLoc2D = MiniMap.WBP_HUD_MiniMap_Content.PlayerLoc2D
        MiniMap.WBP_HUD_MiniMap_Content:MoveToLocation2D(PlayerLoc2D)
        MiniMap.WBP_HUD_MiniMap_Content:CheckIfOutCircle()
    end
end

local function ComparisonCoordinate(PositionOne, PositionTwo)
    if PositionOne and PositionTwo then
        if math.abs(PositionOne.X - PositionTwo.X) < 1 and math.abs(PositionOne.Y - PositionTwo.Y) < 1 then
            return true
        end
    end
end

---@param self WBP_Firm_Map
local function OnClickTransmitButton(self)
    local Avatar = UE.UGameplayStatics.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
    if Avatar == nil then
        G.log:warn("ghgame", "Error! Avatar is nil")
        return
    end
    if Avatar.TeleportComponent == nil then
        G.log:warn("ghgame", "Error! Avatar.TeleportComponent is nil")
        return
    end
    if Avatar.TeleportComponent.Server_TeleportToOffice == nil then
        G.log:warn("ghgame", "Error! Avatar.TeleportComponent.Server_TeleportToOffice is nil")
        return
    end

    Avatar.TeleportComponent:Server_TeleportToOffice()

    UIManager:CloseUI(self)
    UIManager:OpenUI(UIDef.UIInfo.UI_FirmLoading, 1)
end

---@param self WBP_Firm_Map
local function OnClickEnterFirm(self)
    self.bIsTransmitOffice = true
    self.IsRightPopupVisible = not self.IsRightPopupVisible
    if self.IsRightPopupVisible == true then
        self:ShowRightPopupWindow()
        self.WBP_Firm_SidePopupWindow:ShowEnterOfficeInterface(self)
    else
        self:HideRightPopupWindow()
        self.bIsTransmitOffice = false
        self.WBP_Firm_Content:ResetAnchorData()
    end
end

---@param self WBP_Firm_Map
local function OnClickEnterCloudIsland(self)
    G.log:debug("ghgame", ">>>WBP_Firm_Map:OnClickEnterCloudIsland")
end

---@param self WBP_Firm_Map
local function RemoveTrackIcon(self, Index)
    local Row = self.WBP_Firm_Content.Labels[Index].GridLocation.X
    local Column = self.WBP_Firm_Content.Labels[Index].GridLocation.Y
    if self.WBP_Firm_Content.ChildImages[Row] ~= nil and self.WBP_Firm_Content.ChildImages[Row][Column] ~= nil then
        for i, v in ipairs(self.WBP_Firm_Content.ChildImages[Row][Column].Labels) do
            if ComparisonCoordinate(v.Location2D, self.WBP_Firm_Content.Labels[Index].Location2D) then
                table.remove(self.WBP_Firm_Content.ChildImages[Row][Column].Labels, i)
            end
        end
    end
    table.remove(self.WBP_Firm_Content.Labels, Index)
end

---检查地图的头部下拉框是否显示
function WBP_Firm_Map:CheckMapHeadIsShow()
    if self.WBP_Firm_MapHeadline.bIsClicked then
        self.WBP_Firm_MapHeadline.Canvas_MapHeadline:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.WBP_Firm_MapHeadline.bIsClicked = false
    end
end

---@param Mission MissionObject
function WBP_Firm_Map:TransferMissionData(Mission)
    if Mission then
        self.CurMissionObject = Mission
        local MissionId = Mission:GetMissionID()
        local MissionPosition = Mission:GetFirstTrackTargetPosition()
        local TypeId = FirmUtil.GetMapLegendIdByType(FirmMapLegendTypeTableConst.Task)

        if #self.WBP_Firm_Content.Labels > 0 then
            for i = #self.WBP_Firm_Content.Labels, 1, -1 do
                local v = self.WBP_Firm_Content.Labels[i]
                if v.Mission then
                    v:RemoveFromParent()
                    v.Mission = nil
                    RemoveTrackIcon(self, i)
                    if v.FloatUI then
                        v.FloatUI:RemoveFromParent()
                    end
                end
            end
        end
      
        if Mission:IsTracking() then
            
            local MissionTrackList = Mission:GetTrackTargetList()
            for i = 1, MissionTrackList:Length(), 1 do
                if MissionPosition and TypeId then
                    local TrackLocation=Mission:GetTrackTargetPosition(MissionTrackList[i])
                    self.WBP_Firm_Content:AddLabel(TrackLocation, TypeId, FirmMapLegendTypeTableConst.Task, false, nil, nil, nil, Mission)
                    
                end
                if self.WBP_Firm_Content.CurTraceItem then
                    if self.WBP_Firm_Content.CurTraceItem.Mission ~= nil then
                        if self.WBP_Firm_Content.CurTraceItem.Mission:GetMissionType() == 1 then
                            self.WBP_Firm_Content.CurTraceItem.WBP_HUD_Task_Icon:PlayAnimation(self.WBP_Firm_Content.CurTraceItem.WBP_HUD_Task_Icon.DX_IconTrackMainLoop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1, false)
                        end
                        if self.WBP_Firm_Content.CurTraceItem.Mission:GetMissionType() == 2 then
                            self.WBP_Firm_Content.CurTraceItem.WBP_HUD_Task_Icon:PlayAnimation(self.WBP_Firm_Content.CurTraceItem.WBP_HUD_Task_Icon.DX_IconTrackDailyLoop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1, false)
                        end
                    else
                        if self.WBP_Firm_Content.CurTraceItem.IsTrace then
                            self.WBP_Firm_Content.CurTraceItem.WBP_HUD_Task_Icon:PlayAnimation(self.WBP_Firm_Content.CurTraceItem.WBP_HUD_Task_Icon.DX_IconTrackNormalLoop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1, false)
                        end 
                    end
                end
            end
            --self.WBP_Firm_Content:CheckLabelInScreen()
        end
       
    end
end

---显示侧边弹窗
function WBP_Firm_Map:ShowRightPopupWindow()
    self.WBP_Firm_SidePopupWindow:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if self.Firm_MapOptions then
        self.Firm_MapOptions:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    self.WBP_Firm_SidePopupWindow.WBP_ComBtn_Close:SetVisibility(UE.ESlateVisibility.Visible)
    self.WBP_Firm_SidePopupWindow:StopAnimation(self.WBP_Firm_SidePopupWindow.DX_RightOut)
    self.WBP_Firm_SidePopupWindow:PlayAnimation(self.WBP_Firm_SidePopupWindow.DX_RightIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)

end

---隐藏侧边弹窗
function WBP_Firm_Map:HideRightPopupWindow()
    self.WBP_Firm_SidePopupWindow:StopAnimation(self.WBP_Firm_SidePopupWindow.DX_RightIn)
    self.WBP_Firm_SidePopupWindow:PlayAnimation(self.WBP_Firm_SidePopupWindow.DX_RightOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    self.WBP_Firm_SidePopupWindow:SetVisibility(UE.ESlateVisibility.Collapsed)
    --self.WBP_Firm_SidePopupWindow.WBP_ComBtn_Close:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function WBP_Firm_Map:OnConstruct()
    self.WBP_Common_TopContent.CommonButton_Close.OnClicked:Add(self, OnClickTopCloseButton)
    self.WBP_ComBtn_Firm.Button.OnClicked:Add(self, OnClickEnterFirm)
    self.WBP_ComBtn_CloudIsland.Button.OnClicked:Add(self, OnClickEnterCloudIsland)
    local MapId = FirmUtil.GetCurrentMapId(self)
    self.WBP_Firm_Content:Init(self, MapId)
    if self.WBP_Firm_SidePopupWindow:IsValid() == false then
        return
    else
        self.WBP_Firm_SidePopupWindow:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
  
   
end

function WBP_Firm_Map:RemoveAnchorFromMap()
    if self.WBP_Firm_Content.Labels then
        for i, v in ipairs(self.WBP_Firm_Content.Labels) do
            if self.WBP_Firm_SidePopupWindow.CurrentSelectedAnchorItemPicKey == v.PicKey and ComparisonCoordinate(self.WBP_Firm_Content.Pos, v.Location2D) then
                if self.WBP_Firm_Content.Labels[i] ~= nil and self.WBP_Firm_Content.Labels[i].GridLocation ~= nil then
                    local Row = self.WBP_Firm_Content.Labels[i].GridLocation.X
                    local Column = self.WBP_Firm_Content.Labels[i].GridLocation.Y
                    if self.WBP_Firm_Content.ChildImages[Row] ~= nil and self.WBP_Firm_Content.ChildImages[Row][Column] ~= nil then
                        for j, v in ipairs(self.WBP_Firm_Content.ChildImages[Row][Column].Labels) do
                            if ComparisonCoordinate(v.Location2D, self.WBP_Firm_Content.Labels[i].Location2D) then
                                table.remove(self.WBP_Firm_Content.ChildImages[Row][Column].Labels, j)
                            end
                        end
                    end
                end
                table.remove(self.WBP_Firm_Content.Labels, i)
            end
        end
    end
end

---@param FirmSideWidow WBP_Firm_SidePopupWindow
function WBP_Firm_Map:DisplayEffectAfterRemoval(FirmSideWidow)
    if self.WBP_Firm_Content.bIsOpenCustomInterface then
        if self.WBP_Firm_SidePopupWindow.FirmMarkerPointsItem ~= nil and self.WBP_Firm_SidePopupWindow.bKeepMarkerVisible == false then
            self.WBP_Firm_SidePopupWindow.FirmMarkerPointsItem:RemoveFromParent()
            self.WBP_Firm_SidePopupWindow.FirmMarkerPointsItem = nil
            self.WBP_Firm_SidePopupWindow.PreviousAnchor = nil
            self.WBP_Firm_SidePopupWindow.bIsOnClickedAnchor = false
            self:RemoveAnchorFromMap()
            self:CheckMapHeadIsShow()
            self:HideRightPopupWindow()
            self.WBP_Firm_Content:ResetAnchorData()
            self.WBP_Firm_Content.bIsOpenCustomInterface = false
            self.bIsAnchorPopup = false
        end
    end
end

---@param AnchorTypeId string
---@return boolean
function WBP_Firm_Map:CheckLegendInRange(AnchorTypeId)
    local AnchorData = self.WBP_Firm_Content:GetFirmMapLegendTypeData(AnchorTypeId)
    if AnchorData then
        local ScaleMin = AnchorData.Legend_Scale[1]
        local ScaleMax = AnchorData.Legend_Scale[2]
        local bIsScaleInRange = self.WBP_Firm_Content.CurrentScale >= ScaleMin * self.WBP_Firm_Content.PreSetScale and self.WBP_Firm_Content.CurrentScale <= ScaleMax * self.WBP_Firm_Content.PreSetScale
        return bIsScaleInRange
    end
end

---@param LabelsUI WBP_FirmMapLabel
---@param MapIconData MapIconsData[]
---@param ShowId integer
---@param Labels WBP_FirmMapLabel[]
---@param ActorId string
---@param IsPlayer boolean
function WBP_Firm_Map:LabelClick(LabelsUI, MapIconData, ShowId, Labels, ActorId, IsPlayer)
    if ShowId ~= nil then
        local LegendId = self.WBP_Firm_Content:GetFirmMapLegendData(ShowId).Legend_ID
        if LegendId ~= nil and MapIconData[tonumber(LegendId)].Icon ~= nil and IsPlayer == false then
            self:DisplayEffectAfterRemoval()
            self.bIsDetailPopup = true
            self:CheckIfLabelsClose(Labels, LabelsUI.TempId, Labels, MapIconData)
        end
        self:CheckMapHeadIsShow()
    end
    self.WBP_Firm_Content.bIsOpenCustomInterface = false
end

---@param LabelsUI WBP_FirmMapLabel
---@param Type integer
function WBP_Firm_Map:OnHoveredLabel(LabelsUI, Type)
    if LabelsUI and Type then
        local LegendId = FirmUtil.GetMapLegendIdByType(Type)
        local LegendData = self.WBP_Firm_Content:GetFirmMapLegendTypeData(LegendId)
        if LegendData and LegendData.Legend_Hover_Text then
            LabelsUI.Txt_Function:SetText(ConstText.GetConstText(LegendData.Legend_Name))
            LabelsUI:StopAnimation(LabelsUI.DX_TextOut)
            LabelsUI:PlayAnimation(LabelsUI.DX_TextIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
        end
    end
end

---@param LabelsUI WBP_FirmMapLabel
---@param Type integer
function WBP_Firm_Map:OnUnHoveredLabel(LabelsUI, Type)
    local LegendId = FirmUtil.GetMapLegendIdByType(Type)
    local LegendData = self.WBP_Firm_Content:GetFirmMapLegendTypeData(LegendId)
    if LegendData and LegendData.Legend_Hover_Text then
        LabelsUI:StopAnimation(LabelsUI.DX_TextIn)
        LabelsUI:PlayAnimation(LabelsUI.DX_TextOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    end
end

---点击浮标
---@param Key integer
---@param AllFloatUI WBP_FirmMapLabel[]
---@param FloatUISize FVector2D
function WBP_Firm_Map:FloatLabelClick(Key, AllFloatUI, FloatUISize)
    local AllFloat = AllFloatUI
    self.OverlapFloatUI = {}

    for i = 1, #AllFloatUI do
        if AllFloatUI[i].TempId == Key then
            self.CurrentFloatUI = AllFloatUI[i]
            self.FloatLoc = AllFloat[i].Location2D
            self.OldLabelLoc = AllFloat[i].OldLocation
            ---@type UCanvasPanelSlot
            local CanvasSlot = self.CurrentFloatUI.WBP_Map_PositioningTeleport.Slot
            self.FloatUISize = CanvasSlot:GetSize()
        end
    end
    ---不需要合并列表，直接跳转
    self.WBP_Firm_Content:MoveToLocation2D(self.OldLabelLoc)
    ---点击浮标遍历比较所有浮标位置判断是否有重叠事件
    -- for m = 1, #AllFloat do
    --     if AllFloat[m].TempId ~= self.CurrentFloatUI.TempId then
    --         if AllFloat[m].Location2D then
    --             local DifferenceX = math.abs(AllFloat[m].Location2D.X - self.CurrentFloatUI.Location2D.X)
    --             local DifferenceY = math.abs(AllFloat[m].Location2D.Y - self.CurrentFloatUI.Location2D.Y)
    --             if DifferenceY < self.FloatUISize.Y and DifferenceX < self.FloatUISize.X then
    --                 table.insert(self.OverlapFloatUI, AllFloat[m])
    --             end
    --         end
    --     end
    -- end
    
    -- if #self.OverlapFloatUI > 0 then
    --     ---重叠
    --     table.insert(self.OverlapFloatUI, self.CurrentFloatUI)
    --     if self.Firm_MapOptions == nil then
    --         ---@type WBP_Firm_MapOptions_C
    --         self.Firm_MapOptions = UE.UWidgetBlueprintLibrary.Create(self, self.MapOptions)
    --         self.WBP_Firm_Content.CanvasPanel_OptionsContent:AddChildToCanvas(self.Firm_MapOptions)
    --     else
    --         self.Firm_MapOptions:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    --     end
    --     ---设置菜单选项的位置
    --     local CenterPos = self.WBP_Firm_Content.ViewCentrePosition
    --     if self.FloatLoc.Y < CenterPos.Y then
    --         self.NewLocY = self.FloatLoc.Y + 150
    --         self.NewLocX = self.FloatLoc.X
    --         local NewLoc = UE.FVector2D(self.NewLocX, self.NewLocY)
    --         self.Firm_MapOptions:SetRenderTranslation(NewLoc)

    --     elseif self.FloatLoc.X > CenterPos.X then
    --         self.NewLocX = self.FloatLoc.X - 200
    --         self.NewLocY = self.FloatLoc.Y
    --         local NewLoc = UE.FVector2D(self.NewLocX, self.NewLocY)
    --         self.Firm_MapOptions:SetRenderTranslation(NewLoc)
    --     else
    --         self.Firm_MapOptions:SetRenderTranslation(self.FloatLoc)
    --     end
    --     self.WBP_Firm_Content:MoveToLocation2D(self.CurrentFloatUI)
    --     --self.Firm_MapOptions:ShowFloatOptionsData(self.OverlapFloatUI, self)
    -- else
    --     ---不重叠直接移到该位置
        
    -- end
end

---点击地图上的图标
---@param Labels WBP_FirmMapLabel[]
---@param Key integer
function WBP_Firm_Map:OnClickMarkerPointsItem(Labels, Key)
    G.log:debug("xuexiaoyu", "WBP_Firm_Map:OnClickMarkerPointsItem ClickAnchor")
    if Labels and Key then
        self:DisplayEffectAfterRemoval()
        self:CheckIfLabelsClose(Labels, Key, self.WBP_Firm_Content.MarkerPointsItems)
        self:CheckMapHeadIsShow()
    end
end

---@param Labels WBP_FirmMapLabel[]
---@param Key integer
---@param LimitedLabels WBP_FirmMapLabel[]
---@param MapIconData MapIconsData[]
function WBP_Firm_Map:CheckIfLabelsClose(Labels, Key, LimitedLabels, MapIconData)
    self.CloseLabels = {}
    self.AllLabelsData = {}
    local Labels = Labels
    for i = 1, #Labels do
        if Labels[i] then
            if Labels[i].Type ~= FirmMapLegendTypeTableConst.PlayerPosition  then
                local LegendData = nil
                local NameData = nil
                if Labels[i].IsAnchor then
                    if Labels[i].AnchorName == nil or Labels[i].AnchorName == "" then
                        LegendData = self.WBP_Firm_Content:GetFirmMapLegendTypeData(Labels[i].ShowId)
                        NameData = LegendData.Legend_Name
                        Labels[i].AnchorName = ConstText.GetConstText(NameData)
                    end
                else
                    if Labels[i].AnchorName == nil or Labels[i].AnchorName == "" then
                        LegendData = self.WBP_Firm_Content:GetFirmMapLegendData(Labels[i].ShowId)
                        NameData = LegendData.Legend_Name
                        if NameData == nil or NameData == "" then
                            NameData = self.WBP_Firm_Content:GetFirmMapLegendTypeData(LegendData.Legend_ID).Legend_Name
                        end
                        Labels[i].AnchorName = ConstText.GetConstText(NameData)
                    end
                end
                if Labels[i].TempId == Key then
                    self.CurrentLabel = Labels[i]
                end
            end
        end

    end

    if self.CurrentLabel and self.CurrentLabel.TempId == Key then
        if self.CurrentLabel.Type ~= FirmMapLegendTypeTableConst.BigAreaName and self.CurrentLabel.Type ~= FirmMapLegendTypeTableConst.SmallAreaName then
            local LabelRow = self.CurrentLabel.GridLocation.X
            local LabelColumn = self.CurrentLabel.GridLocation.Y
            ---获得当前图标所在格子的相邻格子数据
            local AdjacentCells = self.WBP_Firm_Content.UniqueCells
            if AdjacentCells then
                for i = 1, #AdjacentCells do
                    local GridData = AdjacentCells[i]
                    local row = GridData[1]
                    local column = GridData[2]
                    local AdjacentLabelsData = self.WBP_Firm_Content.ChildImages[row][column].Labels
                    if AdjacentLabelsData ~= nil and #AdjacentLabelsData > 0 then
                        table.insert(self.AllLabelsData, AdjacentLabelsData)
                    end
                end
            end
            ---获得当前点击图标所在地图格子上所有的图标数据
            --local LabelsData = self.WBP_Firm_Content.ChildImages[LabelRow][LabelColumn].Labels
            --table.insert(self.AllLabelsData, LabelsData)
            local ViewBegin = self.WBP_Firm_Content.ViewBegin
            local CurrentScale = self.WBP_Firm_Content.CurrentScale
            for i = 1, #self.AllLabelsData do
                local AllLabelsData = self.AllLabelsData[i]
                for m = 1, #AllLabelsData do
                    if AllLabelsData[m].TempId ~= self.CurrentLabel.TempId and AllLabelsData[m].TempId ~= nil and AllLabelsData[m].bIsVisible and AllLabelsData[m].Type ~= FirmMapLegendTypeTableConst.PlayerPosition then
                        if AllLabelsData[m].Type ~= FirmMapLegendTypeTableConst.BigAreaName and AllLabelsData[m].Type ~= FirmMapLegendTypeTableConst.SmallAreaName then
                            local DifferX = math.abs((AllLabelsData[m].Location2D.X - ViewBegin.X) * CurrentScale - (self.CurrentLabel.Location2D.X - ViewBegin.X) * CurrentScale)
                            local DifferY = math.abs((AllLabelsData[m].Location2D.Y - ViewBegin.Y) * CurrentScale - (self.CurrentLabel.Location2D.Y - ViewBegin.Y) * CurrentScale)
                            self.Differ = math.sqrt(DifferX * DifferX + DifferY * DifferY)
                            ---需要配置最短距离目前用临时的
                            if self.Differ < self.WBP_Firm_Content.IconMergeDistance then
                                table.insert(self.CloseLabels, AllLabelsData[m])
                            end
                        end
                    end
                end
            end
            if #self.CloseLabels < 1 then
                if self.IsRightPopupVisible == true or self.bIsDetailPopup == true then
                    self:HideRightPopupWindow()
                    self.WBP_Firm_Content:ResetAnchorData()
                    self.bIsDetailPopup = false
                    self.IsRightPopupVisible = false
                end
                if self.WBP_Firm_Content.bIsOpenCustomInterface == true or self.bIsAnchorPopup == true then
                    self:HideRightPopupWindow()
                    self.WBP_Firm_Content:ResetAnchorData()
                    self.WBP_Firm_Content.bIsOpenCustomInterface = false
                    self.bIsAnchorPopup = false
                end
                if self.CurrentLabel.TempId == Key then
                    --self.bIsAnchorPopup = true
                    self:ShowRightPopupWindow()
                    self.WBP_Firm_SidePopupWindow:ShowEnterOfficeInterface(self)
                    if self.CurrentLabel.IsAnchor then
                        self.bIsAnchorPopup = true
                        self.WBP_Firm_SidePopupWindow:InitOnClickedMarkerPoints(self.WBP_Firm_Content, Labels, Key)
                    else
                        self.bIsDetailPopup = true
                        self.IsRightPopupVisible = true
                        self.WBP_Firm_SidePopupWindow:InitPopupWindowData(0, nil)
                        self.WBP_Firm_SidePopupWindow:InitOnClickedLabel(self, self.CurrentLabel, MapIconData, self.CurrentLabel.ShowId, Labels, self.CurrentLabel.ActorId, Key, self.WBP_Firm_Content)
                    end
                end
            end
            if #self.CloseLabels > 0 then
                self.IsRightPopupVisible = false
                self.bIsDetailPopup = false
                table.insert(self.CloseLabels, self.CurrentLabel)
                if self.Firm_MapOptions == nil then
                    ---@type WBP_Firm_MapOptions_C
                    self.Firm_MapOptions = UE.UWidgetBlueprintLibrary.Create(self, self.MapOptions)
                    self.WBP_Firm_Content.CanvasPanel_OptionsContent:AddChildToCanvas(self.Firm_MapOptions)
                    self.WBP_Firm_Content.bShowMapOptions = true
                elseif self.CurrentLabel.TempId == Key then
                    self.Firm_MapOptions:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                    self.WBP_Firm_Content.bShowMapOptions = true
                end
                local OptionsLocX = (self.WBP_Firm_Content.ScreenPosCenter.X - self.WBP_Firm_Content.ViewBegin.X) * self.WBP_Firm_Content.CurrentScale
                local OptionsLocY = (self.WBP_Firm_Content.ScreenPosCenter.Y - self.WBP_Firm_Content.ViewBegin.Y) * self.WBP_Firm_Content.CurrentScale
                --local OptionsLocX = (self.CurrentLabel.Location2D.X - self.WBP_Firm_Content.ViewBegin.X) * self.WBP_Firm_Content.CurrentScale
                --local OptionsLocY = (self.CurrentLabel.Location2D.Y - self.WBP_Firm_Content.ViewBegin.Y) * self.WBP_Firm_Content.CurrentScale
                local OptionsLoc = UE.FVector2D(OptionsLocX, OptionsLocY)
                self.Firm_MapOptions:SetRenderTranslation(OptionsLoc)
                self.Firm_MapOptions:ShowLabelOptionsData(self.CloseLabels, self)
            end
        end
    end
end

function WBP_Firm_Map:OnDestruct()
    self.WBP_Common_TopContent.CommonButton_Close.OnClicked:Remove(self, OnClickTopCloseButton)
    self.WBP_ComBtn_Firm.Button.OnClicked:Remove(self, OnClickEnterFirm)
    self.WBP_ComBtn_CloudIsland.Button.OnClicked:Remove(self, OnClickEnterCloudIsland)
end

---检查图例是否被追踪
function WBP_Firm_Map:CheckAnchorTraceState()
    for i, v in ipairs(self.WBP_Firm_Content.Labels) do
        if v.IsTrace then
            self.WBP_Firm_Content.Labels[i].DX_Target_Track:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.WBP_Firm_Content.Labels[i]:PlayAnimation(self.WBP_Firm_Content.Labels[i].DX_TrackLoop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1, false)
        end
    end
end

function WBP_Firm_Map:OnShow()
    self.IsRightPopupVisible = false
    self.bIsOnClicked = false
    self.bIsTransmitOffice = false
    self.bIsDetailPopup = false
    self.bIsAnchorPopup = false
    self.WBP_QuickEnter_Firm.Switcher_QuickEnterIon:SetActiveWidgetIndex(0)
    self.WBP_QuickEnter_CloudIsland.Switcher_QuickEnterIon:SetActiveWidgetIndex(1)
    self.WBP_Firm_Content:OnShow()
    self.WBP_Firm_MapHeadline.Canvas_MapHeadline:SetVisibility(UE.ESlateVisibility.Collapsed)
    self:PlayAnimation(self.DX_BtnEnterIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    self:CheckAnchorTraceState()
    ---@type TaskActVM
    local TaskActVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskActVM.UniqueName)
    if TaskActVM:HasCompleteMainAct() then
        ---@type WBP_Common_RedDot
        local WBP_Common_RedDot = self.WBP_Common_RedDot01
        WBP_Common_RedDot:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        WBP_Common_RedDot:ShowGift()
    elseif TaskActVM:HasInitializeMainAct() then
        ---@type WBP_Common_RedDot
        local WBP_Common_RedDot = self.WBP_Common_RedDot01
        WBP_Common_RedDot:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        WBP_Common_RedDot:ShowNew()
    else
        self.WBP_Common_RedDot01:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function WBP_Firm_Map:OnHide()
    self.IsRightPopupVisible = false
    self.bIsDetailPopup = false
    self:HideRightPopupWindow()
    self.WBP_Firm_Content:ResetAnchorData()
end

---按L鍵是否銷毀此UI
---@param bIsDestory boolean
function WBP_Firm_Map:OnReturn(bIsDestory)

    if self.bIsAnchorPopup == true or self.bIsDetailPopup == true or self.IsRightPopupVisible == true then
        self:HideRightPopupWindow()
    end
    local DefaultChoose = not bIsDestory
    UIManager:CloseUI(self,DefaultChoose)
    if self.WBP_Firm_SidePopupWindow.bKeepMarkerVisible ~= true and self.WBP_Firm_SidePopupWindow.FirmMarkerPointsItem ~= nil then
        self.WBP_Firm_SidePopupWindow.bKeepMarkerVisible = false
        self.WBP_Firm_SidePopupWindow.FirmMarkerPointsItem:RemoveFromParent()
        self.FirmMarkerPointsItem = nil
        if self.WBP_Firm_SidePopupWindow.PreviousAnchor ~= nil then
            self.WBP_Firm_SidePopupWindow.PreviousAnchor.DX_Target_Selected:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.WBP_Firm_SidePopupWindow.PreviousAnchor = nil
        end

        for i, Anchor in ipairs(self.WBP_Firm_Content.Labels) do
            if Anchor.PicKey == self.WBP_Firm_SidePopupWindow.CurrentSelectedAnchorItemPicKey and Anchor.bIsAdd == false and self.WBP_Firm_SidePopupWindow:ComparisonCoordinate(self.WBP_Firm_SidePopupWindow.Position, Anchor.Location2D) then
                self.WBP_Firm_SidePopupWindow:DeleteGridIconData(i)
                table.remove(self.WBP_Firm_Content.Labels, i)
            end
        end
    end
end

--

return WBP_Firm_Map
