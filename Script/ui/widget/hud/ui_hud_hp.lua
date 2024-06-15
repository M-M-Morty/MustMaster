--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require('G')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local InputDef = require('CP0032305_GH.Script.common.input_define')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')

---@class WBP_HUD_HP_C
local UIHudHp = Class(UIWindowBase)

--function UIHudHp:Initialize(Initializer)
--end

--function UIHudHp:PreConstruct(IsDesignTime)
--end

-- function UIHudHp:Construct()
-- end

local DistanceState =
{
    MonsterAlert = 0,
    DiscoverPlayer = 1,
    LockPlayer = 2,
    LevelAndBar = 3,
    LevelShow = 4,
    ShowNone = 5,
}

local MonsterType =
{
    Normal = 0,
    Elite = 1,
    Boss = 2,
}

function UIHudHp:OnConstruct()
    self.DistState = nil
    self:OnResetBarShow()
    self.CurState = -1
    self.PlaySpeed = 0.2
end

function UIHudHp:OnShow()
end

function UIHudHp:UpdateParams()

end

function UIHudHp:OpenHudHP(MonsterType, LevelShow, LevelAndBar, MonsterAlert, DiscoverPlayer)
    self.MonsterType = MonsterType
    self.LevelShow = LevelShow
    self.LevelAndBar = LevelAndBar
    self.MonsterAlert = MonsterAlert
    self.DiscoverPlayer = DiscoverPlayer
    --TODO 暂无level数据
    local Name = "Lv.10"
    self.LevelName:SetText(Name)
    self.Switcher_MosterState:SetActiveWidgetIndex(self.MonsterType)
    self.Switcher_MosterHP:SetActiveWidgetIndex(self.MonsterType)
    self:SetNormalMode(true)
end

function UIHudHp:SetHealth(curHealth, healthLimit)
    self.CurHealth = curHealth
    self.HealthLimit = healthLimit
    if self.CurHealth == 0 then
        self:OnResetBarShow()
        return
    end
    if self.MonsterType == MonsterType.Normal then
        self.HPProgressBar:SetPercent(self.CurHealth / self.HealthLimit)
    elseif self.MonsterType == MonsterType.Elite then
        self.HPProgressBar_1:SetPercent(self.CurHealth / self.HealthLimit)
    end

    self:GetHpBuffer()
end

function UIHudHp:GetHpBuffer()
    if not self.FormerHealth then
        self.FormerHealth = self.CurHealth
        return
    end
    if self.FormerHealth > self.HealthLimit or self.FormerHealth < 0 then
        self.FormerHealth = self.CurHealth
        return
    end
    if self.FormerHealth > self.CurHealth then
        if self.CurHealth == 0 then
            self.FormerHealth = self.CurHealth
        end
        self:OnLoseBlood()
    else
        self.HPBarBuffer:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.HPBarBuffer_1:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.FormerHealth = self.CurHealth
    end
end

function UIHudHp:OnLoseBlood()
    self.StartAtTime = 1 - (self.FormerHealth / self.HealthLimit)
    self.EndAtTime = 1 - (self.CurHealth / self.HealthLimit)
    self.HPBarBuffer:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.HPBarBuffer_1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:OnPlayLoseBloodAnimation()
    self.FormerHealth = self.CurHealth
end

function UIHudHp:SetTenacity(curTenacity, tenacityLimit)
    self.CurTenacity = curTenacity
    self.TenacityLimit = tenacityLimit
    self.WhiteProgressBar_1:SetPercent(self.CurTenacity / self.TenacityLimit)
end

function UIHudHp:SetBattleMode(flag)
    if flag then
        self.CurState = DistanceState.DiscoverPlayer
        self:OnDistanceChange(self.OnDiscoverPlayerShow)
    end
    self:SetNormalMode(not flag)
end

function UIHudHp:SetReturningMode(flag)
    self:SetNormalMode(flag)
end

function UIHudHp:SetAlertMode(flag)
    if flag then
        self.CurState = DistanceState.MonsterAlert
        self:OnDistanceChange(self.OnAlertShow)
    end
    self:SetNormalMode(not flag)
end

function UIHudHp:SetLockMode(flag)
    if flag then
        self.CurState = DistanceState.LockPlayer
        self:OnDistanceChange(self.OnLockPlayerShow)
    end
    self:SetNormalMode(not flag)
end

function UIHudHp:SetNormalMode(flag)
    self.isNormalMode = flag
end

function UIHudHp:UpdateDistance(Distance, InDeltaTime)
    if not self.isNormalMode then
        return   
    end
    if Distance < self.LevelAndBar then
        self.CurState = DistanceState.LevelAndBar
        self:OnDistanceChange(self.OnLevelAndBarShow)
    elseif Distance > self.LevelAndBar and Distance < self.LevelShow then
        self.CurState = DistanceState.LevelShow
        self:OnDistanceChange(self.OnLevelShow)
    elseif Distance > self.LevelShow then
        self.CurState = DistanceState.ShowNone
        self:OnDistanceChange(self.HideAllBar)
    end
end

function UIHudHp:OnResetBarShow()
    self:HideAllBar()
    self.CurAnimType = nil
end

function UIHudHp:OnLevelShow()
    self.LevelName:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Gap:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

    self:PlayShowHpAnim()
end

function UIHudHp:OnLevelAndBarShow()
    self.LevelName:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Switcher_MosterHP:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

    self:PlayShowHpAnim()
end

function UIHudHp:OnAlertShow()
    self.LevelName:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Switcher_MosterHP:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Switcher_MosterState:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Switcher_MosterState:SetActiveWidgetIndex(0)

    self:Emphasize(DistanceState.MonsterAlert)
    self:PlayShowHpAnim()
end

function UIHudHp:OnDiscoverPlayerShow()
    self.LevelName:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Switcher_MosterHP:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Switcher_MosterState:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Switcher_MosterState:SetActiveWidgetIndex(1)

    self:Emphasize(DistanceState.DiscoverPlayer)
    self:PlayShowHpAnim()
end

function UIHudHp:OnLockPlayerShow()
    self.LevelName:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Switcher_MosterHP:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Switcher_MosterState:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Switcher_MosterState:SetActiveWidgetIndex(2)

    self:Emphasize(DistanceState.LockPlayer)
    self:PlayShowHpAnim()
end

function UIHudHp:OnDistanceChange(FunctionName)
    if self.DistState ~= self.CurState then
        self.DistState = self.CurState
        -- if self.CurState ~= DistanceState.ShowNone then
        --     self:HideAllBar()
        -- end
        FunctionName(self)
        if self.CurState == DistanceState.LockPlayer or self.CurState == DistanceState.DiscoverPlayer or self.CurState == DistanceState.MonsterAlert then
            self.CurAnimType = self.CurState
        else
            self.CurAnimType = nil
        end
    end
end

function UIHudHp:HideAllBar()
    if self.CurAnimType ~= nil then
        self:EmphasizeEnd(self.CurAnimType)
    end
    self.LevelName:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Switcher_MosterState:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Switcher_MosterHP:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Gap:SetVisibility(UE.ESlateVisibility.Collapsed)
end

-- function UIHudHp:Tick(MyGeometry, InDeltaTime)
-- end

function UIHudHp:PlayShowHpAnim()
    if not self.Switcher_MosterHP:GetVisibility() or not self.LevelName:GetVisibility() then
        self:StopAnimationsAndLatentActions()
        self:PlayAnimation(self.DX_HP_chuxian, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    end
end

function UIHudHp:OnPlayLoseBloodAnimation()
    local animName
    if self.MonsterType == MonsterType.Normal then
        animName = self.DX_MonsterHPBarBuffer
    elseif self.MonsterType == MonsterType.Elite then
        animName = self.DX_EliteMonsterHPBarBuffer
    end
    if animName == nil then
        return
    end
    self:StopAnimationsAndLatentActions()
    self:PlayAnimationTimeRange(animName, self.StartAtTime, self.EndAtTime, 1,
        UE.EUMGSequencePlayMode.Forward, self.PlaySpeed, false)
end

function UIHudHp:Emphasize(type)
    local animName
    if type == nil then
        return
    end
    if type == DistanceState.MonsterAlert then
        animName = self.DX_wenhao_chuxian
    elseif type == DistanceState.DiscoverPlayer then
        animName = self.DX_tanhao_chuxian
    elseif type == DistanceState.LockPlayer then
        animName = self.DX_suoding_chuxian
    end
    if animName == nil then
        return
    end
    self:StopAnimationsAndLatentActions()
    self:PlayAnimation(animName, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
end

function UIHudHp:EmphasizeEnd(type)
    local animName
    if type == nil then
        return
    end
    if type == DistanceState.MonsterAlert then
        animName = self.DX_wenhao_xiaoshi
    elseif type == DistanceState.DiscoverPlayer then
        animName = self.temp_tanhao_xiaoshi
    else
        animName = self.DX_suoding_xiaoshi
    end
    if animName == nil then
        return
    end
    self:StopAnimationsAndLatentActions()
    self:PlayAnimation(animName, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

return UIHudHp
