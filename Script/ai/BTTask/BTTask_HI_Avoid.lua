require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_Avoid = Class(BTTask_Base)


function BTTask_Avoid:Execute(Controller, Pawn)

    local HitActors = UE.TArray(UE.AActor)

    -- UE.FGameplayTargetDataFilterHandle()
    local FilterHandle = UE.UAbilitySystemBlueprintLibrary.MakeFilterHandle(self.Filter, Pawn)
    UE.UHiCollisionLibrary.PerformOverlapActorsBP(Pawn:GetWorld(), self.TargetActorSpec, Pawn:K2_GetActorLocation(), Pawn:GetActorForwardVector(), FilterHandle, HitActors, false, false)

    -- G.log:debug("yj", "BTTask_Avoid %s - %s - %s", HitActors:Length(), self.AvoidMontage, type(Pawn))

    if HitActors:Length() == 0 then
    	return ai_utils.BTTask_Failed
    end

    -- avoid
    for i = 1, HitActors:Length() do

    	local HitActor = HitActors:Get(i)

    	-- only monster
    	if HitActor.CharIdentity == Enum.Enum_CharIdentity.Monster then

		    local Forward = HitActor:K2_GetActorLocation() - Pawn:K2_GetActorLocation()
	        local Rotation = UE.UKismetMathLibrary.Conv_VectorToRotator(Forward)

	        Pawn:K2_SetActorRotation(Rotation, false)
    		Controller:K2_SetFocus(HitActor)
		    Pawn.AppearanceComponent:Server_PlayMontage(self.AvoidMontage, self.MontagePlayRate)

	    	return ai_utils.BTTask_Succeeded
    	end
    end

    return ai_utils.BTTask_Failed
end


return BTTask_Avoid
