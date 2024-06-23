require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_ReturnToBornLocation = Class(BTTask_Base)


function BTTask_ReturnToBornLocation:Execute(Controller, Pawn)
    Pawn.AppearanceComponent:Multicast_SetDesiredRotationMode(UE.EHiRotationMode.VelocityDirection)
end

function BTTask_ReturnToBornLocation:Tick(Controller, Pawn, DeltaSeconds)
    local SelfLocation = Pawn:K2_GetActorLocation()
    local BornLocation = ai_utils.GetBornLocation(Pawn)
    if UE.UKismetMathLibrary.Vector_Distance2D(SelfLocation, BornLocation) < 50 then
        local ASC = Pawn:GetAbilitySystemComponent()
        ASC:BP_ApplyGameplayEffectToSelf(Pawn.InitGE, 0.0, nil)
        return ai_utils.BTTask_Succeeded
    end

    ai_utils.EvMoveToLocation(Controller, Pawn, BornLocation)
end

function BTTask_ReturnToBornLocation:OnBreak(Controller, Pawn)
	G.log:warn("yj", "BTTask_ReturnToBornLocation:OnBreak")
    local BornLocation = ai_utils.GetBornLocation(Pawn)
    Pawn:K2_SetActorLocation(BornLocation, false, nil, true)
end

return BTTask_ReturnToBornLocation
