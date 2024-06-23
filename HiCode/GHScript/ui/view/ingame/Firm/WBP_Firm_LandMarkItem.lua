--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
---@class WBP_Firm_LandMarkItem : WBP_Firm_LandMarkItem_C
---@field bIsChecked boolean
---@field LandMarkerName string
---@field MarkerPos FVector2D
---@field OwnerWidget WBP_Firm_SidePopupWindow
---@type WBP_Firm_LandMarkItem_C
local WBP_Firm_LandMarkItem = UnLua.Class()

-- function M:Initialize(Initializer)
-- end

-- function M:PreConstruct(IsDesignTime)
-- end

---@param self WBP_Firm_LandMarkItem
---@param bIsCheck boolean
local function RefreshCheckState(self, bIsCheck)
    self.bIsChecked = bIsCheck
end

---@param self WBP_Firm_LandMarkItem
local function RefreshCheckBoxVisible(self)
    local IsClicked = not self.bIsChecked
    self.ListItemObject.bIsChecked = IsClicked
    RefreshCheckState(self, IsClicked)
    if IsClicked then
        self.Switch_AnchorList_State:SetActiveWidgetIndex(1)
        self.WBP_ComBtn_CheckBox.Switch_CheckBox:SetActiveWidgetIndex(0)
        self.WBP_ComBtn_CheckBox.Switch_Check:SetActiveWidgetIndex(0)
    else
        self.WBP_ComBtn_CheckBox.Switch_CheckBox:SetActiveWidgetIndex(1)
        self.Switch_AnchorList_State:SetActiveWidgetIndex(0)
        self.WBP_ComBtn_CheckBox.Switch_Check:SetActiveWidgetIndex(1)
    end
end

---@param self WBP_Firm_LandMarkItem
local function OnClickedCheck(self)
    if self.OwnerWidget.OnClickedCheck then
        RefreshCheckBoxVisible(self)
        self.OwnerWidget:OnClickedCheck(self.bIsChecked, self.Key,false)
        --self:PlayAnimation(self.DX_Focus, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    end
end

---@param self WBP_Firm_LandMarkItem
local function OnClickedLeftBtn(self)
    self.OwnerWidget:OnClickedCheck(self.bIsChecked, self.Key,true)
end

-- function M:Tick(MyGeometry, InDeltaTime)
-- end
---@param self WBP_Firm_LandMarkItem
local function SetLandMarkerItemInfo(self)
    self.Text_LandMarkname:SetText(self.LandMarkerName)
    self.Txt_UseNumber:SetText(tostring(string.format("%.3f", self.MarkerPos.X)) .. "," .. tostring(string.format("%.3f", self.MarkerPos.Y)))
end

---@param self WBP_Firm_LandMarkItem
local function RefreshCheckBox(self)
    if self.bIsChecked == false then
        self.Switch_AnchorList_State:SetActiveWidgetIndex(0)
        --self.WBP_ComBtn_CheckBox.Canvas_CheckBox_Normal:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.WBP_ComBtn_CheckBox.Switch_Check:SetActiveWidgetIndex(1)
        self.WBP_ComBtn_CheckBox.Switch_CheckBox:SetActiveWidgetIndex(1)
    else
        self.Switch_AnchorList_State:SetActiveWidgetIndex(1)
        self.WBP_ComBtn_CheckBox.Switch_Check:SetActiveWidgetIndex(0)
        self.WBP_ComBtn_CheckBox.Switch_CheckBox:SetActiveWidgetIndex(0)
        --[[self.WBP_ComBtn_CheckBox.Canvas_CheckBox_Normal:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.WBP_ComBtn_CheckBox.Canvas_CheckBox_Select:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)]]
    end
end

---@param FirmLandMarkItemData BP_FirmLandMarkItemObject_C
function WBP_Firm_LandMarkItem:RefreshLandMarkData(FirmLandMarkItemData)
    self.LandMarkerName = FirmLandMarkItemData.MarkerName
    self.MarkerPos = FirmLandMarkItemData.Position
    self.OwnerWidget = FirmLandMarkItemData.OwnerWidget
    self.bIsChecked = FirmLandMarkItemData.bIsChecked
    self.Key = FirmLandMarkItemData.Key
    SetLandMarkerItemInfo(self)
    RefreshCheckBox(self)
end

function WBP_Firm_LandMarkItem:Construct()
    self.WBP_CommonButton.OnClicked:Add(self, OnClickedLeftBtn)
    self.WBP_ComBtn_CheckBox.WBP_Btn_CheckBox.OnClicked:Add(self, OnClickedCheck)
end

function WBP_Firm_LandMarkItem:Destruct()
    self.WBP_CommonButton.OnClicked:Remove(self, OnClickedLeftBtn)
    self.WBP_ComBtn_CheckBox.WBP_Btn_CheckBox.OnClicked:Remove(self, OnClickedCheck)
end

function WBP_Firm_LandMarkItem:OnListItemObjectSet(ListItemObject)
    self.ListItemObject = ListItemObject
    self:RefreshLandMarkData(ListItemObject)
    ListItemObject.OwnerWidget:SetLandMarkItemsWidgets(ListItemObject.Index, self)
    

end

return WBP_Firm_LandMarkItem