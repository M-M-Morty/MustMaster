require "UnLua"
local utils = require("common.utils")

local G = require("G")

local NotifyState_PlayWeaponMontage = Class()


function NotifyState_PlayWeaponMontage:Received_NotifyBegin(MeshComp, Animation, TotalDuration, EventReference)
    if not MeshComp:GetOwner() or not MeshComp:GetOwner()._GetComponent then
        return
    end

    local EquipmentComponent = MeshComp:GetOwner():_GetComponent("EquipmentComponent")
    if not EquipmentComponent then
        return false
    end
    for Hand = 1, self.WeaponAnimation:Length() do
        local Montage = self.WeaponAnimation:Get(Hand)
        if Montage then
            EquipmentComponent:PlayWeaponMontage(Hand, Montage, MeshComp:GetAnimInstance(), Animation)
        end
    end
    return true
end

function NotifyState_PlayWeaponMontage:Received_NotifyEnd(MeshComp, Animation, EventReference)
    if not MeshComp:GetOwner() or not MeshComp:GetOwner()._GetComponent then
        return
    end

    local EquipmentComponent = MeshComp:GetOwner():_GetComponent("EquipmentComponent")
    if not EquipmentComponent then
        return false
    end
    for Hand = 1, self.WeaponAnimation:Length() do
        local Montage = self.WeaponAnimation:Get(Hand)
        if Montage then
            EquipmentComponent:StopSyncWeaponMontage(Montage)
        end
    end
    return true
end

return NotifyState_PlayWeaponMontage
