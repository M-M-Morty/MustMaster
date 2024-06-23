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
local IsNormalMonster = Class(BaseNode)

function IsNormalMonster:CanEnterTransition()
    local Blackboard = self:GetBlackBoard()    
    --G.log:info("hycoldrain", "IsNormalMonster:CanEnterTransition %s %s", self:GetNodeName(), tostring(Blackboard.EnemyActor))
    if Blackboard.EnemyActor and Blackboard.EnemyActor:IsValid() then
        return Blackboard.EnemyActor.MonsterType == Enum.Enum_MonsterType.Normal
    end
    return false;
end

return IsNormalMonster