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


---@type BP_MissionNode_LoadMutableActor_C
local MissionNodeLoadMutableActor = Class(MissionNodeBase)

function MissionNodeLoadMutableActor:K2_ExecuteInput(PinName)
    Super(MissionNodeLoadMutableActor).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.Success_Pin, false, false)
    self.ActorIDList:Clear()

    for i = 1, self.TargetReferenceList:Length() do
      self.ActorIDList:Add(self.TargetReferenceList:Get(i).ID)
    end

    self:LoadMutableActor(self.ActorIDList)
    self:TriggerOutput(self.Complete_Pin, true, false)
end


return MissionNodeLoadMutableActor