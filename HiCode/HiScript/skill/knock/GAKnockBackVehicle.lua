local G = require("G")
local GAKnockBackBase = require("skill.knock.GAKnockBackBase")
local GAKnockBackVehicle = Class(GAKnockBackBase)

function GAKnockBackVehicle:OnKnockBack(KnockParams)
    G.log:debug(self.__TAG__, "OnKnockBack")
    self.InKnockHandle = self.OwnerActor.BuffComponent:AddInKnockHitBuff()
    self.OwnerActor.CharacterStateManager:SetHitState(true)

    local KnockInfo = KnockParams.KnockInfo

    local direction_vector = KnockParams.Causer:K2_GetActorLocation() - self.OwnerActor:K2_GetActorLocation()
    direction_vector.Z = 0

    -- Turn to hit causer.
    local direction_yaw = UE.UKismetMathLibrary.Conv_VectorToRotator(direction_vector).Yaw
    local ActorRotator = self.OwnerActor:K2_GetActorRotation()
    ActorRotator.Yaw = direction_yaw
    self.OwnerActor:K2_SetActorRotation(ActorRotator, false)

    direction_vector = self.OwnerActor:K2_GetActorLocation() - KnockParams.Causer:K2_GetActorLocation()
    local IsInAir = not self.OwnerActor:IsOnFloor()
    if not IsInAir then
        direction_vector.Z = 0
    end
    local forward_vector = self.OwnerActor:GetActorForwardVector()
    if direction_vector:Size2D() < G.EPS then
        direction_vector = -forward_vector
    end

    -- Hit back according instigator direction.
    if KnockInfo.bUseInstigatorDir and KnockParams.Instigator then
        direction_vector = UE.UKismetMathLibrary.RotateAngleAxis(KnockParams.Instigator:GetActorForwardVector(), KnockInfo.InstigatorAngleOffset, UE.FVector(0, 0, 1))
    end

    direction_vector:Normalize()

    -- Optimize same causer knock actor back, try to keep a straight line knock back.
    if self.LastHitDirection and self.LastHitCauser then
        if self.LastHitCauser == KnockParams.Causer and
                UE.UKismetMathLibrary.Dot_VectorVector(self.LastHitDirection, direction_vector) > UE.UKismetMathLibrary.Cos(UE.UKismetMathLibrary.DegreesToRadians(MinKnockDirChangeAngle)) then
            direction_vector = self.LastHitDirection
        end
    end
    self.LastHitDirection = direction_vector
    self.LastHitCauser = KnockParams.Causer

    self.OwnerActor.MotionWarping:AddOrUpdateWarpTargetFromTransform("HitTarget", UE.FTransform(UE.FRotator(0, 0, 0):ToQuat(), UE.FVector(0, 0, 0), KnockInfo.KnockDisScale))

    if self.SequenceToPlay then
        local Settings = UE.FMovieSceneSequencePlaybackSettings()
        local Bindings = self:InitBindings()
        local PlayTask = UE.UHiAbilityTask_PlaySequence.CreatePlaySequenceAndWaitProxy(self, "", self.SequenceToPlay, Settings, Bindings);
        PlayTask.OnStop:Add(self, self.OnStopSequence)
        PlayTask:ReadyForActivation()
        self.SequencePlayer = PlayTask:GetLevelSequencePlayer()
    else
        G.log:warn(self.__TAG__, "GA SequenceToPlay not configured.")
        self:K2_EndAbility()
    end
end

function GAKnockBackVehicle:InitBindings()
    local function _MakeActorArray(Actor)
        local Arr = UE.TArray(UE.AActor)
        Arr:Add(Actor)
        return Arr
    end

    local Owner = self:GetAvatarActorFromActorInfo()
    -- G.log:debug("yj", "GAPika_Vehicle:InitBindings Owner.%s Driver.%s", Owner, self:GetDriver())

    local Bindings = UE.TArray(UE.FAbilityTaskSequenceBindings)

    local VehicleBinding = UE.FAbilityTaskSequenceBindings()
    VehicleBinding.BindingTag = "Vehicle"
    VehicleBinding.Actors = _MakeActorArray(Owner)
    Bindings:Add(VehicleBinding)

    local DriverBinding = UE.FAbilityTaskSequenceBindings()
    DriverBinding.BindingTag = "Driver"
    DriverBinding.Actors = _MakeActorArray(self:GetDriver())
    Bindings:Add(DriverBinding)

    return Bindings
end

function GAKnockBackVehicle:GetDriver()
    local Vehicle = self:GetAvatarActorFromActorInfo()
    if Vehicle.VehicleComponent then
        return Vehicle.VehicleComponent.Passengers:Get(1)
    end
end

function GAKnockBackVehicle:OnStopSequence()
    self:K2_EndAbility()
    self.OwnerActor.BuffComponent:RemoveInKnockHitBuff(self.InKnockHandle)
end

return GAKnockBackVehicle
