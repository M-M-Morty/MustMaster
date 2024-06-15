--
-- DESCRIPTION
--
-- @COMPANY **ShowActionName
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")
local EdUtils = require("common.utils.ed_utils")
local BPConst = require("common.const.blueprint_const")

local MissionNodeBase = require("mission.mission_node.mission_node_base")

---@type BP_MissionNode_SpawnMonsters_C
local MissionNodeShowActStart = Class(MissionNodeBase)

function MissionNodeShowActStart:K2_InitializeInstance()
    Super(MissionNodeShowActStart).K2_InitializeInstance(self)
    self.ShowActionName = "ShowActStart"
    local ActionClass = EdUtils:GetUE5ObjectClass(BPConst.MissionActionShowActStart)
    if ActionClass then
        local Action = NewObject(ActionClass)
        Action.Name = self.ShowActionName
        Action.TargetTag = "HiGamePlayer"
        self:RegisterAction(Action)
    end
end

function MissionNodeShowActStart:K2_ExecuteInput(PinName)
    Super(MissionNodeShowActStart).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.SuccessPin, false, false)
    local Action = self:GetAction(self.ShowActionName)
    if not Action then
        G.log:error("[MissionNodeShowActStart:K2_ExecuteInput]", "Action not found, name=%s", self.ShowActionName)
        return
    end
    Action.MissionActID = self:GetMissionActID()
    UE.UHiMissionAction_Base.RunMissionActionByName(self, self.ShowActionName)
    self:TriggerOutput(self.CompletePin, true, false)
end

return MissionNodeShowActStart