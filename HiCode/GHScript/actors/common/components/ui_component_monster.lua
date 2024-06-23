require "UnLua"

local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

local MonsterUIComponent = Component(ComponentBase)

local decorator = MonsterUIComponent.decorator
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local SkillUtils = require("common.skill_utils")
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')

function MonsterUIComponent:ReceiveBeginPlay()
    Super(MonsterUIComponent).ReceiveBeginPlay(self)

    if not self.actor:IsClient() then
        self.actor:RemoveBlueprintComponent(self)
        return
    end

    if self.actor:ActorHasTag("Vehicle") then
        -- 载具不用UIComponent
        self.actor:RemoveBlueprintComponent(self)
        return
    end
    if self.actor.BattleStateComponent:IsInBattle() then
        self:OnEnterBattle()
    end
    self.hpShow = false
    self:RegisterGameTagCallback()
end

decorator.message_receiver()
function MonsterUIComponent:OnReceiveTick(DeltaSeconds)
    if not self.hpShow then
        local ASC = self.actor:GetHiAbilitySystemComponent()
        if ASC:GetAllAttributes():Length() == 0 then
            return
        end


        self.hpShow = true
    end
end

decorator.message_receiver()
function MonsterUIComponent:OnHealthChanged(NewValue, OldValue)
    if SkillUtils.IsBoss(self.actor) then
        return
    end
    local MaxHealthExist, MaxHealth = self:GetAttributeValue(SkillUtils.AttrNames.MaxHealth)
    if MaxHealthExist then
        local widget = self:GetHPWidget()
        if widget then
            if NewValue <= 0 then
                widget:SetHealth(0, MaxHealth)
            else
                widget:SetHealth(NewValue, MaxHealth)
            end
        end
    end
end

function MonsterUIComponent:GetHPWidget()
    local comp = self:GetOwner().BP_MonsterHPWidget
    return comp and comp:GetWidget()
end

decorator.message_receiver()
function MonsterUIComponent:OnTenacityChanged(NewValue, OldValue)
    local TenacityExist, Tenacity = self:GetAttributeValue(SkillUtils.AttrNames.Tenacity)
    local MaxTenacityExist, MaxTenacity = self:GetAttributeValue(SkillUtils.AttrNames.MaxTenacity)

    if TenacityExist and MaxTenacityExist then
        if SkillUtils.IsBoss(self.actor) then
            self:HudMsgCenter():ShieldUpdate(Tenacity, MaxTenacity)
        else
            local widget = self:GetHPWidget()
            if widget then
                widget:SetTenacity(Tenacity, MaxTenacity)
            end
        end
    end
end

decorator.message_receiver()
function MonsterUIComponent:BeSelected(Enabled)
    local widget = self:GetHPWidget()
    if widget then
        if Enabled then
            widget:SetLockMode(true)
        else
            widget:SetLockMode(false)
        end
    end
end

decorator.message_receiver()
function MonsterUIComponent:OnBeginRide(vehicle)
    local Widget = self.actor.WidgetComponent:GetWidget()
    if not Widget then
        return
    end
    Widget.WhiteProgressBar:SetVisibility(0)
    Widget.WhiteProgressBar_BG:SetVisibility(0)

    -- TODO
    if not self.actor.RideComponent then
        return
    end
    if Widget and self.actor.RideComponent then
        Widget:UpdateWhiteProgress(self.actor.RideComponent.CurrentVehicle)
    end
end

decorator.message_receiver()
function MonsterUIComponent:OnEndRide(vehicle)
    local Widget = self.actor.WidgetComponent:GetWidget()
    Widget.WhiteProgressBar:SetVisibility(2)
    Widget.WhiteProgressBar_BG:SetVisibility(2)
end

decorator.message_receiver()
function MonsterUIComponent:OnVehicleHealthChanged()
    local Widget = self.actor.WidgetComponent:GetWidget()
    if Widget and self.actor.RideComponent then
        Widget:UpdateWhiteProgress(self.actor.RideComponent.CurrentVehicle)
    end
end

decorator.message_receiver()
function MonsterUIComponent:OnDamaged(Damage, HitInfo, InstigatorCharacter, DamageCauser, DamageAbility, DamageGESpec)
    G.log:debug("santi", "%s OnDamaged, Ability: %s, damage: %f, bBlockingHit: %s, ImpactPoint: %s",
        self.actor:GetDisplayName(), UE.UKismetSystemLibrary.GetDisplayName(DamageAbility), Damage,
        tostring(HitInfo.bBlockingHit), tostring(HitInfo.ImpactPoint))
    if Damage == 0 then
        return
    end
    self:HudMsgCenter():AddLocationHurtDamage(HitInfo.ImpactPoint, Damage, "Normal", Enum.Enum_DamageNumber.Normal, "",
        false)
    if SkillUtils.IsBoss(self.actor) then
        local data = { num = Damage }
        self:HudMsgCenter():ChangeBossHP(data)
        return
    end
end

decorator.message_receiver()
function MonsterUIComponent:OnDefendFrontDamage(SourceActor)
    -- self:ShowDefendFrontDamageTips()
end

function MonsterUIComponent:ShowDefendFrontDamageTips()
    local DefendWidget = UE.UWidgetBlueprintLibrary.Create(self.actor, self.DefendWidgetClass)
    local Color = UE.FLinearColor(1.0, 0, 0)
    DefendWidget:UpdateColor(Color)

    -- Set position
    local ScreenPos = UE.FVector2D()
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self.actor:GetWorld(), 0)
    UE.UWidgetLayoutLibrary.ProjectWorldLocationToWidgetPosition(PlayerController, self.actor:K2_GetActorLocation(),
        ScreenPos, false)
    DefendWidget:SetPositionInViewport(ScreenPos, false)
    DefendWidget:AddToViewport()
end

function MonsterUIComponent:Destroy()
    Super(MonsterUIComponent).Destroy(self)

    self:ShowJudgeUI(false)
end

function MonsterUIComponent:HudMsgCenter()
    return ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
end

function MonsterUIComponent:GetAttributeValue(attributeName)
    local ASC = self.actor:GetHiAbilitySystemComponent()
    if not ASC then
        return false, 0
    end

    local Attr = SkillUtils.GetAttribute(ASC, attributeName)
    if not Attr then
        return false, 0
    end
    return true, Attr.CurrentValue
end

function MonsterUIComponent:RegisterGameTagCallback()
    self:RegisterGameplayTagCB("StateGH.InDeath", UE.EGameplayTagEventType.NewOrRemoved, "OnDead")
    self:RegisterGameplayTagCB("StateGH.Tenacity.a", UE.EGameplayTagEventType.NewOrRemoved, "GHUI_OnTenacityChanged")
    self:RegisterGameplayTagCB("StateGH.Tenacity.zero", UE.EGameplayTagEventType.NewOrRemoved, "GHUI_OnTenacityChanged")
end

function MonsterUIComponent:SetDaedEvent(fn)
    self.DaedEventCB = fn
end

decorator.message_receiver()
function MonsterUIComponent:OnDead()
    if not self.actor:IsClient() then
        return
    end

    if self.DaedEventCB then
        self.DaedEventCB()
    end
    if SkillUtils.IsBoss(self.actor) then
        self:ShowBossUI(false)
    end
end

function MonsterUIComponent:GHUI_OnTenacityChanged()
    if not self.actor:IsClient() then
        return
    end

    local tagA = FunctionUtil:HasGameplayTag(self.actor, 'StateGH.Tenacity.a')
    local tagZero = FunctionUtil:HasGameplayTag(self.actor, 'StateGH.Tenacity.zero')

    if tagA or tagZero then
        self:OnBeginOutBalance()
    else
        self:OnEndOutBalance()
    end
end

decorator.message_receiver()
function MonsterUIComponent:OnBeginOutBalance()
    if not self.actor:IsClient() then
        return
    end

    local bShow = false
    if not self.actor:IsDead() then
        local Player = UE.UGameplayStatics.GetPlayerCharacter(self, 0)
        local Dis = UE.UKismetMathLibrary.Vector_Distance2D(Player:K2_GetActorLocation(),
            self.actor:K2_GetActorLocation())
        if Dis <= self.actor.SkillComponent.JudgeUIShowMaxDis then
            bShow = true
        end
    end
    self:ShowJudgeUI(bShow)
end

decorator.message_receiver()
function MonsterUIComponent:OnEndOutBalance()
    if not self.actor:IsClient() then
        return
    end

    self:ShowJudgeUI(false)
end

function MonsterUIComponent:ShowJudgeUI(bShow)
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self:GetWorld(), 0)
    PlayerController:SendMessage("ShowJudgeUI", bShow, self.actor, self.JudgeWidgetDuration)
end

decorator.message_receiver()
function MonsterUIComponent:OnEnterBattle()
    if not self.actor:IsClient() then
        return
    end

    if SkillUtils.IsBoss(self.actor) then
        self:ShowBossUI(true)
    end
end

decorator.message_receiver()
function MonsterUIComponent:OnEnterReturning()
    if not self.actor:IsClient() then
        return
    end

    if SkillUtils.IsBoss(self.actor) then
        self:ShowBossUI(false)
    end
end

function MonsterUIComponent:ShowBossUI(bShow)
    local HudMsgCenter = self:HudMsgCenter()
    if not HudMsgCenter then
        return
    end

    if bShow then
        local TenacityExist, Tenacity = self:GetAttributeValue(SkillUtils.AttrNames.Tenacity)
        local MaxTenacityExist, MaxTenacity = self:GetAttributeValue(SkillUtils.AttrNames.MaxTenacity)
        local HealthExist, Health = self:GetAttributeValue(SkillUtils.AttrNames.Health)
        local MaxHealthExist, MaxHealth = self:GetAttributeValue(SkillUtils.AttrNames.MaxHealth)

        if TenacityExist and MaxTenacityExist and HealthExist and MaxHealthExist then
            local BossName = self.actor.Name or ''
            HudMsgCenter:ShowBossHP(MaxHealth, Health, MaxTenacity, Tenacity, BossName)
        end
    else
        HudMsgCenter:CloseBossHP()
    end
end

return MonsterUIComponent
