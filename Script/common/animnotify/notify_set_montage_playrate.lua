require "UnLua"
local utils = require("common.utils")

local G = require("G")

local Notify_SetMontagePlayRate = Class()

function Notify_SetMontagePlayRate:Received_NotifyBegin(MeshComp, Animation, DeltaTime, EventReference)
    local actor = MeshComp:GetOwner()
    local PlayRate = 1
    if not actor or not actor.GetAnimationVariable then
        PlayRate = self.DefaultPlayRate
    else
        PlayRate = actor:GetAnimationVariable(self.PlayRateVariable)
        if PlayRate == nil then
            if self.PlayRateVariable ~= "None" then
                G.log:error("zale", "Notify_SetMontagePlayRate:Invalid variable (%s)", self.PlayRateVariable)
                return
            end
            PlayRate = self.DefaultPlayRate
        else
            PlayRate = PlayRate * self.ExtraPlayRateFactor
        end
    end
    -- G.log:error("devin", "Notify_SetMontagePlayRate:Received_NotifyBegin %f", PlayRate)
    UE.UHiUtilsFunctionLibrary.SetMontagePlayRate(MeshComp, Animation, PlayRate)
    return true
end

function Notify_SetMontagePlayRate:Received_NotifyEnd(MeshComp, Animation, DeltaTime, EventReference)
    local actor = MeshComp:GetOwner()
    if not actor then
        return true
    end
    -- G.log:error("devin", "Notify_SetMontagePlayRate:Received_NotifyEnd")
    UE.UHiUtilsFunctionLibrary.SetMontagePlayRate(MeshComp, Animation, 1.0)
    return true
end


return Notify_SetMontagePlayRate
