--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"
local ActorBase = require("actors.common.interactable.base.base_item")

---@type BP_BabelFragment_C
local M = Class(ActorBase)

function M:AddItemByServer(player)
    if self:HasAuthority() then
        local ItemManager = player.PlayerState:GetPlayerController().ItemManager
        ItemManager:AddItemByExcelID(self.ItemID, self.ItemNum)
    end
end


return M
