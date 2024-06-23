--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


local G = require("G")
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')

---@type BTService_AbilityUsable_C
local BTService_AbilityUsable_C = Class()

function BTService_AbilityUsable_C:ReceiveActivationAI(OwnerController, ControlledPawn)
    self:Update(OwnerController, ControlledPawn)
end
function BTService_AbilityUsable_C:ReceiveTickAI(OwnerController, ControlledPawn)
    self:Update(OwnerController, ControlledPawn)
end

function BTService_AbilityUsable_C:Update(OwnerController, ControlledPawn)
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(OwnerController)
    local tarActor = BB:GetValueAsObject(self.tarActor.SelectedKeyName)

    local result = FunctionUtil:SelectActionRaw(ControlledPawn, tarActor, true)

    local v = BB:GetValueAsBool(self.saveResultKey.SelectedKeyName)
    if v ~= result then
        BB:SetValueAsBool(self.saveResultKey.SelectedKeyName, result)
    end
end


return BTService_AbilityUsable_C
