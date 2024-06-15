local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local utils = require("common.utils")
local check_table = require("common.data.state_conflict_data")

local CustomMovementModes = require("common.event_const").CustomMovementModes

local JumpInAirComponent = Component(ComponentBase)
local decorator = JumpInAirComponent.decorator

function JumpInAirComponent:Initialize(...)
    Super(JumpInAirComponent).Initialize(self, ...)
end

function JumpInAirComponent:Start()
    Super(JumpInAirComponent).Start(self)
    self.is_jump_in_air = false
    self.TotalJumpTime = 0
    self.DisableJump = false
end

function JumpInAirComponent:Stop()
    Super(JumpInAirComponent).Stop(self)
    self.is_jump_in_air = true
    self.SelectedFixedPointActor = nil
    self.LastSelectedFixedPointActor = nil
end

decorator.message_receiver()
function JumpInAirComponent:OnLevelSequencePlay(DisableJump, DisableSpecAnim)
    self.DisableJump = DisableJump
end

decorator.message_receiver()
function JumpInAirComponent:OnLevelSequenceFinished()
    self.DisableJump = false
end

decorator.message_receiver()
function JumpInAirComponent:JumpAction(InJump)
    -- G.log:error("devin", "JumpInAirComponent:JumpAction %s", tostring(InJump))
    if InJump then
        if self.DisableJump then
            return
        end
        if self.actor.AppearanceComponent:GetInAirState() ~= UE.EHiInAirState.Fly then
            local SelectedActor = self:FixedPointJump()
            if SelectedActor then
                self:FixedPointJumpToActor(SelectedActor)
            else
                self:JumpOnGround(InJump)
            end
        -- else
        --     self:PlayerBeginJumpInAir()
        end
    else
        if self.actor.AppearanceComponent:GetInAirState() ~= UE.EHiInAirState.Fly and not self.SelectedFixedPointActor then
            self.actor:StopJumping()
        end
    end
end

decorator.require_check_action(check_table.Action_Jump)
function JumpInAirComponent:JumpOnGround(InJump)
    G.log:error("devin", "JumpInAirComponent:JumpOnGround %d", self.actor.JumpCurrentCount)
    self.Overridden.JumpAction(self, InJump)
end

decorator.message_receiver()
function JumpInAirComponent:BreakJumpInAirState()
    self:PlayerEndJumpInAir()
end

function JumpInAirComponent:BeginJumpInAir()
    self.actor.CharacterMovement.UpdatedComponent:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_Pawn, UE.ECollisionResponse.ECR_Ignore)
    
    self:PlayJumpMontage()

    local Rotation = self.actor:K2_GetActorRotation()
    if math.abs(Rotation.Pitch) > G.EPS then
        Rotation.Pitch = 0

        local CustomSmoothContext = UE.FCustomSmoothContext()
        CustomSmoothContext.CustomRotationStage = UE.ECustomRotationStage.RotationStage_0
        CustomSmoothContext.TargetInterpSpeed = self.TargetInterpSpeed
        CustomSmoothContext.ActorInterpSpeed = self.ActorInterpSpeed

        self.actor.AppearanceComponent:SetCharacterRotation(Rotation, true, CustomSmoothContext)
    end
end

function JumpInAirComponent:EndJumpInAir()
    if self.is_jump_in_air then
        self:StopJumpMontage()
    end
end

decorator.message_receiver()
function JumpInAirComponent:OnBeginJumpInAir()

end

decorator.message_receiver()
function JumpInAirComponent:OnEndJumpInAir()
end

function JumpInAirComponent:CheckJumpInAirCostAndCD()
    return self.actor.PlayerState.AttributeComponent:TryBeginAction(check_table.Action_JumpInAir, Enum.Enum_ActionType.AirJump)
end

decorator.require_check_action(check_table.Action_JumpInAir, JumpInAirComponent.CheckJumpInAirCostAndCD)
function JumpInAirComponent:PlayerBeginJumpInAir()
    assert(self.actor:IsPlayer())
    if self.actor.AppearanceComponent:GetInAirState() ~= UE.EHiInAirState.Fly then
        return
    end

    self:BeginJumpInAir()
    self:Server_BeginJumpInAir()
end

function JumpInAirComponent:Server_BeginJumpInAir_RPC()
    if not self.actor.PlayerState.AttributeComponent:TryBeginAction(check_table.Action_JumpInAir, Enum.Enum_ActionType.AirJump) then
        self:Server_EndJumpInAir()
        return
    end

    self:Multicast_BeginJumpInAir()
end

function JumpInAirComponent:PlayerEndJumpInAir()
    assert(self.actor:IsPlayer())

    self:EndJumpInAir()
    self:Server_EndJumpInAir()
end

function JumpInAirComponent:FixedPointJump()
    local FixedPointJumpActors = UE.UGameplayStatics.GetAllActorsOfClass(self.actor:GetWorld(), self.FixedPointJumpActorClass)

    local FixedPointJumpActorLength = FixedPointJumpActors:Length()
    -- G.log:error("devin", "JumpInAirComponent:FixedPointJump %d", FixedPointJumpActorLength)

    local PlayerController = UE.UGameplayStatics.GetPlayerController(self.actor:GetWorld(), 0)

    local control_rotation = self.actor:GetControlRotation()
    local DirectionVector = control_rotation:GetForwardVector()
    local UpVector = self.actor:GetActorUpVector()
    local CurrentVel = self.actor:GetVelocity()
    local Speed = CurrentVel:Size2D()

    if Speed > 150 then
        CurrentVel.Z = 0
        DirectionVector = CurrentVel
        DirectionVector:Normalize()
    end

    local PlaneNormal = UpVector

    local DistanceMin = 99999999999.0
    local SelectActor = nil

    local CurrentActor = nil

    if self.LastSelectedFixedPointActor then
        local Location = self.LastSelectedFixedPointActor:K2_GetActorLocation()
        local TargetVector = Location - self.actor:K2_GetActorLocation()
        local Distance = TargetVector:SizeSquared()

        if Distance < self.LastSelectedFixedPointActor.Range * self.LastSelectedFixedPointActor.Range then
            CurrentActor = self.LastSelectedFixedPointActor
        end
    end

    if not CurrentActor then
        for FixedPointJumpActorIndex = 1, FixedPointJumpActorLength do
            local FixedPointJumpActor = FixedPointJumpActors:Get(FixedPointJumpActorIndex)
            local Location = FixedPointJumpActor:K2_GetActorLocation()
            local TargetVector = Location - self.actor:K2_GetActorLocation()
            local Distance = TargetVector:SizeSquared()

            if Distance < FixedPointJumpActor.Range * FixedPointJumpActor.Range then
                CurrentActor = FixedPointJumpActor
                break
            end
        end
    end

    for FixedPointJumpActorIndex = 1, FixedPointJumpActorLength do
        local FixedPointJumpActor = FixedPointJumpActors:Get(FixedPointJumpActorIndex)

        if CurrentActor ~= FixedPointJumpActor then
            if not (FixedPointJumpActor:ActorHasTag("FixedPointExit") and (not CurrentActor or (CurrentActor and CurrentActor:ActorHasTag("FixedPointExit")))) then
                local Location = FixedPointJumpActor:K2_GetActorLocation()

                local ScreenPos = UE.FVector2D()
                if UE.UGameplayStatics.ProjectWorldToScreen(PlayerController, Location, ScreenPos) then

                    local ScreenPosX = 0
                    local ScreenPosY = 0
                    ScreenPosX, ScreenPosY = PlayerController:GetViewportSize(ScreenPosX, ScreenPosY)
                    if not (ScreenPos.X < 0 or ScreenPos.X > ScreenPosX or ScreenPos.Y < 0 or ScreenPos.Y > ScreenPosY) then
                        local TargetVector = Location - self.actor:K2_GetActorLocation()
                        local Distance = TargetVector:SizeSquared()

                       -- G.log:error("devin", "JumpInAirComponent:FixedPointJump 111 %s, %f %f %f", FixedPointJumpActor:GetName(), Distance, FixedPointJumpActor.MinRange, FixedPointJumpActor.MaxRange)

                        if Distance <= FixedPointJumpActor.MaxRange * FixedPointJumpActor.MaxRange then
                            if Distance >= FixedPointJumpActor.MinRange * FixedPointJumpActor.MinRange then
                                local ProjectTargetVector = UE.UKismetMathLibrary.ProjectVectorOnToPlane(TargetVector, PlaneNormal)
                                ProjectTargetVector:Normalize()

                                local Angle = UE.UKismetMathLibrary.DegAcos(ProjectTargetVector:Dot(DirectionVector))

                                -- G.log:error("devin", "JumpInAirComponent:FixedPointJump 222 %f", Angle)

                                if Angle < self.FixedPointJumpAngle then
                                    if DistanceMin > Distance then
                                        SelectActor = FixedPointJumpActor
                                        DistanceMin = Distance
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return SelectActor
end

decorator.require_check_action(check_table.Action_FixedPointJump)
function JumpInAirComponent:FixedPointJumpToActor(SelectActor)

    -- G.log:error("devin", "JumpInAirComponent:FixedPointJumpToLocation 111 %s %s", tostring(TargetLocation), tostring(SelectActor.GravitySpeed))
    
    local TargetLocation = SelectActor:K2_GetActorLocation()
    TargetLocation.Z = TargetLocation.Z + self.actor.CapsuleComponent:GetScaledCapsuleHalfHeight()

    local SelfLocation = self.actor:K2_GetActorLocation()
    
    local LaunchVelocity = UE.FVector(0, 0, 0)
    UE.UGameplayStatics.SuggestProjectileVelocity_CustomArc(self.actor:GetWorld(), LaunchVelocity, SelfLocation, TargetLocation, SelectActor.GravitySpeed, SelectActor.ArcParam)

    self.TotalJumpTime = (TargetLocation - SelfLocation):Size2D() / UE.FVector(LaunchVelocity.X, LaunchVelocity.Y, 0):Size2D()

    local UpHeight = LaunchVelocity.Z * LaunchVelocity.Z / (2 * SelectActor.GravitySpeed)
	local UpTime = LaunchVelocity.Z / SelectActor.GravitySpeed

	local ZHeight = SelfLocation.Z - TargetLocation.Z + UpHeight

    self.SelectedFixedPointActor = SelectActor

	--self.TotalJumpTime = UpTime + math.sqrt(2 * ZHeight/SelectActor.GravitySpeed)
	self.ZVelocity = UE.FVector(0, 0, LaunchVelocity.Z)
	self.XYVelocity = UE.FVector(LaunchVelocity.X, LaunchVelocity.Y, 0)

    self.MovementModePre = self.actor.CharacterMovement.MovementMode
    self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Custom, CustomMovementModes.FixedPointJump)

    self.MovementActionPre = self.actor.AppearanceComponent:GetMovementAction()
    self.actor.AppearanceComponent:SetMovementAction(UE.EHiMovementAction.Custom, true)
    --Combine move is closed by default
    --self.actor.CharacterMovement:SetForceNoCombine(true)
    self.actor.CharacterStateManager.FixedPointJump = true

    self.InFixedPointJump.LandPrediction = -1

    if self.actor:IsPlayer() then
        self:Server_FixedPointJumpToActor(SelectActor)
    end
end

function JumpInAirComponent:OnFixedPointJumpEnd()
    self.LastSelectedFixedPointActor = self.SelectedFixedPointActor
    self.SelectedFixedPointActor = nil
    self.TotalJumpTime = 0

    local CharacterMovement = self.actor.CharacterMovement
    local CurrentRotation = self.actor:K2_GetActorRotation()
    local FaceDirection = UE.FVector(CharacterMovement.Velocity.X, CharacterMovement.Velocity.Y, 0)

    if not UE.UKismetMathLibrary.Vector_IsNearlyZero(FaceDirection) then
        CurrentRotation.Yaw = UE.UKismetMathLibrary.Conv_VectorToRotator(FaceDirection).Yaw
        self.actor:K2_SetActorRotation(CurrentRotation, true)
    end

    self.actor.CharacterMovement:SetMovementMode(self.MovementModePre)
    self.actor.AppearanceComponent:SetMovementAction(self.MovementActionPre, true)
    self.actor.CharacterMovement.Velocity = UE.FVector(0, 0, 0)
    --Combine move is closed by default
    --self.actor.CharacterMovement:SetForceNoCombine(false)
    self:SendMessage("EndState", check_table.State_FixedPointJump)

    self:EnterFixedPointJumpLand()
end

function JumpInAirComponent:OnFixedPointJumpLandEnd()
    self.actor.CharacterStateManager.FixedPointJump = false
end

decorator.require_check_action(check_table.Action_FixedPointJumpLand)
function JumpInAirComponent:EnterFixedPointJumpLand()
end

decorator.message_receiver()
function JumpInAirComponent:UpdateCustomMovement(DeltaSeconds)
    local CustomMode = self.actor.CharacterMovement.CustomMovementMode
    if CustomMode == CustomMovementModes.FixedPointJump then
        self:PhysFixedPointJump(DeltaSeconds)
    end
end

function JumpInAirComponent:PhysFixedPointJump(DeltaSeconds)
    if not self.SelectedFixedPointActor then
        return
    end

    --local IsServer = self.actor:IsServer()
    --G.log:error("devin", "JumpInAirComponent:PhysFixedPointJump 111 %s %s", tostring(IsServer), tostring(self.actor:K2_GetActorRotation()))

    local CharacterMovement = self.actor.CharacterMovement
    CharacterMovement.Velocity = self.XYVelocity + self.ZVelocity

    local CurrentRotation = self.actor:K2_GetActorRotation()

    local NewRotation = UE.FRotator()
    local FaceDirection = UE.FVector(CharacterMovement.Velocity.X, CharacterMovement.Velocity.Y, 0)
    if not UE.UKismetMathLibrary.Vector_IsNearlyZero(FaceDirection) then
        NewRotation.Yaw = UE.UKismetMathLibrary.Conv_VectorToRotator(FaceDirection).Yaw
    else
        NewRotation = CurrentRotation
    end

    NewRotation.Yaw = UE.UMathHelper.FAngleNearestInterpConstantTo(CurrentRotation.Yaw, NewRotation.Yaw, DeltaSeconds, self.FixedPointJumpYawInterpSpeed)

    local Delta = CharacterMovement.Velocity * DeltaSeconds
    self.TotalJumpTime = self.TotalJumpTime - DeltaSeconds

    if self.TotalJumpTime < self.FixedPointJumpLandPredictionTime then
        self.InFixedPointJump.LandPrediction = self.FixedPointJumpLandPredictionTime - self.TotalJumpTime
    end

    local HitResult = UE.FHitResult()
    local Success = CharacterMovement:K2_MoveUpdatedComponent(Delta, NewRotation, HitResult, true)
    if (not Success or self.TotalJumpTime <= 0) and self.actor:IsServer() then
        self:Multicast_OnFixedPointJumpEnd()
        return
    end

    self.ZVelocity = self.ZVelocity + UE.FVector(0, 0, self.SelectedFixedPointActor.GravitySpeed) * DeltaSeconds

    --G.log:error("devin", "JumpInAirComponent:PhysFixedPointJump %s %s %s %s %f", tostring(IsServer), tostring(FaceDirection), tostring(NewRotation), tostring(self.actor:K2_GetActorRotation()), self.SelectedFixedPointActor.GravitySpeed)
end

function JumpInAirComponent:PlayJumpMontage()
    self.is_jump_in_air = true
    self:SendMessage("OnBeginJumpInAir")
    local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.actor.Mesh, self.JumpMontage, 1.0)
    local InterruptedCallback = function(name)
                        self.OnJumpMontageEnd(self, name)
                    end
    local CompletedCallback = function(name)
                        self.OnJumpMontageEnd(self, name)
                    end
    PlayMontageCallbackProxy.OnInterrupted:Add(self.actor, InterruptedCallback)
    PlayMontageCallbackProxy.OnCompleted:Add(self.actor, CompletedCallback)
end

function JumpInAirComponent:StopJumpMontage()
    self.actor.StopJumpMontage(self.JumpMontage)
    if self.actor:IsPlayer() then
        self:SendMessage("EndState", check_table.State_JumpInAir)
    end
end

function JumpInAirComponent:OnJumpMontageEnd(name)
    self.is_jump_in_air = false
    self.actor.PlayerState.AttributeComponent:TryEndAction(Enum.Enum_ActionType.AirJump)
    self:SendMessage("OnEndJumpInAir")
    self.actor.CharacterMovement.UpdatedComponent:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_Pawn, UE.ECollisionResponse.ECR_Block)
    if self.actor:IsPlayer() then
        self:SendMessage("EndState", check_table.State_JumpInAir)
    end
end

function JumpInAirComponent:EventOnJumped()
    self.Overridden.EventOnJumped(self)
    self:SendMessage("OnJumped")
end

function JumpInAirComponent:EventOnLanded()
    self.Overridden.EventOnLanded(self)
    self:SendMessage("OnLanded")
end

function JumpInAirComponent:LandedAutoJumpAction()
    if self.actor.CharacterMovement.MovementMode == self.actor.CharacterMovement.GroundMovementMode then
        self:SendMessage("JumpAction",true)
    end
end

decorator.message_receiver()
function JumpInAirComponent:BreakFixedPointJump(reason)
    -- G.log:error("devin", "JumpInAirComponent:BreakFixedPointJump %d", tostring(reason))
    self:Server_OnFixedPointJumpEnd()
    --self.actor.CharacterStateManager.FixedPointJump = false
end

decorator.message_receiver()
function JumpInAirComponent:BreakFixedPointJumpLand(reason)
    -- G.log:error("devin", "JumpInAirComponent:BreakFixedPointJump %d", tostring(reason))
    self:OnFixedPointJumpLandEnd()
    self:Server_OnFixedPointJumpLandEnd()
end

return JumpInAirComponent