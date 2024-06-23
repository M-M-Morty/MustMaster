require "UnLua"
---DestructibleStatic used for non-chaos destructible.

local G = require("G")

local Destructible = require("actors.common.Destructible")

local DestructibleStatic = Class(Destructible)

function DestructibleStatic:Initialize(...)
    Super(DestructibleStatic).Initialize(self, ...)

    self.bBreak = false
end

function DestructibleStatic:ReceiveBeginPlay()
    Super(DestructibleStatic).ReceiveBeginPlay(self)

    self.__TAG__ = string.format("DestructibleStatic(%s, server: %s)", G.GetObjectName(self), self:IsServer())
end

function DestructibleStatic:ReceiveAsyncPhysicsTick(DeltaSeconds, SimSeconds)
    self:SendMessage("ReceiveAsyncPhysicsTick", DeltaSeconds, SimSeconds)
end

--[[
    Implement BPI_Destructible interface.
]]
function DestructibleStatic:OnHit(Instigator, Causer, Hit, Durability, RemainDurability)
    if self.bBreak then
        return
    end
    self.bBreak = true
    G.log:debug(self.__TAG__, "OnHit instigator: %s, Causer: %s, Durability: %f, Remain: %f", G.GetObjectName(Instigator), G.GetObjectName(Causer), Durability, RemainDurability)

    local LinearVelocity = self.StaticMesh:GetPhysicsLinearVelocity()
    local AngularVelocity = self.StaticMesh:GetPhysicsAngularVelocityInDegrees()

    self.StaticMesh:SetStaticMesh(self.InteractionComponent.BrokenMesh)

    -- Recover speed after change mesh.
    self.StaticMesh:SetPhysicsLinearVelocity(LinearVelocity)
    self.StaticMesh:SetPhysicsAngularVelocityInDegrees(AngularVelocity)
end

function DestructibleStatic:OnBreak(Instigator, Causer, Hit, Durability)
end

--[[
    Handle capture and throw behavior.
]]
function DestructibleStatic:OnCapture(Instigator)
    G.log:debug(self.__TAG__, "OnCapture by %s", G.GetObjectName(Instigator))

    local TargetComponent = self:GetTargetComponent()
    if TargetComponent then
        TargetComponent:SetSimulatePhysics(false)
        TargetComponent:SetMobility(UE.EComponentMobility.Movable)
        TargetComponent:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
        TargetComponent:IgnoreActorWhenMoving(Instigator, true)
    end
end

function DestructibleStatic:OnAbsorbCancel()
    self:OnReset()
end

function DestructibleStatic:OnThrow(Instigator, TargetLocation, StartLocation, ThrowType)
    G.log:debug(self.__TAG__, "OnThrow by %s, start pos: %s, ThrowType: %d", G.GetObjectName(Instigator), StartLocation, ThrowType)
    self:K2_SetActorLocation(StartLocation, false, nil, true)

    local TargetComponent = self:GetTargetComponent()
    local ProjectileMovement = self.ProjectileMovementComponent
    local bProjectileActive = false
    if TargetComponent then
        if ThrowType == Enum.Enum_ThrowType.Physics then
            TargetComponent:SetSimulatePhysics(true)
            TargetComponent:SetCollisionEnabled(UE.ECollisionEnabled.QueryAndPhysics)
        elseif ThrowType == Enum.Enum_ThrowType.Projectile then
            TargetComponent:SetSimulatePhysics(false)
            TargetComponent:SetCollisionEnabled(UE.ECollisionEnabled.QueryOnly)
            bProjectileActive = true
        else
            TargetComponent:SetSimulatePhysics(false)
            TargetComponent:SetCollisionEnabled(UE.ECollisionEnabled.QueryOnly)
        end

        if ProjectileMovement then
            ProjectileMovement:SetActive(bProjectileActive)
        end
    end
end

function DestructibleStatic:OnThrowEnd()
    self:OnReset()
end

function DestructibleStatic:OnDestroy(Hit)
    G.log:debug(self.__TAG__, "OnDestroy")
    self:OnReset()
end

function DestructibleStatic:OnReset()
    local TargetComponent = self:GetTargetComponent()
    TargetComponent:SetSimulatePhysics(true)
    TargetComponent:SetCollisionEnabled(UE.ECollisionEnabled.QueryAndPhysics)
    TargetComponent:ClearMoveIgnoreActors()
end

function DestructibleStatic:Destroy()
    Super(DestructibleStatic).Destroy(self)

    G.log:debug(self.__TAG__, "Destroy")
end

return RegisterActor(DestructibleStatic)
