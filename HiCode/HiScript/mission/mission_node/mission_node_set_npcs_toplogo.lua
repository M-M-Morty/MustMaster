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

---@type BP_MissionNode_SetNpcsToplogo_C
local MissionNodeSetNpcsToplogo = Class(MissionNodeBase)

function MissionNodeSetNpcsToplogo:K2_InitializeInstance()
    Super(MissionNodeSetNpcsToplogo).K2_InitializeInstance(self)
    self.ToplogoActionName = "Toplogo"
    local ActionClass = EdUtils:GetUE5ObjectClass(BPConst.MissionActionSetNpcToplogo)
    if ActionClass then
        local Action = NewObject(ActionClass)
        Action.Name = self.ToplogoActionName
        Action.NewToplogo = self.NewToplogo
        Action.ToplogoImage = self.ToplogoImage

        for i = 1, self.Npcs:Length() do
            local Npc = self.Npcs:GetRef(i)
            Action.TargetActorIDList:Add(Npc.ID)
        end
        self:RegisterAction(Action)
    end
end

function MissionNodeSetNpcsToplogo:K2_ExecuteInput(PinName)
    Super(MissionNodeSetNpcsToplogo).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.Success_Pin, false, false)
    UE.UHiMissionAction_Base.RunMissionActionByName(self, self.ToplogoActionName)
    self:TriggerOutput(self.Complete_Pin, true, false)
end

return MissionNodeSetNpcsToplogo