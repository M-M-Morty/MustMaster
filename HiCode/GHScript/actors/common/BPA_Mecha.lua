--UnLua
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local BPA_GH_MonsterBase = require("CP0032305_GH.Script.actors.common.BPA_GH_MonsterBase")

---@type BPA_Mecha_C
local BPA_Mecha_C = Class(BPA_GH_MonsterBase)

local G = require("G")
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')

-- function BPA_Mecha_C:Initialize(Initializer)
-- end

-- function BPA_Mecha_C:UserConstructionScript()
-- end

function BPA_Mecha_C:ReceiveBeginPlay()
    --self.Overridden.ReceiveBeginPlay(self)
    Super(BPA_Mecha_C).ReceiveBeginPlay(self)

    self:UpdateNextIdleAnim()
    self:UpdateNextIntellectual()

    if self:HasAuthority() then
        self.tin_obj_life = self.TinLifePoint

        --self.CapsuleComponent.OnComponentHit:Add(self, self.OnCapsuleComponentHit)
    else
        self.bClientInPeace = true
    end
end

function BPA_Mecha_C:ReceiveEndPlay(EndPlayReason)
    --self.Overridden.ReceiveEndPlay(self, EndPlayReason)
    Super(BPA_Mecha_C).ReceiveEndPlay(self, EndPlayReason)

    if self:HasAuthority() then
        --self.CapsuleComponent.OnComponentHit:Remove(self, self.OnCapsuleComponentHit)
    end
end

function BPA_Mecha_C:ReceiveTick(DeltaSeconds)
    --self.Overridden.ReceiveTick(self, DeltaSeconds)
    Super(BPA_Mecha_C).ReceiveTick(self, DeltaSeconds)

    if self:HasAuthority() then
        self:TryRestoreTinObj()

        local moveComp = self:GetMovementComponent()
        if moveComp and FunctionUtil:FloatZero(moveComp.MaxWalkSpeed) then
            moveComp.MaxWalkSpeed = self.MaxWalkSpeed
        end
        local SelfRotation = self:K2_GetActorRotation()
        if FunctionUtil:FloatNotZero(SelfRotation.Pitch) or FunctionUtil:FloatNotZero(SelfRotation.Roll) then
            SelfRotation.Pitch = 0
            SelfRotation.Roll = 0
            self:K2_SetActorRotation(SelfRotation, true)
        end
    else
        self:TickDeathDissolve(DeltaSeconds)
    end
end

-- function BPA_Mecha_C:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
-- end

-- function BPA_Mecha_C:ReceiveActorBeginOverlap(OtherActor)
-- end

-- function BPA_Mecha_C:ReceiveActorEndOverlap(OtherActor)
-- end

function BPA_Mecha_C:OnCapsuleComponentHit(HitComponent, OtherActor, OtherComp, NormalImpulse, Hit)
end

function BPA_Mecha_C:DoDeath()
    Super(BPA_Mecha_C).DoDeath(self)
    
    if self:HasAuthority() then
        --油桶如果在刷新ing
        local restoreNA = self:GetHoldObject('Tin_Restore_na_obj')
        if restoreNA then
            restoreNA:K2_DestroyActor()
        end
    end
end

function BPA_Mecha_C:PikaAnimationNotify(...)
    if self.PikaBody then
        self.PikaBody:GetAnimInstance():NotifyMasterAnimation(...)
    end
    if self.PikaHand then
        self.PikaHand:GetAnimInstance():NotifyMasterAnimation(...)
    end
end

function BPA_Mecha_C:IsTimeToIdleAnim()
    return UE.UGameplayStatics.GetTimeSeconds(self) > (self.next_anim_time or math.huge)
end

function BPA_Mecha_C:UpdateNextIdleAnim()
    self.next_anim_time = UE.UGameplayStatics.GetTimeSeconds(self) + math.random(10, 20)
end

function BPA_Mecha_C:UpdateAbilityResult(id, result)
    local stamp = UE.UGameplayStatics.GetTimeSeconds(self)
    self.last_ability_result = {id, result, stamp}
end

function BPA_Mecha_C:IsTimeToIntellectual()
    --时间间隔
    local currrent = UE.UGameplayStatics.GetTimeSeconds(self)
    if (not self.last_ability_result) or currrent < (self.next_ip_time or 0) then
        return false
    end
    --特定技能+结果+血量
    local IP_ACTIONS = { {'skill_02', true, 10}, {'skill_02', false, 10}, {'skill_04', true, 10}, {'skill_04', false, 10} }
    local health = self:GetAttributeValue('Health')
    for i, v in ipairs(IP_ACTIONS) do
        local result = self.last_ability_result[2] and true or false
        if v[1] == self.last_ability_result[1] and result == v[2] and health >= v[3] then
            return true
        end
    end
    return false
end

function BPA_Mecha_C:UpdateNextIntellectual()
    self.next_ip_time = UE.UGameplayStatics.GetTimeSeconds(self) + math.random(1, 3)
end

function BPA_Mecha_C:GetLastAbilityResult()
    return self.last_ability_result
end

function BPA_Mecha_C:SetLastAbortAction(action)
    self.last_abort_action = action
    return true
end

function BPA_Mecha_C:GetLastAbortAction()
    return self.last_abort_action
end

function BPA_Mecha_C:IsRestoreMoveTo()
    local action = self:GetLastAbortAction()
    return action and action == 'BTTask_WaitMoveTo_C'
end

function BPA_Mecha_C:UpdateHudInfo()
    local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
    local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
    local HudTrackVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudTrackVM.UniqueName)
    if not self.BP_MonsterHPWidget then
        return
    end
    local widget = self.BP_MonsterHPWidget:GetWidget()
    if not widget then
        return
    end

    local stateComp = self.ChararacteStateManager
    if self.bClientInPeace then
        if stateComp:HasTag('StateGH.InFight') then
            widget:SetBattleMode(true)
            HudTrackVM:AddHurtTrackActor(self)
            self.bClientInPeace = false
        elseif stateComp:HasTag('StateGH.VisionGuard') or stateComp:HasTag('StateGH.SoundGuard') then
            widget:SetAlertMode(true)
        end
    else
        if not stateComp:HasTag('StateGH.InFight') then
            widget:SetNormalMode(true)
            HudTrackVM:RemoveHurtTrackActor(self)
            self.bClientInPeace = true
        end
    end
    -- if stateComp:HasTag('StateGH.VisionSearch') or stateComp:HasTag('StateGH.SoundSearch') then
end

function BPA_Mecha_C:SetAbilityPeriod(period)
    if not period then
        self:RemoveGameplayTag({'StateGH.Ability.Period.start', 'StateGH.Ability.Period.middle', 'StateGH.Ability.Period.end'})
    elseif period == 'start' then
        self:RemoveGameplayTag({'StateGH.Ability.Period.middle', 'StateGH.Ability.Period.end'})
        self:AddGameplayTag('StateGH.Ability.Period.start')
    elseif period == 'middle' then
        self:RemoveGameplayTag({'StateGH.Ability.Period.start', 'StateGH.Ability.Period.end'})
        self:AddGameplayTag('StateGH.Ability.Period.middle')
    elseif period == 'end' then
        self:RemoveGameplayTag({'StateGH.Ability.Period.start', 'StateGH.Ability.Period.middle'})
        self:AddGameplayTag('StateGH.Ability.Period.end')
    end
end

function BPA_Mecha_C:HandleDamageSpecial(hitResult)
    if (not self.TinCollision) or (self.TinCollision ~= hitResult.Component) or self.tin_obj_remove_time then
        return
    end
    self.tin_obj_life = self.tin_obj_life - 1
    if self.tin_obj_life < 1 and self:TryRemoveTinObj() then
        --bomb
        hitResult.ImpactPoint = hitResult.Location
        local GE_Object = UE.NewObject(self.SkillBlockGE:Get(1), self)
        local GE_SpecHandle = UE.UAbilitySystemBlueprintLibrary.MakeSpecHandle(GE_Object, self, self)
        local ContextHandle = UE.UAbilitySystemBlueprintLibrary.GetEffectContext(GE_SpecHandle)
        UE.UAbilitySystemBlueprintLibrary.EffectContextAddHitResult(ContextHandle, hitResult, true)
        
        local tag = UE.UHiGASLibrary.RequestGameplayTag('StateGH.Personal.TinBomb')
        local Payload = UE.FGameplayEventData()
        Payload.EventTag = tag
        Payload.Instigator = self
        Payload.ContextHandle = ContextHandle
        UE.UAbilitySystemBlueprintLibrary.SendGameplayEventToActor(self, tag, Payload)
    end
end

function BPA_Mecha_C:TryRemoveTinObj()
    if self.tin_obj_remove_time then
        return false
    end
    self.TinObj:SetVisibility(false, false)
    self.tin_obj_remove_time = UE.UGameplayStatics.GetTimeSeconds(self)
    self.ChararacteStateManager:AddStateTagDirect('StateGH.Personal.InTinRemove')
    if self.BP_MonsterHPWidget then
        self.BP_MonsterHPWidget.MonsterHpOffset = self.TinHeightOffset
    end
    return true
end

function BPA_Mecha_C:TryRestoreTinObj()
    if (not self.tin_obj_remove_time) or self:HasGameplayTag('StateGH.InDeath') then
        return false
    end

    local current = UE.UGameplayStatics.GetTimeSeconds(self)
    --特效
    local LIFE_TIME_OF_NA = 2
    if self.tin_obj_remove_time + self.TinCoolDown - LIFE_TIME_OF_NA < current then
        local restoreNA = self:GetHoldObject('Tin_Restore_na_obj')
        if not restoreNA then
            local tinNA = self:GetWorld():SpawnActor(FunctionUtil:IndexRes('NA_Tin_Restore_C'), self.TinObj:K2_GetComponentToWorld(), UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, self)
            tinNA:K2_AttachToComponent(self.TinObj, '', UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.KeepWorld)
            tinNA:K2_SetActorRelativeLocation(UE.FVector(60, 0, 0), false, nil, true)
            tinNA:K2_SetActorRelativeRotation(UE.FRotator(90, 0, 0), false, nil, true)
            tinNA:SetLifeSpan(5)
            self:HoldObject('Tin_Restore_na_obj', tinNA, true)
        end
    end

    --刷新
    if (self.tin_obj_remove_time + self.TinCoolDown) < current then
        self.TinObj:SetVisibility(true, false)
        self.tin_obj_life = self.TinLifePoint
        self.tin_obj_remove_time = nil
        self.ChararacteStateManager:RemoveStateTagDirect('StateGH.Personal.InTinRemove')
        if self.BP_MonsterHPWidget then
            self.BP_MonsterHPWidget.MonsterHpOffset = 0
        end
        return true
    end
end

function BPA_Mecha_C:DeathDissolve()
    self.Overridden.DeathDissolve(self) --resource processd

    -- 播放死亡溶解效果时关闭镜头遮挡变更材质的功能
    if self.BP_CameraOcclusionOpacityComponent_BatchTool then
        self.BP_CameraOcclusionOpacityComponent_BatchTool.bIsEffectAllowed = false
    end
    
    local DEATH_DISSOLVE_TIME = 3
    self.death_dissolve_time = math.max(DEATH_DISSOLVE_TIME, 0.0001)
    self.death_dissolve_tick = 0
end

function BPA_Mecha_C:DissolvePrimitiveMaterialElement(Primitive, ElementIndex, ParamName, Value)
    if not Primitive then
        return
    end
    local MatInst = Primitive:CreateDynamicMaterialInstance(ElementIndex)
    if MatInst then
        MatInst:SetScalarParameterValue(ParamName, Value)
    end
end

function BPA_Mecha_C:TickDeathDissolve(DeltaSeconds)
    if not self.death_dissolve_tick or self.death_dissolve_tick > self.death_dissolve_time then
        return
    end
    self.death_dissolve_tick = self.death_dissolve_tick + DeltaSeconds
    if self.death_dissolve_tick < self.death_dissolve_time then
        local x = self.death_dissolve_tick / self.death_dissolve_time
        local curveObj = FunctionUtil:GlobalUObject('DissolveFadeCurve')
        local DissolveFadeValue = curveObj:GetFloatValue(x)
        self:DissolvePrimitiveMaterialElement(self.Mesh, 1, 'DissolveFade', DissolveFadeValue)
        self:DissolvePrimitiveMaterialElement(self.TinObj, 0, 'DissolveFade', DissolveFadeValue)
        self:DissolvePrimitiveMaterialElement(self.TinObj, 1, 'DissolveFade', DissolveFadeValue)
        self:DissolvePrimitiveMaterialElement(self.PikaBody, 0, 'DissolveFade', DissolveFadeValue)
        self:DissolvePrimitiveMaterialElement(self.PikaBody, 1, 'DissolveFade', DissolveFadeValue)
        self:DissolvePrimitiveMaterialElement(self.PikaBody, 2, 'Fade', DissolveFadeValue)
        self:DissolvePrimitiveMaterialElement(self.PikaBody, 3, 'DissolveFade', DissolveFadeValue)
        self:DissolvePrimitiveMaterialElement(self.PikaBody, 4, 'DissolveFade', DissolveFadeValue)
        self:DissolvePrimitiveMaterialElement(self.PikaBody, 5, 'Fade', DissolveFadeValue)
        self:DissolvePrimitiveMaterialElement(self.PikaHand, 0, 'DissolveFade', DissolveFadeValue)
        self:DissolvePrimitiveMaterialElement(self.PikaHand, 1, 'DissolveFade', DissolveFadeValue)
        self:DissolvePrimitiveMaterialElement(self.PikaHand, 2, 'Fade', DissolveFadeValue)
        self:DissolvePrimitiveMaterialElement(self.PikaHand, 3, 'DissolveFade', DissolveFadeValue)
        self:DissolvePrimitiveMaterialElement(self.PikaHand, 4, 'DissolveFade', DissolveFadeValue)
        self:DissolvePrimitiveMaterialElement(self.PikaHand, 5, 'Fade', DissolveFadeValue)
    else
        self:K2_DestroyActor()
    end
end



return BPA_Mecha_C
