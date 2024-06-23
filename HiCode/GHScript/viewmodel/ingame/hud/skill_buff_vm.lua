local G = require('G')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local DialogueObjectModule = require("mission.dialogue_object")

---@class SkillBuffVM : ViewModelBase
local SkillBuffVM = Class(ViewModelBaseClass)

function SkillBuffVM:ctor()
    self.ArrBuffField = self:CreateVMArrayField({})
end

function SkillBuffVM:OpenBuffWnd()
    G.log:debug('zys', 'SkillBuffVM:OpenBuffWnd')
    local BuffWnd = UIManager:OpenUI(UIDef.UIInfo.UI_BuffWnd)
end

function SkillBuffVM:CloseBuffWnd()
    G.log:debug('zys', 'SkillBuffVM:CloseBuffWnd')
    UIManager:CloseUIByName(UIDef.UIInfo.UI_BuffWnd.UIName, true)
end

---@param Tag UE.FGameplayTag
---@param TagName string
---@param Name string
---@param Duration number
---@param Desc string
function SkillBuffVM:AddBuff(Tag, TagName, Name, Duration, Desc)
    G.log:debug('zys', table.concat({'SkillBuffVM:AddBuff: ', TagName, ' ',Name,' ', Duration, '', Desc}))
    local Info = {
        Tag = Tag or nil,
        TagName = TagName or '',
        Name = Name or '',
        Duration = Duration or 1,
        Desc = Desc or '',
    }
    local Arr = self.ArrBuffField:GetFieldValue()
    table.insert(Arr, 1, Info)
    self.ArrBuffField:SetItems(Arr)
end

---@param Tag UE.FGameplayTag
---@param TagName string
function SkillBuffVM:RemoveBuff(Tag, TagName)
    G.log:debug('zys', table.concat({'SkillBuffVM:RemoveBuff: ', TagName}))
    local Count = self.ArrBuffField:GetItemNum()
    for i = 1, Count do
        if self.ArrBuffField:GetItem(Count - i + 1).TagName == TagName then
            self.ArrBuffField:RemoveItemByIndex(Count - i + 1)
            return
        end
    end
end

return SkillBuffVM