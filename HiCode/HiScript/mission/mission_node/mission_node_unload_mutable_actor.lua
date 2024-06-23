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


---@type BP_MissionNode_UnloadMutableActor_C
local MissionNodeUnloadMutableActor = Class(MissionNodeBase)

function MissionNodeUnloadMutableActor:K2_ExecuteInput(PinName)
    Super(MissionNodeUnloadMutableActor).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.Success_Pin, false, false)
    self.ActorIDList:Clear()

    for i = 1, self.TargetReferenceList:Length() do
      self.ActorIDList:Add(self.TargetReferenceList:Get(i).ID)
    end

    self:UnloadMutableActor(self.ActorIDList)
    self:TriggerOutput(self.Complete_Pin, true, false)
end


return MissionNodeUnloadMutableActor