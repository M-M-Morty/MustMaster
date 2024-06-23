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
    self:TriggerOutput(self.SuccessPin, false, false)
    self:DestroyMutableActorByTag(self.Tag)
    self:TriggerOutput(self.DestroyPin, true, false)
end


return MissionNodeDestroyActor