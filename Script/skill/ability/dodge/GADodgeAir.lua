--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local GADodgeBase = require("skill.ability.dodge.GADodgeBase")
---@type GA_DodgeAir_C
local M = Class(GADodgeBase)


function M:K2_GetCostGameplayEffect()
    local Cost = self.CostGameplayEffectClass
    if self.AirCost then Cost = self.AirCost end
    if Cost then
        return Cost:GetDefaultObject()
    else 
        return nil
    end
end


---@return UAnimMontage
function M:GetDodgeMontage()
    local Component = self.OwnerActor.DodgeComponent;
    if not Component then
        return nil
    end
    return Component.Air_DodgeMontage
end

return M
