local string = require("string")
local G = require("G")
local InteractionComponentCharacter = require("actors.common.components.interaction_component_character")
local Component = require("common.component")
local check_table = require("common.data.state_conflict_data")

local InteractionComponent_Monster = Component(InteractionComponentCharacter)
local decorator = InteractionComponent_Monster.decorator

function InteractionComponent_Monster:Initialize(...)
    Super(InteractionComponent_Monster).Initialize(self, ...)
end

function InteractionComponent_Monster:OnCapture(Instigator)
    Super(InteractionComponent_Monster).OnCapture(self, Instigator)
end

function InteractionComponent_Monster:OnThrow(Instigator, TargetLocation, StartLocation, ThrowMoveSpeed, EThrowType, ImpulseMag, ThrowRotateInfo)
    Super(InteractionComponent_Monster).OnThrow(self, Instigator, TargetLocation, StartLocation, ThrowMoveSpeed, EThrowType, ImpulseMag, ThrowRotateInfo)
end

function InteractionComponent_Monster:OnThrowEnd()
    Super(InteractionComponent_Monster).OnThrowEnd(self)
end

return InteractionComponent_Monster
