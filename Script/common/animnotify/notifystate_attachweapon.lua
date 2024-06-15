require "UnLua"
local utils = require("common.utils")
local equip_const = require("common.const.equip_const")

local G = require("G")

local NotifyState_AttachWeapon = Class()


function NotifyState_AttachWeapon:Received_NotifyBegin(MeshComp, Animation, TotalDuration, EventReference)
    if not MeshComp:GetOwner() or not MeshComp:GetOwner()._GetComponent then
        return false
    end
    -- G.log:error("Attach Start", "<Control: %d>   Mesh: %s,   Animation: %s", MeshComp:GetOwner():GetLocalRole(), G.GetDisplayName(MeshComp), G.GetDisplayName(Animation))
    local EquipmentComponent = MeshComp:GetOwner():_GetComponent("EquipmentComponent")
    if not EquipmentComponent then
        return false
    end
    -- Attach
    if self.WeaponVisibility:Length() == 0 then
        EquipmentComponent:AttachWeapon(equip_const.StanceType_Fight, Animation)
    else
        for Index = 1, self.WeaponVisibility:Length() do
            local Hand = self.WeaponVisibility:Get(Index)
            EquipmentComponent:AttachSingleWeapon(Hand, equip_const.StanceType_Fight, Animation)
        end
    end
    -- Animation
    for Hand = 1, self.WeaponAnimation:Length() do
        local Montage = self.WeaponAnimation:Get(Hand)
        if Montage then
            EquipmentComponent:PlayWeaponMontage(Hand, Montage, MeshComp:GetAnimInstance(), Animation)
        end
    end
    return true
end


function NotifyState_AttachWeapon:Received_NotifyEnd(MeshComp, Animation, EventReference)
    if not MeshComp:GetOwner() or not MeshComp:GetOwner()._GetComponent then
        return false
    end
    -- G.log:error("Attach End", "<Control: %d>   Mesh: %s,   Animation: %s", MeshComp:GetOwner():GetLocalRole(), G.GetDisplayName(MeshComp), G.GetDisplayName(Animation))
    local EquipmentComponent = MeshComp:GetOwner():_GetComponent("EquipmentComponent")
    if not EquipmentComponent then
        return false
    end
    -- Animation
    for Hand = 1, self.WeaponAnimation:Length() do
        local Montage = self.WeaponAnimation:Get(Hand)
        if Montage then
            EquipmentComponent:StopSyncWeaponMontage(Montage)
        end
    end
    -- Detach
    if self.WeaponVisibility:Length() == 0 then
        EquipmentComponent:AttachWeapon(equip_const.StanceType_Normal, Animation)
    else
        for Index = 1, self.WeaponVisibility:Length() do
            local Hand = self.WeaponVisibility:Get(Index)
            EquipmentComponent:AttachSingleWeapon(Hand, equip_const.StanceType_Normal, Animation)
        end
    end
    return true
end

return NotifyState_AttachWeapon
