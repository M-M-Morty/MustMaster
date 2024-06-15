require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_AbsorbTarget = Class(BTTask_Base)


-- 吸取目标
-- MinDis：内圈半径，小于这个半径则吸取成功
-- MaxDis：外圈半径，大于这个半径则吸力消失
function BTTask_AbsorbTarget:Execute(Controller, Pawn)
    -- G.log:debug("yjj", "BTTask_AbsorbTarget:Execute %s", G.GetDisplayName(Pawn.InteractionComponent.TargetBeSelected))
    if Pawn.InteractionComponent.TargetBeSelected == nil then
        return ai_utils.BTTask_Failed
    end

    Pawn:GetAIServerComponent().bCanAbsorb = false
end

function BTTask_AbsorbTarget:Tick(Controller, Pawn, DeltaSeconds)
    if not Pawn:GetAIServerComponent().bCanAbsorb then
        return ai_utils.BTTask_InProgress
    end

    local TargetActor = Pawn.InteractionComponent.TargetBeSelected
    local TargetLocation = TargetActor:K2_GetActorLocation()

    local SelfLocation = Pawn:K2_GetActorLocation()
    local Dis = UE.UKismetMathLibrary.Vector_Distance2D(SelfLocation, TargetLocation)
    if Dis < self.MinDis then
        return ai_utils.BTTask_Succeeded
    elseif Dis < self.MaxDis then
        local ForwardWithoutZ = UE.UKismetMathLibrary.Normal(UE.FVector(SelfLocation.X, SelfLocation.Y, 0) - UE.FVector(TargetLocation.X, TargetLocation.Y, 0))
        local LocationDelta = ForwardWithoutZ * self.Speed * DeltaSeconds
        TargetActor.AppearanceComponent:Multicast_SmoothActorLocation(TargetLocation + LocationDelta, 3000, DeltaSeconds, true, false)
    end
end


return BTTask_AbsorbTarget
