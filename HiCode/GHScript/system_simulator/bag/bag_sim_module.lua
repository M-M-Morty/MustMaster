--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')

local PlayerBag = {}
PlayerBag.BagItems = {}
PlayerBag.BagItemsChangedDelegate = {}
PlayerBag.Capacity = 50

function PlayerBag:AddItem(data)
    table.insert(self.BagItems, data)
    self:BroadcastBagItemChanged(data)
end

function PlayerBag:AddItems(arr)
    for _,v in pairs(arr) do
        table.insert(self.BagItems, v)
        self:BroadcastBagItemChanged(v)
    end
end

function PlayerBag:GetAllItems()
    return self.BagItems
end

function PlayerBag:DiscardItemByID(id)
    local count = TableUtil:ArrayRemoveIf(self.BagItems, function(item)
        if item.id == id then
            return true
        end
    end)
end

function PlayerBag:RegisterBagItemChanged(fncall)
    table.insert(self.BagItemsChangedDelegate, fncall)
end

function PlayerBag:BroadcastBagItemChanged(...)
    for k,func in pairs(self.BagItemsChangedDelegate) do
        func(...)
    end
end

return PlayerBag