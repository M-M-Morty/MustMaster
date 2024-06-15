local G = require("G")

local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local SkillDriver = require("skill.SkillDriver")
local SkillUtils = require("common.skill_utils")
local WeaponData = require("common.data.weapon_data").data
local SkillData = require("common.data.skill_list_data").data
local InputModes = require("common.event_const").InputModes
local StateConflictData = require("common.data.state_conflict_data")
local equip_const = require("common.const.equip_const")
local MoveDirConst = require("common.event_const").MoveDir
local CustomMovementModes = require("common.event_const").CustomMovementModes
local utils = require("common.utils")
local EdUtils = require("common.utils.ed_utils")
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local ConstTextTable = require("common.data.const_text_data").data


local SkillComponent = Component(ComponentBase)
local decorator = SkillComponent.decorator

local ChangeDirMillis = 100

function SkillComponent:InitGameAbilitySystem()
    local AbilitySystem = self.actor:GetASC()
    local OwnerActor = self.actor:GetASCOwnerActor()
    self:InitializeAbilitySystem(AbilitySystem, OwnerActor)
    AbilitySystem:BP_RefreshAbilityActorInfo()
    self.AbilitySystemComponent = AbilitySystem

    -- Init attribute component
    self.actor.AttributeComponent:InitializeWithAbilitySystem(AbilitySystem)


    -- Init Skill input modifier map
    self.SkillInputModifiers = {}

    -- Assist Anim MontageCache init
    self.AssistMontageCache:Clear()

    if self.actor:IsServer() then
        -- 只在服务器监听属性变化，客户端会通过 multicast 事件广播下来.
        self.actor.AttributeComponent:InitAttributeListener()
        self:InitGameAbilitySystemOnServer(AbilitySystem, OwnerActor)
    end

    -- Init GE listener
    self:InitGEListener()
    AbilitySystem.OnGameplayEffectRemoved:Add(self, self.OnGameplayEffectRemovedCallback)
    AbilitySystem.OnGameplayEffectTagCountChanged:Add(self, self.OnGameplayEffectTagCountChangedCallback)
end


function SkillComponent:InitTeamAbilitySystemAvatarInfo()
    if not self.actor or not self.actor.PlayerState then
        return
    end
    -- local AbilitySystem = self.actor.PlayerState:GetHiAbilitySystemComponent() 
    -- AbilitySystem:InitAbilityActorInfo(self.actor.PlayerState, self.actor)
end

function SkillComponent:InitGEListener()
    local AbilityAsync = UE.UAbilityAsync_WaitGameplayEffectApplied.WaitGameplayEffectAppliedToActor(self.actor, UE.FGameplayTargetDataFilterHandle(), UE.FGameplayTagRequirements(), UE.FGameplayTagRequirements())
    AbilityAsync.OnApplied = {self, self.OnApplyGE}
    AbilityAsync:Activate()
    self.AbilityAsyncRefList:Add(AbilityAsync)

    return self.AbilityAsyncRefList:Length()
end

function SkillComponent:InitGameAbilitySystemOnServer(AbilitySystem, OwnerActor)
    self:SendServerMessage("OnGameAbilitySystemReady")
end

function SkillComponent:ReceiveBeginPlay()
    Super(SkillComponent).ReceiveBeginPlay(self)
    self.__TAG__ = string.format("SkillComponent(actor: %s, server: %s)", G.GetObjectName(self.actor), self.actor:IsServer())

    if self.actor:IsClient() then
        local BPConst = require("common.const.blueprint_const")
        local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
        if self.actor.PlayerState then
            local ItemCnt = self.actor.EdRuntimeComponent:AddAreaAbilityItem(BPConst.AreaAbilityItemLightID, 0)
            local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
            local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)
            G.log:debug(self.__TAG__, "ReceiveBeginPlay %s %s %s", BPConst.AreaAbilityItemLightID, ItemCnt, ItemCnt<=0)
            if AreaAbilityVM.SetAreaAbilityUsing then
                AreaAbilityVM:SetHasAreaAbility(ItemCnt>0)
                AreaAbilityVM:SetAreaAbilityUsing(ItemCnt <= 0)
                AreaAbilityVM:SetAreaCopyerUsable(ItemCnt<=0)
            end
        end
    end
end

decorator.message_receiver()
function SkillComponent:OnReceiveTick(DeltaSeconds)
    -- Detect OnLand as system OnLand event only trigger in specified mode.

    if self.actor:IsClient() then
        self:OnReceiveTick_Client(DeltaSeconds)
    end
end

function SkillComponent:Stop()
    Super(SkillComponent).Stop(self)

    if self.actor:IsClient() and self.actor:IsPlayer() then
        self:SendMessage("UnRegisterInputHandler", InputModes.Skill)
    end
end

function SkillComponent:OnApplyGE(Source, SpecHandle, ActiveHandle)
    if not self.actor then
        return
    end

    G.log:debug(self.__TAG__, "On apply ge: %s", UE.UAbilitySystemBlueprintLibrary.GetActiveGameplayEffectDebugString(ActiveHandle))
end

function SkillComponent:OnGameplayEffectRemovedCallback(Effect)
    G.log:debug(self.__TAG__, "On remove ge: %s", G.GetObjectName(Effect.Spec.Def))
end

function SkillComponent:OnGameplayEffectTagCountChangedCallback(Tag, NewCount)
    --G.log:debug(self.__TAG__, "On gameplay tag changed: %s, NewCount: %d", GetTagName(Tag), NewCount)

    self:SendMessage("OnTagCountChanged", Tag, NewCount)

    -- TODO Maybe for performance, optimize only listen tag in explict tag list.
    -- Check trigger buff ability, notify UI CD here.
    if NewCount > 0 then
        local AbilitySpecs = self.AbilitySystemComponent.ActivatableAbilities.Items
        for Ind = 1, AbilitySpecs:Length() do
            local Spec = AbilitySpecs:Get(Ind)
            local GA, bInstanced = G.GetGameplayAbilityFromSpecHandle(self.AbilitySystemComponent, Spec.Handle)
            if bInstanced and UE.UKismetSystemLibrary.IsValid(GA) and GA.CanTriggerBuffAbility then
                local bTrigger, SkillID, BuffTag = GA:CanTriggerBuffAbility(Tag)
                if bTrigger then
                    G.log:debug(self.__TAG__, "Can trigger buff ability of SkillID: %d, Tag: %s", SkillID, GetTagName(BuffTag))

                    -- Notify ui to refresh cd and icon.
                    local _, Duration = GA:GetTriggerBuffAbilityRemainingAndDuration(Tag)
                    self:SendMessage("TriggerBuffAbility", SkillID, Duration)
                end
            end
        end
    end
end


decorator.message_receiver()
function SkillComponent:OnBuffAdded(Tag)
    -- Notify GA instance for those need listen to buff change.
    local AbilitySpecs = self.AbilitySystemComponent.ActivatableAbilities.Items
    for Ind = 1, AbilitySpecs:Length() do
        local Spec = AbilitySpecs:Get(Ind)
        local GA, bInstanced = G.GetGameplayAbilityFromSpecHandle(self.AbilitySystemComponent, Spec.Handle)
        if bInstanced and UE.UKismetSystemLibrary.IsValid(GA) and GA.OnBuffAdded then
            GA:OnBuffAdded(Tag)
        end
    end
end

decorator.message_receiver()
function SkillComponent:OnBuffRemoved(Tag)
    -- Notify GA instance for those need listen to buff change.
    local AbilitySpecs = self.AbilitySystemComponent.ActivatableAbilities.Items
    for Ind = 1, AbilitySpecs:Length() do
        local Spec = AbilitySpecs:Get(Ind)
        local GA, bInstanced = G.GetGameplayAbilityFromSpecHandle(self.AbilitySystemComponent, Spec.Handle)
        if bInstanced and UE.UKismetSystemLibrary.IsValid(GA) and GA.OnBuffRemoved then
            GA:OnBuffRemoved(Tag)
        end
    end
end

decorator.message_receiver()
function SkillComponent:HandleKnockTargets(TargetActors, KnockInfo)
    local KInfo = SkillUtils.KnockInfoObjectToStruct(KnockInfo)
    self:SendMessage("OnKnockTargets", TargetActors, KInfo)
end

decorator.message_receiver()
function SkillComponent:HandleDamage(Damage, HitResult, Instigator, DamageCauser, DamageAbility, DamageGESpec)
    self:Multicast_HandleDamage(Damage, HitResult, Instigator, DamageCauser, DamageAbility, DamageGESpec)
end

function SkillComponent:Multicast_HandleDamage_RPC(Damage, HitResult, Instigator, DamageCauser, DamageAbility, DamageGESpec)
    self:SendMessage("OnDamaged", Damage, HitResult, Instigator, DamageCauser, DamageAbility, DamageGESpec)

    local Causer = DamageCauser or Instigator
    Causer:SendMessage("OnDamageOther", Damage, self.actor)
end

function SkillComponent:FindAbilitySpecFromSkillID(SkillID)
    return SkillUtils.FindAbilitySpecFromSkillID(self.AbilitySystemComponent, SkillID)
end

function SkillComponent:FindAbilitySpecHandleFromSkillID(SkillID)
    local Spec = self:FindAbilitySpecFromSkillID(SkillID)
    if Spec then
        return Spec.Handle
    end
end

function SkillComponent:FindAbilityFromSkillID(SkillID)
    local Spec = self:FindAbilitySpecFromSkillID(SkillID)
    if Spec then
        return Spec.Ability
    end
    return nil
end

function SkillComponent:FindUserDataFromSkillID(SkillID)
    local Spec = self:FindAbilitySpecFromSkillID(SkillID)
    if not Spec then
        return nil
    end

    return Spec.UserData
end

-- Get GA montage, only support one montage.
function SkillComponent:FindMontageFromSkillID(SkillID)
    local Spec = self:FindAbilitySpecFromSkillID(SkillID)
    if Spec then
        if Spec.Ability.MontageToPlay then
            return Spec.Ability.MontageToPlay
        end

        if Spec.UserData then
            return Spec.UserData.Anim
        end
    end
end

-- Set skill target into userdata, this will used by TargetActor.
-- TODO Attention: This record ability instance dynamic data into ability CDO !
decorator.message_receiver()
function SkillComponent:SetSkillTarget(SkillID, SkillTarget, SkillTargetTransform, bValidTransform, SkillTargetComponent, SkillClass, bReplicated)
    local UserData
    if SkillID ~= 0 then
        UserData = self:FindUserDataFromSkillID(SkillID)
    elseif UE.UKismetSystemLibrary.IsValidClass(SkillClass) then
        local ASC = G.GetHiAbilitySystemComponent(self.actor)
        local AbilitySpecHandle = ASC:FindAbilitySpecHandleFromClass(SkillClass)
        if AbilitySpecHandle.Handle ~= -1 then
            local AbilitySpec = SkillUtils.FindAbilitySpecFromHandle(ASC, AbilitySpecHandle)
            if AbilitySpec then
                UserData = AbilitySpec.UserData
            end
        end
    end

    if UserData then
        UserData.SkillTarget = SkillTarget
        UserData.SkillTargetTransform = SkillTargetTransform
        UserData.SkillTargetComponent = SkillTargetComponent
    end

    if self.actor:IsPlayerNotStandalone() and bReplicated then
        self:Server_SetSkillTarget(SkillID, SkillTarget, SkillTargetTransform, bValidTransform, SkillTargetComponent, SkillClass)
    end
end

decorator.message_receiver()
function SkillComponent:SetSkillOffsetTime(SkillID, StartOffsetTime)
    G.log:debug(self.__TAG__, "SetSkillUserData SkillID: %d, IsServer: %s", SkillID, self.actor:IsServer())
    local UserData = self:FindUserDataFromSkillID(SkillID)
    if UserData then
        UserData.StartOffsetTime = StartOffsetTime
    end

    if self.actor:IsPlayerNotStandalone() then
        self:Server_SetSkillOffsetTime(SkillID, StartOffsetTime)
    end
end

function SkillComponent:OnImmunityBlockGameplayEffect(BlockedSpec, ImmunityGE)
    self:Multicast_OnImmunityBlockGameplayEffect(BlockedSpec, ImmunityGE)
end

function SkillComponent:Multicast_OnImmunityBlockGameplayEffect_RPC(BlockedSpec, ImmunityGE)
    G.log:debug(self.__TAG__, "OnImmunityBlockGameplayEffect")

    --local TimeDilationActor = HiBlueprintFunctionLibrary.GetTimeDilationActor(self.actor)
    --if TimeDilationActor then
    --    TimeDilationActor:StartWitchTimeEx(0.1, 1000)
    --end

    local ContextHandle = UE.UHiGASLibrary.GetGameplayEffectContextHandle(BlockedSpec)
    local GECauser = UE.UAbilitySystemBlueprintLibrary.EffectContextGetEffectCauser(ContextHandle)
    GECauser:SendMessage("HandleBeImmunityBlockGameplayEffect", self.actor, ImmunityGE)
end

decorator.message_receiver()
function SkillComponent:UpdateCustomMovement(DeltaSeconds)
    local CustomMode = self.actor.CharacterMovement.CustomMovementMode
    if CustomMode == CustomMovementModes.Skill then
        self.actor.CharacterMovement:PhysSkill(DeltaSeconds)
    end
end

decorator.message_receiver()
function SkillComponent:OnLand()
    if self.OnLandCallbackList then
        for _, Item in ipairs(self.OnLandCallbackList) do
            local Owner, Callback, Params = table.unpack(Item)
            Callback(Owner, Params)
        end
    end
end

function SkillComponent:RegisterOnLandCallback(Owner, Func, ...)
    if not self.OnLandCallbackList then
        self.OnLandCallbackList = {}
    end

    table.insert(self.OnLandCallbackList, {Owner, Func, ...})
end

function SkillComponent:Server_EnableSkillCost_RPC(SkillID, bEnableCost)
    self:Multicast_EnableSkillCost(SkillID, bEnableCost)
end

function SkillComponent:Multicast_EnableSkillCost_RPC(SkillID, bEnableCost)
    self:EnableSkillCost(SkillID, bEnableCost, false)
end

function SkillComponent:EnableSkillCost(SkillID, bEnableCost, bReplicated)
    local GA, _ = SkillUtils.FindAbilityInstanceFromSkillID(self.actor.AbilitySystemComponent, SkillID)
    if GA then
        GA:EnableCost(bEnableCost)
    end

    if bReplicated then
        self:Server_EnableSkillCost(SkillID, bEnableCost)
    end
end

--[[
    --------------------------------------------------
    Only run on client
    --------------------------------------------------
    ]]
function SkillComponent:InitSkillClient()
    G.log:debug("LogTemp", "Init skill client.")

    -- Cache ActivatableAbilities in local client, only use to diff abilities change.
    self.AbilitiesCache = {}
    self.ForwardInputValue = 0
    self.RightInputValue = 0
end

-- When server ability list changed, rep to client
decorator.message_receiver()
function SkillComponent:ClientOnRep_ActivateAbilities()
    if self.AbilityCallbacks then
        for _, Item in ipairs(self.AbilityCallbacks) do
            local Owner, Callback, Params = table.unpack(Item)
            Callback(Owner, Params)
        end

        self.AbilityCallbacks = {}
    end

    -- 多角色中，除当前角色外，不初始化 SkillDriver. 当角色成为当前角色(Player) 后会进行初始化.
    if not self.SkillDriver or not self.actor:IsPlayer() then
        return
    end

    -- Init player skills and combo.
    local ActivatableAbilities = self.AbilitySystemComponent.ActivatableAbilities.Items
    local NewAbilities = {}
    local Count = ActivatableAbilities:Length()
    for ind = 1, Count do
        local Spec = ActivatableAbilities:Get(ind)
        local UserData = Spec.UserData
        local AbilityCDO = Spec.Ability
        if UserData and not AbilityCDO.bKnock then
            -- SkillID config in DataTable not in GA blueprint, so must as a dynamic userdata.
            local SkillID = UserData.SkillID
            local SkillType = AbilityCDO.SkillType
            if SkillID ~= 0 and not self.AbilitiesCache[SkillID] then
                G.log:debug(self.__TAG__, "New activated skill id: %d, type: %s, GA: %s", SkillID, SkillType, G.GetObjectName(AbilityCDO))
                self.SkillDriver:OnRepNewSkill(SkillID, SkillType)
            end
            NewAbilities[SkillID] = true
        end
    end
    self.AbilitiesCache = NewAbilities

    if self.actor.PlayerState then
        --初始化助战技能
        --self.SkillDriver:InitAssistSkill(self.actor.PlayerState.BP_AssistTeamComponent.AssistSkillID)

        -- 通知 Controller 客户端技能初始化完成
        self.bSkillInited = true
        G.log:info(self.__TAG__, "AssistTeamComponent:LearnSkill %s", self.actor.PlayerState ~= nil)
        local PlayerController = self.actor.PlayerState:GetPlayerController()
        PlayerController:SendMessage("OnClientPlayerSkillInited")
    end
end

decorator.message_receiver()
function SkillComponent:RegisterAbilityCallback(Owner, Callback, ...)
    if not self.AbilityCallbacks then
        self.AbilityCallbacks = {}
    end

    table.insert(self.AbilityCallbacks, {Owner, Callback, ...})
end


decorator.message_receiver()
function SkillComponent:InitAssistSkills()
    --self.SkillDriver:InitAssistSkill(self.actor.PlayerState.BP_AssistTeamComponent.AssistSkillID)
    if self.actor.PlayerState and self.actor.PlayerState.BP_AssistTeamComponent.AssistSkillID ~= 0 then
        self.SkillDriver:InitAssistSkill(self.actor.PlayerState.BP_AssistTeamComponent.AssistSkillID)
    end
end

decorator.message_receiver()
function SkillComponent:OnClientAvatarReady()
    self:__OnClientReady()
end

decorator.message_receiver()
function SkillComponent:OnClientMonsterReady()
    self:__OnClientReady()
end

function SkillComponent:__OnClientReady()
    if self.bClientInited then
        return
    end
    self.bClientInited = true
    G.log:debug(self.__TAG__, "OnClientAvatarReady init skill component")

    self:InitGameAbilitySystem()

    self.HiddenHudContext = nil
end

-- client Player ready, 做 player 相关的初始化
decorator.message_receiver()
function SkillComponent:OnClientReady()
    -- 怪物和玩家公用的 SkillComponent，这里做下区分
    if not self.actor:IsPlayer() then
        return
    end

    G.log:debug(self.__TAG__, "OnClientReady player ready")
    self:InitSkillClient()
    self.SkillDriver = SkillDriver.new(self)
    self:SendMessage("RegisterInputHandler", InputModes.Skill, self)
    self:SendMessage("OnPostSkillInitialized")
    --self:InitTeamAbilitySystemAvatarInfo()

    -- 手动触发一次 SkillDriver 中 ability 的初始化
    self:ClientOnRep_ActivateAbilities()
end

decorator.message_receiver()
function SkillComponent:OnRecieveMessageAfterSwitchOut()
    if self.actor:IsPlayer() and self.SkillDriver then
        self.SkillDriver:MarkSwitchOut()
    end
end

decorator.message_receiver()
function SkillComponent:AfterSwitchIn(OldPlayer, NewPlayer, ExtraInfo)
    --G.log:info("yb", "init player state is nil %s, is server %s switch", self.actor.PlayerState ~= nil, self.actor:IsServer())
    if self.actor:IsPlayer() and self.SkillDriver then
        --self:InitTeamAbilitySystemAvatarInfo()
        local PS = self.actor.PlayerState
        if PS and PS.BP_AssistTeamComponent then
            local AssistTeam = PS.BP_AssistTeamComponent
            self:Server_LearnAssistSkill()
        else
            G.log:error(self.__TAG__ , "init Assist SkillIndex failed, reason: get Controller failed")
        end
    end
end

function SkillComponent:OnReceiveTick_Client(DeltaSeconds)
end

decorator.message_receiver()
decorator.require_check_action(StateConflictData.Action_Skill)
function SkillComponent:Rush()
    if not self.SkillDriver then
        return
    end

    self.SkillDriver:Rush()
end

function SkillComponent:Attack(InPressed)
    -- 防止 Combo Key 重复调用
    self.bComboKeyExecuted = false

    self:ComboKey(InPressed)

    if not self.bComboKeyExecuted then
        self:ComboKeyWithoutState(InPressed)
    end
end

decorator.require_check_action(StateConflictData.Action_SkillNormal)
function SkillComponent:ComboKey(InPressed)
    if not self.SkillDriver then
        return
    end

    self.bComboKeyExecuted = true
    if InPressed then
        local bAirBattle = self.actor:IsAirBattle()
        local NormalSkillID, ReplaceSkillID = SkillUtils.FindNormalSkillID(self.actor:GetWorld(), bAirBattle)
        if ReplaceSkillID then
            self.SkillDriver:StartSkill(NormalSkillID)
            return
        end
        if self:TryTriggerBuffAbility(NormalSkillID) then
            return
        end
        self.bKeyDown = true
        self.SkillDriver:ComboKeyDown()
    else
        if not self.bKeyDown then
            return
        end
        self.bKeyDown = false

        self.SkillDriver:ComboKeyUp()
    end
end

decorator.message_receiver()
function SkillComponent:JumpAction(InJump)
end

function SkillComponent:TryTriggerBuffAbility(SkillID, Action)
    local ASC = G.GetHiAbilitySystemComponent(self.actor)
    local SpecHandle = self:FindAbilitySpecHandleFromSkillID(SkillID)
    local GA, bInstanced = G.GetGameplayAbilityFromSpecHandle(ASC, SpecHandle)
    if not bInstanced or not UE.UKismetSystemLibrary.IsValid(GA) then
        return false
    end
    local bTriggerBuffAbility, BuffSkillID, BuffTag = GA:CanTriggerBuffAbility()
    if bTriggerBuffAbility then
        G.log:debug(self.__TAG__, "Trigger skillID: %s, buff ability: %s, buff tag: %s", SkillID, BuffSkillID, GetTagName(BuffTag))

        local StateController = self.actor:_GetComponent("StateController", false)
        if Action ~= nil and StateController and not StateController:ExecuteAction(Action) then
            return false
        end
        -- remove buff tag after trigger.
         local Tags = UE.FGameplayTagContainer()
         Tags.GameplayTags:Add(BuffTag)

        -- remove tag, in case no ge but has tag (switch player .etc.)
        UE.UAbilitySystemBlueprintLibrary.RemoveLooseGameplayTags(self.actor, Tags, true)
        if not self:CanActivateSkill(BuffSkillID) then
            G.log:debug(self.__TAG__, "Trigger skillID: %s, buff ability: %s,  CannotActive", SkillID, BuffSkillID)
            return false
        end

        ASC:RemoveActiveEffectsWithTags(Tags)
        self:Server_RemoveActiveEffectsWithTags(Tags)
        self.SkillDriver:StartSkill(BuffSkillID)
        return true
    end

    return false
end

function SkillComponent:Server_RemoveActiveEffectsWithTags_RPC(Tags)
    local ASC = self.actor:GetHiAbilitySystemComponent()
    ASC:RemoveActiveEffectsWithTags(Tags)
end

-- Sometimes we need ComboKey up event no matter what state.
-- for example when skill normal enabled rush pre skill, just in State_Rush, charge ga should receive combo key up event ignore this state.
function SkillComponent:ComboKeyWithoutState(InPressed)
    if InPressed then

    else
        if self.SkillDriver then
            self.SkillDriver:ComboKeyUpWithoutState()
        end
    end
end

decorator.message_receiver()
function SkillComponent:CancelActionSkill(reason)
    --G.log:info("lizhao", "SkillComponent:CancelActionSkill")
end

decorator.message_receiver()
function SkillComponent:BreakSkill(reason)
    if self.SkillDriver then
        G.log:info(self.__TAG__, "On BreakSkill reason: %s", utils.ActionToStr(reason))

        self:SendMessage("OnBreakSKill", reason)
        
        self.SkillDriver:StopCurrentSkill()

        -- Invalidate next KeyUp event
        self.bKeyDown = false
    end
end

decorator.message_receiver()
function SkillComponent:BreakSkillTail(reason)
    if self.SkillDriver then
        G.log:info(self.__TAG__, "On BreakSkillTail reason: %s", utils.ActionToStr(reason))

        self:SendMessage("OnBreakSKill", reason)
        
        -- Stop current montage, in case movement input not working.
        self.actor:StopAnimMontage()

        -- Stop current skill if has.
        self.SkillDriver:StopCurrentSkill()
    end
end

decorator.message_receiver()
function SkillComponent:OnEndAbility(SkillID, SkillType)
    if SkillID and SkillType then
        G.log:debug(self.__TAG__, "OnEndAbility, SkillID: %d, SkillType: %s %s.%s", SkillID, SkillType, self.actor:GetDisplayName(), self.actor)

        if self.SkillDriver then
            self.SkillDriver:OnEndAbility(SkillID, SkillType)
        end
        if self.SkillDriver and self.SkillDriver.CurManager and self.SkillDriver.CurManager.CurNode then
            local CurrNode = self.SkillDriver.CurManager.CurNode
            for _, Transition in pairs(CurrNode.Transitions) do
                local Suc = Transition:Jump(CurrNode.StoryBoard)
                if Suc and Transition.From.SkillID == SkillID then
                    self:SendMessage("AttachWeapon", equip_const.StanceType_Fight)
                    -- next Have ComboNode, not switch to normal weapon
                    G.log:debug(self.__TAG__, "OnEndAbility (Server:%s), SkillID: %d, -> SkillID: %d", self.actor:IsServer(), SkillID, Suc.SkillID)
                    return
                end
            end
        end
        G.log:debug(self.__TAG__, "OnEndAbility (Server:%s), SkillID: %d, -> Normal", self.actor:IsServer(), SkillID)
        --self:SendMessage("AttachWeapon", equip_const.StanceType_Normal)
        self:SendMessage("OnEndSKill", SkillID)
    end   
end

function SkillComponent:SetHudVisibility(bVisible)
    if self.actor:IsClient() then
    end
    if not bVisible then


    else
        if self.HiddenHudContext then
            UIManager:ResetHiddenLayerContext(self.HiddenLayerContext)
            self.HiddenHudContext = nil
        end
    end
end

--[[
    按键绑定触发对应的技能 ID, 按键可触发的类型在 weapon_data 中配置.
 ]]

decorator.message_receiver()
function SkillComponent:StartSkill(SkillID)
    if self.SkillDriver then
        self.SkillDriver:StartSkill(SkillID)
    end
end

decorator.message_receiver()
function SkillComponent:Block(bPressed)
    if not self.SkillDriver then
        return
    end

    local BlockSkillID = SkillUtils.FindBlockSkillIDOfCurrentPlayer(self.actor:GetWorld())
    if not BlockSkillID then
        return
    end

    local ASC = G.GetHiAbilitySystemComponent(self.actor)
    local SpecHandle = self:FindAbilitySpecHandleFromSkillID(BlockSkillID)
    local GA, bInstanced = G.GetGameplayAbilityFromSpecHandle(ASC, SpecHandle)
    if bInstanced and GA.SkillType == Enum.Enum_SkillType.Block then
        -- TODO should move to GA internal implement, not here.
        if bPressed then
            if self.actor.CanUseStrikeBack then
                self.SkillDriver:StrikeBack()
            else
                if not self:CanActivateSkill(BlockSkillID) then
                    return
                end

                self:RealBlock(bPressed)
            end
        end
    else
        if not self:CanActivateSkill(BlockSkillID) then
            return
        end

        self:_BlockSkill(bPressed, BlockSkillID)
    end
end

-- First check skill can activate, then response to key input.
-- TODO all skill need check this, before check action !
function SkillComponent:CanActivateSkill(SkillID)
    return SkillUtils.CanActivateSkill(self.actor, SkillID)
end

decorator.require_check_action(StateConflictData.Action_Skill)
function SkillComponent:RealBlock(InBlockState)
    if InBlockState then
        if self.SkillDriver then
            self.SkillDriver:Block()
        end
    end
end

decorator.require_check_action(StateConflictData.Action_Skill)
function SkillComponent:_BlockSkill(bPressed, SkillID)
    if bPressed then
        self.SkillDriver:StartSkill(SkillID)
    end
end

decorator.message_receiver()
function SkillComponent:SecondarySkill(bPressed)
    if not self.SkillDriver then
        return
    end

    local SecondarySkillID = SkillUtils.FindSecondarySkillIDOfCurrentPlayer(self.actor:GetWorld())
    if not SecondarySkillID then
        return
    end
    
    G.log:info(self.__TAG__, "SecondarySkill CheckStart")

    if self:TryTriggerBuffAbility(SecondarySkillID, StateConflictData.Action_Skill) then
        G.log:info(self.__TAG__, "SecondarySkill BuffAbilityTriggerd")
        return
    end

    if not self:CanActivateSkill(SecondarySkillID) then
        G.log:info(self.__TAG__, "SecondarySkill Cannot Activate %d", SecondarySkillID)
        return
    end

    G.log:info(self.__TAG__, "SecondarySkill  Activate ")
    self:_SecondarySkill(SecondarySkillID)
end

decorator.message_receiver()
decorator.require_check_action(StateConflictData.Action_Skill)
function SkillComponent:ChargeAction()
    local SkillID = SkillUtils.FindChargeSkillIDOfCurrentPlayer(self.actor:GetWorld(), not self.actor:IsOnFloor())
    self.SkillDriver:StartSkill(SkillID)
end

function SkillComponent:GetAssistAnim(EAnimType)
    local Montage = self.AssistMontageCache:Find(EAnimType)
    if Montage then
        return Montage
    end
    local AnimSoftPath = self.AssistSkillAimPathMap:Find(EAnimType)
    if not AnimSoftPath then
        return
    end 
    local Path = UE.UKismetSystemLibrary.BreakSoftObjectPath(AnimSoftPath)
    Montage = UE.UObject.Load(Path)
    self.AssistMontageCache:Add(EAnimType, Montage)
    G.log:info(self.__TAG__, "SkillComponent:GetAssistAnim %s:%s", EAnimType, G.GetObjectName(Montage))
    return Montage
end

decorator.require_check_action(StateConflictData.Action_Skill)
function SkillComponent:_SecondarySkill(SkillID)
    self.SkillDriver:StartSkill(SkillID)
end

decorator.message_receiver()
function SkillComponent:UseSuperSkill()
    local SkillID = SkillUtils.FindSuperSkillIDOfCurrentPlayer(self.actor:GetWorld())
    if not self:CanActivateSkill(SkillID) then
        return
    end

    self:_SuperSkill(SkillID)
end

decorator.message_receiver()
function SkillComponent:SuperSkill()
    local SkillID = SkillUtils.FindSuperSkillIDOfCurrentPlayer(self.actor:GetWorld())
    if not self:CanActivateSkill(SkillID) then
        return
    end

    self:_SuperSkill(SkillID)
end

decorator.require_check_action(StateConflictData.Action_SuperSkill)
function SkillComponent:_SuperSkill(SkillID)
    if self.SkillDriver then
        self.SkillDriver:SuperSkill()
    end
end

decorator.message_receiver()
function SkillComponent:AssistSkill()
    if not self.SkillDriver then
        return
    end
    if self:CanActivateSkill(SkillUtils.FindAssistSkillID(self.actor)) then
        self:_AssistSkill()
    end
end

decorator.require_check_action(StateConflictData.Action_Skill)
function SkillComponent:_AssistSkill()
    self.SkillDriver:AssistSkill()
end

--暴露给道具系统，检查是否可以释放怪谈技能
function SkillComponent:CheckAssistSkill()
    if not self.SkillDriver then
        return false
    end

    if not self:CanActivateSkill(SkillUtils.FindAssistSkillID(self.actor)) then
        return false
    end
    local StateController = self.actor:_GetComponent("StateController", false)
    if StateController then
        if not StateController:CheckAction(StateConflictData.Action_Skill) then
            return false
        end
    end
    return true
end

-- function SkillComponent:Client_InitAssistSkill_RPC()
--     G.log:info(self.__TAG__, "SkillComponent:Client_InitAssistSkill_RPC %s", self.actor.PlayerState.BP_AssistTeamComponent.AssistSkillID)
--     if self.actor.PlayerState and self.actor.PlayerState.BP_AssistTeamComponent.AssistSkillID ~= 0 then
--         self.SkillDriver:InitAssistSkill(self.actor.PlayerState.BP_AssistTeamComponent.AssistSkillID)
--     end
-- end

function SkillComponent:Notify_ComboCheckStart()
    if self.SkillDriver then
        self.SkillDriver:ComboCheckStart_Notify()
    end
end

function SkillComponent:Notify_ComboCheckEnd()
    if self.SkillDriver then
        self.SkillDriver:ComboCheckEnd_Notify()
    end
end

function SkillComponent:Notify_ComboPeriodStart()
    if self.SkillDriver then
        self.SkillDriver:ComboPeriodStart_Notify()
    end
end

function SkillComponent:Notify_ComboPeriodEnd()
    if self.SkillDriver then
        self.SkillDriver:ComboPeriodEnd_Notify()
    end
end

decorator.message_receiver()
function SkillComponent:OnComboTail()
    if self.SkillDriver then
        self.SkillDriver:OnComboTail()
    end
end

-- 失衡动画播放到指定帧后，才进入可处决状态
function SkillComponent:Notify_OutBalance()
    self:SendMessage("NotifyOutBalance")
end

function SkillComponent:MoveForward(value)
    if not self.SkillDriver then
        return
    end

    self.ForwardInputValue = value

    if value > 0 then
        self.LastPressedDir = MoveDirConst.Forward
    else
        self.LastPressedDir = MoveDirConst.Backward
    end
    self.LastPressedDirTime = UE.UKismetMathLibrary.Now()
end

function SkillComponent:MoveRight(value)
    if not self.SkillDriver then
        return
    end

    self.RightInputValue = value

    if value > 0 then
        self.LastPressedDir = MoveDirConst.Right
    else
        self.LastPressedDir = MoveDirConst.Left
    end
    self.LastPressedDirTime = UE.UKismetMathLibrary.Now()
end

function SkillComponent:GetControlVector()
    local control_rotation = self.actor:GetControlRotation()
    local AimRotator = UE.FRotator(0, control_rotation.Yaw, 0)
    local DirectionVector = UE.FVector(0, 0, 0)

    if self.ForwardInputValue ~= 0 then
        DirectionVector = DirectionVector + AimRotator:GetForwardVector() * self.ForwardInputValue
    end

    if self.RightInputValue ~= 0 then
        DirectionVector = DirectionVector + AimRotator:GetRightVector() * self.RightInputValue
    end

    return DirectionVector
end

function SkillComponent:GetInputVector()
    return UE.FVector(self.ForwardInputValue, self.RightInputValue, 0)
end

-- Check whether direction key pressed in last valid time.
function SkillComponent:IsDirPressed()
    if not self.LastPressedDirTime then
        return false
    end

    local TimeSpan = UE.UKismetMathLibrary.Subtract_DateTimeDateTime(UE.UKismetMathLibrary.Now(), self.LastPressedDirTime)
    local DeltaMillis = UE.UKismetMathLibrary.GetTotalMilliseconds(TimeSpan)
    if DeltaMillis > ChangeDirMillis then
        return false
    end

    return true
end

decorator.message_receiver()
function SkillComponent:OnEndZeroGravity()
    if self.SkillDriver then
        -- When falling stop montage in skill (ensure skill should be in combo tail state now), And let locomotion to control.
        self.SkillDriver:StopSkillTail()
    end
end

decorator.message_receiver()
function SkillComponent:OnBeginInKnock()
    if self.SkillDriver then
        G.log:debug(self.__TAG__, "Avatar OnBeginInKnock")
        self.SkillDriver:OnBeginInKnock()
    end
end

decorator.message_receiver()
function SkillComponent:OnEndInKnock()
    if self.SkillDriver then
        G.log:debug(self.__TAG__, "Avatar OnEndInKnock")
        self.SkillDriver:OnEndInKnock()
    end
end

function SkillComponent:Client_SetSkillTarget_RPC(SkillID, SkillTarget, SkillTargetTransform, bValidTransform, SkillTargetComponent, SkillClass)
    self:SetSkillTarget(SkillID, SkillTarget, SkillTargetTransform, bValidTransform, SkillTargetComponent, SkillClass, false)
end

decorator.message_receiver()
function SkillComponent:OnBeginJudge()
    if not self.actor:IsPlayer() then
        return
    end

    G.log:debug(self.__TAG__, "Player: %s OnBeginJudge", self.actor:GetDisplayName())
    self.actor.SkillComponent.bJudgeState = true
    self:SendMessage("ExecuteAction", StateConflictData.Action_Judge)
end

decorator.message_receiver()
function SkillComponent:OnEndJudge()
    G.log:debug(self.__TAG__, "Player: %s OnEndJudge", self.actor:GetDisplayName())
    self.bJudgeState = false
    self:SendMessage("EndState", StateConflictData.State_Judge)
end

decorator.message_receiver()
function SkillComponent:OnDead()
    if self.SkillDriver then
        G.log:debug(self.__TAG__, "OnDead stop current skill")
        self.SkillDriver:StopCurrentSkill()
    end
end

--[[
    ---------------------------------------------------
    Only run on server
    --------------------------------------------------
    ]]
decorator.message_receiver()
function SkillComponent:OnServerAvatarReady()
    self:__OnServerReady()
end

decorator.message_receiver()
function SkillComponent:OnServerMonsterReady()
    self:__OnServerReady()
end

function SkillComponent:__OnServerReady()
    if self.bServerInited then
        return
    end
    self.bServerInited = true
    G.log:debug(self.__TAG__, "OnServerAvatarReady init skill component")

    self:InitGameAbilitySystem()
    self:InitCharacterAttrs()
    self:InitPassiveAbilities()
    self:LearnSkills()
end

function SkillComponent:LearnSkills()
    G.log:info(self.__TAG__, "LearnSkills")

    -- Init skill by weapon.
    if self.actor.CharType then
        G.log:info(self.__TAG__, "Learn skills for CharType: %d", self.actor.CharType)
        -- Read hero weapon id
        local CharData = self.actor:GetCharData()
        if not CharData then
            G.log:error(self.__TAG__, "Init skill error, CharType: %d not found in hero datatable", self.actor.CharType)
            return
        end

        local WeaponID = CharData["weapon_id"]
        if not WeaponID then
            G.log:warn(self.__TAG__, "Init skill error, CharType: %d no weapon")
            return
        end

        G.log:debug(self.__TAG__, "Learn skills of WeaponID: %d", WeaponID)

        G.log:info("yb", "learn skill!")
        self:LearnSkillsOfWeapon(WeaponID)
        --self:LearnAssistSkill()

        -- Standalone mode must manual invoke ClientOnRep_ActivateAbilities to init combo.
        if self.actor:IsStandalone() then
            self:SendClientMessage("ClientOnRep_ActivateAbilities")
        end

        self:SendMessage("LearnAbility")

        return
    end
end

-- input skill remap begin
decorator.message_receiver()
function SkillComponent:AddSkillInputModifier(InputKey, SkillID, GameplayTag)
    G.log:info(self.__TAG__, "AddSkillInputModifier %s %s", InputKey, SkillID)
    self.SkillInputModifiers[InputKey] = SkillID
    local ASC = G.GetHiAbilitySystemComponent(self.actor)
    if ASC:HasGameplayTag(GameplayTag) and self.actor.BuffComponent then
        local _, Duration = self.actor.BuffComponent:GetBuffRemainingAndDuration(GameplayTag)
        self:SendMessage("TriggerBuffAbility", SkillID, Duration)
    end
end

decorator.message_receiver()
function SkillComponent:RemoveSkillInputModifier(InputKey, SkillID, GameplayTag)
    G.log:info(self.__TAG__, "RemoveSkillInputModifier %s %s", InputKey, SkillID)
    if self.SkillInputModifiers[InputKey] == SkillID then
        self.SkillInputModifiers[InputKey] = nil
    end 
end

-- input skill remap end

-- Lean skills when installed weapon.
function SkillComponent:LearnSkillsOfWeapon(WeaponID)
    -- Normal attack
    local WeaponInfo = WeaponData[WeaponID]
    if not WeaponInfo then
        G.log:error(self.__TAG__, "Learn skills of weapon id: %d not found in weapon datatable.", WeaponID)
        return
    end

    self.ExistSkills = {}
    for k, v in pairs(WeaponInfo) do
        if k ~= "name" and k ~= "install_id" and k ~= "back_up_skill_ids" then
            self:LearnSkill(v)
        end
        if k == "back_up_skill_ids" then
            for _, SkillID in pairs(v) do
                self:LearnSkill(SkillID)
            end
        end
    end
end


decorator.message_receiver()
function SkillComponent:ForgetSkill(PreSkillID)
    local GASpe = self:FindAbilitySpecFromSkillID(PreSkillID)
    local AbilityCDO = GASpe.Ability
    G.log:info(self.__TAG__, "SkillComponent:ForgetSkill %s %s %s", PreSkillID, self.SkillDriver == nil, G.GetObjectName(self.actor))
    if AbilityCDO then
        local SkillType = AbilityCDO.SkillType
        self.SkillDriver:OnRepRemoveSkill(PreSkillID, SkillType)
    end
end

-- 初始化角色的助战技能列表，助战技能配置列表应该从玩家存盘属性上获取
-- 只在服务端跑
decorator.message_receiver()
function SkillComponent:LearnAssistSkill()
    G.log:info(self.__TAG__, "SkillComponent:LearnAssistSkill %s %s", self.actor.PlayerState ~= nil, G.GetObjectName(self.actor))
    if not self.actor:IsServer() then
        return
    end

    if not self.actor.PlayerState then
        return
    end

    if self.actor.PlayerState and self.actor.PlayerState.BP_AssistTeamComponent.AssistSkillID ~= 0 then
        G.log:info(self.__TAG__, "SkillComponent:LearnAssistSkill %s %s", self.actor.PlayerState.BP_AssistTeamComponent.AssistSkillID, G.GetObjectName(self.actor))
        self:LearnSkill(self.actor.PlayerState.BP_AssistTeamComponent.AssistSkillID)
        
        --self:Client_InitAssistSkill()
    end

end

--check skill unlock level
function SkillComponent:CheckSkillUnlockLevel(SkillID)
    local SkillInfo = SkillData[SkillID]
    if not SkillInfo then
        G.log:warn(self.__TAG__, "Check skill unlock level id: %d not found in skill datatable", SkillID)
        return false
    end 
    
    --TODO
    --检查技能解锁等级
    
    return true
end

function SkillComponent:GetPlayerStatReliable()
    if self.actor.PlayerState then
        return self.actor.PlayerState
    else
        if not self.actor.CacheController then
            return nil
        end
        return self.actor.CacheController.PlayerState
    end
    
    return nil
end

-- Lean skill with specified skillID
function SkillComponent:LearnSkill(SkillID)
    if self.ExistSkills[SkillID] then
        return
    end

    local SkillInfo = SkillData[SkillID]
    if not SkillInfo then
        G.log:warn(self.__TAG__, "Learn skill id: %d not found in skill datatable", SkillID)
        return
    end

    local PlayerStatReliable = self:GetPlayerStatReliable()
    if not PlayerStatReliable then
        G.log:warn(self.__TAG__, "PlayerStat is nil")
        return
    end
    
    --Check Skill Unlock level
    if not self:CheckSkillUnlockLevel(SkillID) then
        G.log:log(self.__TAG__, "Skill %d unlock level not enough", SkillID)
        
        if(self.actor.CharType) then
            PlayerStatReliable:AddPendingUnlockSkill(self.actor.CharType, SkillID)
        end
        
        return
    end

    self.ExistSkills[SkillID] = 1

    self:GiveAbilityWithUserData(SkillInfo["skill_path"], SkillID)

    -- Recursive check combo skill
    local ComboSkillIDs = SkillInfo["combo_skill_id"]
    if ComboSkillIDs then
        for _, NextSkillID in ipairs(ComboSkillIDs) do
            self:LearnSkill(NextSkillID)
        end
    end
    
    --Record learned skill
    if(self.actor.CharType) then
        PlayerStatReliable:ReceiveCharacterLearnSkill(self.actor.CharType, SkillID)
    end
end

-- Set skill level
function SkillComponent:SetSkillLevel(SkillID, NewLevel)
    if not self.ExistSkills[SkillID] then
        G.log:warn(self.__TAG__, "Set skill level id: %d not found in ExistSkills", SkillID)
        return
    end

    if not SkillData[SkillID] then
        G.log:warn(self.__TAG__, "Set skill level id: %d not found in skill datatable", SkillID)
        return
    end

    local SkillInfo = SkillData[SkillID]
    local GAClassPath = SkillInfo["skill_path"]
    local GAClass = UE.UClass.Load(GAClassPath)
    if not GAClass then
        G.log:error(self.__TAG__, "GA class Load Failed : %s", GAClassPath)
        return
    end
    
    self.SetAbilityLevel(GAClass, NewLevel)    
end

function SkillComponent:GiveAbilityWithUserData(GAClassPath, SkillID)
    local GAClass = UE.UClass.Load(GAClassPath)
    local UserData = utils.MakeUserData()

    -- TODO SkillID defined in datatable not GA blueprint. So as a dynamic runtime data of GA. Right now save into UserData. Maybe can overwrite GA class field directly.
    UserData.SkillID = SkillID

    G.log:debug(self.__TAG__, "Give ability GA: %s, SkillID: %d", GAClassPath, SkillID)
    self.actor.SkillComponent:GiveAbility(GAClass, -1, UserData)
end

function SkillComponent:InitCharacterAttrs()
    if not self.actor.InitGE then
        G.log:error(self.__TAG__, "Init ge not config.")
        assert(self.actor.InitGE)
    end

    local AbilitySystemComponent = G.GetHiAbilitySystemComponent(self.actor)
    AbilitySystemComponent:BP_ApplyGameplayEffectToSelf(self.actor.InitGE, 0.0, nil)
end

function SkillComponent:InitPassiveAbilities()
    if not self.InitAbilityGE then
        return
    end

    local AbilitySystemComponent = G.GetHiAbilitySystemComponent(self.actor)
    AbilitySystemComponent:BP_ApplyGameplayEffectToSelf(self.InitAbilityGE, 0.0, nil)
end

-- TODO common rpc for set UserData, not working right now because UserData as rpc params not replicated right.
function SkillComponent:Server_SetSkillTarget_RPC(SkillID, SkillTarget, SkillTargetTransform, bValidTransform, SkillTargetComponent, SkillClass)
    self:SetSkillTarget(SkillID, SkillTarget, SkillTargetTransform, bValidTransform, SkillTargetComponent, SkillClass, false)
end

function SkillComponent:Server_SetSkillOffsetTime_RPC(SkillID, StartOffsetTime)
    self:SetSkillOffsetTime(SkillID, StartOffsetTime)
end

decorator.message_receiver()
function SkillComponent:OnMaxTenacityChanged(NewValue, OldValue, Attribute)
    G.log:debug(self.__TAG__, "OnMaxTenacityChanged: %s, new: %f, old: %f", Attribute.AttributeName, NewValue, OldValue)
    self:ResetTenacity()
end

decorator.message_receiver()
function SkillComponent:OnTenacityChanged(NewValue, OldValue)
    G.log:debug(self.__TAG__, "OnTenacityChanged new: %f, old: %f", NewValue, OldValue)

    if NewValue > 0 then
        G.log:debug(self.__TAG__, "Actor: %s, in tenacity: %f", self.actor:GetDisplayName(), NewValue)
        self.bInTenacity = true
    end
end

decorator.message_receiver()
function SkillComponent:ResetTenacity()
    G.log:debug(self.__TAG__, "ResetTenacity")
    local ASC = G.GetHiAbilitySystemComponent(self.actor)
    local TenacityAttr = ASC:FindAttributeByName(SkillUtils.AttrNames.Tenacity)
    local AttributeSet = ASC:GetAttributeSet(TenacityAttr.AttributeOwner)
    ASC:SetAttributeBaseValue(TenacityAttr, AttributeSet.MaxTenacity.BaseValue)
end

decorator.message_receiver()
function SkillComponent:OnMovementModeChanged(PrevMovementMode, NewMovementMode, PreCustomMode, NewCustomMode)
    if not self.actor:IsServer() then
        return
    end

    -- G.log:debug(self.__TAG__, "OnMovementModeChanged, prev: %d(%d), new: %d(%d)", PrevMovementMode, PreCustomMode, NewMovementMode, NewCustomMode)
    -- local InAirTagContainer = UE.FGameplayTagContainer()
    -- InAirTagContainer.GameplayTags:Add(self.InAirTag)
    -- local OnGroundTagContainer = UE.FGameplayTagContainer()
    -- OnGroundTagContainer.GameplayTags:Add(self.OnGroundTag)
    local ASC = G.GetHiAbilitySystemComponent(self.actor)
    local bOnGround, _, _= self.actor:IsOnFloor()
    if NewMovementMode ~= UE.EMovementMode.MOVE_Walking and NewMovementMode ~= UE.EMovementMode.MOVE_NavWalking then
        if not ASC:HasGameplayTag(self.InAirTag) then
            self:SendMessage("InAir")
        end
    else
        if not ASC:HasGameplayTag(self.OnGroundTag) then
            self:SendMessage("OnGround")
        end
    end
end

--[[
    Skill judge
]]
decorator.require_check_action(StateConflictData.Action_Judge)
function SkillComponent:TryJudge(BeJudgeActor)
    if not BeJudgeActor then
        G.log:debug(self.__TAG__, "TryJudge BeJudgeActor is nil.")
        return
    end

    if self.bJudgeState then
        G.log:debug(self.__TAG__, "TryJudge already in judge state.")
        return
    end

    G.log:debug(self.__TAG__, "TryJudge send to server.")
    self.bJudgeState = true
    self:Server_TryJudge(BeJudgeActor)
end

function SkillComponent:Client_TryJudgeFail_RPC()
    G.log:debug(self.__TAG__, "Client TryJudgeFail.")
    self.bJudgeState = false
    self:SendMessage("EndState", StateConflictData.State_Judge)
end

function SkillComponent:Server_TryJudge_RPC(BeJudgeActor)
    G.log:debug(self.__TAG__, "TryJudge")
    if not BeJudgeActor then
        G.log:error(self.__TAG__, "TryJudge no BeJudgeActor")
        self:Client_TryJudgeFail()
        return
    end
    if not BeJudgeActor.OutBalanceComponent or not BeJudgeActor.OutBalanceComponent.bOutBalanceState then
        G.log:info(self.__TAG__, "Actor: %s not in OutBalance state, cant be judged.", BeJudgeActor:GetDisplayName())
        self:Client_TryJudgeFail()
        return
    end
    if BeJudgeActor.SkillComponent.bJudgeState then
        G.log:info(self.__TAG__, "Actor: %s already in judge.", BeJudgeActor:GetDisplayName())
        self:Client_TryJudgeFail()
        return
    end
    local JudgeGA = self:_GetJudgeGA(BeJudgeActor)
    if not JudgeGA then
        G.log:warn(self.__TAG__, "Actor: %s not config judge GA for OutBalance type: %d", BeJudgeActor:GetDisplayName(), BeJudgeActor.OutBalanceComponent.OutBalanceType)
        self:Client_TryJudgeFail()
        return
    end

    -- Set both Judge and BeJudge actor to judge state.
    self.bJudgeState = true
    BeJudgeActor.SkillComponent.bJudgeState = true
    BeJudgeActor:StopAnimMontage()
    BeJudgeActor:SendMessage("OnBeginBeJudge")

    local AdjustInfo
    if BeJudgeActor.OutBalanceComponent and BeJudgeActor.OutBalanceComponent.OutBalanceType == Enum.Enum_OutBalanceType.Light then
        AdjustInfo = BeJudgeActor.SkillComponent.LightJudgeAdjustInfo
    else
        AdjustInfo = BeJudgeActor.SkillComponent.HeavyJudgeAdjustInfo
    end
    local AdjustActor,RefActor
    if AdjustInfo.Type == Enum.Enum_JudgeAdjustType.Judge then
        AdjustActor = self.actor
        RefActor = BeJudgeActor
    else
        AdjustActor = BeJudgeActor
        RefActor = self.actor
    end

    BeJudgeActor.SkillComponent:CalcAndUpdatTransformBeforeEnterJudge(AdjustActor,RefActor)

    -- Adjust either Judge or BeJudge actor's position and rotation before judge.
    local AdjustLocation,AdjustRotation = self:CalcBeginPoseForJudge(AdjustActor, RefActor, AdjustInfo)
    AdjustActor.LocomotionComponent:Multicast_SetActorLocationAndRotation(AdjustLocation, AdjustRotation, false, true)

    -- Give judge ability to judge actor
    self:InitJudgeAbility(JudgeGA, BeJudgeActor)
    -- Activate Judge GA.
    local bSuccess = G.GetHiAbilitySystemComponent(self.actor):TryActivateAbilityByClass(JudgeGA)

    G.log:debug(self.__TAG__, "TryJudge success with JudgeActor: %s, BeJudgeActor: %s, GA: %s, activate: %s",
    self.actor:GetDisplayName(), BeJudgeActor:GetDisplayName(), G.GetDisplayName(JudgeGA), bSuccess)

    if bSuccess then
        self:SendMessage("JudgeSuccess", BeJudgeActor)
    else
        self.bJudgeState = false
        self:Client_TryJudgeFail()

        BeJudgeActor.SkillComponent.bJudgeState = false
        BeJudgeActor:SendMessage("OnEndBeJudge")
    end
end

-- 若场景中存在相应RouteActor,更新玩家or怪物位置和朝向
function SkillComponent:CalcAndUpdatTransformBeforeEnterJudge(AdjustActor,RefActor)
    local Actors = GameAPI.GetActorsWithTag(self.actor,self.ChuJueLocationTag)
    if not Actors or #Actors == 0 then
        return
    end

    local RouteActor = Actors[1]
    local isMoveMonster = RouteActor.isMoveMonster
    local Target
    if isMoveMonster then   --移动怪
        Target = AdjustActor:IsPlayerComp() and RefActor or AdjustActor
    else
        Target = AdjustActor:IsPlayerComp() and AdjustActor or RefActor
    end
    if not Target then return end
    local TargetLoc = RouteActor:K2_GetActorLocation()
    TargetLoc.Z = Target:K2_GetActorLocation().Z
    local TargetRot = Target:K2_GetActorRotation()
    TargetRot.Yaw = RouteActor:K2_GetActorRotation().Yaw
    Target.SkillComponent:Client_UpdatTransformBeforeEnterJudge(TargetLoc,TargetRot)
    Target.LocomotionComponent:Multicast_SetActorLocationAndRotation(TargetLoc,TargetRot,false,true)
    -- Target:K2_SetActorLocationAndRotation(TargetLoc,TargetRot,false,UE.FHitResult(),true)
end

function SkillComponent:Client_UpdatTransformBeforeEnterJudge_RPC(Loc,Rot)
    self.actor:K2_SetActorLocationAndRotation(Loc,Rot,false,UE.FHitResult(),true)
end

-- TODO not consider scene overlap.
---@return FVector, FRotator, AdjustLocation, AdjustRotation
function SkillComponent:CalcBeginPoseForJudge(AdjustActor,RefActor,AdjustInfo)
    local AdjustLocation = UE.UKismetMathLibrary.TransformLocation(RefActor:GetTransform(),AdjustInfo.PosOffset)
    AdjustLocation.Z = AdjustActor:K2_GetActorLocation().Z -- TODO Ignore Z
    local AdjustRotation = RefActor:K2_GetActorRotation()
    AdjustRotation.Yaw = AdjustRotation.Yaw + AdjustInfo.AngleOffset
    return AdjustLocation,AdjustRotation
end

--[[
    Judge skill
    ]]
function SkillComponent:InitJudgeAbility(JudgeGA,BeJudgeActor)
    local ASC = G.GetHiAbilitySystemComponent(self.actor)
    local AbilitySpecHandle = ASC:FindAbilitySpecHandleFromClass(JudgeGA)
    if AbilitySpecHandle.Handle ~= -1 then
        local AbilitySpec = SkillUtils.FindAbilitySpecFromHandle(ASC, AbilitySpecHandle)
        if AbilitySpec and AbilitySpec.UserData then
            AbilitySpec.UserData.SkillTarget = BeJudgeActor
        else
            G.log:warn(self.__TAG__, "InitJudgeAbility no ability spec found for GA: %s", JudgeGA)
        end
    else
        local InstigatorUD = utils.MakeUserData()
        InstigatorUD.SkillTarget = BeJudgeActor
        self.actor.SkillComponent:GiveAbility(JudgeGA, -1, InstigatorUD)
    end

    -- TODO Notify client skill to set target. Still has probability when client GA activate but SkillTarget in UserData not replicated to client yet.
    self:Client_SetSkillTarget(0, BeJudgeActor, UE.FTransform(), false, nil, JudgeGA.StaticClass())
end

decorator.message_receiver()
function SkillComponent:OnEndBeJudge()
    G.log:debug(self.__TAG__, "OnEndBeJudge")
    self.actor.SkillComponent.bJudgeState = false
end

function SkillComponent:_GetJudgeGA(BeJudgeActor)
    if BeJudgeActor.OutBalanceComponent.OutBalanceType == Enum.Enum_OutBalanceType.Light then
        return BeJudgeActor.SkillComponent.LightJudgeGA
    else
        return BeJudgeActor.SkillComponent.HeavyJudgeGA
    end
end

------------ AreaAbility Begin ----------
local AREAABILITY_INPUT_TAG = "AREAABILITY_INPUT_TAG"

function SkillComponent:AreaAbility_Lighting(AreaAbilityDetectActor)
    local DisplayName = G.GetDisplayName(AreaAbilityDetectActor)
end

decorator.message_receiver()
function SkillComponent:ReceiveAreaAbility(ItemActor)
    if self.actor:IsServer() then
        return
    end
    -- 获得区域能力-在UI上显示 (这是对于自己来说)
    local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
    local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
    local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)

    if ItemActor.AreaAbilityItemID then
        local ItemCnt = self.actor.EdRuntimeComponent:AddAreaAbilityItem(ItemActor.AreaAbilityItemID, 0)
        G.log:debug(self.__TAG__, "ReceiveAreaAbility %s %s %s", ItemActor.AreaAbilityItemID, ItemCnt, ItemCnt<=0)
        if AreaAbilityVM.SetAreaAbilityUsing then
            AreaAbilityVM:SetHasAreaAbility(ItemCnt > 0, ItemCnt > 0)
            AreaAbilityVM:SetAreaAbilityUsing(ItemCnt <= 0)
            AreaAbilityVM:SetAreaCopyerUsable(ItemCnt<=0)
        end
    end

    if self.actor.EdRuntimeComponent then
        self.actor.EdRuntimeComponent:AreaAbilityCopyEffect(Enum.E_AreaAbility.Lighting)
        --local utils = require("common.utils")
        --utils.DoDelay(self.actor, 2.0, function()
        --    self.actor.EdRuntimeComponent:AreaAbilityCopyEffect(Enum.E_AreaAbility.None)
        --end)
    end
    --self:CloseCopyerPanel()
end

decorator.message_receiver()
function SkillComponent:UseAreaAbility_Other(Location)
    self.AreaAbilityUseLocation = Location
end

decorator.message_receiver()
function SkillComponent:DetectAreaAbility(AreaAbilityDetectActor)
    self.AreaAbilityDetectActor = AreaAbilityDetectActor
    if AreaAbilityDetectActor then
        if AreaAbilityDetectActor.eAreaAbility == Enum.E_AreaAbility.Lighting then
            self:AreaAbility_Lighting(AreaAbilityDetectActor)
        end
    end
end

decorator.message_receiver()
function SkillComponent:OpenAreaAbilityPanel()
    self:OpenAreaAbilityExtractPanel()
    self:OpenCopyerPanel()
end

local EAreaAbilityPanelType = {
    AreaAbilityUsePanel=1,
    AreaAbilityCopyerPanel=2
}

decorator.message_receiver()
function SkillComponent:OpenAreaAbilityExtractPanel()
    if self.AreaAbilityPanelType == EAreaAbilityPanelType.AreaAbilityUsePanel then
        return
    end
    local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
    local InputDef = require('CP0032305_GH.Script.common.input_define')
    local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
    local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)
    local BPConst = require("common.const.blueprint_const")

    -- 打开区域能力使用界面
    local GameState = UE.UGameplayStatics.GetGameState(self.actor:GetWorld())
    if GameState then
        local ItemCnt = self.actor.EdRuntimeComponent:AddAreaAbilityItem(BPConst.AreaAbilityItemLightID, 0)
        if ItemCnt <= 0 then
            return
        end
        if not self.actor.EdRuntimeComponent.bEnableAreaAbility then -- 马杜克等禁用状态
            return
        end
        local ret = GameState:PlayerStartAimingMode(Enum.E_AimingModeType.AreaAbilityUse)
        AreaAbilityVM:HideShineInfo()
        if not ret then
            return
        end
        AreaAbilityVM:HideShineInfo()
        local InputComponent = self.actor:_GetComponent("BP_InputComponent", false)
        if InputComponent then
            --TODO(dougzhang): 目前是照明， 之后会有选择能力
            self.bAreaAbilityVM_SetCanExist = false
            self.actor.EdRuntimeComponent:RemoveAllInteractedUI()
            local function LeftMouseClick(InputHandler, value)
                -- 点击左键对别人使用; 左键使用需要选取一个目标; 这个还是延用 AimingMode 里边的
                if value then
                    if not self.AreaAbilityUseLocation then
                        return
                    end
                    local PlayerActor = self.actor
                    local ItemCnt = self.actor.EdRuntimeComponent:AddAreaAbilityItem(BPConst.AreaAbilityItemLightID, 0)
                    if ItemCnt <= 0 then
                        return
                    end
                    local ActorTransform = PlayerActor:GetTransform()
                    local PlayerLocation = PlayerActor:GetSocketLocation(PlayerActor.EdRuntimeComponent.AreaAbilityFlyAttachName)
                    --ActorTransform.Translation = PlayerLocation
                    --local ActorUse = self.actor.EdRuntimeComponent:AreaAbilityUseEffectOther(ActorTransform)
                    --if ActorUse then
                    --    ActorUse.NS_absorb:SetActive(true, true)
                    --    --ActorUse:AreaAbility_Fly2Other(self.AreaAbilityUseLocation)
                    --end
                    self.bAreaAbilityVM_SetCanExist = true
                    AreaAbilityVM:EnterReplicatorFocusState()
                    AreaAbilityVM:SetCanExist(false)
                    local eAreaAbility = self.actor.EdRuntimeComponent.eDefaultAreaAbility
                    local StartLocation = self.actor:K2_GetActorLocation()
                    self.actor.EdRuntimeComponent:Server_AreaAbilityUse(nil, BPConst.AreaAbilityItemLightID, eAreaAbility, StartLocation, self.AreaAbilityUseLocation)
                else
                    AreaAbilityVM:EnterReplicatorUnFocusState()
                end
            end
            local function RightMouseClick(InputHandler, value)
                if not value then
                    return
                end
                -- 进入区域能力使用之后，这个右键对应需要被替换掉, 指的是对自己使用区域能力; 这里需要反馈到服务端使用了区域能力
                if not self.actor.EdRuntimeComponent then
                    return
                end

                local PlayerActor = self.actor
                local ItemCnt = self.actor.EdRuntimeComponent:AddAreaAbilityItem(BPConst.AreaAbilityItemLightID, 0)
                if ItemCnt <= 0 then -- 没有获得该能力，无法使用
                    return
                end
                HiAudioFunctionLibrary.PlayAKAudio("Scn_Skills_Light_Cast", self.actor)
                local eAreaAbility = self.actor.EdRuntimeComponent.eDefaultAreaAbility
                local StartLocation = self.actor:K2_GetActorLocation()
                self.actor.EdRuntimeComponent:Server_AreaAbilityUse(self.actor, BPConst.AreaAbilityItemLightID, eAreaAbility, StartLocation, UE.FVector(0,0,0))
            end
            local function SprintAction()
                return true
            end
            InputComponent:RegisterInputHandler(InputModes.AreaAbilityUse, {Attack=LeftMouseClick, Aim=RightMouseClick, SprintAction=SprintAction})
            local PlayerController = self.actor.PlayerState:GetPlayerController()
            if PlayerController then
                PlayerController:SendMessage("RegisterIMC", AREAABILITY_INPUT_TAG, {"AreaAbility",}, {})
            end
        end
        AreaAbilityVM:OpenAreaAbilityPanel()
        self.AreaAbilityPanelType = EAreaAbilityPanelType.AreaAbilityUsePanel
        self.actor.EdRuntimeComponent.bInAreaAbility = true
        if not self.bOpenAreaAbilityPanel_First or true then
            self.bOpenAreaAbilityPanel_First = true
            local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
            local UIDef = require('CP0032305_GH.Script.ui.ui_define')
            if self.SpecialOpenUI then
                self.SpecialOpenUI:CloseMyself()
            end
            self.SpecialOpenUI = UIManager:OpenUI(UIDef.UIInfo.UI_ControlTips)
            --｛左键｝瞄准目标使用，或｛右键｝对自己使用
            self.SpecialOpenUI:SpecialOpen(ConstTextTable.AREAABILITY_USE_TIPS.Content)
        end
    end
end

decorator.message_receiver()
function SkillComponent:CloseAreaAbilityPanel(bAreaAbilityVM_SetCanExist_)
    if bAreaAbilityVM_SetCanExist_~= nil then
        self.bAreaAbilityVM_SetCanExist = bAreaAbilityVM_SetCanExist_
    end
    if self.bAreaAbilityVM_SetCanExist then
        return
    end
    -- 关闭区域能力使用界面
    local GameState = UE.UGameplayStatics.GetGameState(self.actor:GetWorld())
    if GameState then
        local InputComponent = self.actor:_GetComponent("BP_InputComponent", false)
        if InputComponent then
            InputComponent:UnRegisterInputHandler(InputModes.AreaAbilityUse)
        end
        local PlayerController = self.actor.PlayerState:GetPlayerController()
        if PlayerController then
            PlayerController:SendMessage("UnregisterIMC", AREAABILITY_INPUT_TAG)
        end
        local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
        local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
        ---@type HudMessageCenter
        local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
        --HudMessageCenterVM:HideControlTips()

        local BPConst = require("common.const.blueprint_const")
        local ItemCnt = self.actor.EdRuntimeComponent:AddAreaAbilityItem(BPConst.AreaAbilityItemLightID, 0)
        local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)
        if AreaAbilityVM then
            AreaAbilityVM:SetHasAreaAbility(ItemCnt>0)
            AreaAbilityVM:SetAreaAbilityUsing(ItemCnt <= 0)
            AreaAbilityVM:SetAreaCopyerUsable(ItemCnt <= 0)
            AreaAbilityVM:CloseAreaAbilityPanel()
        end

        if self.SpecialOpenUI then
            self.SpecialOpenUI:CloseMyself()
        end
        GameState:PlayerStopAimingMode()
        self.AreaAbilityPanelType = nil
        self.actor.EdRuntimeComponent.bInAreaAbility = false
        --- 在电梯上进入区域能力 Use 退出时重新唤起UI
        local OverlapActors = UE.TArray(UE.AActor)
        self.actor:GetOverlappingActors(OverlapActors)
        for Ind=1,OverlapActors:Length() do
            local OverlapActor = OverlapActors:Get(Ind)
            if OverlapActor.CloseAreaAbilityUsePanel then
                OverlapActor:CloseAreaAbilityUsePanel()
            end
        end
    end
end

decorator.message_receiver()
function SkillComponent:EnableAreaAbility(bEnable)
    local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
    local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
    local BPConst = require("common.const.blueprint_const")

    self.actor.EdRuntimeComponent.bEnableAreaAbility = bEnable
    local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)
    if AreaAbilityVM then
        local ItemCnt = self.actor.EdRuntimeComponent:AddAreaAbilityItem(BPConst.AreaAbilityItemLightID, 0)
        if bEnable then
            AreaAbilityVM:SetHasAreaAbility(ItemCnt>0)
            AreaAbilityVM:SetAreaAbilityUsing(ItemCnt <= 0)
            AreaAbilityVM:SetAreaCopyerUsable(ItemCnt <= 0)
        else
            AreaAbilityVM:SetHasAreaAbility(ItemCnt>0)
            AreaAbilityVM:SetAreaAbilityUsing(true)
            AreaAbilityVM:SetAreaCopyerUsable(false)
        end
    end
end

decorator.message_receiver()
function SkillComponent:OpenCopyerPanel()
    if self.AreaAbilityPanelType == EAreaAbilityPanelType.AreaAbilityCopyerPanel then
        return
    end
    local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
    local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
    local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)
    local BPConst = require("common.const.blueprint_const")

    local GameState = UE.UGameplayStatics.GetGameState(self.actor:GetWorld())
    if GameState then
        local ItemCnt = self.actor.EdRuntimeComponent:AddAreaAbilityItem(BPConst.AreaAbilityItemLightID, 0)
        if ItemCnt > 0 then
            return
        end
        if not self.actor.EdRuntimeComponent.bEnableAreaAbility then -- 马杜克等禁用状态
            return
        end
        local ret = GameState:PlayerStartAimingMode(Enum.E_AimingModeType.AreaAbilityCopy)
        if not ret then
            return
        end
        local InputComponent = self.actor:_GetComponent("BP_InputComponent", false)
        if InputComponent then
            self.bAreaAbilityVM_SetCanExist = false
            self.actor.EdRuntimeComponent:RemoveAllInteractedUI()
            --TODO(dougzhang): 目前是照明， 之后会有选择能力
            local function LeftMouseClick(InputHandler, value)
                if value then
                    local ItemCnt = self.actor.EdRuntimeComponent:AddAreaAbilityItem(BPConst.AreaAbilityItemLightID, 0)
                    if ItemCnt > 0 then -- TODO(dougzhang): 当前只能获取一个照明能力
                        return
                    end
                    if self.AreaAbilityDetectActor then
                        if self.AreaAbilityDetectActor.eAreaAbilityMain then
                            local ItemCnt = self.actor.EdRuntimeComponent:AddAreaAbilityItem(BPConst.AreaAbilityItemLightID, 1) -- 防止连续点击，后续数量是server同步过来的
                            self.bAreaAbilityVM_SetCanExist = true
                            AreaAbilityVM:EnterReplicatorFocusState()
                            AreaAbilityVM:SetCanExist(false)
                            local Location = self.AreaAbilityDetectActor:K2_GetActorLocation()
                            self.actor.EdRuntimeComponent:Server_AreaAbilityCopy(BPConst.AreaAbilityItemLightID, Location, self.AreaAbilityDetectActor.eAreaAbilityMain)
                        end
                    end
                    --if self.AreaAbilityDetectActor and self.AreaAbilityDetectActor.DoClientAreaAbilityCopyAction then -- 拷贝能力
                    --    self.AreaAbilityDetectActor:DoClientAreaAbilityCopyAction(self.actor)
                    --end
                else
                    AreaAbilityVM:EnterReplicatorUnFocusState()
                end
            end
            local function RightMouseClick()
                self:CloseCopyerPanel()
            end
            local function SprintAction()
                return true
            end
            InputComponent:RegisterInputHandler(InputModes.AreaAbility, {Attack=LeftMouseClick, Aim=RightMouseClick, SprintAction=SprintAction})
            local PlayerController = self.actor.PlayerState:GetPlayerController()
            if PlayerController then
                PlayerController:SendMessage("RegisterIMC", AREAABILITY_INPUT_TAG, {"AreaAbility",}, {})
            end
            AreaAbilityVM:OpenCopyerPanel()
            --AreaAbilityVM:HideShineInfo()
            self.AreaAbilityPanelType = EAreaAbilityPanelType.AreaAbilityCopyerPanel
            self.actor.EdRuntimeComponent.bInAreaAbility = true
            if not self.bOpenCopyerPanel_First or true then
                self.bOpenCopyerPanel_First = true
                local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
                local InputDef = require('CP0032305_GH.Script.common.input_define')
                local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
                local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
                local UIDef = require('CP0032305_GH.Script.ui.ui_define')
                if self.SpecialOpenUI then
                    self.SpecialOpenUI:CloseMyself()
                end
                self.SpecialOpenUI = UIManager:OpenUI(UIDef.UIInfo.UI_ControlTips)
                --瞄准电灯后｛左键｝点击吸收能力
                self.SpecialOpenUI:SpecialOpen(ConstTextTable.AREAABILITY_COPY_TIPS.Content)
            end
        end

    end
end

decorator.message_receiver()
function SkillComponent:BreakAimingMode(reason)
    -- M Key Invalid State Exist
    local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
    local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
    local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)
    if AreaAbilityVM then
        AreaAbilityVM:CloseAreaAbilityPanel()
        AreaAbilityVM:CloseCopyerPanel()
        self.AreaAbilityPanelType = nil
    end
    if self.SpecialOpenUI then
        self.SpecialOpenUI:CloseMyself()
    end
end

decorator.message_receiver()
function SkillComponent:CloseCopyerPanel(bAreaAbilityVM_SetCanExist_)
    if bAreaAbilityVM_SetCanExist_~= nil then
        self.bAreaAbilityVM_SetCanExist = bAreaAbilityVM_SetCanExist_
    end
    if self.bAreaAbilityVM_SetCanExist then
        return
    end
    local GameState = UE.UGameplayStatics.GetGameState(self.actor:GetWorld())
    if GameState then
        local InputComponent = self.actor:_GetComponent("BP_InputComponent", false)
        if InputComponent then
            InputComponent:UnRegisterInputHandler(InputModes.AreaAbility)
        end
        local PlayerController = self.actor.PlayerState:GetPlayerController()
        if PlayerController then
            PlayerController:SendMessage("UnregisterIMC", AREAABILITY_INPUT_TAG)
        end
        local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
        local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
        ---@type HudMessageCenter
        local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
        --HudMessageCenterVM:HideControlTips()

        local BPConst = require("common.const.blueprint_const")
        local ItemCnt = self.actor.EdRuntimeComponent:AddAreaAbilityItem(BPConst.AreaAbilityItemLightID, 0)
        local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)
        if AreaAbilityVM then
            AreaAbilityVM:SetHasAreaAbility(ItemCnt>0)
            AreaAbilityVM:SetAreaAbilityUsing(ItemCnt <= 0)
            AreaAbilityVM:SetAreaCopyerUsable(ItemCnt <= 0)
            AreaAbilityVM:CloseCopyerPanel()
        end
        EdUtils:SetOverlapActorOutline(self.AreaAbilityDetectActor, false)
        if self.SpecialOpenUI then
            self.SpecialOpenUI:CloseMyself()
        end
        GameState:PlayerStopAimingMode()
        self.AreaAbilityPanelType = nil
        self.actor.EdRuntimeComponent.bInAreaAbility = false

        --- 在电梯上进入区域能力 Copy；退出时重新唤起UI
        local OverlapActors = UE.TArray(UE.AActor)
        self.actor:GetOverlappingActors(OverlapActors)
        for Ind=1,OverlapActors:Length() do
            local OverlapActor = OverlapActors:Get(Ind)
            if OverlapActor.CloseAreaAbilityCopyPanel then
                OverlapActor:CloseAreaAbilityCopyPanel()
            end
        end
    end
end
------------ AreaAbility End ----------

return SkillComponent
