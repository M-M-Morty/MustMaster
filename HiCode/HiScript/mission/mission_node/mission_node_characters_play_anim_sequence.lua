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

---@type BP_MissionNode_CharactersPlayAnimSequence_C
local MissionNodeCharactersPlayAnimSequence = Class(MissionNodeBase)

function MissionNodeCharactersPlayAnimSequence:K2_InitializeInstance()
    Super(MissionNodeCharactersPlayAnimSequence).K2_InitializeInstance(self)
    self.PlayActionName = "Play"
    local ActionClass = EdUtils:GetUE5ObjectClass(BPConst.MissionActionPlayAnimSequence)
    if ActionClass then
        local Action = NewObject(ActionClass)
        Action.Name = self.PlayActionName
        Action.AnimSequ = self.AnimSeq
        Action.bLoop = self.bLoop

        for i = 1, self.Characters:Length() do
            local Character = self.Characters:GetRef(i)
            Action.TargetActorIDList:Add(Character.ID)
        end
        self:RegisterAction(Action)
    end
end

function MissionNodeCharactersPlayAnimSequence:K2_ExecuteInput(PinName)
    Super(MissionNodeCharactersPlayAnimSequence).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.Success_Pin, false, false)
    UE.UHiMissionAction_Base.RunMissionActionByName(self, self.PlayActionName)
    self:TriggerOutput(self.Complete_Pin, true, false)
end

return MissionNodeCharactersPlayAnimSequence