require "UnLua"
local utils = require("common.utils")

local G = require("G")

local check_table = require("common.data.state_conflict_data")

local Stage_BeforeHit = 0
local Stage_InHit = 1
local Stage_Fantan = 2

local NotifyState_BurstPointConsume = Class()

function NotifyState_BurstPointConsume:Received_NotifyTick(MeshComp, Animation, DeltaTime, EventReference)
    local Owner = MeshComp:GetOwner()
    if Owner:IsClient() then
        return true
	end

    if Owner.BurstPointComponent and Owner.BurstPointComponent:GetBurstPointsNum() > 0 then
        G.log:debug("yj", "NotifyState_BurstPointConsume:Received_NotifyTick %s", Owner.BurstPointComponent:GetBurstPointsNum())
        self:SendGameplayEvent(MeshComp)
        Owner.BurstPointComponent:SubBurstPoint()
    end

	return true
end

return NotifyState_BurstPointConsume
