--- Capture and auto throw GA.

local G = require("G")
local TargetFilter = require("actors.common.TargetFilter")

local GAPlayerBase = require("skill.ability.GAPlayerBase")
local GACaptureAndThrow = Class(GAPlayerBase)

GACaptureAndThrow.__replicates = {
    CaptureTarget = 0,
    TargetLocation = 0,
    Target = 0,
}

function GACaptureAndThrow:K2_PostTransfer()
    Super(GACaptureAndThrow).K2_PostTransfer(self)
    self.CaptureTarget = self.OwnerActor.InteractionComponent.TargetCanCapture
end

function GACaptureAndThrow:K2_CanActivateAbility(ActorInfo, GASpecHandle, OutTags)
    if not self.OwnerActor then
        self.OwnerActor = ActorInfo.AvatarActor
    end
    self.__TAG__ = string.format("(%s, server: %s)", G.GetObjectName(self), self:IsServer())
    if not self.OwnerActor or not self.OwnerActor.InteractionComponent then
        return false
    end

    self.CaptureTarget = self.OwnerActor.InteractionComponent.TargetCanCapture
    if not self.CaptureTarget then
        return false
    end
    G.log:debug(self.__TAG__, "Find nearest capture target: %s", G.GetDisplayName(self.CaptureTarget))

    return true
end

function GACaptureAndThrow:HandleActivateAbility()
    if self:CanCalc() then
        self.TargetLocation, self.Target = self:GetThrowTargetLocation()
        if UE.UKismetMathLibrary.Vector_IsZero(self.TargetLocation) or self.Target == self.CaptureTarget then
            self.TargetLocation, self.Target = self:GetThrowDefaultTargetLocation()
        end

        -- Turn to target.
        local DirToTarget = self.TargetLocation - self.OwnerActor:K2_GetActorLocation()
        UE.UKismetMathLibrary.Vector_Normalize(DirToTarget)
        local ToRotation = UE.UKismetMathLibrary.Conv_VectorToRotator(DirToTarget)
        ToRotation.Pitch = 0
        ToRotation.Roll = 0

        local CustomSmoothContext = UE.FCustomSmoothContext()
        self.OwnerActor:GetLocomotionComponent():Multicast_SetCharacterRotation(ToRotation, false, CustomSmoothContext, true, true)
    end

    Super(GACaptureAndThrow).HandleActivateAbility(self)

    self:HandleCaptureEvent()
    self:HandleThrowEvent()
end

function GACaptureAndThrow:GetCaptureTarget()
    local OwnerActor = self:GetAvatarActorFromActorInfo()
    if not self.__TAG__ then
        self.__TAG__ = string.format("(%s, server: %s)", G.GetObjectName(self), self.OwnerActor:IsServer())
    end

    local ObjectTypes = UE.TArray(UE.EObjectTypeQuery)
    local ActorsToIgnore = UE.TArray(UE.AActor)
    ActorsToIgnore:Add(OwnerActor)
    local Targets = UE.TArray(UE.AActor)

    -- TODO view check.
    UE.UHiCollisionLibrary.SphereOverlapActors(OwnerActor, ObjectTypes, OwnerActor:K2_GetActorLocation(),
            self.CaptureRadius, 0, 0, nil, ActorsToIgnore, Targets, self.bDebug, self.LifeTime)

    -- Filter interactable targets.
    local InteractTargets = UE.TArray(UE.AActor)
    for Ind = 1, Targets:Length() do
        local CurTarget = Targets:Get(Ind)
        local CheckActors = {CurTarget}
        if CurTarget.GetAttachParentActor then
            local ParentActor = CurTarget:GetAttachParentActor()
            if ParentActor then
                table.insert(CheckActors, ParentActor)
            end
        end
        for _,TargetActor in ipairs(CheckActors) do
            if SkillUtils.IsInteractable(TargetActor) then
                InteractTargets:AddUnique(TargetActor)
            end
        end
    end

    --G.log:debug(self.__TAG__, "Find capture actor count: %d", InteractTargets:Length())
    if InteractTargets:Length() > 0 then
        local MinDis
        local CaptureTarget

        for Ind = 1, InteractTargets:Length() do
            local CurTarget = InteractTargets:Get(Ind)
            if not CaptureTarget then
                CaptureTarget = CurTarget
                MinDis = utils.GetDisSquare(CurTarget:K2_GetActorLocation(), OwnerActor:K2_GetActorLocation())
            else
                local CurDis = utils.GetDisSquare(CurTarget:K2_GetActorLocation(), OwnerActor:K2_GetActorLocation())
                if CurDis < MinDis then
                    MinDis = CurDis
                    CaptureTarget = CurTarget
                end
            end
        end

        return CaptureTarget
    end
end

function GACaptureAndThrow:GetThrowTargetLocation()
    return self.OwnerActor.InteractionComponent.ThrowTargetLocation, self.OwnerActor.InteractionComponent.TargetBeSelected
end

function GACaptureAndThrow:GetThrowDefaultTargetLocation()
    local ActorsToIgnore = UE.TArray(UE.AActor)
    ActorsToIgnore:Add(self.OwnerActor)
    ActorsToIgnore:Add(self.CaptureTarget)

    local Targets = UE.TArray(UE.AActor)
    -- TODO filter object types.
    local ObjectTypes = UE.TArray(UE.EObjectTypeQuery)
    ObjectTypes:Add(UE.EObjectTypeQuery.Pawn)
    ObjectTypes:Add(UE.EObjectTypeQuery.MountActor)
    ObjectTypes:Add(UE.EObjectTypeQuery.PhysicsBody)
    UE.UHiCollisionLibrary.SphereOverlapActors(self.OwnerActor, ObjectTypes, self.OwnerActor:K2_GetActorLocation(),
            self.Range, self.Range, self.Range, nil, ActorsToIgnore, Targets, self.bDebug, self.LifeTime)

    local Filter = TargetFilter.new(self.OwnerActor, Enum.Enum_CalcFilterType.AllEnemy)
    local FilteredTargets = UE.TArray(UE.AActor)
    for Ind = 1, Targets:Length() do
        local CurActor = Targets:Get(Ind)
        if Filter:FilterActor(CurActor) then
            FilteredTargets:AddUnique(CurActor)
        end
    end

    if FilteredTargets:Length() > 0 then
        local Target = FilteredTargets:Get(1)
        return Target:K2_GetActorLocation(), Target
    else
        local ForwardVector = self.OwnerActor:GetActorForwardVector()
        local TargetLocation = self.OwnerActor:K2_GetActorLocation() + ForwardVector * self.Range

        -- Try find floor under target position, if no target actor.
        local MaxFindFloorDist = 200
        local StartLocation = TargetLocation
        local EndLocation = TargetLocation - UE.FVector(0, 0, MaxFindFloorDist)
        local OutHit = UE.FHitResult()
        local ActorsToIgnore = UE.TArray(UE.AActor)
        local DrawDebugType =  UE.EDrawDebugTrace.None
        if self.bDebug then
            DrawDebugType = UE.EDrawDebugTrace.ForDuration
        end
        UE.UKismetSystemLibrary.LineTraceSingle(self.OwnerActor:GetWorld(), StartLocation, EndLocation,
                UE.ETraceTypeQuery.WorldStatic, false, ActorsToIgnore, DrawDebugType, OutHit, true, UE.FLinearColor(1, 0, 0), UE.FLinearColor(0, 1, 0), self.LifeTime)

        if OutHit.bBlockingHit then
            return UE.FVector(OutHit.ImpactPoint.X, OutHit.ImpactPoint.Y, OutHit.ImpactPoint.Z), nil
        end

        return TargetLocation, nil
    end
end

function GACaptureAndThrow:HandleCaptureEvent()
    local Task = UE.UAbilityTask_WaitGameplayEvent.WaitGameplayEvent(self, self.CapturePrefixTag, nil, false, false)
    Task.EventReceived:Add(self, self.OnCaptureEvent)
    Task:ReadyForActivation()
    self:AddTaskRefer(Task)
end

function GACaptureAndThrow:OnCaptureEvent()
    if not self:CanCalc() then
        return
    end

    self:OnCapture()
end
UE.DistributedDSLua.RegisterFunction("OnCaptureEvent", GACaptureAndThrow.OnCaptureEvent)

function GACaptureAndThrow:HandleThrowEvent()
    local Task = UE.UAbilityTask_WaitGameplayEvent.WaitGameplayEvent(self, self.ThrowPrefixTag, nil, false, false)
    Task.EventReceived:Add(self, self.OnThrowEvent)
    Task:ReadyForActivation()
    self:AddTaskRefer(Task)
end

function GACaptureAndThrow:OnThrowEvent()
    if not self:CanCalc() then
        return
    end

    self:OnThrow()
end
UE.DistributedDSLua.RegisterFunction("OnThrowEvent", GACaptureAndThrow.OnThrowEvent)

function GACaptureAndThrow:OnCapture()
    G.log:debug(self.__TAG__, "OnCapture")
    local ToTransform = self.OwnerActor:GetTransform()
    if self.CaptureTargetSocket then
        ToTransform = self.OwnerActor.Mesh:GetSocketTransform(self.CaptureTargetSocket)
    else
        G.log:warn(self.__TAG__, "CaptureTargetSocket not config.")
    end

    -- Offset in world space.
    local TargetLocation = ToTransform.Translation + self.CaptureTargetLocationOffset
    self.OwnerActor.InteractionComponent:AbsorbTargetWithProcess(self.CaptureTarget, self.CaptureTime, TargetLocation, self.CaptureTargetSocket, false)
end

function GACaptureAndThrow:OnThrow()
    G.log:debug(self.__TAG__, "OnThrow.")
    self.OwnerActor.InteractionComponent:ThrowTarget(self.TargetLocation , self.ThrowMoveSpeed ,self.ThrowType ,self.ImpulseMag, self.ThrowRotateInfo)
    self.CaptureTarget = nil
end

function GACaptureAndThrow:CanCalc()
    if self:K2_HasAuthority() then
        return true
    end

    return false
end

function GACaptureAndThrow:K2_OnEndAbility(bWasCancelled)
    Super(GACaptureAndThrow).K2_OnEndAbility(self, bWasCancelled)

    -- Handle interrupt.
    if self.CaptureTarget and self:IsServer() then
        G.log:debug(self.__TAG__, "Cancel absorb target when interrupt")
        self.OwnerActor.InteractionComponent:CancelAbsorbTarget()
        self.CaptureTarget = nil
    end
end

UE.DistributedDSLua.RegisterCustomClass("GACaptureAndThrow", GACaptureAndThrow, GAPlayerBase)

return GACaptureAndThrow
