--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")
local EdUtils = require("common.utils.ed_utils")
local BPConst = require("common.const.blueprint_const")

local MissionNodeBase = require("mission.mission_node.mission_node_base")


local MissionNodeTriggerBossBattle = Class(MissionNodeBase)

function MissionNodeTriggerBossBattle:K2_InitializeInstance()
    Super(MissionNodeTriggerBossBattle).K2_InitializeInstance(self)
end

function MissionNodeTriggerBossBattle:K2_ExecuteInput(PinName)
    Super(MissionNodeTriggerBossBattle).K2_ExecuteInput(self, PinName)

	local Boss = utils.GetBoss()
	Boss:SendMessage("EnterBattleByFlowGraph")
    
    self:TriggerOutput(self.SuccessPin, true, false)
end


return MissionNodeTriggerBossBattle