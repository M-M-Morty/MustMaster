--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"
local G = require("G")

local BaseNode = require("audio.statemachine.BaseNode")

---@type S_Initial_C
local BattleCheck = Class(BaseNode)

function BattleCheck:CanEnterTransition()
    local Backboard = self:GetBlackBoard()    
    --G.log:info("hycoldrain", "BattleCheck:CanEnterTransition %s %s", self:GetNodeName(), tostring(Backboard.bInBattle))
    return Backboard.bInBattle
end

return BattleCheck