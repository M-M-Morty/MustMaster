--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"
local G = require("G")

---@type GC_SetMontagePlayRate_C
local GC_SetMontagePlayRate = UnLua.Class()

function GC_SetMontagePlayRate:OnActive(TargetActor, Parameters)    
    local PlayRate = 1
    if not TargetActor or not TargetActor.GetAnimationVariable then
        PlayRate = self.DefaultPlayRate
    else
        PlayRate = TargetActor:GetAnimationVariable(self.PlayRateVariable)
        if PlayRate == nil then
            if self.PlayRateVariable ~= "None" then
                G.log:error("hycoldrain", "Notify_SetMontagePlayRate:Invalid variable (%s)", self.PlayRateVariable)
                return false
            end
            PlayRate = self.DefaultPlayRate
        else
            PlayRate = PlayRate * self.ExtraPlayRateFactor
        end
    end
    -- G.log:error("hycoldrain", "Notify_SetMontagePlayRate:Received_NotifyBegin %f", PlayRate)    
    local ASC = UE.UAbilitySystemBlueprintLibrary.GetAbilitySystemComponent(TargetActor)
    if ASC and ASC:IsValid() then
        ASC:CurrentMontageSetPlayRate(PlayRate)
    else
        return false
    end
    return true
end


function GC_SetMontagePlayRate:OnRemove(TargetActor, Parameters)    
    if not TargetActor then
        return false
    end
    local ASC = UE.UAbilitySystemBlueprintLibrary.GetAbilitySystemComponent(TargetActor)
    if ASC and ASC:IsValid() then
        ASC:CurrentMontageSetPlayRate(1.0)
    else
        return false
    end
    return true
end


return GC_SetMontagePlayRate