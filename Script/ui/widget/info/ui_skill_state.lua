--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local InputDef = require('CP0032305_GH.Script.common.input_define')
local UIWidgetBase = require('CP0032305_GH.Script.framework.ui.ui_widget_base')

local TIMER_INTERVAL = 0.1             -- timer的时间间隔

---@class WBP_HUD_SkillState : WBP_HUD_SkillState_C
---@field LastSkillMode number
---
---@type WBP_HUD_SkillState_C
local WBP_HUD_SkillState = Class(UIWindowBase)

WBP_HUD_SkillState.SkillSlotDef = {
    Super       = 1,
    Secondary   = 2,
    Right       = 3,
}

WBP_HUD_SkillState.SkillStateDef = {
    Skill       = 1,
    Copyer      = 2,
    AreaAbility = 3,
    Maduk       = 4,
}

--function WBP_HUD_SkillState:Initialize(Initializer)
--end

--function WBP_HUD_SkillState:PreConstruct(IsDesignTime)
--end

---@param self WBP_HUD_SkillState
local function OnCopyerExitClicked(self)
    G.log:debug('zys', '<<<<<<OnCopyerExitClicked... 关闭复制器')
    local Player = G.GetPlayerCharacter(UIManager.GameWorld, 0)
    Player:SendMessage("CloseCopyerPanel")
end

---@param self WBP_HUD_SkillState
local function OnCopyerLightClicked(self)
    G.log:debug('zys', '<<<<<<OnCopyerLightClicked...吸收能力')
    if self.CopyerUseBtnCB then
        self.CopyerUseBtnCB()
    end
end

---@param self WBP_HUD_SkillState
local function OnAreaAbilityExitClicked(self)
    G.log:debug('zys', '<<<<<<OnAreaAbilityExitClicked... 关闭区域能力')
    local Player = G.GetPlayerCharacter(UIManager.GameWorld, 0)
    Player:SendMessage("CloseAreaAbilityPanel")
end

---@param self WBP_HUD_SkillState
local function OnAreaAbilityLightClicked(self)
    G.log:debug('zys', '<<<<<<OnAreaAbilityLightClicked... 对他人使用区域能力')
    if self.AreaAbilityUseBtnCB then
        self.AreaAbilityUseBtnCB()
    end
end

---@param self WBP_HUD_SkillState
local function OnAreaAbilitySelfUseClicked(self)
    G.log:debug('zys', '<<<<<<OnAreaAbilitySelfUseClicked... 对自己使用区域能力')
    if self.AreaAbilitySelfBtnCB then
        self.AreaAbilitySelfBtnCB()
    end
end

---@param self WBP_HUD_SkillState
local function OnMadukExitClicked(self)
    G.log:debug('zys', '<<<<<<OnAreaAbilitySelfUseClicked... 关闭马杜克灯界面')
    local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)
    if self.MadukCloseBtnCB then
        self.MadukCloseBtnCB()
    end
    AreaAbilityVM:CloseMadukPanel()
end

---@param self WBP_HUD_SkillState
local function OnMadukLightClicked(self)
    G.log:debug('zys', '<<<<<<OnAreaAbilitySelfUseClicked... 使用马杜克灯')
    if self.MadukUseBtnCB then
        self.MadukUseBtnCB()
    end
end

---@param self WBP_HUD_SkillState
local function BuildWidgetProxy(self)
    ---@type UImageProxy
    self.Img_LightWaveProxy = WidgetProxys:CreateWidgetProxy(self.Img_LightWave)
end

---@param self WBP_HUD_SkillState
local function HasAnyAnimPlaying(self)
    if self:IsAnimationPlaying(self.DX_SkillIn) then
        return true
    elseif self:IsAnimationPlaying(self.DX_SkillOut) then
        return true
    end
    return false
end

local function OnSuperBtnClicked(self)
    local Player = G.GetPlayerCharacter(self, 0)
    if Player then
        Player:SendMessage("SuperSkill")
    end
end

local function OnSecondaryBtnClicked(self)
    local Player = G.GetPlayerCharacter(self, 0)
    if Player then
        Player:SendMessage("SecondarySkill")
    end
end

local function OnRightBtnClicked(self)
    local Player = G.GetPlayerCharacter(self, 0)
    if Player then
        local InputComponent = Player:_GetComponent("BP_InputComponent", false)
        if InputComponent then
            if self.MakeInputActionValue then
                InputComponent:AimAction(UE.UEnhancedInputLibrary.Conv_InputActionValueToBool(self:MakeInputActionValue()))
            else
                G.log:debug('zys', 'block skill not found self.MakeInputActionValue')
            end
        else
            G.log:debug('zys', 'block skill not found input component')
        end
    else
        G.log:debug('zys', 'block skill not found player')
    end
end


function WBP_HUD_SkillState:OnConstruct()
    BuildWidgetProxy(self)

    self.ComBtnBig.OnClicked:Add(self, OnSuperBtnClicked)
    self.ComBtnSmall.OnClicked:Add(self, OnSecondaryBtnClicked)
    self.ComBtnBlock.OnClicked:Add(self, OnRightBtnClicked)

end

function WBP_HUD_SkillState:Destruct()
    self.ComBtnSmall.OnClicked:Remove(self, OnSecondaryBtnClicked)
    self.ComBtnBlock.OnClicked:Remove(self, OnRightBtnClicked)
end

--- 播放界面的入场出场动画
---@param bIn boolean 是否是界面入场动画
function WBP_HUD_SkillState:PlayInOutAnim(bIn)
    ---@type UWidgetAnimation
    local CurAnim = bIn and self.DX_SkillIn or self.DX_SkillOut
    self:PlayAnimation(CurAnim, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function WBP_HUD_SkillState:OnShow()
    G.log:debug('zys', table.concat({'WBP_HUD_SkillState:OnShow()', debug.traceback()}))
    if not self.TimerHandle then
        ---@type FTimerHandle
        self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.TimerLoop}, TIMER_INTERVAL, true)
    end
    self:StopAnimationsAndLatentActions()
    self.LastSkillMode = -1
    self:ShowSkillState()
    self:InitWidget()
    -- RefreshSkillPanel(self, 0)
    self:PlayInOutAnim(true)
    self:RefreshPlayerSkillInfo()
end

function WBP_HUD_SkillState:TimerLoop()
    for i = 1, 3 do
        self['WBP_HUD_SkillState_Item_0' .. i]:TimerLoop()
    end
end

function WBP_HUD_SkillState:OnHide()
    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.TimerHandle)
    self.TimerHandle = nil
    if UE.UKismetSystemLibrary.K2_IsValidTimerHandle(self.TimerHandle) then
        G.log:debug("zys", 'failed to invalidate timer handle !')
    end

    UIManager:UnRegisterPressedKeyDelegate(self)
    UIManager:UnRegisterReleasedKeyDelegate(self)
    self:PlayInOutAnim(false)
end

-- function WBP_HUD_SkillState:Tick(MyGeometry, InDeltaTime)
    -- RefreshSkillPanel(self, InDeltaTime)
-- end

function WBP_HUD_SkillState:OnSkillOut()
    -- self:CloseMyself()
end

function WBP_HUD_SkillState:RefreshPlayerSkillInfo()
    -- self['WBP_HUD_SkillState_Item_0' .. 1]:RefreshPlayerSkillInfo()
    -- self['WBP_HUD_SkillState_Item_0' .. 2]:RefreshPlayerSkillInfo()
    -- self['WBP_HUD_SkillState_Item_0' .. 3]:RefreshPlayerSkillInfo()
end

---@param NewCharType number
---@param OldCharType number
function WBP_HUD_SkillState:OnSwitchPlayer(NewCharType, OldCharType)
    self['WBP_HUD_SkillState_Item_0' .. 1]:OnSwitchPlayer(NewCharType, OldCharType)
    self['WBP_HUD_SkillState_Item_0' .. 2]:OnSwitchPlayer(NewCharType, OldCharType)
    self['WBP_HUD_SkillState_Item_0' .. 3]:OnSwitchPlayer(NewCharType, OldCharType)
end

---`brief`打开复制器接口,会由Interface界面点击和按键触发
function WBP_HUD_SkillState:OpenCopyerPanel()
    G.log:debug('zys', 'OpenCopyerPanel')
    if self.SkillState ~= self.SkillStateDef.Skill then
        return false
    end
    self.SkillState = self.SkillStateDef.Copyer
    self.Img_LightWave:SetBrushResourceObject(self.IconAbsorb)
    self.Img_LightEffect:SetVisibility(UE.ESlateVisibility.Hidden)
    self.Cvs_SelfUse:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.WBP_Tips_ControlTips:SetVisibility(UE.ESlateVisibility.Hidden)
    self.WBP_Button_Exit:UnbindAllDelegate()
    self.WBP_Button_SelfUse:UnbindAllDelegate()
    self.WBP_Button_LightWave:UnbindAllDelegate()
    self.WBP_Button_Exit.OnClicked:Add(self, OnCopyerExitClicked)
    self.WBP_Button_LightWave.OnClicked:Add(self, OnCopyerLightClicked)
    self:SetCopyerAimed(false)
    self:StopAnimationsAndLatentActions()

    self.AreaPower_Action_Button:PlayOutAnim(function()
        G.log:debug('OpenCopyerPanel', 'DX_SkillOut')

        local PlayAnimProxy = UE.UWidgetAnimationPlayCallbackProxy.CreatePlayAnimationProxyObject(
        UE.NewObject(UE.UUMGSequencePlayer), self, self.DX_SkillOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
        PlayAnimProxy.Finished:Add(self, function()
            self.Switcher_AtctionBar:SetActiveWidgetIndex(1)

            local PlayAnimProxy = UE.UWidgetAnimationPlayCallbackProxy.CreatePlayAnimationProxyObject(
            UE.NewObject(UE.UUMGSequencePlayer), self, self.DX_SkillIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
            PlayAnimProxy.Finished:Add(self, function()
                --self.AreaPower_Action_Button:ShowCancelImg()
            end)
        end)
    end)
    return true
end

function WBP_HUD_SkillState:BindCopyerUseBtnCB(fnCB)
    self.CopyerUseBtnCB = fnCB
end

function WBP_HUD_SkillState:BindCopyerCloseBtnCB(fnCB)
    self.CopyerCloseBtnCB = fnCB
end

---`brief`关闭复制器接口,会由Interface界面点击和按键触发
function WBP_HUD_SkillState:CloseCopyerPanel()
    G.log:debug('zys', 'CloseCopyerPanel')
    self.WBP_Button_Exit:UnbindAllDelegate()
    self.WBP_Button_SelfUse:UnbindAllDelegate()
    self.WBP_Button_LightWave:UnbindAllDelegate()
    self.SkillState = self.SkillStateDef.Skill
    --self.AreaPower_Action_Button:SetIcon(pic)

    local PlayAnimProxy = UE.UWidgetAnimationPlayCallbackProxy.CreatePlayAnimationProxyObject(
    UE.NewObject(UE.UUMGSequencePlayer), self, self.DX_SkillOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
    PlayAnimProxy.Finished:Add(self, function()
        self.Switcher_AtctionBar:SetActiveWidgetIndex(0)
        local PlayAnimProxy = UE.UWidgetAnimationPlayCallbackProxy.CreatePlayAnimationProxyObject(
            UE.NewObject(UE.UUMGSequencePlayer), self, self.DX_SkillIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
            PlayAnimProxy.Finished:Add(self, function()
                self.AreaPower_Action_Button:PlayInAnim(function()
                    self.AreaPower_Action_Button:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                end)
            end)
    end)
    self:SetCopyerAimed(true)
end

---`brief`设置区域能力瞄准了还是未瞄准
---@param bAim boolean
function WBP_HUD_SkillState:SetCopyerAimed(bAim)
    if self.SkillState == self.SkillStateDef.Maduk then
        self.Cvs_LightWave:SetRenderOpacity(1)
        return
    end
    self.Cvs_LightWave:SetRenderOpacity(bAim and 1 or 0.4)
end

function WBP_HUD_SkillState:SetCanExist(flag)
        self.Cvs_Exit:SetRenderOpacity(1)    
    self.Cvs_Exit:SetRenderOpacity(flag and 1 or 0.4)
    self.canExist = flag
end

---`brief`打开区域能力界面
function WBP_HUD_SkillState:OpenAreaAbilityPanel()
    G.log:debug('zys', 'OpenAreaAbilityPanel')
    if self.SkillState ~= self.SkillStateDef.Skill then
        return false
    end
    self.Img_LightWave:SetBrushResourceObject(self.IconAreaAbility)
    self.Img_LightEffect:SetVisibility(UE.ESlateVisibility.Hidden)
    self.Cvs_SelfUse:SetVisibility(UE.ESlateVisibility.Visible)
    self.WBP_Tips_ControlTips:SetVisibility(UE.ESlateVisibility.Hidden)
    self.Img_LightEffect_1:SetVisibility(UE.ESlateVisibility.Hidden)
    self.SkillState = self.SkillStateDef.AreaAbility
    self.WBP_Button_Exit:UnbindAllDelegate()
    self.WBP_Button_SelfUse:UnbindAllDelegate()
    self.WBP_Button_LightWave:UnbindAllDelegate()
    self.WBP_Button_Exit.OnClicked:Add(self, OnAreaAbilityExitClicked)
    self.WBP_Button_SelfUse.OnClicked:Add(self, OnAreaAbilitySelfUseClicked)
    self.WBP_Button_LightWave.OnClicked:Add(self, OnAreaAbilityLightClicked)
    self:SetCopyerAimed(false)
    self:SetCanExist(true)
    self.AreaPower_Action_Button:PlayOutAnim(function()
        G.log:debug('OpenCopyerPanel', 'DX_SkillOut')

        local PlayAnimProxy = UE.UWidgetAnimationPlayCallbackProxy.CreatePlayAnimationProxyObject(
        UE.NewObject(UE.UUMGSequencePlayer), self, self.DX_SkillOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
        PlayAnimProxy.Finished:Add(self, function()
            self.Switcher_AtctionBar:SetActiveWidgetIndex(1)

            local PlayAnimProxy = UE.UWidgetAnimationPlayCallbackProxy.CreatePlayAnimationProxyObject(
            UE.NewObject(UE.UUMGSequencePlayer), self, self.DX_SkillIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
            PlayAnimProxy.Finished:Add(self, function()
                --self.AreaPower_Action_Button:ShowCancelImg()
            end)
        end)
    end)
    return true
end

function WBP_HUD_SkillState:BindAreaAbilityUseBtnCB(fnCB)
    self.AreaAbilityUseBtnCB = fnCB
end

function WBP_HUD_SkillState:BindAreaAbilitySelfBtnCB(fnCB)
    self.AreaAbilitySelfBtnCB = fnCB
end

function WBP_HUD_SkillState:BindAreaAbilityCloseBtnCB(fnCB)
    self.AreaAbilityCloseBtnCB = fnCB
end

---`brief`关闭区域能力界面
function WBP_HUD_SkillState:CloseAreaAbilityPanel()
    G.log:debug('zys', 'CloseAreaAbilityPanel')
    self.WBP_Button_SelfUse:UnbindAllDelegate()
    self.WBP_Button_LightWave:UnbindAllDelegate()
    self.SkillState = self.SkillStateDef.Skill
    local PlayAnimProxy = UE.UWidgetAnimationPlayCallbackProxy.CreatePlayAnimationProxyObject(
    UE.NewObject(UE.UUMGSequencePlayer), self, self.DX_SkillOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
    PlayAnimProxy.Finished:Add(self, function()
        self.Switcher_AtctionBar:SetActiveWidgetIndex(0)
        local PlayAnimProxy = UE.UWidgetAnimationPlayCallbackProxy.CreatePlayAnimationProxyObject(
            UE.NewObject(UE.UUMGSequencePlayer), self, self.DX_SkillIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
            PlayAnimProxy.Finished:Add(self, function()
                self.AreaPower_Action_Button:PlayInAnim()
            end)

    end)
    self:SetCopyerAimed(true)
end

---`brief`打开马杜克灯界面
function WBP_HUD_SkillState:OpenMadukPanel()
    G.log:debug('zys', 'WBP_HUD_SkillState:OpenMadukPanel 打开马杜克灯')
    if self.SkillState ~= self.SkillStateDef.Skill then
        return false
    end
    self.WBP_Tips_ControlTips:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Img_LightWave:SetBrushResourceObject(self.IconMaduk)
    self.Img_LightEffect:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if 1 then
        -- 2023-11-9: 新手指引的部分先关掉
        self.WBP_Tips_ControlTips:SetVisibility(UE.ESlateVisibility.Hidden)
        self.WBP_Tips_ControlTips:SetVisibility(UE.ESlateVisibility.Hidden)
        self.Img_LightEffect:SetVisibility(UE.ESlateVisibility.Hidden)
    end
    -- self.WBP_Tips_ControlTips.TxtFront:SetText("按住")
    -- self.WBP_Tips_ControlTips.Text_Content:SetText("发射有破坏力的光波")
    -- self.WBP_Tips_ControlTips.WBP_Common_PCkey.ImgBg:SetBrushResourceObject(self.IconMadukPCKey)
    -- self.WBP_Tips_ControlTips.WBP_Common_PCkey.TextNormal:SetText("")
    self.Cvs_SelfUse:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.SkillState = self.SkillStateDef.Maduk
    
    self.WBP_Button_Exit:UnbindAllDelegate()
    self.WBP_Button_SelfUse:UnbindAllDelegate()
    self.WBP_Button_LightWave:UnbindAllDelegate()
    
    self.WBP_Button_Exit.OnClicked:Add(self, OnMadukExitClicked)
    self.WBP_Button_LightWave.OnClicked:Add(self, OnMadukLightClicked)
    self:StopAnimationsAndLatentActions()
    local PlayAnimProxy = UE.UWidgetAnimationPlayCallbackProxy.CreatePlayAnimationProxyObject(
    UE.NewObject(UE.UUMGSequencePlayer), self, self.DX_SkillOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
    PlayAnimProxy.Finished:Add(self, function()
        self.Switcher_AtctionBar:SetActiveWidgetIndex(1)
        self:PlayAnimation(self.DX_SkillIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    end)
    return true
end

function WBP_HUD_SkillState:BindMadukUseBtnCB(fnCB)
    self.MadukUseBtnCB = fnCB
end

function WBP_HUD_SkillState:BindMadukCloseBtnCB(fnCB)
    self.MadukCloseBtnCB = fnCB
end

---`brief`关闭马杜克灯界面
function WBP_HUD_SkillState:CloseMadukPanel()
    G.log:debug('zys', 'WBP_HUD_SkillState:CloseMadukPanel 关闭马杜克灯')
    self.SkillState = self.SkillStateDef.Skill
    self.WBP_Button_SelfUse:UnbindAllDelegate()
    self.WBP_Button_LightWave:UnbindAllDelegate()
    local PlayAnimProxy = UE.UWidgetAnimationPlayCallbackProxy.CreatePlayAnimationProxyObject(
    UE.NewObject(UE.UUMGSequencePlayer), self, self.DX_SkillOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
    PlayAnimProxy.Finished:Add(self, function()
        self.Switcher_AtctionBar:SetActiveWidgetIndex(0)
        self:PlayAnimation(self.DX_SkillIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    end)
    self:SetCopyerAimed(true)
end

---
function WBP_HUD_SkillState:ShowSkillState()
    if self.LastSkillMode and self.LastSkillMode ~= 0 then
        self:StopAnimationsAndLatentActions()
        self:PlayAnimation(self.DX_SkillIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    end

    self.SkillState = self.SkillStateDef.Skill

    UIManager:RegisterPressedKeyDelegate(self, self.OnPressedKeyEvent)
    UIManager:RegisterReleasedKeyDelegate(self, self.OnReleasedKeyEvent)
end

function WBP_HUD_SkillState:HideSkillState()
    UIManager:UnRegisterPressedKeyDelegate(self)
    UIManager:UnRegisterReleasedKeyDelegate(self)
    local PlayAnimProxy = UE.UWidgetAnimationPlayCallbackProxy.CreatePlayAnimationProxyObject(
    UE.NewObject(UE.UUMGSequencePlayer), self, self.DX_SkillOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
    PlayAnimProxy.Finished:Add(self, function()
        self:CloseMyself()
    end)
end

function WBP_HUD_SkillState:OnPressedKeyEvent(KeyName, bFromGame, ActionValue)
end

function WBP_HUD_SkillState:OnReleasedKeyEvent(KeyName, bFromGame, ActionValue)
    -- if KeyName == InputDef.Actions.OpenAreaAbilityAction then
    --     AreaAbilityVM:OpenAreaAbilityPanel()
    -- end
    -- if KeyName == InputDef.Actions.OpenCopyAbilityAction then
    --     AreaAbilityVM:OpenCopyerPanel()
    -- end
end



function WBP_HUD_SkillState:InitWidget()
    self['WBP_HUD_SkillState_Item_0' .. 1]:InitWidgetInfo(self, InputDef.Keys.Q, self.SkillSlotDef.Super, 0)
    self['WBP_HUD_SkillState_Item_0' .. 2]:InitWidgetInfo(self, InputDef.Keys.E, self.SkillSlotDef.Secondary, 1)
    self['WBP_HUD_SkillState_Item_0' .. 3]:InitWidgetInfo(self, InputDef.Keys.RightMouseButton, self.SkillSlotDef.Right, 2)
    self.DX_Loop_Additive_Inst_1:SetVisibility(UE.ESlateVisibility.Hidden)
    self:UpdateKeyboardIcon(self.SkillSlotDef.Super, InputDef.Keys.Q, true)
    self:UpdateKeyboardIcon(self.SkillSlotDef.Secondary, InputDef.Keys.E, true)
    self:UpdateKeyboardIcon(self.SkillSlotDef.Right, InputDef.Keys.RightMouseButton, true)

    --默认不开启滑板
    self.bPlayingBoard = false
    self.Prop_Action_Button:SetVisibility(UE.ESlateVisibility.Hidden)
    self.Place_Action_Button:SetVisibility(UE.ESlateVisibility.Hidden)
end

function WBP_HUD_SkillState:UpdateKeyboardIcon(SlotIndex, Keys, bPressed, bNotShow)
end

---进入滑板状态切换
function WBP_HUD_SkillState:VehicleStateChange(bSingle)
    if self.bPlayingBoard then
        ---todo 切换图标显示
        self.Prop_Action_Button:PlayPropChangeAnim()
    else
        self.bPlayingBoard = true
        self.AreaPower_Action_Button:PlayOutAnim(function()
            self.AreaPower_Action_Button:SetVisibility(UE.ESlateVisibility.Hidden)
            self.Prop_Action_Button:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.Prop_Action_Button:PlayInAnim()
        end)
    end
end

--显隐主界面的放置按钮
function WBP_HUD_SkillState:ShowPlacingBtn(bShow)
    if bShow then
        self.Place_Action_Button:SetVisibility(UE.ESlateVisibility.Visible)
        self:PlayAnimation(self.DX_PlaceIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    else
        self.Place_Action_Button:SetVisibility(UE.ESlateVisibility.Collapsed)
        self:PlayAnimation(self.DX_PlaceOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    end
end

---关闭滑板ui,显示区域能力
function WBP_HUD_SkillState:CloseVehicleUI()
    self.Prop_Action_Button:PlayOutAnim(function()
        self.Prop_Action_Button:SetVisibility(UE.ESlateVisibility.Hidden)
        self.AreaPower_Action_Button:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.AreaPower_Action_Button:PlayInAnim()
    end)
end


function WBP_HUD_SkillState:UpdateKeyboardIcon(SlotIndex, Keys, bPressed, bNotShow)
    local Widget = self['WBP_Common_PCkey_0' .. SlotIndex]
    Widget.KeyNormal:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    Widget.Root:SetRenderOpacity(bPressed and 1 or self.IconOpcityOnCD)
    if bNotShow then
        Widget.KeyNormal:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end

return WBP_HUD_SkillState
