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

---@type IsEnemyDead_C
local IsEnemyDead = Class(BaseNode)

function IsEnemyDead:CanEnterTransition()
    local Blackboard = self:GetBlackBoard()    
    --G.log:info("hycoldrain", "IsNormalMonster:CanEnterTransition %s %s", self:GetNodeName(), tostring(Blackboard.EnemyActor))
    if Blackboard.EnemyActor and Blackboard.EnemyActor:IsValid() then
        return Blackboard.EnemyActor:IsDead()
    end
    return false;
end

return IsEnemyDead