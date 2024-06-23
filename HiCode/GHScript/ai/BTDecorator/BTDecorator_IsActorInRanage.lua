--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@type BTDecorator_IsActorInRanage
local BTDecorator_IsActorInRanage = Class()

function BTDecorator_IsActorInRanage:PerformConditionCheckAI(Controller, Pawn)
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local targetActor = BB:GetValueAsObject(self.tarActor.SelectedKeyName)
    if targetActor then
        return Pawn:GetDistanceTo(targetActor) < self.distance
    else
        return false
    end
end

return BTDecorator_IsActorInRanage