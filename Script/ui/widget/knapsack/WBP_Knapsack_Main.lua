--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@alias ItemSelectedCallBackT fun(Owner:UObject, Item:FBPS_ItemBase)

local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local PathUtil = require("CP0032305_GH.Script.common.utils.path_util")
local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")
local ItemDef = require("CP0032305_GH.Script.item.ItemDef")
local ConstText = require("CP0032305_GH.Script.common.text_const")
local TipsUtil = require("CP0032305_GH.Script.common.utils.tips_util")

---@class WBP_Knapsack_Main : WBP_Knapsack_Main_C
---@field OldTabIndex integer
---@field TabIndex integer
---@field CurrentSelectedItemUniqueID integer
---@field ItemSelectedCallBacks table<UObject, ItemSelectedCallBackT>
---@field TabDatas CommonTabData[]
---@field ItemCount integer
---@field NeedSelectExcelID integer

---@type WBP_Knapsack_Main_C
local WBP_Knapsack_Main = Class(UIWindowBase)

---@type CurrencyData[]
local CurrencyDatas = {
    {ExcelID = 100001, bShowAddButton = true},
    {ExcelID = 100002, bShowAddButton = false},
}
local ITEM_USE_CD_MSG = "ITEM_USE_CD"

---@param self WBP_Knapsack_Main
---@return BP_ItemManager
local function GetItemManager(self)
    return ItemUtil.GetItemManager(self)
end

---@param self WBP_Knapsack_Main
local function OnClickCloseButton(self)
    UIManager:CloseUI(self)
end

---@param self WBP_Knapsack_Main
local function SetCurrencyType(self)
    self.WBP_Common_Currency:SetCurrencyDatas(CurrencyDatas)
end

---@param self WBP_Knapsack_Show
local function ShowUpShadow(self)
    local EffectMaterial = self.RetainerBoxPropList:GetEffectMaterial()
    EffectMaterial:SetScalarParameterValue("Power1", 0)
    EffectMaterial:SetScalarParameterValue("Power2", 1.6)
end

---@param self WBP_Knapsack_Show
local function ShowDownShadow(self)
    local EffectMaterial = self.RetainerBoxPropList:GetEffectMaterial()
    EffectMaterial:SetScalarParameterValue("Power1", 1.6)
    EffectMaterial:SetScalarParameterValue("Power2", 0)
end

---@param self WBP_Knapsack_Show
local function ShowBothShadow(self)
    local EffectMaterial = self.RetainerBoxPropList:GetEffectMaterial()
    EffectMaterial:SetScalarParameterValue("Power1", 1.6)
    EffectMaterial:SetScalarParameterValue("Power2", 1.6)
end

---@param self WBP_Knapsack_Show
local function ShowNoShadow(self)
    local EffectMaterial = self.RetainerBoxPropList:GetEffectMaterial()
    EffectMaterial:SetScalarParameterValue("Power1", 0)
    EffectMaterial:SetScalarParameterValue("Power2", 0)
end

---@param self WBP_Knapsack_Main
local function RefreshTab(self)
    local BagConfigs = ItemUtil.GetAllBagTabConfigs()
    local ItemManager = GetItemManager(self)
    self.TabDatas = {}
    for TabIndex, BagConfig in pairs(BagConfigs) do
        if BagConfig.tab_switch then
            ---@type CommonTabData
            local TabData = {}
            TabData.TabIndex = TabIndex
            TabData.PidKey = BagConfig.tab_icon
            TabData.NameKey = BagConfig.tab_name
            TabData.bHasRedDot = self.TabIndex ~= TabIndex and ItemManager:IsTabRedFlag(TabIndex)

            if self.TabIndex == TabIndex then
                TabData.bHasRedDot = false
            else
                TabData.bHasRedDot = ItemManager:IsTabRedFlag(TabIndex)
            end
            table.insert(self.TabDatas, TabData)
        end
    end
    table.sort(self.TabDatas, function(ItemA, ItemB) return ItemA.TabIndex < ItemB.TabIndex end)
    self.WBP_Common_Tab:SetDatas(self.TabDatas, self.TabIndex)
    self:PlayAnimation(self.DX_ChangeTab, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    self.WBP_Common_Tab.List_CommonTab:ScrollIndexIntoView(self.TabIndex)
end

---@param self WBP_Knapsack_Main
---@return BP_CommonBigPropItemObject_C
local function NewItemObject(self)
    local Path = PathUtil.getFullPathString(self.CommonBigPropItemClass)
    local CommonCurrencyItemObject = LoadObject(Path)
    return NewObject(CommonCurrencyItemObject)
end

---@param self WBP_Knapsack_Main
local function ResetShadowAndScrollBar(self)
    local ListGeometry = self.Tile_PropList:GetCachedGeometry()
    local ListLocalSize = UE.USlateBlueprintLibrary.GetLocalSize(ListGeometry)
    local EntryHeight = self.Tile_PropList:GetEntryHeight()
    local EntryWidth = self.Tile_PropList:GetEntryWidth()
    local ColumnCount = math.floor(ListLocalSize.X / EntryWidth)
    local RowCount = math.floor(ListLocalSize.Y / EntryHeight)

    if ColumnCount * RowCount  >= self.ItemCount then
        ShowNoShadow(self)
        self.Tile_PropList:SetScrollbarVisibility(UE.ESlateVisibility.Hidden)
    else
        ShowDownShadow(self)
        self.Tile_PropList:SetScrollbarVisibility(UE.ESlateVisibility.Visible)
    end
end

---@param self WBP_Knapsack_Main
local function RefreshTabItems(self)
    local ItemManager = GetItemManager(self)
    local Items = ItemManager:GetItemsByTabID(self.TabIndex)
    if #Items == 0 then
        self.CurrentSelectedItemUniqueID = nil
        self.Tile_PropList:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.WBP_Common_BG_emptyState:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        return
    end
    table.sort(Items, ItemUtil.ItemSortFunction)
    self.WBP_Common_BG_emptyState:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Tile_PropList:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local Path = PathUtil.getFullPathString(self.CommonBigPropItemClass)
    local CommonItemObject = LoadObject(Path)
    local InListItems = UE.TArray(CommonItemObject)
    for i, Item in ipairs(Items) do
        if i == 1 then
            self.CurrentSelectedItemUniqueID = Item.UniqueID
        end
        if self.NeedSelectExcelID then
            if self.NeedSelectExcelID == Item.ExcelID then
                self.CurrentSelectedItemUniqueID = Item.UniqueID
                self.NeedSelectExcelID = nil
            end
        end
        local ItemObject = NewItemObject(self)
        ItemObject.UniqueID = Item.UniqueID
        ItemObject.OwnerWidget = self
        InListItems:Add(ItemObject)
    end
    self.ItemCount = InListItems:Length()
    self.Tile_PropList:BP_SetListItems(InListItems)
    self.Tile_PropList:ScrollIndexIntoView(1)

    ResetShadowAndScrollBar(self)
end

---@param self WBP_Knapsack_Main
local function RefreshItemContent(self)
    if not self.CurrentSelectedItemUniqueID then
        self.WBP_Knapsack_Show:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.WBP_ComBtn_Firset_Emphasize:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    self.WBP_Knapsack_Show:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local ItemManager = ItemUtil.GetItemManager(self)
    local CurrentSelectedItem = ItemManager:GetItemByUniqueID(self.CurrentSelectedItemUniqueID)
    self.WBP_Knapsack_Show:SetItem(CurrentSelectedItem)

    local ItemConfig = ItemUtil.GetItemConfigByExcelID(CurrentSelectedItem.ExcelID)
    local Category = ItemConfig.category_ID
    if Category == ItemDef.CATEGORY.CONSUMABLE or Category == ItemDef.CATEGORY.FOOD then
        self.WBP_ComBtn_Firset_Emphasize:SetVisibility(UE.ESlateVisibility.Visible)
        self.WidgetSwitcherButtonName:SetActiveWidgetIndex(0)
    elseif Category == ItemDef.CATEGORY.TASK_ITEM then
        if ItemConfig.task_item_display_type == ItemDef.TASK_ITEM_DISPLAY_TYPE.TEXT then
            self.WBP_ComBtn_Firset_Emphasize:SetVisibility(UE.ESlateVisibility.Visible)
            self.WidgetSwitcherButtonName:SetActiveWidgetIndex(1)
        elseif ItemConfig.task_item_display_type == ItemDef.TASK_ITEM_DISPLAY_TYPE.PICTURE then
            self.WBP_ComBtn_Firset_Emphasize:SetVisibility(UE.ESlateVisibility.Visible)
            self.WidgetSwitcherButtonName:SetActiveWidgetIndex(1)
        else
            self.WBP_ComBtn_Firset_Emphasize:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    elseif Category == ItemDef.CATEGORY.EQUIPMENT then
        self.WBP_ComBtn_Firset_Emphasize:SetVisibility(UE.ESlateVisibility.Visible)
        self.WidgetSwitcherButtonName:SetActiveWidgetIndex(2)
    elseif Category == ItemDef.CATEGORY.WEAPON then
        self.WBP_ComBtn_Firset_Emphasize:SetVisibility(UE.ESlateVisibility.Visible)
        self.WidgetSwitcherButtonName:SetActiveWidgetIndex(2)
    else
        self.WBP_ComBtn_Firset_Emphasize:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

local function RefreshBagCapacity(self)
    local ItemManager = GetItemManager(self)
    local Count, Capacity = ItemManager:GetCapacityByTabID(self.TabIndex)
    if Count > 0 then
        self.Cvs_Capacity:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        self.Text_PropNumber:SetText(Count)
        self.Text_PropTotal:SetText(Capacity)
    else
        self.Cvs_Capacity:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

---@param self WBP_Knapsack_Main
local function RefreshTabName(self)
    local TabData = self.TabDatas[self.TabIndex]
    local Name = ConstText.GetConstText(TabData.NameKey)
    self.WBP_Common_TopContent.Text_Item2:SetText(Name)
    self.Text_PropName:SetText(Name)
end

---@param self WBP_Knapsack_Main
---@param Index integer
local function OnTabChanged(self, Index)
    if self.TabIndex == Index then
        return
    end
    self.OldTabIndex = self.TabIndex
    self.TabIndex = Index
    local ItemManager = GetItemManager(self)
    ItemManager:ChangeBagTab(self.OldTabIndex, self.TabIndex)
    if self.OldTabIndex ~= nil and self.OldTabIndex > 0 then
        self.WBP_Common_Tab:ChangeRedDot(self.OldTabIndex, false)
    end
    self.WBP_Common_Tab:ChangeRedDot(Index, false)
    RefreshTabName(self)
    RefreshBagCapacity(self)
    RefreshTabItems(self)
    RefreshItemContent(self)
end

function WBP_Knapsack_Main:OnShowNextTick()
    ResetShadowAndScrollBar(self)
end

---@param self WBP_Knapsack_Main
---@param TabIndex integer
local function OnBagCapacityChanged(self, TabIndex)
    if self.TabIndex == TabIndex then
        RefreshBagCapacity(self)
    end
end

---@param self WBP_Knapsack_Main
---@param Item FBPS_ItemBase
local function OnAddItem(self, Item)
    local TabIndex = ItemUtil.GetItemTabIndex(Item.ExcelID)
    if self.TabIndex == TabIndex then
        RefreshBagCapacity(self)
        RefreshTabItems(self)
        RefreshItemContent(self)
    end

    local bHasRedDot = GetItemManager(self):IsTabRedFlag(TabIndex)
    if bHasRedDot then
        self.WBP_Common_Tab:ChangeRedDot(TabIndex, bHasRedDot)
    end
end

---@param self WBP_Knapsack_Main
---@param ExcelID integer
local function OnRemoveItem(self, _, ExcelID, _)
    local TabIndex = ItemUtil.GetItemTabIndex(ExcelID)
    if self.TabIndex == TabIndex then
        RefreshBagCapacity(self)
        RefreshTabItems(self)
        RefreshItemContent(self)
    end

    local bHasRedDot = GetItemManager(self):IsTabRedFlag(TabIndex)
    self.WBP_Common_Tab:ChangeRedDot(TabIndex, bHasRedDot)
end

---@param self WBP_Knapsack_Main
---@param Item FBPS_ItemBase
local function OnUpdateItem(self, Item)
    if self.CurrentSelectedItemUniqueID == Item.UniqueID then
        RefreshItemContent(self)
    end
end

---@param self WBP_Knapsack_Main
---@param TabIndex integer
local function OnTabNewRedDot(self, TabIndex)
    self.WBP_Common_Tab:ChangeRedDot(TabIndex, true)
end

---@param self WBP_Knapsack_Main
local function OnClickDetailButton(self)
    local ItemManager = ItemUtil.GetItemManager(self)
    local CurrentSelectedItem = ItemManager:GetItemByUniqueID(self.CurrentSelectedItemUniqueID)
    local ItemConfig = ItemUtil.GetItemConfigByExcelID(CurrentSelectedItem.ExcelID)

    if CurrentSelectedItem.bNew then
        if ItemConfig.disappear_rule == nil
                or ItemConfig.disappear_rule == ItemDef.NEW_DISAPPEAR_RULE.LEAVE_TAB
                or ItemConfig.disappear_rule == ItemDef.NEW_DISAPPEAR_RULE.CLICK_ITEM
                or ItemConfig.disappear_rule == ItemDef.NEW_DISAPPEAR_RULE.CLICK_DETAIL_BUTTON then
            local ItemManager = GetItemManager(self)
            ItemManager:SetItemsNotNewByItemID(CurrentSelectedItem.UniqueID)
        end
    end

    local Category = ItemConfig.category_ID
    if Category == ItemDef.CATEGORY.CONSUMABLE or Category == ItemDef.CATEGORY.FOOD then
        if ItemManager:GetItemUseCD(CurrentSelectedItem.ExcelID) > 0 then
            TipsUtil.ShowCommonTips(ITEM_USE_CD_MSG)
            return
        end
        ---@type WBP_Knapsack_UsePopup
        local SecondConfirmWidget = UIManager:OpenUI(UIDef.UIInfo.UI_Knapsack_UsePopup_Main)
        local Item = ItemManager:GetItemByUniqueID(self.CurrentSelectedItemUniqueID)
        SecondConfirmWidget:UseItem(Item)
    elseif Category == ItemDef.CATEGORY.TASK_ITEM then
        if ItemConfig.task_item_display_type == ItemDef.TASK_ITEM_DISPLAY_TYPE.TEXT then
            ---@type WBP_Knapsack_ViewText
            local WBPText = UIManager:OpenUI(UIDef.UIInfo.UI_Knapsack_ViewText)
            WBPText:SetTexts(ItemConfig.task_item_details)
        elseif ItemConfig.task_item_display_type == ItemDef.TASK_ITEM_DISPLAY_TYPE.PICTURE then
            ---@type WBP_Knapsack_ViewImg
            local WBPImg = UIManager:OpenUI(UIDef.UIInfo.UI_Knapsack_ViewImg)
            WBPImg:SetImages(ItemConfig.task_item_details)
        end
    elseif Category == ItemDef.CATEGORY.EQUIPMENT then
    elseif Category == ItemDef.CATEGORY.WEAPON then
    end
end

---@param self WBP_Knapsack_Main
---@param OffsetInitems float
---@param DistanceRemaining float
local function OnListViewScrolled(self, OffsetInitems, DistanceRemaining)
    local ListGeometry = self.Tile_PropList:GetCachedGeometry()
    local ListLocalSize = UE.USlateBlueprintLibrary.GetLocalSize(ListGeometry)
    local EntryHeight = self.Tile_PropList:GetEntryHeight()
    local EntryWidth = self.Tile_PropList:GetEntryWidth()

    if OffsetInitems <= 0.1 then
        ShowDownShadow(self)
    else
        local ColumnCount = math.floor(ListLocalSize.X / EntryWidth)
        local Row = math.ceil(self.ItemCount * 1.0 / ColumnCount)
        local Delta = EntryHeight / ColumnCount * OffsetInitems + ListLocalSize.Y - EntryHeight * Row
        local DeltaAbs = math.abs(Delta)
        if Delta > 0 or DeltaAbs <= 0.1 then
            ShowUpShadow(self)
        else
            ShowBothShadow(self)
        end
    end
end

function WBP_Knapsack_Main:OnShow()
    self.WBP_Common_TopContent.CommonButton_Close.OnClicked:Add(self, OnClickCloseButton)
    self.WBP_ComBtn_Firset_Emphasize.OnClicked:Add(self, OnClickDetailButton)
    self.Tile_PropList.BP_OnListViewScrolled:Add(self, OnListViewScrolled)

    self.ItemSelectedCallBacks = {}
    self.TabIndex = 1
    self.ItemCount = 0
    self.WBP_Common_Tab:RegOnSelectTab(self, OnTabChanged)

    local ItemManager = GetItemManager(self)
    ItemManager:RegBagCapacityChangeCallBack(self, OnBagCapacityChanged)
    ItemManager:RegAddItemCallBack(self, OnAddItem)
    ItemManager:RegRemoveItemCallBack(self, OnRemoveItem)
    ItemManager:RegUpdateItemCallBack(self, OnUpdateItem)
    ItemManager:RegTabNewRedDotCallBack(self, OnTabNewRedDot)

    self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    ---@type WBP_Common_Currency
    local WBP_Common_Currency = self.WBP_Common_Currency
    WBP_Common_Currency:PlayInAnim()
    ---@type WBP_Common_BG_emptyState
    local WBP_Common_BG_emptyState = self.WBP_Common_BG_emptyState
    WBP_Common_BG_emptyState:PlayInAnim()

    SetCurrencyType(self)
    RefreshTab(self)
    RefreshTabName(self)
    RefreshBagCapacity(self)
    RefreshTabItems(self)
    RefreshItemContent(self)
    UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, self.OnShowNextTick }, 0.2, false)
    self.WBP_Common_Tab:RegisterKeyEvent()
end

function WBP_Knapsack_Main:OnHide()
    local ItemManager = GetItemManager(self)
    ItemManager:ChangeBagTab(self.TabIndex, -1)
    self.WBP_Common_Tab:UnRegisterKeyEvent()

    self.WBP_Common_TopContent.CommonButton_Close.OnClicked:Remove(self, OnClickCloseButton)
    self.WBP_ComBtn_Firset_Emphasize.OnClicked:Remove(self, OnClickDetailButton)
    self.Tile_PropList.BP_OnListViewScrolled:Remove(self, OnListViewScrolled)

    self.WBP_Common_Tab:UnRegOnSelectTab(self, OnTabChanged)

    ItemManager:UnRegBagCapacityChangeCallBack(self, OnBagCapacityChanged)
    ItemManager:UnRegAddItemCallBack(self, OnAddItem)
    ItemManager:UnRegRemoveItemCallBack(self, OnRemoveItem)
    ItemManager:UnRegUpdateItemCallBack(self, OnUpdateItem)
    ItemManager:UnRegTabNewRedDotCallBack(self, OnTabNewRedDot)
end

---@param Item FBPS_ItemBase
function WBP_Knapsack_Main:OnClickItem(Item)
    self.CurrentSelectedItemUniqueID = Item.UniqueID

    for Owner, CB in pairs(self.ItemSelectedCallBacks) do
        CB(Owner, Item)
    end

    RefreshItemContent(self)
    if Item.bNew then
        local ItemConfig = ItemUtil.GetItemConfigByExcelID(Item.ExcelID)
        if ItemConfig.disappear_rule == nil
                or ItemConfig.disappear_rule == ItemDef.NEW_DISAPPEAR_RULE.LEAVE_TAB
                or ItemConfig.disappear_rule == ItemDef.NEW_DISAPPEAR_RULE.CLICK_ITEM then
            local ItemManager = GetItemManager(self)
            ItemManager:SetItemsNotNewByItemID(Item.UniqueID)
        end
    end
end

---@param ExcelID integer
function WBP_Knapsack_Main:ChooseItemByExcelID(ExcelID)
    local TabIndex = ItemUtil.GetItemTabIndex(ExcelID)
    self.NeedSelectExcelID = ExcelID
    self.WBP_Common_Tab:SelectTab(TabIndex)
end

---@param Owner UObject
---@param ItemSelectedCallBack ItemSelectedCallBackT
function WBP_Knapsack_Main:RegOnItemSelected(Owner, ItemSelectedCallBack)
    self.ItemSelectedCallBacks[Owner] = ItemSelectedCallBack
end

---@param Owner UObject
---@param ItemSelectedCallBack ItemSelectedCallBackT
function WBP_Knapsack_Main:UnRegOnItemSelected(Owner, ItemSelectedCallBack)
    self.ItemSelectedCallBacks[Owner] = nil
end

function WBP_Knapsack_Main:OnAnimationStarted(Animation)
    if Animation == self.DX_Out then
        ---@type WBP_Common_Currency
        local WBP_Common_Currency = self.WBP_Common_Currency
        WBP_Common_Currency:PlayOutAnim()
        ---@type WBP_Common_BG_emptyState
        local WBP_Common_BG_emptyState = self.WBP_Common_BG_emptyState
        WBP_Common_BG_emptyState:PlayOutAnim()
    end
end

return WBP_Knapsack_Main
