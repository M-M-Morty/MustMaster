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


---@type BP_MissionNode_DestroyActor_C
local MissionNodeDestroyActor = Class(MissionNodeBase)

function MissionNodeDestroyActor:K2_ExecuteInput(PinName)
    Super(MissionNodeDestroyActor).K2_ExecuteInput(self, PinName)

    for _, Ref in pairs(self.Refs:ToTable()) do
	    local Actor = SubsystemUtils.GetMutableActorSubSystem(self):GetActor(Ref.ID)
	    if Actor then
    		Actor:K2_DestroyActor()
    	end
    end

	self:TriggerOutput(self.SuccessPin, true, false)
end


return MissionNodeDestroyActor