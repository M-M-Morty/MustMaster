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

---@type BP_MissionNode_Log_C
local MissionNodeLog = Class(MissionNodeBase)


function MissionNodeLog:K2_InitializeInstance()
    Super(MissionNodeLog).K2_InitializeInstance(self)
    self.LogActionName = "MissionLog"
    local ActionClass = EdUtils:GetUE5ObjectClass(BPConst.MissionActionLog)
    if ActionClass then
        local Action = NewObject(ActionClass)
        Action.Name = self.LogActionName
        Action.Message = self.Message
        Action.Verbosity = self.Verbosity
        Action.bPrintToScreen = self.bPrintToScreen
        Action.Duration = self.Duration
        Action.TextColor = self.TextColor
        self:RegisterAction(Action)
    end
end

function MissionNodeLog:K2_ExecuteInput(PinName)
    Super(MissionNodeLog).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.SuccessPin, false, false)
    UE.UHiMissionAction_Base.RunMissionActionByName(self, self.LogActionName)
    self:TriggerOutput(self.CompletePin, true, false)
end


return MissionNodeLog