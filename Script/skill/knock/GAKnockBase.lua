local G = require("G")
local StateConflictData = require("common.data.state_conflict_data")
local GABase = require("skill.ability.GABase")

local GAKnockBase = Class(GABase)

function GAKnockBase:K2_ActivateAbilityFromEvent(EventData)
    self:OnActivateAbility()

    G.log:debug(self.__TAG__, "K2_ActivateAbilityFromEvent")
    self.Component = self.OwnerActor.HitComponent
    self.EventData = EventData -- Add refer to avoid gc.

    self:ActivateAbilityFromEvent()

    self.bHitTail = false
    self.bEnd = false
end

function GAKnockBase:ActivateAbilityFromEvent()
    self.KnockParams = {}
    local KnockInfo = self.OwnerActor.HitComponent.KnockInfo
    self.KnockParams.KnockInfo = KnockInfo
    self.KnockParams.Instigator = self.EventData.Instigator
    self.KnockParams.Causer = self.EventData.Instigator
    self.KnockParams.HitResult = KnockInfo.Hit

    self.Component:OnKnockActivated(self)

    -- TODO Stop 3c action (climb end montage .etc.), should changed to use state break (climb end montage as a state).
    self.OwnerActor:GetLocomotionComponent():Replicated_StopMontageGroup("MovementActionGroup")

    self:HandleHitState()
    self:InitKnock(self.KnockParams)
    self:OnKnock(self.KnockParams)
end

function GAKnockBase:HandleHitState()
    -- Weak knock can blendable, not break current animation or skill.
    if self.bBlendable then
        return
    end

    local StateController = self.OwnerActor:_GetComponent("StateController", false)
    if StateController and not StateController:ExecuteAction(StateConflictData.Action_Hit) then
        G.log:debug(self.__TAG__, "State check fail.")
        self:K2_EndAbility()
        return
    end

    self.OwnerActor.CharacterStateManager:SetHitState(true)

    -- TODO Skill state was ended in OnEndAbility, OnEndAbility caused by GAS tags conflict.
    -- When ExecutionAction With Action_hit, already not in Skill_State, cause break skill not invoked.
    -- Here used to reset SkillDriver(reset combo .etc.)
    self.OwnerActor:SendMessage("BreakSkill")
end

function GAKnockBase:InitKnock(KnockParams)
    self.KnockCurDis = 0

    -- Record causer current position when Knock occur.
    self.KnockCauserPos = self.KnockParams.Causer:K2_GetActorLocation()
end

function GAKnockBase:OnKnock(KnockParams)
    local KnockInfo = KnockParams.KnockInfo

    self:HandlePlayMontage()

    if self:IsServer() then
        local ZeroGravityComponent = self.OwnerActor.ZeroGravityComponent
        if ZeroGravityComponent then
			if KnockInfo.EnableZeroGravity and not self.OwnerActor:IsOnFloor() then
				ZeroGravityComponent:EnterZeroGravity(KnockInfo.ZeroGravityTime, true)
			else
				ZeroGravityComponent:EndCurrentZeroGravity()
			end
		end
    end

    self:OnKnockWwiseEvent(self.KnockParams)

    self.OwnerActor:SendMessage("OnKnock", KnockParams.Instigator, KnockParams.Causer, KnockInfo)
end

function GAKnockBase:FaceToInstigator(KnockParams)
    local KnockInfo = KnockParams.KnockInfo
    local direction_vector = KnockParams.Causer:K2_GetActorLocation() - self.OwnerActor:K2_GetActorLocation()
    direction_vector = UE.UKismetMathLibrary.NegateVector(direction_vector)
    if KnockInfo.bUseInstigatorDir and KnockParams.Instigator then
        direction_vector = UE.UKismetMathLibrary.RotateAngleAxis(KnockParams.Instigator:GetActorForwardVector(), KnockInfo.InstigatorAngleOffset, UE.FVector(0, 0, 1))
    end

    local IsInAir = not self.OwnerActor:IsOnFloor()
    if not IsInAir then
        direction_vector.Z = 0
    end
    direction_vector:Normalize()

    local forward_vector = self.OwnerActor:GetActorForwardVector()
    if direction_vector:Size2D() < G.EPS then
        direction_vector = -forward_vector
    end

    direction_vector:Normalize()

    -- Turn to hit causer.
    local direction_yaw = UE.UKismetMathLibrary.Conv_VectorToRotator(direction_vector).Yaw
    local CurRotator = self.OwnerActor:K2_GetActorRotation()
    local ActorRotatorCopy = UE.FRotator(CurRotator.Pitch, CurRotator.Yaw, CurRotator.Roll)
    ActorRotatorCopy.Yaw = direction_yaw + 180
    if ActorRotatorCopy.Yaw < 0 then
        ActorRotatorCopy.Yaw = ActorRotatorCopy.Yaw + 360
    end
    if ActorRotatorCopy.Yaw > 360 then
        ActorRotatorCopy.Yaw = ActorRotatorCopy.Yaw - 360
    end

    self.OwnerActor:K2_SetActorRotation(ActorRotatorCopy, true)
end

function GAKnockBase:HandlePlayMontage(Montage)
    if not Montage then
        Montage = self.MontageToPlay
    end

    if Montage then
        self:PlayMontageWithCallback(self.OwnerActor.Mesh, Montage, 1.0, self.OnKnockMontageEnded, self.OnKnockMontageEnded)
    end
end

function GAKnockBase:GetHitMontageIndex()
    local HitMontages = nil
    if self.OwnerActor:IsOnFloor() then
        HitMontages = self.HitMontages
    else
        HitMontages = self.HitMontages_Air
    end
    local direction_count = 4

    local KnockInfo = self.KnockParams.KnockInfo
    local forward_vector = self.OwnerActor:GetActorForwardVector()
    local direction_vector = self.KnockParams.Causer:K2_GetActorLocation() - self.OwnerActor:K2_GetActorLocation()

    if direction_vector:Size2D() < 1e-4 then
        direction_vector = forward_vector
    end

    if KnockInfo.bUseInstigatorDir and self.KnockParams.Instigator then
        direction_vector = UE.UKismetMathLibrary.RotateAngleAxis(self.KnockParams.Instigator:GetActorForwardVector(), KnockInfo.InstigatorAngleOffset, UE.FVector(0, 0, 1))
    end
    direction_vector.Z = 0

    local forward_yaw = UE.UKismetMathLibrary.Conv_VectorToRotator(forward_vector).Yaw
    local direction_yaw = UE.UKismetMathLibrary.Conv_VectorToRotator(direction_vector).Yaw
    local diff = direction_yaw - forward_yaw
    if diff < 0 then
        diff = diff + 360
    end

    local hit_direction_index = math.floor((diff + 360 / direction_count / 2) * direction_count / 360) % direction_count
    local hit_montage_index = hit_direction_index + 1

    if HitMontages:Length() < hit_montage_index then
        hit_montage_index = 1
    end

    return hit_montage_index
end

function GAKnockBase:OnAkAudioEventCallback(CallbackType, CallbackInfo)
    --G.log:info("hycoldrain", "SkillKnock:OnAkAudioEventCallback")
end

function GAKnockBase:OnKnockWwiseEvent(KnockParams)
    -- Play knock audio only on client.
    if self.OwnerActor:IsClient() then
        local HitAudioEventData = self.HitAudioEvent
        local HitTag = self.EventData.EventTag
        local StrengthKey = nil
        if UE.UBlueprintGameplayTagLibrary.HasTag(self.LightHitTags, HitTag, true) then
            StrengthKey = "Light"
        elseif UE.UBlueprintGameplayTagLibrary.HasTag(self.HeavyHitTags, HitTag, true) then
            StrengthKey = "Heavy"
        end
        --G.log:info("hycoldrain", "SkillKnock:OnKnockWwiseEvent : Enum.Enum_KnockStrength.%s", StrengthKey)
        local HitAudioEvent = HitAudioEventData[StrengthKey]
        if HitAudioEvent and HitAudioEvent:IsValid() then
            --G.log:info("hycoldrain", "SkillKnock:OnKnockWwiseEvent : %s", tostring(HitAudioEvent))        
            local ComponentCreated = false
            local SocketName = HitAudioEventData["SocketName"]
            local Location = self.OwnerActor.Mesh:GetSocketLocation(SocketName)
            local AkComponent = UE.UAkGameplayStatics.GetAkComponent(self.OwnerActor.Mesh, ComponentCreated, "None", ImpactPoint)
            G.log:info("hycoldrain", "UE.UAkGameplayStatics.GetAkComponent : %s %s %s %s", tostring(AkComponent), SocketName, tostring(Location), tostring(self.OwnerActor:K2_GetActorLocation()))
            if AkComponent and AkComponent:IsValid() then   
                G.log:info("hycoldrain", "UE.UAkGameplayStatics.GetAkComponent : %s %s", tostring(AkComponent), tostring(AkComponent:IsValid()))
                local ExternalSources = UE.TArray(UE.FAkExternalSourceInfo)       
                AkComponent:PostAkEvent(HitAudioEvent, 0, {self, self.OnAkAudioEventCallback}, ExternalSources, "")
            end
        end
    end    
end

function GAKnockBase:OnKnockMontageEnded(MontageName)
    G.log:debug(self.__TAG__, "OnKnockMontageEnded %s", tostring(MontageName))

    self:K2_EndAbilityLocally()
end

function GAKnockBase:OnComboTailEvent(Payload)
    Super(GAKnockBase).OnComboTailEvent(self, Payload)
    self.bHitTail = true
end

function GAKnockBase:HandleComboTailState(Payload)
    Super(GAKnockBase).HandleComboTailState(self, Payload)

    if not self:IsClient() then
        return
    end

    local EventTag = Payload.EventTag
    local bNotMovable = UE.UBlueprintGameplayTagLibrary.EqualEqual_GameplayTag(EventTag, self.ComboTailNotMovableTag)

    self.OwnerActor:SendMessage("EndState", StateConflictData.State_Hit, false)
    if bNotMovable then
        self.OwnerActor:SendMessage("EnterState", StateConflictData.State_HitTail_NotMovable)
    else
        self.OwnerActor:SendMessage("EndState", StateConflictData.State_HitTail_NotMovable)
        self.OwnerActor:SendMessage("EnterState", StateConflictData.State_HitTail)
    end
end

function GAKnockBase:IsHitTail()
    return self.bHitTail
end

function GAKnockBase:HandleEndAbility(bWasCancelled)
    Super(GAKnockBase).HandleEndAbility(self, bWasCancelled)

    self.Component:OnKnockDeactivated(self)
    self.bHitTail = false
end

function GAKnockBase:HandleMovementAndStateWhenEnd(bWasCancelled)
    if not self.bBlendable then
        self.OwnerActor:SendMessage("EndState", StateConflictData.State_Hit, false)
        self.OwnerActor:SendMessage("EndState", StateConflictData.State_HitTail, false)
        self.OwnerActor:SendMessage("EndState", StateConflictData.State_HitTail_NotMovable, false)
    end
end

return GAKnockBase
