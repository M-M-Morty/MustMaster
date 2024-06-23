--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


local G = require("G")

---@type BTService_ActorService_C
local BTService_ActorService_C = Class()

function BTService_ActorService_C:ReceiveActivationAI(OwnerController, ControlledPawn)
    self:Update(OwnerController, ControlledPawn)
end
function BTService_ActorService_C:ReceiveTickAI(OwnerController, ControlledPawn)
    self:Update(OwnerController, ControlledPawn)
end

function BTService_ActorService_C:Update(OwnerController, ControlledPawn)
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(OwnerController)
    local actor = BB:GetValueAsObject(self.ActorKey.SelectedKeyName)
    if not actor then
        actor = ControlledPawn
    end

    local result
    if self.Execution == '' then
        result = false
    else
        local obj = actor[self.Execution]
        if not obj then
            result = false
        else
            if type(obj) == 'function' then
                result = obj(actor)
            else
                result = obj and true or false
            end
        end
    end
    
    local v = BB:GetValueAsBool(self.ResultKey.SelectedKeyName)
    if v ~= result then
        BB:SetValueAsBool(self.ResultKey.SelectedKeyName, result)
    end
end


return BTService_ActorService_C
