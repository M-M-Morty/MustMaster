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
local MissionNodeCallStatusFlow = Class(MissionNodeBase)


function MissionNodeCallStatusFlow:K2_InitializeInstance()
    Super(MissionNodeCallStatusFlow).K2_InitializeInstance(self)
    self.CallStatusFlowName = "CallStatusFlow"
    local ActionClass = EdUtils:GetUE5ObjectClass(BPConst.MissionActionCallStatusFlow)
    if ActionClass then
        local Action = NewObject(ActionClass)
        Action.Name = self.CallStatusFlowName
        Action.eStatusFlows = self.eStatusFlows
        Action.eStatusFlowsRaw = self.eStatusFlowsRaw
        for i = 1, self.BaseItemRef:Length() do
            local BaseItem = self.BaseItemRef:GetRef(i)
            Action.TargetActorIDList:Add(BaseItem.ID)
        end
        self:RegisterAction(Action)
    end
end

function MissionNodeCallStatusFlow:K2_ExecuteInput(PinName)
    Super(MissionNodeCallStatusFlow).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.Success_Pin, false, false)
    UE.UHiMissionAction_Base.RunMissionActionByName(self, self.CallStatusFlowName)
    self:TriggerOutput(self.Complete_Pin, true, false)
end


return MissionNodeCallStatusFlow