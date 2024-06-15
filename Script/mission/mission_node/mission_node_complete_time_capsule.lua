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


---@type BP_MissionNode_CompleteTimeCapsule_C
local MissionNodeCompleteTimeCapsule = Class(MissionNodeBase)

function MissionNodeCompleteTimeCapsule:K2_InitializeInstance()
    Super(MissionNodeCompleteTimeCapsule).K2_InitializeInstance(self)
    local ActionClass = EdUtils:GetUE5ObjectClass(BPConst.MissionActionCompleteTimeCapsule)
    if ActionClass then
        local Action = NewObject(ActionClass)
        Action.Name = self.ActionName
        Action.TargetActorID = self.Ref.ID
        self:RegisterAction(Action)
    end
end

function MissionNodeCompleteTimeCapsule:K2_ExecuteInput(PinName)
    Super(MissionNodeCompleteTimeCapsule).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.SuccessPin, false, false)

    UE.UHiMissionAction_Base.RunMissionActionByName(self, self.ActionName)

    self:TriggerOutput(self.CompletePin, true, false)
end


return MissionNodeCompleteTimeCapsule