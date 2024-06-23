--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@class WBP_Interaction_CallingCard : WBP_Interaction_CallingCard_C
---@field OwnerWidget WBP_Interaction_Telephone
---@field ItemExcelID integer
---@field Index integer
---@field DXImageKey string
---@field bDragging boolean

local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")
local PhoneCardTable = require("common.data.phone_card_data").data
local PicConst = require("CP0032305_GH.Script.common.pic_const")

---@type WBP_Interaction_CallingCard_C
local WBP_Interaction_CallingCard = UnLua.Class()

---@param self WBP_Interaction_CallingCard
local function OnCardHovered(self)
    self.Img_CallingCard_Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

---@param self WBP_Interaction_CallingCard
local function OnCardUnhovered(self)
    self.Img_CallingCard_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function WBP_Interaction_CallingCard:PlayOutAnim()
    self:PlayAnimation(self.DX_CardOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end

---@param self WBP_Interaction_CallingCard
local function RefreshRedDot(self)
    local ItemManager = ItemUtil.GetItemManager(self)
    local Items = ItemManager:GetItemsByExcelID(self.ItemExcelID)
    local Item = Items[1]
    if Item.bUsed then
        self.WBP_Common_RedDot:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.WBP_Common_RedDot:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.WBP_Common_RedDot:ShowNew()
    end
end

---@param self WBP_Interaction_CallingCard
---@param Item FBPS_ItemBase
local function OnUpdateItem(self, Item)
    if Item.ExcelID == self.ItemExcelID then
        RefreshRedDot(self)
    end
end

function WBP_Interaction_CallingCard:Construct()
    self.Switcher_CallingCard:SetActiveWidgetIndex(0)
    self.Img_CallingCard_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Btn_CallingCard.OnHovered:Add(self, OnCardHovered)
    self.Btn_CallingCard.OnUnhovered:Add(self, OnCardUnhovered)
    self.bDragging = false
    local ItemManager = ItemUtil.GetItemManager(self)
    ItemManager:RegUpdateItemCallBack(self, OnUpdateItem)
end

function WBP_Interaction_CallingCard:Destruct()
    self.Btn_CallingCard.OnHovered:Add(self, OnCardHovered)
    self.Btn_CallingCard.OnUnhovered:Add(self, OnCardUnhovered)
    local ItemManager = ItemUtil.GetItemManager(self)
    ItemManager:UnRegUpdateItemCallBack(self, OnUpdateItem)
end

function WBP_Interaction_CallingCard:BeginDrag()
    self.Switcher_CallingCard:SetActiveWidgetIndex(1)
    self.WBP_Common_RedDot:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.bDragging = true
end

---@param bUsed boolean
function WBP_Interaction_CallingCard:EndDrag(bUsed)
    self.Switcher_CallingCard:SetActiveWidgetIndex(0)
    self.bDragging = false
    if bUsed then
        self.WBP_Common_RedDot:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        RefreshRedDot(self)
    end
end

function WBP_Interaction_CallingCard:IsWaitingUse()
    return not self.bDragging and self:IsVisible()
end

---@param OwnerWidget WBP_Interaction_Telephone
function WBP_Interaction_CallingCard:SetData(OwnerWidget, Index, ItemExcelID)
    self:PlayAnimation(self.DX_CardIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    self.OwnerWidget = OwnerWidget
    self.ItemExcelID = ItemExcelID
    self.Index = Index
    self.bDragging = false
    local ItemConfig = ItemUtil.GetItemConfigByExcelID(ItemExcelID)
    ---@type PhoneCardConfig
    local PhoneCardConfig = PhoneCardTable[tonumber(ItemConfig.task_item_details[1])]
    local NormalPicKey = PhoneCardConfig.picture_ID
    self.DXImageKey = PhoneCardConfig.mini_picture_ID
    PicConst.SetImageBrush(self.Img_CallingCard_Normal, NormalPicKey)
    PicConst.SetImageBrush(self.Img_CallingCard_Drag, NormalPicKey)
    RefreshRedDot(self)
end

---The system will use this event to notify a widget that the cursor has entered it. This event is NOT bubbled.
---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
---@return void
function WBP_Interaction_CallingCard:OnMouseEnter(MyGeometry, MouseEvent)
    if not self.OwnerWidget.CardInsertStart then
        OnCardHovered(self)
        self.OwnerWidget:OnMouseEnterCard(self.Index)
    end
end

---The system will use this event to notify a widget that the cursor has left it. This event is NOT bubbled.
---@param MouseEvent FPointerEvent
---@return void
function WBP_Interaction_CallingCard:OnMouseLeave(MouseEvent)
    if not self.OwnerWidget.CardInsertStart then
        OnCardUnhovered(self)
        self.OwnerWidget:OnMouseLeaveCard(self.Index)
    end
end

return WBP_Interaction_CallingCard
