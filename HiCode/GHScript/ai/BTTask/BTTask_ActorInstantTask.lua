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

---@type BTTask_ActorInstantTask_C
local BTTask_ActorInstantTask_C = Class(BTTask_Base)

function BTTask_ActorInstantTask_C:Execute(Controller, Pawn)
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local actor = BB:GetValueAsObject(self.actorKey.SelectedKeyName)
    if not actor then
        actor = Pawn
    end

    if self.Execution == '' then
        return ai_utils.BTTask_Failed
    end
    local obj = actor[self.Execution]
    if not obj then
        return ai_utils.BTTask_Failed
    end
    if type(obj) == 'function' then
        return obj(actor, self.strParams) and ai_utils.BTTask_Succeeded or ai_utils.BTTask_Failed
    else
        return obj and ai_utils.BTTask_Succeeded or ai_utils.BTTask_Failed
    end
end


return BTTask_ActorInstantTask_C
