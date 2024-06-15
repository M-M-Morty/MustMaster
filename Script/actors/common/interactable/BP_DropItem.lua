--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"
local ActorBase = require("actors.common.interactable.base.interacted_item")
local ItemBaseTable = require("common.data.item_base_data").data

---@type BP_DropItem_C
local M = Class(ActorBase)

function M:GetItemQuality(ItemID)
    if ItemBaseTable[ItemID] == nil then
        return 1;
    end
    return ItemBaseTable[ItemID].quality
end

function M:GetPlayerActor(OtherActor)
    if OtherActor.EdRuntimeComponent then
        return OtherActor
    end
end

-- called by ServerInteractEvent
---@param invoker AActor
function M:DoServerInteractAction(invoker, Damage, InteractLocation)
    if self:HasAuthority() and self:GetInteractable() then
        local playerActor = self:GetPlayerActor(invoker)
        local ItemManager = playerActor.PlayerState:GetPlayerController().ItemManager
        ItemManager:AddItemByExcelID(self.ItemID, self.ItemNum)
    end
    Super(M).DoServerInteractAction(self, invoker, Damage, InteractLocation)
end

return M
