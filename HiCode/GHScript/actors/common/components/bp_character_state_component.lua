--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@type BP_CharacterStateComponent_C
local BP_CharacterStateComponent_C = Class()

local G = require("G")
local ACTORDEF = require('CP0032305_GH.Script.actors.common.actor_define')
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local StringUtil = require('CP0032305_GH.Script.common.utils.string_utl')

-- function BP_CharacterStateComponent_C:Initialize(Initializer)
-- end

function BP_CharacterStateComponent_C:ReceiveBeginPlay()
end

-- function BP_CharacterStateComponent_C:ReceiveEndPlay()
-- end

-- function BP_CharacterStateComponent_C:ReceiveTick(DeltaSeconds)
-- end

function BP_CharacterStateComponent_C:eventEnumObject()
    if self.eventEnumObj then
        return self.eventEnumObj
    else
        local objPath = UE.UKismetSystemLibrary.BreakSoftObjectPath(self.eventEnumPath)
        self.eventEnumObj = UE.UObject.Load(objPath)
        return self.eventEnumObj
    end
end
function BP_CharacterStateComponent_C:stateEnumObject()
    if self.stateEnumObj then
        return self.stateEnumObj
    else
        local objPath = UE.UKismetSystemLibrary.BreakSoftObjectPath(self.stateEnumPath)
        self.stateEnumObj = UE.UObject.Load(objPath)
        return self.stateEnumObj
    end
end

-- event = Enum_StateEvent
-- state = Enum_StateMain
-- vTags = GameplayTagContainer
function BP_CharacterStateComponent_C:NotifyEvent(event, ...)
    local eventEnum = self:eventEnumObject()
    local stateEnum = self:stateEnumObject()
    local selfActor = self:GetOwner()
    if type(event) == 'string' then
        event = eventEnum[event]
    end

    --G.log:warn('duzy', '%s NotifyEvent %s', tostring(UE.UHiBlueprintFunctionLibrary.GetPIEWorldNetDescription(self:GetOwner())), eventEnum:GetDisplayNameTextByValue(event))

    if event == eventEnum.EnterCommon then
        self.eStateMain = stateEnum.Common
    elseif event == eventEnum.EnterDeath then
        self.eStateMain = stateEnum.Dead
        if not selfActor:GetPreviewTag() then
            selfActor:DoDeath()
        end
    elseif event == eventEnum.BeHitting then
        local CasterActor = select(1, ...)
        local KnockInfo = select(2, ...)
        if selfActor:HasAuthority() then
            UE.UAISense_Damage.ReportDamageEvent(CasterActor, selfActor, CasterActor, 1, UE.FVector(), UE.FVector())
            if selfActor.HandleDamageSpecial and KnockInfo and KnockInfo.Hit then
                selfActor:HandleDamageSpecial(KnockInfo.Hit)
            end
        end
    elseif event == eventEnum.EnterAct then
        local t = selfActor:GetLastAbilityResult()
        self.lastAbilityResult = (t and t[2]) and true or false
        self:AddStateTagDirect('StateGH.IpAnimation')
        selfActor:UpdateNextIntellectual()
        self.eStateMain = stateEnum.Act
    elseif event == eventEnum.LeaveAct then
        if self.eStateMain == stateEnum.Act then
            self.eStateMain = stateEnum.Common
        end
        self:RemoveStateTagDirect('StateGH.IpAnimation')
    elseif event == eventEnum.BeginFight then
        if not selfActor:GetPreviewTag() then
            self:AddStateTagDirect("StateGH.InFight")
            if selfActor.EndPeace then
                selfActor:EndPeace()
            end
            if selfActor.BeginFight then
                selfActor:BeginFight(...)
            end
        end
    elseif event == eventEnum.EndFight then
        if not selfActor:GetPreviewTag() then
            self:RemoveStateTagDirect("StateGH.InFight")
            if selfActor.EndFight then
                selfActor:EndFight(...)
            end
            if selfActor.BeginBackHome then
                selfActor:BeginBackHome()
            elseif selfActor.BeginPeace then
                selfActor:BeginPeace()
            end
        end
    elseif event == eventEnum.EndBackHome then
        if not selfActor:GetPreviewTag() then
            if selfActor.EndBackHome then
                selfActor:EndBackHome()
            end
            if selfActor.BeginPeace then
                selfActor:BeginPeace()
            end
        end
    elseif event == eventEnum.BeginVisionGuard then
        self:AddStateTagDirect("StateGH.VisionGuard")
    elseif event == eventEnum.EndVisionGuard then
        self:RemoveStateTagDirect("StateGH.VisionGuard")
    elseif event == eventEnum.BeginVisionSelect then
        self:AddStateTagDirect("StateGH.VisionSearch")
    elseif event == eventEnum.EndVisionSelect then
        self:RemoveStateTagDirect("StateGH.VisionSearch")
    elseif event == eventEnum.BeginSoundSelect then
        self:AddStateTagDirect("StateGH.SoundSearch")
    elseif event == eventEnum.EndSoundSelect then
        self:RemoveStateTagDirect("StateGH.SoundSearch")
    elseif event == eventEnum.BeginSoundGuard then
        self:AddStateTagDirect("StateGH.SoundGuard")
    elseif event == eventEnum.EndSoundGuard then
        self:RemoveStateTagDirect("StateGH.SoundGuard")
    elseif event == eventEnum.TurnInPlaceStart then
        self.turnDeltaYaw = select(1, ...)
        self.turnAnimPlayRate = select(2, ...)
        self:AddStateTagDirect("StateGH.TurnInPlace")
    elseif event == eventEnum.TurnInPlaceEnd then
        self:RemoveStateTagDirect("StateGH.TurnInPlace")
    elseif event == eventEnum.WaitMoveTo then
        self:AddStateTagDirect("StateGH.WaitMoveTo")
    elseif event == eventEnum.NotifyMoveTo then
        self:AddStateTagDirect("StateGH.NotifyMoveTo")
    elseif event == eventEnum.AbilityRushingStart then
        self:AddStateTagDirect("StateGH.Ability.Rushing")
        selfActor.CapsuleComponent:SetCollisionProfileName(ACTORDEF.Global_Cfg.rush_collision_profile_name, true)
    elseif event == eventEnum.AbilityRushingStop then
        self:RemoveStateTagDirect("StateGH.Ability.Rushing")
        selfActor.CapsuleComponent:SetCollisionProfileName(ACTORDEF.Global_Cfg.default_collision_profile_name, true)
    elseif event == eventEnum.AbilityDurationTurn then
        local content = select(1, ...)
        if content == 'start' then
            self:AddStateTagDirect("StateGH.Ability.DurationTurn")
            local tag = UE.UHiGASLibrary.RequestGameplayTag("StateGH.Ability.DurationTurn")
            UE.UAbilitySystemBlueprintLibrary.SendGameplayEventToActor(selfActor, tag, nil)
        else
            self:RemoveStateTagDirect("StateGH.Ability.DurationTurn")
        end
    elseif event == eventEnum.TagAddAction then
        local strTag = select(1, ...)
        self:AddStateTagDirect(strTag)
    elseif event == eventEnum.TagRemoveAction then
        local strTag = select(1, ...)
        self:RemoveStateTagDirect(strTag)
    elseif event == eventEnum.PlayMontage then
        self.montage = select(1, ...)
        selfActor:PlayAnimMontage(self.montage, 1.0)
    elseif event == eventEnum.StopMontage then
        selfActor:StopAnimMontage(self.montage)
        self.montage = nil
    elseif event == eventEnum.StopMontageGroup then
        self.stopMontageGroup = select(1, ...)
        local tGroupNames = StringUtil:Split(self.stopMontageGroup, '#')
        for i, strGroup in ipairs(tGroupNames) do
            selfActor.Mesh:GetAnimInstance():Montage_StopGroupByName(0, strGroup)
        end
    elseif event == eventEnum.AbilityPeriod then
        local period = select(1, ...)
        selfActor:SetAbilityPeriod(period)
    elseif event == eventEnum.ApplyGameplayEffect then
        if selfActor:HasAuthority() then
            local ge_obj = select(1, ...)
            local clsPath = FunctionUtil:GetBlueprintObjectClassPath(ge_obj)
            local uCls = UE.UClass.Load(clsPath)
            local ASC = selfActor:GetAbilitySystemComponent()
            local GE_SpecHandle = ASC:MakeOutgoingSpec(uCls, 1, UE.FGameplayEffectContextHandle())
            ASC:BP_ApplyGameplayEffectSpecToSelf(GE_SpecHandle)
        end
    elseif event == eventEnum.PikaAnimNotify then
        if selfActor.PikaAnimationNotify then
            selfActor:PikaAnimationNotify(...)
        end
    elseif event == eventEnum.SetAimTarget then
        local flag = select(1, ...)
        if flag == 'set' then
            self.aimTarget = FunctionUtil:FindNearestPlayer(selfActor, selfActor.SearchPlayerDistance)
            selfActor.Mesh.VisibilityBasedAnimTickOption = UE.EVisibilityBasedAnimTickOption.AlwaysTickPoseAndRefreshBones
        else --cancel
            self.aimTarget = nil
            selfActor.Mesh.VisibilityBasedAnimTickOption = UE.EVisibilityBasedAnimTickOption.AlwaysTickPose
        end
    elseif event == eventEnum.DeathStageDetail then
        if not selfActor:HasAuthority() then
            selfActor:DeathDissolve()
        end
    end
end
function BP_CharacterStateComponent_C:NotifyEventString(event, str)
    self:NotifyEvent(event, str)
end
function BP_CharacterStateComponent_C:NotifyEventStringAry(event, vArgs)
    self:NotifyEvent(event, table.unpack(vArgs:ToTable()))
end
function BP_CharacterStateComponent_C:NotifyEventUObject(event, uobject, optionalObj)
    self:NotifyEvent(event, uobject, optionalObj)
end


function BP_CharacterStateComponent_C:OnRep_vTags()
    local selfActor = self:GetOwner()
    local collision = selfActor.CapsuleComponent:GetCollisionProfileName()
    local inRushing = self:HasTag('StateGH.Ability.Rushing')
    if inRushing then
        if collision ~= ACTORDEF.Global_Cfg.rush_collision_profile_name then
            selfActor.CapsuleComponent:SetCollisionProfileName(ACTORDEF.Global_Cfg.rush_collision_profile_name, true)
        end
    else
        if collision == ACTORDEF.Global_Cfg.rush_collision_profile_name then
            selfActor.CapsuleComponent:SetCollisionProfileName(ACTORDEF.Global_Cfg.default_collision_profile_name, true)
        end
    end

    if selfActor.UpdateHudInfo then
        selfActor:UpdateHudInfo()
    end
end
function BP_CharacterStateComponent_C:OnRep_montage()
    if self.montage then
        self.PlayingMontage = self.montage
        self:GetOwner():PlayAnimMontage(self.montage, 1.0)
    else
        self:GetOwner():StopAnimMontage(self.PlayingMontage)
    end
end
function BP_CharacterStateComponent_C:OnRep_stopMontageGroup()
    local tGroupNames = StringUtil:Split(self.stopMontageGroup, '#')
    for i, strGroup in ipairs(tGroupNames) do
        self:GetOwner().Mesh:GetAnimInstance():Montage_StopGroupByName(0, strGroup)
    end
end

function BP_CharacterStateComponent_C:AddStateTagsDirect(tags)
    UE.UBlueprintGameplayTagLibrary.AppendGameplayTagContainers(self.vTags, tags)
end
function BP_CharacterStateComponent_C:RemoveStateTagsDirect(tags)
    local arys = UE.TArray(UE.FGameplayTag)
    UE.UBlueprintGameplayTagLibrary.BreakGameplayTagContainer(tags, arys)
    for i, v in pairs(arys) do
        UE.UBlueprintGameplayTagLibrary.RemoveGameplayTag(self.vTags, v)
    end
end
function BP_CharacterStateComponent_C:AddStateTagDirect(strTag)
    local tag = UE.UHiGASLibrary.RequestGameplayTag(strTag)
    UE.UBlueprintGameplayTagLibrary.AddGameplayTag(self.vTags, tag)
end
function BP_CharacterStateComponent_C:RemoveStateTagDirect(strTag)
    local tag = UE.UHiGASLibrary.RequestGameplayTag(strTag)
    UE.UBlueprintGameplayTagLibrary.RemoveGameplayTag(self.vTags, tag)
end
function BP_CharacterStateComponent_C:HasTag(tag)
    if type(tag) == 'string' then
        tag = UE.UHiGASLibrary.RequestGameplayTag(tag)
    end
    return UE.UBlueprintGameplayTagLibrary.HasTag(self.vTags, tag, true)
end

return BP_CharacterStateComponent_C
