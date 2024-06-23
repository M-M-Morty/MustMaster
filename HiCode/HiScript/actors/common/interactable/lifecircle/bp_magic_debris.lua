--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require('G')

---@type bp_magic_debris_C
local ActorBase = require("actors.common.interactable.base.interacted_item")
local M = Class(ActorBase)

function M:LogInfo(...)
    G.log:info_obj(self, ...)
end

function M:LogDebug(...)
    G.log:debug_obj(self, ...)
end

function M:LogWarn(...)
    G.log:warn_obj(self, ...)
end

function M:LogError(...)
    G.log:error_obj(self, ...)
end

local playerCharacterBlueprintClass = UE.UClass.Load('/Game/Blueprints/Character/BPA_AvatarBase.BPA_AvatarBase_C')

-- function M:Initialize(Initializer)
-- end

function M:ReceiveBeginPlay()
    Super(M).ReceiveBeginPlay(self)
    self:LogInfo('zsf', '[debris] ReceiveBeginPlay')
    self.Cylinder:SetVisibility(false, true)
    if self:HasAuthority() then
        self:UpdateCylinderShape()
        self.Cylinder:SetGenerateOverlapEvents(false)
        self:SetInteractable(true)
    else
        self.Cylinder.OnComponentBeginOverlap:Add(self, self.OnClientBeginOverlap_Cylinder)
        self.Cylinder.OnComponentEndOverlap:Add(self, self.OnClientEndOverlap_Cylinder)

        self.PreviewRotateComponent = self.Niagara
        self:StopRotating()
    end
end

-- function M:ReceiveEndPlay()
-- end

function M:ReceiveTick(DeltaSeconds)
    if not self:HasAuthority() then
        self:OnClientTick(DeltaSeconds)
    end
end

-- function M:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
-- end

-- function M:ReceiveActorBeginOverlap(OtherActor)
-- end

-- function M:ReceiveActorEndOverlap(OtherActor)
-- end

function M:SetInteractable(bCan)
    self:LogInfo('zsf', '[debris] SetInteractable %s %s', self:HasAuthority(), bCan)
    if not self:HasAuthority() then
        return
    end
    self.bInteractable = bCan
end

function M:GetInteractable()
    return self.bInteractable
end

function M:StartProjectileMove(TargetLocation, ArcParam)

    local gravityScale = 6.0
    local overrideGravityZ = -980 * gravityScale

    local OutVelocity = UE.FVector()
    UE.UGameplayStatics.SuggestProjectileVelocity_CustomArc(self, OutVelocity, self:K2_GetActorLocation(), TargetLocation, overrideGravityZ, ArcParam)

    self:LogInfo('zsf', '[debris] StartProjectileMove %s %s %s %s %s %s %s', OutVelocity, self:K2_GetActorLocation(), TargetLocation, overrideGravityZ, ArcParam, self:K2_GetRootComponent(), self.ProjectileMovement:IsActive())
    self.TargetLocation = TargetLocation

    self.ProjectileMovement:SetUpdatedComponent(self:K2_GetRootComponent())
    self.ProjectileMovement:SetComponentTickEnabled(true)
    self.ProjectileMovement.ProjectileGravityScale = gravityScale
    self.ProjectileMovement.Velocity = OutVelocity

    self.ProjectileMovement.OnProjectileStop:Add(self, self.OnProjectileMoveStop)
end

function M:StopProjectileMove()
    self.ProjectileMovement:SetComponentTickEnabled(false)
    self.ProjectileMovement.ProjectileGravityScale = 0.0
    self.ProjectileMovement.Velocity = UE.FVector(0,0,0)
end

function M:OnProjectileMoveStop(ImpactResult)
    self:LogInfo('zsf', '[debris] OnProjectileMoveStop %s', ImpactResult)
    self:StopProjectileMove()
    --TODO(dougzhang): 这里有问题
    if self.TargetLocation then
        self:K2_SetActorLocation(self.TargetLocation, false, nil, true)
    end
end

function M:StartRotating(RotationRate, PivotRadius)
    if self.bComponentRotating then
        return
    end

    self.bComponentRotating = true
    self.RotationRate = RotationRate

    local randomRot = UE.FRotator(0, UE.UKismetMathLibrary.RandomFloatInRange(0, 360), 0)
    local initLocation = randomRot:RotateVector(UE.FVector(PivotRadius,0,0))

    if self.PreviewRotateComponent then
        self.PreviewRotateComponent:SetRelativeScale3D(UE.FVector(0.6, 0.6, 0.6))
        self.PreviewRotateComponent:K2_SetRelativeLocation(initLocation, false, UE.FHitResult(), true)
    end
end

function M:StopRotating()
    self.bComponentRotating = false
    self.RotationRate = 0

    if self.PreviewRotateComponent then
        self.PreviewRotateComponent:SetRelativeScale3D(UE.FVector(1,1,1))
        self.PreviewRotateComponent:K2_SetRelativeLocation(UE.FVector(0, 0, 0), false, UE.FHitResult(), true)
    end
end

function M:OnRep_bInteractable()
    self:LogInfo('zsf', '[debris] OnRep_bInteractable %s %s', self:HasAuthority(), self.bInteractable)
    if self:HasAuthority() then
        return
    end
    self.Cylinder:SetGenerateOverlapEvents(self.bInteractable)

    -- force update overlapping
    local myCollisionProfile = self.Cylinder:GetCollisionProfileName()
    self.Cylinder:SetCollisionProfileName('NoCollision')
    self.Cylinder:SetCollisionProfileName(myCollisionProfile, true)
end

function M:GetPlayerActor(OtherActor)
    if OtherActor.EdRuntimeComponent then
        return OtherActor
    end
end

function M:IsMagicDebris()
    return true
end

---@param InvokerActor AActor
function M:DoClientInteractAction(InvokerActor)
    if not self:HasAuthority() and self:GetInteractable() and InvokerActor then
        ---@type BP_ThirdPersonCharacter_C
        local playerActor = self:GetPlayerActor(InvokerActor)
        if playerActor then
            playerActor.EdRuntimeComponent:Server_InteractEvent(self, 100.0, UE.FVector(0,0,0))
            self:LogInfo('zsf', '%s Interact with %s', G.GetDisplayName(playerActor), G.GetDisplayName(self))
        end
    end
end

-- called by ServerInteractEvent
---@param InvokerActor AActor
---@param InteractLocation Vector
function M:DoServerInteractAction(InvokerActor, Damage, InteractLocation)
    if self:HasAuthority() and self:GetInteractable() then
        ---@type BP_ThirdPersonCharacter_C
        local playerActor = self:GetPlayerActor(InvokerActor)
        if playerActor then
            -- check overlapping
            local tbObjectTypes = { UE.EObjectTypeQuery.Pawn }
            local _, arrOverlapping = UE.UKismetSystemLibrary.ComponentOverlapActors(self.Cylinder, self.Cylinder:K2_GetComponentToWorld(), tbObjectTypes, playerCharacterBlueprintClass, {})
            if arrOverlapping:Contains(playerActor) then
                self:SetInteractable(false)
                playerActor.PickupInventoryComponent:ServerAddSceneObject(self)
            end
        end
    end
end

---@param OverlappedComponent UPrimitiveComponent
---@param OtherActor AActor
---@param OtherComp UPrimitiveComponent
---@param SweepResult FHitResult
function M:OnClientBeginOverlap_Cylinder(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    self:LogInfo('zsf', '[debris] OnClientBeginOverlap_Cylinder %s', G.GetDisplayName(OtherActor))
    if self:HasAuthority() then
        return
    end

    if self:GetInteractable() then
        ---@type BP_ThirdPersonCharacter_C
        local playerActor = self:GetPlayerActor(OtherActor)
        if playerActor then
            playerActor.EdRuntimeComponent:AddNearbyActor(self)
        end
    end
end

---@param OverlappedComponent UPrimitiveComponent
---@param OtherActor AActor
---@param OtherComp UPrimitiveComponent
function M:OnClientEndOverlap_Cylinder(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    if self:HasAuthority() then
        return
    end

    ---@type BP_ThirdPersonCharacter_C
    local playerActor = self:GetPlayerActor(OtherActor)
    if playerActor then
        playerActor.EdRuntimeComponent:RemoveNearbyActor(self)
    end
end

function M:OnClientTick(DeltaSeconds)
    if self.bComponentRotating and self.PreviewRotateComponent then
        local deltaYaw = DeltaSeconds * self.RotationRate
        local deltaRot = UE.FRotator(0, deltaYaw, 0)
        local relativeLocation = self.PreviewRotateComponent.RelativeLocation
        local rotVector = deltaRot:RotateVector(relativeLocation)
        self.PreviewRotateComponent:K2_SetRelativeLocation(rotVector, false, UE.FHitResult(), true)
    end
end

return M
