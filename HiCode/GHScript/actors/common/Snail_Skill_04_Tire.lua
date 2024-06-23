
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')

---@type Snail_Skill_04_Tire_C
local Snail_Skill_04_Tire_C = Class()


function Snail_Skill_04_Tire_C:ReceiveBeginPlay()
    if self:HasAuthority() then
        self.AbilityAvatar = self:GetAbility():GetAvatarActorFromActorInfo()
        self.start_time = UE.UGameplayStatics.GetTimeSeconds(self)

        if self.PROJECTILE_OBJ_CLS then
            local TargetActorOwner = self:GetOwner()
            self.projectileObjectInst = self:GetWorld():SpawnActor(self.PROJECTILE_OBJ_CLS, TargetActorOwner:GetTransform(), UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, TargetActorOwner)
            self:K2_AttachToActor(self.projectileObjectInst, '', UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.KeepRelative)
            self.projectileObjectInst.TireObj = self
            self.projectileObjectInst:PostBeginPlay()
        end
    end

    self.Collision.OnComponentBeginOverlap:Add(self, self.OnComponentBeginOverlap)
end

function Snail_Skill_04_Tire_C:ReceiveTick(DeltaSeconds)
    self.Overridden.ReceiveTick(self, DeltaSeconds)

    if self:HasAuthority() and self.custom_moving then
        self:CustomMoveToIgnoreActors()
        self:CustomMoveToVelocity()
        self:CustomMoveToMove(DeltaSeconds)
    end

    if self:HasAuthority() and (not self.bombed) then
        local current = UE.UGameplayStatics.GetTimeSeconds(self)
        if current - self.start_time > self.TOTAL_LIFE_SECOND then
            self:InstantBomb()
        end
    end
end

function Snail_Skill_04_Tire_C:ReceiveEndPlay(EndPlayReason)
    self.Collision.OnComponentBeginOverlap:Remove(self, self.OnComponentBeginOverlap)
end

function Snail_Skill_04_Tire_C:OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if self:HasAuthority() then
        if FunctionUtil:IsPlayer(OtherActor) then
           self:InstantBomb()
        end
    end
end

function Snail_Skill_04_Tire_C:GetAbility()
    local owner = self:GetOwner()
    return owner and owner.OwningAbility
end

function Snail_Skill_04_Tire_C:InstantBomb()
    local owner = self:GetOwner()
    if owner then
        owner:ConfirmTargeting()
    end

    local bomb_inst = self:GetWorld():SpawnActor(self.NA_BOMB_CLASS, self:GetTransform(), UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, self:GetWorld())
    bomb_inst:SetLifeSpan(5)

    if self.AbilityAvatar then
        local Caster = self.AbilityAvatar
        local tag = UE.UHiGASLibrary.RequestGameplayTag("StateGH.AbilityIdentify.Snail.TireBomb")
        local bombPayload = UE.FGameplayEventData()
        bombPayload.EventTag = tag
        bombPayload.Instigator = Caster
        bombPayload.Target = self
        bombPayload.OptionalObject = FunctionUtil:MakeUDKnockInfo(Caster, self.UD_FKNOCK_INFO)
        UE.UAbilitySystemBlueprintLibrary.SendGameplayEventToActor(Caster, tag, bombPayload)
    end

    if self.custom_moving then
        self:CustomMoveToStop()
    end

    if self.projectileObjectInst then
        self.projectileObjectInst:K2_DestroyActor()
        self.projectileObjectInst = nil
    end

    self.bombed = true
    self:K2_DestroyActor()
end

function Snail_Skill_04_Tire_C:DropProjectileObj()
    self.projectileObjectInst.TireObj = nil
    self.projectileObjectInst = nil
end

function Snail_Skill_04_Tire_C:CustomMoveToStart()
    self.start_fire_time = UE.UGameplayStatics.GetTimeSeconds(self)
    self.moveTarget = self:GetAbility():GetSkillTarget()
    self.custom_moving = true
end
function Snail_Skill_04_Tire_C:CustomMoveToVelocity()
    local selfLocation = self:K2_GetActorLocation()
    local tarLocation = self.moveTarget:K2_GetActorLocation()
    local selfRotation = self:K2_GetActorRotation()
    local lookAt = UE.UKismetMathLibrary.FindLookAtRotation(selfLocation, tarLocation)
    local selfYaw = selfRotation.Yaw
    local tarYaw = lookAt.Yaw
    selfRotation.Yaw = UE.UKismetMathLibrary.ClampAngle(tarYaw, selfYaw - self.UPDATE_DELTA_MAX, selfYaw + self.UPDATE_DELTA_MAX)

    self:K2_SetActorRotation(selfRotation, true)
    self.custom_move_velocity = UE.UKismetMathLibrary.GetForwardVector(selfRotation) * 1000
end

function Snail_Skill_04_Tire_C:CustomMoveToMove(DeltaSeconds)
    local moveComp = self:GetMovementComponent()
    local updateComp = self:K2_GetRootComponent()
    local velocity = UE.FVector(self.custom_move_velocity.X, self.custom_move_velocity.Y, moveComp.Velocity.Z)
    local Delta = velocity * DeltaSeconds
    local LastMoveTimeSlice = DeltaSeconds
    local bMoved, bStepUp
    local Hit = UE.FHitResult()
    local CurrentFloor = moveComp.CurrentFloor
    local SelfLocation = updateComp:K2_GetComponentLocation()
    local BeforeLocation = UE.FVector(SelfLocation.X, SelfLocation.Y, SelfLocation.Z)
    local RampVector = moveComp:BP_ComputeGroundMovementDelta(Delta, CurrentFloor.HitResult, CurrentFloor.bLineTrace)
    local move_stop
    bMoved = moveComp:K2_MoveUpdatedComponent(RampVector, updateComp:K2_GetComponentRotation(), Hit, true, false)
    if Hit.bStartPenetrating then
        moveComp:BP_HandleImpact(Hit)
        moveComp:BP_SlideAlongSurface(Delta, 1.0, Hit.Normal, Hit, true)
        if Hit.bStartPenetrating then
            move_stop = true
        end
    elseif Hit.bBlockingHit then
        local PercentTimeApplied = Hit.Time
        if Hit.Time > 0 and Hit.Normal.Z > 0 and moveComp:IsWalkable(Hit) then
            local InitialPercentRemaining = 1 - PercentTimeApplied
            RampVector = moveComp:BP_ComputeGroundMovementDelta(Delta * InitialPercentRemaining, Hit, false)
            LastMoveTimeSlice = InitialPercentRemaining * DeltaSeconds
            bMoved = moveComp:K2_MoveUpdatedComponent(RampVector, updateComp:K2_GetComponentRotation(), Hit, true)
            local SecondHitPercent = Hit.Time * InitialPercentRemaining
            PercentTimeApplied = UE.UKismetMathLibrary.FClamp(PercentTimeApplied + SecondHitPercent, 0, 1)
        end
        if Hit.bBlockingHit then
            if moveComp:BP_CanStepUp(Hit) then
                local bComputedFloor
                local FloorResult = UE.FFindFloorResult()
				bStepUp = moveComp:BP_StepUp(UE.FVector(0, 0, -1.0), Delta * (1 - PercentTimeApplied), Hit, bComputedFloor, FloorResult)
                if not bStepUp then
                    moveComp:BP_HandleImpact(Hit, LastMoveTimeSlice, RampVector)
                    moveComp:BP_SlideAlongSurface(Delta, 1 - PercentTimeApplied, Hit.Normal, Hit, true)
                end
            elseif Hit.Component and (not moveComp:BP_CanStepUp(Hit)) then
                moveComp:BP_HandleImpact(Hit, LastMoveTimeSlice, RampVector)
                moveComp:BP_SlideAlongSurface(Delta, 1 - PercentTimeApplied, Hit.Normal, Hit, true)
            end
        end
    end

    if move_stop then
        self:InstantBomb()
    else
        local AfterLocation = updateComp:K2_GetComponentLocation()
        local moveDist = UE.UKismetMathLibrary.Vector_Distance(BeforeLocation, AfterLocation)
        if moveDist < self.STOP_DIST_FACTOR * Delta:Size() then
            self.detach_custom_move_stuck = (self.detach_custom_move_stuck or 0) + DeltaSeconds
            if self.detach_custom_move_stuck > self.STOP_TIME then
                self:InstantBomb()
            end
        else
            self.detach_custom_move_stuck = 0
        end
    end
end

function Snail_Skill_04_Tire_C:CustomMoveToStop()
    self:CustomMoveToIgnoreActorsReset()
    self.custom_moving = false
end

function Snail_Skill_04_Tire_C:CustomMoveToIgnoreActors()
    local IgnoreActors = UE.TArray(UE.AActor)
    UE.UGameplayStatics.GetAllActorsOfClass(self, UE.APawn, IgnoreActors)
    local length = IgnoreActors:Length()
    if length > 0 then
        local selfMoveComp = self:GetMovementComponent()
        for i = 1, length do
            local tarActor = IgnoreActors:Get(i)
            if tarActor ~= self then
                selfMoveComp.UpdatedComponent:IgnoreActorWhenMoving(tarActor, true)
                local tarMoveComp = tarActor:GetMovementComponent()
                if tarMoveComp and tarMoveComp.UpdatedComponent then
                    tarMoveComp.UpdatedComponent:IgnoreActorWhenMoving(self, true)
                end
            end
        end
    end
end
function Snail_Skill_04_Tire_C:CustomMoveToIgnoreActorsReset()
    local selfMoveComp = self:GetMovementComponent()
    local arys = selfMoveComp.UpdatedComponent.MoveIgnoreActors
    local length = arys:Length()
    if length > 0 then
        for i = 1, length do
            local tarActor = arys:Get(i)
            local tarMoveComp = tarActor.GetMovementComponent and tarActor:GetMovementComponent()
            if tarMoveComp and tarMoveComp.UpdatedComponent then
                tarMoveComp.UpdatedComponent:IgnoreActorWhenMoving(self, false)
            end
        end
        selfMoveComp.UpdatedComponent:ClearMoveIgnoreActors()
    end
end

return Snail_Skill_04_Tire_C
