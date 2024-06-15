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
local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")

---@class WBP_Knapsack_UsePopup : WBP_Knapsack_UsePopup_C
---@field Item FBPS_ItemBase
---@field UseCount integer

---@type WBP_Knapsack_UsePopup_C
local WBP_Knapsack_UsePopup = Class(UIWindowBase)

--function M:Initialize(Initializer)
--end

--function M:PreConstruct(IsDesignTime)
--end

---@param self WBP_Knapsack_UsePopup
local function OnClickCloseButton(self)
    UIManager:CloseUI(self, true)
end

---@param self WBP_Knapsack_UsePopup
local function OnClickConfirmButton(self)
    local ItemManager = ItemUtil.GetItemManager(self)
    ItemManager:Server_UseItemByExcelID(self.Item.ExcelID, self.UseCount, 0)
    UIManager:CloseUI(self, true)
end

---@param self WBP_Knapsack_UsePopup
---@param Value integer
local function OnValueChanged(self, Value)
    self.UseCount = Value
    self.Text_Number:SetText(Value)
end

---@param Item FBPS_ItemBase
function WBP_Knapsack_UsePopup:UseItem(Item)
    self.Item = Item
    local Max = Item.StackCount
    local Min = 0
    local Step = 1
    self.WBP_Common_Number:InitData(Min, Max, Step)
    self.Text_Total:SetText(Max)
    self.UseCount = self.WBP_Common_Number:GetValue()
    self.Text_Number:SetText(self.UseCount)
end

function WBP_Knapsack_UsePopup:Construct()
    self.WBP_Common_Popup_Medium.WBP_MedPopupClose.OnClicked:Add(self, OnClickCloseButton)
    self.WBP_ComBtn_MedDefine.OnClicked:Add(self, OnClickConfirmButton)
    self.WBP_Common_Number.OnValueChanged:Add(self, OnValueChanged)
end

function WBP_Knapsack_UsePopup:OnShow()
    self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    ---@type WBP_Common_Popup_Medium
    local WBP_Common_Popup_Medium = self.WBP_Common_Popup_Medium
    WBP_Common_Popup_Medium:PlayInAnim()
    self:RefreshHeadIcons()
end

function WBP_Knapsack_UsePopup:Destruct()
    self.WBP_Common_Popup_Medium.WBP_MedPopupClose.OnClicked:Remove(self, OnClickCloseButton)
    self.WBP_ComBtn_MedDefine.OnClicked:Remove(self, OnClickConfirmButton)
    self.WBP_Common_Number.OnValueChanged:Remove(self, OnValueChanged)
end

local function MockRoleDatas(self)
    local Path = PathUtil.getFullPathString(self.UsePropRoleItemClass)
    local UsePropRoleItemObject = LoadObject(Path)
    return NewObject(UsePropRoleItemObject)
end

function WBP_Knapsack_UsePopup:RefreshHeadIcons()
    local Path = PathUtil.getFullPathString(self.UsePropRoleItemClass)
    local UsePropRoleItemObject = LoadObject(Path)
    local InListItems = UE.TArray(UsePropRoleItemObject)
    for i = 1, 4 do
        InListItems:Add(MockRoleDatas(self))
    end
    self.ListView_Role:BP_SetListItems(InListItems)
end

---Called when an animation is started.
---@param Animation UWidgetAnimation
---@return void
function WBP_Knapsack_UsePopup:OnAnimationStarted(Animation)
    if Animation == self.DX_Out then
        ---@type WBP_Common_Popup_Medium
        local WBP_Common_Popup_Medium = self.WBP_Common_Popup_Medium
        WBP_Common_Popup_Medium:PlayOutAnim()
    end
end

--function M:Tick(MyGeometry, InDeltaTime)
--end

return WBP_Knapsack_UsePopup
