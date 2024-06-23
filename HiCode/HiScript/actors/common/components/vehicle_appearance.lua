local AppearanceBase = require("actors.common.components.common_appearance")
local Component = require("common.component")
local G = require("G")


---@type BP_VehicleAppearance_C
local VehicleAppearance = Component(AppearanceBase)

local decorator = VehicleAppearance.decorator


return VehicleAppearance