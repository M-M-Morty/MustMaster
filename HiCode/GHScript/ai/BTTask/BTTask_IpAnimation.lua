--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


local G = require("G")
local ai_utils = require("common.ai_utils")
local BTTask_Base = require("ai.BTCommon.BTTask_Base")

---@type BTTask_IpAnimation_C
local BTTask_IpAnimation_C = Class(BTTask_Base)


function BTTask_IpAnimation_C:Execute(Controller, Pawn)
    if Pawn.ChararacteStateManager then
        Pawn.ChararacteStateManager:NotifyEvent('EnterAct')
    else
        return ai_utils.BTTask_Failed
    end
end

function BTTask_IpAnimation_C:Tick(Controller, Pawn, DeltaSeconds)
    if not Pawn.ChararacteStateManager:HasTag('StateGH.IpAnimation') then
        self:FinishTask(Controller, Pawn)
        return ai_utils.BTTask_Succeeded
    end
end

function BTTask_IpAnimation_C:FinishTask(Controller, Pawn)
    if Pawn and Pawn.ChararacteStateManager then
        Pawn.ChararacteStateManager:NotifyEvent('LeaveAct')
    end
end

function BTTask_IpAnimation_C:ReceiveAbortAI(OwnerController, ControlledPawn)
    self:FinishTask(OwnerController, ControlledPawn)
    self:FinishExecute(false)
end

return BTTask_IpAnimation_C