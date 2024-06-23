local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local character_table = require("common.data.hero_initial_data").data

local UIComponent = Component(ComponentBase)
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local decorator = UIComponent.decorator
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIEventDef = require('CP0032305_GH.Script.ui.ui_event.ui_event_def')
local DebugWidget = nil
local TipsUtil = require("CP0032305_GH.Script.common.utils.tips_util")

local DEBUG_INPUT_TAG ="DEBUG_INPUT_TAG"
local UI_INPUT_TAG ="UI_INPUT_TAG"
function UIComponent:ReceiveBeginPlay()
    Super(UIComponent).ReceiveBeginPlay(self)

    if not self.actor:IsClient() and not UE.UKismetSystemLibrary.IsStandalone(self) then
        self.actor:RemoveBlueprintComponent(self)
        return
    end
    self.ShouldUpdateTeamList = false
    UIManager.UINotifier:UINotify(UIEventDef.LoadPlayerController)
end

decorator.message_receiver()
function UIComponent:F12_Pressed()
    local controller = UE.UGameplayStatics.GetPlayerController(self.actor:GetWorld(), 0)
    if controller:IsInputKeyDown(UE.EKeys.LeftShift) then
        if not self.actor.UI_Login then
            self.actor.UI_Login = UE.UWidgetBlueprintLibrary.Create(self.actor, self.LoginWidgetClass)
            self.actor.UI_Login:AddToViewport()
            return
        end
        if not self.actor.UI_Login:IsVisible() then
            self.actor.UI_Login:SetVisibility(0)
            self.actor.UI_Login:CaptureMouse(true)
        else
            self.actor.UI_Login:SetVisibility(2)
            self.actor.UI_Login:CaptureMouse(false)
        end
    end
end

function UIComponent:InitLoginUI()
    if not self.actor.UI_Login then
        self.actor.UI_Login = UE.UWidgetBlueprintLibrary.Create(self.actor, self.LoginWidgetClass)
        self.actor.UI_Login:AddToViewport()
    end
    self.actor.UI_Login:SetVisibility(2)
    if self.actor.UI_Login:IsEditor() == false then
        local LevelName = tostring(UE.UGameplayStatics.GetCurrentLevelName(self.actor:GetWorld()))
        local DefaultName = tostring(self.actor.UI_Login:GetGameDefaultMap())
        if (DefaultName:sub(-LevelName:len()) == LevelName) then
            if UE.UKismetSystemLibrary.IsStandalone(self.actor:GetWorld()) == true then
                self.actor.UI_Login:ConnectServerLocal()
            end
        end
    end
end

function UIComponent:InitControllerUI()
end
function UIComponent:RegisterUIIMC(RegisterKey,EnableIMCKeys,MaskIMCs)
    self.actor:SendMessage("RegisterIMC", RegisterKey, EnableIMCKeys, MaskIMCs)
end

function UIComponent:UnRegisterUIIMC(RegisterKey)
    self.actor:SendMessage("UnregisterIMC", RegisterKey)
end

decorator.message_receiver()
function UIComponent:PostBeginPlay()
    self:InitLoginUI()
    UIManager:DefaultOpenUI()
    UIManager:InitUIIMC()
    if not G.is_publish then
        self.actor:SendMessage("RegisterIMC", DEBUG_INPUT_TAG, {"Debug",}, {})
    end
end


function UIComponent:ReceiveEndPlay()
    if self.actor == nil then
        return
    end
    if not G.is_publish then
        self.actor:SendMessage("UnregisterIMC", DEBUG_INPUT_TAG)
    end
end
function UIComponent:TryShowTeamListUI(UIObj)
    self.teamList = UIObj
    self.teamList:OnShow(1, self.actor.SwitchPlayerCD, self.actor)
end

decorator.message_receiver()
function UIComponent:OnReceiveTick(DeltaSeconds)
end

function UIComponent:TryShowSkillUI()
    -- self.skillUI = UIManager:OpenUI(UIDef.UIInfo.UI_SkillState)
end

function UIComponent:TryHideeSkillUI()
    if self.skillUI then
        self.skillUI:HideSkillState()
    end
end

decorator.message_receiver()
function UIComponent:OnSwitchPlayerSuccess(OldCharType, NewCharType)
    self:ClearShowTimerHandle()
    
    -- @Augustus du, 延迟一帧触发UI刷新，防止时序问题
    UE.UKismetSystemLibrary.K2_SetTimerForNextTickDelegate({self.actor, function()
        if OldCharType - NewCharType == 0 then
            return
        end
        local teamListIndex = self:Type2idx(NewCharType)
        local MainInterface = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
        if MainInterface and MainInterface.OnSwitchPlayer then

            MainInterface:OnSwitchPlayer(NewCharType, OldCharType,teamListIndex)
        else
            G.log:debug("zys", "failed to forward switch player msg to main interface")
        end
    end})

    local CallBack = function()
        local level = "99"
        local dyingLimit = 50
        local currentHealth = self.actor:K2_GetPawn():GetHealthCurrentValue()
        local healthLimit = self.actor:K2_GetPawn():GetMaxHealthCurrentValue()
        local hp = UIManager:GetUIInstance(UIDef.UIInfo.UI_MainInterfaceHUD.UIName).WBP_HUD_PlayerHP_Item
        if hp then
            hp:OnSwitchPlayerHp(level, dyingLimit, currentHealth, healthLimit)
        end
    
    end

    self.ShowTimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, CallBack}, 0.1, false)

    ---@type HudStaminaVM
    local HudStaminaVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudStaminaVM.UniqueName)
    local Player = G.GetPlayerCharacter(self, 0)
    if Player and UE.UKismetSystemLibrary.IsValid(Player) then
        local CurrentStamina = Player.BP_PlayerStaminaWidget:GetWidget()
        if CurrentStamina then
            HudStaminaVM:SetNewStamina(CurrentStamina)
        end
    end
end

function UIComponent:ClearShowTimerHandle()
    if self.ShowTimerHandle then
        UE.UKismetSystemLibrary.K2_ClearTimerDelegate(self, self.ShowTimerHandle)
        self.ShowTimerHandle = nil
    end
end

function UIComponent:Type2idx(CharType)
    local controller = UE.UGameplayStatics.GetPlayerController(self.actor:GetWorld(), 0)
    return controller.ControllerSwitchPlayerComponent.TeamInfo:Find(CharType)
end
function UIComponent:UpdateSwitchPlayerTeamList()

end

decorator.message_receiver()
function UIComponent:OnRoleHealthChanged(CharType, CurValue)
    local MaxValue = self.actor:K2_GetPawn():GetMaxHealthCurrentValue()
    self.teamList:OnSquadListRoleHealthChanged(self:Type2idx(CharType), CurValue / MaxValue)
end

decorator.message_receiver()
function UIComponent:OnRoleSuperPowerChanged(CharType, CurValue)
    local MaxValue = self.actor:K2_GetPawn():GetMaxSuperPowerCurrentValue()
    self.teamList:OnSquadListSuperPowerChanged(self:Type2idx(CharType), CurValue / MaxValue)
end

decorator.message_receiver()
function UIComponent:OnRoleDead(CharType)
    self.teamList:OnSquadListRoleDead(self:Type2idx(CharType))
end

function UIComponent:GetCharIdxByCharType(CharType)
    -- TODO
    return CharType - 1
end

function UIComponent:GetUICompoent()
    return UIComponent
end

function UIComponent:IsLuaDebugWidget()
    if not DebugWidget then
        return false
    else
        return true
    end
end

decorator.message_receiver()
function UIComponent:CallLuaDebugWidget()
    G.log:debug("yj", "UIComponent:CallLuaDebugWidget %s", self.actor.LuaDebugWidget)
    if not self.actor.LuaDebugWidget then
        self.actor.LuaDebugWidget = UE.UWidgetBlueprintLibrary.Create(self.actor, self.LuaDebugWidgetClass)
        self.actor.LuaDebugWidget:AddToViewport(2000) -- LuaDebugWidget的Order最高，避免点击到其它UI导致回到游戏中
        self.actor.LuaDebugWidget:SetVisibility(0)
        DebugWidget = self.actor.LuaDebugWidget

        utils.SetPlayerInputEnabled(self.actor:GetWorld(), false)
    else
        self.actor.LuaDebugWidget:SetVisibility(2)
        self.actor.LuaDebugWidget:RemoveFromViewport()
        self.actor.LuaDebugWidget:RemoveFromParent()
        self.actor.LuaDebugWidget = nil
        DebugWidget = self.actor.LuaDebugWidget

        utils.SetPlayerInputEnabled(self.actor:GetWorld(), true)
    end
end

decorator.message_receiver()
function UIComponent:OnPrintChange(Result)
    self.actor.LuaDebugWidget:PrintOnScreen(Result)
end

decorator.message_receiver()
function UIComponent:Tab_Pressed(Pressed)
    -- Button TAB Pressed
    if self.actor.LuaDebugWidget and self.actor.LuaDebugWidget:IsVisible() then
        self.actor.LuaDebugWidget:SelectNextCmd()
    end
end

decorator.message_receiver()
function UIComponent:MouseWheelUp()
    if self.actor.LuaDebugWidget and self.actor.LuaDebugWidget:IsVisible() then
        self.actor.LuaDebugWidget:SelectPreCmd()
    end
end

decorator.message_receiver()
function UIComponent:MouseWheelDown()
    if self.actor.LuaDebugWidget and self.actor.LuaDebugWidget:IsVisible() then
        self.actor.LuaDebugWidget:SelectNextCmd()
    end
end

--decorator.message_receiver()
--function UIComponent:F_Pressed()
--    G.log:debug("zsf", "F_Pressed")
--    if self.actor.ui_interact then
--        if self.actor.ui_interact.TrapActor then
--            G.log:debug("zsf", "Interact with : %s", self.actor.ui_interact.TrapActor:GetDisplayName())
--        end
--    end
--end

decorator.message_receiver()
function UIComponent:AddInitationScreenUI(TrapActor)
    if not self.actor.ui_interact then
        self.actor.ui_interact = UE.UWidgetBlueprintLibrary.Create(self.actor, self.InteractWidgetClass)
        self.actor.ui_interact:AddToViewport()
    end
    if self.actor.ui_interact then
        local ObjLocation = TrapActor:K2_GetActorLocation()
        local ScreenPos = UE.FVector2D()
        local PlayerController = UE.UGameplayStatics.GetPlayerController(self.actor:GetWorld(), 0)
        UE.UWidgetLayoutLibrary.ProjectWorldLocationToWidgetPosition(PlayerController, ObjLocation, ScreenPos, false)
        -- TODO(dougzhang): 可以触发多个交互物, 创建列表
        self.actor.ui_interact.btn_interact:SetRenderTranslation(UE.FVector2D(ScreenPos.X, ScreenPos.Y))
        self.actor.ui_interact.bActive = true
        self.actor.ui_interact.InteractedItem = TrapActor
    end
end

decorator.message_receiver()
function UIComponent:RemoveInitationScreenUI(TrapActor)
    if self.actor.ui_interact then
        self.actor.ui_interact:RemoveFromParent()
        self.actor.ui_interact.bActive = false
        self.actor.ui_interact = nil
    end
end

decorator.message_receiver()
function UIComponent:HudMsgCenter()
    return ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
end

decorator.message_receiver()
function UIComponent:OpenMadukLightPanel()
    G.log:debug('zys', 'UIComponent:OpenMadukLightPanel')
end

decorator.message_receiver()
function UIComponent:CloseMadukLightPanel()
    G.log:debug('zys', 'UIComponent:CloseMadukLightPanel')
end

decorator.message_receiver()
function UIComponent:AllPlayerDead(DeadPoint, DeadReasonInfo)
    if not UE.UKismetSystemLibrary.IsServer(self) then
        UIManager:OpenUI(UIDef.UIInfo.UI_CharacterDeath, DeadPoint, DeadReasonInfo)
    end
end

decorator.message_receiver()
function UIComponent:ReceiveBeforeSwitchIn(charType)
    local teamListIndex = self:Type2idx(charType)
    local MainInterface = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
    if MainInterface and MainInterface.OnSwitchPlayer then
        MainInterface:OnSwitchPlayer(charType, nil, teamListIndex)
    else
        G.log:debug("zys", "failed to forward switch player msg to main interface")
    end
end

--超级登场技能QTE显示
decorator.message_receiver()
function UIComponent:ShowQTE(CharInd, QTETime)
    G.log:debug("shiniingliu", "SendMessage:ShowQTE CharInd: %s, QTETime: %s",CharInd, QTETime)
    if not self.SuperAppearanceSkillHud then
        self.SuperAppearanceSkillHud = UIManager:OpenUI(UIDef.UIInfo.UI_SuperAppearanceSkill, CharInd, QTETime)
    else
        self.SuperAppearanceSkillHud:ShowNextQTE(CharInd, QTETime)
    end
end

--超级登场技能QTE关闭
decorator.message_receiver()
function UIComponent:EndQTE()
    if self.SuperAppearanceSkillHud then
        self.SuperAppearanceSkillHud:EndSuperAppearanceSkill()
        self.SuperAppearanceSkillHud = nil
    end
end

decorator.message_receiver()
function UIComponent:DoSuperAppearQTE()
    if self.JudgeWidget then
        UIManager:CloseUI(self.JudgeWidget, true)
        self.JudgeWidget = nil
    end
end

local VehicleState =
{
    None = 1,               -- 无
    SingleBoard = 2,              -- 单板滑板
    DoubleBoard = 3,             -- 双板滑板
    UnavailableByArea = 4,             -- 该区域禁止使用
    UnavailableByPlayer = 5,             -- 该角色禁止使用
    UnavailableBySpline = 6,             -- 该角色禁止使用
}
--滑板状态切换
decorator.message_receiver()
function UIComponent:VehicleStateChange(state)
    local MainInterface = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
    if MainInterface then
        if state == VehicleState.None then
            MainInterface:CloseVehicleUI()
            self:EnableSwitchPlayerUI(true)
            --隐藏单双板，恢复区域能力显示，恢复切人禁用
        elseif state == VehicleState.SingleBoard then
            --播放滑板按钮出现动画，或是切换动画，没禁人的禁用
            MainInterface:VehicleStateChange(true)
            self:EnableSwitchPlayerUI(false)
        elseif state == VehicleState.DoubleBoard then
            --播放滑板按钮出现动画，或是切换动画，没禁人的禁用
            MainInterface:VehicleStateChange(false)
            self:EnableSwitchPlayerUI(false)
        elseif state == VehicleState.UnavailableByArea then
            TipsUtil.ShowCommonTips("此处无法使用滑板")
        elseif state == VehicleState.UnavailableByPlayer then
            TipsUtil.ShowCommonTips("该角色无法召唤滑板")
        elseif state == VehicleState.UnavailableBySpline then
            TipsUtil.ShowCommonTips("该角色无法召唤滑板滑行")
            --todo 待添加常量表
        end
    else
        G.log:debug("shiniingliu", "failed to msg to main interface")
        return
    end
end

--禁用切人ui
function UIComponent:EnableSwitchPlayerUI(bEnable)
    self.teamList:EnableSwitchPlayerUI()
end

--拾取道具，通知hud显示放置按钮
decorator.message_receiver()
function UIComponent:ShowPlacingBtn(bShowPlacingBtn)
    local MainInterface = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
    if MainInterface then
        MainInterface:ShowPlacingBtn(bShowPlacingBtn)
    end
   
    self.teamList:EnableSwitchPlayerUI()
end

decorator.message_receiver()
function UIComponent:InitSquadListUI(charType, attributeSets)
    if not self.teamList then
        if not self.teamListAttributeSets then
            self.teamListAttributeSets = {}
        end
        self.teamListAttributeSets[charType] = attributeSets
    else
        self.teamList:InitItemUI(self:Type2idx(charType), attributeSets)
    end
end

decorator.message_receiver()
function UIComponent:InitTeamListAttributeSets(index)
    local controller = UE.UGameplayStatics.GetPlayerController(self.actor:GetWorld(), 0)
    local charType = controller.ControllerSwitchPlayerComponent.TeamInfo[index]

    if charType then
        local attributeSets = self.teamListAttributeSets[charType]
        if attributeSets then
            self.teamList:InitItemUI(self:Type2idx(charType), attributeSets)
        end
    end
end

decorator.message_receiver()
function UIComponent:ShowJudgeUI(bShow, actor, judgeWidgetDuration)
    if self.JudgeWidget then
        if self.JudgeWidget:IsDestroying() or not self.JudgeWidget:IsValid() then
            self.JudgeWidget = nil
        end
    end
    if bShow then
        if not self.JudgeWidget then
            self.JudgeWidget = UIManager:OpenUI(UIDef.UIInfo.UI_Judge)
            if not self.JudgeWidget then
                G.log:debug("ShowJudgeUI", "create JudgeWidget fail.")
                return
            end
        end
        self.JudgeWidget:InitWidget(actor, judgeWidgetDuration)
    else
        if self.JudgeWidget then
            UIManager:CloseUI(self.JudgeWidget, true)
            self.JudgeWidget = nil
        end
    end
end

decorator.message_receiver()
function UIComponent:DoJudge()
    self:EndQTE()
end

--角色入战斗后，处理ui
decorator.message_receiver()
function UIComponent:HandleEnterBattleUI()
    G.log:info("UIComponent:OnEnterBattle", "HandleEnterBattleUI")

    if self.teamList then
        self.teamList:OnEnterBattle()
    end
end

--角色离开战斗后，处理ui
decorator.message_receiver()
function UIComponent:HandleLeaveBattleUI()
    G.log:info("UIComponent:OnLeaveBattle", "HandleLeaveBattleUI")
    if self.teamList then
        self.teamList:OnLeaveBattle()
    end
end

return UIComponent
