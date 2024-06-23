--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')

---@type BP_PerceptionComponent_C
local BP_PerceptionComponent_C = Class()

-- function BP_PerceptionComponent_C:Initialize(Initializer)
-- end

function BP_PerceptionComponent_C:ReceiveBeginPlay()
    self.tbSightActors = {}
    self.LastVisionAdd = 0
    self.LastSoundAdd = 0
    self.GE_SightDec_Handle = nil
    self.GE_SoundDec_Handle = nil
end

-- function BP_PerceptionComponent_C:ReceiveEndPlay()
-- end

function BP_PerceptionComponent_C:GetGameplayEffect(key)
    return self.vGEMap:Find(key)
end

function BP_PerceptionComponent_C:ReceiveTick(DeltaSeconds)
    local selfActor = self:GetOwner()
    if UE.UKismetSystemLibrary.IsServer(selfActor) then
        local current = UE.UHiUtilsFunctionLibrary.GetNowTimestampMs()

        local ASC = selfActor:GetAbilitySystemComponent()
        if (not self.GE_SightDec_Handle) and current - self.LastVisionAdd > self.VisionGuardReset * 1000 then
            local GE_SightDec_SpecHandle = ASC:MakeOutgoingSpec(self:GetGameplayEffect('GE_SightDec_C'), 1, UE.FGameplayEffectContextHandle())
            self.GE_SightDec_Handle = ASC:BP_ApplyGameplayEffectSpecToSelf(GE_SightDec_SpecHandle)
        end

        if (not self.GE_SoundDec_Handle) and current - self.LastSoundAdd > self.SoundGuardReset * 1000 then
            local GE_SoundDec_SpecHandle = ASC:MakeOutgoingSpec(self:GetGameplayEffect('GE_SoundDec_C'), 1, UE.FGameplayEffectContextHandle())
            self.GE_SoundDec_Handle = ASC:BP_ApplyGameplayEffectSpecToSelf(GE_SoundDec_SpecHandle)
        end
    end
end

function BP_PerceptionComponent_C:HandleSightUpdated(InTargetActor, InStimulus)
    --UnLua.LogWarn("duzy", "HandleSightUpdated", UE.UHiBlueprintFunctionLibrary.GetPIEWorldNetDescription(self:GetOwner()), InTargetActor, InStimulus, InStimulus.bSuccessfullySensed)
    
    if not FunctionUtil:IsPlayer(InTargetActor) then
        return
    end

    local selfActor = self:GetOwner()
    local ASC = selfActor:GetAbilitySystemComponent()
    if InStimulus.bSuccessfullySensed then
        local GE_SightInc_Object = UE.NewObject(self:GetGameplayEffect('GE_SightInc_C'), selfActor)
        local GE_SightInc_SpecHandle = UE.UAbilitySystemBlueprintLibrary.MakeSpecHandle(GE_SightInc_Object, selfActor, InTargetActor)
        --local GE_SightInc_SpecHandle = ASC:MakeOutgoingSpec(self:GetGameplayEffect('GE_SightInc_C'), 1, UE.FGameplayEffectContextHandle())
        local GE_SightInc_Handle = ASC:BP_ApplyGameplayEffectSpecToSelf(GE_SightInc_SpecHandle)
        self.tbSightActors[InTargetActor] = GE_SightInc_Handle -- GE
        self.vSightActors:Add(InTargetActor)
        if self.vSightActors:Length() == 1 then
            selfActor.ChararacteStateManager:AddStateTagDirect("StateGH.VisionTarget")
        end
    else
        local GE_SightInc_Handle = self.tbSightActors[InTargetActor]
        if GE_SightInc_Handle then
            ASC:RemoveActiveGameplayEffect(GE_SightInc_Handle, -1)
            self.tbSightActors[InTargetActor] = nil
        end
        self.vSightActors:RemoveItem(InTargetActor)
        if self.vSightActors:Length() == 0 then
            selfActor.ChararacteStateManager:RemoveStateTagDirect("StateGH.VisionTarget")
        end
    end
end

function BP_PerceptionComponent_C:HandleHearingUpdated(InTargetActor, InStimulus)
    --UnLua.LogWarn("duzy", "HandleHearingUpdated", UE.UHiBlueprintFunctionLibrary.GetPIEWorldNetDescription(self:GetOwner()), InTargetActor, InStimulus, InStimulus.bSuccessfullySensed)
    
    if not FunctionUtil:IsPlayer(InTargetActor) then
        return
    end

    local selfActor = self:GetOwner()
    local GE_SoundInc_Object = UE.NewObject(self:GetGameplayEffect('GE_SoundInc_C'), selfActor)
    local GE_SoundInc_SpecHandle = UE.UAbilitySystemBlueprintLibrary.MakeSpecHandle(GE_SoundInc_Object, selfActor, InTargetActor)
    --local GE_SoundInc_SpecHandle = ASC:MakeOutgoingSpec(self:GetGameplayEffect('GE_SoundInc_C'), 1, UE.FGameplayEffectContextHandle())
    local ASC = selfActor:GetAbilitySystemComponent()
    ASC:BP_ApplyGameplayEffectSpecToSelf(GE_SoundInc_SpecHandle)

    --fire montage react
    local lookAt = UE.UKismetMathLibrary.FindLookAtRotation(selfActor:K2_GetActorLocation(), InStimulus.StimulusLocation)
    local deltaRot = UE.UKismetMathLibrary.NormalizedDeltaRotator(selfActor:K2_GetActorRotation(), lookAt)
    local montageKey = ((deltaRot.Yaw > 0) and 'LeftHearing' or 'RightHearing')
    local montageObj = self.Montages:Find(montageKey)
    if montageObj then
        selfActor.ChararacteStateManager:NotifyEvent('PlayMontage', montageObj)
    end
end

function BP_PerceptionComponent_C:HandleDamageUpdated(InTargetActor, InStimulus)
    --UnLua.LogWarn("duzy", "HandleDamageUpdated", UE.UHiBlueprintFunctionLibrary.GetPIEWorldNetDescription(self:GetOwner()), InTargetActor, InStimulus, InStimulus.bSuccessfullySensed)

    local ASC = self:GetOwner():GetAbilitySystemComponent()
    local GE_DamageInc_SpecHandle = ASC:MakeOutgoingSpec(self:GetGameplayEffect('GE_DamageInc_C'), 1, UE.FGameplayEffectContextHandle())
    ASC:BP_ApplyGameplayEffectSpecToSelf(GE_DamageInc_SpecHandle)
end

function BP_PerceptionComponent_C:PostSightChange(NewValue, OldValue)
    local VisionGuardMax = self.VisionGuardMax
    local unclamp_change = NewValue - OldValue
    local selfActor = self:GetOwner()

    --clamp limit
    if not UE.UKismetMathLibrary.InRange_FloatFloat(NewValue, 0, VisionGuardMax, true, true) then
        NewValue = UE.UKismetMathLibrary.FClamp(NewValue, 0, VisionGuardMax)
        selfActor:SetAttribute('VisionGuardCurrent', NewValue)
    end

    if OldValue <= 0 and NewValue > 0 then
        selfActor.ChararacteStateManager:NotifyEvent('BeginVisionGuard')
    elseif OldValue > 0 and NewValue <= 0 then
        selfActor.ChararacteStateManager:NotifyEvent('EndVisionGuard')
    end

    if FunctionUtil:FloatLittle(OldValue, VisionGuardMax) and FunctionUtil:FloatEqual(NewValue, VisionGuardMax) then
        selfActor.ChararacteStateManager:NotifyEvent('BeginVisionSelect')
    elseif FunctionUtil:FloatGreat(OldValue, 0) and FunctionUtil:FloatZero(NewValue) then
        selfActor.ChararacteStateManager:NotifyEvent('EndVisionSelect')
    end

    if FunctionUtil:FloatGreat(unclamp_change, 0) then
        if self.GE_SightDec_Handle then
            local ASC = selfActor:GetAbilitySystemComponent()
            ASC:RemoveActiveGameplayEffect(self.GE_SightDec_Handle, -1)
            self.GE_SightDec_Handle = nil
        end
        self.LastVisionAdd = UE.UHiUtilsFunctionLibrary.GetNowTimestampMs();
    end
end

function BP_PerceptionComponent_C:PostSoundChange(NewValue, OldValue)
    local SoundGuardMax = self.SoundGuardMax
    local selfActor = self:GetOwner()

    --clamp limit
    if not UE.UKismetMathLibrary.InRange_FloatFloat(NewValue, 0, SoundGuardMax, true, true) then
        NewValue = UE.UKismetMathLibrary.FClamp(NewValue, 0, SoundGuardMax)
        selfActor:SetAttribute('SoundGuardCurrent', NewValue)
    end
    
    if OldValue <= 0 and NewValue > 0 then
        selfActor.ChararacteStateManager:NotifyEvent('BeginSoundGuard')
    elseif OldValue > 0 and NewValue <= 0 then
        selfActor.ChararacteStateManager:NotifyEvent('EndSoundGuard')
    end

    if OldValue < SoundGuardMax and NewValue >= SoundGuardMax then
        selfActor.ChararacteStateManager:NotifyEvent('BeginSoundSelect')
    elseif OldValue > 0 and NewValue <= 0 then
        selfActor.ChararacteStateManager:NotifyEvent('EndSoundSelect')
    end

    if NewValue > OldValue then
        self.LastSoundAdd = UE.UHiUtilsFunctionLibrary.GetNowTimestampMs();
        if self.GE_SoundDec_Handle then
            local ASC = selfActor:GetAbilitySystemComponent()
            ASC:RemoveActiveGameplayEffect(self.GE_SoundDec_Handle, -1)
            self.GE_SoundDec_Handle = nil
        end
    end
end


return BP_PerceptionComponent_C
