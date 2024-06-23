

local G = require('G')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local DialogueObjectModule = require("mission.dialogue_object")

---@class ThrowSkillVM : ViewModelBase
local ThrowSkillVM = Class(ViewModelBaseClass)

function ThrowSkillVM:ctor()
    self.CanThrowPointShowField = self:CreateVMField(true)
end

function ThrowSkillVM:SetCanAllThrowPointShow(bCanShow)
    G.log:debug("zys][throw point", table.concat({"ThrowSkillVM:SetCanAllThrowPointShow: ", tostring(bCanShow)}))
    self.CanThrowPointShowField:SetFieldValue(bCanShow)
end

return ThrowSkillVM