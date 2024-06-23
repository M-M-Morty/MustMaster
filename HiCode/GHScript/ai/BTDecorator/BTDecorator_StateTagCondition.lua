--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@type BTDecorator_StateTagCondition_C
local BTDecorator_StateTagCondition_C = Class()


function BTDecorator_StateTagCondition_C:PerformConditionCheckAI(Controller, Pawn)
    if not Pawn.ChararacteStateManager then
        return false
    end
    local vTags = Pawn.ChararacteStateManager.vTags
    if self.matchType == UE.EGameplayContainerMatchType.Any then
        return UE.UBlueprintGameplayTagLibrary.HasAnyTags(vTags, self.tags, true)
    else
        return UE.UBlueprintGameplayTagLibrary.HasAllTags(vTags, self.tags, true)
    end
end

return BTDecorator_StateTagCondition_C