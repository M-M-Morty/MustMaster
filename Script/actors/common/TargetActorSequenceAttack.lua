require "UnLua"

-- TargetActorSequenceAttack use in weapon or something sequence attack.
-- And this will use PrimComp sweep to hit targets.
local G = require("G")

local TargetActor = require("actors.common.TargetActor")

local HiCollisionLibrary = require("common.HiCollisionLibrary")
local ComponentUtils = require("common.component_utils")

local TargetActorSequenceAttack = Class(TargetActor)

function TargetActorSequenceAttack:Initialize(...)
    Super(TargetActorSequenceAttack).Initialize(self, ...)
end

function TargetActorSequenceAttack:ReceiveBeginPlay()
    Super(TargetActorSequenceAttack).ReceiveBeginPlay(self)

    self:SetActorTickEnabled(true)
end

function TargetActorSequenceAttack:ReceiveTick(DeltaSeconds)
    if self:IsShouldProduceTargetDataOnServer() and not self:IsServer() then
        return
    end

    local PrimComp = self.KnockInfo.PrimComp
    if not PrimComp then
        return
    end

    if not SkillUtils.IsComponentAttacking(PrimComp) then
        return
    end

    if self.SourceActor and self.SourceActor.TimeDilationComponent and self.SourceActor.TimeDilationComponent.bWitchTime then
        return
    end

    self:Attack()
end

function TargetActorSequenceAttack:Attack()
    local PrimComp = self.KnockInfo.PrimComp
    local AttackInterval = self.KnockInfo.AttackInterval
    local CurLocation = PrimComp:K2_GetComponentLocation()
    local CurRotation = PrimComp:K2_GetComponentRotation()

    if self.bDebug then
        UE.UKismetSystemLibrary.DrawDebugPoint(self:GetWorld(), CurLocation, 20, UE.FLinearColor(1, 0, 0), self.DebugTime)
        UE.UKismetSystemLibrary.DrawDebugArrow(self:GetWorld(), CurLocation, CurLocation + UE.UKismetMathLibrary.Conv_RotatorToVector(CurRotation) * 100, 10, UE.FLinearColor(0, 1, 0), self.DebugTime, 2)
    end

    if not self.LastCompLocation then
        self.LastCompLocation = CurLocation
        self.LastCompRotation = CurRotation
        return
    end

    local LastCompRotationVec = UE.UKismetMathLibrary.Normal(UE.UKismetMathLibrary.Conv_RotatorToVector(self.LastCompRotation))
    local CurCompRotation = PrimComp:K2_GetComponentRotation()
    local CurCompRotationVec = UE.UKismetMathLibrary.Normal(UE.UKismetMathLibrary.Conv_RotatorToVector(CurCompRotation))

    local Hits = UE.TArray(UE.FHitResult)
    local ActorsToIgnore = UE.TArray(UE.AActor)
    ActorsToIgnore:AddUnique(self.SourceActor)
    if self.CollisionType == Enum.Enum_CollisionType.Sphere then
        UE.UKismetSystemLibrary.SphereTraceMultiForObjects(self:GetWorld(), self.LastCompLocation, CurLocation, self.CollisionRadius, self.Spec.HitTypes, false, ActorsToIgnore, self.DebugType, Hits, true)
    elseif self.CollisionType == Enum.Enum_CollisionType.Box then
        local LastSweepLocation = self.LastCompLocation + LastCompRotationVec * self.CollisionHalfHeight
        local CurSweepLocation = CurLocation + LastCompRotationVec * self.CollisionHalfHeight
        UE.UKismetSystemLibrary.BoxTraceMultiForObjects(self:GetWorld(), LastSweepLocation, CurSweepLocation, self.CollisionHalfExtent, self.LastCompRotation, self.Spec.HitTypes, false, ActorsToIgnore, self.DebugType, Hits, true)
    elseif self.CollisionType == Enum.Enum_CollisionType.Capsule then
        -- TODO Need optimize: here use single capsule sweep, will leak detect when component rotation changed significantly. Even sweep use last and current rotation not enough.
        local TempHits = UE.TArray(UE.FHitResult)
        -- Sweep use last rotation.
        --if self.LastSweepRotation then
        --    local LastSweepLocation = self.LastCompLocation + LastCompRotationVec * self.CollisionHalfHeight
        --    local CurSweepLocation = CurLocation + LastCompRotationVec * self.CollisionHalfHeight
        --
        --    if self.bDebug then
        --        UE.UKismetSystemLibrary.DrawDebugArrow(self:GetWorld(), LastSweepLocation, CurSweepLocation, 10, UE.FLinearColor(0, 1, 1), self.DebugTime, 2)
        --        UE.UKismetSystemLibrary.DrawDebugArrow(self:GetWorld(), self.LastCompLocation, CurLocation, 10, UE.FLinearColor(1, 1, 0), self.DebugTime, 2)
        --    end
        --
        --    UE.UHiCollisionLibrary.CapsuleTraceMultiForObjects(self:GetWorld(), LastSweepLocation, CurSweepLocation, self.LastSweepRotation, self.CollisionRadius, self.CollisionHalfHeight, self.Spec.HitTypes, true, ActorsToIgnore, self.DebugType, TempHits, true, UE.FLinearColor(1, 0, 0), UE.FLinearColor(0, 1, 0), self.DebugTime)
        --    Hits:Append(TempHits)
        --end

        -- Sweep use current rotation.
        local LastSweepLocation = self.LastCompLocation + CurCompRotationVec * self.CollisionHalfHeight
        local CurSweepLocation = CurLocation + CurCompRotationVec * self.CollisionHalfHeight

        if self.bDebug then
            UE.UKismetSystemLibrary.DrawDebugArrow(self:GetWorld(), LastSweepLocation, CurSweepLocation, 10, UE.FLinearColor(0, 1, 1), self.DebugTime, 2)
            UE.UKismetSystemLibrary.DrawDebugArrow(self:GetWorld(), self.LastCompLocation, CurLocation, 10, UE.FLinearColor(1, 1, 0), self.DebugTime, 2)
        end

        -- Capsule trace orientation need to specific handle.
        local NewRelativeRotVec = UE.UKismetMathLibrary.RotateAngleAxis(UE.UKismetMathLibrary.Conv_RotatorToVector(PrimComp.RelativeRotation), 90, UE.FVector(0, 1, 0))
        local NewRot = UE.UKismetMathLibrary.TransformRotation(PrimComp:K2_GetComponentToWorld(), UE.UKismetMathLibrary.Conv_VectorToRotator(NewRelativeRotVec))
        UE.UHiCollisionLibrary.CapsuleTraceMultiForObjects(self:GetWorld(), LastSweepLocation, CurSweepLocation, NewRot, self.CollisionRadius, self.CollisionHalfHeight, self.Spec.HitTypes, true, ActorsToIgnore, self.DebugType, TempHits, true, UE.FLinearColor(1, 0, 0), UE.FLinearColor(0, 1, 0), self.DebugTime)
        Hits:Append(TempHits)

        self.LastSweepRotation = NewRot
    end

    self.LastCompLocation = CurLocation
    self.LastCompRotation = CurRotation

    -- Check attack interval
    local ResHits = UE.TArray(UE.FHitResult)
    for ind = 1, Hits:Length() do
        local CurHit = Hits:Get(ind)
        local HitActor = CurHit.Component:GetOwner()
        if HitActor then
            local Now = UE.UKismetMathLibrary.Now()
            if HitActor ~= self.SourceActor and
                    not ComponentUtils.ComponentUnHitable(CurHit.Component) and
                    (not self.LastHitTimeDict[HitActor] or utils.GetSecondsElapsed(self.LastHitTimeDict[HitActor], Now) > AttackInterval) then
                ResHits:AddUnique(CurHit)
                self.LastHitTimeDict[HitActor] = Now
            end
        end
    end

    if ResHits:Length() > 0 then
        G.log:debug("santi", "TargetActorSequenceAttack hits: %d", ResHits:Length())
        self:SendMessage("ExecCalcForHits", ResHits, self, true, true)
    end
end

function TargetActorSequenceAttack:OnStartTargeting(Ability)
    G.log:debug("santi", "TargetActorSequenceAttack OnStartTargeting: %s, IsServer: %s", G.GetDisplayName(self), self:IsServer())

    self.OwningAbility = Ability
    self.SourceActor = Ability:GetAvatarActorFromActorInfo()

    -- Init skill target.
    self:_InitSkillTarget(Ability)

    -- Init caculator for hits.
    self:SendMessage("InitCalcForHits", self.SourceActor, self.SourceActor, 
        self.Spec, self.KnockInfo, self.GameplayEffectsHandle, self.HitSceneTargetConfig)

    self.LastHitTimeDict = {}
end

function TargetActorSequenceAttack:_InitSkillTarget(Ability)
    local UserData = Ability:GetCurrentUserData()

    if UserData then
        self.SkillTarget = UserData.SkillTarget
        self.SkillTargetTransform = UserData.SkillTargetTransform
    end
end

function TargetActorSequenceAttack:OnConfirmTargetingAndContinue()
    assert(false)
end


return RegisterActor(TargetActorSequenceAttack)
