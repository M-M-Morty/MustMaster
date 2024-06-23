local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local state_conflict = require("common.data.state_conflict_data")

local RushComponent = Component(ComponentBase)
local decorator = RushComponent.decorator

local MinRushDeltaZ = 10
local GroundRushZ = 30

function RushComponent:Initialize(...)
    Super(RushComponent).Initialize(self, ...)
end

function RushComponent:Start()
    Super(RushComponent).Start(self)

    self.ASC = G.GetHiAbilitySystemComponent(self.actor)
end

function RushComponent:ReceiveBeginPlay()
    Super(RushComponent).ReceiveBeginPlay(self)

    self.__TAG__ = string.format("RushComponent(actor: %s, server: %s)", G.GetObjectName(self.actor), self.actor:IsServer())
end

--- Rush use in skill preprocess. This will check skill cd.
--- Return bEnabled
function RushComponent:BeginRushInPreSkill(SkillID, TargetActor, TargetComp, CallbackOwner, CallbackFunc)
    local GASpec = self:FindAbilitySpecFromSkillID(SkillID)
    local AbilityCDO = GASpec.Ability
    if not AbilityCDO.RushInfo or not AbilityCDO.RushInfo.RushEnabled then
        return false
    end

    self.RushCallbackOwner = CallbackOwner
    self.RushCallbackFunc = CallbackFunc

    return self:BeginRush(SkillID, TargetActor, TargetComp, true)
end

function RushComponent:FindAbilitySpecFromSkillID(SkillID)
    return SkillUtils.FindAbilitySpecFromSkillID(self.ASC, SkillID)
end

function RushComponent:FindAbilityFromSkillID(SkillID)
    local Spec = self:FindAbilitySpecFromSkillID(SkillID)
    if Spec then
        return Spec.Ability
    end
    return nil
end

decorator.message_receiver()
function RushComponent:EndRushInPreSkill(SkillID)
    if self.RushSkillID ~= SkillID then
        return
    end

    self:EndRush()
end

decorator.message_receiver()
function RushComponent:BeginRush(SkillID, TargetActor, TargetComp, bPreSkill)
    G.log:debug(self.__TAG__, "RushComponent:BeginRush TargetActor %s TargetComp %s", UE.UKismetSystemLibrary.GetObjectName(TargetActor), UE.UKismetSystemLibrary.GetObjectName(TargetComp))
    local AbilityCDO = self:FindAbilityFromSkillID(SkillID)
    local SkillType = AbilityCDO.SkillType
    local RushInfo = AbilityCDO.RushInfo

    if not RushInfo then
        return false
    end

    if (not TargetActor) and (not TargetComp) and (not RushInfo.RushCanEnableWithoutTarget) then
        G.log:debug(self.__TAG__, "Cancel rush as RushCanEnableWithoutTarget not enabled and no target.")
        return false
    end

    local SelfLocation = self.actor:K2_GetActorLocation()
    local TargetDis, TargetLocation, OutComp = utils.GetTargetNearestDistance(SelfLocation, TargetActor, TargetComp)

    -- target location is nil
    --UE.UKismetSystemLibrary.DrawDebugPoint(self.actor, TargetLocation, 20, UE.FLinearColor(1, 0, 0), 15)
    if not TargetLocation and not AbilityCDO.RushInfo.bFallAttack then
        local Forward = self.actor:GetActorForwardVector()
        TargetLocation = self.actor:K2_GetActorLocation() + Forward * AbilityCDO.RushInfo.RushMaxDis
    end

    -- Add rush target location offset.
    -- RushTargetOffset改成相对于目标和施法者构成的坐标系下的相对位移
    if TargetLocation and RushInfo.RushTargetOffset:Size() > 0 then
        local Dir = self.actor:K2_GetActorLocation() - TargetLocation
        Dir.Z = 0
        local LocalTransform = UE.UKismetMathLibrary.MakeTransform(TargetLocation, UE.UKismetMathLibrary.Conv_VectorToRotator(Dir), UE.FVector(1, 1, 1))
        local Loc = UE.UKismetMathLibrary.TransformLocation(LocalTransform, RushInfo.RushTargetOffset)
        --UE.UKismetSystemLibrary.DrawDebugPoint(self.actor, Loc, 20, UE.FLinearColor(0, 1, 0), 15)
        TargetLocation = UE.UKismetMathLibrary.TransformLocation(LocalTransform, RushInfo.RushTargetOffset)
    end

    -- Check whether target already in rush dis, no need rush.
    if bPreSkill then
        if RushInfo.RushEndToTarget and TargetDis <= RushInfo.RushDisToTarget then
            return false
        end
    end

    self.bRushStarter = true
    self.RushSkillID = SkillID

    if self.actor:IsPlayer() then
        self:SendMessage("EnterState", state_conflict.State_Rush)
    end

    if self.actor:IsServer() then
        -- 服务器发起的，通知所有客户端
        self:Server_OnBeginRush(SkillID, RushInfo, TargetActor, TargetComp, TargetLocation, bPreSkill)
    else
        -- 客户端发起的，先客户端先行，再通过服务器通知其他客户端
        -- Invoke OnBeginRush local on owning player, to avoid net latency.
        self:OnBeginRushLocal(SkillID, RushInfo, TargetActor, TargetComp, TargetLocation, bPreSkill)

        -- Notify server and other client OnBeginRush.
        if not self.actor:IsStandalone() then
            self:Server_OtherOnBeginRush(SkillID, RushInfo, TargetActor, TargetComp, TargetLocation, bPreSkill)
        end
    end

    local PlayerCameraManager = UE.UGameplayStatics.GetPlayerCameraManager(self:GetWorld(), 0)
    PlayerCameraManager:PlayAnimation_Delay()
    return true
end

function RushComponent:Server_OtherOnBeginRush_RPC(SkillID, RushInfo, TargetActor, TargetComp, TargetLocation, bPreSkill)
    self:MulticastOther_OnBeginRush(SkillID, RushInfo, TargetActor, TargetComp, TargetLocation, bPreSkill)
end

function RushComponent:Server_OnBeginRush_RPC(SkillID, RushInfo, TargetActor, TargetComp, TargetLocation, bPreSkill)
    self:Multicast_OnBeginRush(SkillID, RushInfo, TargetActor, TargetComp, TargetLocation, bPreSkill)
end

function RushComponent:MulticastOther_OnBeginRush_RPC(SkillID, RushInfo, TargetActor, TargetComp, TargetLocation, bPreSkill)
    self:OnBeginRushLocal(SkillID, RushInfo, TargetActor, TargetComp, TargetLocation, bPreSkill)
end

function RushComponent:Multicast_OnBeginRush_RPC(SkillID, RushInfo, TargetActor, TargetComp, TargetLocation, bPreSkill)
    self:OnBeginRushLocal(SkillID, RushInfo, TargetActor, TargetComp, TargetLocation, bPreSkill)
end

function RushComponent:OnBeginRushLocal(SkillID, RushInfo, TargetActor, TargetComp, TargetLocation, bPreSkill)
    if not bPreSkill then
        self.RushCallbackOwner = nil
        self.RushCallbackFunc = nil
    end

    -- TODO Must add reference in blueprint, otherwise data goes wrong !
    self.RushInfo = RushInfo
    self.RushSkillID = SkillID
    self.TargetActor = TargetActor
    self.TargetComp = TargetComp
    self.TargetLocation = TargetLocation
    self.bPreSkill = bPreSkill

    -- 使用辅助冲刺，播放辅助冲刺动画
    if self.RushInfo.RushEnabled and self.RushInfo.RushAnimMontage then
        self.actor:PlayAnimMontage(self.RushInfo.RushAnimMontage, 1.0)
    end

    if self.actor:IsSimulated() then
        return
    end

    -- Set MovementAction to custom to avoid rotation update by ALS UpdateCharacterRotation.
    -- 不能关同步，会导致end动作被拉
    --self.actor:SetReplicateMovement(false)
    self.actor.AppearanceComponent:SetMovementAction(UE.EHiMovementAction.Custom)
    self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_None)

    if self.actor:HasCalcAuthority() then
        self.ZGHandle = self.actor.ZeroGravityComponent:EnterZeroGravity(-1, false)
    end

    G.log:debug(self.__TAG__, "OnBeginRushLocal, SkillID: %d, IsSever: %s", SkillID, self.actor:IsServer())
    self.bRush = true
    self.RushTime = 0
    self.RushCurDis = 0
    self.LastUpdateLocation = nil
    self.RushCurSpeed = RushInfo.RushSpeed

    -- If enable rush through, not dynamic change rush forward vector.
    if self.TargetLocation then
        self.LastForwardVector = self.TargetLocation - self.actor:K2_GetActorLocation()
        if self.actor:IsOnFloor() and self.LastForwardVector.Z < 0 then
            self.LastForwardVector.Z = 0
        end
        UE.UKismetMathLibrary.Vector_Normalize(self.LastForwardVector)
    end
end

decorator.message_receiver()
function RushComponent:OnReceiveTick(DeltaSeconds)
    if self.bRush then
        self:RushTick(DeltaSeconds)
    end
end

-- Only call on rush instigator.
function RushComponent:RushTick(DeltaSeconds)
    -- Rush exceed max distance.
    if self.RushCurDis >= self.RushInfo.RushMaxDis then
        self:EndRush()
        return
    end

    local SelfLocation = self.actor:K2_GetActorLocation()
    local CurTargetLocation = self.TargetLocation
    if self.RushInfo.RushFollowTarget then
        _, CurTargetLocation = utils.GetTargetNearestDistance(SelfLocation, self.TargetActor, self.TargetComp)
    end

    -- Check rush end
    local DisToTarget
    local NextMaxRushDis
    local EPS = 2.0
    if CurTargetLocation and self.RushInfo.RushEndToTarget and not self.RushInfo.bFallAttack then
        -- Rush to target and stop
        DisToTarget = utils.GetDis(SelfLocation, CurTargetLocation)
        if DisToTarget <= self.RushInfo.RushDisToTarget or DisToTarget - self.RushInfo.RushDisToTarget < EPS then
            self:EndRush()
            return
        end

        NextMaxRushDis = DisToTarget - self.RushInfo.RushDisToTarget
    end


    if self.RushInfo.bFallAttack then
        self.LastForwardVector = UE.FVector(0, 0, -1.0)
        -- fall attack support fall around target
        if self.RushInfo.bFallToTarget  and  (self.TargetActor or self.TargetComp) and CurTargetLocation then
            --CurTargetLocation may be not on ground，fall attack must end on ground
            if CurTargetLocation.Z <= SelfLocation.Z then
                self.LastForwardVector = CurTargetLocation - SelfLocation
            else 
                self.LastForwardVector = SelfLocation - CurTargetLocation
            end 
        end
    elseif not self.RushInfo.RushThroughEnabled then
        local ForwardVector = self.actor:GetActorForwardVector()

        -- Forward to target if has.
        if CurTargetLocation then
            ForwardVector = CurTargetLocation - SelfLocation
        end

        -- Avoid OnGround rush into air.
        if self.actor:IsOnFloor() and ForwardVector.Z < 0 then
            ForwardVector.Z = 0
        end
        UE.UKismetMathLibrary.Vector_Normalize(ForwardVector)

        -- Control follow rotate speed.
        if self.LastForwardVector and self.RushInfo.RushRotateSpeed > 0 then
            local MaxAngle = self.RushInfo.RushRotateSpeed * DeltaSeconds
            local MaxRadians = UE.UKismetMathLibrary.DegreesToRadians(MaxAngle)
            local CosDelta = UE.UKismetMathLibrary.Dot_VectorVector(self.LastForwardVector, ForwardVector)
            if CosDelta < UE.UKismetMathLibrary.Cos(MaxRadians) then
                local UpVector = UE.UKismetMathLibrary.Cross_VectorVector(self.LastForwardVector, ForwardVector)
                ForwardVector = UE.UKismetMathLibrary.RotateAngleAxis(self.LastForwardVector, MaxAngle, UpVector)
                UE.UKismetMathLibrary.Vector_Normalize(ForwardVector)
            end
        end

        self.LastForwardVector = ForwardVector
    end

    local CharacterMovement = self.actor.CharacterMovement
    -- TODO place here to handle actors create during rush, may cause performance problem.
    local IgnoreActors = UE.TArray(UE.AActor)
    UE.UGameplayStatics.GetAllActorsOfClass(self.actor, UE.APawn, IgnoreActors)
    for Ind = 1, IgnoreActors:Length() do
        local CurActor = IgnoreActors:Get(Ind)
        -- Ignore all actor except target actor if has.
        if CurActor ~= self.TargetActor then
            CharacterMovement.UpdatedComponent:IgnoreActorWhenMoving(CurActor, true)
            if CurActor.CharacterMovement then
                CurActor.CharacterMovement.UpdatedComponent:IgnoreActorWhenMoving(self.actor, true)
            end
        end
    end

    local NewRotation = self.actor:K2_GetActorRotation()
    if self.RushInfo.bRotateToVelocity then
        NewRotation = UE.UKismetMathLibrary.Conv_VectorToRotator(self.LastForwardVector)
        --角色旋转主要是YAW，其它两个轴向不做旋转
        NewRotation.Roll = 0
        NewRotation.Pitch = 0
        CharacterMovement.UpdatedComponent:K2_SetWorldRotation(NewRotation, true, UE.FHitResult(), false)
    end

    -- Ensure not rush over target.
    local Delta = self.LastForwardVector * self.RushCurSpeed * DeltaSeconds
    if NextMaxRushDis then
        Delta = UE.UKismetMathLibrary.Vector_ClampSizeMax(Delta, NextMaxRushDis)
    end

    -- Movement logic.
    local bMoved, bStepUp
    local Hit = UE.FHitResult()
    local OldFloor = CharacterMovement.CurrentFloor
    local CurLocation = self.actor:K2_GetActorLocation()
    local BeforeLoc = UE.FVector(CurLocation.X, CurLocation.Y, CurLocation.Z)
    local RampVector = CharacterMovement:BP_ComputeGroundMovementDelta(Delta, OldFloor.HitResult, OldFloor.bLineTrace)
    bMoved = CharacterMovement:K2_MoveUpdatedComponent(RampVector, NewRotation, Hit, true, false)

    if not bMoved and Hit.bBlockingHit and not Hit.bStartPenetrating then
        local PercentTimeApplied = Hit.Time
        local LastMoveTimeSlice = DeltaSeconds
        if Hit.Time > 1e-4 and Hit.Normal.Z > 0 and CharacterMovement:IsWalkable(Hit) then
            local InitialPercentRemaining = 1 - PercentTimeApplied
            RampVector = CharacterMovement:BP_ComputeGroundMovementDelta(Delta * InitialPercentRemaining, Hit, false)
            LastMoveTimeSlice = InitialPercentRemaining * DeltaSeconds
            bMoved = CharacterMovement:K2_MoveUpdatedComponent(RampVector, NewRotation, Hit, true)
            local SecondHitPercent = Hit.Time * InitialPercentRemaining;
            PercentTimeApplied = UE.UKismetMathLibrary.FClamp(PercentTimeApplied + SecondHitPercent, 0, 1)
        end

        if Hit.bBlockingHit and not Hit.bStartPenetrating and not self.RushInfo.bFallAttack then
            if CharacterMovement:BP_CanStepUp(Hit) then
                local bComputedFloor
                local FloorResult = UE.FFindFloorResult()
                bStepUp = CharacterMovement:BP_StepUp(UE.FVector(0, 0, -1.0), Delta, Hit, bComputedFloor, FloorResult)
                if not bStepUp then
                    CharacterMovement:BP_HandleImpact(Hit, LastMoveTimeSlice, RampVector)
                    CharacterMovement:BP_SlideAlongSurface(Delta, 1 - PercentTimeApplied, Hit.Normal, Hit, true)
                end
            end
        end

        if not bMoved and not bStepUp then
            G.log:debug(self.__TAG__, "Rush block by object: %s(%s) end rush.", G.GetObjectName(Hit.HitObjectHandle.Actor), G.GetObjectName(Hit.Component))
            self:EndRush()
            return
        end
    end

    -- 冲刺最小移动距离必须和冲刺速度成正比，否则表示冲刺被卡主，FrameRateFactor 主要考虑低帧率的情况.
    local AfterLoc = self.actor:K2_GetActorLocation()
    local FrameRateFactor = 0.5
    local MinMoveDelta = self.RushCurSpeed * DeltaSeconds * FrameRateFactor
    if UE.UKismetMathLibrary.Vector_Distance(BeforeLoc, AfterLoc) < MinMoveDelta then
        G.log:debug(self.__TAG__, "Tiny move happened, end rush.")
        self:EndRush()
        return
    end

    -- Calculate rush dis.
    if not self.LastUpdateLocation then
        self.LastUpdateLocation = self.actor.CharacterMovement:GetLastUpdateLocation()
    else
        local NewLocation = self.actor.CharacterMovement:GetLastUpdateLocation()
        self.RushCurDis = self.RushCurDis + utils.GetDis(NewLocation, self.LastUpdateLocation)
        self.LastUpdateLocation = NewLocation
    end

    -- Update rush speed.
    if self.RushInfo.RushSpeedCurve then
        self.RushCurSpeed = self.RushInfo.RushSpeedCurve:GetFloatValue(self.RushTime) * 10000
        self.RushTime = self.RushTime + DeltaSeconds
    elseif self.RushInfo.RushSpeedAcc then
        -- Update speed with acceleration.
        local OldRushSpeed = self.RushCurSpeed
        self.RushCurSpeed = self.RushCurSpeed + DeltaSeconds * self.RushInfo.RushSpeedAcc

        if OldRushSpeed * self.RushCurSpeed < 0 then
            self.RushCurSpeed = 0
            self:EndRush()
            return
        end
    end
end

-- Call on instigator.
decorator.message_receiver()
function RushComponent:EndRush(bCanceled)
    --if not self.bRushStarter then
    --    return
    --end
    --self.bRushStarter = false

    -- 先通知其他段 end 消息，再调用本地的 end 逻辑，end 逻辑中包括一些 rpc 调用（比如 SetMovementMode 等)，防止 rpc 时序错乱。
    self:Server_OnEndRush(bCanceled)
    self:DoEndRush(bCanceled)
end

function RushComponent:Server_OnEndRush_RPC(bCanceled)
    self:MulticastOther_OnEndRush(bCanceled)
end

decorator.message_receiver()
function RushComponent:OnLand()
    self:EndRush()
end

function RushComponent:MulticastOther_OnEndRush_RPC(bCanceled)
    self:DoEndRush(bCanceled)
end

function RushComponent:DoEndRush(bCanceled)
    if not self.bRush then
        return
    end

    self.actor.CharacterStateManager.Rush = false
    self.bRushStarter = false
    self.bRush = false

    local PlayerCameraManager = UE.UGameplayStatics.GetPlayerCameraManager(self:GetWorld(), 0)
    PlayerCameraManager:StopAnimation_Delay()

    -- Stop rush anim.
    if self.RushInfo.RushAnimMontage then
        self.actor:StopAnimMontage(self.RushInfo.RushAnimMontage)
    end

    if self.actor:IsSimulated() then
        return
    end

    local RushAbilityCDO = self:FindAbilityFromSkillID(self.RushSkillID)
    if RushAbilityCDO.StartMontage then
        self.actor:StopAnimMontage(RushAbilityCDO.StartMontage)
    end

    if RushAbilityCDO.LoopMontage then
        self.actor:StopAnimMontage(RushAbilityCDO.LoopMontage)
    end

    self.actor.AppearanceComponent:SetMovementAction(UE.EHiMovementAction.None)
    --self.actor:SetReplicateMovement(true)

    G.log:debug(self.__TAG__, "OnEndRush Skill: %s, bCanceled: %s", G.GetObjectName(RushAbilityCDO), bCanceled)
    self.actor.CharacterMovement.UpdatedComponent:ClearMoveIgnoreActors()
    self.actor:ClearVelocityAndAcceleration()

    -- After rush rotate forward to target if in air.
    if not self.RushInfo.bFallAttack and (not self.RushInfo.RushThroughEnabled) and RushAbilityCDO.OwnerZeroGravityEnabled
            and RushAbilityCDO.OwnerZeroGravityTime > 0
            and (not self.actor:IsOnFloor()) then
        local RightVector = self.actor:GetActorRightVector()
        local ForwardVector = self.actor:GetActorForwardVector()
        if self.LastForwardVector then
            ForwardVector = self.LastForwardVector
        end
        local NewRotation = UE.UKismetMathLibrary.MakeRotFromXY(ForwardVector, RightVector)
        self.actor:K2_SetActorRotation(UE.FRotator(0, NewRotation.Yaw, 0), false)
    end

    -- TODO Fix rush anim cause owner on ground before rush, but not after.
    local _, FloorDist, _ = self.actor:IsOnFloor()
    if FloorDist < GroundRushZ and FloorDist > 0 then
        local SelfLocation = self.actor:K2_GetActorLocation()
        self.actor:K2_SetActorLocation(UE.FVector(SelfLocation.X, SelfLocation.Y, SelfLocation.Z - FloorDist), false, nil, true)
    end

    -- After rush reset movement mode.
    if (not self.bPreSkill) and RushAbilityCDO.OwnerZeroGravityEnabled
            and RushAbilityCDO.OwnerZeroGravityTime > 0
            and (not self.actor:IsOnFloor()) then
        -- If config zero gravity in skill and InAir.
        if self.actor:HasCalcAuthority() then
            self.actor.ZeroGravityComponent:EnterZeroGravity(RushAbilityCDO.OwnerZeroGravityTime, false)
        end
    else
        if self.actor:HasCalcAuthority() then
            self.actor.ZeroGravityComponent:EndZeroGravity(self.ZGHandle)
        end

        -- Ensure a OnLand callback after rush.
        self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Falling)
    end

    if self.actor:IsPlayerNotStandalone() then
        self:SendMessage("EndState", state_conflict.State_Rush)

        if self.RushCallbackOwner and self.RushCallbackFunc then
            self.RushCallbackFunc(self.RushCallbackOwner, bCanceled)
        else
            if self.bPreSkill then
                -- Handle strange things, make sure clear state, This should never happen.
                G.log:error(self.__TAG__, "Rush in pre skill process but no any callback.")
            end
        end
    end
end

decorator.message_receiver()
function RushComponent:BreakStateRush(reason)
    G.log:debug(self.__TAG__, "Break state rush: %s", utils.ActionToStr(reason))
    self:EndRush(true)
end

function RushComponent:Server_RequestDirectMove_RPC(MoveVelocity, bForceMaxSpeed)
    self.actor.CharacterMovement:RequestDirectMove(MoveVelocity, bForceMaxSpeed)
end

return RushComponent
