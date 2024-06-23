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

---@type BTTask_CustomOptions_C
local BTTask_CustomOptions_C = Class(BTTask_Base)

function BTTask_CustomOptions_C:Execute(Controller, Pawn)
    if not Pawn.ChararacteStateManager then
        return ai_utils.BTTask_Failed
    end

    if self.AddStateTag then
        Pawn.ChararacteStateManager:AddStateTagsDirect(self.Tag)
    elseif self.RemoveStateTag then
        Pawn.ChararacteStateManager:RemoveStateTagsDirect(self.Tag)
    end

    return ai_utils.BTTask_Succeeded
end


return BTTask_CustomOptions_C
