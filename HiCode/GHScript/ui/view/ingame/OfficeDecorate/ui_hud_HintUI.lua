local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local HintUI = Class(UIWindowBase)

function HintUI:Init(InitializeDate)
    if InitializeDate ~= nil then
        self.ExecuteNumber = InitializeDate.Execute
        local InitializeFunction ={self.InitializeOne}
        InitializeFunction[self.ExecuteNumber](self,InitializeDate)
    end
end

function HintUI:OnDestruct()
    local DestructFunction = {self.DestructOne}
    DestructFunction[self.ExecuteNumber](self)
end
function HintUI:OnCancelClicked()
    self:CancelFunction()
end

function HintUI:OnCommitClicked()
    self:CommitFunction()
end





---@type Cancel function
---@type Commit function
---@type ParentUI UUserWidget
function HintUI.InitializeOne(self,InitializeDate)
    self.WBP_Common_Popup_Small:Destruct()
    self.CancelFunction = InitializeDate.Cancel
    self.CommitFunction = InitializeDate.Commit
    self.ParentUI = InitializeDate.ParentUI
    self.WBP_Common_Popup_Small.WBP_ComBtn_Cancel.Button.OnClicked:Add(self,self.OnCancelClicked)
    self.WBP_Common_Popup_Small.WBP_ComBtn_Commit.Button.OnClicked:Add(self,self.OnCommitClicked)
    self.WBP_Common_Popup_Small:PlayInAnim()
end
function HintUI.DestructOne(self)
    self.WBP_Common_Popup_Small.WBP_ComBtn_Cancel.Button.OnClicked:Remove(self,self.OnCancelClicked)
    self.WBP_Common_Popup_Small.WBP_ComBtn_Commit.Button.OnClicked:Remove(self,self.OnCommitClicked)
    self.CancelFunction = nil
    self.CommitFunction = nil
    self.ParentUI = nil
    self.ExecuteNumber = nil
end
return HintUI