--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")

local MissionNodeBase = require("mission.mission_node.mission_node_base")


---@type BP_MissionNode_SetActState_C
local MissionNodeSetMissionActState = Class(MissionNodeBase)

function MissionNodeSetMissionActState:K2_ExecuteInput(PinName)
    Super(MissionNodeSetMissionActState).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.SuccessPin, false, false)

    self:GetDataComponent():SetMissionActState(self:GetMissionIdentifier(), self.NewActState)

    self:TriggerOutput(self.CompletePin, true, false)
end


return MissionNodeSetMissionActState