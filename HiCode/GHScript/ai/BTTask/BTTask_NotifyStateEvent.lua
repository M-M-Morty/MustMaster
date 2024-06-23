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

---@type BTTask_NotifyStateEvent_C
local BTTask_NotifyStateEvent_C = Class(BTTask_Base)


function BTTask_NotifyStateEvent_C:Execute(Controller, Pawn)
    if not Pawn.ChararacteStateManager then
        return ai_utils.BTTask_Failed
    end

    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local sourceActor = BB:GetValueAsObject(self.source.SelectedKeyName)
    if sourceActor == nil then
        sourceActor = Pawn
    end
    local targetActor = BB:GetValueAsObject(self.target.SelectedKeyName)
    Pawn.ChararacteStateManager:NotifyEvent(self.event, sourceActor, targetActor, self.content)
    return ai_utils.BTTask_Succeeded
end

return BTTask_NotifyStateEvent_C