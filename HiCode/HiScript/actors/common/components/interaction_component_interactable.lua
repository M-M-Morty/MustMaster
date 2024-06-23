local string = require("string")
local G = require("G")
local InteractionComponent = require("actors.common.components.interaction_component")
local Component = require("common.component")
local check_table = require("common.data.state_conflict_data")

local InteractionComponent_Interactable = Component(InteractionComponent)
local decorator = InteractionComponent_Interactable.decorator

function InteractionComponent_Interactable:Initialize(...)
    Super(InteractionComponent_Interactable).Initialize(self, ...)
end

function InteractionComponent_Interactable:OnCapture(Instigator)
    Super(InteractionComponent_Interactable).OnCapture(self, Instigator)
end

function InteractionComponent_Interactable:OnThrow(Instigator, TargetLocation, StartLocation, ThrowMoveSpeed, EThrowType, ImpulseMag, ThrowRotateInfo)
    Super(InteractionComponent_Interactable).OnThrow(self, Instigator, TargetLocation, StartLocation, ThrowMoveSpeed, EThrowType, ImpulseMag, ThrowRotateInfo)
end

function InteractionComponent_Interactable:OnThrowEnd()
    Super(InteractionComponent_Interactable).OnThrowEnd(self)
end


return InteractionComponent_Interactable
