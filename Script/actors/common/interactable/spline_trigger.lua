--
-- DESCRIPTION
--
-- @COSplineTriggerPANY **
-- @AUTHOR **
-- @DATE ${date} ${tiSplineTriggere}
--

---@type BP_SplineTrigger_C

require "UnLua"
local G = require("G")
local ActorBase = require("actors.common.interactable.base.interacted_item")
local SplineTrigger = Class(ActorBase)

local decorator = SplineTrigger.decorator

function SplineTrigger:ReceiveBeginPlay()
    Super(SplineTrigger).ReceiveBeginPlay(self)
end

function SplineTrigger:OnBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    local track = self:GetParentActor()
    if not track then
        return
    end
    if OtherActor == nil then
        return
    end
    if OtherActor.VehicleComponent == nil then
        return
    end
    local spline = track.spline
    G.log:info_obj(self, "SplineTrigger", "%s", OtherActor.VehicleComponent.SplineTrack )
    if spline:IsActorInTrack(OtherActor) then
        G.log:info_obj(self, "SplineTrigger", "already InSplineTrigger!!!!!!!!!!!!!!!!!!!!!!!!")
    elseif OtherActor.VehicleComponent.SplineTrack ~= nil then
        G.log:info_obj(self, "SplineTrigger", "Enter Other SplineTrigger!!!!!!!!!!!!!!!!!!!!!!!!")
    else
        Super(SplineTrigger).OnBeginOverlap(self, OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    end
end

function SplineTrigger:TriggerInteractedItem(PlayerActor, Damage, InteractLocation)
    -- Server Receive pressed F 
    self:GetParentActor().spline:JumpToSplineTrack(self)
end

function SplineTrigger:OnEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    Super(SplineTrigger).OnEndOverlap(self, OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
end

return SplineTrigger
