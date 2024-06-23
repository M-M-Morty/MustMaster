--
-- Work Action Node.
--
-- @COMPANY **
-- @AUTHOR virgilzhuge
-- @DATE 2024-06-11 
--

local G = require("G")

---@type BP_MissionNode_WorkAction_C
local WorkActionNode = Class()

function WorkActionNode:K2_ExecuteInput(PinName)

    local OuterObj = self:GetOuter()
    local FlowAsset = OuterObj:Cast(UE.UHiMissionFlowAsset)

    -- Get entry node from asset, then trigger entry output.
    if FlowAsset then
        local EntryNode = FlowAsset:GetNode(self.EntryNodeGuid)

        if EntryNode then
            EntryNode:TriggerFirstOutput(true)
        else
            G.log:info("virgilzhuge", "WorkActionNode:K2_ExecuteInput EntryNode is nil!")
        end
    end

end

function WorkActionNode:OnFinishNodeDone(NodeGuid)

    -- self.Overridden.OnFinishNodeDone(self, NodeGuid)
    local OuterObj = self:GetOuter()
    local FlowAsset = OuterObj:Cast(UE.UHiMissionFlowAsset)

    if FlowAsset then
        local RecordedNodes = FlowAsset:GetRecordedNodes()
        local bShouldFinish = self:IsAllRequiredNodeFinished(RecordedNodes)

        -- Finish work action.
        if bShouldFinish then 
            --1. Finish recursive entry node.
            local FlowAsset = OuterObj:Cast(UE.UHiMissionFlowAsset)

            if FlowAsset then
                local EntryNode = FlowAsset:GetNode(self.EntryNodeGuid)

                if EntryNode then
                    EntryNode:Abort()
                else
                    G.log:info("virgilzhuge", "WorkActionNode:OnFinishNodeDone:FinishRecursive EntryNode is nil!")
                end
            end

            -- 2. Trigger output
            self:TriggerFirstOutput(true)

        end
    end
end


-- Check required nodes have finished.
function WorkActionNode:IsAllRequiredNodeFinished(AssetRecordedNodes)

    -- TSet<FGuid> RequiredNodes -> TArray
    local TmpRequiredNodes = self.RequiredNodes:ToArray()

    for Index = 1, AssetRecordedNodes:Length() do 
        local RecordNode = AssetRecordedNodes[Index]
        local FinishNode = RecordNode:Cast(UE.UHiMissionFlowNode_WorkActionFinish)

        if FinishNode then
            if TmpRequiredNodes:Contains(FinishNode.NodeGuid) then
                TmpRequiredNodes:RemoveItem(FinishNode.NodeGuid)

                if TmpRequiredNodes:Length() == 0 then 
                    break
                end
            end
        end
    end

    return TmpRequiredNodes:Length() == 0
end


return WorkActionNode