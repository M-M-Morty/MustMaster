local G = require("G")

local WeaponMgrBase = require("actors.common.components.weapon_mgr")
local Component = require("common.component")

local WeaponMgr = Component(WeaponMgrBase)
local decorator = WeaponMgr.decorator

return WeaponMgr
