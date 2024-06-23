local G = require("G")

local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local equip_const = require("common.const.equip_const")

local weapon_data = require("common.data.weapon_data").data

local WeaponMgr = Component(ComponentBase)

local decorator = WeaponMgr.decorator

function WeaponMgr:Start()
    Super(WeaponMgr).Start(self)
end

function WeaponMgr:Stop()
    Super(WeaponMgr).Stop(self)

    if self:GetWeaponID() then
        self:DestroyWeapon()
    end
end

function WeaponMgr:GetWeaponID()
    self.CharData = self.actor:GetCharData()
    if not self.CharData then
        return
    end

    return self.CharData.weapon_id
end

decorator.message_receiver()
function WeaponMgr:PostBeginPlay()
	local weapon_id = self:GetWeaponID()
    if weapon_id then
        self:InitWeapon()
    end
end

function WeaponMgr:InitWeapon()
    local weapon_info = self:GetWeaponData()
    if weapon_info == nil then
        G.log:error("yj", "%s weapon_info is %s", self.actor:GetDisplayName(), weapon_info)
        return
    end
    for _, equip_id in ipairs(weapon_info.install_id) do
        self:SendMessage("AddEquip", equip_const.EquipType_Weapon, equip_id)
    end
    self:SendMessage("InitWeaponVisibility")
end

function WeaponMgr:DestroyWeapon()
    local weapon_info = self:GetWeaponData()
    for _, equip_id in ipairs(weapon_info.install_id) do
        self:SendMessage("RemoveEquip", equip_const.EquipType_Weapon, equip_id)
    end
    self.actor.Weapons:Clear()
end

decorator.message_receiver()
function WeaponMgr:AddWeapon(Weapon)
    G.log:debug("santi", "WeaponMgr AddWeapon: %s, IsServer: %s", G.GetDisplayName(Weapon), self.actor:IsServer())
    self.actor.Weapons:AddUnique(Weapon)
end

decorator.message_receiver()
function WeaponMgr:RemoveWeapon(Weapon)
    G.log:debug("santi", "WeaponMgr RemoveWeapon: %s, IsServer: %s", G.GetDisplayName(Weapon), self.actor:IsServer())
    self.actor.Weapons:RemoveItem(Weapon)
end

function WeaponMgr:GetWeaponData()
    return weapon_data[self:GetWeaponID()]
end

return WeaponMgr


