--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local PicConst = require("CP0032305_GH.Script.common.pic_const")
local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")

---@class WBP_Firm_AnchorIcon : WBP_Firm_AnchorIcon_C
---@type WBP_Firm_AnchorIcon_C
---@field AnchorOwnerWidget WBP_Firm_SidePopupWindow
---@field AnchorItem string
---@field bIsDisplayText boolean
---@field TotalAnchorNum integer
---@field CheckedNum integer
---@field bIsSelected boolean
---@field PicKey string

local WBP_Firm_AnchorIcon = UnLua.Class()
---富文本颜色设置
local FORMAT_DEFAULT = "<Default>%d</>"
---富文本颜色设置
local FORMAT_HIGHLIGHT = "<highlight>%d</>"

-- function M:Initialize(Initializer)
-- end

-- function M:PreConstruct(IsDesignTime)
-- end

---@param PicKey string
---@param self WBP_Firm_AnchorIcon
---@return table
local function GetAnchorItemByPicKey(self, PicKey)
    if self.AnchorOwnerWidget == nil then
        error("Anchor item not found for PicKey: ")
    else
        if self.AnchorOwnerWidget.Firm and PicKey and PicKey ~= "" then
            local AnchorData = self.AnchorOwnerWidget.Firm:GetFirmAnchorData()
            for i, data in ipairs(AnchorData) do
                if data.PicKey == PicKey then
                    return data
                end
            end
            return nil
        end
    end
end

---@param self WBP_Firm_AnchorIcon
local function RefreshSingleSelectedAnchorItem(self)
    local CurrentSelectedAnchorItem = nil
    if self.AnchorOwnerWidget and self.AnchorOwnerWidget.CurrentSelectedAnchorItemPicKey then
        local AnchorItem = GetAnchorItemByPicKey(self, self.AnchorOwnerWidget.CurrentSelectedAnchorItemPicKey)
        CurrentSelectedAnchorItem = AnchorItem
    end
    if CurrentSelectedAnchorItem and CurrentSelectedAnchorItem.PicKey == self.AnchorItem.PicKey then
        self.Img_Select:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Img_AnchorIcon:SetColorAndOpacity(self.SelectedStateLinearColor)
    else
        self.Img_AnchorIcon:SetColorAndOpacity(self.UnselectedStateLinearColor)
        self.Img_Select:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

---@param self WBP_Firm_AnchorIcon
local function RefreshMultiSelected(self)
    if self.bIsSelected then
        self.Img_AnchorIcon:SetColorAndOpacity(self.UnselectedStateLinearColor)
        self.Img_Select:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.bIsSelected = false
    else
        self.Img_AnchorIcon:SetColorAndOpacity(self.SelectedStateLinearColor)
        self.Img_Select:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.bIsSelected = true
    end
    self.AnchorItem.PicKey = self.PicKey
    self.AnchorOwnerWidget:OnChooseMultiAnchorItem(self.AnchorItem, self.TotalAnchorNum, self.bIsSelected)
    UE.UAkGameplayStatics.PostEvent(self.OnClickbtnAkEvent, UE.UGameplayStatics.GetPlayerPawn(self, 0), nil, nil, true)
end

---@param self WBP_Firm_AnchorIcon
local function OnClickSingleAnchorItem(self)
    UE.UAkGameplayStatics.PostEvent(self.OnClickbtnAkEvent, UE.UGameplayStatics.GetPlayerPawn(self, 0), nil, nil, true)
    if self.bIsDisplayText == false then
        if self.AnchorOwnerWidget.OnClickSingleAnchorItem then
            self.AnchorItem.PicKey = self.PicKey
            self.AnchorOwnerWidget:OnClickSingleAnchorItem(self.AnchorItem)
        end
    else
        RefreshMultiSelected(self)
    end
end

---@param self WBP_Firm_AnchorIcon
local function OnAnchorHovered(self)
    self.Img_Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

---@param self WBP_Firm_AnchorIcon
local function OnAnchorUnHovered(self)
    self.Img_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
end

---@param self WBP_Firm_AnchorIcon
---@param AnchorItem string
local function OnSelectedItem(self, AnchorItem)
    RefreshSingleSelectedAnchorItem(self)
end

function WBP_Firm_AnchorIcon:Construct()
    self.MultipleSelectionIndex = {}
    self.Btn_Anchor.OnClicked:Add(self, OnClickSingleAnchorItem)
    self.Btn_Anchor.OnHovered:Add(self, OnAnchorHovered)
    self.Btn_Anchor.OnUnhovered:Add(self, OnAnchorUnHovered)
end

function WBP_Firm_AnchorIcon:Destruct()
    self.Btn_Anchor.OnClicked:Remove(self, OnClickSingleAnchorItem)
    self.Btn_Anchor.OnHovered:Remove(self, OnAnchorHovered)
    self.Btn_Anchor.OnUnhovered:Remove(self, OnAnchorUnHovered)
    if self.AnchorOwnerWidget and self.AnchorOwnerWidget.RegOnAnchorItemSelected then
        self.AnchorOwnerWidget:UnRegOnAnchorItemSelected(self, OnSelectedItem)
    end
end

---@param self WBP_Firm_AnchorIcon
---@param PicKey string
local function ShowAnchorIcon(self, PicKey)
    PicConst.SetImageBrush(self.Img_AnchorIcon, tostring(PicKey))
end

---@param self WBP_Firm_AnchorIcon
local function NumbersAreEqual(self)
    if self.CheckedNum == 0 and self.TotalAnchorNum == 0 then
        self.Text_AnchorNumber:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Text_Slash:SetVisibility(UE.ESlateVisibility.Collapsed)
        local DTotalAnchorNum = string.format(FORMAT_DEFAULT, self.TotalAnchorNum)
        self.TotalAnchorNum = DTotalAnchorNum
    else
        if self.CheckedNum == self.TotalAnchorNum then
            local HCheckNum = string.format(FORMAT_HIGHLIGHT, self.CheckedNum)
            self.CheckedNum = HCheckNum
            local HTotalAnchorNum = string.format(FORMAT_HIGHLIGHT, self.TotalAnchorNum)
            self.TotalAnchorNum = HTotalAnchorNum
            self.Text_Slash:SetText("<highlight>/</>")
        else
            local DCheckNum = string.format(FORMAT_DEFAULT, self.CheckedNum)
            self.CheckedNum = DCheckNum
            local DTotalAnchorNum = string.format(FORMAT_DEFAULT, self.TotalAnchorNum)
            self.TotalAnchorNum = DTotalAnchorNum
            self.Text_Slash:SetText("<Default>/</>")
        end
        self.Text_AnchorNumber:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Text_Slash:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end

end

---@param self WBP_Firm_AnchorIcon
local function SetBottomNumVisibility(self)
    if self.bIsDisplayText == true then
        self.HorizontalBox_41:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        self.Text_AnchorTotal:SetText(self.TotalAnchorNum)
        self.Text_AnchorNumber:SetText(self.CheckedNum)
    else
        if self.bIsImportAnchor == true then
            self.Text_AnchorTotal:SetText(self.TotalAnchorNum)
            self.Text_AnchorNumber:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.Text_Slash:SetVisibility(UE.ESlateVisibility.Collapsed)
        else
            self.HorizontalBox_41:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

---@param self WBP_Firm_AnchorIcon
local function RefreshChooseState(self)
    if self.bIsSelected == true then
        self.Img_Select:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Img_AnchorIcon:SetColorAndOpacity(self.SelectedStateLinearColor)
    else
        self.Img_Select:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Img_AnchorIcon:SetColorAndOpacity(self.UnselectedStateLinearColor)
    end
end

---@param FirmAnchorData BP_FirmAnchorsItemObject_C
function WBP_Firm_AnchorIcon:RefreshAnchorData(FirmAnchorData)
    self.PicKey = FirmAnchorData.PicKey
    self.AnchorOwnerWidget = FirmAnchorData.AnchorOwnerWidget
    self.bIsDisplayText = FirmAnchorData.bIsDisplayText
    self.TotalAnchorNum = FirmAnchorData.TotalAnchorNum
    self.bIsSelected = FirmAnchorData.bIsSelected
    self.CheckedNum = FirmAnchorData.CheckedNum
    self.bIsImportAnchor = FirmAnchorData.bIsImportAnchor
    local AnchorItem = GetAnchorItemByPicKey(self, self.PicKey)
    self.AnchorItem = AnchorItem
    if self.AnchorOwnerWidget and self.AnchorOwnerWidget.RegOnAnchorItemSelected then
        self.AnchorOwnerWidget:RegOnAnchorItemSelected(self, OnSelectedItem)
    end
    NumbersAreEqual(self)
    ShowAnchorIcon(self, self.PicKey)
    RefreshSingleSelectedAnchorItem(self)
    SetBottomNumVisibility(self)
    RefreshChooseState(self)
end

function WBP_Firm_AnchorIcon:OnListItemObjectSet(ListItemObject)
    self:RefreshAnchorData(ListItemObject)
end

-- function M:Tick(MyGeometry, InDeltaTime)
-- end

return WBP_Firm_AnchorIcon

