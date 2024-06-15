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
local TimeUtil = require("common.utils.time_utils")

local MissionNodeBase = require("mission.mission_node.mission_node_base")

---@type BP_MissionNode_ChangeHour_C
local MissionNodeChangeHour = Class(MissionNodeBase)


function MissionNodeChangeHour:K2_InitializeInstance()
    Super(MissionNodeChangeHour).K2_InitializeInstance(self)
    self.ActionName = "ChangeHour"
    local ActionClass = EdUtils:GetUE5ObjectClass(BPConst.MissionActionChangeHour)
    if ActionClass then
        local Action = NewObject(ActionClass)
        Action.Name = self.ActionName
        Action.TargetHour = self.TargetHour
        self:RegisterAction(Action)
    end
end

function MissionNodeChangeHour:K2_ExecuteInput(PinName)
    Super(MissionNodeChangeHour).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.SuccessPin, false, false)
    if self.TargetHour >= 0 and self.TargetHour < TimeUtil.HOURS_PER_DAY then
        UE.UHiMissionAction_Base.RunMissionActionByName(self, self.ActionName)
    else
        G.log:error("MissionNodeChangeHour", "K2_ExecuteInput TargetHour(%s) Error", self.TargetHour)
    end
    self:TriggerOutput(self.CompletePin, true, false)
end


return MissionNodeChangeHour