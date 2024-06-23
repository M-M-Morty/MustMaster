require "UnLua"

local G = require("G")
local Projectile = require("actors.common.Projectile")

local Projectile_DunFanPao = Class(Projectile)


function Projectile_DunFanPao:InitSplineTimeline()
	if not self:IsServer() then
		return
	end

    Super(Projectile_DunFanPao).InitSplineTimeline(self)
end

function Projectile_DunFanPao:MoveFollowTargetBySpline()
	if not self:IsServer() then
		return
	end

    Super(Projectile_DunFanPao).MoveFollowTargetBySpline(self)
end

return RegisterActor(Projectile_DunFanPao)
