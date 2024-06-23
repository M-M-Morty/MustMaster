--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
---@alias AnchorItemSelectedCallBackT fun(Owner:UObject, AnchorItem:string)

local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local MissionSystem = require("CP0032305_GH.Script.system_simulator.mission_system.mission_system_sample")
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local PathUtil = require("CP0032305_GH.Script.common.utils.path_util")
local PicConst = require("CP0032305_GH.Script.common.pic_const")
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local json = require("thirdparty.json")
local G = require('G')
local FirmMapLegendTypeTableConst = require("common.data.firm_map_legend_type_data")
local FirmMapLegendTable = require("common.data.firm_map_legend_data").data
local ConstText = require("CP0032305_GH.Script.common.text_const")
local FirmUtil = require("CP0032305_GH.Script.ui.view.ingame.Firm.FirmUtil")
local IconUtility = require('CP0032305_GH.Script.common.utils.icon_util')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local StringUtil = require("CP0032305_GH.Script.common.utils.string_utl")

---@class FirmAnchorData
---@field ShowId integer
---@field PicKey string
---@field bIsSelected boolean

---@class MapsIconData
---@field Icon string
---@field ShowIcon string
---@field bIsSelected boolean
---@field bIsRewards boolean
---@field bIsTrace boolean


---@class WBP_Firm_SidePopupWindow : WBP_Firm_SidePopupWindow_C
---@field Index integer
---@field AnchorItemSelectedCallBacks table<UObject, AnchorItemSelectedCallBackT>
---@field CurrentSelectedAnchorItemPicKey string 当前选择的图标
---@field bKeepMarkerVisible boolean 标记是否显示
---@field FirmMarkerPointsItem WBP_FirmMapLabel
---@field Position FVector2D
---@field Location FVector
---@field LandMarkItemsWidgets WBP_Firm_LandMarkItem[]

---@field bIsOnClickedBlank boolean
---@field SelectAnchorPicKey string 点击图标的图片Id
---@field SelectedMarkerPos FVector2D
---@field CheckedTotalNum integer
---@field Key integer
---@field bIsOnClicked boolean
---@field IsClickedCloseButton  boolean
---@field Firm WBP_Firm_Content
---@field bIsOnClickedAnchor boolean
---@field AnchorName string
---@field bIsTrace boolean
---@field FirmMap WBP_Firm_Map
---@field AnchorId integer
---@field IsTraceBtn boolean
---@field ActorId string 传送所需要的ActorId
---@field TraceBtnName string
---@field PreviousAnchor WBP_FirmMapLabel 当前选中的item

---@type WBP_Firm_SidePopupWindow_C
local WBP_Firm_SidePopupWindow = Class()

---批量选择标题
local BATCH_TITLE = "BATCHSELECTION"
---追踪文本
local TRACE = "TRACE"
---取消追踪文本
local CANCEL_TRACE = "UNTRACE"
---传送文本
local TRANSMIT = "TRANSMIT"
---输入框字数上限
local INPUT_LIMIT = 12
---文本框超过输入的错误文本
local ERROR_TEXT = "ERRORTEXT"

---传送至文本
local SEND_TO = "SENDTO"

---锚点文本
local AnchorText = "ANCHOR_NAME"

local MAT_PARAM_NO_HIDE = 0
local MAT_PARAM_HIDE = 1.6
local MAT_PARAM = 23

---@param self WBP_Firm_SidePopupWindow
local function ShowUpShadow(self)
    local EffectMaterial = self.RetainerBox_58:GetEffectMaterial()
    EffectMaterial:SetScalarParameterValue("Power1", MAT_PARAM_NO_HIDE)
    EffectMaterial:SetScalarParameterValue("Power2", MAT_PARAM_HIDE)
    EffectMaterial:SetScalarParameterValue("progress", MAT_PARAM)
end

---@param self WBP_Firm_SidePopupWindow
local function ShowDownShadow(self)
    local EffectMaterial = self.RetainerBox_58:GetEffectMaterial()
    EffectMaterial:SetScalarParameterValue("Power1", MAT_PARAM_HIDE)
    EffectMaterial:SetScalarParameterValue("Power2", MAT_PARAM_NO_HIDE)
    EffectMaterial:SetScalarParameterValue("progress", MAT_PARAM)
end

---@param self WBP_Firm_SidePopupWindow
local function ShowBothShadow(self)
    local EffectMaterial = self.RetainerBox_58:GetEffectMaterial()
    EffectMaterial:SetScalarParameterValue("Power1", MAT_PARAM_HIDE)
    EffectMaterial:SetScalarParameterValue("Power2", MAT_PARAM_HIDE)
    EffectMaterial:SetScalarParameterValue("progress", MAT_PARAM)
end

---@param self WBP_Firm_SidePopupWindow
local function ShowNoShadow(self)
    local EffectMaterial = self.RetainerBox_58:GetEffectMaterial()
    EffectMaterial:SetScalarParameterValue("Power1", MAT_PARAM_NO_HIDE)
    EffectMaterial:SetScalarParameterValue("Power2", MAT_PARAM_NO_HIDE)
    EffectMaterial:SetScalarParameterValue("progress", MAT_PARAM)
end

---@param Index integer
---@param Widget WBP_Firm_LandMarkItem
function WBP_Firm_SidePopupWindow:SetLandMarkItemsWidgets(Index, Widget)
    self.LandMarkItemsWidgets[Index] = Widget

end

---@param self WBP_Firm_SidePopupWindow
---@param OffsetInitems float
local function OnListViewScrolled(self, OffsetInitems)
    local CurrentFirst = math.ceil(OffsetInitems)
    local Total = self.ListView_329:GetNumItems()
    local RemainHeight = 0
    local NotShowLastOne = false
    for i = CurrentFirst, Total do
        local ItemObject = self.ListView_329:GetItemAt(i - 1)
        if self.ListView_329:BP_IsItemVisible(ItemObject) then
            local Widget = self.LandMarkItemsWidgets[i]
            local WidgetGeometry = Widget:GetCachedGeometry()
            local ListLocalSize = UE.USlateBlueprintLibrary.GetLocalSize(WidgetGeometry)
            if i == CurrentFirst then
                RemainHeight = RemainHeight + ListLocalSize.Y * (CurrentFirst - OffsetInitems)
            else
                RemainHeight = RemainHeight + ListLocalSize.Y
            end
        else
            NotShowLastOne = true
            break
        end
    end

    local ListGeometry = self.ListView_329:GetCachedGeometry()
    local ListLocalSize = UE.USlateBlueprintLibrary.GetLocalSize(ListGeometry)
    if NotShowLastOne then
        if OffsetInitems <= 0.1 then
            ShowDownShadow(self)
        else
            ShowBothShadow(self)
        end
    else
        if ListLocalSize.Y > RemainHeight or (RemainHeight - ListLocalSize.Y > 0 and RemainHeight - ListLocalSize.Y < 2) then
            if OffsetInitems <= 0.1 then
                ShowNoShadow(self)
            else
                ShowUpShadow(self)
            end
        else
            if OffsetInitems <= 0.1 then
                ShowDownShadow(self)
            else
                ShowBothShadow(self)
            end
        end
    end
end

---刷新可编辑文本按钮状态
---@param self WBP_Firm_SidePopupWindow
local function RefreshEditableState(self, Text)
    if StringUtil.utf8len(Text) <= INPUT_LIMIT then
        self.WBP_Common_InputBox:HideErrorMsg()
    else
        local ExceedText = StringUtil.utf8sub(Text, 1, INPUT_LIMIT)
        self.WBP_Common_InputBox.EditableText_Content:SetText(ExceedText)
        local HintText = ConstText.GetConstText(ERROR_TEXT)
        self.WBP_Common_InputBox:ShowErrorMsg(string.format(HintText, INPUT_LIMIT))
    end
    if self.Firm ~= nil and self.SelectedMarkerPos ~= nil and self.Firm.MarkerPointsItems ~= nil and self.Firm.Labels ~= nil then
        for i, v in pairs(self.Firm.MarkerPointsItems) do
            local Position = UE.FVector2D(v.PositionX, v.PositionY)
            if self:ComparisonCoordinate(Position, self.SelectedMarkerPos) then
                v.AnchorName = Text
            end
        end
        for j, v in ipairs(self.Firm.Labels) do
            if self:ComparisonCoordinate(v.Location2D, self.SelectedMarkerPos) then
                v.AnchorName = Text
            end
        end
    end
end

---@param self WBP_Firm_SidePopupWindow
local function OnCommittedText(self)
    local Text = self.WBP_Common_InputBox.EditableText_Content:GetText()
    if Text == "" then
        self.WBP_Common_InputBox:SetText(AnchorText)
    end
end

---导入后更新锚点创建时的按钮状态
---@param self WBP_Firm_SidePopupWindow
local function UpdateBtnDisplay(self)
    local AnchorCurNum = 0
    if self.Firm and self.Firm.Labels then
        for i, v in ipairs(self.Firm.Labels) do
            if self.Firm.Labels[i].IsAnchor then
                AnchorCurNum = AnchorCurNum + 1
            end
        end
        if AnchorCurNum >= self.Firm.AnchorUpperLimit then
            self.WBP_ComBtn_Commit:SetIsEnabled(false)
        else
            self.WBP_ComBtn_Commit:SetIsEnabled(true)
        end
    end
end

---@param self WBP_Firm_SidePopupWindow
local function RefreshSideWindow(self)
    self.Canvas_Anchor_Export:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Canvas_EmptyState:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Switcher_BtnStyle:SetActiveWidgetIndex(0)
    UpdateBtnDisplay(self)
end

---@param self WBP_Firm_SidePopupWindow
---@param bIsChecked boolean
local function RefreshBtnState(self, bIsChecked)
    self.bIsOnClicked = bIsChecked
end

---@param self WBP_Firm_SidePopupWindow
---@param bIsClicked boolean
local function ChangeOnClickedState(self, bIsClicked)
    if bIsClicked then
        self.WBP_ComBtn_CheckBox_SelectAll.Switch_Check:SetActiveWidgetIndex(0)
        self.WBP_ComBtn_CheckBox_SelectAll.Switch_CheckBox:SetActiveWidgetIndex(0)
        RefreshBtnState(self, bIsClicked)
    else
        self.WBP_ComBtn_CheckBox_SelectAll.Switch_CheckBox:SetActiveWidgetIndex(1)
        self.WBP_ComBtn_CheckBox_SelectAll.Switch_Check:SetActiveWidgetIndex(1)
        RefreshBtnState(self, bIsClicked)
    end
end

---@param self WBP_Firm_SidePopupWindow
local function ChangeBtnState(self, bIsEnable)
    if bIsEnable then
        self.WBP_ComBtn_Delete_1:SetIsEnabled(true)
        self.WBP_ComBtn_ExportSelected:SetIsEnabled(true)
    else
        self.WBP_ComBtn_Delete_1:SetIsEnabled(false)
        self.WBP_ComBtn_ExportSelected:SetIsEnabled(false)
    end

end
---@param self WBP_Firm_SidePopupWindow
---@param bIsDisplay boolean
local function RefreshEmptyState(self, bIsDisplay)
    if bIsDisplay then
        self.Canvas_Anchor_Export:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Canvas_EmptyState:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.Canvas_Anchor_Export:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Canvas_EmptyState:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
end

---获取选中图标在数组中的索引
---@param self WBP_Firm_SidePopupWindow
---@return integer
local function GetSelectedAnchorIndexFromTable(self)
    local MarkerIndex
    for key, value in pairs(self.Firm.MarkerPointsItems) do
        local Position = UE.FVector2D(value.PositionX, value.PositionY)
        if value.TempId == self.OnClickPicKey then
            MarkerIndex = key
            break
        end
    end
    return MarkerIndex
end

---@param self WBP_Firm_SidePopupWindow
local function GetLabelsIndexFromTable(self)
    local MarkerIndex
    for key, value in ipairs(self.Firm.Labels) do
        if self.OnClickPicKey == value.TempId and value.bIsAdd == true
                and self:ComparisonCoordinate(self.SelectedMarkerPos, value.Location2D) then
            MarkerIndex = key
            break
        end
    end
    return MarkerIndex
end

---@param self WBP_Firm_SidePopupWindow
local function GetAnchorBusinessData(self)
    if self.Firm then
        local AnchorCount = 0
        for key, value in pairs(self.Firm.MarkerPointsItems) do
            local PicKey = value.SelectIconIndex
            -- 更新 MultipleSelectionIndex
            if PicKey == self.CurrentSelectedAnchorItemPicKey then
                if self.Firm.MultipleSelectionIndex[PicKey] then
                    AnchorCount = AnchorCount + 1
                    self.Firm.MultipleSelectionIndex[PicKey].TotalNum = AnchorCount
                end
            end
        end
    end
end

---@param self WBP_Firm_SidePopupWindow
local function OnClickedCommit(self)
    self.bKeepMarkerVisible = true
    self.AnchorName = self.WBP_Common_InputBox:GetText()
    local Position = UE.FVector2D(self.Position.X, self.Position.Y)
    if self.Firm then
        if self.Firm.OnClickedCommit then
            self.Firm:OnClickedCommit(self.FirmMarkerPointsItem, self.CurrentSelectedAnchorItemPicKey, Position, self.AnchorName, self.AnchorId)
            ---对应小地图添加自定义锚点
            if self.Firm and self.Firm.MiniMap then
                local LabelData ={}
                LabelData.Location = self.Location
                LabelData.ShowId = self.AnchorId
                LabelData.IsGuide = false
                LabelData.Type = FirmMapLegendTypeTableConst.Anchor
                LabelData.PicKey = self.CurrentSelectedAnchorItemPicKey
                --self.Firm.MiniMap.WBP_HUD_MiniMap_Content:AddLabel(self.Location, self.AnchorId, false, FirmMapLegendTypeTableConst.Anchor, self.CurrentSelectedAnchorItemPicKey)
                self.Firm.MiniMap.WBP_HUD_MiniMap_Content:AddLabel(LabelData)
                --local MinimapMarkerPointsItem = self.Firm.MiniMap.WBP_HUD_MiniMap_Content.CustomUI
                --self.Firm.MiniMap.WBP_HUD_MiniMap_Content:OnClickedCommit(MinimapMarkerPointsItem)
            end
            self.FirmMarkerPointsItem.DX_Target_Selected:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.Firm.Parent:HideRightPopupWindow()
        end
        if self.Firm.Parent:CheckLegendInRange(self.AnchorTypeId) then
            self.FirmMarkerPointsItem:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            self.FirmMarkerPointsItem:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
    GetAnchorBusinessData(self)
end


---@param self WBP_Firm_SidePopupWindow
local function OnClickedDeleteAnchor(self)

    if self.MarkerPointsItem ~= nil and self.Firm then
        self.MarkerPointsItem:PlayAnimation(self.MarkerPointsItem.DX_TeleportOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
        self.Firm.Parent:HideRightPopupWindow()
        self.MarkerPointsItem:BindToAnimationFinished(self.MarkerPointsItem.DX_TeleportOut, { self, function()
            if self.MarkerPointsItem ~= nil then
                self.MarkerPointsItem:RemoveFromParent()
                if self.MarkerPointsItem.FloatUI ~= nil then
                    self.MarkerPointsItem.FloatUI:RemoveFromParent()
                    self:RemoveMapFloatUI(self.MarkerPointsItem.FloatUI.TempId)
                    self.MarkerPointsItem.FloatUI = nil
                end
                self.MarkerPointsItem = nil
                if self.Firm then
                    if self.MiniItem ~= nil then
                        if self.MiniItem.FloatUI then
                            --self.MiniItem.FloatUI:RemoveFromParent()
                            self.CanvasFloatLabels:RemoveChild(self.MiniItem.FloatUI)
                            --self.MiniLabels:RemoveItem(self.MiniItem.FloatUI)
                        end
                        --self.MiniItem:RemoveFromParent()
                        self.CanvasLabels:RemoveChild(self.MiniItem)
                        self.MiniLabels:RemoveItem(self.MiniItem)
                    end
                    local Index = GetSelectedAnchorIndexFromTable(self)
                    if Index ~= nil then
                        self.Firm.MultipleSelectionIndex[self.SelectAnchorPicKey].TotalNum = self.Firm.MultipleSelectionIndex[self.SelectAnchorPicKey].TotalNum - 1
                        self.Firm.MarkerPointsItems[Index] = nil
                        if self.Firm.MiniMap then
                            if self.Firm.MiniMap.WBP_HUD_MiniMap_Content.MarkerPointsItems then
                                self.Firm.MiniMap.WBP_HUD_MiniMap_Content.MarkerPointsItems[Index] = nil
                            end
                        end
                    end
                    local LabelsIndex = GetLabelsIndexFromTable(self)
                    if LabelsIndex ~= nil then
                        self:DeleteGridIconData(LabelsIndex)
                        table.remove(self.Firm.Labels, LabelsIndex)
                        --if self.MiniLabels and self.MiniLabels[LabelsIndex - 1] then
                        --    table.remove(self.MiniLabels, LabelsIndex - 1)
                        --end
                    end
                    if self.PreviousAnchor ~= nil then
                        self.PreviousAnchor.DX_Target_Selected:SetVisibility(UE.ESlateVisibility.Collapsed)
                        self.PreviousAnchor = nil
                    end
                    self.bIsOnClickedAnchor = false
                    self.Firm.bIsOpenCustomInterface = false
                    self.Firm.Parent.bIsAnchorPopup = false
                    self.Firm.Parent.bIsTransmitOffice = false
                end
            end
        end })
    end
end

---@param self WBP_Firm_SidePopupWindow
local function OnClickedBatchSelection(self)
    self:PlayAnimation(self.DX_SwitchInformation, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    self.Txt_Title:SetText(ConstText.GetConstText(BATCH_TITLE))
    self.Canvas_TitleIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Canvas_EditAnchorDesc:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Canvas_AnchorPosition:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.WBP_ComBtn_CheckBox_SelectAll.Switch_Check:SetActiveWidgetIndex(0)

    self.TileView_Anchor:SetSelectionMode(UE.ESelectionMode.Multi)
    self.Switcher_BtnStyle:SetActiveWidgetIndex(2)
    self.WBP_ComBtn_Delete_1:SetIsEnabled(false)
    self.WBP_ComBtn_ExportSelected:SetIsEnabled(false)
    for i, v in pairs(self.Firm.MultipleSelectionIndex) do
        v.bIsChecked = false
    end
    if self.PreviousAnchor ~= nil then
        self.PreviousAnchor.DX_Target_Selected:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    self:SetBatchSelectionDatas()
    self:PlayAnimation(self.DX_AnchorListIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    self:BindToAnimationFinished(self.DX_AnchorListIn, { self, function()
        RefreshEmptyState(self, false)
        self:SetAnchorListInfo()
        OnListViewScrolled(self, 0)
    end })

end

---@param self WBP_Firm_SidePopupWindow
---@return boolean
local function CalculateAnchorCurLimit(self)
    local AnchorCount = 0
    for i, v in pairs(self.Firm.MarkerPointsItems) do
        AnchorCount = AnchorCount + 1
    end
    if AnchorCount and AnchorCount < self.Firm.AnchorUpperLimit then
        return true
    end
    return false
end

function WBP_Firm_SidePopupWindow:ChangeDataToArray()
    local MultiData = {}
    if self.Firm.MultipleSelectionIndex then
        for i, v in pairs(self.Firm.MultipleSelectionIndex) do
            table.insert(MultiData, v)
        end
    end
    table.sort(MultiData, function(a, b)
        return a.PicKey < b.PicKey
    end)
    return MultiData
end

---@param PositionOne FVector2D
---@param PositionTwo FVector2D
function WBP_Firm_SidePopupWindow:ComparisonCoordinate(PositionOne, PositionTwo)
    if PositionOne and PositionTwo then
        if math.abs(PositionOne.X - PositionTwo.X) < 1 and math.abs(PositionOne.Y - PositionTwo.Y) < 1 then
            return true
        end
    end
end

---@param Index integer
function WBP_Firm_SidePopupWindow:DeleteGridIconData(Index)
    if Index ~= nil and self.Firm ~= nil and self.Firm.Labels[Index] ~= nil and self.Firm.Labels[Index].GridLocation ~= nil then
        local Row = self.Firm.Labels[Index].GridLocation.X
        local Column = self.Firm.Labels[Index].GridLocation.Y
        if self.Firm.ChildImages[Row] ~= nil and self.Firm.ChildImages[Row][Column] ~= nil then
            for i, v in ipairs(self.Firm.ChildImages[Row][Column].Labels) do
                if self:ComparisonCoordinate(v.Location2D, self.Firm.Labels[Index].Location2D) then
                    table.remove(self.Firm.ChildImages[Row][Column].Labels, i)
                end
            end
        end
    end
end

---@param Item WBP_FirmMapLabel
function WBP_Firm_SidePopupWindow:RemoveMiniMapGuideUI(Item)
    if Item == nil then
        G.log:warn("WBP_Firm_SidePopupWindow", "Error! Item is nil")
        return
    end
    for i = 1, self.MiniLabels:Length() do
        local MiniLabel = self.MiniLabels:GetRef(i)
        if MiniLabel and MiniLabel.Location2D then
            local AnchorLocNum = Item.AnchorItem.Location2D.X / Item.AnchorItem.Location2D.Y
            local MiniAnchorLocNum = MiniLabel.Location2D.X / MiniLabel.Location2D.Y
            local formattedAnchorNum = string.format("%.3f", AnchorLocNum)
            local formattedNum = string.format("%.3f", MiniAnchorLocNum)
            if formattedAnchorNum == formattedNum then
                self.CanvasLabels:RemoveChild(MiniLabel)
                self.MiniLabels:RemoveItem(MiniLabel)
                if MiniLabel.FloatUI ~= nil then
                    self.CanvasFloatLabels:RemoveChild(MiniLabel.FloatUI)
                end
                break
            end
        end
    end
end

---@param TempId integer
function WBP_Firm_SidePopupWindow:RemoveMapFloatUI(TempId)
    if TempId == nil then
        G.log:warn("WBP_Firm_SidePopupWindow", "TempId is nil")
        return
    end
    for i,v in ipairs(self.Firm.FloatLabelsUI) do
        if TempId == v.TempId then
            table.remove(self.Firm.FloatLabelsUI,i)
        end
    end
end

function WBP_Firm_SidePopupWindow:RefreshCheckedData()
    local TotalNum = 0
    local CheckedNum = 0
    for i, v in pairs(self.Firm.MultipleSelectionIndex) do
        if v.bIsChecked then
            TotalNum = TotalNum + v.TotalNum
        end
    end
    for j, k in pairs(self.Firm.MarkerPointsItems) do
        if k.bIsChecked then
            CheckedNum = CheckedNum + 1
        end
    end
    if TotalNum == CheckedNum and TotalNum > 0 then
        ChangeOnClickedState(self, true)
    else
        ChangeOnClickedState(self, false)
    end
end

function WBP_Firm_SidePopupWindow:RefreshMultiDeleteBtn()
    for i, v in pairs(self.Firm.MarkerPointsItems) do
        if v.bIsChecked == true then
            ChangeBtnState(self, v.bIsChecked)
        else
            ChangeBtnState(self, v.bIsChecked)
        end
    end
end

---多选删除逻辑
---@param self WBP_Firm_SidePopupWindow
local function OnClickedDeleteMultiAnchor(self)
    ---@type WBP_FirmSecondaryConfirmation_Popup
    local FirmSecondaryConfirmationPopup = UIManager:OpenUI(UIDef.UIInfo.UI_FirmSecondaryConfirmation_Popup)
    FirmSecondaryConfirmationPopup:InitData(self, self.Firm.MarkerPointsItems, self.Firm.MultipleSelectionIndex, false, self.PreviousAnchor)
end

---@param Data MarkerItem
local function UpdateCheckedStatus(Data, bIsChecked)
    if bIsChecked then
        Data.CheckedNum = Data.CheckedNum + 1
    else
        Data.CheckedNum = Data.CheckedNum - 1
    end
end

---@param self WBP_Firm_SidePopupWindow
local function OnClickedSelectAll(self)
    self.bIsSelectAnchor = false
    local bIsClicked = not self.bIsOnClicked
    ChangeOnClickedState(self, bIsClicked)
    for i, v in pairs(self.Firm.MarkerPointsItems) do
        local SelectionData = self.Firm.MultipleSelectionIndex[v.SelectIconIndex]
        if bIsClicked and SelectionData.bIsChecked and not v.bIsChecked then
            self.WBP_ComBtn_Delete_1:SetIsEnabled(true)
            self.WBP_ComBtn_ExportSelected:SetIsEnabled(true)
            UpdateCheckedStatus(SelectionData, true)
            self.Firm.MarkerPointsItems[i].bIsChecked = true
            self.Firm.MarkerPointsItems[i].AnchorItem.DX_Target_Selected:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.Firm.MarkerPointsItems[i].AnchorItem:PlayAnimation(self.Firm.MarkerPointsItems[i].AnchorItem.DX_IconSelect, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
        elseif not bIsClicked and SelectionData.bIsChecked and v.bIsChecked then
            self.WBP_ComBtn_Delete_1:SetIsEnabled(false)
            self.WBP_ComBtn_ExportSelected:SetIsEnabled(false)
            UpdateCheckedStatus(SelectionData, false)
            self.Firm.MarkerPointsItems[i].bIsChecked = false
            self.Firm.MarkerPointsItems[i].AnchorItem.DX_Target_Selected:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
    self:SetBatchSelectionDatas()
    self:SetAnchorListInfo()
end

---导出
---@param self WBP_Firm_SidePopupWindow
local function OnClickedExportSelected(self)
    local ExportData = {}
    for key, value in pairs(self.Firm.MarkerPointsItems) do
        if value.bIsChecked == true then
            local Item = {}
            Item.PicKey = value.SelectIconIndex
            Item.PositionX = value.PositionX
            Item.PositionY = value.PositionY
            Item.AnchorName = value.AnchorName
            table.insert(ExportData, Item)
            value.bIsChecked = false
        end
    end

    local Content = json.encode(ExportData)
    local Path = UE.UBlueprintPathsLibrary.ProjectSavedDir() .. "/Map" .. "/Labels.json"
    FirmUtil.WriteFile(Path, Content)
    self.Firm.Parent:HideRightPopupWindow()
    self.Firm:ResetAnchorData()
    for i, v in pairs(self.Firm.MultipleSelectionIndex) do
        v.bIsChecked = false
    end
    ---@type WBP_FirmSecondaryConfirmation_Popup
    local FirmSecondaryConfirmationPopup = UIManager:OpenUI(UIDef.UIInfo.UI_FirmSecondaryConfirmation_Popup)
    FirmSecondaryConfirmationPopup:InitData(self, self.Firm.MarkerPointsItems, self.Firm.MultipleSelectionIndex, true)
    self.Firm.Parent.bIsAnchorPopup = false
    self.Firm.Parent.bIsDetailPopup = false
    self.Firm.Parent.IsRightPopupVisible = false
    self.Firm.Parent.bIsTransmitOffice = false
    self.Firm.bIsOpenCustomInterface = false

end

---@param self WBP_Firm_SidePopupWindow
local function OnClickCloseButton(self)
    if self.bKeepMarkerVisible ~= true and self.FirmMarkerPointsItem then
        self.FirmMarkerPointsItem:PlayAnimation(self.FirmMarkerPointsItem.DX_TeleportOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
        self.FirmMarkerPointsItem:BindToAnimationFinished(self.FirmMarkerPointsItem.DX_TeleportOut, { self, function()
            if self.Firm then
                if self.bKeepMarkerVisible ~= true and self.FirmMarkerPointsItem ~= nil then
                    self.bKeepMarkerVisible = false
                    self.FirmMarkerPointsItem:RemoveFromParent()
                    self.FirmMarkerPointsItem = nil
                    if self. PreviousAnchor ~= nil then
                        self.PreviousAnchor.DX_Target_Selected:SetVisibility(UE.ESlateVisibility.Collapsed)
                        self.PreviousAnchor = nil
                    end
                    
                    for i, Anchor in ipairs(self.Firm.Labels) do
                        if Anchor.PicKey == self.CurrentSelectedAnchorItemPicKey and Anchor.bIsAdd == false and self:ComparisonCoordinate(self.Position, Anchor.Location2D) then
                            self:DeleteGridIconData(i)
                            table.remove(self.Firm.Labels, i)
                        end
                    end
                end

            end
        end })
    end
    if self.Firm ~= nil then
        self.Firm.Parent.IsRightPopupVisible = false
        self.Firm.Parent.bIsDetailPopup = false
        self.Firm.Parent.bIsAnchorPopup = false
        self.Firm.bIsOpenCustomInterface = false
        self.Firm.Parent.bIsTransmitOffice = false
        self.Firm.Parent:CheckMapHeadIsShow()
        self.Firm:ResetAnchorData()
        self.Firm.Parent:HideRightPopupWindow()
    end
    if self. PreviousAnchor ~= nil then
        self.PreviousAnchor.DX_Target_Selected:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.PreviousAnchor = nil
    end
    self.bIsOnClickedAnchor = false
end

---@param self WBP_Firm_SidePopupWindow
local function OnClickedImportAnchor(self)
    if self.Firm.bIsOnClickedBlank then
        self.Firm.Parent:HideRightPopupWindow()
        local bIsExceedLimit = CalculateAnchorCurLimit(self)
        if bIsExceedLimit then
            if self.bKeepMarkerVisible ~= true and self.FirmMarkerPointsItem ~= nil then
                self.bKeepMarkerVisible = false
                self.FirmMarkerPointsItem:RemoveFromParent()
                self.FirmMarkerPointsItem = nil
                self.PreviousAnchor = nil
                for i, Anchor in ipairs(self.Firm.Labels) do
                    if Anchor.PicKey == self.CurrentSelectedAnchorItemPicKey and self:ComparisonCoordinate(self.Position, Anchor.Location2D) then
                        self:DeleteGridIconData(i)
                        table.remove(self.Firm.Labels, i)
                    end
                end
            end
            for key, value in pairs(self.Firm.MarkerPointsItems) do
                self.Firm.MarkerPointsItems[key].bIsChecked = false
            end
            self.Firm:ResetAnchorData()
            ---@type WBP_Firm_SelectImportAnchor
            local FirmImportPopup = UIManager:OpenUI(UIDef.UIInfo.UI_Firm_SelectImportAnchor)
            FirmImportPopup:GetsFimMapIncomingData(self, self.Firm.MarkerPointsItems, self.Firm.MultipleSelectionIndex, self.PreviousAnchor)
        end
        self.Firm.bIsOpenCustomInterface = false
        self.Firm.Parent.bIsAnchorPopup = false
    end
 
end

---@param self WBP_Firm_SidePopupWindow
local function OnClickedTrace(self)

    for i, v in ipairs(self.Firm.Labels) do
        local Position = UE.FVector2D(v.Location2D.X, v.Location2D.Y)
        if v.Type ~= FirmMapLegendTypeTableConst.PlayerPosition then
            if self:ComparisonCoordinate(self.SelectedMarkerPos, v.Location2D) then
                if v.IsTrace ~= nil then
                    if v.IsTrace == false then
                        v.IsTrace = true
                        self.MarkerPointsItem.IsTrace = true
                        self.WBP_ComBtn_Trace.Txt_BtnName:SetText(ConstText.GetConstText(CANCEL_TRACE))
                        self.Firm.Labels[i].DX_Target_Track:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                        self.Firm.Labels[i]:PlayAnimation(self.Firm.Labels[i].DX_TrackLoop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1, false)

                    else
                        v.IsTrace = false
                        self.MarkerPointsItem.IsTrace = false
                        self.WBP_ComBtn_Trace.Txt_BtnName:SetText(ConstText.GetConstText(TRACE))
                        self.Firm.Labels[i]:StopAnimation(self.Firm.Labels[i].DX_TrackLoop)
                        self.Firm.Labels[i].DX_Target_Track:SetVisibility(UE.ESlateVisibility.Collapsed)
                    end
                end
            else
                if v.Mission == nil then
                    v.IsTrace = false
                    self.Firm.Labels[i]:StopAnimation(self.Firm.Labels[i].DX_TrackLoop)
                    self.Firm.Labels[i].DX_Target_Track:SetVisibility(UE.ESlateVisibility.Collapsed)
                    if self.Firm.Labels[i].FloatUI then
                        self.Firm.Labels[i].FloatUI:SetVisibility(UE.ESlateVisibility.Collapsed)
                    end
                end
            end
        end

    end
    self.Firm:CheckLabelInScreen()
    local MiniMapLabels = self.MiniLabels
    for i = 1, MiniMapLabels:Length() do
        if self.MiniItem then
            local MiniLabel = MiniMapLabels:GetRef(i)
            if MiniLabel.Location2D then
                if self:ComparisonCoordinate(self.MiniItem.Location2D, MiniLabel.Location2D) then
                    if MiniLabel.IsTrace == false then
                        MiniLabel.IsTrace = true
                        self.MiniItem.IsTrace = true
                        MiniLabel.DX_Target_Track:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                        MiniLabel:PlayAnimation(MiniMapLabels[i].DX_TrackLoop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1, false)
                    else
                        MiniLabel.IsTrace = false
                        self.MiniItem.IsTrace = false
                        MiniLabel:StopAnimation(MiniMapLabels[i].DX_TrackLoop)
                        MiniLabel.DX_Target_Track:SetVisibility(UE.ESlateVisibility.Collapsed)
                    end
                else
                    MiniLabel.IsTrace = false
                    MiniLabel:StopAnimation(MiniMapLabels[i].DX_TrackLoop)
                    MiniLabel.DX_Target_Track:SetVisibility(UE.ESlateVisibility.Collapsed)
                    if MiniLabel.FloatUI then
                        MiniLabel.FloatUI:SetVisibility(UE.ESlateVisibility.Collapsed)
                    end
                end
            end
        end
    end
end

---传送
---@param self WBP_Firm_SidePopupWindow
local function OnClickedTransmit(self)
    if self.IsTraceBtn then
        if self.FirmMap then
            local bRemoveMissionLabel = false
            for i, v in ipairs(self.FirmMap.WBP_Firm_Content.Labels) do
                if v.Type ~= FirmMapLegendTypeTableConst.PlayerPosition then
                    if self:ComparisonCoordinate(self.SelectedMarkerPos, v.Location2D) then
                        if v.IsTrace ~= nil then
                            if v.IsTrace == false then
                                v.IsTrace = true
                                self.MarkerPointsItem.IsTrace = true
                                self.WBP_ComBtn_Transmit.Txt_BtnName:SetText(ConstText.GetConstText(CANCEL_TRACE))
                                self.FirmMap.WBP_Firm_Content.Labels[i].DX_Target_Track:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                                self.FirmMap.WBP_Firm_Content.Labels[i]:PlayAnimation(self.FirmMap.WBP_Firm_Content.Labels[i].DX_TrackLoop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1, false)
                            else
                                v.IsTrace = false
                                self.MarkerPointsItem.IsTrace = false
                                self.WBP_ComBtn_Transmit.Txt_BtnName:SetText(ConstText.GetConstText(TRACE))
                                self.FirmMap.WBP_Firm_Content.Labels[i]:StopAnimation(self.FirmMap.WBP_Firm_Content.Labels[i].DX_TrackLoop)
                                self.FirmMap.WBP_Firm_Content.Labels[i].DX_Target_Track:SetVisibility(UE.ESlateVisibility.Collapsed)
                            end
                        end
                        if v.Mission then
                            self.WBP_ComBtn_Transmit.Txt_BtnName:SetText(ConstText.GetConstText(TRACE))
                            ---@type TaskMainVM
                            local TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
                            TaskMainVM:ToggleTaskTrack(v.Mission)
                            v:RemoveFromParent()
                            table.remove(self.FirmMap.WBP_Firm_Content.Labels, i)
                            if v.FloatUI then
                                v.FloatUI:RemoveFromParent()
                            end
                            self.FirmMap:HideRightPopupWindow()
                            bRemoveMissionLabel = true
                        end
                    else
                        if v.Mission == nil then
                            v.IsTrace = false
                            self.FirmMap.WBP_Firm_Content.Labels[i]:StopAnimation(self.FirmMap.WBP_Firm_Content.Labels[i].DX_TrackLoop)
                            self.FirmMap.WBP_Firm_Content.Labels[i].DX_Target_Track:SetVisibility(UE.ESlateVisibility.Collapsed)
                            if self.FirmMap.WBP_Firm_Content.Labels[i].FloatUI then
                                self.FirmMap.WBP_Firm_Content.Labels[i].FloatUI:SetVisibility(UE.ESlateVisibility.Collapsed)
                            end
                        end
                    end
                end
            end
            self.FirmMap.WBP_Firm_Content:CheckLabelInScreen()
            local MiniMapLabels = self.MiniLabels
            for i = 1, MiniMapLabels:Length() do
                if self.MiniItem then
                    local MiniLabel = MiniMapLabels:GetRef(i)
                    if self:ComparisonCoordinate(self.MiniItem.Location2D, MiniLabel.Location2D) and not bRemoveMissionLabel then
                        if MiniLabel.IsTrace == false then
                            MiniLabel.IsTrace = true
                            self.MiniItem.IsTrace = true
                            MiniLabel.DX_Target_Track:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                            MiniLabel:PlayAnimation(MiniLabel.DX_TrackLoop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1, false)
                        else
                            MiniLabel.IsTrace = false
                            self.MiniItem.IsTrace = false
                            MiniLabel:StopAnimation(MiniLabel.DX_TrackLoop)
                            MiniLabel.DX_Target_Track:SetVisibility(UE.ESlateVisibility.Collapsed)
                        end
                    else
                        MiniLabel.IsTrace = false
                        MiniLabel:StopAnimation(MiniLabel.DX_TrackLoop)
                        MiniLabel.DX_Target_Track:SetVisibility(UE.ESlateVisibility.Collapsed)
                        if MiniLabel.FloatUI then
                            MiniLabel.FloatUI:SetVisibility(UE.ESlateVisibility.Collapsed)
                        end
                    end
                end
            end

        end
    else
        if self.FirmMap.bIsTransmitOffice then
            local Avatar = UE.UGameplayStatics.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
            if Avatar == nil then
                G.log:debug("ghgame", "Error! Avatar is nil")
                return
            end
            if Avatar.TeleportComponent == nil then
                G.log:debug("ghgame", "Error! Avatar.TeleportComponent is nil")
                return
            end
            if Avatar.TeleportComponent.Server_TeleportToOffice == nil then
                G.log:debug("ghgame", "Error! Avatar.TeleportComponent.Server_TeleportToOffice is nil")
                return
            end
            Avatar.TeleportComponent:Server_TeleportToOffice()
        else
            local Avatar = UE.UGameplayStatics.GetPlayerCharacter(self, 0)
            if Avatar == nil then
                G.log:debug("ghgame", "Error! Avatar is nil")
                return
            end
            if Avatar.TeleportComponent == nil then
                G.log:debug("ghgame", "Error! Avatar.TeleportComponent is nil")
                return
            end
            if Avatar.TeleportComponent.RequestTeleportToActor == nil then
                G.log:debug("ghgame", "Error! Avatar.TeleportComponent.RequestTeleportToActor is nil")
                return
            end
            if self.ActorId == nil then
                G.log:debug("ghgame", "Error! Avatar.ActorId is nil")
                return
            end
            Avatar.TeleportComponent:RequestTeleportToActor(Enum.Enum_AreaType.MainWorld, self.ActorId)
        end
        if self.PreviousAnchor ~= nil then
            self.PreviousAnchor.DX_Target_Selected:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
        -- self.FirmMap:HideRightPopupWindow()
        -- self.FirmMap.WBP_Firm_Content:ResetAnchorData()
        -- UIManager:CloseUIByName(UIDef.UIInfo.UI_FirmMap.UIName,false)
        -- UIManager:OpenUI(UIDef.UIInfo.UI_FirmLoading, 1)
    end
end


---@param FirmMap WBP_Firm_Map
function WBP_Firm_SidePopupWindow:ShowEnterOfficeInterface(FirmMap)
    self.FirmMap = FirmMap
    if FirmMap then
        self.Firm = FirmMap.WBP_Firm_Content
    end
    self.Switcher_MapInformation:SetActiveWidgetIndex(0)
    self.WBP_ComBtn_Transmit.Txt_BtnName:SetText(ConstText.GetConstText(TRANSMIT))
end

---@param self WBP_Firm_SidePopupWindow
---@return BP_FirmAnchorsItemObject_C
local function NewFirmAnchorItemObject(self)
    local Path = PathUtil.getFullPathString(self.FirmAnchorsItemClass)
    local FirmAnchorItemObject = LoadObject(Path)
    return NewObject(FirmAnchorItemObject)
end

---@param self WBP_Firm_SidePopupWindow
---@return BP_FirmLandMarkItemObject_C
local function NewFirmLandMarkItemObject(self)
    local Path = PathUtil.getFullPathString(self.FirmLandMarkerItemClass)
    local FirmLandMarkItemObject = LoadObject(Path)
    return NewObject(FirmLandMarkItemObject)
end

---@param self WBP_Firm_SidePopupWindow
---@param LegendId WBP_Firm_SidePopupWindow
local function SetDetailTitle (self, LegendId)
    if LegendId then
        local Title = self.Firm:GetFirmMapLegendTypeData(LegendId).Legend_Name
        if Title then
            self.Txt_Title:SetText(ConstText.GetConstText(Title))
            self.Canvas_TitleIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

---@param AnchorData FirmAnchorData
---@param SelectPicKey string
function WBP_Firm_SidePopupWindow:RefreshSingleItemCheckedState(AnchorData, SelectPicKey)
    for i, v in ipairs(AnchorData) do
        if SelectPicKey == v.PicKey then
            v.bIsSelected = true
        else
            v.bIsSelected = false
        end
    end
end

---@param AnchorsData FirmAnchorData[]
function WBP_Firm_SidePopupWindow:SetAnchorData(AnchorsData)
    local Path = PathUtil.getFullPathString(self.FirmAnchorsItemClass)
    local FirmAnchorItemObject = LoadObject(Path)
    local InAnchorsList = UE.TArray(FirmAnchorItemObject)

    if #AnchorsData == 0 then
        self.CurrentSelectedAnchorItemPicKey = nil
        self.TileView_Anchor:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    for i = 1, #AnchorsData do
        if self.Firm.bIsOnClickedBlank == true then
            self.CurrentSelectedAnchorItemPicKey = AnchorsData[1].PicKey
        else
            self.CurrentSelectedAnchorItemPicKey = self.SelectAnchorPicKey
        end
        local FirmAnchorItem = NewFirmAnchorItemObject(self)
        FirmAnchorItem.PicKey = AnchorsData[i].PicKey
        FirmAnchorItem.AnchorOwnerWidget = self
        FirmAnchorItem.bIsDisplayText = false
        FirmAnchorItem.TotalAnchorNum = 0
        FirmAnchorItem.bIsSelected = AnchorsData[i].bIsSelected
        FirmAnchorItem.bIsImportAnchor = false
        InAnchorsList:Add(FirmAnchorItem)
    end
    self.TileView_Anchor:BP_SetListItems(InAnchorsList)
end

---@param AnchorData FirmAnchorData
function WBP_Firm_SidePopupWindow:InitAnchorData(AnchorData)
    self:SetAnchorData(AnchorData)
end

---@param Firm WBP_Firm_Content
function WBP_Firm_SidePopupWindow:AddAnchorToTheMap(Firm)
    if Firm then
        Firm:AddLabel(self.Location, self.AnchorId, FirmMapLegendTypeTableConst.Anchor, false, self.CurrentSelectedAnchorItemPicKey, nil)
        Firm:TrimLabel(Firm.CustomUI)
        self.FirmMarkerPointsItem = Firm.CustomUI
        self.AnchorTypeId = FirmUtil.GetMapLegendIdByType(Firm.CustomUI.Type)
        if self.AnchorTypeId then
            local AnchorData = Firm:GetFirmMapLegendTypeData(self.AnchorTypeId)
            if AnchorData then
                if Firm.CustomUI.AnchorName == "" or Firm.CustomUI.AnchorName == nil then
                    local Type = AnchorData.Legend_Name
                    if Type then
                        self.WBP_Common_InputBox:SetText(Type)
                    end
                end
                if Firm.Parent:CheckLegendInRange(self.AnchorTypeId) then
                    Firm.CustomUI.bIsVisible = true
                    Firm.CustomUI.Icon_CustomMark:SetVisibility(UE.ESlateVisibility.Visible)
                else
                    Firm.CustomUI.bIsVisible = false
                    Firm.CustomUI.Icon_CustomMark:SetVisibility(UE.ESlateVisibility.Collapsed)
                end
                if self.PreviousAnchor ~= nil then
                    if self.PreviousAnchor:IsValid() == false then
                        return
                    else
                        self.PreviousAnchor.DX_Target_Selected:SetVisibility(UE.ESlateVisibility.Collapsed)
                    end
                end
                self.PreviousAnchor = self.FirmMarkerPointsItem
                self.PreviousAnchor.DX_Target_Selected:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                self.FirmMarkerPointsItem:PlayAnimation(self.FirmMarkerPointsItem.DX_TeleportIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
                self.PreviousAnchor:PlayAnimation(self.PreviousAnchor.DX_IconSelect, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
            end
        end
    end
end

---@param Firm WBP_Firm_Content
function WBP_Firm_SidePopupWindow:ShowAnchorOnTheMap(Firm)
    local bIsRemoveAnchorItem = false
    if self.FirmMarkerPointsItem ~= nil and self.bKeepMarkerVisible == false and self.Location then
        bIsRemoveAnchorItem = true
        self.FirmMarkerPointsItem:RemoveFromParent()
        self.FirmMarkerPointsItem = nil
        self.PreviousAnchor = nil
        for i, v in ipairs(Firm.Labels) do
            if self:ComparisonCoordinate(Firm.Pos, v.Location2D) then
                self:DeleteGridIconData(i)
                table.remove(Firm.Labels, i)
            end
        end
        self:AddAnchorToTheMap(Firm)
        Firm.bIsOpenCustomInterface = true
    else
        if bIsRemoveAnchorItem == false then
            self:AddAnchorToTheMap(Firm)
        end
    end
end

---@param Index integer
---@param Firm WBP_Firm_Content
function WBP_Firm_SidePopupWindow:InitPopupWindowData(Index, Firm)
    self.WBP_Common_InputBox:HideErrorMsg()
    self.WBP_Common_InputBox.Switch_InputBtn:SetActiveWidgetIndex(1)
    if Index == 0 and Firm == nil then
        self.Switcher_MapInformation:SetActiveWidgetIndex(0)
    else
        G.log:debug("xuexiaoyu", "WBP_Firm_SidePopupWindow:InitPopupWindowData %s %s",tostring(self.bIsOnClickedAnchor),tostring(Firm.bIsOnClickedBlank))
        if not self.bIsOnClickedAnchor and Firm.bIsOnClickedBlank then
            self.Firm = Firm
            self.Switcher_MapInformation:SetActiveWidgetIndex(Index)
            self.AnchorData = Firm:GetFirmAnchorData()
            self.Location = Firm.Location
            self.Position = Firm.Location2D
            self.AnchorId = FirmUtil.GetMapLegendIdByType(FirmMapLegendTypeTableConst.Anchor)
            local MiniMap = Firm.MiniMap
            if MiniMap then
                if MiniMap.WBP_HUD_MiniMap_Content.Labels then
                    self.CanvasLabels = MiniMap.WBP_HUD_MiniMap_Content.CanvasPanel_Labels
                    self.CanvasFloatLabels = MiniMap.WBP_HUD_MiniMap_Content.CanvasPanel_FloatLabels
                    self.MiniLabels = MiniMap.WBP_HUD_MiniMap_Content.Labels
                end
            end
            self.Canvas_EditAnchorDesc:SetVisibility(UE.ESlateVisibility.Visible)
            self.Canvas_AnchorPosition:SetVisibility(UE.ESlateVisibility.Visible)
            self.WBP_Common_InputBox.EditableText_Content:SetText("")
            RefreshSideWindow(self)
            self:InitAnchorData(self.AnchorData)
            self:ShowAnchorOnTheMap(Firm)

            local bIsImportEnable = CalculateAnchorCurLimit(self)
            self.WBP_ComBtn_Import:SetIsEnabled(bIsImportEnable)
            self.WBP_ComBtn_Commit:SetIsEnabled(bIsImportEnable)
        end
        SetDetailTitle(self, self.AnchorId)
        self.Index = Index
        self.bKeepMarkerVisible = false
    end
end

---@param Content WBP_Firm_Content
---@param Labels WBP_FirmMapLabel[]
---@param Key integer
function WBP_Firm_SidePopupWindow:InitOnClickedMarkerPoints(Content, Labels, Key)
    self.Switcher_MapInformation:SetActiveWidgetIndex(1)
    self.Canvas_EditAnchorDesc:SetVisibility(UE.ESlateVisibility.Visible)
    self.Canvas_AnchorPosition:SetVisibility(UE.ESlateVisibility.Visible)
    self.bIsOnClickedAnchor = true
    self.OnClickPicKey = Key
    local SelectPicKey = nil
    local Pos = nil
    local AnchorName = nil
    local AnchorItem = nil
    local AnchorShowId = nil
    if Content then
        for i, v in ipairs(Labels) do
            if Key == v.TempId then
                SelectPicKey = Labels[i].PicKey
                Pos = Labels[i].Location2D
                AnchorName = Labels[i].AnchorName
                AnchorItem = Labels[i]
                AnchorShowId = Labels[i].ShowId
                break
            end
        end
        local MiniMap = Content.MiniMap
        if MiniMap then
            if MiniMap.WBP_HUD_MiniMap_Content.Labels then
                self.CanvasLabels = MiniMap.WBP_HUD_MiniMap_Content.CanvasPanel_Labels
                self.CanvasFloatLabels = MiniMap.WBP_HUD_MiniMap_Content.CanvasPanel_FloatLabels
                self.MiniLabels = MiniMap.WBP_HUD_MiniMap_Content.Labels
                for i = 1, self.MiniLabels:Length() do
                    local v = self.MiniLabels:GetRef(i)
                    if v.Location2D ~= nil then
                        local MiniNum = v.Location2D.X / v.Location2D.Y
                        local formattedNum = string.format("%.3f", MiniNum)
                        local AnchorNum = AnchorItem.Location2D.X / AnchorItem.Location2D.Y
                        local formattedAnchorNum = string.format("%.3f", AnchorNum)
                        if formattedNum == formattedAnchorNum then
                            local MiniItem = v
                            self.MiniItem = MiniItem
                        end
                    end
                end
            end
        end
        Content.bIsOnClickedBlank = false
        Content.bIsOpenCustomInterface = false
        self.SelectAnchorPicKey = SelectPicKey
        self.MarkerPointsItem = AnchorItem
        self.SelectedMarkerPos = Pos
        self.ChooseAnchorName = AnchorName
        if AnchorName ~= "" and AnchorName ~= nil then
            self.WBP_Common_InputBox.EditableText_Content:SetText(self.ChooseAnchorName)
        end
        self.WBP_Common_InputBox:HideErrorMsg()
        self.Canvas_Anchor_Export:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Canvas_EmptyState:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Switcher_BtnStyle:SetActiveWidgetIndex(1)
        self.TileView_Anchor:SetSelectionMode(UE.ESelectionMode.Single)
        if self.PreviousAnchor ~= nil then
            if self.PreviousAnchor:IsValid() == false then
                return
            else
                self.PreviousAnchor.DX_Target_Selected:SetVisibility(UE.ESlateVisibility.Collapsed)
            end
        end
        self.PreviousAnchor = self.MarkerPointsItem
        self.PreviousAnchor.DX_Target_Selected:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.PreviousAnchor:PlayAnimation(self.PreviousAnchor.DX_IconSelect, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
        self.AnchorData = Content.AnchorData
        self.Firm = Content
        SetDetailTitle(self, AnchorShowId)
        self:RefreshSingleItemCheckedState(self.AnchorData, SelectPicKey)
        self:InitAnchorData(self.AnchorData)
        for i, v in pairs(self.Firm.Labels) do
            local Position = UE.FVector2D(v.Location2D.X, v.Location2D.Y)
            if self:ComparisonCoordinate(self.SelectedMarkerPos, Position) then
                if v.IsTrace then
                    self.WBP_ComBtn_Trace.Txt_BtnName:SetText(ConstText.GetConstText(CANCEL_TRACE))
                else
                    self.WBP_ComBtn_Trace.Txt_BtnName:SetText(ConstText.GetConstText(TRACE))
                end
            end
        end
    end

end

---显示地标详情界面
---@param Labels WBP_FirmMapLabel[]
---@param Key integer
---@param MapIconData MapsIconData[]
---@param ShowId integer
---@param LabelsUI  WBP_FirmMapLabel
function WBP_Firm_SidePopupWindow:ShowDescInterface(Labels, Key, MapIconData, ShowId, LabelsUI)
    if Labels and Key and ShowId and self.FirmMap then
        local LegendId = self.FirmMap.WBP_Firm_Content:GetFirmMapLegendData(ShowId).Legend_ID
        local LegendType = self.FirmMap.WBP_Firm_Content:GetFirmMapLegendTypeData(LegendId).LegendType
        local NameData = self.FirmMap.WBP_Firm_Content:GetFirmMapLegendData(ShowId).Legend_Name
        if NameData == "" or NameData == nil then
            NameData = self.FirmMap.WBP_Firm_Content:GetFirmMapLegendTypeData(LegendId).Legend_Name
        end
        local TitleName = ConstText.GetConstText(NameData)
        for i, v in ipairs(Labels) do
            if v.TempId == Key then
                if LabelsUI.Type ~= FirmMapLegendTypeTableConst.BigArea_Transport and LabelsUI.Type ~= FirmMapLegendTypeTableConst.SmallArea_Transport and LabelsUI.Type ~= FirmMapLegendTypeTableConst.Instance then
                    if self:DetermineTransportPosition(LabelsUI) then
                        self.IsTraceBtn = false
                        self.WBP_ComBtn_Transmit.Txt_BtnName:SetText(string.format((ConstText.GetConstText(SEND_TO)) .. self.TraceBtnName))
                    else
                        self.IsTraceBtn = true
                        if v.IsTrace then
                            self.WBP_ComBtn_Transmit.Txt_BtnName:SetText(ConstText.GetConstText(CANCEL_TRACE))
                        else
                            self.WBP_ComBtn_Transmit.Txt_BtnName:SetText(ConstText.GetConstText(TRACE))
                        end
                    end
                else
                    self.IsTraceBtn = false
                    self.WBP_ComBtn_Transmit.Txt_BtnName:SetText(ConstText.GetConstText(TRANSMIT))
                end
                if v.Mission then
                    self.Canvas_TitleIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                    self.Iocn_Title:SetVisibility(UE.ESlateVisibility.Collapsed)
                    self.WBP_HUD_Task_Icon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                    self.WBP_ComBtn_Transmit.Txt_BtnName:SetText(ConstText.GetConstText(CANCEL_TRACE))
                    local TrackType = v.Mission:GetMissionType()
                    local TrackState = v.Mission:GetMissionTrackIconType()
                    IconUtility:SetTaskIcon(self.WBP_HUD_Task_Icon, TrackType, TrackState - 1)
                    self.Txt_Title:SetText(v.Mission:GetMissionName())
                    if v.Mission:GetMissionAwards() then
                        local Awards = v.Mission:GetMissionAwards()
                        self.TileViewProxy:SetListItems(Awards)
                    else
                        self.Tile_RewardWBPProp:SetVisibility(UE.ESlateVisibility.Collapsed)
                    end
                else
                    self.Txt_Title:SetText(TitleName)
                    self.Tile_RewardWBPProp:SetVisibility(UE.ESlateVisibility.Collapsed) 
                    if LegendType == FirmMapLegendTypeTableConst.Task then
                        self.Canvas_TitleIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                        self.Iocn_Title:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                        self.WBP_HUD_Task_Icon:SetVisibility(UE.ESlateVisibility.Collapsed)
                        PicConst.SetImageBrush(self.Iocn_Title, MapIconData[tonumber(LegendId)].Icon)
                    else
                        self.Canvas_TitleIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
                    end
                    if MapIconData[tonumber(LegendId)].bIsRewards then
                        local Items = MissionSystem:CreateItemList(5)
                        self.TileViewProxy:SetListItems(Items)
                        self.Tile_RewardWBPProp:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                    else
                        self.Tile_RewardWBPProp:SetVisibility(UE.ESlateVisibility.Collapsed)
                    end
                end
            end
        end
    end
end

---判断追踪点的周围是否有传送点
---@param LabelsUI  WBP_FirmMapLabel
function WBP_Firm_SidePopupWindow:DetermineTransportPosition(LabelsUI)
    local Found = false
    local AllAdjacentCellsData = {}
    local LegendData = {}
    if LabelsUI and self.FirmMap then
        local Avatar = UE.UGameplayStatics.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
        local PawnPosition = Avatar:K2_GetActorLocation()
        local PlayerToTarget = math.ceil(math.sqrt(math.abs(PawnPosition.X - LabelsUI.Location.X) ^ 2 + math.abs(PawnPosition.Y - LabelsUI.Location.Y) ^ 2 + math.abs(PawnPosition.Z - LabelsUI.Location.Z) ^ 2))
        local CurGridData = self.FirmMap.WBP_Firm_Content.ChildImages[LabelsUI.GridLocation.X][LabelsUI.GridLocation.Y].Labels
        table.insert(AllAdjacentCellsData, CurGridData)
        local AdjacentCells = self.FirmMap.WBP_Firm_Content:GetAdjacentCells(LabelsUI.GridLocation.X, LabelsUI.GridLocation.Y)
        if AdjacentCells then
            for i, Grid in ipairs(AdjacentCells) do
                local row = Grid[1]
                local column = Grid[2]
                local AdjacentLabelsData = self.FirmMap.WBP_Firm_Content.ChildImages[row][column].Labels
                table.insert(AllAdjacentCellsData, AdjacentLabelsData)
            end
            for j, data in ipairs(AllAdjacentCellsData) do
                for i, v in ipairs(data) do
                    if v.Type ~= FirmMapLegendTypeTableConst.Anchor then
                        table.insert(LegendData, v)
                    end
                end
            end
        end
        table.sort(LegendData,function(a, b) return a.TempId < b.TempId end)
        local MinDistance = math.huge
        local MinItem = nil
        for k, v in ipairs(LegendData) do
            local DifferX = math.abs((v.Location.X - LabelsUI.Location.X))
            local DifferY = math.abs((v.Location.Y - LabelsUI.Location.Y))
            local DifferZ = math.abs((v.Location.Z - LabelsUI.Location.Z))
            local Distance = math.sqrt(DifferX * DifferX + DifferY * DifferY + DifferZ + DifferZ)
            if Distance < self.FirmMap.WBP_Firm_Content.RangeDistance then
                if v.Type == FirmMapLegendTypeTableConst.BigArea_Transport or v.Type == FirmMapLegendTypeTableConst.SmallArea_Transport or v.Type == FirmMapLegendTypeTableConst.Instance then
                    if Distance < MinDistance then
                        MinDistance = Distance
                        MinItem = v
                    end
                    Found = true
                end
            end
        end
        if MinItem then
            local ShowId = FirmUtil.GetMapLegendIdByType(MinItem.Type)
            if ShowId then
                self.ActorId = self.FirmMap.WBP_Firm_Content:GetLegendOwingActorId(ShowId)
                local TraceName = self.FirmMap.WBP_Firm_Content:GetFirmMapLegendData(MinItem.ShowId).Legend_Name
                if TraceName == nil or TraceName == "" then
                    TraceName = self.FirmMap.WBP_Firm_Content:GetFirmMapLegendTypeData(ShowId).Legend_Name
                end
                self.TraceBtnName = ConstText.GetConstText(TraceName)
            end
        end
        if Found == false then
            if PlayerToTarget < self.FirmMap.WBP_Firm_Content.RangeDistance then
                return Found
            end
        end
    end
    return Found
end

---@param FirmMap  WBP_Firm_Map
---@param LabelsUI WBP_FirmMapLabel
---@param MapIconData MapsIconData[]
---@param ShowId integer
---@param Labels WBP_FirmMapLabel[]
---@param Key integer
function WBP_Firm_SidePopupWindow:InitOnClickedLabel(FirmMap, LabelsUI, MapIconData, ShowId, Labels, ActorId, Key)
    self.ActorId = ActorId
    self.FirmMap = FirmMap
    if FirmMap then
        self.Firm = FirmMap.WBP_Firm_Content
        if self.PreviousAnchor ~= nil then
            self.PreviousAnchor.DX_Target_Selected:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
        self.PreviousAnchor = LabelsUI
        self.PreviousAnchor.DX_Target_Selected:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.PreviousAnchor:PlayAnimation(self.PreviousAnchor.DX_IconSelect, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
        self.MarkerPointsItem = LabelsUI
        self.SelectedMarkerPos = LabelsUI.Location2D
        local MiniMap = FirmMap.WBP_Firm_Content.MiniMap
        if MiniMap then
            if MiniMap.WBP_HUD_MiniMap_Content.Labels then
                self.CanvasLabels = MiniMap.WBP_HUD_MiniMap_Content.CanvasPanel_Labels
                self.CanvasFloatLabels = MiniMap.WBP_HUD_MiniMap_Content.CanvasPanel_FloatLabels
                self.MiniLabels = MiniMap.WBP_HUD_MiniMap_Content.Labels
                for i = 1, self.MiniLabels:Length() do
                    local v = self.MiniLabels:GetRef(i)
                    if Key - 1 == v.TempId then
                        local MiniItem = v
                        self.MiniItem = MiniItem
                    end
                end
            end
        end
    end
    self.Cvs_Visitor:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Cvs_RewardCollection:SetVisibility(UE.ESlateVisibility.Collapsed)

    --[[if self.WBP_HUD_Task_Icon then
        self.WBP_HUD_Task_Icon:SetVisibility(UE.ESlateVisibility.Collapsed)
    end]]
    self:ShowDescInterface(Labels, Key, MapIconData, ShowId, LabelsUI)
end

---设置批量选择图标数据
function WBP_Firm_SidePopupWindow:SetBatchSelectionDatas()
    local Path = PathUtil.getFullPathString(self.FirmAnchorsItemClass)
    local FirmAnchorItemObject = LoadObject(Path)
    local InAnchorsList = UE.TArray(FirmAnchorItemObject)
    local MultipleAnchorData = self:ChangeDataToArray()
    for i, v in ipairs(MultipleAnchorData) do
        local FirmAnchorItem = NewFirmAnchorItemObject(self)
        FirmAnchorItem.PicKey = v.PicKey
        FirmAnchorItem.AnchorOwnerWidget = self
        FirmAnchorItem.bIsDisplayText = true
        FirmAnchorItem.TotalAnchorNum = v.TotalNum
        FirmAnchorItem.bIsSelected = v.bIsChecked
        FirmAnchorItem.CheckedNum = v.CheckedNum
        FirmAnchorItem.bIsImportAnchor = false
        InAnchorsList:Add(FirmAnchorItem)
    end
    self.TileView_Anchor:BP_SetListItems(InAnchorsList)
end

---设置多选中时的图标列表信息
function WBP_Firm_SidePopupWindow:SetAnchorListInfo()
    local Path = PathUtil.getFullPathString(self.FirmLandMarkerItemClass)
    local FirmLandMarkerItemObject = LoadObject(Path)
    local InLandMarkerList = UE.TArray(FirmLandMarkerItemObject)
    local Index = 0
    for i, MarkerPoints in pairs(self.Firm.MarkerPointsItems) do
        if self.Firm.MultipleSelectionIndex[MarkerPoints.SelectIconIndex].bIsChecked == true then
            local FirmLandMarkerItem = NewFirmLandMarkItemObject(self)
            local Position = UE.FVector2D(MarkerPoints.PositionX, MarkerPoints.PositionY)
            if MarkerPoints.AnchorName == nil or MarkerPoints.AnchorName == "" then
                MarkerPoints.AnchorName = ConstText.GetConstText(AnchorText)
            end
            FirmLandMarkerItem.MarkerName = MarkerPoints.AnchorName
            FirmLandMarkerItem.Position = Position
            FirmLandMarkerItem.OwnerWidget = self
            FirmLandMarkerItem.bIsChecked = MarkerPoints.bIsChecked
            FirmLandMarkerItem.Key = i
            Index = Index + 1
            FirmLandMarkerItem.Index = Index
            InLandMarkerList:Add(FirmLandMarkerItem)
        end
    end
    self.ListView_329:BP_SetListItems(InLandMarkerList)
    self.ListView_329:SetScrollbarVisibility(UE.ESlateVisibility.Collapsed)
end

---@param Key integer
function WBP_Firm_SidePopupWindow:PlayClickAnchorFocusAnimation(Key)
    if self.Firm and self.Firm.MarkerPointsItems then
        local AnchorPosition = UE.FVector2D(self.Firm.MarkerPointsItems[Key].PositionX, self.Firm.MarkerPointsItems[Key].PositionY)
        if AnchorPosition then
            self.Firm:MoveToLocation2D(AnchorPosition)
        end
        self.Firm.MarkerPointsItems[Key].AnchorItem:PlayAnimation(self.Firm.MarkerPointsItems[Key].AnchorItem.DX_Focus, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    end
end

---@param bIsCheck boolean
---@param Key integer
---@param bIsLeft boolean
function WBP_Firm_SidePopupWindow:OnClickedCheck(bIsCheck, Key, bIsLeft)
    if bIsLeft then
        self:PlayClickAnchorFocusAnimation(Key)
    else
        self.bIsSelectAnchor = false
        self.Firm.MarkerPointsItems[Key].bIsChecked = bIsCheck
        if self.Firm.MarkerPointsItems[Key].bIsChecked == true then
            self.WBP_ComBtn_Delete_1:SetIsEnabled(true)
            self.WBP_ComBtn_ExportSelected:SetIsEnabled(true)
            self.Firm.MultipleSelectionIndex[self.Firm.MarkerPointsItems[Key].SelectIconIndex].CheckedNum = self.Firm.MultipleSelectionIndex[self.Firm.MarkerPointsItems[Key].SelectIconIndex].CheckedNum + 1
            self.Firm.MarkerPointsItems[Key].AnchorItem.DX_Target_Selected:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.Firm.MarkerPointsItems[Key].AnchorItem:PlayAnimation(self.Firm.MarkerPointsItems[Key].AnchorItem.DX_IconSelect, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
        else
            self.Firm.MarkerPointsItems[Key].AnchorItem.DX_Target_Selected:SetVisibility(UE.ESlateVisibility.Collapsed)
            for i, v in pairs(self.Firm.MarkerPointsItems) do
                if v.bIsChecked == true then
                    self.WBP_ComBtn_Delete_1:SetIsEnabled(true)
                    self.WBP_ComBtn_ExportSelected:SetIsEnabled(true)
                    break
                else
                    self.WBP_ComBtn_Delete_1:SetIsEnabled(false)
                    self.WBP_ComBtn_ExportSelected:SetIsEnabled(false)
                end
            end
            self.Firm.MultipleSelectionIndex[self.Firm.MarkerPointsItems[Key].SelectIconIndex].CheckedNum = self.Firm.MultipleSelectionIndex[self.Firm.MarkerPointsItems[Key].SelectIconIndex].CheckedNum - 1
        end
        self:RefreshCheckedData()
        self:SetBatchSelectionDatas()
    end
end

---多选图标点击回调
---@param AnchorItem string
---@param AnchorCount integer
---@param bIsChecked boolean
function WBP_Firm_SidePopupWindow:OnChooseMultiAnchorItem(AnchorItem, AnchorCount, bIsChecked)
    self.bIsSelectAnchor = bIsChecked
    local HasTrueValue = false
    self.Firm.MultipleSelectionIndex[AnchorItem.PicKey].bIsChecked = bIsChecked
    if self.Firm.MultipleSelectionIndex[AnchorItem.PicKey].bIsChecked == false then
        for key, value in pairs(self.Firm.MarkerPointsItems) do
            if AnchorItem.PicKey == value.SelectIconIndex then
                self.Firm.MarkerPointsItems[key].bIsChecked = false
            end
        end
        for i, data in pairs(self.Firm.MultipleSelectionIndex) do
            if data.bIsChecked == true and data.TotalNum > 0 then
                HasTrueValue = true
                break
            end
        end
        if HasTrueValue then
            RefreshEmptyState(self, true)
        else
            RefreshEmptyState(self, false)
        end
        self.Firm.MultipleSelectionIndex[AnchorItem.PicKey].CheckedNum = 0
        ChangeOnClickedState(self, false)
    else
        for i, data in pairs(self.Firm.MultipleSelectionIndex) do
            if data.bIsChecked == true and data.TotalNum > 0 then
                RefreshEmptyState(self, true)
                break
            else
                RefreshEmptyState(self, false)
            end
        end
    end

    self:RefreshCheckedData()
    self:SetBatchSelectionDatas()
    self:SetAnchorListInfo()
end

---单选图标点击回调
---@param AnchorItem string
function WBP_Firm_SidePopupWindow:OnClickSingleAnchorItem(AnchorItem)
    local NewItemPicKey = AnchorItem.PicKey
    local OldItemPicKey = self.CurrentSelectedAnchorItemPicKey
    self.CurrentSelectedAnchorItemPicKey = AnchorItem.PicKey
    for Owner, CB in pairs(self.AnchorItemSelectedCallBacks) do
        CB(Owner, AnchorItem)
    end
    if self.bKeepMarkerVisible == false then
        if self.FirmMarkerPointsItem then
            self.FirmMarkerPointsItem.PicKey = self.CurrentSelectedAnchorItemPicKey
            PicConst.SetImageBrush(self.FirmMarkerPointsItem.Icon_CustomMark, tostring(self.CurrentSelectedAnchorItemPicKey))
        end
    end
    if self.bIsOnClickedAnchor then
        self.Firm.MultipleSelectionIndex[OldItemPicKey].TotalNum = self.Firm.MultipleSelectionIndex[OldItemPicKey].TotalNum - 1
        self.Firm.MultipleSelectionIndex[NewItemPicKey].TotalNum = self.Firm.MultipleSelectionIndex[NewItemPicKey].TotalNum + 1
        for i, v in pairs(self.Firm.MarkerPointsItems) do
            local Position = UE.FVector2D(v.PositionX, v.PositionY)
            if self:ComparisonCoordinate(Position, self.SelectedMarkerPos) then
                self.Firm.MarkerPointsItems[i].SelectIconIndex = self.CurrentSelectedAnchorItemPicKey
                PicConst.SetImageBrush(self.MarkerPointsItem.Icon_CustomMark, tostring(self.Firm.MarkerPointsItems[i].SelectIconIndex))
                PicConst.SetImageBrush(self.MiniItem.Icon_CustomMark, tostring(self.Firm.MarkerPointsItems[i].SelectIconIndex))
            end
        end
        for j, v in ipairs(self.Firm.Labels) do
            if self:ComparisonCoordinate(v.Location2D, self.SelectedMarkerPos) then
                self.Firm.Labels[j].PicKey = self.CurrentSelectedAnchorItemPicKey
                if self.Firm.Labels[j].FloatUI then
                    PicConst.SetImageBrush(self.Firm.Labels[j].FloatUI.Img_Target, tostring(self.Firm.Labels[j].PicKey))
                end
            end
        end

        for i = 1, self.MiniLabels:Length() do
            local v = self.MiniLabels:GetRef(i)
            if self:ComparisonCoordinate(v.Location2D, self.MiniItem.Location2D) then
                v.PicKey = self.CurrentSelectedAnchorItemPicKey
            end
        end
    end
end

---@param Owner UObject
---@param AnchorItemSelectedCallBack AnchorItemSelectedCallBackT
function WBP_Firm_SidePopupWindow:RegOnAnchorItemSelected(Owner, AnchorItemSelectedCallBack)
    self.AnchorItemSelectedCallBacks[Owner] = AnchorItemSelectedCallBack
end

---@param Owner UObject
---@param AnchorItemSelectedCallBack AnchorItemSelectedCallBackT
function WBP_Firm_SidePopupWindow:UnRegOnAnchorItemSelected(Owner, AnchorItemSelectedCallBack)
    self.AnchorItemSelectedCallBacks[Owner] = nil
end

function WBP_Firm_SidePopupWindow:OnShow()
    self:PlayAnimation(self.DX_RightIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end


function WBP_Firm_SidePopupWindow:Construct()
    ---@type UTileViewProxy
    self.TileViewProxy = WidgetProxys:CreateWidgetProxy(self.Tile_RewardWBPProp)
    self.RewardItem = {}
    self.GetRewardItem = nil
    self.LandMarkItemsWidgets = {}
    self.AnchorItemSelectedCallBacks = {}
    self.CheckedTotalNum = 0
    self.Key = 0
    self.bIsOnClickedAnchor = false
    self.bIsTrace = false
    self.bIsSelectAll = false
    self.WBP_ComBtn_Close.OnClicked:Add(self, OnClickCloseButton)
    self.WBP_Common_InputBox.EditableText_Content.OnTextChanged:Add(self, RefreshEditableState)
    self.WBP_ComBtn_Commit.OnClicked:Add(self, OnClickedCommit)
    self.WBP_ComBtn_Delete.OnClicked:Add(self, OnClickedDeleteAnchor)
    self.WBP_ComBtn_BatchSelection.OnClicked:Add(self, OnClickedBatchSelection)
    self.WBP_ComBtn_ExportSelected.OnClicked:Add(self, OnClickedExportSelected)
    self.WBP_ComBtn_Import.OnClicked:Add(self, OnClickedImportAnchor)
    self.WBP_ComBtn_Delete_1.OnClicked:Add(self, OnClickedDeleteMultiAnchor)
    self.WBP_ComBtn_CheckBox_SelectAll.WBP_Btn_CheckBox.OnClicked:Add(self, OnClickedSelectAll)
    self.WBP_ComBtn_Trace.OnClicked:Add(self, OnClickedTrace)
    self.WBP_ComBtn_Transmit.OnClicked:Add(self, OnClickedTransmit)
    self.WBP_Common_InputBox:HideErrorMsg()
    self.WBP_Common_InputBox.Switch_Colour:SetActiveWidgetIndex(1)
    self.ListView_329.BP_OnListViewScrolled:Add(self, OnListViewScrolled)
    self.WBP_Common_InputBox.EditableText_Content.OnTextCommitted:Add(self, OnCommittedText)
    --FirmUtil.RegMissionChanged(self,self.OnMissionChanged)
end
function WBP_Firm_SidePopupWindow:Destruct()
    self.WBP_ComBtn_Close.OnClicked:Remove(self, OnClickCloseButton)
    self.WBP_Common_InputBox.EditableText_Content.OnTextChanged:Add(self, RefreshEditableState)
    self.WBP_ComBtn_Commit.OnClicked:Remove(self, OnClickedCommit)
    self.WBP_ComBtn_Delete.OnClicked:Remove(self, OnClickedDeleteAnchor)
    self.WBP_ComBtn_BatchSelection.OnClicked:Remove(self, OnClickedBatchSelection)
    self.WBP_ComBtn_ExportSelected.OnClicked:Remove(self, OnClickedExportSelected)
    self.WBP_ComBtn_Import.OnClicked:Remove(self, OnClickedImportAnchor)
    self.WBP_ComBtn_Delete_1.OnClicked:Remove(self, OnClickedDeleteMultiAnchor)
    self.WBP_ComBtn_CheckBox_SelectAll.WBP_Btn_CheckBox.OnClicked:Remove(self, OnClickedSelectAll)
    self.WBP_ComBtn_Transmit.OnClicked:Remove(self, OnClickedTransmit)
    self.WBP_ComBtn_Trace.OnClicked:Remove(self, OnClickedTrace)
    self.ListView_329.BP_OnListViewScrolled:Remove(self, OnListViewScrolled)
    self.WBP_Common_InputBox.EditableText_Content.OnTextCommitted:Remove(self, OnCommittedText)
    --FirmUtil.UnRegMissionChanged(self,self.OnMissionChanged)
end

-- function M:Tick(MyGeometry, InDeltaTime)
-- end

return WBP_Firm_SidePopupWindow

