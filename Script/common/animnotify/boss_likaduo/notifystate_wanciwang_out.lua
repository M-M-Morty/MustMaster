require "UnLua"
local utils = require("common.utils")

local G = require("G")

local NotifyState_Wanciwang_Out = Class()

local MaxProssNum = 50

function NotifyState_Wanciwang_Out:Received_NotifyBegin(MeshComp, Animation, TotalDuration, EventReference)
    local Owner = MeshComp:GetOwner()
    local BlastActors = GameAPI.GetActorsWithTag(Owner, "BlastActor")
    for idx=1, math.min(#BlastActors, MaxProssNum) do
        local BlastActor = BlastActors[idx]
        BlastActor.RollSpeed = math.random(self.RollSpeed - 30, self.RollSpeed + 30)
        if math.random(0, 1) == 1 then
            BlastActor.RollSpeed = -BlastActor.RollSpeed
        end
    end

    local HydrantActors = GameAPI.GetActorsWithTag(Owner, "Hydrant")
    for idx=1, #HydrantActors do
        local HydrantActor = HydrantActors[idx]
        HydrantActor.DestructComponent:Hit(Owner, Owner, nil, 0)
    end

    return true
end

function NotifyState_Wanciwang_Out:Received_NotifyTick(MeshComp, Animation, DeltaTime, EventReference)
    local Owner = MeshComp:GetOwner()
    local BlastActors = GameAPI.GetActorsWithTag(Owner, "BlastActor")
    for idx=1, math.min(#BlastActors, MaxProssNum) do
        local BlastActor = BlastActors[idx]
        if not BlastActor:ActorHasTag("Hydrant") then
            local BlastLocation = BlastActor:K2_GetActorLocation()
            local NormalForward = UE.UKismetMathLibrary.Normal(BlastLocation - Owner:K2_GetActorLocation())
            local DeltaForward = NormalForward * self.OutSpeed * DeltaTime
            DeltaForward.Z = 0
            BlastActor:K2_SetActorLocation(BlastActor:K2_GetActorLocation() + DeltaForward, false, nil, true)
            BlastActor:K2_SetActorRotation(BlastActor:K2_GetActorRotation() + UE.FRotator(0, 0, BlastActor.RollSpeed * DeltaTime), true)
        end
    end
    
	return true
end

function NotifyState_Wanciwang_Out:Received_NotifyEnd(MeshComp, Animation, EventReference)
    local Owner = MeshComp:GetOwner()
    local BlastActors = GameAPI.GetActorsWithTag(Owner, "BlastActor")
    for idx=1, math.min(#BlastActors, MaxProssNum) do
        local BlastActor = BlastActors[idx]
        utils.DoDelay(Owner, 0.1, function() BlastActor:K2_DestroyActor() end)
    end
    return true
end

return NotifyState_Wanciwang_Out
