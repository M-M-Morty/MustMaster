local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local utils = require("common.utils")
local check_table = require("common.data.state_conflict_data")

local GlideComponent = Component(ComponentBase)
local InputModes = require("common.event_const").InputModes
local decorator = GlideComponent.decorator
local CustomMovementModes = require("common.event_const").CustomMovementModes

local Glide_INPUT_TAG = "Glide_INPUT_TAG"

function GlideComponent:Start()
    Super(GlideComponent).Start(self)

    self.InputDirection = UE.FVector2D()
    self.bJumpPressed = false
    self.bSprintAfterGlide = false
end

function GlideComponent:Stop()
    self.bJumpPressed = false

    if self.AircraftActor then
        self.AircraftActor:K2_DestroyActor()
        self.AircraftActor = nil
    end
    
    Super(GlideComponent).Stop(self)
end

-- 在空中的时候，按空格键直接滑翔，不触发跳跃
function GlideComponent:AllowJump()
    local CapsuleComponent = self.actor.CapsuleComponent
    local CapsuleRadius = CapsuleComponent:GetScaledCapsuleRadius()
    local CapsuleHalfHeight_WithoutHemisphere = CapsuleComponent:GetScaledCapsuleHalfHeight_WithoutHemisphere()

    local ActorLocation = self.actor:K2_GetActorLocation()
    local ActorRotation = self.actor:K2_GetActorRotation()
    local UpVector = ActorRotation:GetUpVector()

    local StartPos = ActorLocation - UpVector * CapsuleHalfHeight_WithoutHemisphere
    local EndPos = StartPos - UE.FVector(0, 0, self.GlideCheckHeight)

    local HitResult = UE.FHitResult()
    local ignore = UE.TArray(UE.AActor)

    local bHit = UE.UKismetSystemLibrary.SphereTraceSingleByProfile(self.actor, StartPos, EndPos, CapsuleRadius, self.ClimbObjectDetectionProfile, false, ignore, UE.EDrawDebugTrace.None, HitResult, true)

    if bHit then
        return true
    end

    return false
end

function GlideComponent:JumpAction(value)
    G.log:error("qwt", "GlideComponent:JumpAction %s %s %d %s", self.actor:IsServer(), tostring(value), self.actor.JumpCurrentCount, tostring(self.GlideState))
    if self.GlideState == UE.EHiGlideState.None then
        if value and (self.actor.JumpCurrentCount > 1 or not self:AllowJump()) then
            self:StartGlide()
        else
            self:SendMessage("JumpAction", value)
        end
    elseif value then
        self:StopGlide()
    end

    self.bJumpPressed = value
end

decorator.require_check_action(check_table.Action_Glide)
function GlideComponent:StartGlide()
    self.Overridden.StartGlide(self)

    --G.log:error("qiaowentao", "StartGlide %s", self.actor:IsServer())

    --self:AttachAircraft()
    
    self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Custom, CustomMovementModes.Glide)

    if self.actor:IsClient() then
  
        if self.actor.AppearanceComponent.DesiredGait == UE.EHiGait.Sprinting then
            self.bSprintAfterGlide = true
        end
        self.actor.AppearanceComponent:SprintAction(false)
        --G.log:info("qwt", "GlideComponent:StartGlide bSprintAfterGlide: %s", tostring(self.bSprintAfterGlide))
        
        local PlayerController = self.actor.PlayerState:GetPlayerController()
        if PlayerController then
            PlayerController:SendMessage("RegisterIMC", Glide_INPUT_TAG, {"Glide",}, {})
        else 
            G.log:error(self.__TAG__, "can not get PlayerController")
        end
        self:Server_StartGlide()
    end
end

function GlideComponent:StopGlide()
    self.Overridden.StopGlide(self)
    if self.actor:IsClient() then
        local PlayerController = self.actor.PlayerState:GetPlayerController()
        if PlayerController then
            PlayerController:SendMessage("UnregisterIMC", Glide_INPUT_TAG)
        end
    end

    if self.AircraftAttached then
        self:DetachAircraft()
    end

    --G.log:error("qwt", "StopGlide %s", self.actor:IsServer())

    self:SendMessage("EndState", check_table.State_Glide)

    if self.actor:IsOnFloor() then
        self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Walking)
    else
        self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Falling)
    end

    if self.actor:IsClient() then
        if self.bSprintAfterGlide then
            self.actor.AppearanceComponent:SprintAction(true)
        end
        self:Server_StopGlide()
    end
end

function GlideComponent:OnLandedCallback(Hit)
    self:StopGlide()
end

decorator.message_receiver()
function GlideComponent:UpdateCustomMovement(DeltaSeconds)
    local CustomMode = self.actor.CharacterMovement.CustomMovementMode
    if CustomMode == CustomMovementModes.Glide then
        self:PhysGlide(DeltaSeconds)
    end
end

decorator.message_receiver()
function GlideComponent:BreakGlide(reason)
    self:StopGlide()
end

function GlideComponent:CheckGlide()
    if self.bJumpPressed then
        self:StartGlide()
    end
end

function GlideComponent:MoveForward(value)
    self.InputDirection.X = value
    if math.abs(value) <= G.EPS and  math.abs(self.InputDirection.Y) <= G.EPS then
        self.bSprintAfterGlide = false
    end
    --G.log:info("qwt", "GlideComponent:MoveForward value: %s Server: %s bSprintAfterGlide: %s", tostring(value), tostring(self.actor:IsServer()), tostring(self.bSprintAfterGlide))
    self.actor:AddMovementInput(UE.FVector(value, 0, 0), 1.0)
end

function GlideComponent:MoveRight(value)
    self.InputDirection.Y = value
    if math.abs(value) <= G.EPS and  math.abs(self.InputDirection.X) <= G.EPS then
        self.bSprintAfterGlide = false
    end
    --G.log:info("qwt", "GlideComponent:MoveRight value: %s Server: %s bSprintAfterGlide: %s", tostring(value), tostring(self.actor:IsServer()), tostring(self.bSprintAfterGlide))
    self.actor:AddMovementInput(UE.FVector(0, value, 0), 1.0)
end

function GlideComponent:AttachAircraft()
    local ExtraData = { SourceActor = self.actor}
    local EquipActor = self.AircraftActor
    if not EquipActor then
        EquipActor = GameAPI.SpawnActor(self.actor:GetWorld(), self.AircraftActorClass, self.actor:GetTransform(), UE.FActorSpawnParameters(), ExtraData)
        self.AircraftActor = EquipActor
    end
    --G.log:error("lizhao", "GlideComponent:AttachAircraft %s %s %s %s", self.actor:IsServer(), G.GetDisplayName(EquipActor), tostring(EquipActor.K2_AttachToComponent), debug.traceback())
    if EquipActor.IsPlayingDeath then
        EquipActor:StopDeath()
    end
    EquipActor:K2_AttachToComponent(self.actor.Mesh, self.AircraftAttachSocket, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, true)
    local WeaponMeshComponent = EquipActor:GetComponentByClass(UE.USkeletalMeshComponent)
    if WeaponMeshComponent then
        WeaponMeshComponent:AddTickPrerequisiteComponent(self.actor.Mesh)
    end
    if EquipActor.SetVisibility then
        EquipActor:SetVisibility(true)
    end
    if EquipActor.SupportPlayBirth and EquipActor:SupportPlayBirth() then
        EquipActor:Birth()
    end
    self.AircraftAttached = true
end

function GlideComponent:DetachAircraft(Immediately)
    local EquipActor = self.AircraftActor
    if EquipActor then
        EquipActor:K2_DetachFromActor(UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld)
        if not Immediately and EquipActor:SupportPlayDeath() then
            EquipActor:Death()
        else
            EquipActor:SetVisibility(false)
        end
        self.AircraftAttached = false
    end
end

function GlideComponent:ProcessGlideRotation(DeltaTime)
    self.Overridden.ProcessGlideRotation(self, DeltaTime)
    if self.actor.CharacterMovement.MovementMode == self.actor.CharacterMovement.GroundMovementMode then
        self.GlideState = UE.EHiGlideState.None
    end
end

function GlideComponent:TryAttachAircraft(Attach)
    if Attach and not self.AircraftAttached and self.GlideState ~= UE.EHiGlideState.None then
        self:AttachAircraft()
    elseif not Attach and self.AircraftAttached then
        self:DetachAircraft()
    end
end

decorator.message_receiver()
function GlideComponent:PlayerBeforeSwitchOut()
    if self.GlideState ~= UE.EHiGlideState.None then
        self:StopGlide()
    end
end

return GlideComponent
