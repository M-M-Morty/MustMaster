--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"
local G = require("G")

local Actor = require("common.actor")

local TreeDestructionActor = Class(Actor)

---@type TreeDestructionBase_C

function TreeDestructionActor:Initialize(...)
    Super(TreeDestructionActor).Initialize(self, ...)
    self.BlastingTreeDict = {}
end
function TreeDestructionActor:ReceiveBeginPlay()    
    
    self.__TAG__ = string.format("TreeDestructionActor(%s, server: %s)", G.GetObjectName(self), self:IsServer())
    self:SwitchShowTrees(true)
end

function TreeDestructionActor:OnHit(Instigator, Causer, Hit, Durability, RemainDurability)
    G.log:debug(self.__TAG__, "OnHit instigator: %s, Causer: %s, Durability: %f, Remain: %f", G.GetObjectName(Instigator), G.GetObjectName(Causer), Durability, RemainDurability)
end

function TreeDestructionActor:OnBreak(Instigator, Causer, Hit, Durability)
    if (Hit.Component:IsA(UE.UStaticMeshComponent)) then
        self:Collapse(Hit.Component)
    end
    if (Hit.Component:IsA(UE.UGeometryCollectionComponent)) then
        local HitFS = self.DestructComponent.HitFS
        local World = self:GetWorld()
        local HitPoint = UE.FVector(Hit.ImpactPoint.X, Hit.ImpactPoint.Y, Hit.ImpactPoint.Z)
        local Transform = UE.UKismetMathLibrary.MakeTransform(HitPoint, UE.UKismetMathLibrary.Conv_VectorToRotator(UE.UKismetMathLibrary.NegateVector(Hit.ImpactNormal)), UE.FVector(1, 1, 1))
        local FSActor = World:SpawnActor(HitFS, Transform, UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, self, self)
        FSActor.UseDirectionalVector = false
        FSActor.UseRadialVector = true
        FSActor.RadialMagnitude = 750
        FSActor:CE_Trigger()
    end
    
end

function TreeDestructionActor:OnMeshFalling(Mesh)
    if self.BlastingTreeDict[Mesh:GetName()] then
        return
    end
    self.BlastingTreeDict[Mesh:GetName()] = true
    
    local BlastingTreeManager = require("actors.common.BlastingTreeManager")
    BlastingTreeManager:AddBlastingTree(Mesh)
end

function TreeDestructionActor:SwitchShowTrees(bSleeping) 
    local StaticMeshComponents = self:K2_GetComponentsByClass(UE.UStaticMeshComponent)
    for i = 1, StaticMeshComponents:Length() do
        local StaticMeshComp = StaticMeshComponents:Get(i)
        if StaticMeshComp:GetName() ~= 'BaseTree' and StaticMeshComp:GetName() ~= 'BaseCube' then
            StaticMeshComp:SetVisibility(not bSleeping)
            if bSleeping then
                StaticMeshComp:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
            else
                StaticMeshComp:SetCollisionEnabled(UE.ECollisionEnabled.QueryAndPhysics)
            end
            

        end
        if StaticMeshComp:GetName() == 'BaseTree' then
            StaticMeshComp:SetVisibility(bSleeping)
        end
    end
    local GCComponents = self:K2_GetComponentsByClass(UE.UGeometryCollectionComponent)
    for i = 1, GCComponents:Length() do
        local GCComp = GCComponents:Get(i)
        GCComp:SetSimulatePhysics(not bSleeping)
        GCComp:SetVisibility(not bSleeping)
    end
    
end
--[[
function TreeDestructionActor:AddPhysicsConstrainComp()
    local StaticMeshComponents = self:K2_GetComponentsByClass(UE.UStaticMeshComponent)
    for i = 1, StaticMeshComponents:Length() do
        local StaticMeshComp = StaticMeshComponents:Get(i)
        if ~StaticMeshComp:IsSimulatingPhysics() then
            local Name = StaticMeshComp:GetName()
            self:AddComponentByClass(UE.UPhysicsConstraintComponent, false, UE.FTransform.Identity, false)
        end

        
        StaticMeshComp:SetMaterial(0, MaterialInstance)
end
]]--
return  RegisterActor(TreeDestructionActor)
