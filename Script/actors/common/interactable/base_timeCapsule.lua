--
-- DESCRIPTION
--
-- @COMPANY tencent
-- @AUTHOR seekerma
-- @DATE 2023/08/02
--

---@type

require "UnLua"
local G = require("G")
local ActorBase = require("actors.common.interactable.base.interacted_item")

local M = Class(ActorBase)

function M:Initialize(...)
    Super(M).Initialize(self, ...)
end

function M:UserConstructionScript()
    Super(M).UserConstructionScript(self)
end

function M:ShowUI(playerActor)
    playerActor.EdRuntimeComponent:AddNearbyActor(self)
end

return M