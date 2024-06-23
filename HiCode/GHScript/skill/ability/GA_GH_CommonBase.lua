--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')

---@type GA_GH_CommonBase_C
local GA_GH_CommonBase_C = Class()


function GA_GH_CommonBase_C:BP_WaitHandleDamage()
    self:WaitHandleDamage()
end

function GA_GH_CommonBase_C:BP_WaitHandleTurn()
    self:WaitHandleTurn()
end

function GA_GH_CommonBase_C:BP_InstantHandleDamage(payLoad)
    self:InstantHandleDamage(payLoad)
end

function GA_GH_CommonBase_C:BP_GetSkillTarget(radius)
    return self:GetSkillTarget(radius)
end


function GA_GH_CommonBase_C:CanSkillBeBlocked()
    return self.CanBeBlocked
end

function GA_GH_CommonBase_C:PreDamageCheck(aryActor)
    local selfActor = self:GetOwningActorFromActorInfo()
    local blockActor
    local length = aryActor:Length()
    if length > 0 and self:CanSkillBeBlocked() then
        local Tag = UE.UHiGASLibrary.RequestGameplayTag("Ability.Skill.Defend.WithStand")
        for i = 1, length do
            local actor = aryActor:Get(i)
            if FunctionUtil:IsPlayer(actor) and FunctionUtil:HasGameplayTag(actor, Tag) then
                blockActor = actor
                break
            end
        end
    end

    if blockActor then
        if self.OnSkillBlockedBy then
            self:OnSkillBlockedBy(blockActor)
        elseif FunctionUtil:IsGHCharacter(selfActor) then
            selfActor:AddGameplayTag('StateGH.InSkillBlock')
            for i, cls in pairs(selfActor.SkillBlockGE) do
                local GE_SkillBlock_Object = UE.NewObject(cls, selfActor)
                local GE_SkillBlock_SpecHandle = UE.UAbilitySystemBlueprintLibrary.MakeSpecHandle(GE_SkillBlock_Object, selfActor, (blockActor or selfActor))
                local ASC = selfActor:GetAbilitySystemComponent()
                ASC:BP_ApplyGameplayEffectSpecToSelf(GE_SkillBlock_SpecHandle)
            end
            self:K2_EndAbility(true)
        end
    end
    return ((not blockActor) and true or false)
end

function GA_GH_CommonBase_C:DamageFilter(tarActor)
    if tarActor.IsDead and tarActor:IsDead() then
        return false
    elseif FunctionUtil:HasGameplayTag(tarActor, 'Ability.Skill.Defend.WithStand') then
        return false
    end
    return true
end

function GA_GH_CommonBase_C:ProcessDamage(payLoad, targetData, effectContainer)
    local actors = UE.UAbilitySystemBlueprintLibrary.GetActorsFromTargetData(targetData, 0)
    for _, tarActor in pairs(actors) do
        if self:DamageFilter(tarActor) then
            --effects
            for _, effectCls in pairs(effectContainer.TargetGameplayEffectClasses) do
                self:ProcessGameplayEffect(tarActor, effectCls, payLoad.ContextHandle)
            end

            --knock
            self:ProcessKnockInfo(tarActor, payLoad)
        end
    end
end

function GA_GH_CommonBase_C:ProcessGameplayEffect(tarActor, effectCls, contextHandle)
    local selfActor = self:GetAvatarActorFromActorInfo()
    local ASC = selfActor:GetAbilitySystemComponent()
    local GE_SpecHandle = ASC:MakeOutgoingSpec(effectCls, 1, (contextHandle or UE.FGameplayEffectContextHandle()))
    ASC:BP_ApplyGameplayEffectSpecToTarget(GE_SpecHandle, tarActor:GetAbilitySystemComponent())
end

function GA_GH_CommonBase_C:ProcessKnockInfo(tarActor, payLoad)
    local KnockInfo, ghNotify = payLoad.OptionalObject, payLoad.OptionalObject2
    --UnLua.LogWarn('GA_GH_CommonBase_C:ProcessKnockInfo', UE.UKismetSystemLibrary.GetDisplayName(self:GetClass()), tarActor, KnockInfo)

    if not KnockInfo then
        KnockInfo = UE.NewObject(FunctionUtil:IndexRes('UD_KnockInfo_C'), self)
    end
    --KnockInfo.Hit = xxx fill hit info
    local HitTags = KnockInfo.HitTags.GameplayTags;
    if HitTags:Length() < 1 then --default
        HitTags:Add(UE.UHiGASLibrary.RequestGameplayTag('Event.Hit.KnockBack.Light'))
    end
    if UE.UKismetMathLibrary.Vector_IsNearlyZero(KnockInfo.KnockDisScale) then -- default
        KnockInfo.KnockDisScale.X = 1
        KnockInfo.KnockDisScale.Y = 1
        KnockInfo.KnockDisScale.Z = 1
    end

    local ignoreHitResult = ghNotify and ghNotify.NotifyData.ignoreHitResult
    local selfActor = self:GetOwningActorFromActorInfo()
    if (not ignoreHitResult) and FunctionUtil:IsPlayer(tarActor) and selfActor.UpdateAbilityResult then
        local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(selfActor:GetController())
        local key = BB:GetValueAsString('actionKey')
        selfActor:UpdateAbilityResult(key, true)
    end
    
    local NoneTag = UE.UHiGASLibrary.RequestGameplayTag('StateGH.None')
    local length = HitTags:Length()
    if UE.UAbilitySystemBlueprintLibrary.GetAbilitySystemComponent(tarActor) and length > 0 then
        for i = 1, length do
            local tag = HitTags:Get(i)
            if tag ~= NoneTag then
                local HitPayload = UE.FGameplayEventData()
                HitPayload.EventTag = tag
                HitPayload.Instigator = self:GetOwningActorFromActorInfo()
                HitPayload.Target = tarActor
                HitPayload.OptionalObject = KnockInfo
                tarActor:SendMessage('HandleHitEvent', HitPayload)
            end
        end
    end
end


function GA_GH_CommonBase_C:RefTask(task)
    self.Tasks:Add(task)
end

function GA_GH_CommonBase_C:RefTargetActor(ta, TaskInstanceName)
    local actor = self.ActorsMap:Find(TaskInstanceName)
    if actor then
        if actor:IsValid() then
            self.TargetActors:Add(ta)
        else
            self.ActorsMap:Remove(TaskInstanceName)
            self.ActorsMap:Add(TaskInstanceName, ta)
        end
    else
        self.ActorsMap:Add(TaskInstanceName, ta)
    end
end

function GA_GH_CommonBase_C:RemoveTargetActor(TaskInstanceName)
    local actor = self.ActorsMap:Find(TaskInstanceName)
    if actor then
        self.ActorsMap:Remove(TaskInstanceName)
        if actor:IsValid() then
            actor:K2_DestroyActor()
        end
    end
end


function GA_GH_CommonBase_C:OnEventReceived_WaitDamage(payLoad)
    self:InstantHandleDamage(payLoad)
end

function GA_GH_CommonBase_C:OnEventReceived_WaitEndTarget(payLoad)
    local ghNotify = payLoad.OptionalObject2
    local TaskInstanceName = ghNotify and ghNotify.NotifyData.nameString
    self:RemoveTargetActor(TaskInstanceName)
end

function GA_GH_CommonBase_C:WaitHandleDamage()
    local keys = self.EffectContainerMap:Keys()
    local length = keys:Length()
    if length > 0 then
        for i = 1, length do
            local eventTag = keys:Get(i)
            local waitTask = UE.UAbilityTask_WaitGameplayEvent.WaitGameplayEvent(self, eventTag, nil, false, true)
            self:RefTask(waitTask)
            waitTask.EventReceived:Add(self, self.OnEventReceived_WaitDamage)
            waitTask:ReadyForActivation()
        end
    end

    local EndTag = UE.UHiGASLibrary.RequestGameplayTag('StateGH.NotifyDamage.EndDamage')
    local waitEndTarget = UE.UAbilityTask_WaitGameplayEvent.WaitGameplayEvent(self, EndTag, nil, false, true)
    self:RefTask(waitEndTarget)
    waitEndTarget.EventReceived:Add(self, self.OnEventReceived_WaitEndTarget)
    waitEndTarget:ReadyForActivation()
end

function GA_GH_CommonBase_C:InstantHandleDamage(payLoad)
    local effectContainer = self.EffectContainerMap:Find(payLoad.EventTag)
    if effectContainer then
        self.PayLoadObj = payLoad -- should be a ary or map
        local selfActor = self:GetAvatarActorFromActorInfo()
        local targetActor = selfActor:GetWorld():SpawnActor(effectContainer.TargetType, selfActor:GetTransform(), UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, self)
        self:RefTargetActor(targetActor, effectContainer.TaskInstanceName)
        local waitTask = UE.UAbilityTask_WaitTargetData.WaitTargetDataUsingActor(self, effectContainer.TaskInstanceName, effectContainer.ConfirmationType, targetActor)
        self:RefTask(waitTask)
        --[[local waitTask = UE.UAbilityTask_WaitTargetData.WaitTargetData(self, effectContainer.TaskInstanceName, effectContainer.ConfirmationType, effectContainer.TargetType)
        local ok, ta = waitTask:BeginSpawningActor(self, effectContainer.TargetType)
        waitTask:FinishSpawningActor(self, ta)]]
        waitTask.ValidData:Add(self, self.OnValidData_InstantDamage)
        waitTask:ReadyForActivation()
    end
end

function GA_GH_CommonBase_C:OnValidData_InstantDamage(TargetDataHandle, EventTag)
    local actors = UE.UAbilitySystemBlueprintLibrary.GetActorsFromTargetData(TargetDataHandle, 0)
    if self:PreDamageCheck(actors) then
        local effectContainer = self.EffectContainerMap:Find(self.PayLoadObj.EventTag)
        self:ProcessDamage(self.PayLoadObj, TargetDataHandle, effectContainer)
    end
end


function GA_GH_CommonBase_C:K2_OnEndAbility(bWasCancelled)
    local selfActor = self:GetAvatarActorFromActorInfo()
    if selfActor.ChararacteStateManager then
        selfActor.ChararacteStateManager:RemoveStateTagDirect('StateGH.Ability.DurationTurn') --Notify配对的保证
        selfActor.ChararacteStateManager:NotifyEvent('SetAimTarget', 'cancel') --Notify重置保证
    end
    if selfActor.SetAbilityPeriod then
        selfActor:SetAbilityPeriod()
    end

    self.Tasks:Clear()
    for i, actor in pairs(self.TargetActors) do
        if actor and actor:IsValid() then
            actor:K2_DestroyActor()
        end
    end
    self.TargetActors:Clear()

    for k, actor in pairs(self.ActorsMap) do
        if actor and actor:IsValid() then
            actor:K2_DestroyActor()
        end
    end
    self.ActorsMap:Clear()
end


function GA_GH_CommonBase_C:GetSkillTarget(radius)
    local selfActor = self:GetAvatarActorFromActorInfo()
    if (not radius) or FunctionUtil:FloatZero(radius) then
        radius = self.SkillRadius
    end
    return FunctionUtil:FindNearestPlayer(selfActor, radius)
end

function GA_GH_CommonBase_C:GetAvatarLookat(selfActor, tarActor)
    local lookAt = UE.UKismetMathLibrary.FindLookAtRotation(selfActor:K2_GetActorLocation(), tarActor:K2_GetActorLocation())
    return lookAt
end

function GA_GH_CommonBase_C:TryInstantTurnToTarget()
    local selfActor = self:GetAvatarActorFromActorInfo()
    local tarActor = self:GetSkillTarget()
    if tarActor then
        local selfRotation = selfActor:K2_GetActorRotation()
        local lookAt = self:GetAvatarLookat(selfActor, tarActor)
        selfRotation.Yaw = lookAt.Yaw
        selfActor:K2_SetActorRotation(selfRotation, false)
    end
end

function GA_GH_CommonBase_C:TryDurationTurnToTarget()
    local selfActor = self:GetAvatarActorFromActorInfo()
    local tarActor = self:GetSkillTarget()
    if tarActor then
        local selfRotation = selfActor:K2_GetActorRotation()
        local lookAt = self:GetAvatarLookat(selfActor, tarActor)
        local deltaRot = UE.UKismetMathLibrary.NormalizedDeltaRotator(lookAt, selfRotation)
        if math.abs(deltaRot.Yaw) < self.deltaLimit then
            selfRotation.Yaw = lookAt.Yaw
            selfActor:K2_SetActorRotation(selfRotation, true)
        else
            local selfYaw = selfRotation.Yaw
            selfRotation.Yaw = UE.UKismetMathLibrary.ClampAngle(lookAt.Yaw, selfYaw - self.deltaLimit, selfYaw + self.deltaLimit)
            selfActor:K2_SetActorRotation(selfRotation, true)
        end
    end

    return selfActor.ChararacteStateManager:HasTag('StateGH.Ability.DurationTurn')
end


function GA_GH_CommonBase_C:OnEventReceived_InstantTurn(payLoad)
    self:TryInstantTurnToTarget()
end

function GA_GH_CommonBase_C:OnPerformAction_DurationTurn()
    if not self:TryDurationTurnToTarget() then
        if self.duration_turn_task and self.duration_turn_task:IsValid() then
            self.duration_turn_task:EndTask()
            self.duration_turn_task = nil
        end
    end
end

function GA_GH_CommonBase_C:OnEventReceived_DurationTurn(payLoad)
    local tickTask = UE.UAbilityTask_Repeat.RepeatAction(self, math.max(self.durationTurnInterval, 0.03), 999999)
    self:RefTask(tickTask)
    self.duration_turn_task = tickTask
    tickTask.OnPerformAction:Add(self, self.OnPerformAction_DurationTurn)
    tickTask:ReadyForActivation()
end

function GA_GH_CommonBase_C:WaitHandleTurn()
    local InstantTurnTag = UE.UHiGASLibrary.RequestGameplayTag('StateGH.Ability.InstantTurn')
    local waitTask = UE.UAbilityTask_WaitGameplayEvent.WaitGameplayEvent(self, InstantTurnTag, nil, false, true)
    self:RefTask(waitTask)
    waitTask.EventReceived:Add(self, self.OnEventReceived_InstantTurn)
    waitTask:ReadyForActivation()

    local DurationTurnTag = UE.UHiGASLibrary.RequestGameplayTag('StateGH.Ability.DurationTurn')
    local waitTaskDuration = UE.UAbilityTask_WaitGameplayEvent.WaitGameplayEvent(self, DurationTurnTag, nil, false, true)
    self:RefTask(waitTaskDuration)
    waitTaskDuration.EventReceived:Add(self, self.OnEventReceived_DurationTurn)
    waitTaskDuration:ReadyForActivation()
end


function GA_GH_CommonBase_C:WaitHandleWarning()
    local WarningBeginTag = UE.UHiGASLibrary.RequestGameplayTag('StateGH.Ability.WarningBegin')
    local beginTask = UE.UAbilityTask_WaitGameplayEvent.WaitGameplayEvent(self, WarningBeginTag, nil, false, true)
    self:RefTask(beginTask)
    beginTask.EventReceived:Add(self, self.OnEventReceived_WarningBegin)
    beginTask:ReadyForActivation()

    local WarningEndTag = UE.UHiGASLibrary.RequestGameplayTag('StateGH.Ability.WarningEnd')
    local endTask = UE.UAbilityTask_WaitGameplayEvent.WaitGameplayEvent(self, WarningEndTag, nil, false, true)
    self:RefTask(endTask)
    endTask.EventReceived:Add(self, self.OnEventReceived_WarningEnd)
    endTask:ReadyForActivation()
end

function GA_GH_CommonBase_C:OnEventReceived_WarningBegin(payLoad)
    local selfActor = self:GetAvatarActorFromActorInfo()
    local UD = payLoad.OptionalObject.UD
    local targetActor = selfActor:GetWorld():SpawnActor(UD.TargetActorClass, selfActor:GetTransform(), UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, self)
    self.ActorsMap:Add(UD.TaskInstanceName, targetActor)
    self:RefTargetActor(targetActor, UD.TaskInstanceName)
    local waitTask = UE.UAbilityTask_WaitTargetData.WaitTargetDataUsingActor(self, UD.TaskInstanceName, UD.ConfirmationType, targetActor)
    self:RefTask(waitTask)
    waitTask.ValidData:Add(self, self.OnValidData_Warning)
    waitTask:ReadyForActivation()
end

function GA_GH_CommonBase_C:OnValidData_Warning(TargetDataHandle, EventTag)
    local actors = UE.UAbilitySystemBlueprintLibrary.GetActorsFromTargetData(TargetDataHandle, 0)
    for k, v in pairs(actors) do
    end
end

function GA_GH_CommonBase_C:OnEventReceived_WarningEnd(payLoad)
    local UD = payLoad.OptionalObject.UD
    self:RemoveTargetActor(UD.TaskInstanceName)
end

return GA_GH_CommonBase_C

