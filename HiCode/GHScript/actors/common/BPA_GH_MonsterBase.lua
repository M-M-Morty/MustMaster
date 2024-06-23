--UnLua
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local Character = require("actors.common.Character")

---@type BPA_GH_MonsterBase_C
local BPA_GH_MonsterBase_C = Class(Character)

local G = require("G")
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')


function BPA_GH_MonsterBase_C:HoldObject(key, uObj, overwrite)
    local v = self.HoldedObjs:Find(key)
    if v and v:IsValid() then
        if overwrite then
            if v:IsA(UE.AActor) then
                v:K2_DestroyActor()
            end
            self.HoldedObjs:Remove(key)
            self.HoldedObjs:Add(key, uObj)
            return true, nil
        else
            return false, v
        end
    else
        self.HoldedObjs:Remove(key)
        self.HoldedObjs:Add(key, uObj)
        return true, nil
    end
end

function BPA_GH_MonsterBase_C:GetHoldObject(key)
    local v = self.HoldedObjs:Find(key)
    return (v and v:IsValid()) and v or nil
end

function BPA_GH_MonsterBase_C:GetSkillWithStandComponent()
    return nil
end

function BPA_GH_MonsterBase_C:GetASC()
    return self:GetHiAbilitySystemComponent()
end

function BPA_GH_MonsterBase_C:GetASCOwnerActor()
    return self
end

function BPA_GH_MonsterBase_C:GetAIServerComponent()
    return self.AIComp
end

function BPA_GH_MonsterBase_C:SetNpcDisplayName(DisplayName)
end

function BPA_GH_MonsterBase_C:GetNpcDisplayName()
    return ''
end

function BPA_GH_MonsterBase_C:BP_PreInitializeComponents()
    -- attributeSet init must before component init
    if self:HasAuthority() then
        self.AbilitySystemComponent:SetIsReplicated(true)
        self.AbilitySystemComponent:SetReplicationMode(UE.EGameplayEffectReplicationMode.Mixed)
        self:InitAttributeSet()
    end
end

function BPA_GH_MonsterBase_C:ReceiveBeginPlay()
    self.Overridden.ReceiveBeginPlay(self)
    Super(BPA_GH_MonsterBase_C).ReceiveBeginPlay(self)

    local ASC = self:GetAbilitySystemComponent()
    self.AttributeComponent:InitializeWithAbilitySystem(ASC)
    self.AttributeComponent:InitAttributeListener()
    self:InitWalkableSlope()    --初始化身上所有组件的InitWalkableSlope

    if self:HasAuthority() then
        self.home_location = self:K2_GetActorLocation()

        self:SendMessage("OnServerReady")
        self:InitBlackBoard()
    else
        self:RegisterGameplayTagCB('StateGH.InDeath', UE.EGameplayTagEventType.NewOrRemoved, 'DoDeath')
    end
end

function BPA_GH_MonsterBase_C:ReceiveTick(DeltaSeconds)
    self.Overridden.ReceiveTick(self, DeltaSeconds)
    --Super(BPA_GH_MonsterBase_C).ReceiveTick(self, DeltaSeconds)

    if self.ChararacteStateManager:HasTag('StateGH.Ability.Rushing') then
        self:CustomMoveToIgnoreActors()
    else
        self:CustomMoveToIgnoreActorsReset()
    end 

    if self:HasAuthority() then
        self:CustomMoveToUpdate(DeltaSeconds)
    end
end

function BPA_GH_MonsterBase_C:ReceiveEndPlay(EndPlayReason)
    self.Overridden.ReceiveEndPlay(self, EndPlayReason)
    --Super(BPA_GH_MonsterBase_C).ReceiveEndPlay(self, EndPlayReason)
end

function BPA_GH_MonsterBase_C:InitBlackBoard()
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(self:GetController())
    if BB then
        BB:SetValueAsVector('homeLocation', self.home_location)
    end
end

function BPA_GH_MonsterBase_C:GetBlackBoardActor(key)
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(self:GetController())
    if BB then
        return BB:GetValueAsObject(key)
    end
end

function BPA_GH_MonsterBase_C:GetBlackBoardExtend()
    local EXTEND_OBJ_NAME = 'extend'
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(self:GetController())
    local extendObj = BB:GetValueAsObject(EXTEND_OBJ_NAME)
    if not extendObj then
        if not self.extendObj then
            self.extendObj = UE.NewObject(FunctionUtil:IndexRes('UD_CommonBoardExtend_C'), self)
            self:HoldObject(EXTEND_OBJ_NAME, self.extendObj, true)
        end
        BB:SetValueAsObject(EXTEND_OBJ_NAME, self.extendObj)
        extendObj = self.extendObj
    end
    return extendObj
end

function BPA_GH_MonsterBase_C:AddGameplayTag(strTag)
    return FunctionUtil:AddGameplayTag(self, strTag)
end

function BPA_GH_MonsterBase_C:RemoveGameplayTag(strTag)
    return FunctionUtil:RemoveGameplayTag(self, strTag)
end

function BPA_GH_MonsterBase_C:HasGameplayTag(strTag)
    return FunctionUtil:HasGameplayTag(self, strTag)
end

function BPA_GH_MonsterBase_C:TryRunBehaviorTree(key)
    local tag = UE.UHiGASLibrary.RequestGameplayTag(key)
    local bt = self.AIComp.BTSwitch:Find(tag)
    if bt then
        self:GetController():RunBehaviorTree(bt.BehaviorTree)
    end
end

function BPA_GH_MonsterBase_C:BeginFight(sourceActor, targetActor, content)
    local moveComp = self:GetMovementComponent()
    moveComp.MaxWalkSpeed = self.MaxRunSpeed

    self:TryRunBehaviorTree('StateGH.BT.Fight')
    self:SendMessage("EnterBattle", targetActor)
end

function BPA_GH_MonsterBase_C:EndFight(sourceActor, targetActor, content)
    local moveComp = self:GetMovementComponent()
    moveComp.MaxWalkSpeed = self.MaxWalkSpeed
    self:SendMessage("LeaveBattle", targetActor)
end

function BPA_GH_MonsterBase_C:BeginBackHome()
    self.back_home_start_time = UE.UGameplayStatics.GetTimeSeconds(self)

    self:TryRunBehaviorTree('StateGH.BT.BackHome')
end

function BPA_GH_MonsterBase_C:EndBackHome()
    self.path_move_stuck = false
end

-- 注意这个函数在角色InitBT进入的时候不会被执行
function BPA_GH_MonsterBase_C:BeginPeace()
    self:TryRunBehaviorTree('StateGH.BT.Peace')

    local ASC = self:GetHiAbilitySystemComponent()
    if ASC then
        ASC:BP_ApplyGameplayEffectToSelf(self.InitGE, 0.0, nil)
    end
end

function BPA_GH_MonsterBase_C:EndPeace()
    -- body
end


function BPA_GH_MonsterBase_C:GetAttribute(attributeName)
    if not attributeName then
        return
    end

    --if a FGameplayAttributeData
    local ASC = self:GetHiAbilitySystemComponent()
    local AttributeData = ASC:FindAttributeByName(attributeName)
    if AttributeData and AttributeData.AttributeOwner then
        local AttributeSet = ASC:GetAttributeSet(AttributeData.AttributeOwner)
        return AttributeSet[attributeName], AttributeSet
    end

    --if a float? search one by one
    if self.AttributeComponent and self.AttributeComponent.AttributeSetClasses then
        local AttributeSetClasses = self.AttributeComponent.AttributeSetClasses
        for i, UCls in pairs(AttributeSetClasses) do
            local AttributeSet = ASC:GetAttributeSet(UCls)
            if AttributeSet[attributeName] then
                return AttributeSet[attributeName], AttributeSet
            end
        end
    end
end

function BPA_GH_MonsterBase_C:SetAttribute(attributeName, current, base)
    if not attributeName then
        return
    end

    local v, set = self:GetAttribute(attributeName)
    if set then
        if type(v) == 'number' then
            set[attributeName] = current
        else
            set[attributeName].CurrentValue = current
            set[attributeName].BaseValue = base or current
        end
    end
end

function BPA_GH_MonsterBase_C:GetAttributeValue(attributeName)
    local v = self:GetAttribute(attributeName)
    if not v then
        return 0, false
    elseif type(v) == 'number' then
        return v, true
    else
        return v.CurrentValue, true
    end 
end


function BPA_GH_MonsterBase_C:DoDeath()
    if self:HasAuthority() then
        self.ChararacteStateManager:ClearLookAtTarget()
        self:GetController():StopMovement()
        self:StopAnimMontage()

        local fightTarget = self:GetBlackBoardActor('FightActor')
        self:SendMessage("LeaveBattle", fightTarget)

        self.ChararacteStateManager:NotifyEvent('StopMontageGroup', 'DefaultGroup#TenacityGroup')
        local ASC = self:GetHiAbilitySystemComponent()
        if ASC then
            ASC:BP_CancelAbilities()
        end
        self:AddGameplayTag('StateGH.InDeath')
        self:TryRunBehaviorTree('StateGH.BT.Death')

        self:SetLifeSpan(self.DeathTimeSpan)
    else
        local MaxHealth = self:GetAttributeValue("MaxHealth")
        local widget = self.BP_MonsterHPWidget and self.BP_MonsterHPWidget:GetWidget()
        if widget then
            widget:SetHealth(0, MaxHealth)
        end
    end
end


function BPA_GH_MonsterBase_C:OnAttributeChanged(Attribute, NewValue, OldValue)
    --UnLua.LogWarn("OnAttributeChanged", Attribute.AttributeName, NewValue, OldValue)
    if self:HasAuthority() then
        if Attribute.AttributeName == "VisionGuardCurrent" then
            self.BP_PerceptionComponent:PostSightChange(NewValue, OldValue)
        elseif Attribute.AttributeName == "SoundGuardCurrent" then
            self.BP_PerceptionComponent:PostSoundChange(NewValue, OldValue)
        elseif Attribute.AttributeName == "Health" then
            if FunctionUtil:FloatZero(NewValue) then
                self.ChararacteStateManager:NotifyEvent('EnterDeath')
            end
        elseif Attribute.AttributeName == "Tenacity" then
            if NewValue < OldValue then
                self:TenacityDecrement(NewValue, OldValue)
            end
        end
    else
        if Attribute.AttributeName == "Health" then
            self:SendMessage('OnHealthChanged', NewValue, OldValue)
        elseif Attribute.AttributeName == "Tenacity" then
            self:SendMessage('OnTenacityChanged', NewValue, OldValue)
        end
    end
end

function BPA_GH_MonsterBase_C:TenacityDecrement(NewValue, OldValue)
    local tag
    local tenacity
    for k, v in pairs(self.TenacityPoints) do
        if OldValue > k and NewValue <= k then
            if (not tenacity) or tenacity > k then
                tenacity = k
                tag = v
            end
        end
    end
    if tag then
        self:RemoveGameplayTag('StateGH.InSkillBlock')

        local Payload = UE.FGameplayEventData()
        Payload.EventTag = tag
        Payload.Instigator = self
        UE.UAbilitySystemBlueprintLibrary.SendGameplayEventToActor(self, tag, Payload)
    end
end


function BPA_GH_MonsterBase_C:GetOverlappingActors()
    local selfCapsule = self:K2_GetRootComponent()
    local tbObjectTypes = { UE.EObjectTypeQuery.Pawn }
    local outComps = UE.TArray(UE.UCapsuleComponent)
    UE.UKismetSystemLibrary.ComponentOverlapComponents(selfCapsule, selfCapsule:K2_GetComponentToWorld(), tbObjectTypes, UE.UCapsuleComponent, nil, outComps)
    local length = outComps:Length()
    if length > 0 then
        local set = UE.TSet(UE.AActor)
        for i = 1, length do
            local actor = outComps:Get(i):GetOwner()
            set:Add(actor)
        end
        return set
    end
end


function BPA_GH_MonsterBase_C:CustomMoveToStart(Location, Duration)
    self.bCustomMoving = true
    self.custom_move_expire = UE.UGameplayStatics.GetTimeSeconds(self) + Duration
    local selfLocation = self:K2_GetActorLocation()
    self.custom_move_velocity = (Location - selfLocation) / Duration;
end

function BPA_GH_MonsterBase_C:CustomMoveToStop()
    self.bCustomMoving = false
    self.custom_move_expire = nil
    self:GetController():StopMovement()
end

function BPA_GH_MonsterBase_C:CustomMoveToUpdate(DeltaSeconds)
    if self.bCustomMoving then
        if (self.custom_move_expire or 0) < UE.UGameplayStatics.GetTimeSeconds(self) then
            return
        end
        --[[ Base of Velocity logic
        local moveComp = self:GetMovementComponent()
        if moveComp then
            moveComp.Velocity.X = self.custom_move_velocity.X
            moveComp.Velocity.Y = self.custom_move_velocity.Y
        end]]
        self:CustomMoveToMove(DeltaSeconds)
    end
end

function BPA_GH_MonsterBase_C:SetCustomMoveCollisionCB(pf)
    self.custom_move_collision_cb = pf
    self.detach_custom_move_stuck = 0
end

function DeltaDegreeInXY(v1, v2)
    local t1 = UE.FVector(v1.X, v1.Y, v1.Z)
    local t2 = UE.FVector(v2.X, v2.Y, v2.Z)
    t1:Normalize()
    t1.Z = 0
    t2:Normalize()
    t2.Z = 0
    local CosDelta = UE.UKismetMathLibrary.Dot_VectorVector(t1, t2)
    local DegreesDelta = UE.UKismetMathLibrary.DegACos(CosDelta)
    return DegreesDelta
end

function BPA_GH_MonsterBase_C:CustomMoveBreaking()
    if self.bCustomMoving then
        self.custom_move_expire = nil
    end
    if self.custom_move_collision_cb then
        self.custom_move_collision_cb()
    end
end

function BPA_GH_MonsterBase_C:CustomMoveToIgnoreActors()
    local IgnoreActors = UE.TArray(UE.AActor)
    local tbObjectTypes = { UE.EObjectTypeQuery.Pawn }
    local PawnObjClass = UE.APawn
    local ActorsToIgnore = { self }
    UE.UKismetSystemLibrary.SphereOverlapActors(self, self:K2_GetActorLocation(), 1000, tbObjectTypes, PawnObjClass, ActorsToIgnore, IgnoreActors)
    local selfMoveComp = self:GetMovementComponent()
    for i, v in pairs(IgnoreActors) do
        local tarActor = v
        if tarActor ~= self then
            selfMoveComp.UpdatedComponent:IgnoreActorWhenMoving(tarActor, true)
            local tarMoveComp = tarActor:GetMovementComponent()
            if tarMoveComp and tarMoveComp.UpdatedComponent then
                tarMoveComp.UpdatedComponent:IgnoreActorWhenMoving(self, true)
            end
        end
    end
end

function BPA_GH_MonsterBase_C:CustomMoveToIgnoreActorsReset()
    local selfMoveComp = self:GetMovementComponent()
    local arys = selfMoveComp.UpdatedComponent.MoveIgnoreActors
    local length = arys:Length()
    if length > 0 then
        local set = self:GetOverlappingActors()
        local resetActors = UE.TArray(UE.AActor)
        for i = 1, length do
            local tarActor = arys:Get(i)
            if (not set) or (not set:Contains(tarActor)) then
                resetActors:Add(tarActor)
            end
        end
        local resetLength = resetActors:Length()
        if resetLength > 0 then
            for i = 1, resetLength do
                local tarActor = resetActors:Get(i)
                local tarMoveComp = tarActor.GetMovementComponent and tarActor:GetMovementComponent()
                if tarMoveComp and tarMoveComp.UpdatedComponent then
                    tarMoveComp.UpdatedComponent:IgnoreActorWhenMoving(self, false)
                end
                selfMoveComp.UpdatedComponent:IgnoreActorWhenMoving(tarActor, false)
            end
        end
    end
end

function BPA_GH_MonsterBase_C:CustomMoveToMove(DeltaSeconds)
    local moveComp = self:GetMovementComponent()
    local updateComp = self:K2_GetRootComponent()
    local velocity = UE.FVector(self.custom_move_velocity.X, self.custom_move_velocity.Y, moveComp.Velocity.Z)
    local Delta = velocity * DeltaSeconds
    local LastMoveTimeSlice = DeltaSeconds
    local bMoved, bStepUp
    local degreeXY
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
            degreeXY = DeltaDegreeInXY(Hit.Normal, velocity)
            if moveComp:BP_CanStepUp(Hit) then
                local bComputedFloor
                local FloorResult = UE.FFindFloorResult()
				bStepUp = moveComp:BP_StepUp(UE.FVector(0, 0, -1.0), Delta * (1 - PercentTimeApplied), Hit, bComputedFloor, FloorResult)
                if not bStepUp then
                    if degreeXY > self.CustomMoveStopYawInXY then
                        move_stop = true
                    else
                        moveComp:BP_HandleImpact(Hit, LastMoveTimeSlice, RampVector)
                        moveComp:BP_SlideAlongSurface(Delta, 1 - PercentTimeApplied, Hit.Normal, Hit, true)
                    end
                end
            elseif Hit.Component and (not moveComp:BP_CanStepUp(Hit)) then
                if degreeXY > self.CustomMoveStopYawInXY then
                    move_stop = true
                else
                    moveComp:BP_HandleImpact(Hit, LastMoveTimeSlice, RampVector)
                    moveComp:BP_SlideAlongSurface(Delta, 1 - PercentTimeApplied, Hit.Normal, Hit, true)
                end
            end
        end
    end

    if move_stop then
        self:CustomMoveBreaking()
    else
        local AfterLocation = updateComp:K2_GetComponentLocation()
        local moveDist = UE.UKismetMathLibrary.Vector_Distance(BeforeLocation, AfterLocation)
        if moveDist < self.CustomMoveStopDistFactor * Delta:Size() then
            self.detach_custom_move_stuck = (self.detach_custom_move_stuck or 0) + DeltaSeconds
            if self.detach_custom_move_stuck > self.CustomMoveStopTime then
                self:CustomMoveBreaking()
            end
        else
            self.detach_custom_move_stuck = 0
        end
    end
end


function BPA_GH_MonsterBase_C:IsNeedBackToHome()
    if self.home_location and FunctionUtil:FloatNotZero(self.BackHomeDistance) then
        if UE.UKismetMathLibrary.Vector_Distance(self:K2_GetActorLocation(), self.home_location) > self.BackHomeDistance then
            return true
        end
    end
    if FunctionUtil:FloatNotZero(self.UnFightDistance) then
        local fightTarget = self:GetBlackBoardActor('FightActor')
        if fightTarget and self:GetDistanceTo(fightTarget) > self.UnFightDistance then
            return true
        end
    end
    return false
end

function BPA_GH_MonsterBase_C:IsNeedTeleportToHome()
    if self.BackHomeTime then
        if UE.UGameplayStatics.GetTimeSeconds(self) - (self.back_home_start_time or 0) > self.BackHomeTime then
            return true
        end
    end
    if self.path_move_stuck then
        return true
    end
    return false
end

function BPA_GH_MonsterBase_C:TeleportToHome()
    if self.home_location then
        self:K2_SetActorLocation(self.home_location, false, nil, true)
        return true
    else
        return false
    end
end

function BPA_GH_MonsterBase_C:IsDesignedToStandAtHome()
    return FunctionUtil:FloatZero(self.WanderHomeDistance)
end

function BPA_GH_MonsterBase_C:RandHomeWanderPos(saveKey)
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(self:GetController())
    if BB and self.WanderHomeDistance > 0 then
        local pos = UE.FVector()
        UE.UNavigationSystemV1.K2_GetRandomReachablePointInRadius(self, self.home_location, pos, self.WanderHomeDistance, nil, nil)
        BB:SetValueAsVector(saveKey, pos)
        return true
    end
end

function BPA_GH_MonsterBase_C:SetQuickFollowAction(key, elapse)
    self.skill_quick_follow = {key, UE.UGameplayStatics.GetTimeSeconds(self) + elapse}
end

function BPA_GH_MonsterBase_C:GetQuickFollowAction()
    local t = self.skill_quick_follow
    if t and UE.UGameplayStatics.GetTimeSeconds(self) < t[2] then
        local extend = self:GetBlackBoardExtend()
        if extend then
            for i, v in pairs(extend.actions) do
                local action = v
                if action.ActionKey == t[1] and FunctionUtil:CheckActionRaw(self, nil, action, {'Weight', 'CD', 'Tag', 'ExTag'}) then
                    return action
                end
            end
        end
    end
end

function BPA_GH_MonsterBase_C:IsInBeHitting()
    local TagContainer = UE.FGameplayTagContainer()
    local strTags = {--[['StateGH.Hit.BeHitBack', 'StateGH.Hit.BeHitFly', ]]'StateGH.Tenacity.zero', 'StateGH.Tenacity.a'}
    local ASC = self:GetHiAbilitySystemComponent()
    for i, v in ipairs(strTags) do
        local Tag = UE.UHiGASLibrary.RequestGameplayTag(v)
        TagContainer.GameplayTags:Add(Tag)
    end
    return ASC:HasAnyMatchingGameplayTags(TagContainer)
end

function BPA_GH_MonsterBase_C:IsSkillBlocking()
    return self:HasGameplayTag('StateGH.InSkillBlock')
end



function BPA_GH_MonsterBase_C:GetPreviewTag()
    local tag = { -- actor tag for preview animation:
    'preview_walk_in_place',   --原地走
    'preview_run_in_place',    --原地跑
    'preview_walk',            --直线走
    'preview_run',             --直线跑
    'preview_turn',            --原地转身
    'preview_mix',             --混合行为
    }
    for i, v in ipairs(tag) do
        if self:ActorHasTag(v) then
            return v
        end
    end
end

--[[
    以下内容属于动画预览调试功能应用需求相关，属于特定目的用途，正式版本可以屏蔽
]]

function BPA_GH_MonsterBase_C:ExecuteCmd(strCmd)
    G.log:warn("duzy", "%s BPA_GH_MonsterBase_C:ExecuteCmd %s", tostring(UE.UHiBlueprintFunctionLibrary.GetPIEWorldNetDescription(self)), tostring(strCmd))

    if self:AnimationPreviewCommand(strCmd) then
        return
    end
    
    local Player = UE.UGameplayStatics.GetPlayerCharacter(self, 0)
    --self.ChararacteStateManager:NotifyEvent(0, 'abc')
    --self.ChararacteStateManager:NotifyEvent('BeginFight')
    --self.ChararacteStateManager:NotifyEvent('BeginVisionSelect')

    --self.let_me_skill_block = (not self.let_me_skill_block)

    --UE.UAISense_Hearing.ReportNoiseEvent(Player, Player:K2_GetActorLocation(), 10, Player, 1000);

    if false and self:HasAuthority() then
        self.ChararacteStateManager:NotifyEvent('EnterDeath')
    end

    if false and self:HasAuthority() then
        local HitTag = UE.UHiGASLibrary.RequestGameplayTag('Event.Hit.Behavior.KnockBack.Weak')
        local Payload = UE.FGameplayEventData()
        Payload.EventTag = HitTag
        Payload.Instigator = self
        UE.UAbilitySystemBlueprintLibrary.SendGameplayEventToActor(self, HitTag, Payload)
    end

    if false and self:HasAuthority() then
        local tag = UE.UHiGASLibrary.RequestGameplayTag('StateGH.Tenacity.a')
        local Payload = UE.FGameplayEventData()
        Payload.EventTag = tag
        Payload.Instigator = self
        UE.UAbilitySystemBlueprintLibrary.SendGameplayEventToActor(self, tag, Payload)
    end

    if false and self:HasAuthority() then
        self.player_has_with_stand = (not self.player_has_with_stand)
        if self.player_has_with_stand then
            FunctionUtil:AddGameplayTag(Player, 'Ability.Skill.Defend.WithStand')
        else
            FunctionUtil:RemoveGameplayTag(Player, 'Ability.Skill.Defend.WithStand')
        end
    end

    if false and self:HasAuthority() then
        --self:SendKnockInfoToHiCharacter(nil, 'Event.Hit.KnockBack.Weak')--NO
        self:SendKnockInfoToHiCharacter(nil, 'Event.Hit.KnockBack.Light')--YES
        --self:SendKnockInfoToHiCharacter(nil, 'Event.Hit.KnockBack.Heavy')--YES
        --self:SendKnockInfoToHiCharacter(nil, 'Event.Hit.KnockBack.SuperHeavy')--NO
        --self:SendKnockInfoToHiCharacter(nil, 'Event.Hit.KnockFly')--NO
        --self:SendKnockInfoToHiCharacter(nil, 'Event.Hit.KnockFlykc')--NO
        --self:SendKnockInfoToHiCharacter(nil, 'Event.Hit.KnockFlylianji')--NO
        --self:SendKnockInfoToHiCharacter(nil, 'Event.Hit.KnockFlyzadi')--NO
        --self:SendKnockInfoToHiCharacter(nil, 'Event.Hit.KnockFlyzadilanghao')--NO
    end

    if false and self:HasAuthority() then
        local HitTag = UE.UHiGASLibrary.RequestGameplayTag('StateGH.AbilityIdentify.Snail.Turret')
        local Payload = UE.FGameplayEventData()
        local OptionalObject = UE.NewObject(FunctionUtil:IndexRes('UD_Turret_C'), self)
        OptionalObject.FireCount = 0
        Payload.EventTag = HitTag
        Payload.Instigator = self
        Payload.OptionalObject = OptionalObject
        UE.UAbilitySystemBlueprintLibrary.SendGameplayEventToActor(self, HitTag, Payload)
    end

    if false and self:HasAuthority() then
        local GACls = UE.UClass.Load('/Game/CP0032305_GH/Character/Monster/PikaSnail/Skill/Skill_04/GA_Snail_Skill_04.GA_Snail_Skill_04_C')
        FunctionUtil:TryActiveGA(self, GACls)
    end

    if false and self:HasAuthority() then
        self.ChararacteStateManager:NotifyEvent('EndFight')
    end
end

function BPA_GH_MonsterBase_C:AnimationPreviewCommand(cmd)
    local StringUtil = require('CP0032305_GH.Script.common.utils.string_utl')

    if StringUtil:StartsWith(cmd, 'AnimPreview') then -- Preview RPC相关内容
        local arys = StringUtil:Split(cmd, '#')
        if arys[2] == 'ClientRPC' then
            local token = arys[3]
            table.remove(arys, 1) --前面几个参数不要了
            table.remove(arys, 1)
            table.remove(arys, 1)
            self:ServerEXE(token, table.unpack(arys))
        elseif arys[2] == 'ServerRPC' then
            local token = arys[3]
            table.remove(arys, 1) --前面几个参数不要了
            table.remove(arys, 1)
            table.remove(arys, 1)
            self:ClientEXE(token, table.unpack(arys))
        end
        return true
    end
end

function BPA_GH_MonsterBase_C:GetPlayerExtendGH()
    local Pawn = UE.UGameplayStatics.GetPlayerCharacter(self, 0)
    if Pawn then
        return Pawn:GetComponentByClass(FunctionUtil:IndexRes('BP_PLAYER_EXTEND_GH_C'))
    end
end

function BPA_GH_MonsterBase_C:ClientRPC(token, ...)
    local comGH = self:GetPlayerExtendGH()
    if comGH and comGH.server_ActorExecute then
        local cmd = string.format('AnimPreview#ClientRPC#%s', token)
        local count = select('#', ...)
        if count > 0 then
            for i = 1, count do
                local v = select(i, ...)
                cmd = cmd .. '#' .. tostring(v)
            end
        end
        comGH:server_ActorExecute(self, cmd)
    end
end

function BPA_GH_MonsterBase_C:ServerEXE(token, ...)
    if token == 'SetMaxWalkSpeed' then
        local moveComp = self:GetMovementComponent()
        local v = select(1, ...)
        moveComp.MaxWalkSpeed = tonumber(v)
    elseif token == 'ReqMaxWalkSpeed' then
        local moveComp = self:GetMovementComponent()
        self:ServerRPC('ResMaxWalkSpeed', moveComp.MaxWalkSpeed)
    elseif token == 'serverExecuteCmd' then
        local strCmd = select(1, ...)
        self:ExecuteCmd(strCmd)
    end
end

function BPA_GH_MonsterBase_C:ServerRPC(token, ...)
    local comGH = self:GetPlayerExtendGH()
    if comGH and comGH.client_ActorExecute then
        local cmd = string.format('AnimPreview#ServerRPC#%s', token)
        local count = select('#', ...)
        if count > 0 then
            for i = 1, count do
                local v = select(i, ...)
                cmd = cmd .. '#' .. tostring(v)
            end
        end
        comGH:client_ActorExecute(self, cmd)
    end
end

function BPA_GH_MonsterBase_C:ClientEXE(token, ...)
    local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
    local UIDef = require('CP0032305_GH.Script.ui.ui_define')
    local UIPreview = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_PreviewAnimation.UIName)
    local preivewTag = self:GetPreviewTag()
    if token == 'ResMaxWalkSpeed' then
        if UIPreview and UIPreview:GetPreviewTarget() == self then
            if preivewTag == 'preview_walk' then
                UIPreview:UpdateWalkSpeed(select(1, ...))
            elseif preivewTag == 'preview_run' then
                UIPreview:UpdateRunSpeed(select(1, ...))
            end
        end
    end
end

function BPA_GH_MonsterBase_C:SendKnockInfoToHiCharacter(tarActor, KnockInfo)
    if not tarActor then
        tarActor = UE.UGameplayStatics.GetPlayerCharacter(self, 0)
    end
    if not KnockInfo then
        KnockInfo = UE.NewObject(FunctionUtil:IndexRes('UD_KnockInfo_C'), self)
    elseif type(KnockInfo) == 'string' then
        local tag = UE.UHiGASLibrary.RequestGameplayTag(KnockInfo)
        KnockInfo = UE.NewObject(FunctionUtil:IndexRes('UD_KnockInfo_C'), self)
        KnockInfo.HitTags.GameplayTags:Add(tag)
    end
    --KnockInfo.Hit = xxx fill hit info
    local HitTags = KnockInfo.HitTags.GameplayTags;
    if HitTags:Length() < 1 then --default
        HitTags:Add(UE.UHiGASLibrary.RequestGameplayTag('Event.Hit.KnockBack.Light'))
    end
  
    if UE.UAbilitySystemBlueprintLibrary.GetAbilitySystemComponent(tarActor) then
        for i, v in pairs(HitTags) do
            local HitPayload = UE.FGameplayEventData()
            HitPayload.EventTag = v
            HitPayload.Instigator = self
            HitPayload.Target = tarActor
            HitPayload.OptionalObject = KnockInfo
            tarActor:SendMessage('HandleHitEvent', HitPayload)
        end
    end
end

return BPA_GH_MonsterBase_C

