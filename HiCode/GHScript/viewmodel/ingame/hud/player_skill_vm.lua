local G = require('G')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local DialogueObjectModule = require("mission.dialogue_object")

---@class PlayerSkillVM : ViewModelBase
local PlayerSkillVM = Class(ViewModelBaseClass)

function PlayerSkillVM:ctor()
    self.PowerField = self:CreateVMField(0)
    self.MaxPowerField = self:CreateVMField(100)
end

function PlayerSkillVM:UpdatePowerVal(power)
    if power then
        self.PowerField:SetFieldValue(power)
    end
end

function PlayerSkillVM:UpdateMaxPowerVal(maxPower)
    if maxPower then
        self.MaxPowerField:SetFieldValue(maxPower)
    end
end

return PlayerSkillVM
