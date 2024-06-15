require "UnLua"

local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local utils = require("common.utils")
local SkillUtils = require("common.skill_utils")

local UIComponent = Component(ComponentBase)
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local decorator = UIComponent.decorator
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local UIEventDef = require('CP0032305_GH.Script.ui.ui_event.ui_event_def')

function UIComponent:ReceiveBeginPlay()
    Super(UIComponent).ReceiveBeginPlay(self)

    if not self.actor:IsClient() then
        self.actor:RemoveBlueprintComponent(self)
        return
    end
    -- self:InitDamageNumberWidgetPool()
end

function UIComponent:InitUI()
    G.log:debug("santi", "Init UI.")

    self.ShouldUpdateWSButtonUI = false
    self.ShouldUpdateRushButtonUI = false
end

decorator.message_receiver()
function UIComponent:OnPostSkillInitialized()
    if self.actor:IsPlayer() then
        self:InitUI()
        self:InitStateUI()
    end
end

decorator.message_receiver()
function UIComponent:BeforeSwitchOut()
    --2024/1/31 注释废弃代码 崔智源
    --[[if self.actor.PlayerWidget then
        self.actor.PlayerWidget:SetVisibility(2)
    end--]]
end

decorator.message_receiver()
function UIComponent:AfterSwitchIn()
    --[[if self.actor.PlayerWidget then
        self.actor.PlayerWidget:SetVisibility(0)
    end--]]
end

function UIComponent:InitStateUI()
    --[[local Widget = UE.UWidgetBlueprintLibrary.Create(self.actor, self.StateWidgetClass)
    Widget.Player = self.actor
    self.actor.PlayerWidget = Widget--]]
end

function UIComponent:ShowPlayerHp(UIObj)
    local level = "99"
    local dyingLimit = 50

    local currentHealth = self:GetOwner():GetHealthCurrentValue()
    local healthLimit = self:GetOwner():GetMaxHealthCurrentValue()
    ---@type WBP_HUD_PlayerHP_Item_C
    self.PlayerHp = UIObj
    UIObj:OnShow(level, dyingLimit, currentHealth, healthLimit)
end

function UIComponent:InitPowerVal()
    G.log:debug("zys", "UIComponent:ShowPowerVal()")
    local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
    if not Player then
        return false
    end
    local ASC = G.GetHiAbilitySystemComponent(Player)
    if not ASC then
        return false
    end
    if not SkillUtils.GetAttribute or not SkillUtils.AttrNames.Power then
        return
    end
    local Power = SkillUtils.GetAttribute(ASC, SkillUtils.AttrNames.Power)
    local Max = SkillUtils.GetAttribute(ASC, SkillUtils.AttrNames.MaxPower)
    local playerskillvm = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.PlayerSkillVM.UniqueName)
    if Power then
        playerskillvm:UpdatePowerVal(Power.CurrentValue)
    end
    if Max then
        playerskillvm:UpdatePowerVal(Max.CurrentValue)
    end
    G.log:debug("zys", "UIComponent:ShowPowerVal() succeed to init power value")
end

decorator.message_receiver()
function UIComponent:OnReceiveTick(DeltaSeconds)
    self.index = self.index or 0
    self.index = self.index + 1
    if self.index < 10 then
        return
    end
    -- if not self.IsInit then
    --     self:InitPlayerHp()
    --     self.IsInit = true
    -- end
    if not self.actor:IsPlayer() then
        return
    end

    -- self:UpdateHPGradually()
    -- self:UpdateWSProgressBar()
    self:UpdateWSButtonUI()
    -- if SkillUtils.AttrNames.Power and SkillUtils.AttrNames.MaxPower then
    --     local ASC           = G.GetHiAbilitySystemComponent(self.actor)
    --     local SkillUtils    = require('common.skill_utils')
    --     local power         = SkillUtils.GetAttribute(ASC, SkillUtils.AttrNames.Power).CurrentValue
    --     local powerMax      = SkillUtils.GetAttribute(ASC, SkillUtils.AttrNames.MaxPower).CurrentValue
    --     local playerskillvm = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.PlayerSkillVM.UniqueName)
    --     playerskillvm:UpdateSuperSkill(power, powerMax)
    -- end
end

decorator.message_receiver()
function UIComponent:OnRepNewSkill(SkillID, SkillType)
    local SkillClient = self.actor.SkillComponent
    --2024/1/26 注释废弃代码 崔智源
    --[[if SkillUtils.IsBlockSkill(SkillType) and SkillClient.SkillDriver:GetBlockManager() then
        self.actor.PlayerWidget.Skill_Block:SetVisibility(0)
    elseif SkillUtils.IsSecondarySkill(SkillType) and SkillClient.SkillDriver:GetSecondarySkillManager() then
        self.actor.PlayerWidget.Skill_Small:SetVisibility(UE.ESlateVisibility.Visible)
    elseif SkillUtils.IsSuperSkill(SkillType) and SkillClient.SkillDriver:GetSuperManager() then
        self.actor.PlayerWidget.Skill_Big:SetVisibility(UE.ESlateVisibility.Visible)
    end]]--
end


function UIComponent:SwitchWSButton_1()
end

function UIComponent:SwitchWSButton_2()
end

--2024/1/26 注释废弃代码 崔智源
--[[function UIComponent:DelaySet_Image_Block_StrikeBack_UnVisibility()
    self.actor.PlayerWidget.Image_Block_StrikeBack:SetVisibility(2)
end--]]

function UIComponent:UpdateWSButtonUI()
end

function UIComponent:UpdateHPGradually()
end

decorator.message_receiver()
function UIComponent:OnHealthChanged(NewValue, OldValue)
    local PlayerController = UE.UGameplayStatics.GetPlayerState(G.GameInstance:GetWorld(), 0):GetPlayerController()
    PlayerController:SendMessage("OnRoleHealthChanged", self.actor.CharType, NewValue)
end

decorator.message_receiver()
function UIComponent:OnSuperPowerChanged(NewValue, OldValue)
    local PlayerController = UE.UGameplayStatics.GetPlayerState(G.GameInstance:GetWorld(), 0):GetPlayerController()
    PlayerController:SendMessage("OnRoleSuperPowerChanged", self.actor.CharType, NewValue)
end

decorator.message_receiver()
function UIComponent:OnDead()
    if self.actor:IsPlayer() then
        ---@type WBP_HUD_PlayerHP_Item_C
        self.PlayerHP = UIManager:OpenUI(UIDef.UIInfo.UI_MainInterfaceHUD).WBP_HUD_PlayerHP_Item
        if self.PlayerHP then
            self.PlayerHP:SetPlayerHealth(0)
        end
    end
end

decorator.message_receiver()
function UIComponent:OnStrikeBackQteScheduleChanged(CurValue, MaxValue, WithStandTotalTime, ExtremeWithStandTotalTime)
    if not self.actor:IsPlayer() then
        return
    end

    local function _UpdateSanDuanTiao(CurValue)
        if CurValue == -1 then
            self.actor.PlayerWidget:OnSanDuanTiaoDisAppear()

            -- End All Loop
            self.actor.PlayerWidget.SanDuanTiao_Point1:EndAllLoop()
            self.actor.PlayerWidget.SanDuanTiao_Point2:EndAllLoop()
            self.actor.PlayerWidget.SanDuanTiao_Point3:EndAllLoop()
            self.actor.PlayerWidget.SanDuanTiao_Point1:Reset()
            self.actor.PlayerWidget.SanDuanTiao_Point2:Reset()
            self.actor.PlayerWidget.SanDuanTiao_Point3:Reset()
            self.actor.PlayerWidget.SanDuanTiao_BG_1:SetVisibility(2)
        elseif CurValue == 0 then
            self.actor.PlayerWidget:OnSanDuanTiaoAppear()
        else
            if CurValue == 1 then
                self.actor.PlayerWidget.SanDuanTiao_Point1:OnActive()
            elseif CurValue == 2 then
                self.actor.PlayerWidget.SanDuanTiao_Point2:OnActive()
            elseif CurValue == 3 then
                self.actor.PlayerWidget.SanDuanTiao_Point3:OnActive()

                -- All Loop
                self.actor.PlayerWidget.SanDuanTiao_Point1:OnAllLoop()
                self.actor.PlayerWidget.SanDuanTiao_Point2:OnAllLoop()
                self.actor.PlayerWidget.SanDuanTiao_Point3:OnAllLoop()
                self.actor.PlayerWidget.SanDuanTiao_BG_1:SetVisibility(0)

                -- 美术同学要求加个延时
                -- UE.UKismetSystemLibrary.K2_SetTimerDelegate({self.actor, self.actor.SwitchWSButton_1}, 0.3, false)
                UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, self.SwitchWSButton_1 }, 0.3, false)
            end
        end
    end

    if CurValue == -1 then
        -- self.actor.PlayerWidget.WithStand:SetVisibility(2)
        self.WithStandStartTime = nil
    elseif CurValue == 0 then
        -- self.actor.PlayerWidget.WithStand:SetVisibility(0)
        self.WithStandStartTime = UE.UKismetMathLibrary.Now()
        self.WithStandTotalTime = WithStandTotalTime
        self.ExtremeWithStandTotalTime = ExtremeWithStandTotalTime
    end

    -- _UpdateSanDuanTiao(CurValue)
end

decorator.message_receiver()
function UIComponent:OnDamaged(Damage, HitInfo, InstigatorCharacter, DamageCauser, DamageAbility, DamageGESpec)
    G.log:debug("1111santi", "%s OnDamaged, Ability: %s, damage: %f, bBlockingHit: %s, ImpactPoint: %s",
        G.GetObjectName(self.actor), G.GetDisplayName(DamageAbility), Damage,
        tostring(HitInfo.bBlockingHit), tostring(HitInfo.ImpactPoint))
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    if Damage == 0 then
        return
    end
    if Damage < 0 then
        local currentHealth = self:GetOwner():GetHealthCurrentValue()
        local healthLimit = self:GetOwner():GetMaxHealthCurrentValue()
        if currentHealth == healthLimit then
            return
        end
        HudMessageCenterVM:AddActorHurtDamage(self.actor, math.abs(Damage), "Normal", Enum.Enum_DamageNumber.AddHealth, "", true)
        return
    end

    if HitInfo.bBlockingHit then
        HudMessageCenterVM:AddLocationHurtDamage(HitInfo.ImpactPoint, Damage, "Normal", Enum.Enum_DamageNumber.Normal, "",
            true)
    else
        HudMessageCenterVM:AddActorHurtDamage(self.actor, Damage, "Normal", Enum.Enum_DamageNumber.Normal, "", true)
    end
end

decorator.message_receiver()
function UIComponent:OnManaChanged(NewValue, OldValue)
    if self.actor:IsPlayer() then
        self.actor.PlayerWidget:UpdateMana()
    end
end

decorator.message_receiver()
function UIComponent:OnStaminaChanged(NewValue, OldValue)
    local PlayerState = UE.UGameplayStatics.GetPlayerState(G.GameInstance:GetWorld(), 0)
    local ASC = PlayerState:GetPlayerController():K2_GetPawn():GetAbilitySystemComponent()
    local StaminaAttribute = SkillUtils.GetAttribute(ASC, SkillUtils.AttrNames.MaxStamina)
    if StaminaAttribute and StaminaAttribute.CurrentValue then
        self.MaxStamina = StaminaAttribute.CurrentValue
    end
    if self.MaxStamina then
        self.LastMaxStamina = self.MaxStamina
    end
    if self.LastMaxStamina and not self.MaxStamina then
        self.MaxStamina = self.LastMaxStamina
    end
    if self.MaxStamina then
        self.actor.BP_PlayerStaminaWidget:UpdateStamina(NewValue, OldValue, self.MaxStamina)
        self.LastMaxStamina = self.MaxStamina
    end
end

function UIComponent:HudMsgCenter()
    return ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
end

decorator.message_receiver()
function UIComponent:OnBuffAdded(Tag)
    G.log:debug("zys", 'UIComponent:OnBuffAdded(Tag)', GetTagName(Tag))
    -- TODO buff界面第一期仅处理瓦利大招buff或者仅处理配置表中的buff
    if GetTagName(Tag) == 'Ability.Buff.SuperSkill' then
        local BuffVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.SkillBuffVM.UniqueName)
        BuffVM:AddBuff(Tag, 'Ability.Buff.SuperSkill', '燃尽一切', 10, '瓦利的怒火难以自抑，将倾泻在所有敌人身上。在此期间瓦利的攻击会附带烈焰，对敌人造成更多的伤害')
    end
    -- G.log:debug("zys", 'UIComponent:OnBuffAdded(Tag)', GetTagName(Tag))
    -- local ArrGEHandle = self.actor.AbilitySystemComponent:GetActiveEffectsWithAllTags(UE.BlueprintGameplayTagLibrary.MakeGameplayTagContainerFromArray(UE.TArray(UE.GameplayTag):Add(Tag)))
    -- for i = 1, ArrGEHandle:Num() do
    --     local cd = ArrGEHandle:Get(i):GetActiveGameplayEffectRemainingDuration()
    --     return
    -- end
    -- if GetTagName(Tag) == 'Ability.Buff.SuperSkill' then
    --     local SuperSkillTag = UE.UHiGasLibrary.RequestGameplayTag(GetTagName(Tag))
    --     if self.actor.BuffComponent:HasBuff(SuperSkillTag) then
    --         UnLua.LogWarn("zys buff cd", self.actor.BuffComponent:GetBuffRemainingAndDuration(SuperSkillTag))
    --     end
    -- end

    -- 手动刷新一次技能界面
    local MainInterface = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
    if MainInterface then
        MainInterface:RefreshSkillPanel()
    end
end

decorator.message_receiver()
function UIComponent:OnBuffRemoved(Tag)
    G.log:debug("zys", 'UIComponent:OnBuffRemoved(Tag)', GetTagName(Tag))
    if GetTagName(Tag) == 'Ability.Buff.SuperSkill' then
        local BuffVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.SkillBuffVM.UniqueName)
        BuffVM:RemoveBuff(Tag)
    end

    -- 手动刷新一次技能界面
    local MainInterface = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
    if MainInterface then
        MainInterface:RefreshSkillPanel()
    end
end

decorator.message_receiver()
function UIComponent:OnPowerChanged(NewValue, OldValue)
    G.log:debug("zys", table.concat({ 'UIComponent:OnPowerChanged(NewValue, OldValue) ', NewValue, ',', OldValue }))
    local playerskillvm = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.PlayerSkillVM.UniqueName)
    playerskillvm:UpdatePowerVal(NewValue)
end

decorator.message_receiver()
function UIComponent:OnMaxPowerChanged(NewValue, OldValue)
    G.log:debug("zys", table.concat({ 'UIComponent:OnMaxPowerChanged(NewValue, OldValue) ', NewValue, ',', OldValue }))
    local playerskillvm = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.PlayerSkillVM.UniqueName)
    playerskillvm:UpdateMaxPowerVal(NewValue)
end

decorator.message_receiver() -- OldPlayer
function UIComponent:OnRecieveMessageBeforeSwitchOut()
    UIManager.UINotifier:UINotify(UIEventDef.UnloadPlayerActor)
end

decorator.message_receiver() -- NewPlayer After SwitchIn
function UIComponent:AfterSwitchIn(OldPlayer, NewPlayer, bInBattle, bInExtreme, bInAir)
    UIManager.UINotifier:UINotify(UIEventDef.LoadPlayerActor)
end

decorator.message_receiver()
function UIComponent:OnRep_Health(NewAttr, OldAttr)
    local CurHp = NewAttr.CurrentValue
    if self.actor:IsPlayer() then
        ---@type WBP_HUD_PlayerHP_Item_C
        self.PlayerHP = UIManager:OpenUI(UIDef.UIInfo.UI_MainInterfaceHUD).WBP_HUD_PlayerHP_Item
        if self.PlayerHP then
            self.PlayerHP:SetPlayerHealth(CurHp)
        end
    end
    self:ShowHP()
end

decorator.message_receiver()
function UIComponent:OnRep_MaxHealth(NewAttr, OldAttr)
    self.healthLimit = NewAttr.CurrentValue
    self:ShowHP()
end

--复活后前台角色被切入，通知ui
decorator.message_receiver()
function UIComponent:ReceiveBeforeSwitchIn()
    local PlayerController = UE.UGameplayStatics.GetPlayerState(G.GameInstance:GetWorld(), 0):GetPlayerController()
    PlayerController:SendMessage("ReceiveBeforeSwitchIn", self.actor.CharType)
end

---通知uicomponent，可以更新squaditem
decorator.message_receiver()
function UIComponent:OnClientAvatarReady()
    local attributeSets = {}
    local currentHealth = self:GetOwner():GetHealthCurrentValue()
    local healthLimit = self:GetOwner():GetMaxHealthCurrentValue()
    local currentSuperPower = self:GetOwner():GetSuperPowerCurrentValue()
    local superPowerLimit = self:GetOwner():GetMaxSuperPowerCurrentValue()
    attributeSets.Health = currentHealth / healthLimit
    attributeSets.SuperPower = currentSuperPower / superPowerLimit

    local PlayerController = UE.UGameplayStatics.GetPlayerController(self:GetWorld(), 0)
    --PlayerController:InitSquadListUI(self.actor.CharType, attributeSets)
    PlayerController:SendMessage("InitSquadListUI", self.actor.CharType, attributeSets)
end

function UIComponent:ShowHP()

end

return UIComponent
