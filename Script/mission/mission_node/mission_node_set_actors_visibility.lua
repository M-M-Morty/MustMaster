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

---@type BP_MissionNode_SetActorsVisibility_C
local MissionNodeSetActorsVisibility = Class(MissionNodeBase)


function MissionNodeSetActorsVisibility:K2_InitializeInstance()
    Super(MissionNodeSetActorsVisibility).K2_InitializeInstance(self)
    self.VisibleActionName = "Visible"
    local ActionClass = EdUtils:GetUE5ObjectClass(BPConst.MissionActionSetActorVisibility)
    if ActionClass then
        local Action = NewObject(ActionClass)
        Action.Name = self.VisibleActionName
        Action.bHidden = self.IsHidden

        for i = 1, self.Actors:Length() do
            local Actor = self.Actors:GetRef(i)
            Action.TargetActorIDList:Add(Actor.ID)
        end
        self:RegisterAction(Action)
    end
end

function MissionNodeSetActorsVisibility:K2_ExecuteInput(PinName)
    Super(MissionNodeSetActorsVisibility).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.Success_Pin, false, false)
    UE.UHiMissionAction_Base.RunMissionActionByName(self, self.VisibleActionName)
    self:TriggerOutput(self.Complete_Pin, true, false)
end



return MissionNodeSetActorsVisibility