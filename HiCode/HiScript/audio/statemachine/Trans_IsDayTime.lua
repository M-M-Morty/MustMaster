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
local Trans_IsDayTime = Class(BaseNode)

function Trans_IsDayTime:CanEnterTransition()
    local Backboard = self:GetBlackBoard()    
    --G.log:info("hycoldrain", "BattleCheck:CanEnterTransition %s %s", tostring(self.bNegate), tostring(Backboard.bInBattle))
    if self.bNegate then
        return not Backboard.bDayTime
    else
        return Backboard.bDayTime
    end
end

return Trans_IsDayTime