local AppearanceBase = require("actors.common.components.common_appearance")
local Component = require("common.component")
local G = require("G")

local check_table = require("common.data.state_conflict_data")

---@type BP_NpcAppearance_C
local NpcAppearance = Component(AppearanceBase)

local decorator = NpcAppearance.decorator

function NpcAppearance:ReceiveBeginPlay()
    Super(NpcAppearance).ReceiveBeginPlay(self)

    self:OnAnimInitialized()
    self.actor.Mesh.OnAnimInitialized:Add(self, self.OnAnimInitialized)
end

decorator.message_receiver()
function NpcAppearance:OnReceiveTick(DeltaSeconds)
end

function NpcAppearance:OnAnimInitialized()
end


return NpcAppearance
