---AttributeComponent bind to both role and PlayerState.
---PlayerState and role use same ASC in role.
---1. In PlayerState it handle across-role attributes.
---2. In role it handle only current role attributes.
local G = require("G")
local AttributeComponentBase = require("actors.common.components.attribute_component_base")
local Component = require("common.component")

local AttributeComponent = Component(AttributeComponentBase)
local decorator = AttributeComponent.decorator

function AttributeComponent:Initialize(...)
    Super(AttributeComponent).Initialize(self, ...)
end

function AttributeComponent:Start()
    Super(AttributeComponent).Start(self)
end

function AttributeComponent:ReceiveBeginPlay()
    Super(AttributeComponent).ReceiveBeginPlay(self)
    self.__TAG__ = string.format("AttributeComponent(actor: %s, server: %s)", G.GetObjectName(self.actor), self.actor:IsServer())
    if self.actor:IsA(UE.APlayerState) then
        self.bIsPlayerState = true
    else
        self.ASC = self.actor.AbilitySystemComponent
        self.bIsPlayerState = false
    end
end

-- TODO may be need handle order of BeginPlay and OnPawnSet delegate callback.
decorator.message_receiver()
function AttributeComponent:OnPawnSet(PlayerState, NewPawn, OldPawn)
    G.log:debug("AttributeComponent", "OnPawnSet New: %s, Old: %s", G.GetDisplayName(NewPawn), G.GetDisplayName(OldPawn))

    -- Clear auto recover effects from old pawn ASC.
    if OldPawn and OldPawn ~= NewPawn then
        OldPawn.AttributeComponent:ClearAutoEffects()
        OldPawn.AttributeComponent:ClearAllActionEffects()
    end

    if NewPawn then
        NewPawn.AttributeComponent:ClearTagOnSwitchPlayer()
        self.ASC = G.GetHiAbilitySystemComponent(NewPawn)

        -- TODO old pawn should cancel ge ?
        self:ApplyAutoEffects()
    end
end

---Check and apply action(3C) cost, Invoke this both on client and server.
---     On client, this was did in require_check_action in StateControllerComponent.
---     On server, this was did in specified component of corresponding action.
---Only server will do the actual apply.
---usage:
---      1. Add new action type to Enum_ActionType.
---      2. Modify ActionCostEffects in Character AttributeComponent to config cost GE for this action.
---@param Action string Action defined in state conflict table.
---@param CostAction Enum_ActionType custom defined action(3C .etc.)
---@param CallbackOwner UObject callback owner
---@param OnSuccess function success callback
---@param OnFail function fail callback
function AttributeComponent:TryBeginAction(Action, CostAction, CallbackOwner, OnSuccess, OnFail)
    if not UE.UKismetSystemLibrary.IsStandalone(self) then
        local CostEffect = self.ActionCostEffects:Find(CostAction)
        if CostEffect then
            if not self.ASC:CanApplyGE(NewObject(CostEffect), 1, UE.FGameplayEffectContextHandle()) then
                G.log:debug(self.__TAG__, "TryBeginAction costAction: %s, cost ge: %s fail.", CostAction, G.GetObjectName(CostEffect))
                -- TODO hardcode here, read error notice from cost ge.
                local ErrNotice = "耐力值不足"
                if OnFail then
                    OnFail(CallbackOwner, Action, CostAction, ErrNotice)
                else
                    utils.PrintString(ErrNotice, UE.FLinearColor(1, 0, 0, 1), 2)
                end
                return false
            end

            -- Apply cost ge on server.
            G.log:debug(self.__TAG__, "TryBeginAction costAction: %s, cost ge: %s success.", CostAction, G.GetObjectName(CostEffect))
            if self.actor:IsServer() then
                self:HandleActionEffect(CostAction, true)
            end
        end
    end

    -- With client predict, not wait server check.
    if OnSuccess then
        OnSuccess(CallbackOwner, Action, CostAction)
    end
    return true
end

---End action will cancel cost of this action if has, only work on server.
---@param Action Enum_ActionType custom defined action
function AttributeComponent:TryEndAction(Action)
    G.log:debug(self.__TAG__, "TryEndAction costaction: %d, server: %s", Action, self.actor:IsServer())
    -- Remove cost ge on server.
    if self.actor:IsServer() then
        self:HandleActionEffect(Action, false)
    end
end

---Auto apply effects use to auto recover attribute(Stamina, Mana .etc.)
---This may be paused by other GE use OnGoing tags.
function AttributeComponent:ApplyAutoEffects()
    for Ind = 1, self.AutoApplyEffects:Length() do
        local CurEffect = self.AutoApplyEffects:Get(Ind)
        local Spec = self.ASC:MakeOutgoingSpec(CurEffect, 1, UE.FGameplayEffectContextHandle())
        G.log:debug("AttributeComponent", "%s ApplyAutoEffects ge: %s", G.GetObjectName(self.actor), G.GetObjectName(CurEffect))
        self.ASC:BP_ApplyGameplayEffectSpecToSelf(Spec)
    end
end

---Clear all auto recover effects
function AttributeComponent:ClearAutoEffects()
    for Ind = 1, self.AutoApplyEffects:Length() do
        local CurEffect = self.AutoApplyEffects:Get(Ind)
        G.log:debug("AttributeComponent", "ClearAutoEffects ge: %s", G.GetObjectName(CurEffect))
        self.ASC:RemoveActiveGameplayEffectBySourceEffect(CurEffect)
    end
end

function AttributeComponent:ClearAllActionEffects()
    local Keys = self.ActionCostEffects:Keys()
    for Ind = 1, Keys:Length() do
        local CurKey = Keys:Get(Ind)
        local GEClass = self.ActionCostEffects:Find(CurKey)
        if GEClass then
            self.ASC:RemoveActiveGameplayEffectBySourceEffect(GEClass)
        end
    end
end

function AttributeComponent:HandleActionEffect(Action, bStart)
    if bStart then
        -- Apply cost effects.
        local CostEffect = self.ActionCostEffects:Find(Action)
        if CostEffect then
            G.log:debug(self.__TAG__, "HandleActionEffect with costAction: %s, add costGE: %s", Action, G.GetObjectName(CostEffect))
            self:_AddGEByClass(CostEffect)
            self:_AddGEByClass(self.RecoverStaminaBlockGE)
        end
    else
        -- Remove cost effects.
        local CostEffect = self.ActionCostEffects:Find(Action)
        if CostEffect then
            G.log:debug(self.__TAG__, "HandleActionEffect with costAction: %s, remove costGE: %s", Action, G.GetObjectName(CostEffect))
            self:_RemoveGEByClass(CostEffect)
        end

        self:_RemoveGEByClass(self.RecoverStaminaBlockGE)
        -- Add delay effects.
        self:_AddGEByClass(self.RecoverDelayGE)
    end
end

function AttributeComponent:_AddGEByClass(GEClass, Level)
    if not Level then
        Level = 1
    end
    local Spec = self.ASC:MakeOutgoingSpec(GEClass, Level, UE.FGameplayEffectContextHandle())
    local SpecHandle = self.ASC:BP_ApplyGameplayEffectSpecToSelf(Spec)
    return SpecHandle
end

function AttributeComponent:_RemoveGEByClass(GEClass)
    self.ASC:RemoveActiveGameplayEffectBySourceEffect(GEClass)
end

decorator.message_receiver()
function AttributeComponent:OnStaminaChanged(NewValue, OldValue)
    --G.log:debug(self.__TAG__, "OnStaminaChanged new: %f, old: %f", NewValue, OldValue)

    -- Run full stamina check on current role only.
    if not self.actor:IsServer() or self.bIsPlayerState then
        return
    end

    local MaxStamina = SkillUtils.GetAttribute(self.ASC, SkillUtils.AttrNames.MaxStamina).BaseValue
    local TagContainer = UE.FGameplayTagContainer()
    TagContainer.GameplayTags:Add(self.StaminaFullTag)
    if NewValue == MaxStamina then
        if not self.bFullStamina then
            self.bFullStamina = true
            UE.UAbilitySystemBlueprintLibrary.AddLooseGameplayTags(self.actor, TagContainer, true)
        end
    else
        if self.bFullStamina then
            self.bFullStamina = false
            UE.UAbilitySystemBlueprintLibrary.RemoveLooseGameplayTags(self.actor, TagContainer, true)
        end
    end
end

function AttributeComponent:ClearTagOnSwitchPlayer()
    local TagContainer = UE.FGameplayTagContainer()
    TagContainer.GameplayTags:Add(self.StaminaFullTag)
    TagContainer.GameplayTags:Add(self.StaminaRecoverBlockTag)
    self.bFullStamina = false
    UE.UAbilitySystemBlueprintLibrary.RemoveLooseGameplayTags(self.actor, TagContainer, true)
end

decorator.message_receiver()
function AttributeComponent:OnMovementModeChanged(PrevMovementMode, NewMovementMode, PreCustomMode, NewCustomMode)
    if not self.actor:IsServer() or not self.actor.PlayerState then
        return
    end

    --G.log:debug(self.__TAG__, "OnMovementModeChanged, prev: %d(%d), new: %d(%d)", PrevMovementMode, PreCustomMode, NewMovementMode, NewCustomMode)
    if NewMovementMode == UE.EMovementMode.MOVE_Walking or NewMovementMode == UE.EMovementMode.MOVE_NavWalking or self.actor:IsOnFloor() then
        -- Add delay effects.
        local Spec = self.ASC:MakeOutgoingSpec(self.actor.PlayerState.AttributeComponent.RecoverDelayGE, 1, UE.FGameplayEffectContextHandle())
        local SpecHandle = self.ASC:BP_ApplyGameplayEffectSpecToSelf(Spec)
    end
end

decorator.message_receiver()
function AttributeComponent:AddPowerOnDamage(Damage)
    if not self.ASC then
        return
    end

    local PowerAttrData = SkillUtils.GetAttribute(self.ASC, SkillUtils.AttrNames.Power)
    local MaxPowerAttrData = SkillUtils.GetAttribute(self.ASC, SkillUtils.AttrNames.MaxPower)
    local MaxHealthAttrData = SkillUtils.GetAttribute(self.ASC, SkillUtils.AttrNames.MaxHealth)
    if PowerAttrData and MaxPowerAttrData and MaxHealthAttrData then
        local DeltaPower = self.RecoverPowerAddValue + self.RecoverPowerMulValue * Damage / MaxHealthAttrData.CurrentValue
        local NewPower = UE.UKismetMathLibrary.FClamp(PowerAttrData.CurrentValue + DeltaPower, 0, MaxPowerAttrData.CurrentValue)
        SkillUtils.SetAttributeBaseValue(self.ASC, SkillUtils.AttrNames.Power, NewPower)
    end
end

decorator.message_receiver()
function AttributeComponent:SetInBattleState(bInBattle)
    if self.bIsPlayerState then
        return
    end

    if bInBattle == self.bInBattle then
        return
    end
    self.bInBattle = bInBattle

    if not bInBattle then
        for Ind = 1, self.OutBattleEffects:Length() do
            self.ASC:BP_ApplyGameplayEffectToSelf(self.OutBattleEffects:Get(Ind), 0.0, nil)
        end
    end
end

return AttributeComponent
