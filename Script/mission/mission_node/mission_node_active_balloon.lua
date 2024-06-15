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


local MissionNodeActiveBalloon = Class(MissionNodeBase)

function MissionNodeActiveBalloon:K2_InitializeInstance()
    Super(MissionNodeActiveBalloon).K2_InitializeInstance(self)
end

function MissionNodeActiveBalloon:K2_ExecuteInput(PinName)
    Super(MissionNodeActiveBalloon).K2_ExecuteInput(self, PinName)

    local SmallBalloon = SubsystemUtils.GetMutableActorSubSystem(self):GetActor(self.Ref.ID)
    local Player = G.GetPlayerCharacter(self, 0)
    if SmallBalloon and SmallBalloon:ActiveByFlowGraph(Player) then
	    self:TriggerOutput(self.SuccessPin, true, false)
	end
end


return MissionNodeActiveBalloon