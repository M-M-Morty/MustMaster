--
-- Work Action Finish Node.
--
-- @COMPANY 
-- @AUTHOR virgilzhuge
-- @DATE 2024-06-11 
--

local G = require("G")
local BP_WorkActionBlueprintClass = UE.UClass.Load('/Game/Blueprints/Mission/MissionNode/BP_MissionNode_WorkAction.BP_MissionNode_WorkAction_C')

---@type BP_MissionNode_WorkActionFinishNode_C
local WorkActionFinishNode = Class()

function WorkActionFinishNode:K2_ExecuteInput(PinName)

    local OuterObj = self:GetOuter()
    local FlowAsset = OuterObj:Cast(UE.UHiMissionFlowAsset)

    if FlowAsset then
        self:Finish()

        local node = FlowAsset:GetNode(self.WorkActionNodeGuid)
        
        if node then
            local workActionObj = node:Cast(BP_WorkActionBlueprintClass)

            -- Notify work action finished.
            if workActionObj then
                workActionObj:OnFinishNodeDone(self:GetNodeGuid())
            end
        end

    else
        G.log:error("virgilzhuge", "WorkActionFinishNode:K2_ExecuteInput: Outer is not UE.UHiMissionFlowAsset !")
    end
end


return WorkActionFinishNode