--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"
local ActorBase = require("actors.common.interactable.base.interacted_item")

---@type BP_Interacted_GainItem_C
local M = Class(ActorBase)

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
        local ItemManager = playerActor.PlayerState.ItemManager
        ItemManager:AddItemByExcelID(self.ItemID, self.ItemNum)
    end
    Super(M).DoServerInteractAction(self, invoker, Damage, InteractLocation)
end

return M
