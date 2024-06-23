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

---@type BTTask_ModifyBB_C
local BTTask_ModifyBB_C = Class(BTTask_Base)

function BTTask_ModifyBB_C:Execute(Controller, Pawn)
    local objClass = UE.UClass.Load("/Script/AIModule.BlackboardKeyType_Object")
    local vecClass = UE.UBlackboardKeyType_Vector
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)

    if self.targetKey.SelectedKeyType:GetClass() == vecClass:GetClass() then
        BB:SetValueAsVector(self.targetKey.SelectedKeyName, self.vec)
    end

    return ai_utils.BTTask_Succeeded
end


return BTTask_ModifyBB_C
