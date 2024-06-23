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
    --G.log:info("hycoldrain", "BattleCheck:CanEnterTransition %s %s", tostring(self.bNegate), tostring(Backboard.bInBattle))
    if self.bNegate then
        return not Backboard.bInStory
    else
        return Backboard.bInStory
    end
end

return BattleCheck