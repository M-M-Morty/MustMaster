require "UnLua"

local G = require("G")
local Projectile = require("actors.common.Projectile")

local Projectile_LiuXingYu = Class(Projectile)


function Projectile_LiuXingYu:InitSplineTimeline()
	if not self:IsServer() then
		return
	end

	local RandRadius_X = math.random(-self.ScopeRadius, self.ScopeRadius)
	local RandRadius_Y = math.random(-self.ScopeRadius, self.ScopeRadius)

	local TargetLocation = self:GetSkillTargetLocation() + UE.FVector(RandRadius_X, RandRadius_Y, 0)
	local YOffset = self.ScopeHeight / UE.UKismetMathLibrary.DegTan(math.max(5, self.TanDegree))

	local BeginLocation = TargetLocation + UE.FVector(0, -YOffset, self.ScopeHeight)
	local EndLocation = TargetLocation + UE.FVector(0, YOffset, -self.ScopeHeight)

	self:Multicast_BeginMove(BeginLocation, EndLocation)
end

function Projectile_LiuXingYu:Multicast_BeginMove_RPC(BeginLocation, EndLocation)

    self:K2_SetActorLocation(BeginLocation, false, UE.FHitResult(), false)
    local Rotation = UE.UKismetMathLibrary.Conv_VectorToRotator(EndLocation - BeginLocation)
    self:K2_SetActorRotation(Rotation, true)

    self:SendMessage("CreateSplineAndTimeline", self:GetTransform(), false)
    self:SendMessage("UpdateSplineTargetLocation", EndLocation)
end

return RegisterActor(Projectile_LiuXingYu)
