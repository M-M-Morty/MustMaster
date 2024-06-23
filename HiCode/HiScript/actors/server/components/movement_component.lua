local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

local MovementComponent = Component(ComponentBase)
local decorator = MovementComponent.decorator

decorator.engine_callback()
function MovementComponent:Server_SetCharacterRotation_RPC(TargetRotation, bSmooth, TargetInterpSpeed, ActorInterpSpeed)
    local CustomSmoothContext = UE.FCustomSmoothContext()
    CustomSmoothContext.TargetInterpSpeed = TargetInterpSpeed
    CustomSmoothContext.ActorInterpSpeed = ActorInterpSpeed

    self.actor:GetLocomotionComponent():SetCharacterRotation(TargetRotation, bSmooth, CustomSmoothContext)
end

return MovementComponent
