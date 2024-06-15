--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR PanZiBin
-- @DATE ${date} ${time}
--

require "UnLua"
-- local utils = require("common.utils")
-- local G = require("G")
---@type notify_set_capsule_nocollision
local notify_set_capsule_nocollision = Class()

local function _SetCollisionEnabled(Comp,ECollisionEnabled)
    if Comp and Comp.SetCollisionEnabled then
        Comp:SetCollisionEnabled(ECollisionEnabled or UE.ECollisionEnabled.NoCollision)
    end
end

local function _MainFunc(MeshComp,ECollision_Capsule,ECollision_Mesh)
    local Owner = MeshComp:GetOwner()
    local CapsuleComp = Owner.CapsuleComponent
    _SetCollisionEnabled(CapsuleComp,ECollision_Capsule)
    local Comps = UE.TArray(UE.USceneComponent)
    MeshComp:GetChildrenComponents(true,Comps)
    for _, Comp in pairs(Comps:ToTable()) do 
        _SetCollisionEnabled(Comp,ECollision_Mesh)
    end
end

function notify_set_capsule_nocollision:Received_NotifyBegin(MeshComp, Animation, TotalDuration)
    _MainFunc(MeshComp)
    return true
end

-- function notify_set_capsule_nocollision:Received_NotifyTick(MeshComp, Animation, FrameDeltaTime)
-- end

function notify_set_capsule_nocollision:Received_NotifyEnd(MeshComp, Animation)
    _MainFunc(MeshComp,self.ECollision_Capsule,self.ECollision_MeshAndChild)
    return true
end

return notify_set_capsule_nocollision