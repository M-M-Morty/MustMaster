--
-- @COMPANY GHGame
-- @AUTHOR xuminjie
--

local G = require('G')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local DialogueObjectModule = require("mission.dialogue_object")


---@class DialogueVM : ViewModelBase
local DialogueVM = Class(ViewModelBaseClass)

function DialogueVM:ctor()
    self.DialogContentIndex = 0
    self.DialogContentField = self:CreateVMField('')
    self.NextIconDelayField = self:CreateVMField(1)
    self.DialogTitleField = self:CreateVMField('')
    self.bNextActionShowField = self:CreateVMField(true)
    self.DialogueSoundField = self:CreateVMField(nil)

end

function DialogueVM:ResetFields()
    self.DialogContentIndex = 0
    self.DialogContentField:SetFieldValue('')
    self.NextIconDelayField:SetFieldValue(1)
    self.DialogTitleField:SetFieldValue('')
    self.bNextActionShowField:SetFieldValue(true)
    self.DialogueSoundField:SetFieldValue(nil)

end

function DialogueVM:GetInteractVM()
    if not self.InteractVM then
        self.InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
    end
    return self.InteractVM
end

---@param InDialogUIContext UIInfoClass
function DialogueVM:SetDialogUIContext(InDialogUIContext)
    self.DialogUIContext = InDialogUIContext
end

function DialogueVM:ResetDialogUIContext()
    self.DialogUIContext = UIDef.UIInfo.UI_CommunicationNPC
end

function DialogueVM:GetDialogUIContext()
    return self.DialogUIContext and self.DialogUIContext or UIDef.UIInfo.UI_CommunicationNPC
end

function DialogueVM:OpenDialogInstance(DialogueObject)
    if not DialogueObject then
        return
    end
    self:CloseDialog()
    self.DialogueObject = DialogueObject
    local NextStep = self.DialogueObject:GetNextDialogueStep(0)
    self:ProcessDialogueStep(NextStep)    
end

function DialogueVM:ProcessDialogueStep(DialogueStep)
    if not DialogueStep then
        self:CloseDialog()
        return
    end
    
    local StepType = DialogueStep:GetType()
    if StepType == DialogueObjectModule.DialogueType.TALK then
        self:CloseSelectionUI()
        self:OpenDialogUI()
        self.DialogTitleField:SetFieldValue(DialogueStep:GetTalkerName())
        self.DialogContentField:SetFieldValue(DialogueStep:GetContent())
        if DialogueStep.GetNextDelay then
            self.NextIconDelayField:SetFieldValue(DialogueStep:GetNextDelay())
        end
        self.DialogueSoundField:SetFieldValue({
            Asset = DialogueStep.GetAudio and DialogueStep:GetAudio() or nil,
            Skip = DialogueStep.GetCanSkipTime and (DialogueStep:GetCanSkipTime()) or nil
        })
        self.bNextActionShowField:SetFieldValue(true)
    elseif StepType == DialogueObjectModule.DialogueType.INTERACT then
        self:OpenSelectionUI(DialogueStep:GetInteractItems())
        self.bNextActionShowField:SetFieldValue(false)
    elseif StepType == DialogueObjectModule.DialogueType.FINISHED then
        local FinishedDialogObject = self.DialogueObject
        self:CloseDialog()
        FinishedDialogObject:FinishDialogue()
    end
end

function DialogueVM:NextDialogueStep(Index)
    if self.DialogueObject == nil then
        return
    end
    local CurrentDialogueObject = self.DialogueObject
    local NextStep = self.DialogueObject:GetNextDialogueStep(Index)
    -- 处理选项Action可能导致的重入问题
    if CurrentDialogueObject == self.DialogueObject then
        self:ProcessDialogueStep(NextStep)
    end
end


function DialogueVM:CloseDialog()
    if self.DialogueObject then
        self:CloseDialogUI()
        self:CloseSelectionUI()
        self.DialogueObject = nil
    end
    self:ResetFields()
end

-- function DialogueVM:UpdateDialogItem(DialogItem)
--     self.DialogContentIndex = 1
--     self.CurrentDialogItem = DialogItem

--     self:CloseSelectionUI()
--     self:NextTalkContent()
-- end

-- function DialogueVM:NextTalkContent()
--     local DialogItem = self.CurrentDialogItem
--     if not DialogItem then
--         return
--     end

--     local Content = DialogItem.DialogContent[self.DialogContentIndex]
--     if Content then
--         self.DialogContentIndex = self.DialogContentIndex + 1
--         self.DialogTitleField:SetFieldValue(DialogItem.DialogTitle)
--         self.DialogContentField:SetFieldValue(Content)
--     elseif not DialogItem.DialogSelection then
--         self:CloseDialog()
--     end
-- end

-- function DialogueVM:ShowCurrentSelectionContent()
--     local DialogItem = self.CurrentDialogItem
--     if not DialogItem then
--         return
--     end

--     local Content = DialogItem.DialogContent[self.DialogContentIndex]
--     if Content then
--         return
--     end

--     if DialogItem.DialogSelection then
--         self:OpenSelectionUI(DialogItem.DialogSelection)
--     end
-- end

-- function DialogueVM:DialogSelect(SelectIndex)
--     local DialogItem = self.CurrentDialogItem
--     if not DialogItem or not DialogItem.DialogSelection then
--         return
--     end
--     local DialogSelection = DialogItem.DialogSelection[SelectIndex]
--     if DialogSelection then
--         if DialogSelection.SelectionAction then
--             DialogSelection.SelectionAction()
--         end

--         local JumpToItem = DialogSelection.JumpToItem
--         if JumpToItem and self.CurrentDialogData[JumpToItem] then
--             self:UpdateDialogItem(self.CurrentDialogData[JumpToItem])
--         else
--             self:CloseDialog()
--         end
--     end
-- end

function DialogueVM:OpenDialogUI()
    local UIInfo = self:GetDialogUIContext()
    local DialogUI = UIManager:GetUIInstanceIfVisible(UIInfo.UIName)
    if not DialogUI then
        DialogUI = UIManager:OpenUI(UIInfo)
    end
    if DialogUI and DialogUI.OnOpenDialogWidget then
        DialogUI:OnOpenDialogWidget()
    end
end

function DialogueVM:CloseDialogUI()
    local UIInfo = self:GetDialogUIContext()
    local DialogUI = UIManager:GetUIInstanceIfVisible(UIInfo.UIName)
    if DialogUI and DialogUI.OnCloseDialogWidget then
        DialogUI:OnCloseDialogWidget()
    end
end

function DialogueVM:OpenSelectionUI(SelectionItems)
    local InteractVM = self:GetInteractVM()
    if InteractVM then
        InteractVM:OpenDialogSelection(SelectionItems)
    end
end

function DialogueVM:CloseSelectionUI()
    G.log:debug('zys', table.concat({'DialogueVM:CloseSelectionUI', debug.traceback()}))
    local InteractVM = self:GetInteractVM()
    if InteractVM then
        InteractVM:CloseDialogSelection()
    end
end

return DialogueVM
