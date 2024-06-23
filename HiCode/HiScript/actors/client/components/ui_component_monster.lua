---已废弃，目前monsteruicomponent使用的脚本为gh目录下ui_component_monster
require "UnLua"

local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

local MonsterUIComponent = Component(ComponentBase)

local decorator = MonsterUIComponent.decorator

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

    self:InitDamageNumberWidgetPool()

    if self.actor.BattleStateComponent:IsInBattle() then
        self:ShowHpBar()
    end
end

decorator.message_receiver()
function MonsterUIComponent:OnReceiveTick(DeltaSeconds)
    -- TODO Temp close judge.
    --self:TryShowJudgeUI()
end

function MonsterUIComponent:TryShowJudgeUI()
    local bShow = false
    if not self.actor:IsDead() then
        local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
        local Dis = UE.UKismetMathLibrary.Vector_Distance2D(Player:K2_GetActorLocation(), self.actor:K2_GetActorLocation())
        if Dis <= self.actor.SkillComponent.JudgeUIShowMaxDis then
            bShow = true
        end
    end

    self:ShowJudgeUI(bShow)
end

decorator.message_receiver()
function MonsterUIComponent:ShowHpBar()
    if self.actor.MonsterType == Enum.Enum_MonsterType.Boss or self.actor.CharIdentity == Enum.Enum_CharIdentity.NPC then
        -- BOSS和NPC不用头顶血条
        return
    end

    self.actor.WidgetComponent:SetVisibility(true)
end

decorator.message_receiver()
function MonsterUIComponent:HideHpBar()
    self.actor.WidgetComponent:SetVisibility(false)
end

decorator.message_receiver()
function MonsterUIComponent:OnHealthChanged(NewValue, OldValue)
    if NewValue > 0 then
        local Widget = self.actor.WidgetComponent:GetWidget()
        if Widget then
            Widget.Character = self.actor
            Widget:UpdateHP()
        end
    end
end

decorator.message_receiver()
function MonsterUIComponent:OnTenacityChanged(NewValue, OldValue)
    local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
    Player:SendControllerMessage("UpdateBossTenacityUI")
end

decorator.message_receiver()
function MonsterUIComponent:BeSelected(Enabled)
    local Widget = self.actor.WidgetComponent:GetWidget()
    if Enabled then
        Widget.BeSelected:SetVisibility(0)
    else
        Widget.BeSelected:SetVisibility(2)
    end
end

decorator.message_receiver()
function MonsterUIComponent:OnBeginRide(vehicle)
    local Widget = self.actor.WidgetComponent:GetWidget()
    Widget.WhiteProgressBar:SetVisibility(0)
    Widget.WhiteProgressBar_BG:SetVisibility(0)

    -- TODO
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
        self.actor:GetDisplayName(), G.GetDisplayName(DamageAbility), Damage, tostring(HitInfo.bBlockingHit), tostring(HitInfo.ImpactPoint))
    local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
    local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    HudMessageCenterVM:AddLocationHurtDamage(HitInfo.ImpactPoint, Damage, "Normal", "Fire", "")
end

function MonsterUIComponent:InitDamageNumberWidgetPool()
    for Idx = 1, self.PoolSize do
        self.DamageNumberWidgetPool:Add(UE.UWidgetBlueprintLibrary.Create(self.actor, self.DamageNumberWidgetClass))
    end
end

function MonsterUIComponent:GetDamageNumberWidgetFromPool()
    self.PoolIdx = self.PoolIdx + 1
    if self.PoolIdx > self.PoolSize then
        self.PoolIdx = 1
    end

    return self.DamageNumberWidgetPool:Get(self.PoolIdx)
end

function MonsterUIComponent:ShowDamageNumber(Damage, ImpactPoint)
    local DamageNumberWidget = self:GetDamageNumberWidgetFromPool()
    DamageNumberWidget.DamageNumber = math.abs(Damage)
    if DamageNumberWidget.DamageNumber < 0.01 then
        return
    end
    
    local Color = UE.FLinearColor(1.0, 1.0, 1.0)
    if Damage < 0 then
        Color = UE.FLinearColor(0, 1.0, 0)
    end
    DamageNumberWidget:UpdateColor(Color)

    -- Set position
    if not ImpactPoint or UE.UKismetMathLibrary.Vector_IsNearlyZero(ImpactPoint) then
        ImpactPoint = self.actor:K2_GetActorLocation()
    end

    local ScreenPos = UE.FVector2D()
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self.actor:GetWorld(), 0)
    UE.UWidgetLayoutLibrary.ProjectWorldLocationToWidgetPosition(PlayerController, ImpactPoint, ScreenPos, false)
    DamageNumberWidget:SetPositionInViewport(ScreenPos, false)
    DamageNumberWidget:AddToViewport()
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
    UE.UWidgetLayoutLibrary.ProjectWorldLocationToWidgetPosition(PlayerController, self.actor:K2_GetActorLocation(), ScreenPos, false)
    DefendWidget:SetPositionInViewport(ScreenPos, false)
    DefendWidget:AddToViewport()
end

function MonsterUIComponent:ShowJudgeUI(bShow)
    -- if bShow then
    --     if not self.bJudgeWidgetShowing then
    --         self.JudgeWidget = UE.UWidgetBlueprintLibrary.Create(self.actor, self.actor.SkillComponent.JudgeUI, nil)
    --         local ViewPortSize = UE.UWidgetLayoutLibrary.GetViewportSize(self.actor)
    --         self.JudgeWidget:SetPositionInViewport(ViewPortSize/2, true)
    --         self.JudgeWidget.OwnerActor = self.actor
    --         self.JudgeWidget:AddToViewport()
    --         self.bJudgeWidgetShowing = true
    --     end
    -- else
    --     if self.JudgeWidget then
    --         self.JudgeWidget:RemoveFromViewport()
    --         self.JudgeWidget = nil
    --         self.bJudgeWidgetShowing = false
    --     end
    -- end
end

function MonsterUIComponent:Destroy()
    Super(MonsterUIComponent).Destroy(self)

    self:ShowJudgeUI(false)
end

return MonsterUIComponent
