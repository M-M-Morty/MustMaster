require "UnLua"
local utils = require("common.utils")

local G = require("G")

local NotifyState_Wanciwang_Up = Class()

local MaxProssNum = 50

function NotifyState_Wanciwang_Up:Received_NotifyBegin(MeshComp, Animation, TotalDuration, EventReference)
    local Owner = MeshComp:GetOwner()
    local BlastActors = GameAPI.GetActorsWithTag(Owner, "BlastActor")
    for idx=1, math.min(#BlastActors, MaxProssNum) do
        local BlastActor = BlastActors[idx]
        BlastActor.RollSpeed = math.random(self.RollSpeed - 30, self.RollSpeed + 30)
        if math.random(0, 1) == 1 then
            BlastActor.RollSpeed = -BlastActor.RollSpeed
        end
    end
    return true
end

function NotifyState_Wanciwang_Up:Received_NotifyTick(MeshComp, Animation, DeltaTime, EventReference)
    local Owner = MeshComp:GetOwner()
    local BlastActors = GameAPI.GetActorsWithTag(Owner, "BlastActor")
    for idx=1, math.min(#BlastActors, MaxProssNum) do
        local BlastActor = BlastActors[idx]
        if not BlastActor:ActorHasTag("Hydrant") then
            local DeltaRoll = BlastActor.RollSpeed * DeltaTime
            BlastActor:K2_SetActorLocation(BlastActor:K2_GetActorLocation() + UE.FVector(0, 0, self.UpSpeed * DeltaTime), false, nil, true)
            BlastActor:K2_SetActorRotation(BlastActor:K2_GetActorRotation() + UE.FRotator(0, 0, DeltaRoll), true)
        end
    end

	return true
end

function NotifyState_Wanciwang_Up:Received_NotifyEnd(MeshComp, Animation, EventReference)
    return true
end

return NotifyState_Wanciwang_Up
