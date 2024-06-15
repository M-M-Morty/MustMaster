local G = require("G")

local VehicleMgrBase = require("actors.common.components.vehicle_mgr")
local Component = require("common.component")

local VehicleMgr = Component(VehicleMgrBase)
local decorator = VehicleMgr.decorator

return VehicleMgr
