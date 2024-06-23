--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local PicConst = require("CP0032305_GH.Script.common.pic_const")
local ConstText = require("CP0032305_GH.Script.common.text_const")
local FirmMapLegendTypeTableConst = require("common.data.firm_map_legend_type_data")
local IconUtility = require('CP0032305_GH.Script.common.utils.icon_util')

---@class WBP_Firm_MapOptions_Item : WBP_Firm_MapOptions_Item_C


---@type WBP_Firm_MapOptions_Item_C
local WBP_Firm_MapOptions_Item = UnLua.Class()

---前往目标点文本
local Target = "GOTOTARGET"

--function M:Initialize(Initializer)
--end

--function M:PreConstruct(IsDesignTime)
--end

function WBP_Firm_MapOptions_Item:Construct()
    self.ComBtn_Normal.Button.OnClicked:Add(self, self.OnClickButton)
end

function WBP_Firm_MapOptions_Item:Destruct()
    self.ComBtn_Normal.Button.OnClicked:Remove(self, self.OnClickButton)
end

function WBP_Firm_MapOptions_Item:OnClickButton()
    ---如果是浮标
    if self.ItemObject.IsFloat then
        self.ItemObject.FirmMapUI.WBP_Firm_Content:MoveToLocation2D(self.Loc)
        self.ItemObject.FirmMapUI.Firm_MapOptions:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.ItemObject.FirmMapUI.WBP_Firm_Content.bShowMapOptions = false
    else
        self.ItemObject.FirmMapUI:ShowRightPopupWindow()
        if self.ItemObject.LabelUI.IsAnchor then
            local Labels = self.ItemObject.FirmMapUI.CloseLabels
            local Key = self.ItemObject.LabelUI.TempId
            self.ItemObject.FirmMapUI.WBP_Firm_SidePopupWindow.bIsOnClickedAnchor = true
            self.ItemObject.FirmMapUI.bIsAnchorPopup = true
            self.ItemObject.FirmMapUI.WBP_Firm_SidePopupWindow:InitOnClickedMarkerPoints(self.ItemObject.FirmMapUI.WBP_Firm_Content, Labels, Key)
            self.ItemObject.FirmMapUI.Firm_MapOptions:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.ItemObject.FirmMapUI.WBP_Firm_Content.bShowMapOptions = false
        else
            local Key = self.ItemObject.LabelUI.TempId
            self.ItemObject.FirmMapUI.WBP_Firm_SidePopupWindow:InitPopupWindowData(0, nil)
            local FirmMapContent = self.ItemObject.FirmMapUI.WBP_Firm_Content
            self.ItemObject.FirmMapUI.bIsDetailPopup = true
            self.ItemObject.FirmMapUI.WBP_Firm_SidePopupWindow:InitOnClickedLabel(self.ItemObject.FirmMapUI, self.ItemObject.LabelUI, FirmMapContent.MapIconData, self.ItemObject.LabelUI.ShowId, FirmMapContent.Labels, self.ItemObject.LabelUI.ActorId, Key)
            self.ItemObject.FirmMapUI.Firm_MapOptions:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.ItemObject.FirmMapUI.WBP_Firm_Content.bShowMapOptions = false
        end
    end
end



--function M:Tick(MyGeometry, InDeltaTime)
--end

---@param ListItemObject BP_FirmMapOptionsObject_C
---@return void
function WBP_Firm_MapOptions_Item:OnListItemObjectSet(ListItemObject)
    self.ItemObject = ListItemObject
    local ItemObject = self.ItemObject
    local Num = ItemObject.LabelUI.TempId
    local PicKey = ItemObject.LabelUI.PicKey
    local Name = ItemObject.LabelUI.AnchorName
    local MapIconData = ItemObject.FirmMapUI.WBP_Firm_Content.MapIconData
    local ShowId = ItemObject.LabelUI.ShowId
    if self.ItemObject.IsFloat then
        local Text = ConstText.GetConstText(Target)
        self.Txt_Normal:SetText(Text .. Num)
    elseif self.ItemObject.LabelUI.Mission then
        self.Txt_Normal:SetText(self.ItemObject.LabelUI.Mission:GetMissionName())
    else
        if Name ~= "" or Name ~= nil then
            self.Txt_Normal:SetText(Name)
        end
    end
    self.Icon_Normal:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.WBP_HUD_Task_Icon:SetVisibility(UE.ESlateVisibility.Collapsed)
    if ItemObject.LabelUI.IsAnchor then
        PicConst.SetImageBrush(self.Icon_Normal, PicKey)
    elseif ItemObject.LabelUI.Type == FirmMapLegendTypeTableConst.PlayerPosition then
        PicConst.SetImageBrush(self.Icon_Normal, MapIconData[tonumber(ShowId)].Icon)
    elseif ShowId and ItemObject.LabelUI.Mission == nil then
        local ItemData = ItemObject.FirmMapUI.WBP_Firm_Content:GetFirmMapLegendData(ShowId)
        if ItemData then
            local TypeId = ItemData.Legend_ID
            PicConst.SetImageBrush(self.Icon_Normal, MapIconData[tonumber(TypeId)].Icon)
        end
    elseif ItemObject.LabelUI.Mission then
        local TrackType = ItemObject.LabelUI.Mission:GetMissionType()
        local TrackState = ItemObject.LabelUI.Mission:GetMissionTrackIconType()
        self.Icon_Normal:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.WBP_HUD_Task_Icon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        IconUtility:SetTaskIcon(self.WBP_HUD_Task_Icon, TrackType, TrackState - 1)
    end
    self.Loc = ItemObject.LabelUI.OldLocation
end

return WBP_Firm_MapOptions_Item
