--
-- @COMPANY GHGame
-- @AUTHOR xuminjie
--

local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local InputDef = require('CP0032305_GH.Script.common.input_define')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UICommonUtil = require('CP0032305_GH.Script.framework.ui.ui_common_utl')


local HPLENGTH
---@type WBP_BOSS_HP_C
local UIBossHP = Class(UIWindowBase)

--function UIBossHP:Initialize(Initializer)
--end

--function UIBossHP:PreConstruct(IsDesignTime)
--end

function UIBossHP:OnConstruct()
    self.addDurHealthTime = 0
end

function UIBossHP:OnShow()
    self:PlayAnimation(self.DX_BossHP_chuxian, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
end

function UIBossHP:UpdateParams(HealthLimit, curHealth, tenacityLimit, curTenacity, name)
    -- master appear open ui
    self.HealthLimit = HealthLimit
    self.CurHealth = curHealth
    self.TenacityLimit = tenacityLimit
    self.CurTenacity = curTenacity
    self.BossName:SetText(name)
    self.BossHPProgressBar:SetPercent(curHealth / HealthLimit)
    self.BossTenacityProgressBar:SetPercent(curTenacity / tenacityLimit)
    self.BossHPText:SetText(curHealth .. '/' .. HealthLimit)
    self.EndAtTime = 0
end

function UIBossHP:ChangeBossHP(data)
    if data.num / self.HealthLimit >= self.SpecialAttackPercent then
        self:SpecialAttack(data.num)
    else
        self:NormalAttack(data.num)
    end
end

function UIBossHP:NormalAttack(damage)
    self:UpdateHPSize()
    self.CurHealth = self.CurHealth - damage
    if self.CurHealth < 0 then
        self.CurHealth = 0
    end
    local percent = self.CurHealth / self.HealthLimit

    self.animPercent = self.BossHPBarBuffer:GetDynamicMaterial():K2_GetScalarParameterValue('Progress')
    if self.animPercent > percent then
        self.StartAtTime = 1 - self.animPercent
        self.EndAtTime = 1 - percent
    else
        self.StartAtTime = self.EndAtTime
        self.EndAtTime = 1 - percent
    end
    self:PlayAnimationTimeRange(self.DX_BossHPBarBuffer, self.StartAtTime, 1, 1,
        UE.EUMGSequencePlayMode.Forward, 0.05, false)
    local x = self.HPLENGTH.X * percent - (self.HPLENGTH.X / 2)
    self.FX_kouxue.Slot:SetPosition(UE.FVector2D(x, 0))
    self:PlayAnimation(self.DX_BossHP_putongkouxue, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    self.BossHPProgressBar:SetPercent(percent)
    self.BossHPText:SetText(self.CurHealth .. '/' .. self.HealthLimit)
end

function UIBossHP:SpecialAttack(damage)
    self:UpdateHPSize()
    self.FX_BossHPProgressBar_1:SetPercent(self.CurHealth / self.HealthLimit)
    self.CurHealth = self.CurHealth - damage
    if self.CurHealth < 0 then
        self.CurHealth = 0
    end
    local percent = self.CurHealth / self.HealthLimit

    self.animPercent = self.BossHPBarBuffer:GetDynamicMaterial():K2_GetScalarParameterValue('Progress')
    if self.animPercent > percent then
        self.StartAtTime = 1 - self.animPercent
        self.EndAtTime = 1 - percent
    else
        self.StartAtTime = self.EndAtTime
        self.EndAtTime = 1 - percent
    end
    self:PlayAnimationTimeRange(self.DX_BossHPBarBuffer, self.StartAtTime, 1, 1,
        UE.EUMGSequencePlayMode.Forward, 0.05, false)
    local x = self.HPLENGTH.X * percent - (self.HPLENGTH.X / 2)
    self.FX_kouxue.Slot:SetPosition(UE.FVector2D(x, 0))
    self:PlayAnimation(self.DX_BossHP_teshukouxue, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    self.BossHPProgressBar:SetPercent(percent)
    self.BossHPText:SetText(self.CurHealth .. '/' .. self.HealthLimit)
end

function UIBossHP:BossAddHealth(health)
    self:UpdateHPSize()
    local x = self.HPLENGTH.X * (self.CurHealth / self.HealthLimit) - (self.HPLENGTH.X / 2)
    self.FX_jiaxue.Slot:SetPosition(UE.FVector2D(x, 0))
    self.animDurationTime = self.DX_BossHP_jiaxue
    self.CurHealth = self.CurHealth + health
    if self.CurHealth > self.HealthLimit then
        self.CurHealth = self.HealthLimit
    end

    self:PlayAnimation(self.DX_BossHP_jiaxue, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    self.BossHPText:SetText(self.CurHealth .. '/' .. self.HealthLimit)
    self.addDurHealthTime = self.DX_BossHP_jiaxue:GetEndTime();
end

-- function UIBossHP:ShieldAttack(damage)
--     self:UpdateShieldSize()
--     self.CurTenacity = self.CurTenacity - damage
--     local percent = self.CurTenacity / self.TenacityLimit
--     local x = self.SHIELD.X * percent - (self.SHIELD.X / 2)
--     self.FX_hudun.Slot:SetPosition(UE.FVector2D(x, 0))
--     self:PlayAnimation(self.DX_BossHP_hudunshouji, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
--     self.BossTenacityProgressBar:SetPercent(percent)
--     self.BossTenacityText:SetText(self.CurTenacity .. '/' .. self.TenacityLimit)
--     if self.CurTenacity <= 0 then
--         self:StopAnimationsAndLatentActions()
--         self.CurTenacity = 0
--         self:PlayAnimation(self.DX_BossHP_hudunposusi, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
--     end
-- end

-- function UIBossHP:ShieldRecover(addNum)
--     self:UpdateShieldSize()
--     self.CurTenacity = self.CurTenacity + addNum
--     if self.CurTenacity > self.TenacityLimit then
--         self.CurTenacity = self.TenacityLimit
--     end
--     local percent = self.CurTenacity / self.TenacityLimit
--     local x = self.SHIELD.X * percent - (self.SHIELD.X / 2)
--     self.FX_hudun.Slot:SetPosition(UE.FVector2D(x, 0))
--     self.BossTenacityProgressBar:SetPercent(percent)
--     self.BossTenacityText:SetText(self.CurTenacity .. '/' .. self.TenacityLimit)
-- end

function UIBossHP:ShieldUpdate(curVal, litVal)
    self:UpdateShieldSize()
    local percent = curVal / litVal
    local x = self.SHIELD.X * percent - (self.SHIELD.X / 2)
    if curVal > 0.01 then
        self.bShieldCrush = false
    end  
    if self.bShieldCrush then
        return
    end
    self.FX_hudun.Slot:SetPosition(UE.FVector2D(x, 0))
    if curVal <= 0.01 then
        self.bShieldCrush = true
        self:PlayAnimation(self.DX_BossHP_hudunposusi, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
        self.BossTenacityProgressBar:SetPercent(percent)
        return
    end
    self:PlayAnimation(self.DX_BossHP_hudunshouji, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    self.BossTenacityProgressBar:SetPercent(percent)
    -- self.BossTenacityText:SetText(self.CurTenacity .. '/' .. self.TenacityLimit)
end

function UIBossHP:UpdateHPSize()
    local Geo = self.BossHPProgressBar:GetCachedGeometry()
    self.HPLENGTH = UE.USlateBlueprintLibrary.GetLocalSize(Geo)
end

function UIBossHP:UpdateShieldSize()
    local Geo = self.BossTenacityProgressBar:GetCachedGeometry()
    self.SHIELD = UE.USlateBlueprintLibrary.GetLocalSize(Geo)
end

function UIBossHP:Tick(MyGeometry, InDeltaTime)
end

function UIBossHP:Close()
    self:CloseMyself()
end

return UIBossHP
