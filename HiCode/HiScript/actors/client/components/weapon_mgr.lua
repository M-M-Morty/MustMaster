local G = require("G")

local WeaponMgrBase = require("actors.common.components.weapon_mgr")
local Component = require("common.component")

local WeaponMgr = Component(WeaponMgrBase)

local decorator = WeaponMgr.decorator

decorator.message_receiver()
function WeaponMgr:OnClientReady()
    -- G.log:error("devin", "WeaponMgr:OnRep_Controller %s", tostring(self))
	-- local weapon_id = self:GetWeaponID()
    -- if weapon_id then
    --     self:InitWeapon()
    -- end
end

return WeaponMgr


