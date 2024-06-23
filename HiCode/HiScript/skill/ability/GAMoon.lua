-- Charge GA.
local G = require("G")
local GASkillBase = require("skill.ability.GASkillBase")
local GAMoon = Class(GASkillBase)

function GAMoon:HandleActivateAbility()
    local OwnerActor = self:GetAvatarActorFromActorInfo()
    local OwnerTransform = OwnerActor:GetTransform()
    local MoonLocation = UE.UKismetMathLibrary.TransformLocation(OwnerTransform, self.MoonLocationOffset)
    local MoonRotation = UE.UKismetMathLibrary.TransformRotation(OwnerTransform, self.MoonRotationOffset)
    local MoonTransform = UE.UKismetMathLibrary.MakeTransform(MoonLocation, MoonRotation)
    self.MoonActor = GameAPI.SpawnActor(self:GetWorld(), self.MoonActorClass, MoonTransform,  UE.FActorSpawnParameters(), {})
    self.LightActor = GameAPI.SpawnActor(self:GetWorld(), self.LightActorClass, UE.UKismetMathLibrary.MakeTransform(),  UE.FActorSpawnParameters(), {})

    -- TODO Temp avoid notify trigger multi times bug.
    self.bHasAttack = false
    if not self:IsServer() then
        self.ZGHandle = OwnerActor.ZeroGravityComponent:EnterZeroGravity(-1, false)
    end
    self:PlayForwardSequence()
end

function GAMoon:PlayForwardSequence()
    -- Player forward camera sequence
    -- Attention: Camera sequence should play before animation sequence.
    -- Otherwise when current skill step animation sequence play and stopped immediately, and play next step's camera sequence, cause crash.
    if self:IsClient() and self.ForwardCameraSequence then
        local PlayerCameraManager = UE.UGameplayStatics.GetPlayerController(self.OwnerActor:GetWorld(), 0).PlayerCameraManager
        if self.bDebug then
            PlayerCameraManager.bDebug = true
        end
        local OwnerTransform = self.OwnerActor:GetTransform()
        local Params = UE.FCameraAnimationParams()
        Params.PlaySpace = UE.ECameraAnimationPlaySpace.UserDefined
        Params.UserPlaySpaceLocation = UE.UKismetMathLibrary.TransformLocation(OwnerTransform, self.CameraRelativeLocation)
        Params.UserPlaySpaceRotator = UE.UKismetMathLibrary.TransformRotation(OwnerTransform, self.CameraRelativeRotation)
        self.ForwardCameraSequenceHandler = PlayerCameraManager:PlaySequence(self.ForwardCameraSequence, Params)
    end

    G.log:debug("GAMoon", "Play forward sequence: %s, IsServer: %s", G.GetDisplayName(self.ForwardSequence), self:IsServer())
    local OwnerActor = self:GetAvatarActorFromActorInfo()
    local Settings = UE.FMovieSceneSequencePlaybackSettings()
    local Bindings = self:InitBindings()
    self.ForwardSequenceTask = UE.UHiAbilityTask_PlaySequence.CreatePlaySequenceAndWaitProxy(self, "", self.ForwardSequence, Settings, Bindings);
    self.ForwardSequenceTask.OnStop:Add(self, self.OnStopForwardSequence)
    self.ForwardSequenceTask:ReadyForActivation()
    self.ForwardSequencePlayer = self.ForwardSequenceTask:GetLevelSequencePlayer()

    if OwnerActor.OnMoveBlockedBy then
        OwnerActor.OnMoveBlockedBy:Add(self, self.OnOwnerMoveBlockedBy)
    end

    -- TODO reuse TargetActor to unify handle.
    self:AddTriggerComponent()
end

function GAMoon:StopForwardSequence()
    if self.ForwardSequencePlayer then
        G.log:debug("GAMoon", "GAMoon StopForwardSequence")
        self.ForwardSequencePlayer:Stop()
    end

    if self.ForwardCameraSequenceHandler then
        local OwnerActor = self:GetAvatarActorFromActorInfo()
        local PlayerCameraManager = UE.UGameplayStatics.GetPlayerController(OwnerActor:GetWorld(), 0).PlayerCameraManager
        PlayerCameraManager:StopSequence(self.ForwardCameraSequenceHandler)
    end
end

function GAMoon:AddTriggerComponent()
    local OwnerActor = self:GetAvatarActorFromActorInfo()
    self.TriggerComponent = NewObject(UE.USphereComponent, OwnerActor)
    self.TriggerComponent:SetSphereRadius(self.TriggerRadius)
    if self.TriggerComponent then
        UE.UHiUtilsFunctionLibrary.RegisterComponent(self.TriggerComponent)

        self.TriggerComponent:SetGenerateOverlapEvents(true)
        self.TriggerComponent:SetCollisionEnabled(UE.ECollisionEnabled.QueryOnly)
        -- TODO reuse projectile.
        self.TriggerComponent:SetCollisionObjectType(UE.ECollisionChannel.ECC_Pawn)
        self.TriggerComponent.OnComponentBeginOverlap:Add(self, self.BeginOverlap)
        self.TriggerComponent:K2_AttachToComponent(OwnerActor:K2_GetRootComponent(), "", UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative)
    end
end

function GAMoon:RemoveTriggerComponent()
    if self.TriggerComponent then
        self.TriggerComponent:K2_DetachFromComponent()
        self.TriggerComponent:K2_DestroyComponent()
    end
end

function GAMoon:BeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    local OwnerActor = self:GetAvatarActorFromActorInfo()

    if OtherActor == OwnerActor then
        return
    end

    local ObjectType = OtherComp:GetCollisionObjectType()
    if ObjectType ~= UE.ECollisionChannel.ECC_Pawn then
        return
    end

    G.log:debug("GAMoon", "GAMoon overlap actor: %s, ObjectType: %d", G.GetDisplayName(OtherActor), ObjectType)

    self:TrySwitchToAttack()
end

function GAMoon:PlayAttackSequence()
    local SocketLocation = self.MoonActor.SkeletalMeshComponent:GetSocketLocation("root")
    self.MoonActor:K2_SetActorLocation(SocketLocation, false, nil, true)

    -- Play attack camera sequence.
    if self:IsClient() and self.AttackCameraSequence then
        local OwnerActor = self:GetAvatarActorFromActorInfo()
        local PlayerCameraManager = UE.UGameplayStatics.GetPlayerController(OwnerActor:GetWorld(), 0).PlayerCameraManager
        local OwnerTransform = OwnerActor:GetTransform()
        local Params = UE.FCameraAnimationParams()
        Params.PlaySpace = UE.ECameraAnimationPlaySpace.UserDefined
        Params.UserPlaySpaceLocation = UE.UKismetMathLibrary.TransformLocation(OwnerTransform, self.CameraRelativeLocation)
        Params.UserPlaySpaceRotator = UE.UKismetMathLibrary.TransformRotation(OwnerTransform, self.CameraRelativeRotation)

        self.AttackCameraSequenceHandler = PlayerCameraManager:PlaySequence(self.AttackCameraSequence, Params)
    end

    G.log:debug("GAMoon", "Play attack sequence: %s, IsServer: %s", G.GetDisplayName(self.AttackSequence), self:IsServer())
    local Settings = UE.FMovieSceneSequencePlaybackSettings()
    local Bindings = self:InitBindings()
    self.AttackSequenceTask = UE.UHiAbilityTask_PlaySequence.CreatePlaySequenceAndWaitProxy(self, "", self.AttackSequence, Settings, Bindings);
    self.AttackSequenceTask.OnStop:Add(self, self.OnStopAttackSequence)
    self.AttackSequenceTask:ReadyForActivation()
    self.AttackSequencePlayer = self.AttackSequenceTask:GetLevelSequencePlayer()

    if self:IsServer() then
        self:HandleCalc()
    end
end

function GAMoon:StopAttackSequence()
    if self.AttackSequencePlayer then
        G.log:debug("GAMoon", "GAMoon StopAttackSequence")
        self.AttackSequencePlayer:Stop()
    end
end

function GAMoon:PlayEndSequence()
    -- Stop anim in sequence, to break KeepState to idle on ground.
    if self.OwnerActor.Mesh then
        self.OwnerActor.Mesh:GetAnimInstance():StopSlotAnimation()
    end

    local Settings = UE.FMovieSceneSequencePlaybackSettings()
    local Bindings = self:InitBindings({Player = true})
    self.EndSequenceTask = UE.UHiAbilityTask_PlaySequence.CreatePlaySequenceAndWaitProxy(self, "", self.EndSequence, Settings, Bindings);
    self.EndSequenceTask.OnStop:Add(self, self.OnStopEndSequence)
    self.EndSequenceTask:ReadyForActivation()
    self.EndSequencePlayer = self.EndSequenceTask:GetLevelSequencePlayer()

    self:RemoveTriggerComponent()
end

function GAMoon:StopEndSequence()
    if self.EndSequencePlayer then
        G.log:debug("GAMoon", "GAMoon StopEndSequence")
        self.EndSequencePlayer:Stop()
    end
end

function GAMoon:InitBindings(BindingMap)
    if not BindingMap then
        BindingMap = {
            Player = true,
            Moon = true,
            Light = true,
        }
    end
    local Bindings = UE.TArray(UE.FAbilityTaskSequenceBindings)

    -- Player binding.
    if BindingMap["Player"] then
        local OwnerActor = self:GetAvatarActorFromActorInfo()
        local PlayerBinding = UE.FAbilityTaskSequenceBindings()
        PlayerBinding.BindingTag = self.PlayerBindingTag
        PlayerBinding.Actors = _MakeActorArray(OwnerActor)
        Bindings:Add(PlayerBinding)
    end

    -- Moon binding.
    if BindingMap["Moon"] then
        local MoonBinding = UE.FAbilityTaskSequenceBindings()
        MoonBinding.BindingTag = self.MoonBindingTag
        MoonBinding.Actors = _MakeActorArray(self.MoonActor)
        Bindings:Add(MoonBinding)
    end

    -- Light binding.
    if BindingMap["Light"] then
        local LightBinding = UE.FAbilityTaskSequenceBindings()
        LightBinding.BindingTag = self.LightBindingTag
        LightBinding.Actors = _MakeActorArray(self.LightActor)
        Bindings:Add(LightBinding)
    end

    return Bindings
end

function GAMoon:OnOwnerMoveBlockedBy(HitResult)
    G.log:debug("GAMoon", "GAMoon OnOwnerMoveBlockedBy, IsServer: %s.", self:IsServer())

    self:TrySwitchToAttack()
end

function GAMoon:TrySwitchToAttack()
    if self.bHasAttack then
        return
    end
    self.bHasAttack = true

    self:StopForwardSequence()
    self:PlayAttackSequence()
    local OwnerActor = self:GetAvatarActorFromActorInfo()
    if OwnerActor.OnMoveBlockedBy then
        OwnerActor.OnMoveBlockedBy:Remove(self, self.OnOwnerMoveBlockedBy)
    end
end

function GAMoon:OnStopForwardSequence()
    if self.bEnd then
        return
    end

    G.log:debug("GAMoon", "GAMoon OnStopForwardSequence, IsServer: %s.", self:IsServer())
    self:TrySwitchToAttack()
end

function GAMoon:OnStopAttackSequence()
    if self.LightActor then
        self.LightActor:K2_DestroyActor()
        self.LightActor = nil
    end

    if self.MoonActor then
        self.MoonActor:K2_DestroyActor()
        self.MoonActor = nil
    end

    if self.bEnd then
        return
    end

    -- Should play end sequence in attack sequence OnStop callback, otherwise end sequence may blended and not completed.
    self:PlayEndSequence()
end

function GAMoon:OnCalcEvent(Payload)
    local EventTag = Payload.EventTag
    if EventTag == self.AttackTag then
        -- AttackTag use targets from AttackPreTag, no need to spawn TargetActor.
        self.KnockInfo = Payload.OptionalObject

        -- Trigger attack directly.
        if self.Hits and self.Hits:Length() > 0 then
            G.log:debug("GAMoon", "Attack count: %d, tag: %s, IsServer: %s", self.Hits:Length(), UE.UBlueprintGameplayTagLibrary.GetTagName(EventTag), self:K2_HasAuthority())
            self.AttackList = _GenerateAttackList(self.Hits:Length(), self.ShadowEffects.GameplayTags:Length())
            self.CurAttackInd = 1
            self.EventTag = EventTag
            self:ScheduleAttack()
        end
    elseif EventTag == self.AttackPreTag then
        Super(GAMoon).OnCalcEvent(self, Payload)
    else
        G.log:error("GAMoon", "Not handled calc event: %s", UE.UBlueprintGameplayTagLibrary.GetTagName(EventTag))
    end
end

function GAMoon:OnValidDataCallback(Data, EventTag)
    Super(GAMoon).OnValidDataCallback(self, Data, EventTag)

    local Hits = UE.TArray(UE.FHitResult)
    UE.UAbilitySystemBlueprintLibrary.GetAllHitResultsFromTargetData(Data, Hits)

    self.Hits = UE.TArray(UE.FHitResult)
    for Ind = 1, Hits:Length() do
        local CurHit = Hits:Get(Ind)
        local ObjectType = CurHit.Component:GetCollisionObjectType()
        if SkillUtils.IsObjectTypeDamageable(ObjectType) then
            self.Hits:AddUnique(CurHit)
        end
    end

    -- Record hits from AttackPre, will used in Attack.
    G.log:debug("GAMoon", "OnValidDataCallback hits: %d, tag: %s, IsServer: %s", self.Hits:Length(), UE.UBlueprintGameplayTagLibrary.GetTagName(EventTag), self:K2_HasAuthority())
end

function GAMoon:ScheduleAttack()
    self.AttackTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.Attack}, self.AttackInterval,false)
end

function GAMoon:Attack()
    local CurTargetIndex = self.AttackList[self.CurAttackInd]
    G.log:debug("GAMoon", "GAMoon Attack target index: %d(%d), IsServer: %s", self.CurAttackInd, CurTargetIndex, self:IsServer())

    local CurHit = self.Hits:Get(CurTargetIndex)
    local bDead, HitActor = CheckHitActor(CurHit)
    if not bDead and HitActor then
        HitActor:SendMessage("HandleKnock", self.OwnerActor, self.OwnerActor, self.KnockInfo)

        local TargetDataHandle = UE.UAbilitySystemBlueprintLibrary.AbilityTargetDataFromHitResult(CurHit)
        local ShadowEffectInd = self.CurAttackInd
        ShadowEffectInd = (ShadowEffectInd - 1) % self.ShadowEffects.GameplayTags:Length() + 1
        local ShadowEffectTag = self.ShadowEffects.GameplayTags:Get(ShadowEffectInd)
        self:ApplyGEToTargetData(TargetDataHandle, ShadowEffectTag)
    end

    if self.CurAttackInd >= #self.AttackList then
        self:StopAttackSequence()
        return
    end

    if bDead then
        -- Regenerate target list by replace dead target.
        local bRefresh = self:_RefreshAttackList(self.CurAttackInd)
        if not bRefresh then
            -- No alive targets anymore, stop schedule attack.
            self:StopAttackSequence()
            return
        end

        -- Try attack next target when current dead.
        self:Attack()
    else
        self.CurAttackInd = self.CurAttackInd + 1
        self:ScheduleAttack()
    end
end

---Check whether hit result actor dead.
---@return boolean, AActor (bDead, HitActor)
function CheckHitActor(Hit)
    if Hit and Hit.Component and UE.UKismetSystemLibrary.IsValid(Hit.Component) then
        local HitActor = Hit.Component:GetOwner()
        if HitActor and UE.UKismetSystemLibrary.IsValid(HitActor) and not HitActor:IsDead() then
            return false, HitActor
        end
    end

    return true, nil
end

function _MakeActorArray(Actor)
    local Arr = UE.TArray(UE.AActor)
    Arr:Add(Actor)
    return Arr
end

function _GenerateAttackList(TargetCount, EffectCount)
    if TargetCount > EffectCount then
        TargetCount = EffectCount
    end

    local OutIndexList = {}
    local Avg = math.floor(EffectCount / TargetCount)
    local Left = EffectCount % TargetCount
    for Ind = 1, TargetCount do
        local Add = 0
        if Ind <= Left then
            Add = 1
        end

        for _ = 1, Avg + Add do
            table.insert(OutIndexList, Ind)
        end
    end
    return OutIndexList
end

function GAMoon:_RefreshAttackList(DeadInd)
    local DeadTargetInd = self.AttackList[DeadInd]
    local AliveList = {}
    for Ind = 1, #self.AttackList do
        local CurTargetIndex = self.AttackList[Ind]
        if CurTargetIndex ~= DeadTargetInd then
            local CurHit = self.Hits:Get(CurTargetIndex)
            local bDead = CheckHitActor(CurHit)
            if not bDead then
                table.insert(AliveList, CurTargetIndex)
            end
        end
    end

    if #AliveList == 0 then
        return false
    end

    local bRefresh = false
    local AllocInd = 1
    for Ind = DeadInd, #self.AttackList do
        if AllocInd > #AliveList then
            AllocInd = 1
        end

        if self.AttackList[Ind] == DeadTargetInd then
            self.AttackList[Ind] = AliveList[AllocInd]
            AllocInd = AllocInd + 1
            bRefresh = true
        end
    end

    return bRefresh
end

function GAMoon:OnStopEndSequence()
    G.log:debug("GAMoon", "GAMoon OnStopEndSequence, IsServer: %s.", self:IsServer())

    self:K2_EndAbilityLocally()
end

function GAMoon:HandleEndAbility(bWasCancelled)
    G.log:debug("GAMoon", "HandleEndAbility")
    Super(GAMoon).HandleEndAbility(self, bWasCancelled)

    if not self:IsServer() then
        self.OwnerActor.ZeroGravityComponent:EndZeroGravity(self.ZGHandle)
    end

    self:StopForwardSequence()
    self:StopAttackSequence()
    self:StopEndSequence()

    if self.LightActor then
        self.LightActor:K2_DestroyActor()
        self.LightActor = nil
    end

    if self.MoonActor then
        self.MoonActor:K2_DestroyActor()
        self.MoonActor = nil
    end

    if self.bDebug then
        local OwnerActor = self:GetAvatarActorFromActorInfo()
        local PlayerCameraManager = UE.UGameplayStatics.GetPlayerController(OwnerActor:GetWorld(), 0).PlayerCameraManager
        PlayerCameraManager.bDebug = false
    end
end

return GAMoon
