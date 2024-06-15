require "UnLua"

local G = require("G")

local ComponentBase = require("common.componentbase")
local Component = require("common.component")

local MountActorCaptureComponent = Component(ComponentBase)

local decorator = MountActorCaptureComponent.decorator

decorator.message_receiver()
function MountActorCaptureComponent:OnThrowByCapturerEnd()
    UE.UKismetSystemLibrary.K2_SetTimerDelegate({self.actor, self.actor.K2_DestroyActor}, 0.1, false)
end

return MountActorCaptureComponent
