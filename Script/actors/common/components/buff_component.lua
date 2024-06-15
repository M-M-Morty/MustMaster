local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local check_table = require("common.data.state_conflict_data")

local BuffComponent = Component(ComponentBase)
local decorator = BuffComponent.decorator

local EBuffOP = {
    ADD = 1,
    REMOVE =  2 
}

function BuffComponent:Initialize(...)
    Super(BuffComponent).Initialize(self, ...)
end

function BuffComponent:Start()
    Super(BuffComponent).Start(self)

    -- Init buff handle for all buffs in BuffMap.
    self.BuffOps = {}

    local BuffMapKeys = self.BuffMap:Keys()
    for Ind = 1, BuffMapKeys:Length() do
        local Key = BuffMapKeys:Get(Ind)
        local PrefixKey = self.BuffTagPrefix
        local BuffName, _ = string.gsub(GetTagName(Key), GetTagName(PrefixKey)..".", "")
        BuffName, _ = string.gsub(BuffName, "%.", "")
        local OpFuncName = "Op"..BuffName.."Imp"
        if not BuffComponent[OpFuncName] then
            G.log:warn("BuffComponent", "buff: %s op func not found!", GetTagName(Key))
        else
            G.log:debug("BuffComponent", "Init buff: %s handler", BuffName)
            self.BuffOps[GetTagName(Key)] = BuffComponent[OpFuncName]
        end
    end
end

function BuffComponent:ReceiveBeginPlay()
    Super(BuffComponent).ReceiveBeginPlay(self)

    self.__TAG__ = string.format("BuffComponent(%s, server: %s)", G.GetObjectName(self.actor), self.actor:IsServer())
end

decorator.message_receiver()
---Add buff by tag. Invoke on server.
---@param Tag FGameplayTag
function BuffComponent:AddBuffByTag(Tag)
    local BuffGEClass = self.BuffMap:Find(Tag)
    if not BuffGEClass or not UE.UKismetSystemLibrary.IsValidClass(BuffGEClass) then
        G.log:error(self.__TAG__, "AddBuffByTag tag: %s not found in BuffMap.", GetTagName(Tag))
        return
    end

    local ASC = self.actor.AbilitySystemComponent
    local Level = 1
    local Context = UE.FGameplayEffectContextHandle()
    local Handle = ASC:BP_ApplyGameplayEffectToSelf(BuffGEClass, Level, Context)
    G.log:debug(self.__TAG__, "AddBuffByTag tag: %s, Handle: %d", GetTagName(Tag), Handle.Handle)
    return Handle
end

decorator.message_receiver()
---Remove buff by tag. Invoke on server.
---@param Tag FGameplayTag
---@param StacksToRemove number if nil or -1, removes all stacks, otherwise remove specified count.
function BuffComponent:RemoveBuffByTag(Tag, StacksToRemove)
    local BuffGEClass = self.BuffMap:Find(Tag)
    if not BuffGEClass or not UE.UKismetSystemLibrary.IsValidClass(BuffGEClass) then
        G.log:error(self.__TAG__, "RemoveBuffByTag tag: %s not found in BuffMap.", GetTagName(Tag))
        return
    end

    if not StacksToRemove then
        StacksToRemove = -1
    end

    G.log:debug(self.__TAG__, "RemoveBuffByTag tag: %s", GetTagName(Tag))
    local ASC = self.actor.AbilitySystemComponent
    ASC:RemoveActiveGameplayEffectBySourceEffect(BuffGEClass, nil, StacksToRemove)
end

decorator.message_receiver()
---Remove buff by FActiveGameplayEffectHandle.
---@param Handle FActiveGameplayEffectHandle
---@param StacksToRemove number if nil or -1, removes all stacks, otherwise remove specified count.
function BuffComponent:RemoveBuffByHandle(Handle, StacksToRemove)
    G.log:debug(self.__TAG__, "RemoveBuffByHandle: %d", Handle.Handle)
    if Handle.Handle == -1 then
        return
    end

    if not StacksToRemove then
        StacksToRemove = -1
    end

    local ASC = self.actor.AbilitySystemComponent
    ASC:RemoveActiveGameplayEffect(Handle, StacksToRemove)
end

decorator.message_receiver()
function BuffComponent:OnTagCountChanged(Tag, NewCount)
    -- if not UE.UBlueprintGameplayTagLibrary.MatchesTag(Tag, self.BuffTagPrefix, false) or
    --         UE.UBlueprintGameplayTagLibrary.EqualEqual_GameplayTag(Tag, self.BuffTagPrefix) then
    --     return
    -- end
    local QueryTagContainer = UE.FGameplayTagContainer()
    QueryTagContainer.GameplayTags:Add(Tag)
    if not UE.UBlueprintGameplayTagLibrary.MatchesTag(Tag, self.BuffTagPrefix, false) or UE.UBlueprintGameplayTagLibrary.HasAnyTags(self.BlackGameplayTags, QueryTagContainer, false) then
        --G.log:info(self.__TAG__, "buff %s in black list", GetTagName(Tag))
        return
    end

    G.log:info(self.__TAG__, "Buff OnTagCountChanged %s: %d", GetTagName(Tag), NewCount)
    if NewCount > 0 then
        self:OnBuffAdded(Tag)
    else
        self:OnBuffRemoved(Tag)
    end
end

function BuffComponent:HasBuff(BuffTag)
    local ASC = G.GetHiAbilitySystemComponent(self.actor)
    return ASC:HasGameplayTag(BuffTag)
end

function BuffComponent:GetBuffRemainingAndDuration(BuffTag)
    local ASC = G.GetHiAbilitySystemComponent(self.actor)
    local QueryTagContainer = UE.FGameplayTagContainer()
    QueryTagContainer.GameplayTags:Add(BuffTag)
    local EffectHandleList = ASC:GetActiveEffectsWithAllTags(QueryTagContainer)
    for Ind = 1, EffectHandleList:Length() do
        local EffectHandle = EffectHandleList:Get(Ind)
        if EffectHandle.Handle ~= -1 then
            local Remaining, Duration = ASC:GetActiveGameplayEffectRemainingAndDuration(EffectHandle)
            return Remaining, Duration
        end
    end

    return -1, -1
end

function BuffComponent:GetGameplayEffectByTag(BuffTag)
    local ASC = G.GetHiAbilitySystemComponent(self.actor)
    local QueryTagContainer = UE.FGameplayTagContainer()
    QueryTagContainer.GameplayTags:Add(BuffTag)
    local ActiveEffectHandleList = ASC:GetActiveEffectsWithAllTags(QueryTagContainer)
    G.log:info(self.__TAG__, "GetGameplayEffectByTag %s", ActiveEffectHandleList:Num())
    for Ind = 1, ActiveEffectHandleList:Length() do
        local EffectHandle = ActiveEffectHandleList:Get(Ind)
        if EffectHandle.Handle ~= -1 then
            return UE.UAbilitySystemBlueprintLibrary.GetGameplayEffectFromActiveEffectHandle(EffectHandle)
        end
    end
    return nil
end

--[[
    Some specified buffs.
]]
-- 极限闪避
decorator.message_receiver()
function BuffComponent:AddPreAttackBuff()
    self:AddBuffByTag(self.PreAttackTag)
end

decorator.message_receiver()
function BuffComponent:RemovePreAttackBuff()
    self:RemoveBuffByTag(self.PreAttackTag, -1)
end

function BuffComponent:HasPreAttackBuff()
    return false

    --local ASC = self.actor.AbilitySystemComponent
    --if ASC and ASC:HasGameplayTag(self.PreAttackTag) then
    --    return true
    --end
    --
    --return false
end

-- 受击硬直
decorator.message_receiver()
function BuffComponent:AddInKnockHitBuff()
    return self:AddBuffByTag(self.InKnockHitTag)
end

decorator.message_receiver()
function BuffComponent:RemoveInKnockHitBuff(Handle)
    self:RemoveBuffByHandle(Handle)
end

-- 击飞硬直
decorator.message_receiver()
function BuffComponent:AddInKnockHitFlyBuff()
    return self:AddBuffByTag(self.InKnockHitFlyTag)
end

decorator.message_receiver()
function BuffComponent:RemoveInKnockHitFlyBuff(Handle)
    self:RemoveBuffByHandle(Handle)
end

function BuffComponent:FindOps(Tag)
    local Parent = Tag
    while GetTagName(Parent) ~= "None" do
        G.log:debug(self.__TAG__, "Current tag: %s", GetTagName(Parent))
        local func = self.BuffOps[GetTagName(Parent)]
        if func ~= nil then
            return func
        end
        Parent = UE.UHiUtilsFunctionLibrary.GetDirectParentGameplayTag(Parent)
    end
    return
end

function BuffComponent:OnBuffAdded(Tag)
    local func = self:FindOps(Tag)
    G.log:debug(self.__TAG__, "OnBuffAdded tag: %s %s", GetTagName(Tag), func == nil)
    if func then
        func(self, EBuffOP.ADD, Tag)
    end
    self:SendMessage("OnBuffAdded", Tag)
end

function BuffComponent:OnBuffRemoved(Tag)
    local func = self:FindOps(Tag)
    G.log:debug(self.__TAG__, "OnBuffRemoved tag: %s %s", GetTagName(Tag), func == nil)
    if func then
        func(self, EBuffOP.REMOVE, Tag)
    end
    self:SendMessage("OnBuffRemoved", Tag)
end

-- Check whether gameplay effect is buff.
function BuffComponent:IsBuff(EffectSpec)
    return UE.UBlueprintGameplayTagLibrary.HasTag(EffectSpec.Def.InheritableGameplayEffectTags.CombinedTags, self.BuffTagPrefix, false)
end

-- 定帧
function BuffComponent:OpStiffnessImp(OpType)
    if OpType == EBuffOP.ADD then
        -- 首先停掉魔女时间
        local MAX_TIME = 1000
        local STIFFNESS_TIME_SPEED = 0.01
        local Delay = 0.01
        local STIFFNESS_TIME_PRIORITY = 10;
        G.log:info(self.__TAG__, "STIFF TAG BEGIN %s", self.actor:GetName())
        self:SendMessage("StopWitchTime")
        self:SendMessage("SetTimeDilation", MAX_TIME, STIFFNESS_TIME_SPEED, Delay, STIFFNESS_TIME_PRIORITY)
    elseif OpType == EBuffOP.REMOVE then
        self:SendMessage("ForceClearTimerDilation")
        G.log:info(self.__TAG__, "STIFF TAG END %s", self.actor:GetName())
    end
end

-- 禁止输入
function BuffComponent:OpDisableInputImp(OpType)
    if OpType == EBuffOP.ADD then
        utils.SetPlayerInputEnabled(self.actor, false)
    elseif OpType == EBuffOP.REMOVE then
        utils.SetPlayerInputEnabled(self.actor, true)
    end
end

-- 预警攻击，用于极限闪避
function BuffComponent:OpPreAttackImp(OpType, BuffTag)
    G.log:debug(self.__TAG__, "OnPreAttackImp: %d", OpType)
end

-- 免疫受击
function BuffComponent:OpImmuneHitImp(OpType, BuffTag)
    G.log:debug(self.__TAG__, "OpImmuneHitImp: %d", OpType)
end

decorator.message_receiver()
function BuffComponent:EventOnDialogueBegin()
    self:Server_EnterImmuneDamageSituation()
end

function BuffComponent:Server_EnterImmuneDamageSituation_RPC()
    self:AddBuffByTag(self.ImmuneHitTag)
    self:AddBuffByTag(self.ImmuneDamageTag)
end

decorator.message_receiver()
function BuffComponent:EventOnDialogueEnd()
    self:Server_OutImmuneDamageSituation()
end

function BuffComponent:Server_OutImmuneDamageSituation_RPC()
    self:RemoveBuffByTag(self.ImmuneHitTag)
    self:RemoveBuffByTag(self.ImmuneDamageTag)
end

-- OPxxx开头表示添加buff时回调为前面字符串组装，后续根据接收buff进行调用
-- 免疫伤害[通知]
function BuffComponent:OpImmuneDamageImp(OpType)
    G.log:debug(self.__TAG__, "OpImmuneDamageImp: %d", OpType)
end

-- 免疫受击和伤害
function BuffComponent:OpImmuneImp(OpType)
end

function BuffComponent:OpInKnockHitImp(OpType, BuffTag)
    G.log:debug(self.__TAG__, "OpInKnockHitImp: %d", OpType)
    self:HandleInKnockChanged()
end

function BuffComponent:OpInKnockHitFlyImp(OpType, BuffTag)
    G.log:debug(self.__TAG__, "OpInKnockHitFlyImp: %d", OpType)
    self:HandleInKnockChanged()
end

function BuffComponent:OpModifySkillImp(OpType, BuffTag)
    local GameplayEffectCDO = self:GetGameplayEffectByTag(BuffTag)
    if GameplayEffectCDO == nil then
        G.log:error(self.__TAG__, "Get GameplayEffectCDO failed: %s", GetTagName(BuffTag))
        return
    else
        G.log:debug(self.__TAG__, "Get GameplayEffectCDO success: %s %s %s", GetTagName(BuffTag), GameplayEffectCDO.InputKey, GameplayEffectCDO.SkillID)
    end
    if OpType == EBuffOP.ADD then
        self:SendMessage("AddSkillInputModifier", GameplayEffectCDO.InputKey, GameplayEffectCDO.SkillID, BuffTag)
    elseif OpType == EBuffOP.REMOVE then
        self:SendMessage("RemoveSkillInputModifier", GameplayEffectCDO.InputKey, GameplayEffectCDO.SkillID, BuffTag)
    end
end

function BuffComponent:HandleInKnockChanged()
    local ASC = self.actor.AbilitySystemComponent
    if not ASC then
        return
    end

    local bInKnock = ASC:HasGameplayTag(self.InKnockHitTag) or ASC:HasGameplayTag(self.InKnockHitFlyTag)
    self.actor.CharacterStateManager:SetInKnock(bInKnock)
end

decorator.message_receiver()
function BuffComponent:ClearBuff()
    local Tags = self.BuffToClearWhenSwitchPlayer.GameplayTags
    if Tags:Length() then
        local ASC = G.GetHiAbilitySystemComponent(self.actor)

        ASC:RemoveActiveEffectsWithTags(self.BuffToClearWhenSwitchPlayer)

        for Ind = 1, Tags:Length() do
            local CurTag = Tags:Get(Ind)
            local ToRemoveTags = UE.FGameplayTagContainer()
            ToRemoveTags.GameplayTags:Add(CurTag)

            if ASC:HasGameplayTag(CurTag) then
                UE.UAbilitySystemBlueprintLibrary.RemoveLooseGameplayTags(self.actor, ToRemoveTags, true)
            end
        end
    end

end

return BuffComponent
