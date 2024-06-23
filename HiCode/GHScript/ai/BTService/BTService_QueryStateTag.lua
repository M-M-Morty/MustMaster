--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


local G = require("G")

---@type BTService_QueryStateTag_C
local BTService_QueryStateTag_C = Class()

function BTService_QueryStateTag_C:ReceiveActivationAI(OwnerController, ControlledPawn)
    self:Update(OwnerController, ControlledPawn)
end
function BTService_QueryStateTag_C:ReceiveTickAI(OwnerController, ControlledPawn)
    self:Update(OwnerController, ControlledPawn)
end

function BTService_QueryStateTag_C:Update(OwnerController, ControlledPawn)
    if not ControlledPawn.ChararacteStateManager then
        return
    end
    local vTags = ControlledPawn.ChararacteStateManager.vTags
    local result
    if self.matchType == UE.EGameplayContainerMatchType.Any then
        result = UE.UBlueprintGameplayTagLibrary.HasAnyTags(vTags, self.tags, true)
    else
        result = UE.UBlueprintGameplayTagLibrary.HasAllTags(vTags, self.tags, true)
    end

    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(OwnerController)
    local v = BB:GetValueAsBool(self.saveResultKey.SelectedKeyName)
    if v ~= result then
        BB:SetValueAsBool(self.saveResultKey.SelectedKeyName, result)
    end
end


return BTService_QueryStateTag_C
