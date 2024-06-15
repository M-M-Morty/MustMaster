require "UnLua"

local G = require("G")

local Actor = require("common.actor")

local PhysicsAnimationActor = Class(Actor)

function PhysicsAnimationActor:ReceiveBeginPlay()
    Super(PhysicsAnimationActor).ReceiveBeginPlay(self)

    self.PhysicalAnimation:SetSkeletalMeshComponent(self.SkeletalMesh)
    local Bones = self.PhysicsBones
    for PhyicsBonesIndex = 1, Bones:Length() do
        local PhysicsBone = Bones:Get(PhyicsBonesIndex)
        if PhysicsBone.EnableSimulate then
            self.PhysicalAnimation:ApplyPhysicalAnimationSettingsBelow(PhysicsBone.BoneName, self.PhysicalAnimationConfig)
        end
    end
end

function PhysicsAnimationActor:ReceiveEndPlay(Reason)
    Super(PhysicsAnimationActor).ReceiveEndPlay(self, Reason)
    self.PhysicalAnimation:SetSkeletalMeshComponent(nil)
end

function PhysicsAnimationActor:EnableSimulatePhysics(Enable)
    local Bones = self.PhysicsBones
    for PhyicsBonesIndex = 1, Bones:Length() do
        local PhysicsBone = Bones:Get(PhyicsBonesIndex)
        if not Enable then
            self.SkeletalMesh:SetAllBodiesBelowPhysicsBlendWeight(PhysicsBone.BoneName, 0.0, false, PhysicsBone.IncludeSelf)
        end
        self.SkeletalMesh:SetAllBodiesBelowSimulatePhysics(PhysicsBone.BoneName, Enable and PhysicsBone.EnableSimulate, PhysicsBone.IncludeSelf)
    end
end

function PhysicsAnimationActor:SetBlendWeight(BlendWeight)
    local Bones = self.PhysicsBones
    for PhyicsBonesIndex = 1, Bones:Length() do
        local PhysicsBone = Bones:Get(PhyicsBonesIndex)
        if PhysicsBone.EnableSimulate then
            self.SkeletalMesh:SetAllBodiesBelowPhysicsBlendWeight(PhysicsBone.BoneName, BlendWeight, false, PhysicsBone.IncludeSelf)
        else
            self.SkeletalMesh:SetAllBodiesBelowPhysicsBlendWeight(PhysicsBone.BoneName, 0.0, false, PhysicsBone.IncludeSelf)
        end
    end
end

return PhysicsAnimationActor






