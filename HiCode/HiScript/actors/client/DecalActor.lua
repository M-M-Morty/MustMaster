--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"
local G = require("G")
local Actor = require("common.actor")

---@type BP_DecalSpill_C
local DecalActor = Class(Actor)

function DecalActor:ReceiveBeginPlay()
    self.BoxComponent.OnComponentBeginOverlap:Add(self, self.OnActorEnterDecal)
    self.BoxComponent.OnComponentEndOverlap:Add(self, self.OnActorLeaveDecal)
end

function DecalActor:ReceiveEndPlay()
    self.BoxComponent.OnComponentBeginOverlap:Remove(self, self.OnActorEnterDecal)
    self.BoxComponent.OnComponentEndOverlap:Remove(self, self.OnActorLeaveDecal)
end

function DecalActor:OnActorEnterDecal(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    G.log:debug("DecalActor", "OnActorEnterDecal  %s ", tostring(OtherActor))
    if OtherActor and OtherActor:IsValid() then
        OtherActor:SendMessage("EnterDecal", self)
    end
end

function DecalActor:OnActorLeaveDecal(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    G.log:debug("DecalActor", "OnActorLeaveDecal  %s ", tostring(OtherActor))
    if OtherActor and OtherActor:IsValid() then
        OtherActor:SendMessage("LeaveDecal", self)
    end
end

return RegisterActor(DecalActor)