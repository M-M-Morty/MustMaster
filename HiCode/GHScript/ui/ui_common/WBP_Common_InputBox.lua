--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
---@class WBP_Common_InputBox : WBP_Common_InputBox_C

---@type WBP_Common_InputBox
local WBP_Common_InputBox = UnLua.Class()

local ConstText = require("CP0032305_GH.Script.common.text_const")


---@param self WBP_Common_InputBox
local function OnClickInputBox(self)
    if self.EditableText_Content ~= nil then
        self.EditableText_Content:SetFocus()
    end
    if self.Switch_InputBtn ~= nil then
        self.Switch_InputBtn:SetActiveWidgetIndex(0)
    end
end

---@param self WBP_Common_InputBox
---@param Text string
---@param CommitMethod ETextCommit
local function OnTextChanged(self, Text, CommitMethod)
    if string.len(self.EditableText_Content:GetText()) > 0 then
        self.Txt_HintText:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.Txt_HintText:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
end

---@param self WBP_Common_InputBox
---@param Text string
---@param CommitMethod ETextCommit
local function OnTextCommitted(self, Text, CommitMethod)
    if self.WBP_Btn_InputBox.Button:HasAnyUserFocus() then
        return
    end
    if self.WBP_Btn_Clear.Button:HasAnyUserFocus() then
        return
    end
    if string.len(self.EditableText_Content:GetText()) > 0 then
        self.Txt_HintText:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.Txt_HintText:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
    UE.UAkGameplayStatics.PostEvent(self.InputCompleteAkEvent, UE.UGameplayStatics.GetPlayerPawn(self, 0), nil, nil, true)
    self.Switch_InputBtn:SetActiveWidgetIndex(1)
end

---@param self WBP_Common_InputBox
local function OnClickClear(self)
    self.EditableText_Content:SetText("")
    self.EditableText_Content:SetFocus()
    self.Txt_HintText:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function WBP_Common_InputBox:Construct()
    if self.WBP_Btn_InputBox ~= nil then
        self.WBP_Btn_InputBox.OnClicked:Add(self, OnClickInputBox)
    end
    if self.EditableText_Content ~= nil then
        self.EditableText_Content.OnTextChanged:Add(self, OnTextChanged)
        self.EditableText_Content.OnTextCommitted:Add(self, OnTextCommitted)
    end
    self.WBP_Btn_Clear.OnClicked:Add(self, OnClickClear)
end

function WBP_Common_InputBox:Destruct()
    if self.WBP_Btn_InputBox ~= nil then
        self.WBP_Btn_InputBox.OnClicked:Remove(self, OnClickInputBox)
    end
    if self.EditableText_Content ~= nil then
        self.EditableText_Content.OnTextChanged:Remove(self, OnTextChanged)
        self.EditableText_Content.OnTextCommitted:Remove(self, OnTextCommitted)
    end
    self.WBP_Btn_Clear.OnClicked:Remove(self, OnClickClear)
end

---@param Msg string
function WBP_Common_InputBox:ShowErrorMsg(Msg)
    self.Canvas_ImportErrorPrompt:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    UE.UAkGameplayStatics.PostEvent(self.ErrorTipsAkEvent, UE.UGameplayStatics.GetPlayerPawn(self, 0), nil, nil, true)
    self.Txt_ErrorPrompt:SetText(Msg)
end

---@param TextKey string
function WBP_Common_InputBox:ShowErrorMsgByKey(TextKey)
    local Msg = ConstText.GetConstText(TextKey)
    self:ShowErrorMsg(Msg)
    self:PlayAnimation(self.DX_ErrorIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end

function WBP_Common_InputBox:HideErrorMsg()
    self.Canvas_ImportErrorPrompt:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function WBP_Common_InputBox:GetText()
    return self.EditableText_Content:GetText()
end

---@param TextKey string
function WBP_Common_InputBox:SetText(TextKey)
    local Text = ConstText.GetConstText(TextKey)
    self.Txt_HintText:SetText(Text)
    self.HintText = Text
end

return WBP_Common_InputBox
