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

---@type BP_MissionNode_ItemsAdd_C
local MissionNodeItemsAdd = Class(MissionNodeBase)

function MissionNodeItemsAdd:K2_InitializeInstance()
    Super(MissionNodeItemsAdd).K2_InitializeInstance(self)
    self.ActionName = "ItemsAddAction"
    local ActionClass = EdUtils:GetUE5ObjectClass(BPConst.MissionActionItemsAdd)
    if ActionClass then
        local Action = NewObject(ActionClass)
        Action.Name = self.ActionName
        Action.ItemInfos = self.ItemInfos
        self:RegisterAction(Action)
    end
end

function MissionNodeItemsAdd:K2_ExecuteInput(PinName)
    Super(MissionNodeItemsAdd).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.Success_Pin, false, false)
    UE.UHiMissionAction_Base.RunMissionActionByName(self, self.ActionName)
    self:TriggerOutput(self.Complete_Pin, true, false)
end

return MissionNodeItemsAdd