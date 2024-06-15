--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@class WBP_Knapsack_Show : WBP_Knapsack_Show_C
---@field Item FBPS_ItemBase

---@type WBP_Knapsack_Show_C
local WBP_Knapsack_Show = UnLua.Class()

local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")
local ItemDef = require("CP0032305_GH.Script.item.ItemDef")
local PicConst = require("CP0032305_GH.Script.common.pic_const")
local ConstText = require("CP0032305_GH.Script.common.text_const")
local PathUtil = require("CP0032305_GH.Script.common.utils.path_util")

local MAT_PARAM_NO_HIDE = 0
local MAT_PARAM_HIDE = 1.6

---@param self WBP_Knapsack_Show
local function ShowUpShadow(self)
    local EffectMaterial = self.RetainerBoxShadow:GetEffectMaterial()
    EffectMaterial:SetScalarParameterValue("Power1", MAT_PARAM_NO_HIDE)
    EffectMaterial:SetScalarParameterValue("Power2", MAT_PARAM_HIDE)
end

---@param self WBP_Knapsack_Show
local function ShowDownShadow(self)
    local EffectMaterial = self.RetainerBoxShadow:GetEffectMaterial()
    EffectMaterial:SetScalarParameterValue("Power1", MAT_PARAM_HIDE)
    EffectMaterial:SetScalarParameterValue("Power2", MAT_PARAM_NO_HIDE)
end

---@param self WBP_Knapsack_Show
local function ShowBothShadow(self)
    local EffectMaterial = self.RetainerBoxShadow:GetEffectMaterial()
    EffectMaterial:SetScalarParameterValue("Power1", MAT_PARAM_HIDE)
    EffectMaterial:SetScalarParameterValue("Power2", MAT_PARAM_HIDE)
end

---@param self WBP_Knapsack_Show
---@param Offset float
local function OnUserScrolled(self, Offset)
    if Offset == 0.0 then
        ShowDownShadow(self)
    elseif math.abs(Offset - self.ScrollBoxShow:GetScrollOffsetOfEnd()) < 1 then
        ShowUpShadow(self)
    else
        ShowBothShadow(self)
    end
end

function WBP_Knapsack_Show:Construct()
    self.ScrollBoxShow.OnUserScrolled:Add(self, OnUserScrolled)
end

function WBP_Knapsack_Show:Destruct()
    self.ScrollBoxShow.OnUserScrolled:Remove(self, OnUserScrolled)
end

---@param TextBlock UTextBlock
---@param TextKey string
local function SetText(TextBlock, TextKey)
    local Text = ConstText.GetConstText(TextKey)
    TextBlock:SetText(Text)
end

---@param self WBP_Knapsack_Show
local function ShowBasic(self)
    local ItemConfig= ItemUtil.GetItemConfigByExcelID(self.Item.ExcelID)
    local QualityConfig = ItemUtil.GetItemQualityConfig(ItemConfig.quality)
    PicConst.SetImageBrush(self.Img_BackgroundQualityBox, QualityConfig.detail_reference)
    PicConst.SetImageBrush(self.Img_PropIcon, ItemConfig.icon_reference)
    SetText(self.Text_PropName, ItemConfig.name)
end

local function GetCategoryName(self)
    local ItemConfig= ItemUtil.GetItemConfigByExcelID(self.Item.ExcelID)
    local ItemCategoryConfig = ItemUtil.GetItemCategoryConfig(ItemConfig.category_ID)
    return ItemCategoryConfig.category_name
end

---@param self WBP_Knapsack_Show
local function ShowTopDefault(self)
    self.Switch_PropDescribe:SetActiveWidgetIndex(3)
    SetText(self.Text_DefaultType, GetCategoryName(self))
    self.Text_DefaultNumber:SetText(self.Item.StackCount)
end

---@param self WBP_Knapsack_Show
local function ShowTopWeapon(self)
    self.Switch_PropDescribe:SetActiveWidgetIndex(0)
    SetText(self.Text_WeaponType, GetCategoryName(self))
    ---todo 后面补充等级、属性、星级的显示
end

---@param self WBP_Knapsack_Show
local function ShowTopEquipment(self)
    self.Switch_PropDescribe:SetActiveWidgetIndex(1)
    SetText(self.Text_EquipType, GetCategoryName(self))
    ---todo 后面补充等级、属性、星级的显示
end

---@param self WBP_Knapsack_Show
local function ShowTopFood(self)
    self.Switch_PropDescribe:SetActiveWidgetIndex(2)
    SetText(self.Text_Food, GetCategoryName(self))
    self.Text_FoodNumber:SetText(self.Item.StackCount)
end

---@param self WBP_Knapsack_Show
local function ShowTop(self)
    local Category = ItemUtil.GetItemCategory(self.Item.ExcelID)
    local ItemCategory = ItemDef.CATEGORY
    if Category == ItemCategory.WEAPON then
        ShowTopWeapon(self)
    elseif Category == ItemCategory.EQUIPMENT then
        ShowTopEquipment(self)
    elseif Category == ItemCategory.FOOD then
        ShowTopFood(self)
    else
        ShowTopDefault(self)
    end
end

---@param self WBP_Knapsack_Show
---@return BP_Tips_WeaponDescription_C
local function CreateTipsWeaponDescriptionItem(self)
    local Path = PathUtil.getFullPathString(self.TipsWeaponDescriptionClass)
    local TipsWeaponDescriptionItemObject = LoadObject(Path)
    return NewObject(TipsWeaponDescriptionItemObject)
end

---@param self WBP_Knapsack_Show
local function ShowWeaponExplanation(self)
    self.Switch_Explanationarea:SetActiveWidgetIndex(0)

    ---todo 下面等有了武器属性，需要填入正式数据
    local Path = PathUtil.getFullPathString(self.TipsWeaponDescriptionClass)
    local TipsWeaponDescriptionItemObject = LoadObject(Path)
    local InListItems = UE.TArray(TipsWeaponDescriptionItemObject)
    for i = 1, 2 do
        local InListItem = CreateTipsWeaponDescriptionItem(self)
        ---todo 需要填入正式数据
        InListItems:Add(InListItem)
    end
    self.List_WeaponDescription:BP_SetListItems(InListItems)
end

---@param self WBP_Knapsack_Show
---@return BP_Tips_EquipmentDescription_C
local function CreateTipsEquipmentDescriptionItem(self)
    local Path = PathUtil.getFullPathString(self.TipsEquipmentDescriptionClass)
    local TipsEquipmentDescriptionItemObject = LoadObject(Path)
    return NewObject(TipsEquipmentDescriptionItemObject)
end

---@param self WBP_Knapsack_Show
---@return BP_Tips_SetEffect_C
local function CreateTipsSetEffectItem(self)
    local Path = PathUtil.getFullPathString(self.TipsSetEffectClass)
    local TipsSetEffectItemObject = LoadObject(Path)
    return NewObject(TipsSetEffectItemObject)
end

---@param self WBP_Knapsack_Show
local function ShowEquipmentExplanation(self)
    self.Switch_Explanationarea:SetActiveWidgetIndex(1)

    ---todo 下面等有了装备属性，需要填入正式数据
    local TipsEquipmentDescriptionPath = PathUtil.getFullPathString(self.TipsEquipmentDescriptionClass)
    local TipsEquipmentDescriptionItemObject = LoadObject(TipsEquipmentDescriptionPath)
    local DescriptionInListItems = UE.TArray(TipsEquipmentDescriptionItemObject)
    for i = 1, 3 do
        local InListItem = CreateTipsEquipmentDescriptionItem(self)
        ---todo 需要填入正式数据
        DescriptionInListItems:Add(InListItem)
    end
    self.List_EquipDescription:BP_SetListItems(DescriptionInListItems)

    ---todo 下面等有了装备属性，需要填入正式数据
    local TipsSetEffectPath = PathUtil.getFullPathString(self.TipsSetEffectClass)
    local TipsSetEffectItemObject = LoadObject(TipsSetEffectPath)
    local EffectInListItems = UE.TArray(TipsSetEffectItemObject)
    for i = 1, 3 do
        local InListItem = CreateTipsSetEffectItem(self)
        ---todo 需要填入正式数据
        EffectInListItems:Add(InListItem)
    end
    self.List_SetEffect:BP_SetListItems(EffectInListItems)
end

---@param self WBP_Knapsack_Show
local function ShowFoodExplanation(self)
    self.Switch_Explanationarea:SetActiveWidgetIndex(2)
    ---todo 需要填入正式数据 RichText_ConsumablesDescription
end

---@param self WBP_Knapsack_Show
local function ShowExplanation(self)
    local Category = ItemUtil.GetItemCategory(self.Item.ExcelID)
    local ItemCategory = ItemDef.CATEGORY
    if Category == ItemCategory.WEAPON then
        self.Switch_Explanationarea:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        ShowWeaponExplanation(self)
    elseif Category == ItemCategory.EQUIPMENT then
        self.Switch_Explanationarea:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        ShowEquipmentExplanation(self)
    elseif Category == ItemCategory.FOOD then
        self.Switch_Explanationarea:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        ShowFoodExplanation(self)
    else
        self.Switch_Explanationarea:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

---@param self WBP_Knapsack_Show
local function ShowDescribe(self)
    local ItemConfig= ItemUtil.GetItemConfigByExcelID(self.Item.ExcelID)
    SetText(self.Text_Describe, ItemConfig.desc_ID)
end

---@param self WBP_Knapsack_Show
---@return BP_Tips_AccessChannel_C
local function CreateTipsAccessChannelItem(self)
    local Path = PathUtil.getFullPathString(self.TipsAccessChannelClass)
    local TipsAccessChannelItemObject = LoadObject(Path)
    return NewObject(TipsAccessChannelItemObject)
end

---@param self WBP_Knapsack_Show
local function ShowAccessChannels(self)
    ---todo 下面等有了获取途径数据，需要填入正式数据
    local Path = PathUtil.getFullPathString(self.TipsAccessChannelClass)
    local TipsAccessChannelItemObject = LoadObject(Path)
    local AccessChannelInListItems = UE.TArray(TipsAccessChannelItemObject)
    for i = 1, 3 do
        local InListItem = CreateTipsAccessChannelItem(self)
        ---todo 需要填入正式数据
        AccessChannelInListItems:Add(InListItem)
    end
    self.List_AccessChannels:BP_SetListItems(AccessChannelInListItems)
end

---@param self WBP_Knapsack_Show
local function ShowBottom(self)
    local Category = ItemUtil.GetItemCategory(self.Item.ExcelID)
    local ItemCategory = ItemDef.CATEGORY
    if Category == ItemCategory.WEAPON then
        self.Cvs_BottomTips:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Switcher_Tips:SetActiveWidgetIndex(0)
        ---todo 后续对接是否装备的数据
    elseif Category == ItemCategory.EQUIPMENT then
        self.Cvs_BottomTips:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Switcher_Tips:SetActiveWidgetIndex(0)
        ---todo 后续对接是否装备的数据
    elseif Category == ItemCategory.FURNITURE then
        self.Cvs_BottomTips:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Switcher_Tips:SetActiveWidgetIndex(1)
        ---todo 后续对接家具是否被摆放的数据
    else
        self.Cvs_BottomTips:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

---@param Item FBPS_ItemBase
function WBP_Knapsack_Show:SetItem(Item)
    self:PlayAnimation(self.DX_Update, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    self.Item = Item
    ShowBasic(self)
    ShowTop(self)
    ShowExplanation(self)
    ShowDescribe(self)
    ShowAccessChannels(self)
    ShowBottom(self)
end

return WBP_Knapsack_Show
