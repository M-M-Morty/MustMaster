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


---@type BP_MissionNode_StopCharactersMontage_C
local MissionNodeStopCharactersMontage = Class(MissionNodeBase)


function MissionNodeStopCharactersMontage:K2_InitializeInstance()
    Super(MissionNodeStopCharactersMontage).K2_InitializeInstance(self)
    self.StopActionName = "StopMontage"
    local ActionClass = EdUtils:GetUE5ObjectClass(BPConst.MissionActionStopMontage)
    if ActionClass then
        local Action = NewObject(ActionClass)
        Action.Name = self.StopActionName

        for i = 1, self.Characters:Length() do
            local Character = self.Characters:GetRef(i)
            Action.TargetActorIDList:Add(Character.ID)
        end
        self:RegisterAction(Action)
    end
end

function MissionNodeStopCharactersMontage:K2_ExecuteInput(PinName)
    Super(MissionNodeStopCharactersMontage).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.Success_Pin, false, false)
    UE.UHiMissionAction_Base.RunMissionActionByName(self, self.StopActionName)
    self:TriggerOutput(self.Complete_Pin, true, false)
end


return MissionNodeStopCharactersMontage