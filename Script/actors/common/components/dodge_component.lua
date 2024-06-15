local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local utils = require("common.utils")
local check_table = require("common.data.state_conflict_data")

local DodgeComponent = Component(ComponentBase)
local InputModes = require("common.event_const").InputModes
local decorator = DodgeComponent.decorator
local SkillUtils = require("common.skill_utils")
local CustomMovementModes = require("common.event_const").CustomMovementModes

local DODGE_GAMEPLAY_TAG_STR = "Ability.Skill.Dodge"

function DodgeComponent:Initialize(...)
    Super(DodgeComponent).Initialize(self, ...)
    self.InputDirection = UE.FVector2D()
    self.allow_warp_rotation = false
    self.last_rotation = UE.FQuat()
    self.dodge_time = 0
    self.bTriggerSprint = false
    -- Immunity will ignore some block dodge state.
    self.LastImmunityTriggerTime = UE.UKismetMathLibrary.Now()
end

function DodgeComponent:Start()
    Super(DodgeComponent).Start(self)

    self.CharacterMovement = self.actor.CharacterMovement
    self.prev_RequestedMoveUseAcceleration =
        self.CharacterMovement.bRequestedMoveUseAcceleration
    self.is_dodge = false
end

-- decorator.message_receiver()
-- function DodgeComponent:PostBeginPlay()
--     self:LearnDodge()
-- end

decorator.message_receiver()
function DodgeComponent:LearnAbility()
    self:_LearnAbility(self.GADodgeAirClass)
    self:_LearnAbility(self.GADodgeGroundClass)
end

function DodgeComponent:_LearnAbility(GAClass)
    local DodgeGameplayTag = UE.UHiGASLibrary.RequestGameplayTag(DODGE_GAMEPLAY_TAG_STR)
    local DodgeData = utils.MakeUserData()
    DodgeData.SkillTag = DodgeGameplayTag
    if GAClass then
        self.actor.SkillComponent:GiveAbility(GAClass, -1,
                                              DodgeData)
    end
end 

decorator.message_receiver()
function DodgeComponent:OnClientReady()
    if self.actor:IsClient() or self.actor:IsStandalone() then
        self:SendMessage("RegisterInputHandler", InputModes.Dodge, self)
    end
end

function DodgeComponent:Stop()
    Super(DodgeComponent).Stop(self)

    if self.is_dodge then self:EndDodge() end

    self.is_dodge = false

    if self.actor:IsClient() or self.actor:IsStandalone() then
        self:SendMessage("UnRegisterInputHandler", InputModes.Dodge)
    end
end
function DodgeComponent:CheckDodgeCostAndCD(Action)
    -- 检测 GA 能否释放
    local GAClass = self.actor:IsOnFloor() and self.GADodgeGroundClass or self.GADodgeAirClass
    if GAClass and not SkillUtils.CanActivateSkillOfClass(self.actor, GAClass) then
        return false
    end

    local StateController = self.actor:_GetComponent("StateController", false)
    if StateController and not StateController:ExecuteAction(check_table.Action_Dodge) then
        return false
    end

    local bImmunity = false
    if not self.LastImmunityTriggerTime or
        utils.GetSecondsUntilNow(self.LastImmunityTriggerTime) > self.ImmunityCD then
        bImmunity = true
        self.LastImmunityTriggerTime = UE.UKismetMathLibrary.Now()
    end

    if bImmunity then
        -- Dodge immunity will ignore some conflict states.
        return true, check_table.Action_Dodge_Immunity
    end

    return true
end


decorator.require_check_action(check_table.Action_Dodge, DodgeComponent.CheckDodgeCostAndCD)
function DodgeComponent:Dodge()
    -- self:PlayerBeginDodge()
    local ASC = self.actor.SkillComponent:GetHiAbilitySystemComponent()
    self.bGroundDodge = false
    if self.actor:IsOnFloor() then
        if self.GADodgeGroundClass then
            ASC:TryActivateAbilityByClass(self.GADodgeGroundClass, true)
            self.bGroundDodge = true
        end
    else 
        if self.GADodgeAirClass then
            ASC:TryActivateAbilityByClass(self.GADodgeAirClass, true)
        end
    end
end

---废弃
-- function DodgeComponent:GetImmunityDodgeCD()
--     return math.max(0, self.ImmunityCD -
--                         utils.GetSecondsUntilNow(self.LastImmunityTriggerTime))
-- end

function DodgeComponent:SprintAction(value)
    if value then
        self:Dodge()
    else
        --G.log:info("yb", "can sprint action (%s), delta_time(%s)", self:CanSprint(), UE.UGameplayStatics.GetTimeSeconds(self.actor:GetWorld()) - self.dodge_time)
        if self:CanSprint() and (self.InputDirection.X ~= 0 or self.InputDirection.Y ~= 0) then 
            self.bTriggerSprint = true
        end
        self.dodge_time = 0
    end
end

decorator.message_receiver()
-- decorator.require_check_action(check_table.Action_Move)
function DodgeComponent:MoveForward(value)
    self.InputDirection.X = value
    self:Server_SetInputDirection(self.InputDirection)
    self:UpdateDirection()
end

decorator.message_receiver()
function DodgeComponent:MoveForward_Released(value)
    self.InputDirection.X = 0
    self:Server_SetInputDirection(self.InputDirection)
    self:UpdateDirection()
end

decorator.message_receiver()
-- decorator.require_check_action(check_table.Action_Move)
function DodgeComponent:MoveRight(value)
    self.InputDirection.Y = value
    self:Server_SetInputDirection(self.InputDirection)
    self:UpdateDirection()
end
 
decorator.message_receiver()
function DodgeComponent:MoveRight_Released(value)
    self.InputDirection.Y = 0
    self:Server_SetInputDirection(self.InputDirection)
    self:UpdateDirection()
end

function DodgeComponent:Notify_DodgeAllowWarpRotationBegin()
    self.allow_warp_rotation = true
end

function DodgeComponent:Notify_DodgeAllowWarpRotationEnd()
    self.allow_warp_rotation = false
    self:ClearRotationTarget()
end

-- state break
decorator.message_receiver()
function DodgeComponent:BreakDodge(reason)
    if not self.is_dodge then return end
    self:PlayerEndDodge()
end

function DodgeComponent:PlayerBeginDodge(NeedInit, InitRotation)
    assert(self.actor:IsPlayer())
    local DirectionVector = self:GetDirectionVector()

    -- G.log:info("yb", "current direction %s %s", self.InputDirection.X, self.InputDirection.Y)
    -- G.log:info("yb", "dodge dirction Vector(%s %s %s)", DirectionVector.X, DirectionVector.Y,DirectionVector.Z)

    local NeedInit = false
    local InitRotation = UE.FQuat()
    if DirectionVector:SizeSquared() > 0.5 then
        NeedInit = true
        InitRotation = UE.UKismetMathLibrary.Conv_VectorToQuaternion(
                           DirectionVector)
    end

    -- RPC需要在客户端表现执行前执行，防止表现执行内部存在其它状态RPC，导致RPC乱序
    G.log:info("devin", "DodgeComponent:PlayerBeginDodge %s %s", NeedInit, InitRotation)

    self:Server_BeginDodge(NeedInit, InitRotation)
    self:BeginDodge(NeedInit, InitRotation)

    self.actor.CharacterStateManager.Dodge = true

    self.bTriggerSprint = false
    self.dodge_time = UE.UGameplayStatics.GetTimeSeconds(self.actor:GetWorld())
end

function DodgeComponent:PlayerEndDodge()
    assert(self.actor:IsPlayer())
    -- RPC需要在客户端表现执行前执行，防止表现执行内部存在其它状态RPC，导致RPC乱序
    -- self:Server_EndDodge()
    -- self:EndDodge()

    local ASC = G.GetHiAbilitySystemComponent(self.actor)
    local GAClass = self.bGroundDodge and self.GADodgeGroundClass or self.GADodgeAirClass
    local SpecHandle = ASC:FindAbilitySpecHandleFromClass(GAClass)
    if SpecHandle ~= -1 then
        ASC:BP_CancelAbilityHandle(SpecHandle)
    end
end

function DodgeComponent:PlayerEndDodgeCallback() self:PlayerEndDodge() end

function DodgeComponent:BeginDodge(NeedInit, InitRotation)
    self.is_dodge = true

    if NeedInit and InitRotation:SizeSquared() > G.EPS then
        self.actor.AppearanceComponent:SetCharacterRotation(
            InitRotation:ToRotator(), false)

        self:ClearRotationTarget()
    end

    if self.actor:HasCalcAuthority() and not self.actor:IsOnFloor() then
        if self.ZeroGravityTime > G.EPS then
            self.ZGHandle = self.actor.ZeroGravityComponent:EnterZeroGravity(
                                self.ZeroGravityTime, false, true)
        end
    end

    self.CharacterMovement.UpdatedComponent:SetCollisionResponseToChannel(
        UE.ECollisionChannel.ECC_Pawn, UE.ECollisionResponse.ECR_Ignore)
end

function DodgeComponent:OnExtremeDodge()
    G.log:debug("DodgeComponent", "OnExtremeDodge actor: %s IsServer: %s",
                G.GetObjectName(self.actor), self.actor:IsServer())
    local TimeDilationActor = HiBlueprintFunctionLibrary.GetTimeDilationActor(
                                  self.actor)
    local GameState = UE.UGameplayStatics.GetGameState(self.actor:GetWorld())
    if TimeDilationActor and GameState then
        TimeDilationActor:StartWitchTimeEx(GameState.WitchTimeTimeScale,
                                           GameState.WitchTimeDuration,
                                           self.actor)
    end

end

decorator.message_receiver()
function DodgeComponent:OnStaminaChanged(NewValue, OldValue)
    if self.actor:IsClient() and NewValue <= 0 then
        self.actor.AppearanceComponent:SprintAction(false)
    end
end

function DodgeComponent:EndDodge()
    G.log:info("yb", "end dodge",self.is_dodge)
    if not self.is_dodge then return end

    -- if self.actor.PlayerState then
    --     self.actor.PlayerState.AttributeComponent:TryEndAction(self.DodgeCostAction)
    -- end

    if self.actor:HasCalcAuthority() then
        self.actor.ZeroGravityComponent:EndZeroGravity(self.ZGHandle)
    end

    self.CharacterMovement.UpdatedComponent:SetCollisionResponseToChannel(
        UE.ECollisionChannel.ECC_Pawn, UE.ECollisionResponse.ECR_Block)

    self.is_dodge = false
    G.log:info("yb", "dodge sprint action %s %s %s %s", self.bTriggerSprint, self.dodge_time, self:CanSprint(), self.actor:IsServer())

    if self.bTriggerSprint or (self:CanSprint() and (self.InputDirection.X ~= 0 or self.InputDirection.Y ~= 0)) then
        --G.log:info("yb", "sprint action")
        self.actor.AppearanceComponent:SprintAction(true)
    end
    self.bTriggerSprint = false

    if self.actor:IsGrounded() then
        local gait = self.actor.AppearanceComponent:GetDesiredGait()
        local speed = self.CharacterMovement:GetGaitSpeedInSettings(gait)
        local CurrentRotation = self.actor:K2_GetActorRotation()
        self.CharacterMovement.Velocity =
            UE.UKismetMathLibrary.Conv_RotatorToVector(CurrentRotation) * speed
    else
        self.CharacterMovement.Velocity = UE.FVector(0, 0, 0)
    end
end

function DodgeComponent:ClearRotationTarget()
    local TargetRotation = self.actor:K2_GetActorRotation():ToQuat()
    self:WarpRotation(TargetRotation)

    if self.actor:IsPlayer() then self.last_rotation = TargetRotation end
end

function DodgeComponent:OnClearRotationTarget() self:ClearRotationTarget() end

function DodgeComponent:OnRep_RotationTarget()
    self:WarpRotation(self.RotationTarget)
end

function DodgeComponent:CanSprint()
    return self.dodge_time > 0 and
               UE.UGameplayStatics.GetTimeSeconds(self.actor:GetWorld()) -
               self.dodge_time > self.SprintTime
end

function DodgeComponent:OnBeginDodge(NeedInit, InitRotation)

    if self.actor:IsPlayer() then
        self.dodge_time = UE.UGameplayStatics.GetTimeSeconds(
                              self.actor:GetWorld())
    else
        -- G.log:info("devin", "OnBeginDodge")
        self:BeginDodge(NeedInit, InitRotation)
    end
end

function DodgeComponent:OnEndDodge()
    self:EndDodge()
end

function DodgeComponent:OnDodgeMontageEnd(name)
    self:ClearRotationTarget()
    self:EndDodge()
    G.log:info("yb", "end dodge! %s %s", self.actor:IsPlayer(), self.actor:IsServer())
    if self.actor:IsPlayer() then
        self.dodge_time = 0
        self.allow_warp_rotation = false
        self.actor.CharacterStateManager.Dodge = false
    end
end

function DodgeComponent:GetDirectionVector()
    local control_rotation = self.actor:GetControlRotation()
    local AimRotator = UE.FRotator(0, control_rotation.Yaw, 0)
    local DirectionVector = UE.FVector(0, 0, 0)

    local forward_value = self.InputDirection.X

    if forward_value ~= 0 then
        DirectionVector = DirectionVector + AimRotator:GetForwardVector() *
                              forward_value
    end

    local right_value = self.InputDirection.Y

    if right_value ~= 0 then
        DirectionVector = DirectionVector + AimRotator:GetRightVector() *
                              right_value
    end

    return DirectionVector
end

function DodgeComponent:UpdateDirection()
    if self.allow_warp_rotation then
        local DirectionVector = self:GetDirectionVector()

        if DirectionVector:SizeSquared() > 0.5 then
            local TargetRotation = UE.UKismetMathLibrary
                                       .Conv_VectorToQuaternion(DirectionVector)
            self:WarpRotation(TargetRotation)
            if not UE.UKismetMathLibrary.EqualEqual_QuatQuat(self.last_rotation,
                                                             TargetRotation,
                                                             0.001) then
                -- G.log:info("devin", "TargetRotation %f %f %f %f", TargetRotation.X, TargetRotation.Y, TargetRotation.Z, TargetRotation.W)
                self.last_rotation = TargetRotation
                self:Server_SetRotationTarget(TargetRotation)
            end
        else
            self:ClearRotationTarget()
            local TargetRotation = self.actor:K2_GetActorRotation():ToQuat()
            self:Server_SetRotationTarget(TargetRotation)
        end
    end

    if self.InputDirection.X == 0 and self.InputDirection.Y == 0 then
        self.bTriggerSprint = false
        self.actor.AppearanceComponent:SprintAction(false)
    end
end

decorator.message_receiver()
function DodgeComponent:ReceiveMoveBlockedBy(HitResult)
    if not self.is_dodge then return end

    if not self.actor:IsPlayer() then return end

    local bBlockingHit, bInitialOverlap, Time, Distance, Location, ImpactPoint,
          Normal, ImpactNormal, PhysMat, HitActor, HitComponent, HitBoneName,
          BoneName, HitItem, ElementIndex, FaceIndex, TraceStart, TraceEnd =
        UE.UGameplayStatics.BreakHitResult(HitResult)

    local DirectionVector = self:GetDirectionVector()

    G.log:debug("devin", "DodgeComponent:MoveBlockedBy %s %s %s %s %s",
                tostring(HitResult), tostring(bBlockingHit),
                tostring(bInitialOverlap), tostring(Time), tostring(Distance))
    if bBlockingHit and ImpactNormal:Dot(-DirectionVector) <
        math.cos(math.rad(self.SlideAngle)) then
        G.log:debug("devin", "DodgeComponent:MoveBlockedBy %s %s",
                    tostring(Normal), tostring(ImpactNormal))
        -- Trigger once after movement tick
        self.actor.CharacterMovement.OnMovementTickEndTrigger:Add(self, self.PlayerEndDodgeCallback)
    end
end

function DodgeComponent:WarpRotation(Rotation)
    self.actor.MotionWarping:AddOrUpdateWarpTargetFromTransform(
        "RotationTarget", UE.FTransform(Rotation))
end

return DodgeComponent
