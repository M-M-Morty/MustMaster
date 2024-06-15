local G = require("G")
local ItemBaseTable = require("common.data.item_base_data").data
local ItemBaseDef = require("common.data.item_base_data")
local SubsystemUtils = require("common.utils.subsystem_utils")

local ItemEffectUtils = {
    ItemEffectHandler = {},         -- 道具效果处理函数
    ItemFailedEffectHandler = {}    -- 道具使用失败处理函数
}

function ItemEffectUtils:RegisterItemEffect(UseType, Handler)
    if not self.ItemEffectHandler[UseType] then
        self.ItemEffectHandler[UseType] = {}
    end
    table.insert(self.ItemEffectHandler[UseType], Handler)
end

function ItemEffectUtils:RegisterItemFailedEffect(UseType, Handler)
    if not self.ItemFailedEffectHandler[UseType] then
        self.ItemFailedEffectHandler[UseType] = {}
    end
    table.insert(self.ItemFailedEffectHandler[UseType], Handler)
end

function ItemEffectUtils:UnregisterItemEffect(UseType, Handler)
    if not self.ItemEffectHandler[UseType] then
        return
    end

    for i in 1, #self.ItemEffectHandler do
        if self.ItemEffectHandler[i] == Handler then
            table.remove(self.ItemEffectHandler, i)
            return
        end
    end
end

function ItemEffectUtils:UnregisterItemFailedEffect(UseType, Handler)
    if not self.ItemFailedEffectHandler[UseType] then
        return
    end

    for i in 1, #self.ItemFailedEffectHandler do
        if self.ItemFailedEffectHandler[i] == Handler then
            table.remove(self.ItemFailedEffectHandler, i)
            return
        end
    end
end

-- server
function ItemEffectUtils:UseItemEffect(User, ItemId, ItemNum, Target)
    local ItemBaseData = ItemBaseTable[ItemId]
    if not ItemBaseData then
        G.log:warn("ItemEffectUtils:UseItemEffect", "ItemId(%s) not in data table")
        return
    end
    local UseType = ItemBaseData.item_use_type
    local UseParam = ItemBaseData.item_use_details

    if not UseType then
        return
    end
    
    G.log:debug("ItemEffectUtils", "UseItemEffect, User:%s, ItemID:%s, ItemNum:%s, Target:%s", User, ItemId, ItemNum, Target)
    -- 根据UseType进入不同的处理流程
    local HandlerList = self.ItemEffectHandler[UseType]
    if not HandlerList then
        return
    end
    local ExtraData = {
        ItemId = ItemId,
        ItemNum = ItemNum
    }
    for _, Handler in ipairs(HandlerList) do
        Handler(User, Target, UseParam, ExtraData)
    end
end

-- server
function ItemEffectUtils:UseItemFailedEffect(User, ItemId)
    local ItemBaseData = ItemBaseTable[ItemId]
    if not ItemBaseData then
        G.log:warn("ItemEffectUtils:UseItemFailedEffect", "ItemId(%s) not in data table")
        return
    end
    local UseType = ItemBaseData.item_use_type

    if not UseType then
        return
    end
    
    G.log:debug("ItemEffectUtils", "UseItemFailedEffect, User:%s, ItemID:%s", User, ItemId)
    -- 根据UseType进入不同的处理流程
    local HandlerList = self.ItemFailedEffectHandler[UseType]
    if not HandlerList then
        return
    end
    for _, Handler in ipairs(HandlerList) do
        Handler(User)
    end
end

return ItemEffectUtils
