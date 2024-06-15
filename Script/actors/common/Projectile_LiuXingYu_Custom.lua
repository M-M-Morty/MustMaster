require "UnLua"

local G = require("G")
local Projectile = require("actors.common.Projectile")

local Projectile_LiuXingYu_Custom = Class(Projectile)


function Projectile_LiuXingYu_Custom:InitSplineTimeline()
    if not self:IsServer() then
        return
    end

    local TargetLocation = self:GetSkillTargetLocation()

    local TargetActors = GameAPI.GetActorsWithTag(self.SourceActor, self.SourceActor.Param1)
    if TargetActors[1] then
		TargetLocation = TargetActors[1]:K2_GetActorLocation()
    end

    local YOffset = self.ScopeHeight / UE.UKismetMathLibrary.DegTan(math.max(5, self.TanDegree))

    local BeginLocation = TargetLocation + UE.FVector(0, -YOffset, self.ScopeHeight)
    local EndLocation = TargetLocation + UE.FVector(0, YOffset, -self.ScopeHeight)

    self:Multicast_BeginMove(BeginLocation, EndLocation)
end

function Projectile_LiuXingYu_Custom:Multicast_BeginMove_RPC(BeginLocation, EndLocation)

    self:K2_SetActorLocation(BeginLocation, false, UE.FHitResult(), false)
    local Rotation = UE.UKismetMathLibrary.Conv_VectorToRotator(EndLocation - BeginLocation)
    self:K2_SetActorRotation(Rotation, true)
    
    self:SendMessage("CreateSplineAndTimeline", self:GetTransform(), false)
    self:SendMessage("UpdateSplineTargetLocation", EndLocation)    
end

return RegisterActor(Projectile_LiuXingYu_Custom)
