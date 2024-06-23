--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


require "UnLua"

local G = require("G")
local json = require("thirdparty.json")
local MissionActionOnActorBase = require("mission.mission_action.mission_action_onactor_base")

---@type BP_MissionAction_DisplayNpcBubble_C
local MissionActionDisplayNpcBubble = Class(MissionActionOnActorBase)

function MissionActionDisplayNpcBubble:GenerateActionParam()
    local Param = {
        BubbleID = self.BubbleID,
        DelayResumeTime = self.DelayResumeAutoBubbleTime,
    }
    return json.encode(Param)
end

function MissionActionDisplayNpcBubble:Run(Actor, ActionParamStr)
    Super(MissionActionDisplayNpcBubble).Run(self, Actor, ActionParamStr)
    if Actor.GetBillboardComponent ~= nil then
        local BillboardComponent = Actor:GetBillboardComponent()
        if BillboardComponent ~= nil then
            local Param = self:ParseActionParam(ActionParamStr)
            BillboardComponent:Multicast_DisplayMissionBubble(Param.BubbleID, Param.DelayResumeTime)
        else
            G.log:error("xaelpeng", "MissionActionDisplayNpcBubble:Run Actor %s has no BillboardComponent", Actor:GetDisplayName())
        end
    else
        G.log:error("xaelpeng", "MissionActionDisplayNpcBubble:Run Actor %s has no GetBillboardComponent", Actor:GetDisplayName())
    end
end

function MissionActionDisplayNpcBubble:ParseActionParam(ActionParamStr)
    return json.decode(ActionParamStr)
end

return MissionActionDisplayNpcBubble
