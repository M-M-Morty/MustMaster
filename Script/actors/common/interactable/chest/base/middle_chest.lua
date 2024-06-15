--
-- DESCRIPTION
--
-- @COMPANY tencent
-- @AUTHOR dougzhang
-- @DATE 2023/05/15
--

---@type

require "UnLua"
local G = require("G")
local ActorBase = require("actors.common.interactable.chest.base.base_chest")

local M = Class(ActorBase)


function M:Initialize(...)
    Super(M).Initialize(self, ...)
end

function M:ReceiveBeginPlay()
    Super(M).ReceiveBeginPlay(self)
end

function M:ReceiveEndPlay()
    Super(M).ReceiveEndPlay(self)
end

return M