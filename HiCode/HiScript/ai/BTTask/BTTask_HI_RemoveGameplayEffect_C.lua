--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR PanZiBin
-- @DATE ${date} ${time}
--

require "UnLua"

local BTTask_Base = require("ai.BTCommon.BTTask_Base")

---@type BTTask_RemoveGameplayEffect_C
local BTTask_RemoveGameplayEffect = Class(BTTask_Base)

local ai_utils = require("common.ai_utils")

function BTTask_RemoveGameplayEffect:Execute(Controller, Pawn)
    -- local BB = Controller and UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    -- Target = BB and BB:GetValueAsObject("TargetActor")
    local ASC = Pawn.AbilitySystemComponent
    if not ASC then return ai_utils.BTTask_Failed end
    local StacksToRemove = -1    
    local GEList = self.GEList
    if GEList then
        for _, GEClass in pairs(GEList) do
            ASC:RemoveActiveGameplayEffectBySourceEffect(GEClass, nil, StacksToRemove)
        end
    end
    return ai_utils.BTTask_Succeeded
end

return BTTask_RemoveGameplayEffect