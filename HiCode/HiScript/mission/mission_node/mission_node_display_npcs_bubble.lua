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

---@type BP_MissionNode_DisplayNpcsBubble_C
local MissionNodeDisplayNpcsBubble = Class(MissionNodeBase)

function MissionNodeDisplayNpcsBubble:K2_InitializeInstance()
    Super(MissionNodeDisplayNpcsBubble).K2_InitializeInstance(self)
    self.DisplayActionName = "Display"
    local ActionClass = EdUtils:GetUE5ObjectClass(BPConst.MissionActionDisplayNpcBubble)
    if ActionClass then
        local Action = NewObject(ActionClass)
        Action.Name = self.DisplayActionName
        Action.BubbleID = self.BubbleID
        Action.DelayResumeAutoBubbleTime = self.DelayResumeAutoBubbleTime

        for i = 1, self.Npcs:Length() do
            local Npc = self.Npcs:GetRef(i)
            Action.TargetActorIDList:Add(Npc.ID)
        end
        self:RegisterAction(Action)
    end
end

function MissionNodeDisplayNpcsBubble:K2_ExecuteInput(PinName)
    Super(MissionNodeDisplayNpcsBubble).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.Success_Pin, false, false)
    UE.UHiMissionAction_Base.RunMissionActionByName(self, self.DisplayActionName)
    self:TriggerOutput(self.Complete_Pin, true, false)
end

return MissionNodeDisplayNpcsBubble