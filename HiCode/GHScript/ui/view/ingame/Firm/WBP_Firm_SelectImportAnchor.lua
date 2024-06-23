--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local PathUtil = require("CP0032305_GH.Script.common.utils.path_util")
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ConstText = require("CP0032305_GH.Script.common.text_const")
local FirmMapTable = require("common.data.firm_map_data").data
local FirmMapLegendTypeTableConst = require("common.data.firm_map_legend_type_data")
local TipsUtil = require("CP0032305_GH.Script.common.utils.tips_util")
local json = require("thirdparty.json")
local FirmUtil = require("CP0032305_GH.Script.ui.view.ingame.Firm.FirmUtil")
local G = require('G')

---@class AnchorData
---@field PicKey string
---@field bIsChecked boolean
---@field TotalAnchorNum integer

---@class InComingMapData
---@field TempId integer
---@field AnchorItem WBP_FirmMapLabel
---@field SelectIconIndex string
---@field PositionX number
---@field PositionY number
---@field AnchorName string
---@field bIsChecked boolean

---@class InComingMapMarkerData
---@field PicKey string
---@field bIsChecked boolean
---@field TotalNum integer
---@field CheckedNum integer
---@field SelectIconIndex string
---@field PositionX number
---@field PositionY number
---@field AnchorName string

---@class WBP_Firm_SelectImportAnchor : WBP_Firm_SelectImportAnchor_C
---@field MarkerPointsItems table<number,InComingMapData>
---@field MultipleSelectionIndex table<string,InComingMapMarkerData>
---@field AnchorDataMap  table<string,AnchorData>
---@field SelectAnchorItemClass BP_FirmAnchorsItemObject_C
---@field FirmMapWidget WBP_Firm_SidePopupWindow
---@field bIsInput boolean
---@field bIsRange boolean 导入的锚点是否在范围内
---@field bIsOnClickMergBtn boolean 是否點擊確認合并按鈕

---@type WBP_Firm_SelectImportAnchor_C
local WBP_Firm_SelectImportAnchor = Class(UIWindowBase)

---提示文本
local Tips = "NEEDSELECTANCHOR"

---tips弹窗
local ImportTips = "FIRMIMPORTTIPS"

local LABEL_IN_DELAY = 0.23
local LABEL_OUT_DELAY = 0.33

local LastClickTime = 0
local DoubleClickThreshold  = 0.5
local bIsButtonClicked = false
-- function M:Initialize(Initializer)
-- end

-- function M:PreConstruct(IsDesignTime)
-- end

---@param Id string
---@return FirmMapData
local function GetFirmMapData(Id)
    return FirmMapTable[Id]
end

---@param self WBP_Firm_SelectImportAnchor
local function OnClickCloseMedPopup(self)
    UIManager:CloseUI(self, true)
    for i, v in pairs(self.MultipleSelectionIndex) do
        v.bIsChecked = false
    end
end

function WBP_Firm_SelectImportAnchor:OnClickedMedDefine()
    G.log:debug("xuexiaoyu", "OnClickButton is OnClickEvent")
    if self.bIsInput == false then
        G.log:debug("xuexiaoyu", "WBP_Firm_SelectImportAnchor:OnClickedMedDefine222")
        self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
        self.Switch_MapTips:SetActiveWidgetIndex(0)
        self:RefreshSelectAnchorData()
        self.bIsInput = true
    else
        G.log:debug("xuexiaoyu", "WBP_Firm_SelectImportAnchor:CheckTheIconIsSelected")
        if self:CheckTheIconIsSelected() then
            G.log:debug("xuexiaoyu", "WBP_Firm_SelectImportAnchor:CheckAnchorInUse")
            if self:CheckAnchorInUse() then
                self.bIsOnClickMergBtn = false
                UIManager:CloseUI(self, true)
                ---@type WBP_FirmSecondaryConfirmation_Popup
                local FirmSecondaryConfirmationPopup = UIManager:OpenUI(UIDef.UIInfo.UI_FirmSecondaryConfirmation_Popup)
                FirmSecondaryConfirmationPopup:InitData(self.FirmMapWidget, self.MarkerPointsItems, self.MultipleSelectionIndex, nil, nil, self)
            else
                G.log:debug("xuexiaoyu", "WBP_Firm_SelectImportAnchor:ImportAnchorData %s",tostring(bIsButtonClicked))
                if not bIsButtonClicked then
                    self:ImportAnchorData()
                    bIsButtonClicked = true
                end
                local CurrentTime = os.time()
                if CurrentTime - LastClickTime < DoubleClickThreshold and bIsButtonClicked ~= true then
                    self:ImportAnchorData()
                end
                LastClickTime = CurrentTime
            end
        else
            ---@type WBP_Tips_Tips2_C
            TipsUtil.ShowCommonTips(Tips, 1)
        end
    end
end

---@param self WBP_Firm_SelectImportAnchor
---@return BP_FirmAnchorsItemObject_C
local function NewSelectAnchorItemObject(self)
    local Path = PathUtil.getFullPathString(self.SelectAnchorItemClass)
    local SelectAnchorItemObject = LoadObject(Path)
    return NewObject(SelectAnchorItemObject)
end

---@param self WBP_Firm_SelectImportAnchor
---@return integer
local function DefaultChoseAnchor(self)
    local Index = nil
    if self.MultipleSelectionIndex then
        for i, v in ipairs(self.MultipleData) do
            if v.TotalNum == 0 then
                Index = v.PicKey
                break
            end
            if not Index then
                Index = v.PicKey  -- 如果没有找到TotalNum等于0的元素，则将第一个元素的索引赋值给Index
            end
        end
    end

    return Index
end

---@param self WBP_Firm_SelectImportAnchor
local function RefreshImportAfterInterface(self)
    G.log:debug("xuexiaoyu", "WBP_Firm_SelectImportAnchor:RefreshImportAfterInterface is finish")
    for i, v in pairs(self.MultipleSelectionIndex) do
        v.bIsChecked = false
    end
    self.FirmMapWidget.bKeepMarkerVisible = true
    TipsUtil.ShowCommonTips(ImportTips, 1)
    local LastAnchorPosition = UE.FVector2D(self.AnchorData[#self.AnchorData].PositionX, self.AnchorData[#self.AnchorData].PositionY)
    if LastAnchorPosition then
        self.FirmMapWidget.Firm:MoveToLocation2D(LastAnchorPosition)
    end
    self:KeepTheDefaultSize()
    self:RefreshImportAnchorNum()
    self.FirmMapWidget.Firm.bIsImportComplete = false
    bIsButtonClicked = false
    self.bIsOnClickMergBtn = false
    G.log:debug("xuexiaoyu", "WBP_Firm_SelectImportAnchor:bIsButtonClicked is false")
end


function WBP_Firm_SelectImportAnchor:RefreshImportAnchorNum ()
    if self.FirmMapWidget and self.FirmMapWidget.Firm and self.FirmMapWidget.Firm.MarkerPointsItems then
        local AnchorCount = 0
        for key, value in pairs(self.FirmMapWidget.Firm.MarkerPointsItems) do
            local PicKey = value.SelectIconIndex
            if self.FirmMapWidget.CurrentSelectedAnchorItemPicKey == PicKey then
                if self.FirmMapWidget.Firm.MultipleSelectionIndex and self.FirmMapWidget.Firm.MultipleSelectionIndex[PicKey] then
                    AnchorCount = AnchorCount + 1
                    self.FirmMapWidget.Firm.MultipleSelectionIndex[PicKey].TotalNum = AnchorCount
                end
            end
        end
    end
end

function WBP_Firm_SelectImportAnchor:GetImportData ()
    local Path = UE.UBlueprintPathsLibrary.ProjectSavedDir() .. "/Map" .. "/Labels.json"
    local ImportData = FirmUtil.ReadFile(Path)
    if ImportData ~= "" then
        local Data = json.decode(ImportData)
        return Data
    end
end

function WBP_Firm_SelectImportAnchor:InsertNewData(Position, SelectedIconIndex, Name)
    if self.FirmMapWidget and self.FirmMapWidget.Firm and Position then
        self.FirmMapWidget.Firm.bIsOnClickedBlank = true
        local Location = self.FirmMapWidget.Firm:Map2D2Location(Position)
        G.log:debug("xuexiaoyu", "WBP_Firm_SelectImportAnchor:InsertNewData %s %s",SelectedIconIndex,tostring(self.FirmMapWidget.Firm.bIsOnClickedBlank))
        self.FirmMapWidget.Firm:AddLabel(Location, self.AnchorId, FirmMapLegendTypeTableConst.Anchor, false, SelectedIconIndex, Name)
        self.FirmMapWidget.Firm:TrimLabel(self.FirmMapWidget.Firm.CustomUI)
        local TypeId = FirmUtil.GetMapLegendIdByType(self.FirmMapWidget.Firm.CustomUI.Type)
        if self.FirmMapWidget.Firm.Parent:CheckLegendInRange(TypeId) then
            self.FirmMapWidget.Firm.CustomUI:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.bIsRange = true
        else
            self.bIsRange = false
            self.FirmMapWidget.Firm.CustomUI:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
        local MiniMap = self.FirmMapWidget.Firm.MiniMap
        if MiniMap then
            local LabelData = {}
            LabelData.Location = Location
            LabelData.ShowId = self.AnchorId
            LabelData.IsGuide= false
            LabelData.Type = FirmMapLegendTypeTableConst.Anchor
            LabelData.PicKey = SelectedIconIndex
            --MiniMap.WBP_HUD_MiniMap_Content:AddLabel(Location, self.AnchorId, false, FirmMapLegendTypeTableConst.Anchor, SelectedIconIndex)
            MiniMap.WBP_HUD_MiniMap_Content:AddLabel(LabelData)
            MiniMap.WBP_HUD_MiniMap_Content:TrimLabel()
        end
        local SamePosAnchorItem = {}
        SamePosAnchorItem.TempId = self.FirmMapWidget.Firm.CustomUI.TempId
        SamePosAnchorItem.AnchorItem = self.FirmMapWidget.Firm.CustomUI
        SamePosAnchorItem.PositionX = Position.X
        SamePosAnchorItem.PositionY = Position.Y
        SamePosAnchorItem.SelectIconIndex = SelectedIconIndex
        SamePosAnchorItem.AnchorName = Name
        SamePosAnchorItem.bIsChecked = false
        SamePosAnchorItem.bIsTrace = false
        self.MarkerPointsItems[SamePosAnchorItem.TempId] = SamePosAnchorItem
        for i, v in ipairs(self.FirmMapWidget.Firm.Labels) do
            if self.FirmMapWidget.Firm.CustomUI.TempId == v.TempId then
                v.AnchorName = Name
                v.bIsAdd = true
            end
        end
    end
end

function WBP_Firm_SelectImportAnchor:KeepTheDefaultSize()
    local Delta = nil
    if self.FirmMapWidget and self.FirmMapWidget.Firm then
        local Data = GetFirmMapData(self.FirmMapWidget.Firm.MapId)
        if Data then
            self.MinScale = Data.scale_max[1]
            self.MaxScale = Data.scale_max[2]
            self.DefaultSize = Data.default_scale
            self.ZoomClicked = Data.scale_number
            self.CurValue = self.FirmMapWidget.Firm.Parent.Slider_round:GetValue()
            self.DefaultSliderValue = (self.DefaultSize - self.MinScale) / (self.MaxScale - self.MinScale)
            self.FirmMapWidget.Firm.Parent.Slider_round:SetValue(self.DefaultSliderValue)
            local ScaleAfter = UE.FVector2D(1, 1) * self.FirmMapWidget.Firm.BaseScale
            self.FirmMapWidget.Firm:BeginScale(1, nil, self.DefaultSliderValue)
        end
    end
end

function WBP_Firm_SelectImportAnchor:InsertNewAnchorData(RefreshImportAfterInterface)
    self.AnimQueueIn = 0
    G.log:debug("xuexiaoyu", "WBP_Firm_SelectImportAnchor:AnchorData1111 %d",#self.AnchorData)
    if self.AnchorData and #self.AnchorData > 0 then
        G.log:debug("xuexiaoyu", "WBP_Firm_SelectImportAnchor:AnchorData2222 %d",#self.AnchorData)
        for i, data in ipairs(self.AnchorData) do
            local Position = UE.FVector2D(data.PositionX, data.PositionY)
            G.log:debug("xuexiaoyu", "WBP_Firm_SelectImportAnchor:InsertNewAnchorData %s %s",self.FirmMapWidget.CurrentSelectedAnchorItemPicKey,tostring(self.bIsRange))
            self:InsertNewData(Position, self.FirmMapWidget.CurrentSelectedAnchorItemPicKey, data.AnchorName)
            if self.bIsRange then
                self.AnimQueueIn = self.AnimQueueIn + 1
                if self.AnimQueueIn == #self.AnchorData then
                    G.log:debug("xuexiaoyu", "WBP_Firm_SelectImportAnchor:InsertNewAnchorData RefreshImportAfterInterface1111 %d",self.AnimQueueIn)
                    RefreshImportAfterInterface(self)
                end
                -- local CallBack = function()
                --     G.log:debug("xuexiaoyu", "WBP_Firm_SelectImportAnchor:InsertNewAnchorData RefreshImportAfterInterface2222 %d",self.AnimQueueIn)
                --     self.AnimQueueIn = self.AnimQueueIn - 1
                --     G.log:debug("xuexiaoyu", "WBP_Firm_SelectImportAnchor:InsertNewAnchorData RefreshImportAfterInterface333 %d",self.AnimQueueIn)
                --     if self.AnimQueueIn == 0 then
                --     end
                -- end
                --local TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, CallBack}, LABEL_IN_DELAY, false)
                G.log:debug("xuexiaoyu", "WBP_Firm_SelectImportAnchor:InsertNewAnchorData PlayAnimation")
                self.FirmMapWidget.Firm.CustomUI:StopAnimation(self.FirmMapWidget.Firm.CustomUI.DX_TeleportOut)
                self.FirmMapWidget.Firm.CustomUI:PlayAnimation(self.FirmMapWidget.Firm.CustomUI.DX_TeleportIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
            end
        end
        if not self.bIsRange then
            if RefreshImportAfterInterface then
                G.log:debug("xuexiaoyu", "WBP_Firm_SelectImportAnchor:self.bIsRange is false")
                RefreshImportAfterInterface(self)
            end
        end
    end
end

function WBP_Firm_SelectImportAnchor:DisplayAnchorPoints()
    G.log:debug("xuexiaoyu", "WBP_Firm_SelectImportAnchor:DisplayAnchorPoints11111")
    self.AnimQueueOut = 0
    if self.AnchorData and #self.AnchorData > 0 then
        local bIsDelete = false
        for i, data in ipairs(self.AnchorData) do
            local Position = UE.FVector2D(data.PositionX, data.PositionY)
            for j, MapData in pairs(self.MarkerPointsItems) do
                local AnchorPos = UE.FVector2D(MapData.PositionX, MapData.PositionY)
                if self.FirmMapWidget:ComparisonCoordinate(Position, AnchorPos) then
                    bIsDelete = true
                    local CallBack = function()
                        ---@type WBP_FirmMapLabel
                        if MapData.AnchorItem ~= nil then
                            MapData.AnchorItem:RemoveFromParent()
                            if MapData.AnchorItem.FloatUI ~= nil then
                                MapData.AnchorItem.FloatUI:RemoveFromParent()
                                self.FirmMapWidget:RemoveMapFloatUI(MapData.AnchorItem.FloatUI.TempId)
                                MapData.AnchorItem.FloatUI = nil
                            end
                            self.FirmMapWidget:RemoveMiniMapGuideUI(MapData)
                            MapData.AnchorItem = nil
                        end
                        if self.MultipleSelectionIndex[MapData.SelectIconIndex].TotalNum > 0 then
                            self.MultipleSelectionIndex[MapData.SelectIconIndex].TotalNum = self.MultipleSelectionIndex[MapData.SelectIconIndex].TotalNum - 1
                        else
                            self.MultipleSelectionIndex[MapData.SelectIconIndex].TotalNum = 0
                        end
                        self.FirmMapWidget.Firm.MarkerPointsItems[j] = nil
                        for k, v in ipairs(self.FirmMapWidget.Firm.Labels) do
                            if v.Type ~= FirmMapLegendTypeTableConst.PlayerPosition then
                                if self.FirmMapWidget:ComparisonCoordinate(v.Location2D, Position) then
                                    self.FirmMapWidget:DeleteGridIconData(k)
                                    if self.PreviousAnchor ~= nil and self.FirmMapWidget:ComparisonCoordinate(v.Location2D,self.PreviousAnchor.Location2D) then
                                        self.PreviousAnchor = nil
                                    end
                                    table.remove(self.FirmMapWidget.Firm.Labels, k)
                                end
                            end
                        end
                        self.AnimQueueOut = self.AnimQueueOut - 1
                        G.log:debug("xuexiaoyu", "WBP_Firm_SelectImportAnchor:DisplayAnchorPoints InsertNewAnchorData %d",self.AnimQueueOut)
                        if self.AnimQueueOut == 0 then
                            G.log:debug("xuexiaoyu", "WBP_Firm_SelectImportAnchor:DisplayAnchorPoints InsertNewAnchorData11111 %d",self.AnimQueueOut)
                            self:InsertNewAnchorData(RefreshImportAfterInterface)
                        end
                    end
                    self.AnimQueueOut = self.AnimQueueOut + 1
                    UE.UKismetSystemLibrary.K2_SetTimerDelegate({self,CallBack}, LABEL_OUT_DELAY, false)
                    MapData.AnchorItem:StopAnimation(self.FirmMapWidget.Firm.CustomUI.DX_TeleportIn)
                    MapData.AnchorItem:PlayAnimation(MapData.AnchorItem.DX_TeleportOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
                end
            end
        end
        if bIsDelete == false then
            self:InsertNewAnchorData(RefreshImportAfterInterface)
        end
    end
end

function WBP_Firm_SelectImportAnchor:ImportAnchorData()
    self:BindToAnimationFinished(self.DX_Out, { self, function()
        self.FirmMapWidget.Firm.bIsImportComplete = true
        ---操作锚点删除和插入的逻辑
        self:DisplayAnchorPoints()
    end })
    G.log:debug("xuexiaoyu", "WBP_Firm_SelectImportAnchor:CloseUI")
    UIManager:CloseUI(self, true)
end

function WBP_Firm_SelectImportAnchor:CheckTheIconIsSelected()
    for i, v in pairs(self.MultipleSelectionIndex) do
        if v.bIsChecked then
            return true
        end
    end
    return false
end

---检查图标是否在使用中
function WBP_Firm_SelectImportAnchor:CheckAnchorInUse()
    local ChoseAnchorPosData = {}
    if self.FirmMapWidget then
        if self.MarkerPointsItems then
            for i, v in pairs(self.MarkerPointsItems) do
                if self.FirmMapWidget.CurrentSelectedAnchorItemPicKey == v.SelectIconIndex then
                    local AnchorPos = UE.FVector2D(v.PositionX, v.PositionY)
                    table.insert(ChoseAnchorPosData, { Position = AnchorPos, AnchorPicKey = v.SelectIconIndex })
                end
            end
        end
        for j, v in pairs(ChoseAnchorPosData) do
            if self.FirmMapWidget.CurrentSelectedAnchorItemPicKey == v.AnchorPicKey then
                return true
            else
                return false
            end
        end
    end
end

function WBP_Firm_SelectImportAnchor:RefreshSelectAnchorData()
    local Path = PathUtil.getFullPathString(self.SelectAnchorItemClass)
    local SelectAnchorItemObject = LoadObject(Path)
    local InAnchorsList = UE.TArray(SelectAnchorItemObject)
    self.MultipleData = self.FirmMapWidget:ChangeDataToArray()
    for i, v in ipairs(self.MultipleData) do
        local FirmAnchorItem = NewSelectAnchorItemObject(self)
        FirmAnchorItem.PicKey = v.PicKey
        FirmAnchorItem.AnchorOwnerWidget = self.FirmMapWidget
        FirmAnchorItem.bIsDisplayText = false
        FirmAnchorItem.TotalAnchorNum = v.TotalNum
        FirmAnchorItem.bIsSelected = v.bIsChecked
        FirmAnchorItem.CheckedNum = 0
        FirmAnchorItem.bIsImportAnchor = true
        InAnchorsList:Add(FirmAnchorItem)
    end
    local Index = DefaultChoseAnchor(self)
    local InAnchorsListTable = InAnchorsList:ToTable()
    for i, v in pairs(InAnchorsListTable) do
        if InAnchorsListTable[i].PicKey == Index then
            InAnchorsListTable[i].bIsSelected = true
            self.FirmMapWidget.CurrentSelectedAnchorItemPicKey = Index
        end
    end
    self.MultipleSelectionIndex[Index].bIsChecked = true
    self.Tile_ImportIcon:BP_SetListItems(InAnchorsList)
end
---@param FirmMapWidget WBP_Firm_SidePopupWindow
---@param MapData InComingMapData
---@param MarkerData InComingMapMarkerData
---@param PreviousAnchor WBP_FirmMapLabel
function WBP_Firm_SelectImportAnchor:GetsFimMapIncomingData(FirmMapWidget, MapData, MarkerData,PreviousAnchor)
    self.FirmMapWidget = FirmMapWidget
    self.MarkerPointsItems = MapData
    self.MultipleSelectionIndex = MarkerData
    self.PreviousAnchor = PreviousAnchor
    self.Switch_MapTips:SetActiveWidgetIndex(1)
    self.WBP_Common_InputBox.Switch_Colour:SetActiveWidgetIndex(0)
    self.AnchorId = FirmUtil.GetMapLegendIdByType(FirmMapLegendTypeTableConst.Anchor)
end

function WBP_Firm_SelectImportAnchor:OnShow()
    self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    self.AnchorData = self:GetImportData()
    if self.AnchorData and #self.AnchorData > 0 then
        for i, v in ipairs(self.AnchorData) do
            self.ExportAnchorNum = self.ExportAnchorNum + 1
        end
        self.Text_SignNum:SetText(self.ExportAnchorNum)
    end
end

function WBP_Firm_SelectImportAnchor:OnConstruct()
    self.AnchorDataMap = {}
    self.bIsInput = false
    self.ExportAnchorNum = 0
    self.Text_Title:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.WBP_Common_Popup_Medium.WBP_MedPopupClose.OnClicked:Add(self, OnClickCloseMedPopup)
    self.WBP_ComBtn_MedDefine.OnReleased:Add(self, self.OnClickedMedDefine)
    --self.WBP_CommonButton.OnClicked:Add(self, OnClickedMedDefine)
end

function WBP_Firm_SelectImportAnchor:OnDestruct()
    self.WBP_Common_Popup_Medium.WBP_MedPopupClose.OnClicked:Remove(self, OnClickCloseMedPopup)
end

-- function M:Tick(MyGeometry, InDeltaTime)
-- end

return WBP_Firm_SelectImportAnchor
