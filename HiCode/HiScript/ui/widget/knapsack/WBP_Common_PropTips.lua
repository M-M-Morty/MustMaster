--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local ItemUtil = require("common.item.ItemUtil")
local ItemDef = require("common.item.ItemDef")
local PicConst = require("CP0032305_GH.Script.common.pic_const")
local ConstText = require("CP0032305_GH.Script.common.text_const")
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')

---@class WBP_Common_PropTips : WBP_Common_PropTips_C
---@field ItemExcelID integer
---@field ItemConfig ItemConfig

---@type WBP_Common_PropTips_C
local WBP_Common_PropTips = Class(UIWindowBase)

---@param self WBP_Common_PropTips
local function OnClickBg(self)
    UIManager:CloseUI(self, true)
end

function WBP_Common_PropTips:Construct()
    self.WBP_Common_BG_02.ButtonBg.OnClicked:Add(self, OnClickBg)
end

function WBP_Common_PropTips:Destruct()
    self.WBP_Common_BG_02.ButtonBg.OnClicked:Remove(self, OnClickBg)
end

function WBP_Common_PropTips:OnShow()
    self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end

---@param self WBP_Common_PropTips
local function ShowItemName(self)
    local Name = ConstText.GetConstText(self.ItemConfig.name)
    self.Text_PropTipsName:SetText(Name)
end

---@param self WBP_Common_PropTips
local function ShowItemIcon(self)
    PicConst.SetImageBrush(self.Img_PropTipsIcon, self.ItemConfig.icon_reference)
end

---@param self WBP_Common_PropTips
local function ShowQualityBg(self)
    local QualityConfig = ItemUtil.GetItemQualityConfig(self.ItemConfig.quality)
    PicConst.SetImageBrush(self.Img_QualityBoxPropTips, QualityConfig.tips_bg_reference)
end

---@param self WBP_Common_PropTips
local function ShowCurrencyCount(self)
    local ItemManager = ItemUtil.GetItemManager(self)
    local Count = ItemManager:GetItemCountByExcelID(self.ItemExcelID)
    self.Text_TipsCurrencyNumber:SetText(Count)
end

---@param self WBP_Common_PropTips
local function ShowCurrencyContent(self)
    local Desc = ConstText.GetConstText(self.ItemConfig.desc_ID)
    self.Text_TipsCurrencyIllustrate:SetText(Desc)
end

---@param self WBP_Common_PropTips
local function ShowCurrencyTips(self)
    self.Switch_PropTipsDescribe:SetActiveWidgetIndex(0)
    self.Switcher_TipsContent:SetActiveWidgetIndex(0)
    ShowItemIcon(self)
    ShowItemName(self)
    ShowQualityBg(self)
    ShowCurrencyCount(self)
    ShowCurrencyContent(self)
end

---@param self WBP_Common_PropTips
local function ShowRewardCount(self, Number)
    self.Text_TipsCurrencyNumber:SetText(Number)
end

local function SetRewardTipsData(self, Number)
    self.Switch_PropTipsDescribe:SetActiveWidgetIndex(0)
    self.Switcher_TipsContent:SetActiveWidgetIndex(0)
    ShowItemIcon(self)
    ShowItemName(self)
    ShowQualityBg(self)
    ShowRewardCount(self, Number)
    ShowCurrencyContent(self)
end

---@param ExcelID integer
function WBP_Common_PropTips:SetRewardTipsByExcelID(ExcelID, Number)
    self.ItemExcelID = ExcelID
    local ItemConfig = ItemUtil.GetItemConfigByExcelID(ExcelID)
    self.ItemConfig = ItemConfig
    SetRewardTipsData(self, Number)
end

---@param ExcelID integer
function WBP_Common_PropTips:InitByItemExcelID(ExcelID)
    self.ItemExcelID = ExcelID
    local ItemConfig = ItemUtil.GetItemConfigByExcelID(ExcelID)
    self.ItemConfig = ItemConfig
    if ItemConfig.category_ID == ItemDef.CATEGORY.CURRENCY then
        ShowCurrencyTips(self, ItemConfig)
    elseif ItemConfig.category_ID == ItemDef.CATEGORY.WEAPON then
    elseif ItemConfig.category_ID == ItemDef.CATEGORY.EQUIPMENT then
    elseif ItemConfig.category_ID == ItemDef.CATEGORY.CONSUMABLE or ItemConfig.category_ID == ItemDef.CATEGORY.FOOD then
    else
    end
end

return WBP_Common_PropTips
