--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@type BP_SplineTrack_C
require "UnLua"

local BPConst = require("common.const.blueprint_const")
local Actor = require("common.actor")

local SplineTrack = Class(Actor)

local G = require("G")


-- function M:Initialize(Initializer)
-- end

-- function M:UserConstructionScript()
-- end

function SplineTrack:ReceiveBeginPlay()
    Super(SplineTrack).ReceiveBeginPlay(self)
end

function SplineTrack:OnConstruction()
    G.log:error("OnConstruction", "!!!!")
end

-- function M:ReceiveTick(DeltaSeconds)
-- end

-- function M:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
-- end

-- function M:ReceiveActorBeginOverlap(OtherActor)
-- end

-- function M:ReceiveActorEndOverlap(OtherActor)
-- end

return SplineTrack
