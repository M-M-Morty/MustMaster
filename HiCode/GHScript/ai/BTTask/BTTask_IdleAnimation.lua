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

---@type BTTask_IdleAnimation_C
local BTTask_IdleAnimation_C = Class(BTTask_Base)


function BTTask_IdleAnimation_C:Execute(Controller, Pawn)
    if Pawn.ChararacteStateManager then
        Pawn.ChararacteStateManager:AddStateTagDirect('StateGH.IdleAnimation')
        Pawn:UpdateNextIdleAnim()
    else
        return ai_utils.BTTask_Failed
    end
end

function BTTask_IdleAnimation_C:Tick(Controller, Pawn, DeltaSeconds)
    if not Pawn.ChararacteStateManager:HasTag('StateGH.IdleAnimation') then
        self:FinishTask(Controller, Pawn)
        return ai_utils.BTTask_Succeeded
    end
end

function BTTask_IdleAnimation_C:FinishTask(Controller, Pawn)
    if Pawn and Pawn.ChararacteStateManager then
        Pawn.ChararacteStateManager:RemoveStateTagDirect('StateGH.IdleAnimation')
    end
end

function BTTask_IdleAnimation_C:ReceiveAbortAI(OwnerController, ControlledPawn)
    self:FinishTask(OwnerController, ControlledPawn)
    self:FinishExecute(false)
end

return BTTask_IdleAnimation_C