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

---@type IsBossMonster
local IsBossMonster = Class(BaseNode)

function IsBossMonster:CanEnterTransition()
    local Blackboard = self:GetBlackBoard()    
    --G.log:info("hycoldrain", "IsBossMonster:CanEnterTransition %s %s", self:GetNodeName(), tostring(Blackboard.EnemyActor))
    if Blackboard.EnemyActor and Blackboard.EnemyActor:IsValid() then
        return Blackboard.EnemyActor.MonsterType == Enum.Enum_MonsterType.Boss
    end
    return false;
end

return IsBossMonster