--
-- DESCRIPTION
--
-- @COMPANY Wuhan GHGame Studio
-- @AUTHOR Zhiyuan Li
--

local ItemUtil = {}

local BagTable = require("common.data.bag_data").data
local ItemBaseTable = require("common.data.item_base_data").data
local ItemCategoryTable = require("common.data.item_category_data").data
local ItemQualityTable = require("common.data.item_quality_data").data
local ItemDef = require("common.item.ItemDef")

---@class ItemConfig
---@field name string
---@field icon_reference string
---@field mini_icon_reference string
---@field category_ID integer
---@field quality integer
---@field stack_limit integer
---@field limit integer
---@field desc_ID string
---@field item_use_type integer
---@field item_use_details string[]
---@field appear_rule integer
---@field disappear_rule integer
---@field use_CD_seconds integer
---@field keep_after_use boolean

---@class ItemCategoryConfig
---@field category_name string
---@field sort integer

---@class ItemQualityConfig
---@field quality_name string
---@field color_value string
---@field icon_reference_small string
---@field icon_reference_big string
---@field detail_reference string
---@field tips_bg_reference string
---@field new_get_bg string
---@field normal_get_bg string

---@class BagConfig
---@field tab_name string
---@field tab_switch boolean
---@field tab_icon string
---@field capacity integer
---@field item_categories integer[]

local MaxID = 0


---生成道具UniqueID，实现是临时的
---@return integer
function ItemUtil.GenerateItemUniqueID()
    MaxID = MaxID + 1
    return MaxID
end

---@return table<integer, BagConfig>
function ItemUtil.GetAllBagTabConfigs()
    return BagTable
end

---@param TabIndex integer
---@return BagConfig
function ItemUtil.GetBagTabConfig(TabIndex)
    return BagTable[TabIndex]
end

function ItemUtil.IsBagTabExist(TabIndex)
    return BagTable[TabIndex] ~= nil
end

---@param ExcelID integer
---@return ItemConfig
function ItemUtil.GetItemConfigByExcelID(ExcelID)
    return ItemBaseTable[ExcelID]
end

---@return table<integer, ItemConfig>
function ItemUtil.GetAllItemConfig()
    return ItemBaseTable
end

---@param Category integer
---@return ItemCategoryConfig
function ItemUtil.GetItemCategoryConfig(Category)
    return ItemCategoryTable[Category]
end

---@param Quality integer
---@return ItemQualityConfig
function ItemUtil.GetItemQualityConfig(Quality)
    return ItemQualityTable[Quality]
end

---@param Quality integer
---@return FSlateColor
function ItemUtil.GetItemQualitySlateColor(Quality)
    local ItemQualityConfig = ItemUtil.GetItemQualityConfig(Quality)
    if ItemQualityConfig == nil then
        return nil
    end
    local hex = ItemQualityConfig.color_value
    local FColor = UE.FColor(tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6)))
    local Color = UE.FSlateColor()
    local LinearColor = FColor:ToLinearColor()
    Color.SpecifiedColor = LinearColor
    return Color
end

---@param ExcelID integer
---@return integer
function ItemUtil.GetItemCategory(ExcelID)
    local ItemConfig = ItemUtil.GetItemConfigByExcelID(ExcelID)
    return ItemConfig.category_ID
end

---@param ExcelID integer
---@return integer
function ItemUtil.GetItemQuality(ExcelID)
    local ItemConfig = ItemUtil.GetItemConfigByExcelID(ExcelID)
    return ItemConfig.quality
end

---@param ExcelID integer
---@return integer
function ItemUtil.GetItemTabIndex(ExcelID)
    local Category = ItemUtil.GetItemCategory(ExcelID)
    local TabConfigs = ItemUtil.GetAllBagTabConfigs()
    for TabIndex, BagConfig in pairs(TabConfigs) do
        if BagConfig.item_categories then
            for _, v in pairs(BagConfig.item_categories) do
                if v == Category then
                    return TabIndex
                end
            end
        end
    end
    -- 没有配置页签，默认隐藏
    return ItemDef.HideTabIndex
end

---@param Category integer
---@return integer
function ItemUtil.GetItemTabIndexByCategory(Category)
    local TabConfigs = ItemUtil.GetAllBagTabConfigs()
    for TabIndex, BagConfig in pairs(TabConfigs) do
        if BagConfig.item_categories then
            for _, v in pairs(BagConfig.item_categories) do
                if v == Category then
                    return TabIndex
                end
            end
        end
    end
    return -1
end

---@param TabIndex integer
---@return integer
function ItemUtil.GetBagTabBaseCapacity(TabIndex)
    if TabIndex == ItemDef.HideTabIndex then
        return 2^32 - 1
    end
    local TabConfig = ItemUtil.GetBagTabConfig(TabIndex)
    return TabConfig.capacity
end

---@param RewardList RewardList[]
---@return RewardList[]
function ItemUtil.ItemSortFunctionByList(RewardList)
    local tempList = {}
    for index, value in pairs(RewardList) do
        local propItem = {}
        local rewardItem = ItemUtil.GetItemConfigByExcelID(index)
        local rewardCategory = ItemUtil.GetItemCategoryConfig(rewardItem.category_ID)
        propItem.ID = index
        propItem.Number = value
        propItem.Quality = rewardItem.quality
        propItem.Sort = rewardCategory.sort
        table.insert(tempList, propItem)
    end
    table.sort(tempList, ItemUtil.RewardItemSortFunc)
    return tempList
end

---@return boolean
function ItemUtil.RewardItemSortFunc(ItemA, ItemB)
    if ItemA.Quality ~= ItemB.Quality then
        return ItemA.Quality > ItemB.Quality
    end
    if ItemA.Sort ~= ItemB.Sort then
        return ItemA.Sort < ItemB.Sort
    end
    return ItemA.ID < ItemB.ID
end

---@param ItemA FBPS_ItemBase
---@param ItemB FBPS_ItemBase
---@return boolean
function ItemUtil.ItemSortFunction(ItemA, ItemB)
    ---todo 判断 已装备>未装备
    local ItemConfigA = ItemUtil.GetItemConfigByExcelID(ItemA.ExcelID)
    local CategoryConfigA = ItemUtil.GetItemCategoryConfig(ItemConfigA.category_ID)
    local ItemConfigB = ItemUtil.GetItemConfigByExcelID(ItemB.ExcelID)
    local CategoryConfigB = ItemUtil.GetItemCategoryConfig(ItemConfigB.category_ID)
    if CategoryConfigA.sort ~= CategoryConfigB.sort then
        return CategoryConfigA.sort < CategoryConfigB.sort
    end
    if ItemConfigA.quality ~= ItemConfigB.quality then
        return ItemConfigA.quality > ItemConfigB.quality
    end
    if ItemA.ExcelID ~= ItemB.ExcelID then
        return ItemA.ExcelID < ItemB.ExcelID
    end
    if ItemA.StackCount ~= ItemB.StackCount then
        return ItemA.StackCount > ItemB.StackCount
    end
    return ItemA.UniqueID < ItemB.UniqueID
end

---在客户端获得ItemManager
---@param WorldContextObject UObject
---@return BP_ItemManager
function ItemUtil.GetItemManager(WorldContextObject)
    ---@type BP_PlayerController_C
    local BPPlayerController = UE.UGameplayStatics.GetPlayerController(WorldContextObject, 0)
    return BPPlayerController.PlayerState.ItemManager
end

---在客户端获得所有电话卡道具
---@param WorldContextObject UObject
---@return FBPS_ItemBase[]
function ItemUtil.GetAllPhoneCards(WorldContextObject)
    local ItemManager = ItemUtil.GetItemManager(WorldContextObject)
    local PhoneCards = {}
    local TaskItems = ItemManager:GetItemsByCategoryID(ItemDef.CATEGORY.TASK_ITEM)
    for _, v in ipairs(TaskItems) do
        local ItemConfig = ItemUtil.GetItemConfigByExcelID(v.ExcelID)
        if ItemConfig.item_use_type == ItemDef.ITEM_USE_TYPE.SHOW_PHONECARD then
            table.insert(PhoneCards, v)
        end
    end
    local SortFunction = function(ItemA, ItemB)
        return ItemA.ExcelID < ItemB.ExcelID
    end
    table.sort(PhoneCards, SortFunction)
    return PhoneCards
end

return ItemUtil