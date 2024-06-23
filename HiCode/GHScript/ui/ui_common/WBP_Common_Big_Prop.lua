--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@class WBP_Common_Big_Prop : WBP_Common_Big_Prop_C
---@field OwnerWidget UUserWidget
---@field Item FBPS_ItemBase
---@field CDTimerHandle FTimerHandle

---@type WBP_Common_Big_Prop_C
local WBP_Common_Big_Prop = UnLua.Class()

local UIConst = require("CP0032305_GH.Script.common.ui_const")
local ItemBaseTable = require("common.data.item_base_data")
local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")
local ItemDef = require("CP0032305_GH.Script.item.ItemDef")
local PicConst = require("CP0032305_GH.Script.common.pic_const")
local G = require("G")

local function OnClickItem(self)
    if self.OwnerWidget.OnClickItem then
        self.OwnerWidget:OnClickItem(self.Item)
    end
end

---@param self WBP_Common_Big_Prop
local function RefreshSelected(self)
    local CurrentSelectedItem = nil
    if self.OwnerWidget and self.OwnerWidget.CurrentSelectedItemUniqueID then
        local ItemManager = ItemUtil.GetItemManager(self)
        local Item = ItemManager:GetItemByUniqueID(self.OwnerWidget.CurrentSelectedItemUniqueID)
        CurrentSelectedItem = Item
    end
    if CurrentSelectedItem and CurrentSelectedItem.UniqueID == self.Item.UniqueID then
        self.ImgSelected:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.ImgSelected:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

---@param self WBP_Common_Big_Prop
local function ClearCDTimerHandle(self)
    if self.CDTimerHandle then
        UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.CDTimerHandle)
        self.CDTimerHandle = nil
    end
end

---@param self WBP_Common_Big_Prop
---@param RemainSecond integer
local function ShowUseCD(self, RemainSecond)
    ClearCDTimerHandle(self)
    self.Text_Time:SetText(RemainSecond..UIConst.Second)
    RemainSecond = RemainSecond - 1
    local CallBack = function()
        ShowUseCD(self, RemainSecond)
    end
    if RemainSecond <= 0 then
        CallBack = function()
            self.Cvs_QualityBoxCD:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
    self.CDTimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, CallBack}, 1, false)
end

---@param self WBP_Common_Big_Prop
---@param RemainSecond integer
---@param TotalSecond integer
local function PlayCDAnim(self, RemainSecond, TotalSecond)
    local AnimEndTime = self.DX_Progress:GetEndTime()
    local StartAtTime = AnimEndTime / TotalSecond * (TotalSecond - RemainSecond)
    local PlaybackSpeed = AnimEndTime / TotalSecond
    self:PlayAnimation(self.DX_Progress, StartAtTime, 1, UE.EUMGSequencePlayMode.Forward, PlaybackSpeed, false)
end

---@param self WBP_Common_Big_Prop
---@param ExcelID integer
local function RefreshCD(self, ExcelID)
    local ItemManager = ItemUtil.GetItemManager(self)
    local RemainSecond = ItemManager:GetItemUseCD(ExcelID)
    if RemainSecond > 0 then
        self.Cvs_QualityBoxCD:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        local ItemConfig = ItemUtil.GetItemConfigByExcelID(ExcelID)
        if ItemConfig == nil then
            G.log:warn("WBPCommonBigProp", "RefreshCD error! ExcelID invalid: ExcelID: %d", ExcelID)
            return
        end
        local TotalSecond = ItemConfig.use_CD_seconds
        PlayCDAnim(self, RemainSecond, TotalSecond)
        ShowUseCD(self, RemainSecond)
    else
        self:StopAnimation(self.DX_Progress)
        self.Cvs_QualityBoxCD:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

---@param self WBP_Common_Big_Prop
local function RefreshItem(self)
    local Item = self.Item
    local ItemConfig = ItemUtil.GetItemConfigByExcelID(Item.ExcelID)
    local ItemQualityConfig = ItemUtil.GetItemQualityConfig(ItemConfig.quality)
    PicConst.SetImageBrush(self.ImgQuality, ItemQualityConfig.icon_reference_big)
    PicConst.SetImageBrush(self.ImgItemIcon, ItemConfig.icon_reference)
    if ItemConfig.category_ID == ItemDef.CATEGORY.WEAPON then
        --- todo 后面有了等级再替换
        self.TextNumber:SetText("Lv89")
    elseif ItemConfig.category_ID == ItemDef.CATEGORY.EQUIPMENT then
        --- todo 后面有了等级再替换
        self.TextNumber:SetText("+10")
    else
        self.TextNumber:SetText(Item.StackCount)
    end

    RefreshCD(self, Item.ExcelID)

    ---@type WBP_Common_RedDot
    local WBP_Common_RedDot = self.WBP_Common_RedDot
    if ItemConfig.appear_rule == ItemBaseTable.New and Item.bNew then
        WBP_Common_RedDot:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        WBP_Common_RedDot:ShowNew()
    elseif ItemConfig.appear_rule == ItemBaseTable.Redpoint and Item.bNew then
        WBP_Common_RedDot:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        WBP_Common_RedDot:ShowRedDot()
    else
        self.WBP_Common_RedDot:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    RefreshSelected(self)
end

---@param self WBP_Common_Big_Prop
---@param Item FBPS_ItemBase
local function OnSelectedItem(self, Item)
    RefreshSelected(self)
end

---@param self WBP_Common_Big_Prop
---@param Item FBPS_ItemBase
local function OnItemUpdate(self, Item)
    if Item.UniqueID == self.Item.UniqueID then
        self.Item = Item
        RefreshItem(self)
    end
end

---@param self WBP_Common_Big_Prop
local function OnUseItem(self, ExcelID, Count, Time)
    if ExcelID == self.Item.ExcelID then
        RefreshCD(self, ExcelID)
    end
end

---Called when this entry is assigned a new item object to represent by the owning list view
---@param ListItemObject BP_CommonBigPropItemObject_C
---@return void
function WBP_Common_Big_Prop:OnListItemObjectSet(ListItemObject)
    self.OwnerWidget = ListItemObject.OwnerWidget
    local UniqueID = ListItemObject.UniqueID
    local ItemManager = ItemUtil.GetItemManager(self)
    local Item = ItemManager:GetItemByUniqueID(UniqueID)
    self.Item = Item
    if self.OwnerWidget and self.OwnerWidget.RegOnItemSelected then
        self.OwnerWidget:RegOnItemSelected(self, OnSelectedItem)
    end
    RefreshItem(self)
end

function WBP_Common_Big_Prop:Construct()
    self.BtnItem.Button.OnClicked:Add(self, OnClickItem)

    local ItemManager = ItemUtil.GetItemManager(self)
    ItemManager:RegUpdateItemCallBack(self, OnItemUpdate)
    ItemManager:RegUseItemCallBack(self, OnUseItem)
end

function WBP_Common_Big_Prop:Destruct()
    self.BtnItem.Button.OnClicked:Remove(self, OnClickItem)
    if self.OwnerWidget and self.OwnerWidget.UnRegOnItemSelected then
        self.OwnerWidget:UnRegOnItemSelected(self, OnSelectedItem)
    end
    local ItemManager = ItemUtil.GetItemManager(self)
    ItemManager:UnRegUpdateItemCallBack(self, OnItemUpdate)
    ItemManager:UnRegUseItemCallBack(self, OnUseItem)
    ClearCDTimerHandle(self)
end

return WBP_Common_Big_Prop
