local string = require("string")
local G = require("G")
local InteractionComponent = require("actors.common.components.interaction_component")
local Component = require("common.component")
local check_table = require("common.data.state_conflict_data")

local CircleRoundComponent = Component(InteractionComponent)
local decorator = CircleRoundComponent.decorator

function CircleRoundComponent:Initialize(...)
    Super(CircleRoundComponent).Initialize(self, ...)
end

decorator.message_receiver()
function CircleRoundComponent:OnCapture(Instigator)
    self.actor:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
    self.actor.Instigator = Instigator
end

decorator.message_receiver()
function CircleRoundComponent:OnThrow(Instigator)
    self.actor:SetCollisionEnabled(UE.ECollisionEnabled.QueryAndPhysics)
    self.actor:Multicast_OnThrow()
end

decorator.message_receiver()
function CircleRoundComponent:OnThrowEnd()
    -- 重新抓起来
    self.actor.Instigator.InteractionComponent:CaptureTarget(self.actor)
    self.actor:Multicast_OnThrowEnd()
end


return CircleRoundComponent
