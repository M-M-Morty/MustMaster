

local G = require('G')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")
local ItemBaseTable = require("common.data.item_base_data").data
local TipsUtil = require("CP0032305_GH.Script.common.utils.tips_util")
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local ui_communication_npcsubmit = Class(UIWindowBase)

function ui_communication_npcsubmit:UpdateParams(Param, DialogueInfo)
    self.Param = Param
    self.DialogueInfo = DialogueInfo.DialogueObject
end

function ui_communication_npcsubmit:OnShow()
    local PlayerController = UE.UGameplayStatics.GetPlayerController(G.GameInstance:GetWorld(), 0)
    self.DialogueId = self.DialogueInfo.StartDialogueID
    self.SubmitItemInfo = PlayerController.PlayerState.MissionAvatarComponent.DialogueSubmitItemInfoMap:FindRef(self.DialogueId)
    self:InitData()
end


function ui_communication_npcsubmit:InitData()
    if not self.SubmitItemInfo then
        G.log:error("shiniingliu:ui_communication_npcsubmit", "self.SubmitItemInfo is nil !!!")
        return
    end
    self.SubmitItemsData = {}
    self.SubmitItems = {}
    self.SubmitType = self.SubmitItemInfo.SubmitType
    self.ItemManager = ItemUtil.GetItemManager(self)

    self:GetOwnedItems()
    self:SetDialogue()
    self:InitWidget()
end

function ui_communication_npcsubmit:InitWidget()

    if self.SubmitType == Enum.ESubmitType.SpecificItem then
        self.WBP_Common_LeftPopupWindow:SetVisibility(UE.ESlateVisibility.Hidden)
        self.Canvas_SpecialDeliver:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

        self.WBP_ComBtn_Deliver.OnClicked:Add(self, self.ClickSubmitBtn)
        self.WBP_Common_TopContent.CommonButton_Close.OnClicked:Add(self, self.ClosePanel)

        self.List_PropSlotProxy = WidgetProxys:CreateWidgetProxy(self.List_PropSlot)
    else
        self.WBP_Common_LeftPopupWindow:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Canvas_SpecialDeliver:SetVisibility(UE.ESlateVisibility.Hidden)
        self.WBP_Common_LeftPopupWindow:InitWidget("交付", false)

        if self.LeftPopUpItemsData ~= nil then
            self.WBP_Common_LeftPopupWindow.Switch_PropList:SetActiveWidgetIndex(1)
            self.WBP_Common_LeftPopupWindow:LoadItemList(self.LeftPopUpItemsData)
        else
            self.WBP_Common_LeftPopupWindow.Switch_PropList:SetActiveWidgetIndex(0)
        end

        self.WBP_Common_LeftPopupWindow.WBP_ComBtn_Deliver.OnClicked:Add(self, self.ClickSubmitBtn)
        self.WBP_Common_LeftPopupWindow.Img_PropListBg.WBP_Common_TopContent.CommonButton_Close.OnClicked:Add(self, self.ClosePanel)

        self.List_PropSlotProxy = WidgetProxys:CreateWidgetProxy(self.WBP_Common_LeftPopupWindow.List_PropSlot)
    end
    self:RefreshSubmitBtnState()
    self:LoadSubmitedItems()
    self:ShowAnim()
end

function ui_communication_npcsubmit:ShowAnim()
    self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    self.WBP_HUD_Nagging:PlayInAnim()
    self.WBP_Common_LeftPopupWindow:PlayInAnim()
end

function ui_communication_npcsubmit:CloseAnim()
    ---其他控件拥有默认关闭动画DX_Out，会自动执行
    self.WBP_HUD_Nagging:PlayOutAnim()
end

---设置对话内容
function ui_communication_npcsubmit:SetDialogue()
    local detail = self.DialogueInfo:GetCurrentStepData().Detail
    self.WBP_HUD_Nagging:SetContent(detail)
end


--- 处理拥有的满足条件的item数据以及需要交付的数据
function ui_communication_npcsubmit:GetOwnedItems()
    if self.SubmitType == Enum.ESubmitType.SpecificItem then
        if self.SubmitItemInfo.ItemMapKey:Length() ~= self.SubmitItemInfo.ItemMapValue:Length() then
            G.log:error("shiniingliu:ui_communication_npcsubmit", "itemMapKey:Length() ~= itemMapValue:Length()")
        end
        local itemMapKey = self.SubmitItemInfo.ItemMapKey:ToTable()
        local itemMapValue = self.SubmitItemInfo.ItemMapValue:ToTable()
        for idx, id in pairs(itemMapKey) do
            local propSlot = {
                index = id,
                ownedCount = 0,
                needCount = itemMapValue[idx],
                itemId = id,
                ownedWidget = self,
                submitType = Enum.ESubmitType.SpecificItem
            }
            propSlot.ownedCount = self.ItemManager:GetItemCountByExcelID(id)
            self.SubmitItemsData[id] = propSlot
        end
    elseif self.SubmitType == Enum.ESubmitType.ItemSet then
        local itemSet = self.SubmitItemInfo.ItemSet:ToTable()
        for index, id in pairs(itemSet) do
            local count = self.ItemManager:GetItemCountByExcelID(id)
            if count > 0 then
                local ownedItem = {
                    ownedCount = count,
                    itemName = "",
                    itemId = id,
                    ownedWidget = self,
                    isSelected = false
                }
                local ItemData = ItemBaseTable[id]
                ownedItem.itemName = ItemData.name
                if self.LeftPopUpItemsData == nil then
                    self.LeftPopUpItemsData = {}
                end
                self.LeftPopUpItemsData[id] = ownedItem
            end
        end
        for idx = 1, self.SubmitItemInfo.ItemSetNum do
            local propSlot = {
                index = idx,
                ownedCount = 0,
                needCount = 1,
                itemId = 0,
                ownedWidget = self,
                submitType = Enum.ESubmitType.ItemSet
            }
            self.SubmitItemsData[idx] = propSlot
        end

    elseif self.SubmitType == Enum.ESubmitType.ItemType then
        local ItemType = self.SubmitItemInfo.ItemType
        local items = self.ItemManager:GetItemsByCategoryID(ItemType)

        for _, item in pairs(items) do
            local count = self.ItemManager:GetItemCountByExcelID(item.ExcelID)
            if count > 0 then
                local ownedItem = {
                    ownedCount = count,
                    itemName = "",
                    itemId = item.ExcelID,
                    ownedWidget = self,
                    isSelected = false
                }
                local ItemData = ItemBaseTable[item.ExcelID]
                ownedItem.itemName = ItemData.name
                if self.LeftPopUpItemsData == nil then
                    self.LeftPopUpItemsData = {}
                end
                self.LeftPopUpItemsData[item.ExcelID] = ownedItem
            end
        end
        local itemTypeNumList = self.SubmitItemInfo.ItemTypeNumList:ToTable()

        for idx, num in pairs(itemTypeNumList) do
            local propSlot = {
                index = idx,
                ownedCount = 0,
                needCount = num,
                itemId = 0,
                submitType = Enum.ESubmitType.ItemType,
                ownedWidget = self,
                isSelected = false
            }
            self.SubmitItemsData[idx] = propSlot
        end
    end
end

---load当前提交栏中物品
function ui_communication_npcsubmit:LoadSubmitedItems()
    self.List_PropSlot:ClearListItems()
    self.SubmitItems = {}
    if self.SubmitItemsData ~= nil then
        for id, item in pairs(self.SubmitItemsData) do
            self.List_PropSlotProxy:AddItem(item)
        end
    end
end

---Create提交栏中物品会缓存
function ui_communication_npcsubmit:AddPropItem(item)
    self.SubmitItems[item.itemData.index] = item
end

---刷新当前提交栏中物品
function ui_communication_npcsubmit:RefreshSubmitItem(index)
    local item = self.SubmitItems[index]
    if item then
        item:SetItem(self.SubmitItemsData[index])
    end
end

function ui_communication_npcsubmit:CheckSubmitListFull()
    for index, item in pairs(self.SubmitItemsData) do
        if item.itemId == 0 then
            return false
        end
    end
    return true
end

function ui_communication_npcsubmit:SelectOwnedItem(itemId)
    if self.LeftPopUpItemsData[itemId].ownedCount <= 0 then
        TipsUtil.ShowCommonTips("物品数量不足")
        return
    end

    ---塞数据到SubmitItemsMap，显示或刷新
    if self.SubmitType == Enum.ESubmitType.ItemSet then
        if self:CheckSubmitListFull() then
            TipsUtil.ShowCommonTips("交付栏位已满")
            return
        end
        self.LeftPopUpItemsData[itemId].ownedCount = self.LeftPopUpItemsData[itemId].ownedCount - 1
        for index, propSlot in pairs(self.SubmitItemsData) do
            if propSlot.itemId == 0 then
                self.SubmitItemsData[index].ownedCount = 1
                self.SubmitItemsData[index].itemId = itemId
                self:RefreshSubmitItem(index)
                break
            end
        end
        self.LeftPopUpItemsData[itemId].isSelected = true
        self.WBP_Common_LeftPopupWindow:RefreshItem(self.LeftPopUpItemsData[itemId])
    
        self:RefreshSubmitBtnState()
    elseif self.SubmitType == Enum.ESubmitType.ItemType then
        local itemTypeNumListLength = #self.SubmitItemInfo.ItemTypeNumList:ToTable()
        if itemTypeNumListLength == 1 then              --仅有一个数量要求时，已选择的状态下，点击其他item可以切换
            if not self.SubmitItemsData[itemTypeNumListLength] then
                return
            end
            if self:CheckSubmitListFull() then
                local oldItem = self.SubmitItemsData[itemTypeNumListLength]
                if oldItem ~= nil then
                    self.LeftPopUpItemsData[oldItem.itemId].ownedCount = oldItem.ownedCount + self.LeftPopUpItemsData[oldItem.itemId].ownedCount
                    self.LeftPopUpItemsData[oldItem.itemId].isSelected = false
                    self.WBP_Common_LeftPopupWindow:RefreshItem(self.LeftPopUpItemsData[oldItem.itemId])
                end
            end
            if self.LeftPopUpItemsData[itemId].ownedCount >= self.SubmitItemsData[itemTypeNumListLength].needCount then
                self.SubmitItemsData[itemTypeNumListLength].ownedCount = self.SubmitItemsData[itemTypeNumListLength].needCount
                self.LeftPopUpItemsData[itemId].ownedCount = self.LeftPopUpItemsData[itemId].ownedCount - self.SubmitItemsData[itemTypeNumListLength].needCount
            else
                self.SubmitItemsData[itemTypeNumListLength].ownedCount = self.LeftPopUpItemsData[itemId].ownedCount
                self.LeftPopUpItemsData[itemId].ownedCount = 0
            end

            self.SubmitItemsData[itemTypeNumListLength].itemId = itemId
            self.LeftPopUpItemsData[itemId].isSelected = true
            self:RefreshSubmitItem(itemTypeNumListLength)
            self.WBP_Common_LeftPopupWindow:RefreshItem(self.LeftPopUpItemsData[itemId])
            self:RefreshSubmitBtnState()
        else
            if self:CheckSubmitListFull() then
                TipsUtil.ShowCommonTips("交付栏位已满")
                return
            end
            if self.LeftPopUpItemsData[itemId].isSelected then
                return
            end
            for index, propSlot in pairs(self.SubmitItemsData) do
                if propSlot.itemId == 0 then
                    if self.LeftPopUpItemsData[itemId].ownedCount >= self.SubmitItemsData[index].needCount then
                        self.SubmitItemsData[index].ownedCount = self.SubmitItemsData[index].needCount
                        self.LeftPopUpItemsData[itemId].ownedCount = self.LeftPopUpItemsData[itemId].ownedCount - self.SubmitItemsData[index].needCount
                    else
                        self.SubmitItemsData[index].ownedCount = self.LeftPopUpItemsData[itemId].ownedCount
                        self.LeftPopUpItemsData[itemId].ownedCount = 0
                    end
                    self.SubmitItemsData[index].itemId = itemId
                    self.LeftPopUpItemsData[itemId].isSelected = true
                   
                    self:RefreshSubmitItem(index)
                    self.WBP_Common_LeftPopupWindow:RefreshItem(self.LeftPopUpItemsData[itemId])

                    self:RefreshSubmitBtnState()
                    break
                end
            end
        end
    end

end

function ui_communication_npcsubmit:RefreshSubmitBtnState()
    local enableBtn = self:IsCanSubmit() 
    if self.SubmitType == Enum.ESubmitType.SpecificItem then
        self.WBP_ComBtn_Deliver:SetIsEnabled(enableBtn)
    else
        self.WBP_Common_LeftPopupWindow.WBP_ComBtn_Deliver:SetIsEnabled(enableBtn)
    end
end

function ui_communication_npcsubmit:IsCanSubmit()
    for index, item in pairs(self.SubmitItemsData) do
        if item.needCount > item.ownedCount then
            return false
        end
    end
    return true
end

function ui_communication_npcsubmit:ClickSubmitBtn()
    if self:IsCanSubmit() then
        local BPS_ItemSlot = Struct.BPS_ItemSlot
        local allItems = UE.TArray(BPS_ItemSlot)
        for index, item in pairs(self.SubmitItemsData) do
            local itemSlot = Struct.BPS_ItemSlot()
            itemSlot.ItemID = item.itemId
            itemSlot.ItemNum = item.needCount
            allItems:Add(itemSlot)
        end
        local PlayerController = UE.UGameplayStatics.GetPlayerController(G.GameInstance:GetWorld(), 0)
        PlayerController.PlayerState.MissionAvatarComponent:Server_DialogueSubmitItems(self.DialogueId, allItems)
        self:ClosePanel()
    else
        TipsUtil.ShowCommonTips("物品不足无法交付")
    end
end

function ui_communication_npcsubmit:ClosePanel()
    UIManager:CloseUI(self, true)
    self:CloseAnim()
end

--删除交付物品，
function ui_communication_npcsubmit:DeleteSubmitItem(index)
    local deleteItem = self.SubmitItemsData[index]
    local deleteItemId = deleteItem.itemId
    self.LeftPopUpItemsData[deleteItemId].ownedCount = self.LeftPopUpItemsData[deleteItemId].ownedCount + deleteItem.ownedCount
    
    self.SubmitItemsData[index].ownedCount = 0
    self.SubmitItemsData[index].itemId = 0

    for index, item in pairs(self.SubmitItemsData) do
        if deleteItemId == item.itemId then
            self.LeftPopUpItemsData[item.itemId].isSelected = true
            break
        end
        self.LeftPopUpItemsData[deleteItemId].isSelected = false
    end
    self:RefreshSubmitItem(index)
    self.WBP_Common_LeftPopupWindow:RefreshItem(self.LeftPopUpItemsData[deleteItemId])

    self:RefreshSubmitBtnState()
end

return ui_communication_npcsubmit
