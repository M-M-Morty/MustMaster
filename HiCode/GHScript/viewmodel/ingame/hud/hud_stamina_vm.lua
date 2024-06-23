local G = require('G')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local DialogueObjectModule = require("mission.dialogue_object")

---@class HudStaminaVM : ViewModelBase
local HudStaminaVM = Class(ViewModelBaseClass)

function HudStaminaVM:ctor()
    ---@type WBP_HUD_Stamina_C
    self.curStamina = nil
    ---@type WBP_HUD_Stamina_C
    self.lastStamina = nil
    self.bIsFull = false
    self.lastTime = UE.UHiUtilsFunctionLibrary.GetNowTimestampMs()
    self.curValue = nil
    self.targetValue = nil
    self.bIsAdd = false
    self.speed = 100
end

function HudStaminaVM:SetNewStamina(obj)
    if not self.curStamina then
        self.curStamina = obj
        self.curStamina:SetStaminaHide()
        return
    else
        self.lastStamina = self.curStamina
        self.curStamina = obj
    end
    self:SwitchStamina()
end

function HudStaminaVM:SwitchStamina()
    self.lastStamina:OnStaminaClose()
end

function HudStaminaVM:SetStaminaValue(NewValue, OldValue, LimitValue)
    local percent = NewValue / LimitValue
    local lastPercent = OldValue / LimitValue
    self.curStamina:SetPercent(lastPercent, percent)
end

return HudStaminaVM
