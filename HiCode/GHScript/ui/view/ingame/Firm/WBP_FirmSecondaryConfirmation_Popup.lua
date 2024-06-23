--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ConstText = require("CP0032305_GH.Script.common.text_const")
local json = require("thirdparty.json")
local FirmUtil = require("CP0032305_GH.Script.ui.view.ingame.Firm.FirmUtil")
local FirmMapLegendTypeTableConst = require("common.data.firm_map_legend_type_data")
local FirmMapTable = require("common.data.firm_map_data").data
local TipsUtil = require("CP0032305_GH.Script.common.utils.tips_util")
local G = require('G')

---@class ImportMapData
---@field TempId integer
---@field AnchorItem WBP_FirmMapLabel
---@field SelectIconIndex string
---@field PositionX number
---@field PositionY number
---@field AnchorName string
---@field bIsChecked boolean

---@class ImportMarkerData
---@field PicKey string
---@field bIsChecked boolean
---@field TotalNum integer
---@field CheckedNum integer
---@field SelectIconIndex string
---@field PositionX number
---@field PositionY number
---@field AnchorName string

---@class WBP_FirmSecondaryConfirmation_Popup : WBP_FirmSecondaryConfirmation_Popup_C
---@field MarkerPointsItems table<number,ImportMapData>
---@field MultipleSelectionIndex table<string,ImportMarkerData>
---@field FirmMapWidget WBP_Firm_SidePopupWindow
---@field TimerHandle FTimerHandle
---@field bIsDelete boolean 是否是删除
---@field AnimQueue int 动画队列

---@type WBP_FirmSecondaryConfirmation_Popup_C
local WBP_FirmSecondaryConfirmation_Popup = Class(UIWindowBase)

-- function M:Initialize(Initializer)
-- end

-- function M:PreConstruct(IsDesignTime)
-- end
---弹窗标题
local TitleName = "EXPORTEDSUCCESS"
local SecondaryConfirm = "SECONDARYCONFIRM"
---tips弹窗
local ImportTips = "FIRMIMPORTTIPS"
---确认删除信息
local ConfirmDelete = "CONFIRMDELETE"

local LABEL_OUT_DELAY = 0.33

---@param Id string
---@return FirmMapData
local function GetFirmMapData(Id)
    return FirmMapTable[Id]
end

---@param self WBP_Firm_SidePopupWindow
local function CopyMapCode(self)
    self.WBP_Tips_MapCode_Export:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, function()
        self.WBP_Tips_MapCode_Export:SetVisibility(UE.ESlateVisibility.Collapsed)
    end }, 1, false)
end

---@param self WBP_FirmSecondaryConfirmation_Popup
local function OnClickedCancel(self)
    UIManager:CloseUI(self, true)
end

---@param self WBP_FirmSecondaryConfirmation_Popup
local function OnClickedConfirm(self)
    self:BindToAnimationFinished(self.DX_Out, { self, function()
        self.AnimQueue = 0
        local SwitcherIndex = self.Switch_Tips:GetActiveWidgetIndex()
        if SwitcherIndex == 0 and self.bIsDelete == false then
            
            if self.SelectAnchorWidget then
                if not self.SelectAnchorWidget.bIsOnClickMergBtn then
                    G.log:debug("xuexiaoyu", "WBP_Firm_SelectImportAnchor:ImportAnchorData %s",tostring(self.SelectAnchorWidget.bIsOnClickMergBtn))
                    self.SelectAnchorWidget.bIsOnClickMergBtn = true
                    self.SelectAnchorWidget:DisplayAnchorPoints()
                end
            end
        else
            self:MultiDeleteAnchor()
        end
    end })
   
    UIManager:CloseUI(self, true)
end

---@param RemoveIndices table 需要删除的索引
function WBP_FirmSecondaryConfirmation_Popup:RefreshDeleteInterface(RemoveIndices)
    local TempCount = 0
    for i, v in ipairs(RemoveIndices) do
        self.FirmMapWidget:DeleteGridIconData(RemoveIndices[i] - TempCount)
        table.remove(self.FirmMapWidget.Firm.Labels, RemoveIndices[i] - TempCount)
        --if self.FirmMapWidget.MiniLabels:GetRef(RemoveIndices[i] - TempCount - 1) then
        --self.FirmMapWidget.MiniLabels:Remove(RemoveIndices[i] - TempCount - 1)
        --table.remove(self.FirmMapWidget.MiniLabels, RemoveIndices[i] - TempCount - 1)
        --end
        TempCount = TempCount + 1
    end
    for i, data in pairs(self.FirmMapWidget.Firm.MultipleSelectionIndex) do
        if data.bIsChecked == true and data.TotalNum > 0 then
            self.FirmMapWidget.Canvas_Anchor_Export:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.FirmMapWidget.Canvas_EmptyState:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.FirmMapWidget.WBP_ComBtn_Delete_1:SetIsEnabled(true)
            self.FirmMapWidget.WBP_ComBtn_ExportSelected:SetIsEnabled(true)
            break
        else
            self.FirmMapWidget.Canvas_Anchor_Export:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.FirmMapWidget.Canvas_EmptyState:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.FirmMapWidget.WBP_ComBtn_Delete_1:SetIsEnabled(false)
            self.FirmMapWidget.WBP_ComBtn_ExportSelected:SetIsEnabled(false)
        end
    end
    self.FirmMapWidget:RefreshCheckedData()
    self.FirmMapWidget:SetBatchSelectionDatas()
    self.FirmMapWidget:SetAnchorListInfo()
    self.FirmMapWidget:RefreshMultiDeleteBtn()
end

function WBP_FirmSecondaryConfirmation_Popup:MultiDeleteAnchor()
    self.AnimQueue = 0
    if self.FirmMapWidget and self.FirmMapWidget.Firm and self.FirmMapWidget.Firm.Labels then
        local RemoveIndices = {} -- 临时表存储需要删除的索引
        for i, v in ipairs(self.FirmMapWidget.Firm.Labels) do
            if self.PreviousAnchor ~= nil then
                if self.FirmMapWidget:ComparisonCoordinate(v.Location2D, self.PreviousAnchor.Location2D) then
                    self.PreviousAnchor = nil
                end
            end
            local isChecked = false -- 标记是否找到匹配项
            for key, value in pairs(self.FirmMapWidget.Firm.MarkerPointsItems) do
                local Location = UE.FVector2D(value.PositionX, value.PositionY)
                if v.Type ~= FirmMapLegendTypeTableConst.PlayerPosition and v.TempId == key then
                    if value.bIsChecked and self.FirmMapWidget:ComparisonCoordinate(v.Location2D, Location) then
                        table.insert(RemoveIndices, i)
                        local CallBack = function()
                            if value.AnchorItem then
                                value.AnchorItem:RemoveFromParent()
                                if value.AnchorItem.FloatUI ~= nil then
                                    value.AnchorItem.FloatUI:RemoveFromParent()
                                    self.FirmMapWidget:RemoveMapFloatUI(value.AnchorItem.FloatUI.TempId)
                                    value.AnchorItem.FloatUI = nil
                                end
                                local MiniMap = self.FirmMapWidget.Firm.MiniMap
                                self.FirmMapWidget:RemoveMiniMapGuideUI(value)
                                value.AnchorItem = nil
                                isChecked = true
                                self.FirmMapWidget.Firm.MarkerPointsItems[key] = nil
                                if self.FirmMapWidget.Firm.MultipleSelectionIndex[value.SelectIconIndex].TotalNum > 0 then
                                    self.FirmMapWidget.Firm.MultipleSelectionIndex[value.SelectIconIndex].TotalNum = self.FirmMapWidget.Firm.MultipleSelectionIndex[value.SelectIconIndex].TotalNum - 1
                                else
                                    self.FirmMapWidget.Firm.MultipleSelectionIndex[value.SelectIconIndex].TotalNum = 0
                                end
                                if self.FirmMapWidget.Firm.MultipleSelectionIndex[value.SelectIconIndex].CheckedNum > 0 then
                                    self.FirmMapWidget.Firm.MultipleSelectionIndex[value.SelectIconIndex].CheckedNum = self.FirmMapWidget.Firm.MultipleSelectionIndex[value.SelectIconIndex].CheckedNum - 1
                                else
                                    self.FirmMapWidget.Firm.MultipleSelectionIndex[value.SelectIconIndex].CheckedNum = 0
                                end
                                
                                if isChecked then
                                    self.FirmMapWidget.WBP_ComBtn_Delete_1:SetIsEnabled(true)
                                    self.FirmMapWidget.WBP_ComBtn_ExportSelected:SetIsEnabled(true)
                                else
                                    self.FirmMapWidget.WBP_ComBtn_Delete_1:SetIsEnabled(false)
                                    self.FirmMapWidget.WBP_ComBtn_ExportSelected:SetIsEnabled(false)
                                end
                                self.AnimQueue = self.AnimQueue - 1
                                if self.AnimQueue == 0 then
                                    self:RefreshDeleteInterface(RemoveIndices)
                                    
                                end
                            end
                            
                        end
                        UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, CallBack}, LABEL_OUT_DELAY, false)

                        --value.AnchorItem:BindToAnimationFinished(value.AnchorItem.DX_TeleportOut, { self, function()
                        --
                        --end })
                        self.AnimQueue = self.AnimQueue + 1
                        value.AnchorItem:PlayAnimation(value.AnchorItem.DX_TeleportOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
                    end
                end

            end
        end
        -- 批量删除需要删除的索引
    end
end

---@param FirmMapWidget WBP_Firm_SidePopupWindow
---@param MapData FirmMapData
---@param MarkerData FirmMarkerData
---@param bIsExport boolean
---@param PreviousAnchor WBP_FirmMapLabel
---@param SelectAnchorWidget WBP_Firm_SelectImportAnchor
function WBP_FirmSecondaryConfirmation_Popup:InitData(FirmMapWidget, MapData, MarkerData, bIsExport, PreviousAnchor, SelectAnchorWidget)
    self.FirmMapWidget = FirmMapWidget
    self.MarkerPointsItems = MapData
    self.MultipleSelectionIndex = MarkerData
    self.AnchorId = FirmUtil.GetMapLegendIdByType(FirmMapLegendTypeTableConst.Anchor)
    self.PreviousAnchor = PreviousAnchor
    self.SelectAnchorWidget = SelectAnchorWidget
    if bIsExport ~= nil then
        if bIsExport then
            self:ShowExportInterface()
        else
            self:ShowDeleteInterface()
        end
    end
end

function WBP_FirmSecondaryConfirmation_Popup:ShowExportInterface()
    self.WBP_Common_Popup_Small:ShowCloseButton(true)
    self.WBP_Common_Popup_Small:SetOwnerWidget(self)
    self.WBP_Common_Popup_Small:SetTitle(TitleName)
    self.WBP_Common_Popup_Small.WBP_ComBtn_Cancel:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.WBP_Common_Popup_Small.WBP_ComBtn_Commit:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.WBP_Tips_MapCode_Export:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Switch_Tips:SetActiveWidgetIndex(1)
end

function WBP_FirmSecondaryConfirmation_Popup:ShowDeleteInterface()
    local CheckNum = 0
    self.WBP_Common_Popup_Small:ShowCloseButton(false)
    self.WBP_Common_Popup_Small:SetTitle(SecondaryConfirm)
    self.WBP_Common_Popup_Small.WBP_ComBtn_Cancel:SetVisibility(UE.ESlateVisibility.Visible)
    self.WBP_Common_Popup_Small.WBP_ComBtn_Commit:SetVisibility(UE.ESlateVisibility.Visible)
    self.WBP_Tips_MapCode_Export:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Switch_Tips:SetActiveWidgetIndex(0)
    self.bIsDelete = true
    for j, k in pairs(self.FirmMapWidget.Firm.MarkerPointsItems) do
        if k.bIsChecked then
            CheckNum = CheckNum + 1
        end
    end
    local HintText = ConstText.GetConstText(ConfirmDelete)

    self.Text_Introduce:SetText(string.format(HintText, CheckNum))
end

function WBP_FirmSecondaryConfirmation_Popup:OnShow()
    self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    self.WBP_Common_Popup_Small:PlayInAnim()
end

function WBP_FirmSecondaryConfirmation_Popup:OnConstruct()
    self.WBP_Tips_MapCode_Export:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Switch_Tips:SetActiveWidgetIndex(0)
    self.bIsDelete = false
    self.WBP_Common_Popup_Small:BindCommitCallBack(self, OnClickedConfirm)
    self.WBP_Common_Popup_Small:BindCancelCallBack(self, OnClickedCancel)
    self.Btn_MapCode.Button.OnClicked:Add(self, CopyMapCode)
end

function WBP_FirmSecondaryConfirmation_Popup:OnDestruct()
    self.WBP_Common_Popup_Small:UnBindCommitCallBack(self, OnClickedConfirm)
    self.WBP_Common_Popup_Small:UnBindCancelCallBack(self, OnClickedCancel)
    self.Btn_MapCode.Button.OnClicked:Remove(self, CopyMapCode)
end

-- function M:Tick(MyGeometry, InDeltaTime)
-- end

return WBP_FirmSecondaryConfirmation_Popup
