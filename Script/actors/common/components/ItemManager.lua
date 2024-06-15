--
-- DESCRIPTION
--
-- @COMPANY Wuhan GHGame Studio
-- @AUTHOR Zhiyuan Li
--

---@alias AddItemCallbackT fun(Owner:UObject, Item:FBPS_ItemBase)
---@alias RemoveItemCallbackT fun(Owner:UObject, UniqueID:integer, ExcelId:integer, Count:integer)
---@alias UpdateItemCallbackT fun(Owner:UObject, Item:FBPS_ItemBase)
---@alias BagCapacityChangeCallbackT fun(Owner:UObject, TabIndex:integer)
---@alias UseItemCallbackT fun(Owner:UObject, ExcelID:integer, Count:integer, UseTime:integer)
---@alias TabNewRedDotCallbackT fun(Owner:UObject, TabIndex:integer)

---@class BP_ItemManager : BP_ItemManager_C
---@field Overridden BP_ItemManager_C
---@field AddItemCallbacks table<UObject, AddItemCallbackT>
---@field RemoveItemCallbacks table<UObject, RemoveItemCallbackT>
---@field UpdateItemCallbacks table<UObject, UpdateItemCallbackT>
---@field BagCapacityChangeCallbacks table<UObject, BagCapacityChangeCallbackT>
---@field UseItemCallbacks table<UObject, UseItemCallbackT>
---@field TabNewRedDotCallbacks table<UObject, TabNewRedDotCallbackT>
---@field ItemUseTimeRecords table<integer, integer>

---@type BP_ItemManager
local BP_ItemManager = UnLua.Class()

local G = require("G")
local ItemBaseTable = require("common.data.item_base_data")
local ItemUtil = require("common.item.ItemUtil")
local BlueprintConst = require("CP0032305_GH.Script.common.blueprint_const")
local NEW_DISAPPEAR_RULE = require("common.item.ItemDef").NEW_DISAPPEAR_RULE
local TipsUtil = require("CP0032305_GH.Script.common.utils.tips_util")
local ConstText = require("CP0032305_GH.Script.common.text_const")
local PicText = require("CP0032305_GH.Script.common.pic_const")
local ItemEffectUtil = require("common.utils.item_effect_utils")
local SubsystemUtils = require("common.utils.subsystem_utils")

local ITEM_BAG_FULL_MSG = "ITEM_BAG_FULL"
local ITEM_USE_CD_MSG = "ITEM_USE_CD"
local FAILED = -1

---Server Client
---@param self BP_ItemManager
---@param Item FBPS_ItemBase
local function OnAddItemCallback(self, Item)
    if self.AddItemCallbacks == nil then
        return
    end
    for Owner, CB in pairs(self.AddItemCallbacks) do
        if CB then
            CB(Owner, Item)
        end
    end
end

---Server Client
---@param self BP_ItemManager
---@param UniqueID integer
---@param ExcelId integer
---@param Count integer
local function OnRemoveItemCallback(self, UniqueID, ExcelId, Count)
    if self.RemoveItemCallbacks == nil then
        return
    end
    for Owner, CB in pairs(self.RemoveItemCallbacks) do
        if CB then
            CB(Owner, UniqueID, ExcelId, Count)
        end
    end
end

---Server Client
---@param self BP_ItemManager
---@param Item FBPS_ItemBase
local function OnUpdateItemCallback(self, Item)
    if self.AddItemCallbacks == nil then
        return
    end
    for Owner, CB in pairs(self.UpdateItemCallbacks) do
        if CB then
            CB(Owner, Item)
        end
    end
end

---Server Client
---@param self BP_ItemManager
---@param TabIndex integer
local function OnBagCapacityChangeCallback(self, TabIndex)
    if self.BagCapacityChangeCallbacks == nil then
        return
    end
    for Owner, CB in pairs(self.BagCapacityChangeCallbacks) do
        if CB then
            CB(Owner, TabIndex)
        end
    end
end

---Server Client
---@param self BP_ItemManager
---@param ExcelID integer
---@param Count integer
---@param UseTime integer
local function OnUseItemCallback(self, ExcelID, Count, UseTime)
    if self.UseItemCallbacks == nil then
        return
    end
    for Owner, CB in pairs(self.UseItemCallbacks) do
        if CB then
            CB(Owner, ExcelID, Count, UseTime)
        end
    end
end

---Server Client
---@param self BP_ItemManager
---@param TabIndex integer
local function OnTabNewRedDotCallback(self, TabIndex)
    if self.TabNewRedDotCallbacks == nil then
        return
    end
    for Owner, CB in pairs(self.TabNewRedDotCallbacks) do
        if CB then
            CB(Owner, TabIndex)
        end
    end
end

---Server
---@param self BP_ItemManager
---@param ExcelID integer
local function IsItemUnlock(self, ExcelID)
    return self.UnlockItemExcelIDs:Contains(ExcelID)
end

local function IsItemAutoUse(ExcelID)
    local ItemConfig = ItemUtil.GetItemConfigByExcelID(ExcelID)
    return ItemConfig.item_use_auto == 1 or ItemConfig.item_use_auto == true
end

---Server
---@param self BP_ItemManager
---@param ExcelID integer
local function UnlockItem(self, ExcelID)
    self.UnlockItemExcelIDs:Add(ExcelID)
end

---Server
---@param self BP_ItemManager
---@param ExcelID integer 调用方保证ExcelID有效
---@param StackCount integer 调用方去保证StackCount不超过配置叠加上限
---@return FBPS_ItemBase
local function CreateItem(self, ExcelID, StackCount)
    if StackCount == nil or StackCount <= 0 then
        G.log:warn("ItemManager", "CreateItem failed! StackCount invalid! %d", StackCount)
        return nil
    end
    ---@type FBPS_ItemBase
    local NewItem = Struct.BPS_ItemBase()
    NewItem.UniqueID = ItemUtil.GenerateItemUniqueID()
    NewItem.ExcelID = ExcelID
    NewItem.StackCount = StackCount
    NewItem.ObtainTime = UE.UHiUtilsFunctionLibrary.GetNowTimestamp()
    NewItem.bNew = false
    NewItem.bUsed = false
    local ItemConfig = ItemUtil.GetItemConfigByExcelID(ExcelID)
    if ItemConfig.appear_rule == ItemBaseTable.New then
        NewItem.bNew = true
        if ItemConfig.stack_limit > 1 and self:GetItemCountByExcelID(ExcelID) > 0 then
            NewItem.bNew = false
        end
    elseif ItemConfig.appear_rule == ItemBaseTable.Redpoint then
        NewItem.bNew = true
    else
        NewItem.bNew = false
    end
    return NewItem
end

---@param ExcelID integer
---@param Time integer
---@return FBPS_ItemUseRecord
local function CreateItemUseRecord(ExcelID, Time)
    ---@type FBPS_ItemUseRecord
    local NewItemUseRecord = Struct.BPS_ItemUseRecord()
    NewItemUseRecord.ExcelID = ExcelID
    NewItemUseRecord.LastUseTime = Time
    return NewItemUseRecord
end

---Server Client
---@param self BP_ItemManager
---@param ExcelID integer
---@param Time integer
local function AddUseItemRecord(self, ExcelID, Time)
    local bFound = false
    local ItemConfig = ItemUtil.GetItemConfigByExcelID(ExcelID)
    if ItemConfig.use_CD_seconds == nil or ItemConfig.use_CD_seconds == 0 then
        G.log:warn("ItemManager", "AddUseItemRecord no cd! ExcelID:%d", ExcelID)
        return
    end
    local Now = UE.UHiUtilsFunctionLibrary.GetNowTimestamp()
    if Time + ItemConfig.use_CD_seconds < Now then
        G.log:warn("ItemManager", "AddUseItemRecord cd! ExcelID:%d", ExcelID)
        return
    end
    for i = 1, self.InitItemUseRecord:Length() do
        ---@type FBPS_ItemUseRecord
        local ItemUseRecord = self.InitItemUseRecord:GetRef(i)
        if ItemUseRecord.ExcelID == ExcelID then
            ItemUseRecord.LastUseTime = Time
            bFound = true
            break
        end
    end
    if not bFound then
        local UseRecord = CreateItemUseRecord(ExcelID, Time)
        self.InitItemUseRecord:Add(UseRecord)
    end
    self.ItemUseTimeRecords[ExcelID] = Time
end

---Server Client
---@param self BP_ItemManager
---@param TabIndex integer
---@return FBPS_BagTab
local function CreateBagTabData(self, TabIndex)
    G.log:info("ItemManager", "CreateBagTabData TabIndex %d", TabIndex)
    if not ItemUtil.IsBagTabExist(TabIndex) then
        G.log:warn("ItemManager", "CreateBagTabData failed! Cannot find TabIndex Config!TabIndex: %d", TabIndex)
        return nil
    end
    ---@type FBPS_BagTab
    local BagTabData = Struct.BPS_BagTab()
    BagTabData.TabIndex = TabIndex
    BagTabData.ExtraCapacity = 0
    BagTabData.bHasRedDot = false
    return BagTabData
end

---Server
---@param TabIndex integer
---@param AddCount integer
---@return integer
function BP_ItemManager:AddBagCapacity(TabIndex, AddCount)
    if not UE.UKismetSystemLibrary.IsServer(self) then
        return
    end
    ---@type FBPS_BagTab
    local BagTabData = nil
    for i = 1, self.BagTabDatas:Length() do
        local TabData = self.BagTabDatas:GetRef(i)
        if TabData.TabIndex == TabIndex then
            BagTabData = TabData
            BagTabData.ExtraCapacity = BagTabData.ExtraCapacity + AddCount
        end
    end
    if BagTabData == nil then
        BagTabData = CreateBagTabData(self, TabIndex)
        BagTabData.ExtraCapacity = BagTabData.ExtraCapacity + AddCount
        self.BagTabDatas:Add(BagTabData)
    end
    OnBagCapacityChangeCallback(self, TabIndex)
    G.log:info("ItemManager", "Add bag capacity Index:%d, AddCount:%d, NewCount:%d", TabIndex, AddCount, BagTabData.ExtraCapacity)
    return BagTabData.ExtraCapacity
end

---Client
---@param self BP_ItemManager
---@param TabIndex integer
---@param Count integer
local function SetBagExtraCapacity(self, TabIndex, Count)
    ---@type FBPS_BagTab
    local BagTabData = nil
    for i = 1, self.BagTabDatas:Length() do
        local TabData = self.BagTabDatas:GetRef(i)
        if TabData.TabIndex == TabIndex then
            BagTabData = TabData
            BagTabData.ExtraCapacity = Count
        end
    end
    if BagTabData == nil then
        BagTabData = CreateBagTabData(self, TabIndex)
        BagTabData.ExtraCapacity = Count
        self.BagTabDatas:Add(BagTabData)
    end
    OnBagCapacityChangeCallback(self, TabIndex)
    G.log:info("ItemManager", "Set bag capacity Index:%d, Count:%d, capacity:d%", TabIndex, Count, BagTabData.ExtraCapacity)
end

---Server Client
---@param self BP_ItemManager
---@param NewItem FBPS_ItemBase
local function AddItemToTab(self, NewItem)
    local TabIndex = ItemUtil.GetItemTabIndex(NewItem.ExcelID)
    if TabIndex <= 0 then
        G.log:warn("ItemManager", "Cannot find item tabIndex! ExcelID %d", NewItem.ExcelID)
        return
    end
    if self.AllTabItems:Find(TabIndex) == nil then
        ---@type FBPS_BagTabItems
        local BPS_BagTabItems = Struct.BPS_BagTabItems()
        self.AllTabItems:Add(TabIndex, BPS_BagTabItems)
    end
    ---@type FBPS_BagTabItems
    local BPS_BagTabItems = self.AllTabItems:FindRef(TabIndex)
    BPS_BagTabItems.TabItems:Add(NewItem.UniqueID, NewItem)
end

---Server Client
---@param self BP_ItemManager
---@param Item FBPS_ItemBase
local function RemoveItemFromTab(self, Item)
    local TabIndex = ItemUtil.GetItemTabIndex(Item.ExcelID)
    ---@type FBPS_BagTabItems
    local BPS_BagTabItems = self.AllTabItems:Find(TabIndex)
    if BPS_BagTabItems == nil then
        G.log:warn("ItemManager", "Cannot find item to remove! UniqueID %d, ExcelID %d", Item.UniqueID, Item.ExcelID)
        return
    end
    self.AllTabItems:FindRef(TabIndex).TabItems:Remove(Item.UniqueID)
end

---Server Client
---@param self BP_ItemManager
---@param Item FBPS_ItemBase
local function AddItem(self, Item)
    self.InitItems:Add(Item)
    AddItemToTab(self, Item)
    OnAddItemCallback(self, Item)
end

---Server
---@param self BP_ItemManager
---@param UniqueID integer
---@param AddCount integer
---@param bNew boolean
local function AddInitItemStack(self, UniqueID, AddCount, bNew)
    for i = 1, self.InitItems:Length() do
        ---@type FBPS_ItemBase
        local Item = self.InitItems:GetRef(i)
        if Item.UniqueID == UniqueID then
            Item.StackCount = Item.StackCount + AddCount
            Item.bNew = bNew
            AddItemToTab(self, Item)
            return
        end
    end
end

---Client
---@param self BP_ItemManager
---@param UniqueID integer
---@param Count integer
local function SetInitItemStack(self, UniqueID, Count)
    for i = 1, self.InitItems:Length() do
        ---@type FBPS_ItemBase
        local Item = self.InitItems:GetRef(i)
        if Item.UniqueID == UniqueID then
            Item.StackCount = Count
            AddItemToTab(self, Item)
            return
        end
    end
end

---Server Client
---@param self BP_ItemManager
---@param UniqueID integer
---@param bNew boolean
local function SetInitItemNew(self, UniqueID, bNew)
    for i = 1, self.InitItems:Length() do
        ---@type FBPS_ItemBase
        local Item = self.InitItems:GetRef(i)
        if Item.UniqueID == UniqueID then
            Item.bNew = bNew
            AddItemToTab(self, Item)
            return
        end
    end
end

---Server Client
---@param self BP_ItemManager
---@param UniqueID integer
local function SetInitItemUsed(self, UniqueID)
    for i = 1, self.InitItems:Length() do
        ---@type FBPS_ItemBase
        local Item = self.InitItems:GetRef(i)
        if Item.UniqueID == UniqueID then
            Item.bUsed = true
            AddItemToTab(self, Item)
            return
        end
    end
end

---Server
---@param self BP_ItemManager
---@param Item FBPS_ItemBase
---@param AddCount integer
local function AddItemStack(self, Item, AddCount)
    Item.StackCount = Item.StackCount + AddCount
    local ItemConfig = ItemUtil.GetItemConfigByExcelID(Item.ExcelID)
    if AddCount > 0 and ItemConfig.appear_rule == ItemBaseTable.Redpoint then
        Item.bNew = true
    end
    AddInitItemStack(self, Item.UniqueID, AddCount, Item.bNew)
    OnUpdateItemCallback(self, Item)
end

---Server
---@param self BP_ItemManager
---@param Item FBPS_ItemBase
---@param ReduceCount integer
local function ReduceItemStack(self, Item, ReduceCount)
    AddItemStack(self, Item, -ReduceCount)
end

---Client
---@param self BP_ItemManager
---@param Item FBPS_ItemBase
---@param Count integer
local function SetItemStack(self, Item, Count)
    Item.StackCount = Count
    SetInitItemStack(self, Item.UniqueID, Count)
    OnUpdateItemCallback(self, Item)
end

---Server Client
---@param self BP_ItemManager
---@param Item FBPS_ItemBase
---@param bNew boolean
local function SetItemNew(self, Item, bNew)
    Item.bNew = bNew
    SetInitItemNew(self, Item.UniqueID, bNew)
    OnUpdateItemCallback(self, Item)
end

---Server Client
---@param self BP_ItemManager
---@param Item FBPS_ItemBase
local function SetItemUsed(self, Item)
    Item.bUsed = true
    SetInitItemUsed(self, Item.UniqueID)
    OnUpdateItemCallback(self, Item)
end

---Server Client
---@param self BP_ItemManager
---@param UniqueID integer
local function RemoveItemByUniqueID(self, UniqueID)
    local Found = false
    for i = 1, self.InitItems:Length() do
        ---@type FBPS_ItemBase
        local Item = self.InitItems:GetRef(i)
        if Item.UniqueID == UniqueID then
            Found = true
            local ExcelID = Item.ExcelID
            local StackCount = Item.StackCount
            RemoveItemFromTab(self, Item)
            self.InitItems:Remove(i)
            OnRemoveItemCallback(self, UniqueID, ExcelID, StackCount)
            break
        end
    end
    if not Found then
        G.log:warn("ItemManager", "RemoveItemByUniqueID failed! ItemIndex not valid! UniqueID %d", UniqueID)
    end
end

---@param self BP_ItemManager
local function MockInitItemData(self)
    local NewItem = CreateItem(self, 100002, 1)
    AddItem(self, NewItem)
end


function BP_ItemManager:Initialize(Initializer)
    self.AddItemCallbacks = {}
    self.RemoveItemCallbacks = {}
    self.UpdateItemCallbacks = {}
    self.BagCapacityChangeCallbacks = {}
    self.UseItemCallbacks = {}
    self.TabNewRedDotCallbacks = {}
    self.ItemUseTimeRecords = {}
end

function BP_ItemManager:ReceiveBeginPlay()
    if UE.UKismetSystemLibrary.IsServer(self) then
        G.log:debug("ItemManager", "Server BP_ItemManager:ReceiveBeginPlay()")
        --MockInitItemData(self)
    else
        G.log:debug("ItemManager", "Client BP_ItemManager:ReceiveBeginPlay()")
    end
end

function BP_ItemManager:ReceiveEndPlay()
    if UE.UKismetSystemLibrary.IsServer(self) then
        G.log:debug("ItemManager", "Server BP_ItemManager:ReceiveEndPlay()")
    else
        G.log:debug("ItemManager", "Client BP_ItemManager:ReceiveEndPlay()")
    end
end

---@return void
function BP_ItemManager:OnRep_BagTabDatas()
    if UE.UKismetSystemLibrary.IsServer(self) then
        return
    end
end

---@return void
function BP_ItemManager:OnRep_InitItems()
    if UE.UKismetSystemLibrary.IsServer(self) then
        return
    end
    for i = 1, self.InitItems:Length() do
        local Item = self.InitItems:GetRef(i)
        AddItemToTab(self, Item)
    end
end

---@return void
function BP_ItemManager:OnRep_InitItemUseRecord()
    if UE.UKismetSystemLibrary.IsServer(self) then
        return
    end
    for i = 1, self.InitItemUseRecord:Length() do
        ---@type FBPS_ItemUseRecord
        local ItemUseRecord = self.InitItemUseRecord:GetRef(i)
        self.ItemUseTimeRecords[ItemUseRecord.ExcelID] = ItemUseRecord.LastUseTime
    end
end

---@param IDs TArray<integer>
---@return void
function BP_ItemManager:Server_SetItemsNotNew_RPC(IDs)
    if not UE.UKismetSystemLibrary.IsServer(self) then
        return
    end
    if IDs == nil or IDs:Length() <= 0 then
        G.log:warn("ItemManager","Server_SetItemsNotNew_RPC failed!ID invalid")
        return
    end
    for i = 1, IDs:Length() do
        local UniqueID = IDs:GetRef(i)
        local Item = self:GetItemByUniqueID(UniqueID)
        SetItemNew(self, Item, false)
    end
end

---@param ExcelID integer
---@param Count integer
---@param TargetID string
---@return void
function BP_ItemManager:Server_UseItemByExcelID_RPC(ExcelID, Count, TargetID)
    local Target = SubsystemUtils.GetMutableActorSubSystem(UE.UHiUtilsFunctionLibrary.GetGWorld()):GetActor(TargetID)
    self:UseItemByExcelID(ExcelID, Count, Target)
end

---@param ExcelID integer
---@param Count integer
---@param AvatarIndex integer
---@return void
function BP_ItemManager:Server_UseItemForAvatarByExcelID_RPC(ExcelID, Count, AvatarIndex)
    local Target = self:GetOwner():GetPlayerController():GetAvatarByIndex(AvatarIndex)
    self:UseItemByExcelID(ExcelID, Count, Target)
end

-- server
--TODO 补充道具使用reason，后续运营流水打点
function BP_ItemManager:UseItemByExcelID(ExcelID, Count, Target)
    if not UE.UKismetSystemLibrary.IsServer(self) then
        return
    end

    if not self:CanUseItemByExcelID(ExcelID, Count) then
        -- 使用失败效果
        ItemEffectUtil:UseItemFailedEffect(self:GetOwner(), ExcelID)
        return
    end

    local ItemConfig = ItemUtil.GetItemConfigByExcelID(ExcelID)
    if ItemConfig.keep_after_use then
        ---设计假设：使用后不扣除的道具都是一个一个使用的，不存在批量
        local Items = self:GetItemsByExcelID(ExcelID)
        SetItemUsed(self, Items[1])
        if not IsItemAutoUse(ExcelID) then
            local BPS_ItemBaseStruct = Struct.BPS_ItemBase
            local UpdateItems = UE.TArray(BPS_ItemBaseStruct)
            UpdateItems:Add(Items[1])
            self:Client_UpdateItems(UpdateItems)
        end
    else
        self:ReduceItemByExcelID(ExcelID, Count)
    end

    local UseTime = UE.UHiUtilsFunctionLibrary.GetNowTimestamp()
    AddUseItemRecord(self, ExcelID,  UseTime)
    OnUseItemCallback(self, ExcelID, Count, UseTime)

    -- 使用效果
    ItemEffectUtil:UseItemEffect(self:GetOwner(), ExcelID, Count, Target)

    if not IsItemAutoUse(ExcelID) then
        self:Client_UseItemResult(true, ExcelID, Count, UseTime)
    end
    
    G.log:info("ItemManager","UseItemByExcelID, ExcelID:%d, Count:%d, UseTime:%s, Target:%s", ExcelID, Count, UseTime, Target)
end

-- client & server
function BP_ItemManager:CanUseItemByExcelID(ExcelID, Count)
    local ItemConfig = ItemUtil.GetItemConfigByExcelID(ExcelID)
    if ItemConfig == nil then
        G.log:warn("ItemManager", "CanUseItemByExcelID failed!Cannot find ExcelID! %d, %d", ExcelID, Count)
        return false
    end
    if self:GetItemUseCD(ExcelID) > 0 then
        G.log:warn("ItemManager", "CanUseItemByExcelID failed! CD limit! %d, %d, %s", ExcelID, Count, self:GetItemUseCD(ExcelID))
        return false
    end

    if self:GetItemCountByExcelID(ExcelID) < Count then
        G.log:warn("ItemManager", "CanUseItemByExcelID failed! Count not enough! %d, %d", ExcelID, Count)
        return false
    end
    return true
end

---@param TabIndex integer
---@param UniqueID integer
---@param Count integer
---@param TargetID string
---@return void
function BP_ItemManager:Server_UseItemByUniqueID_RPC(TabIndex, UniqueID, Count, TargetID)
    local Target = SubsystemUtils.GetMutableActorSubSystem(UE.UHiUtilsFunctionLibrary.GetGWorld()):GetActor(TargetID)
    self:UseItemByUniqueID(TabIndex, UniqueID, Count, Target)
end

---@param TabIndex integer
---@param UniqueID integer
---@param Count integer
---@param AvatarIndex integer
---@return void
function BP_ItemManager:Server_UseItemForAvatarByUniqueID_RPC(TabIndex, UniqueID, Count, AvatarIndex)
    local Target = self:GetOwner():GetPlayerController():GetAvatarByIndex(AvatarIndex)
    self:UseItemByUniqueID(TabIndex, UniqueID, Count, Target)
end

-- server
function BP_ItemManager:UseItemByUniqueID(TabIndex, UniqueID, Count, Target)
    if not UE.UKismetSystemLibrary.IsServer(self) then
        return
    end

    local BagTabItems = self.AllTabItems:FindRef(TabIndex)
    if not BagTabItems then
        return
    end

    local Item = BagTabItems.TabItems:FindRef(UniqueID)
    if not Item then
        return
    end

    local ExcelID = Item.ExcelID

    local ItemConfig = ItemUtil.GetItemConfigByExcelID(ExcelID)
    if ItemConfig == nil then
        G.log:warn("ItemManager", "Server_UseItemForTeamByUniqueID_RPC failed!Cannot find ExcelID! %d, %d", ExcelID, Count)
        return
    end

    -- 判断数量
    if Count > Item.StackCount then
        G.log:warn("ItemManager", "Server_UseItemForTeamByUniqueID_RPC failed! Count not enough! %d, %d", ExcelID, Count)
        return
    end

    -- 判断cd
    if self:GetItemUseCD(ExcelID) > 0 then
        G.log:warn("ItemManager", "Server_UseItemForTeamByUniqueID_RPC failed! CD limit! %d, %d", ExcelID, Count)
        return
    end

    -- 扣除数量
    if ItemConfig.keep_after_use then
        ---设计假设：使用后不扣除的道具都是一个一个使用的，不存在批量
        SetItemUsed(self, Item)
        if not IsItemAutoUse(ExcelID) then
            local BPS_ItemBaseStruct = Struct.BPS_ItemBase
            local UpdateItems = UE.TArray(BPS_ItemBaseStruct)
            UpdateItems:Add(Item)
            self:Client_UpdateItems(UpdateItems)
        end
    else
        Item.StackCount = Item.StackCount - Count
    end

    local UseTime = UE.UHiUtilsFunctionLibrary.GetNowTimestamp()
    AddUseItemRecord(self, ExcelID,  UseTime)
    OnUseItemCallback(self, ExcelID, Count, UseTime)

    -- 使用效果
    ItemEffectUtil:UseItemEffect(self:GetOwner(), ExcelID, Count, Target)
    if not IsItemAutoUse(ExcelID) then
        self:Client_UseItemResult(true, ExcelID, Count, UseTime)
    end
    G.log:info("ItemManager", "Server_UseItemForTeamByUniqueID_RPC %d, %d, %d, %s", TabIndex, UniqueID, Count, Target)
end

---@param Items TArray<FBPS_ItemBase>
---@return void
function BP_ItemManager:Client_UpdateItems_RPC(Items)
    if UE.UKismetSystemLibrary.IsServer(self) then
        return
    end
    if Items == nil or Items:Length() <= 0 then
        G.log:warn("ItemManager", "Client_UpdateItems_RPC failed! Items Empty!")
        return
    end
    for i = 1, Items:Length() do
        ---@type FBPS_ItemBase
        local ItemNeedUpdate = Items:GetRef(i)
        local Item, TabIndex = self:GetItemByUniqueID(ItemNeedUpdate.UniqueID)
        if Item then
            ---todo 后面如果有别的字段可更新，需要在这里添加
            if ItemNeedUpdate.StackCount ~= Item.StackCount then
                SetItemStack(self, Item, ItemNeedUpdate.StackCount)
            end
            if ItemNeedUpdate.bNew ~= Item.bNew then
                SetItemNew(self, Item, ItemNeedUpdate.bNew)
            end
            if ItemNeedUpdate.bUsed ~= Item.bUsed then
                SetItemUsed(self, Item)
            end
        else
            G.log:warn("ItemManager", "Client_UpdateItems_RPC cannot find uniqueID %d, %d, %d", ItemNeedUpdate.UniqueID, ItemNeedUpdate.ExcelID, ItemNeedUpdate.StackCount)
        end
    end
end

---@param UniqueIDs TArray<integer>
---@return void
function BP_ItemManager:Client_RemoveItems_RPC(UniqueIDs)
    if UE.UKismetSystemLibrary.IsServer(self) then
        return
    end
    if UniqueIDs == nil or UniqueIDs:Length() <= 0 then
        G.log:warn("ItemManager", "Client_RemoveItems_RPC failed! UniqueIDs Empty!")
        return
    end
    for i = 1, UniqueIDs:Length() do
        local UniqueID = UniqueIDs:GetRef(i)
        RemoveItemByUniqueID(self, UniqueID)
    end
end

---@param Items TArray<FBPS_ItemBase>
---@return void
function BP_ItemManager:Client_AddItems_RPC(Items)
    if UE.UKismetSystemLibrary.IsServer(self) then
        return
    end
    if Items == nil or Items:Length() <= 0 then
        G.log:warn("ItemManager", "Client_AddItems_RPC failed! Items Empty!")
        return
    end
    for i = 1, Items:Length() do
        ---@type FBPS_ItemBase
        local Item = Items:GetRef(i)
        AddItem(self, Item)
    end
end

---@param TabIndex integer
---@param Count integer
---@return void
function BP_ItemManager:Client_UpdateTabCapacity_RPC(TabIndex, Count)
    if UE.UKismetSystemLibrary.IsServer(self) then
        return
    end
    if TabIndex == nil or Count == nil or TabIndex <= 0 or Count <= 0 then
        G.log:warn("ItemManager", "Client_UpdateTabCapacity_RPC failed!TabIndex: %d, Count: %d", TabIndex, Count)
        return
    end
    SetBagExtraCapacity(self, TabIndex, Count)
end

---@param bSuccess boolean
---@param ExcelID integer
---@param Count integer
---@param UseTime integer
---@return void
function BP_ItemManager:Client_UseItemResult_RPC(bSuccess, ExcelID, Count, UseTime)
    if UE.UKismetSystemLibrary.IsServer(self) then
        return
    end
    if bSuccess then
        if ExcelID == nil or Count == nil or UseTime == nil or ExcelID <= 0 or Count <= 0 or UseTime <= 0 then
            G.log:warn("ItemManager", "Client_UseItemResult_RPC failed!ExcelID: %d, Count: %d, UseTime:%d", ExcelID, Count, UseTime)
            return
        end
        local ItemConfig = ItemUtil.GetItemConfigByExcelID(ExcelID)
        if ItemConfig == nil then
            G.log:warn("ItemManager", "Client_UseItemResult_RPC failed! ItemConfig nil, ExcelID:%d", ExcelID)
            return
        end
        AddUseItemRecord(self, ExcelID, UseTime)
        OnUseItemCallback(self, ExcelID, Count, UseTime)
    else
        TipsUtil.ShowCommonTips(ITEM_USE_CD_MSG)
    end
end

---@param NewItems TArray<FBPS_NewItem>
---@return void
function BP_ItemManager:Client_NewItems_RPC(NewItems)
    if UE.UKismetSystemLibrary.IsServer(self) then
        return
    end
    if NewItems == nil or NewItems:Length() <= 0 then
        G.log:warn("ItemManager", "Client_NewItems_RPC failed! NewItems Empty!")
        return
    end
    local ItemDatas = {}
    local NewDatasItems = {}
    for i = 1, NewItems:Length() do
        ---@type FBPS_NewItem
        local NewItem = NewItems:Get(i)
        local Item = {}
        Item.ID = NewItem.ExcelID
        Item.Number = NewItem.Count
        local ItemConfig = ItemUtil.GetItemConfigByExcelID(NewItem.ExcelID)
        if ItemConfig == nil then
            G.log:warn("ItemManager", "Client_NewItems_RPC cannot find itemconfig! %d", NewItem.ExcelID)
        else
            Item.Name = ConstText.GetConstText(ItemConfig.name)
            Item.IconResourceObject = PicText.GetPicResource(ItemConfig.icon_reference)
            Item.Quality = ItemConfig.quality
            if NewItem.bNew then
                table.insert(NewDatasItems, Item)
            else
                table.insert(ItemDatas, Item)
            end
        end
    end
    if #ItemDatas > 0 then
        local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
        local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
        ---@type HudMessageCenter
        local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
        HudMessageCenterVM:PushItemList(ItemDatas)
    end
    if #NewDatasItems > 0 then
        local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
        local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
        ---@type HudMessageCenter
        local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
        HudMessageCenterVM:PushNewItemList(NewDatasItems)
    end
end

---@param TabIndex integer
---@return void
function BP_ItemManager:Client_BagTabFull_RPC(TabIndex)
    if UE.UKismetSystemLibrary.IsServer(self) then
        return
    end
    TipsUtil.ShowCommonTips(ITEM_BAG_FULL_MSG)
end

---Server Client
---@param self BP_ItemManager
---@param TabIndex integer
---@param bRedDot boolean
local function SetTabRedDot(self, TabIndex, bRedDot)
    local bFound = false
    for i = 1, self.BagTabDatas:Length() do
        ---@type FBPS_BagTab
        local BagTabData = self.BagTabDatas:GetRef(i)
        if BagTabData.TabIndex == TabIndex then
            BagTabData.bHasRedDot = bRedDot
            bFound = true
            break
        end
    end
    if not bFound then
        local BagTabData = CreateBagTabData(self, TabIndex)
        BagTabData.bHasRedDot = bRedDot
        self.BagTabDatas:Add(BagTabData)
    end
end


---@param TabIndex integer
---@return void
function BP_ItemManager:Client_TabRedDot_RPC(TabIndex)
    if UE.UKismetSystemLibrary.IsServer(self) then
        return
    end
    if not ItemUtil.IsBagTabExist(TabIndex) then
        G.log:warn("ItemManager", "Client_TabRedDot_RPC failed! Cannot find TabIndex Config!TabIndex: %d", TabIndex)
        return
    end
    SetTabRedDot(self, TabIndex, true)
    OnTabNewRedDotCallback(self, TabIndex)
end

---@param self BP_ItemManager
---@param TabIndex integer
local function SetItemsNotNewByTabIndex(self, TabIndex)
    if self.AllTabItems:Find(TabIndex) == nil then
        return
    end
    local BPS_TabItems = self.AllTabItems:FindRef(TabIndex)
    ---@type TMap<integer, FBPS_ItemBase>
    local TabItems = BPS_TabItems.TabItems:ToTable()

    for _, Item in pairs(TabItems) do
        if Item.bNew then
            local ItemConfig = ItemUtil.GetItemConfigByExcelID(Item.ExcelID)
            if ItemConfig.disappear_rule == nil or ItemConfig.disappear_rule == NEW_DISAPPEAR_RULE.LEAVE_TAB then
                SetItemNew(self, Item, false)
            end
        end
    end
end

---Server Client
---@param self BP_ItemManager
---@param OldTabIndex integer
---@param NewTabIndex integer
local function ChangeBagTab(self, OldTabIndex, NewTabIndex)
    if OldTabIndex ~= nil and OldTabIndex > 0 then
        SetItemsNotNewByTabIndex(self, OldTabIndex)
        SetTabRedDot(self, OldTabIndex, false)
    end
    if NewTabIndex ~= nil and NewTabIndex > 0 then
        SetTabRedDot(self, NewTabIndex, false)
    end
end

---Client
---@param OldTabIndex integer
---@param NewTabIndex integer
function BP_ItemManager:ChangeBagTab(OldTabIndex, NewTabIndex)
    if UE.UKismetSystemLibrary.IsServer(self) then
        return
    end
    ChangeBagTab(self, OldTabIndex, NewTabIndex)
    self:Server_ChangeBagTab(OldTabIndex, NewTabIndex)
end

---@param OldTabIndex integer
---@param NewTabIndex integer
---@return void
function BP_ItemManager:Server_ChangeBagTab_RPC(OldTabIndex, NewTabIndex)
    ChangeBagTab(self, OldTabIndex, NewTabIndex)
end

---Server
---@param self BP_ItemManager
---@param ExcelID integer
---@param Count integer
---@param AddItems TArray<FBPS_ItemBase>
local function AddItemByExcelID(self, ExcelID, Count, AddItems)
    local NewItem = CreateItem(self, ExcelID, Count)
    AddItem(self, NewItem)
    AddItems:Add(NewItem)
end

---Server
---@param self BP_ItemManager
---@param ExcelID integer
---@param Count integer
---@param StackLimit integer
---@param AddItems TArray<FBPS_ItemBase>
local function AddStackItems(self, ExcelID, Count, StackLimit, AddItems)
    local RemainCount = Count
    for i = 1, Count/StackLimit + 1 do
        if RemainCount > 0 then
            local StackCount = math.min(RemainCount, StackLimit)
            RemainCount = RemainCount - StackCount
            AddItemByExcelID(self, ExcelID, StackCount, AddItems)
        end
    end
end

---Server
---@param self BP_ItemManager
---@param SameItems FBPS_ItemBase[]
---@param AllCount integer
---@param StackLimit integer
---@param UpdateItems TArray<FBPS_ItemBase>
---@return integer
local function FillItemCountToStackLimit(self, SameItems, AllCount, StackLimit, UpdateItems)
    local RemainAddItemCount = AllCount
    for _, Item in pairs(SameItems) do
        if Item.StackCount < StackLimit then
            local AddCount = math.min(RemainAddItemCount, StackLimit - Item.StackCount)
            AddItemStack(self, Item, AddCount)
            UpdateItems:Add(Item)
            RemainAddItemCount = RemainAddItemCount - AddCount
            if RemainAddItemCount <= 0 then
                break
            end
        end
    end
    return RemainAddItemCount
end

---Server
---@param self BP_ItemManager
--TODO 这里可能会有问题，背包达上限，道具直接丢失了
local function CanAddToBagTab(self, ExcelID, Count)
    local ItemConfig = ItemUtil.GetItemConfigByExcelID(ExcelID)
    local TotalAddCount = math.ceil(Count * 1.0 / ItemConfig.stack_limit)
    local TabIndex = ItemUtil.GetItemTabIndex(ExcelID)
    local CurrentCount, Capacity = self:GetCapacityByTabID(TabIndex)
    if CurrentCount + TotalAddCount > Capacity then
        G.log:info("ItemManager","CanAddToBagTab failed, bag full! ExcelID:%d, Count:%d", ExcelID, Count)
        self:Client_BagTabFull(TabIndex)
        return false
    end
    return true
end



---Server
---@param self BP_ItemManager
---@param ExcelID integer
---@param Count integer
local function SendNewItem(self, ExcelID, Count)
    local BPS_NewItemStruct = Struct.BPS_NewItem
    local NewItems = UE.TArray(BPS_NewItemStruct)
    local bNew = false
    if not IsItemUnlock(self, ExcelID) then
        bNew = true
        UnlockItem(self, ExcelID)
    end

    if not IsItemAutoUse(ExcelID) then
        ---@type FBPS_NewItem
        local NewItem = BPS_NewItemStruct()
        NewItem.ExcelID = ExcelID
        NewItem.Count = Count
        NewItem.bNew = bNew
        NewItems:Add(NewItem)
        self:Client_NewItems(NewItems)
    end
end

---Server
---@param ExcelID integer
---@param Count integer
---@return integer 失败返回-1，成功返回实际增加数量
--TODO 补充新增道具来源流水
function BP_ItemManager:AddItemByExcelID(ExcelID, Count)
    if not UE.UKismetSystemLibrary.IsServer(self) then
        return FAILED
    end
    if ExcelID == nil or ExcelID <= 0 or Count == nil or Count <= 0 then
        G.log:warn("ItemManager", "AddItemByExcelID failed! ExcelID: %d, Count: %d", ExcelID, Count)
        return FAILED
    end
    local ItemConfig = ItemUtil.GetItemConfigByExcelID(ExcelID)
    if ItemConfig == nil then
        G.log:warn("ItemManager", "AddItemByExcelID failed! ItemConfig nil, ExcelID: %d", ExcelID)
        return FAILED
    end

    local bAutoUse = IsItemAutoUse(ExcelID)

    if (not bAutoUse) and not CanAddToBagTab(self, ExcelID, Count) then
        return FAILED
    end

    if ItemConfig.limit ~= nil then
        local CurrentCount = self:GetItemCountByExcelID(ExcelID)
        if CurrentCount >= ItemConfig.limit then
            return FAILED
        end
        if CurrentCount + Count > ItemConfig.limit then
            Count = ItemConfig.limit - CurrentCount
        end
    end
    
    if not bAutoUse and ItemConfig.appear_rule == ItemBaseTable.Redpoint then
        local TabIndex = ItemUtil.GetItemTabIndex(ExcelID)
        SetTabRedDot(self, TabIndex, true)
        self:Client_TabRedDot(TabIndex)
    end

    local BPS_ItemBaseStruct = Struct.BPS_ItemBase
    local AddItems = UE.TArray(BPS_ItemBaseStruct)
    local UpdateItems = UE.TArray(BPS_ItemBaseStruct)
    if ItemConfig.stack_limit == nil or ItemConfig.stack_limit <= 1 then
        for i = 1, Count do
            AddItemByExcelID(self, ExcelID, 1, AddItems)
        end
    else
        local Items = self:GetItemsByExcelID(ExcelID)
        if #Items == 0 then
            AddStackItems(self, ExcelID, Count, ItemConfig.stack_limit, AddItems)
        else
            local RemainAddItemCount = FillItemCountToStackLimit(self, Items, Count, ItemConfig.stack_limit, UpdateItems)
            if RemainAddItemCount > 0 then
                AddStackItems(self, ExcelID, RemainAddItemCount, ItemConfig.stack_limit, AddItems)
            end
        end
    end

    if not bAutoUse then
        if AddItems:Length() > 0 then
            self:Client_AddItems(AddItems)
        end
        if UpdateItems:Length() > 0 then
            self:Client_UpdateItems(UpdateItems)
        end
    end

    SendNewItem(self, ExcelID, Count)
    G.log:info("ItemManager","AddItemByExcelID, ExcelID:%d, Count:%d", ExcelID, Count)

    if bAutoUse then
        G.log:info("ItemManager","ItemType, ExcelID:%d, is auto use", ExcelID)
        self:UseItemByExcelID(ExcelID, Count)
    end
    return Count
end

---Server Client
---@param ExcelID integer
---@param Count integer
---@return boolean
function BP_ItemManager:IsItemEnough(ExcelID, Count)
    local CurrentCount = self:GetItemCountByExcelID(ExcelID)
    return CurrentCount >= Count
end

---Server
---使用前需要先检查道具数量是否足够：BP_ItemManager:IsItemEnough(ExcelID, Count)
---@param ExcelID integer
---@param Count integer
function BP_ItemManager:ReduceItemByExcelID(ExcelID, Count)
    if not UE.UKismetSystemLibrary.IsServer(self) then
        return
    end
    local Items = self:GetItemsByExcelID(ExcelID)
    table.sort(Items, function(ItemA, ItemB) return ItemA.StackCount < ItemB.StackCount end)
    local NeedReduceCount = Count
    local RemoveItemIDs = UE.TArray(UE.FInt)
    local BPS_ItemBaseStruct = Struct.BPS_ItemBase
    local UpdateItems = UE.TArray(BPS_ItemBaseStruct)
    for _, Item in pairs(Items) do
        local UniqueID = Item.UniqueID
        if Item.StackCount <= NeedReduceCount then
            RemoveItemByUniqueID(self, UniqueID)
            RemoveItemIDs:Add(UniqueID)
            NeedReduceCount = NeedReduceCount - Item.StackCount
            if NeedReduceCount <= 0 then
                break
            end
        else
            ReduceItemStack(self, Item, NeedReduceCount)
            NeedReduceCount = 0
            UpdateItems:Add(Item)
            break
        end
    end
    local ReduceCount = Count
    if NeedReduceCount > 0 then
        ReduceCount = Count - NeedReduceCount
    end
    if not IsItemAutoUse(ExcelID) then
        if RemoveItemIDs:Length() > 0 then
            self:Client_RemoveItems(RemoveItemIDs)
        end
        if UpdateItems:Length() > 0 then
            self:Client_UpdateItems(UpdateItems)
        end
    end
    G.log:info("ItemManager","ReduceItemByExcelID, ExcelID:%d, Count:%d", ExcelID, Count, ReduceCount)
    return
end

---@param ItemInfo table<integer, integer> ExcelID, Count
---@return boolean
local function CheckItemInfo(ItemInfo)
    if not ItemInfo then
        return false
    end
    local bHasInfo = false
    local bValid = true
    for ExcelID, Count in pairs(ItemInfo) do
        bHasInfo = true
        if not ItemUtil.GetItemConfigByExcelID(ExcelID) then
            G.log:warn("ItemManager", "Check ItemInfo failed! ExcelID invalid: ExcelID: %d", ExcelID)
            bValid = false
        end
        if Count <= 0 then
            G.log:warn("ItemManager", "Check ItemInfo failed! Count invalid: ExcelID: %d, Count: %d", ExcelID, Count)
            bValid = false
        end
    end
    return bHasInfo and bValid
end

---Server
---批量增加道具，如果存在无效ID或Count，该方法不生效
---@param AddItemInfo table<integer, integer> ExcelID, Count
---@return boolean
function BP_ItemManager:AddItems(AddItemInfo)
    local CheckResult = CheckItemInfo(AddItemInfo)
    if not CheckResult then
        return false
    end
    for ExcelID, Count in pairs(AddItemInfo) do
        self:AddItemByExcelID(ExcelID, Count)
    end
    return true
end

---Server
---批量扣除道具，如果存在无效ID或Count，或者道具不足，该方法不生效
---@param ReduceItemInfo table<integer, integer> ExcelID, Count
---@return boolean
function BP_ItemManager:ReduceItems(ReduceItemInfo)
    local CheckResult = CheckItemInfo(ReduceItemInfo)
    if not CheckResult then
        return false
    end
    local ItemEnough = true
    for ExcelID, Count in pairs(ReduceItemInfo) do
        if not self:IsItemEnough(ExcelID, Count) then
            G.log:warn("ItemManager", "ReduceItems failed! The number of items is not enough, ExcelID: %d, Count: d%", ExcelID, Count)
            ItemEnough = false
        end
    end
    if not ItemEnough then
        return false
    end
    for ExcelID, Count in pairs(ReduceItemInfo) do
        self:ReduceItemByExcelID(ExcelID, Count)
    end
    return true
end

---Server Client
---@param UniqueID integer
---@return FBPS_ItemBase, integer @Item, @TabIndex
function BP_ItemManager:GetItemByUniqueID(UniqueID)
    local alltabitems = self.AllTabItems:ToTable()
    for TabIndex, BPS_TabItems in pairs(alltabitems) do
        local TabItems = BPS_TabItems.TabItems:ToTable()
        if TabItems[UniqueID] then
            return TabItems[UniqueID], TabIndex
        end
    end
    return nil, nil
end

---Server Client
---@param ExcelID integer
---@return FBPS_ItemBase[]
function BP_ItemManager:GetItemsByExcelID(ExcelID)
    local Items = {}

    local TabIndex = ItemUtil.GetItemTabIndex(ExcelID)
    if self.AllTabItems:Find(TabIndex) == nil then
        return Items
    end
    ---@type FBPS_BagTabItems
    local BPS_TabItems = self.AllTabItems:FindRef(TabIndex)
    local TabItems = BPS_TabItems.TabItems:ToTable()
    for _, Item in pairs(TabItems) do
        if Item.ExcelID == ExcelID then
            table.insert(Items, Item)
        end
    end

    return Items
end

---Server Client
---@param ExcelID integer
---@return integer
function BP_ItemManager:GetItemCountByExcelID(ExcelID)
    local Count = 0
    local TabIndex = ItemUtil.GetItemTabIndex(ExcelID)
    ---@type FBPS_BagTabItems
    local BPS_TabItems = self.AllTabItems:FindRef(TabIndex)
    if BPS_TabItems == nil then
        return Count
    end
    local TabItems = BPS_TabItems.TabItems:ToTable()
    for _, Item in pairs(TabItems) do
        if Item.ExcelID == ExcelID then
            Count = Count + Item.StackCount
        end
    end
    return Count
end

---Server Client
---@param CategoryID integer
---@return FBPS_ItemBase[]
function BP_ItemManager:GetItemsByCategoryID(CategoryID)
    local Items = {}
    local TabIndex = ItemUtil.GetItemTabIndexByCategory(CategoryID)
    if self.AllTabItems:Find(TabIndex) == nil then
        return Items
    end
    ---@type FBPS_BagTabItems
    local BPS_TabItems = self.AllTabItems:FindRef(TabIndex)
    local TabItems = BPS_TabItems.TabItems:ToTable()
    for _, Item in pairs(TabItems) do
        local ItemCategory = ItemUtil.GetItemCategory(Item.ExcelID)
        if ItemCategory == CategoryID then
            table.insert(Items, Item)
        end
    end

    return Items
end

---Server Client
---@param TabIndex integer
---@return FBPS_ItemBase[]
function BP_ItemManager:GetItemsByTabID(TabIndex)
    local Items = {}
    if self.AllTabItems:Find(TabIndex) == nil then
        return Items
    end
    ---@type FBPS_BagTabItems
    local BPS_TabItems = self.AllTabItems:FindRef(TabIndex)
    local TabItems = BPS_TabItems.TabItems:ToTable()
    for _, Item in pairs(TabItems) do
        table.insert(Items, Item)
    end
    return Items
end

---Server Client
---@param TabIndex integer
---@return integer, integer @CurrentCount, @Capacity
function BP_ItemManager:GetCapacityByTabID(TabIndex)
    local BaseCapacity = ItemUtil.GetBagTabBaseCapacity(TabIndex)
    local CurrentCount = 0
    local Capacity = BaseCapacity
    for i = 1, self.BagTabDatas:Length() do
        ---@type FBPS_BagTab
        local BagTabData = self.BagTabDatas:GetRef(i)
        if BagTabData.TabIndex == TabIndex then
            Capacity = BaseCapacity + BagTabData.ExtraCapacity
            break
        end
    end
    ---@type FBPS_BagTabItems
    local BPS_TabItems = self.AllTabItems:Find(TabIndex)
    if BPS_TabItems ~= nil then
        CurrentCount = BPS_TabItems.TabItems:Length()
    end
    return CurrentCount, Capacity
end

---Server Client
---@param UniqueID integer
---@return ItemConfig
function BP_ItemManager:GetItemConfigByUniqueID(UniqueID)
    local Item = self:GetItemByUniqueID(UniqueID)
    if Item == nil then
        G.log:warn("ItemManager", "GetItemConfigByUniqueID failed! %d", UniqueID)
        return nil
    end
    return ItemUtil.GetItemConfigByExcelID(Item.ExcelID)
end

---Server Client
---@param UniqueID integer
---@return integer
function BP_ItemManager:GetItemCategoryByUniqueID(UniqueID)
    local Item = self:GetItemByUniqueID(UniqueID)
    if Item == nil then
        G.log:warn("ItemManager", "GetItemCategoryByUniqueID failed! %d", UniqueID)
        return nil
    end
    return ItemUtil.GetItemCategory(Item.ExcelID)
end

---Server Client
---@param TabIndex integer
---@return boolean
function BP_ItemManager:IsTabRedFlag(TabIndex)
    for i = 1, self.BagTabDatas:Length() do
        ---@type FBPS_BagTab
        local BagTabData = self.BagTabDatas:Get(i)
        if BagTabData.TabIndex == TabIndex then
            return BagTabData.bHasRedDot
        end
    end
    return false
end

---Client
---@param UniqueID integer
function BP_ItemManager:SetItemsNotNewByItemID(UniqueID)
    if UE.UKismetSystemLibrary.IsServer(self) then
        return
    end

    local Item, _ = self:GetItemByUniqueID(UniqueID)
    if Item == nil then
        G.log:warn("ItemManager", "SetItemsNotNewByItemID failed! %d", UniqueID)
        return
    end
    if Item.bNew then
        SetItemNew(self, Item, false)
        local IDs = UE.TArray(UE.FInt)
        IDs:Add(UniqueID)
        self:Server_SetItemsNotNew(IDs)
    end
end

---Server Client
---@param ExcelID integer
---@return integer
function BP_ItemManager:GetItemUseCD(ExcelID)
    local LastUseTime = self.ItemUseTimeRecords[ExcelID]
    if LastUseTime == nil then
        return 0
    end
    local ItemConfig = ItemUtil.GetItemConfigByExcelID(ExcelID)
    if ItemConfig == nil then
        G.log:warn("ItemManager", "GetItemUseCD failed! ItemConfig nil, ExcelID: %d", ExcelID)
        return 0
    end
    if ItemConfig.use_CD_seconds == nil or ItemConfig.use_CD_seconds == 0 then
        return 0
    end
    local Now = UE.UHiUtilsFunctionLibrary.GetNowTimestamp()
    if LastUseTime + ItemConfig.use_CD_seconds < Now then
        return 0
    else
        return LastUseTime + ItemConfig.use_CD_seconds - Now
    end
end

---Server Client
---@param TabIndex integer
---@return boolean
function BP_ItemManager:IsBagTabFull(TabIndex)
    local CurrentCount, Capacity = self:GetCapacityByTabID(TabIndex)
    return CurrentCount < Capacity
end

---Server Client
---@param Owner UObject
---@param CallBack AddItemCallbackT
function BP_ItemManager:RegAddItemCallBack(Owner, CallBack)
    self.AddItemCallbacks[Owner] = CallBack
end

---Server Client
---@param Owner UObject
---@param CallBack AddItemCallbackT
function BP_ItemManager:UnRegAddItemCallBack(Owner, CallBack)
    self.AddItemCallbacks[Owner] = nil
end

---Server Client
---@param Owner UObject
---@param CallBack RemoveItemCallbackT
function BP_ItemManager:RegRemoveItemCallBack(Owner, CallBack)
    self.RemoveItemCallbacks[Owner] = CallBack
end

---Server Client
---@param Owner UObject
---@param CallBack RemoveItemCallbackT
function BP_ItemManager:UnRegRemoveItemCallBack(Owner, CallBack)
    self.RemoveItemCallbacks[Owner] = nil
end

---Server Client
---@param Owner UObject
---@param CallBack UpdateItemCallbackT
function BP_ItemManager:RegUpdateItemCallBack(Owner, CallBack)
    self.UpdateItemCallbacks[Owner] = CallBack
end

---Server Client
---@param Owner UObject
---@param CallBack UpdateItemCallbackT
function BP_ItemManager:UnRegUpdateItemCallBack(Owner, CallBack)
    self.UpdateItemCallbacks[Owner] = nil
end

---Server Client
---@param Owner UObject
---@param CallBack BagCapacityChangeCallbackT
function BP_ItemManager:RegBagCapacityChangeCallBack(Owner, CallBack)
    self.BagCapacityChangeCallbacks[Owner] = CallBack
end

---Server Client
---@param Owner UObject
---@param CallBack BagCapacityChangeCallbackT
function BP_ItemManager:UnRegBagCapacityChangeCallBack(Owner, CallBack)
    self.BagCapacityChangeCallbacks[Owner] = nil
end

---Server Client
---@param Owner UObject
---@param CallBack UseItemCallbackT
function BP_ItemManager:RegUseItemCallBack(Owner, CallBack)
    self.UseItemCallbacks[Owner] = CallBack
end

---Server Client
---@param Owner UObject
---@param CallBack UseItemCallbackT
function BP_ItemManager:UnRegUseItemCallBack(Owner, CallBack)
    self.UseItemCallbacks[Owner] = nil
end

---Server Client
---@param Owner UObject
---@param CallBack TabNewRedDotCallbackT
function BP_ItemManager:RegTabNewRedDotCallBack(Owner, CallBack)
    self.TabNewRedDotCallbacks[Owner] = CallBack
end

---Server Client
---@param Owner UObject
---@param CallBack TabNewRedDotCallbackT
function BP_ItemManager:UnRegTabNewRedDotCallBack(Owner, CallBack)
    self.TabNewRedDotCallbacks[Owner] = nil
end

return BP_ItemManager
