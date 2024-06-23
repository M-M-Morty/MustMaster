--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR PanZiBin
-- @DATE ${date} ${time}
--

require "UnLua"
-- local utils = require("common.utils")
-- local G = require("G")
---@type notify_add_buff_for_player
local notify_add_buff_for_player = Class()

local function SelectTargetBuffComponent(MeshComp)
    local Target
    local Owner = MeshComp:GetOwner()
    if Owner.IsMonster and Owner:IsMonster() then
        local Controller = UE.UAIBlueprintHelperLibrary.GetAIController(Owner)
        local BB = Controller and UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
        Target = BB and BB:GetValueAsObject("TargetActor")
    elseif Owner.IsPlayerComp and Owner:IsPlayerComp() then
        Target = Owner
    end
    return Target and Target.BuffComponent
end

function notify_add_buff_for_player:Received_NotifyBegin(MeshComp, Animation, TotalDuration)
    local BuffComponent = SelectTargetBuffComponent(MeshComp)
    if not BuffComponent then return false end
    local Tag = self.Buff_GE_Tag
    BuffComponent:AddBuffByTag(Tag)
    return true
end

-- function notify_add_buff_for_player:Received_NotifyTick(MeshComp, Animation, FrameDeltaTime)
-- end

function notify_add_buff_for_player:Received_NotifyEnd(MeshComp, Animation)
    local BuffComponent = SelectTargetBuffComponent(MeshComp)
    if not BuffComponent then return false end
    local Tag = self.Buff_GE_Tag
    BuffComponent:RemoveBuffByTag(Tag)
    return true
end

return notify_add_buff_for_player