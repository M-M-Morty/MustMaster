require "UnLua"

local G = require("G")

local Component = require("common.component")
local ComponentBase = require("common.componentbase")
local MantleComponent = Component(ComponentBase)

local CustomMovementModes = require("common.event_const").CustomMovementModes
local InputModes = require("common.event_const").InputModes
local SprintClimbEndReason = require("common.event_const").SprintClimbEndReason

local check_table = require("common.data.state_conflict_data")

local decorator = MantleComponent.decorator

local MANTLE_INPUT_TAG = "MANTLE_INPUT_TAG"

function MantleComponent:Start()
    Super(MantleComponent).Start(self)
    self.__TAG__ = string.format("MantleComponent(%s, server: %s)", G.GetObjectName(self.actor), self.actor:IsServer())
    --G.log:debug("devin", "MantleComponent:Start")
    self.ForwardInputValue = 0
    self.RightInputValue = 0
    self.TargetWalkMode = UE.EMovementMode.MOVE_Walking
    self.bPlayMantleAnimation = false
    self.bDelayFinishClimbCamera = false
    self.SprintStartLockRollDuration = 0
    self.SprintKeyDown = false
    self.MantleData.State = Enum.EClimbState.None
    self.bSkipFirstCheck = false
end

function MantleComponent:Stop()
    Super(MantleComponent).Stop(self)

    --G.log:debug("devin", "MantleComponent:Stop")
end

decorator.message_receiver()
function MantleComponent:OnClientReady()
end

function MantleComponent:CheckClimbCostAndCD()
    return self.actor.PlayerState.AttributeComponent:TryBeginAction(check_table.Action_Climb, Enum.Enum_ActionType.Climb)
end
    
decorator.require_check_action(check_table.Action_Climb, MantleComponent.CheckClimbCostAndCD)
function MantleComponent:ClimbStart(WallRunType, HitResult, Direction)
    G.log:debug("devin", "MantleComponent:ClimbStart %s", tostring(self.actor:IsServer()))

    if self.actor:IsServer() and self.actor.PlayerState then
        self.actor.PlayerState.AttributeComponent:TryBeginAction(check_table.Action_Climb, Enum.Enum_ActionType.Climb, self, function()
            self.OnClimbStartSuccess(self, WallRunType, HitResult, Direction)
        end, self.OnServerClimbStartFail)
    else
        self.OnClimbStartSuccess(self, WallRunType, HitResult, Direction)
    end

    if self.actor:IsClient() then
        self:Server_ClimbStart(WallRunType, HitResult, Direction)
    end
end

function MantleComponent:OnClimbStartSuccess(WallRunType, HitResult, Direction)

    -- G.log:error("devin", "MantleComponent:OnSprintClimbStartSuccess %s %f %f %s %s %s", tostring(self.actor:IsServer()), self.ForwardInputValue, self.RightInputValue, tostring(self.bPlayMantleAnimation), tostring(CustomMovementModes.Climb), tostring(self.MantleParams.AnimMontage))

    local PrevType = self.ClimbType
    if self.bPlayMantleAnimation then
        self:StopMantleStartAnim()
        self.bPlayMantleAnimation = false
    end

    self.Overridden.ClimbStart(self, WallRunType, HitResult, Direction)
    if self.actor:IsPlayer() then
        local PlayerController = self.actor.PlayerState:GetPlayerController()
        if PlayerController then
            PlayerController:SendMessage("RegisterIMC", MANTLE_INPUT_TAG, {"Climb",}, {})
        else 
            G.log:error(self.__TAG__, "can not get PlayerController")
        end
    end

    local TargetRotation = self.actor:K2_GetActorRotation()
    local bBlockingHit, bInitialOverlap, Time, Distance, Location, ImpactPoint, Normal, ImpactNormal, PhysMat, HitActor, HitComponent, HitBoneName, BoneName, HitItem, ElementIndex, FaceIndex, TraceStart, TraceEnd = UE.UGameplayStatics.BreakHitResult(HitResult)
    local Rotation = UE.UKismetMathLibrary.Conv_VectorToRotator(-ImpactNormal)
    TargetRotation.Yaw = Rotation.Yaw

    self.SprintStartLockRollDuration = 0

    --Combine move is closed by default
    --self.actor.CharacterMovement:SetForceNoCombine(true)

    if WallRunType == UE.EHiWallRunType.Sprint then
        self.bSkipFirstCheck = true
        self.MaxClimbMovementSpeed = self.MaxSprintSpeed
        self.MantleData.State = Enum.EClimbState.SprintClimbLoop
    elseif WallRunType == UE.EHiWallRunType.Climb then
        self.MaxClimbMovementSpeed = self.MaxClimbSpeed
        self.MantleData.State = Enum.EClimbState.ClimbLoop
    end

    self.actor.CharacterStateManager.ClimbCamera = true
    self.actor.CharacterStateManager.Climb = true
    self.actor.AppearanceComponent:SetMovementState(UE.EHiMovementState.Custom)
    self.actor.AppearanceComponent:SetMovementAction(UE.EHiMovementAction.HighMantle)

    if self.actor:IsClient() or self.actor:IsStandalone()then
        self:PlayClimbStartMontage(PrevType)
    end

    self.actor.InputVectorMode = UE.EHiInputVectorMode.WorldSpace

    self.actor.CharacterMovement.bServerAcceptClientAuthoritativePosition = true
    self.actor.CharacterMovement.Velocity = UE.FVector(0, 0, 0)
    self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Custom, CustomMovementModes.Climb) -- 这个一定要在最后
end

decorator.message_receiver()
function MantleComponent:OnBeginActionFail(Action, CostAction, Reason)
    if Action == check_table.Action_Climb then
        if self.actor:IsClient() then
            -- TODO hardcode notify here.
            utils.PrintString("耐力值不够", UE.FLinearColor(1, 0, 0, 1), 2)
        end
    end
end

function MantleComponent:OnServerClimbStartFail()
    self:Client_ClimbStartFailed()
end

function MantleComponent:ClimbStartFailed()
    self:OnClimbEnd(SprintClimbEndReason.Cancel)
end

function MantleComponent:PlayClimbStartMontage(PrevType)
    local Animation = self:GetWallRunStartAsset(PrevType)
    local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.actor.Mesh, self.SprintClimbStartAnimation, 1.0)
    local callback = function(name)
                        self.OnSprintClimbStartMontageEnd(self, name)
                    end
    local BlendOutCallback = function(name)
                        self.OnSprintClimbStartMontageBlendOut(self, name)
                    end
    PlayMontageCallbackProxy.OnInterrupted:Add(self.actor, callback)
    PlayMontageCallbackProxy.OnCompleted:Add(self.actor, callback)
    PlayMontageCallbackProxy.OnBlendOut:Add(self.actor, BlendOutCallback)

    self.ClimbStartAnimation = Animation

    --self.MantleData.State = Enum.EClimbState.SprintClimbStart
end

function MantleComponent:OnSprintClimbStartMontageBlendOut()
    self.ClimbStartAnimation = nil
    G.log:debug("devin", "MantleComponent:OnSprintClimbStartMontageBlendOut %s", tostring(self.actor:IsServer()))
    -- self.MantleData.State = Enum.EClimbState.SprintClimbLoop
end

function MantleComponent:OnSprintClimbStartMontageEnd(name)
    self.ClimbStartAnimation = nil
    G.log:debug("devin", "MantleComponent:OnSprintClimbStartMontageEnd %s", tostring(self.actor:IsServer()))
end

function MantleComponent:PlayClimbStopMontage()

    local ActorLocation = self.actor:K2_GetActorLocation()

    local ActorRotation = self.actor:K2_GetActorRotation()
    local ForwardVector = ActorRotation:GetForwardVector()

    local StartPos = ActorLocation - ForwardVector * self.SprintClimbEndCheckOffset
    local EndPos = StartPos - UE.FVector(0, 0, self.SprintClimbEndCheckHeight)

    local CapsuleComponent = self.actor.CapsuleComponent
    local CapsuleRadius = CapsuleComponent:GetScaledCapsuleRadius()

    local HitResult = UE.FHitResult()
    local ignore = UE.TArray(UE.AActor)

    local bHit = UE.UKismetSystemLibrary.SphereTraceSingleByProfile(self.actor, StartPos, EndPos, CapsuleRadius, self.ClimbObjectDetectionProfile, false, ignore, UE.EDrawDebugTrace.None, HitResult, true)

    local Height = self.SprintClimbEndCheckHeight

    if bHit then
        local bBlockingHit, bInitialOverlap, Time, Distance, Location, ImpactPoint, Normal, ImpactNormal, PhysMat, HitActor, HitComponent, HitBoneName, BoneName, HitItem, ElementIndex, FaceIndex, TraceStart, TraceEnd = UE.UGameplayStatics.BreakHitResult(HitResult)
        if bInitialOverlap then
            Height = 0
        else
            Height = Distance + CapsuleRadius
        end
    end

    local Animation = self:GetWallRunEndAsset(Height)
    if Animation then
        local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.actor.Mesh, Animation, 1.0)
        local callback = function(name)
                            self.OnSprintClimbStopMontageEnd(self, name)
                        end
        PlayMontageCallbackProxy.OnInterrupted:Add(self.actor, callback)
        PlayMontageCallbackProxy.OnCompleted:Add(self.actor, callback)
    
        self.actor.CharacterStateManager.SprintClimbEnd = true

        return true
    end

    return false
end

function MantleComponent:OnSprintClimbStopMontageEnd(name)
    self.actor.CharacterStateManager.SprintClimbEnd = false
    self.ClimbType = UE.EHiClimbType.None
    self.actor.AppearanceComponent:SetMovementAction(UE.EHiMovementAction.None)
    if self.actor:IsOnFloor() then
        self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Walking)
    else
        self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Falling)
    end
    --G.log:error("devin", "MantleComponent:OnSprintClimbStartMontageEnd %s", tostring(self.actor:IsClient()))
end

-- decorator.message_receiver()
-- function MantleComponent:OnReceiveTick(DeltaSeconds)
--    G.log:error("devin", "MantleComponent:OnReceiveTick %s %s %s", tostring(self.actor:IsServer()), tostring(self.actor.CharacterMovement.CustomMovementMode), tostring(self.actor:K2_GetActorLocation()))
-- end

function MantleComponent:ClimbEnd(Reason)
    if not Reason or Reason == 0 then
        Reason = SprintClimbEndReason.Cancel
    end
    self:OnClimbEnd(Reason)
    if self.actor:IsClient() then
        self:Server_ClimbEnd(Reason)
    end
end

function MantleComponent:OnClimbEnd(Reason)

    if self.ClimbStartAnimation then
        self.actor:StopAnimMontage(self.ClimbStartAnimation)
        self.ClimbStartAnimation = nil
    end

    self.actor.InputVectorMode = UE.EHiInputVectorMode.CameraSpace
    self.actor.CharacterMovement.bServerAcceptClientAuthoritativePosition = false
    G.log:error("devin", "MantleComponent:SprintClimbEnd %s %s %s %s", tostring(self.ClimbType), tostring(self.actor:IsServer()), tostring(Reason), debug.traceback())

    local ActorRotation = self.actor:K2_GetActorRotation()

    local NewUpVector = UE.FVector(0, 0, 1)
    
    local CacheWallRunType = self.WallRunType

    local OriginalUpVector = ActorRotation:GetUpVector()
    local OriginalPos = self.actor:K2_GetActorLocation()

    local CapsuleComponent = self.actor.CapsuleComponent
    local CapsuleHalfHeightWithoutHemisphere = CapsuleComponent:GetScaledCapsuleHalfHeight_WithoutHemisphere()

    local RotateCenter = OriginalPos + OriginalUpVector * CapsuleHalfHeightWithoutHemisphere
    local NewLocation = RotateCenter - NewUpVector * CapsuleHalfHeightWithoutHemisphere

    local ForwardVector = ActorRotation:GetForwardVector()
    ForwardVector.Z = 0
    if UE.UKismetMathLibrary.Vector_IsNearlyZero(ForwardVector) then
        ForwardVector = UE.FVector(1, 0, 0)
    else
        ForwardVector:Normalize()
    end

    local TargetRotation = UE.UKismetMathLibrary.MakeRotFromZX(NewUpVector, ForwardVector)

    local HitResult = UE.FHitResult()
    local Success = self.actor.CharacterMovement:K2_MoveUpdatedComponent(NewLocation - OriginalPos, TargetRotation, HitResult, true)

    local bBlockingHit, bInitialOverlap, Time, Distance, Location, ImpactPoint, Normal, ImpactNormal, PhysMat, HitActor, HitComponent, HitBoneName, BoneName, HitItem, ElementIndex, FaceIndex, TraceStart, TraceEnd = UE.UGameplayStatics.BreakHitResult(HitResult)

    self.CachedForwardInputValue = nil
    self.CachedRightInputValue = nil
    -- G.log:error("devin", "MantleComponent:SprintClimbEnd %s %s %s %s", tostring(self.actor:IsServer()), tostring(self.actor:K2_GetActorLocation()), tostring(self.actor:K2_GetActorRotation()), tostring(bInitialOverlap))

    if not self.bDelayFinishClimbCamera then
        self.actor.CharacterStateManager.ClimbCamera = false
    end
    self.actor.CharacterStateManager.Climb = false

    --self.actor.CharacterMovement.Velocity = UE.FVector(0, 0, 0)
    --Combine move is closed by default
    --self.actor.CharacterMovement:SetForceNoCombine(false)

    self:SendMessage("EndState", check_table.State_Climb)
    self:SendMessage("OnClimbPause")

    G.log:info("santi", "MantleComponent:SprintClimbEnd ps: %s", self.actor.PlayerState)
    if self.actor.PlayerState then
        G.log:info("santi", "MantleComponent:SprintClimbEnd invoke end action")
        self.actor.PlayerState.AttributeComponent:TryEndAction(Enum.Enum_ActionType.Climb)
    end

    local bResetMovementAction = true

    if self.ClimbType ~= UE.EHiClimbType.Mantle  then
        if Reason == SprintClimbEndReason.Cancel or Reason == SprintClimbEndReason.Break then
            if self.actor:IsOnFloor() then
                self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Walking)
            else
                -- 技能或受击打断攀爬，不需要结束动作。
                if Reason ~= SprintClimbEndReason.Break then
                    bResetMovementAction = not self:PlayClimbStopMontage()
                end
            end
        end
    end

    if bResetMovementAction then
        -- 下落的时候不触发任何攀爬
        self.ClimbType = UE.EHiClimbType.None
        self.actor.AppearanceComponent:SetMovementAction(UE.EHiMovementAction.None)
        self.actor.CharacterMovement.Velocity = UE.FVector(0, 0, 0)
        self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Falling)
    else
        self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Flying)
    end
    self.Overridden.ClimbEnd(self, Reason)
    if self.actor:IsPlayer() then
        local PlayerController = self.actor.PlayerState:GetPlayerController()
        if PlayerController then
            PlayerController:SendMessage("UnregisterIMC", MANTLE_INPUT_TAG)
        end
    end

    self:OnMantleStateEnd()

    G.log:info("qwt", "MantleComponent:SprintClimbEnd Sprint: %s Input: %s Server: %s", tostring(CacheWallRunType == UE.EHiWallRunType.Sprint), tostring(math.abs(self.ForwardInputValue) < G.EPS and math.abs(self.RightInputValue) < G.EPS), tostring(self.actor:IsServer()))
    if (math.abs(self.ForwardInputValue) < G.EPS and math.abs(self.RightInputValue) < G.EPS) 
            and CacheWallRunType == UE.EHiWallRunType.Sprint 
            and self.actor:GetLocalRole() == UE.ENetRole.ROLE_AutonomousProxy then
        self.actor.AppearanceComponent:SprintAction(false)
    end
    -- G.log:error("devin", "MantleComponent:SprintClimbEnd %d %s", client, tostring(self.actor:K2_GetActorLocation()))

end

--decorator.require_check_action(check_table.Action_Move)
function MantleComponent:MoveForward(value)
    if self.CachedForwardInputValue == nil then
        self.CachedForwardInputValue = value
    end
    self.ForwardInputValue = value
end


--decorator.require_check_action(check_table.Action_Move)
function MantleComponent:MoveRight(value)
    if self.CachedRightInputValue == nil then
        self.CachedRightInputValue = value
    end
    self.RightInputValue = value
end

function MantleComponent:OnMontageEnded(Montage, bInterrupted)
    -- 墙上疾奔到顶触发翻越的下一tick取消输入会导致Dodge无法触发取消方向键进而取消冲刺，因此需要在翻越蒙太奇结束时进行额外判断
    self.Overridden.OnMontageEnded(self, Montage, bInterrupted)
    local DesiredGait = self.actor.AppearanceComponent:GetDesiredGait()
    if(self.actor:IsClient() and not self.actor.AppearanceComponent:HasMovementInput() and DesiredGait == UE.EHiGait.Sprinting ) then
        G.log:info("qwt", "MantleComponent::OnMontageEnded StopSprint")
        self.actor.AppearanceComponent:SprintAction(false)
    end
end

function MantleComponent:FlyOverStart(MantleAsset, MantleLedgeWS)
    self.Overridden.FlyOverStart(self, MantleAsset, MantleLedgeWS)

    self.bPlayMantleAnimation = true
    --self.actor:StopAnimMontage(self.SprintClimbAnimation)

    -- SetMovementMode需要在MantleStart之后，防止因播放动画逻辑导致MovementMode切换到未知状态
    self.PrevMovementMode = self.actor.CharacterMovement.MovementMode
    self.PrevCustomMovementMode = self.actor.CharacterMovement.CustomMovementMode
    self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Custom, CustomMovementModes.Mantle)

    if self.actor:IsClient() then
        self:Server_FlyOverStart(MantleAsset, MantleLedgeWS)
    end
end

function MantleComponent:FlyOverEnd()
    self.Overridden.FlyOverEnd(self, MantleAsset, MantleLedgeWS)

    if self.PrevMovementMode ~= nil and self.PrevCustomMovementMode ~= nil then
        -- G.log:error("qwt", "MantleComponent::FlyOverEnd %s %s", self.PrevMovementMode, self.PrevCustomMovementMode)
        self.actor.CharacterMovement:SetMovementMode(self.PrevMovementMode, self.PrevCustomMovementMode)
        self.PrevMovementMode = nil
        self.PrevCustomMovementMode = nil
    end
end

function MantleComponent:CanMantle()
    if self.actor.CharacterStateManager.SprintClimbEnd then
        return false
    end
    
    local StateController = self.actor:_GetComponent("StateController", false)
    
    if StateController then
        return StateController:CheckAction(check_table.Action_Mantle)
    end

    return true
end

decorator.require_check_action(check_table.Action_Mantle)
function MantleComponent:MantleStart(MantleAsset, MantleHeight, MantleLedgeWS, MantleType)
    G.log:debug("devin", "MantleComponent:MantleStart 111 %s %s %s", tostring(self.actor:IsServer()), tostring(self.ClimbType), tostring(CustomMovementModes.Mantle))

    if self.ClimbType == UE.EHiClimbType.WallRun then
        self.bDelayFinishClimbCamera = true
        self:OnClimbEnd(SprintClimbEndReason.MantleStart)
    else
        self.actor.CharacterStateManager.Mantle = true
    end

    self.bEnableBreakMantle = false
    self.Overridden.MantleStart(self, MantleAsset, MantleHeight, MantleLedgeWS, MantleType)

    if self.actor.AppearanceComponent:HasMovementInput() then
        local gait = self.actor.AppearanceComponent:GetDesiredGait()
        local sprint_speed = self.actor.CharacterMovement:GetGaitSpeedInSettings(UE.EHiGait.Sprinting)
        local speed = self.actor.CharacterMovement:GetGaitSpeedInSettings(gait)
        self.actor:SetAnimationVariable("MantleStartSpeedRate", speed / sprint_speed)
    end
    self.bPlayMantleAnimation = true
    --self.actor:StopAnimMontage(self.SprintClimbAnimation)

    -- SetMovementMode需要在MantleStart之后，防止因播放动画逻辑导致MovementMode切换到未知状态
    self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Custom, CustomMovementModes.Mantle)

    if self.actor:IsClient() then
        self:Server_MantleStart(MantleAsset, MantleHeight, MantleLedgeWS, MantleType)
    end
end

function MantleComponent:MantleEnd()
    G.log:debug("devin", "MantleComponent:MantleEnd")
    if self.bDelayFinishClimbCamera then
        self.actor.CharacterStateManager.ClimbCamera = false
    end
    self.bDelayFinishClimbCamera = false
    self.actor.CharacterStateManager.Mantle = false

    self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Walking)
    
    self.Overridden.MantleEnd(self)
    if self.bPlayMantleAnimation then
        self.actor:StopAnimMontage(self.MantleParams.AnimMontage)
        self.bPlayMantleAnimation = false
    end
    if self.actor.AppearanceComponent:HasMovementInput() then
        local gait = self.actor.AppearanceComponent:GetDesiredGait()
        local speed = self.actor.CharacterMovement:GetGaitSpeedInSettings(gait)
        local CurrentRotation = self.actor:K2_GetActorRotation()
        self.actor.CharacterMovement.Velocity = UE.UKismetMathLibrary.Conv_RotatorToVector(CurrentRotation) * speed
        --G.log:error("devin", "MantleComponent:MantleEnd %s %s %s", tostring(gait), tostring(speed), tostring(self.actor.CharacterMovement.Velocity))
    else
        self.actor.CharacterMovement.Velocity = UE.FVector(0, 0, 0)
    end

    self:SendMessage("EndState", check_table.State_Mantle)
    
    self:OnMantleStateEnd()
end

function MantleComponent:CanBreakMantle(HitResult)
    return self.bEnableBreakMantle
end

function MantleComponent:CanStartClimb(HitResult)
    -- if true then
    --     return true
    -- end

    if self.actor.CharacterStateManager.SprintClimbEnd then
        return false
    end

    if self.actor.AppearanceComponent:HasMovementInput() then
        local MovementInputVector = self.actor.AppearanceComponent:GetMovementInput()
        local bBlockingHit, bInitialOverlap, Time, Distance, Location, ImpactPoint, Normal, ImpactNormal, PhysMat, HitActor, HitComponent, HitBoneName, BoneName, HitItem, ElementIndex, FaceIndex, TraceStart, TraceEnd = UE.UGameplayStatics.BreakHitResult(HitResult)
        ImpactNormal.Z = 0
        MovementInputVector:Normalize()
        if ImpactNormal:Normalize() then
            if ImpactNormal:Dot(-MovementInputVector) < UE.UKismetMathLibrary.DegCos(self.MantleAngle) then
                return UE.EHiWallRunType.None
            end
        end
    
        local DesiredGait = self.actor.AppearanceComponent:GetDesiredGait()
        if self.bEnableClimb and DesiredGait ~= UE.EHiGait.Sprinting then
            return UE.EHiWallRunType.Climb
        else
            return UE.EHiWallRunType.Sprint
        end
    end

    return UE.EHiWallRunType.None
end

function MantleComponent:SprintAction(value)
    if not value then
        return
    end

    if self.bEnableClimb and self.WallRunType == UE.EHiWallRunType.Climb then
        self.MaxClimbMovementSpeed = self.MaxSprintSpeed
        self.MantleData.State = Enum.EClimbState.SprintClimbLoop
        self.WallRunType = UE.EHiWallRunType.Sprint
        self.actor.AppearanceComponent:SprintAction(true)
    end

    -- self.SprintKeyDown = value
    -- if value and self.ClimbType == UE.EHiClimbType.None then
    --     if self:MantleCheck(self.GroundedTraceSettings, UE.EDrawDebugTrace.ForDuration) then
    --         return true
    --     end
    -- end

    return false
end

function MantleComponent:StopClimbAction(value)
    if value then
        self:StopClimb()
    end
end

function MantleComponent:GetRoll()
    local Roll = 0

    if self.actor.AppearanceComponent:HasMovementInput() then
        local MovementInputVector = self.actor.AppearanceComponent:GetMovementInput()
        local control_rotation = self.actor:GetControlRotation()
        --local control_rotation = self.actor:K2_GetActorRotation()

        Roll = UE.UKismetMathLibrary.RadiansToDegrees(UE.UKismetMathLibrary.Vector_HeadingAngle(MovementInputVector)) - control_rotation.Yaw

        --G.log:error("devin", "MantleComponent:GetRoll %s %f %f", tostring(MovementInputVector), UE.UKismetMathLibrary.RadiansToDegrees(UE.UKismetMathLibrary.Vector_HeadingAngle(MovementInputVector)), control_rotation.Yaw)

        if Roll > 180 then
            Roll = Roll - 360
        end

        if Roll < -180 then
            Roll = Roll + 360
        end

        local MaxRoll = UE.UKismetMathLibrary.FClamp(self.MaxClimbRoll, -90.0, 90.0)
        local MinRoll = UE.UKismetMathLibrary.FClamp(-self.MaxClimbRoll, -90.0, 90.0)

        Roll = UE.UKismetMathLibrary.FClamp(Roll, MinRoll, MaxRoll)
    end

    return -Roll
end

function MantleComponent:ClimbUpdate(DeltaTime)
    local Roll = 0
    self.SprintStartLockRollDuration = self.SprintStartLockRollDuration + DeltaTime
    if self.actor:GetLocalRole() == UE.ENetRole.ROLE_AutonomousProxy then
        local ForwardInputValue = self.ForwardInputValue
        local RightInputValue = self.RightInputValue

        local CameraManager = UE.UGameplayStatics.GetPlayerCameraManager(self:GetWorld(), 0)

        if self.WallRunType == UE.EHiWallRunType.Sprint then
            if self.SprintStartLockRollDuration <= self.SprintStartLockRollTime then
                ForwardInputValue = self.CachedForwardInputValue or 0
                RightInputValue = self.CachedRightInputValue or 0
            end

            -- 变成攀爬
            if not self.bSkipFirstCheck and (ForwardInputValue < 0 or (math.abs(ForwardInputValue) < G.EPS and math.abs(RightInputValue) < G.EPS)) then
                if self.bEnableClimb then
                    self.MaxClimbMovementSpeed = self.MaxClimbSpeed
                    self.MantleData.State = Enum.EClimbState.ClimbLoop
                    self.WallRunType = UE.EHiWallRunType.Climb
                    self.actor.AppearanceComponent:SprintAction(false)
                else
                    self:StopClimb()
                    return
                end
            end

            self.bSkipFirstCheck = false
        end

        --G.log:error("devin", "MantleComponent:ClimbUpdate %f %f %f", DeltaTime, ForwardInputValue, RightInputValue)

        self:SendMessage("OnClimbMove", RightInputValue * self.CameraYawOffset, ForwardInputValue * self.CameraPitchOffset)

        local UpVector = self.actor:K2_GetActorRotation():GetUpVector()
        local RightVector = self.actor:K2_GetActorRotation():GetRightVector()

        self.actor:AddMovementInput(UpVector * ForwardInputValue, 1.0)
        self.actor:AddMovementInput(RightVector * RightInputValue, 1.0)

        self.ForwardInputValue = 0
        self.RightInputValue = 0
    end
end

function MantleComponent:StopClimb(Reason)
    self:ClimbEnd()
    self.ForwardInputValue = 0
    self.RightInputValue = 0
end

decorator.message_receiver()
function MantleComponent:OnStaminaChanged(NewValue, OldValue)
    if NewValue <= 0 then
        if self.ClimbType == UE.EHiClimbType.WallRun and self.actor:IsPlayer() then
            G.log:debug("santi", "Stamina not enough, stop sprint climb")
            self:StopClimb()
        end
    end
end

decorator.message_receiver()
function MantleComponent:OnLand()
    G.log:debug("qwt", "MantleComponent:OnLand, IsServer: %s INput:%s", self.actor:IsServer(), tostring(self.actor.AppearanceComponent:HasMovementInput()))
    if self.actor:IsClient() and not self.actor.AppearanceComponent:HasMovementInput() then
        self.actor.AppearanceComponent:SprintAction(false)
    end
end

decorator.message_receiver()
function MantleComponent:UpdateCustomMovement(DeltaSeconds)
    local CustomMode = self.actor.CharacterMovement.CustomMovementMode
    if CustomMode == CustomMovementModes.Climb then
        self:PhysClimb(DeltaSeconds)
    elseif CustomMode == CustomMovementModes.Mantle then
        self:PhysMantle(DeltaSeconds)
    end
end

decorator.message_receiver()
function MantleComponent:BreakStateClimb(reason)
    G.log:debug("devin", "MantleComponent:BreakStateClimb %s", tostring(reason))
    if self.ClimbType == UE.EHiClimbType.WallRun then
        self:ClimbEnd(SprintClimbEndReason.Break)
    end
    -- if self.ClimbType == UE.EHiClimbType.Mantle then
    --     self:MantleEnd()
    -- elseif self.ClimbType == UE.EHiClimbType.Sprint then
    --     self:SprintClimbEnd()
    -- end
end

decorator.message_receiver()
function MantleComponent:BreakMantle(reason)
    if self.ClimbType == UE.EHiClimbType.Mantle then
        self:MantleEnd()
    end
end

function MantleComponent:OnMantleStateEnd()
    self.MantleData.State = Enum.EClimbState.None
end

decorator.message_receiver()
function MantleComponent:PlayerBeforeSwitchOut()
    if self.ClimbType == UE.EHiClimbType.WallRun then
        self:ClimbEnd()
    end
    if self.ClimbType == UE.EHiClimbType.Mantle then
        self:MantleEnd()
    end
end

-- decorator.message_receiver()
-- function MantleComponent:OnReceiveTick(DeltaSeconds)
--     G.log:error("devin", "MantleComponent:OnReceiveTick %s %s", tostring(self.actor:IsServer()), tostring(self.actor:K2_GetActorLocation()))
-- end


return MantleComponent
