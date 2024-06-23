--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@class WBP_Common_Currency_Item : WBP_Common_Currency_Item_C
---@field ExcelID integer
---@field bShowAddButton boolean

---@type WBP_Common_Currency_Item_C
local WBP_Common_Currency_Item = UnLua.Class()

local G = require("G")
local UIConst = require("CP0032305_GH.Script.common.ui_const")
local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")
local PicConst = require("CP0032305_GH.Script.common.pic_const")
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')

local CONST_NUM = 99999

---@param self WBP_Common_Currency_Item
local function OnClickButtonLeft(self)
    ---@type WBP_Common_PropTips
    local WBPCommonPropTips = UIManager:OpenUI(UIDef.UIInfo.UI_Common_PropTips_Main)
    WBPCommonPropTips:InitByItemExcelID(self.ExcelID)
end

---@param self WBP_Common_Currency_Item
local function OnClickButtonRight(self)
    G.log:debug("WBP_Common_Currency_Item", "OnClickButtonRight TabIndex %d, %s", self.ExcelID, self.bShowAddButton)
end

---@param self WBP_Common_Currency_Item
local function Refresh(self)
    if self.bShowAddButton then
        self.CommonButtonRight:SetVisibility(UE.ESlateVisibility.Visible)
    else
        self.CommonButtonRight:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    local ItemManager = ItemUtil.GetItemManager(self)
    local ItemConfig = ItemUtil.GetItemConfigByExcelID(self.ExcelID)
    PicConst.SetImageBrush(self.ImgCurrencyIcon, ItemConfig.mini_icon_reference)

    local CurrencyCount = ItemManager:GetItemCountByExcelID(self.ExcelID)
    if CurrencyCount > CONST_NUM then
        CurrencyCount = tostring(math.floor(CurrencyCount/1000)) ..UIConst.Thousand
    end

    self.TextNumber:SetText(CurrencyCount)
end

---@param self WBP_Common_Currency_Item
---@param Item FBPS_ItemBase
local function OnItemAdd(self, Item)
    if Item.ExcelID == self.ExcelID then
        Refresh(self)
    end
end

local function OnItemRemove(self, _, ExcelID, _)
    if ExcelID == self.ExcelID then
        Refresh(self)
    end
end

local function OnItemUpdate(self, Item)
    if Item.ExcelID == self.ExcelID then
        Refresh(self)
    end
end

function WBP_Common_Currency_Item:Construct()
    self.ButtonLeft.OnClicked:Add(self, OnClickButtonLeft)
    self.CommonButtonRight.OnClicked:Add(self, OnClickButtonRight)
    local ItemManager = ItemUtil.GetItemManager(self)
    ItemManager:RegAddItemCallBack(self, OnItemAdd)
    ItemManager:RegRemoveItemCallBack(self, OnItemRemove)
    ItemManager:RegUpdateItemCallBack(self, OnItemUpdate)
end

function WBP_Common_Currency_Item:Destruct()
    self.ButtonLeft.OnClicked:Remove(self, OnClickButtonLeft)
    self.CommonButtonRight.OnClicked:Remove(self, OnClickButtonRight)
    local ItemManager = ItemUtil.GetItemManager(self)
    ItemManager:UnRegAddItemCallBack(self, OnItemAdd)
    ItemManager:UnRegRemoveItemCallBack(self, OnItemRemove)
    ItemManager:UnRegUpdateItemCallBack(self, OnItemUpdate)
end

---@param ExcelID integer
---@param bShowAddButton boolean
function WBP_Common_Currency_Item:SetCurrencyItemExcelID(ExcelID, bShowAddButton)
    self.ExcelID = ExcelID
    self.bShowAddButton = bShowAddButton
    Refresh(self)
end

---Called when this entry is assigned a new item object to represent by the owning list view
---@param ListItemObject BP_CommonCurrencyItemObject_C
---@return void
function WBP_Common_Currency_Item:OnListItemObjectSet(ListItemObject)
    self:SetCurrencyItemExcelID(ListItemObject.ExcelID, ListItemObject.ShowAddButton)
    if ListItemObject.bDark then
        self.TextNumber:SetColorAndOpacity(self.DarkTextSlateColor)
    else
        self.TextNumber:SetColorAndOpacity(self.LightTextSlateColor)
    end
end


return WBP_Common_Currency_Item
