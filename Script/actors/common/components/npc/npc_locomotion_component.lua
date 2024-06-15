local AppearanceBase = require("actors.common.components.common_appearance")
local Component = require("common.component")
local G = require("G")

local check_table = require("common.data.state_conflict_data")

---@type BP_NpcLocomotionComponent_C
local NpcLocomotionComponent = Component(AppearanceBase)

local decorator = NpcLocomotionComponent.decorator

function NpcLocomotionComponent:ReceiveBeginPlay()
    Super(NpcLocomotionComponent).ReceiveBeginPlay(self)

    self:OnAnimInitialized()
    self.actor.Mesh.OnAnimInitialized:Add(self, self.OnAnimInitialized)
end

decorator.message_receiver()
function NpcLocomotionComponent:OnReceiveTick(DeltaSeconds)
end

function NpcLocomotionComponent:OnAnimInitialized()
end


return NpcLocomotionComponent
