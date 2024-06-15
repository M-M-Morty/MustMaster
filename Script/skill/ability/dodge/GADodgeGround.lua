--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")
local GADodgeBase = require("skill.ability.dodge.GADodgeBase")
---@type GA_DodgeGround_C
local M = Class(GADodgeBase)

function M:K2_GetCostGameplayEffect()
    local Cost = self.CostGameplayEffectClass
    if self.GroundCost then Cost = self.GroundCost end
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
    local DodgeAnimMontage = nil
    local NeedInit = false
    local InitRotation = UE.FQuat()
    local DirectionVector = Component:GetDirectionVector()

    if DirectionVector:SizeSquared() > 0.5 then
        NeedInit = true
        InitRotation = UE.UKismetMathLibrary.Conv_VectorToQuaternion(
                           DirectionVector)
    end
    if NeedInit and InitRotation:SizeSquared() > G.EPS then
        DodgeAnimMontage = Component.Ground_DodgeMontage
    else
        DodgeAnimMontage = Component.Ground_DodgeBackMontage
    end
    -- G.log:info("yb", "GADodgeClass %s", tostring(GADodgeClass))
    return DodgeAnimMontage
end



return M
