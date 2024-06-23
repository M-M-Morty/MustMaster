--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@class WBP_Common_Popup_Small : WBP_Common_Popup_Small_C
---@field CommitCallbacks table<UObject, function>
---@field CancelCallbacks table<UObject, function>
---@field OwnerWidget UWidget

local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local ConstText = require("CP0032305_GH.Script.common.text_const")

---@type WBP_Common_Popup_Small_C
local WBP_Common_Popup_Small = UnLua.Class()

---@param self WBP_Common_Popup_Small
local function OnCallBacks(self, Callbacks)
    for Owner, CB in pairs(Callbacks) do
        if CB then
            CB(Owner)
        end
    end
end

---@param self WBP_Common_Popup_Small
local function CloseOwnerWidget(self)
    self:PlayAnimation(self.DX_Out, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    UIManager:CloseUI(self.OwnerWidget, true)
end

---@param self WBP_Common_Popup_Small
local function OnClickCommitButton(self)
    OnCallBacks(self, self.CommitCallBacks)
    CloseOwnerWidget(self)
end

---@param self WBP_Common_Popup_Small
local function OnClickCancelButton(self)
    OnCallBacks(self, self.CancelCallBacks)
    CloseOwnerWidget(self)
end

local function OnClickCloseButton(self)
    CloseOwnerWidget(self)
end

function WBP_Common_Popup_Small:Construct()
    self.CommitCallBacks = {}
    self.CancelCallBacks = {}
    self.WBP_ComBtn_Commit.OnClicked:Add(self, OnClickCommitButton)
    self.WBP_ComBtn_Cancel.OnClicked:Add(self, OnClickCancelButton)
    self.WBP_Btn_SmallPopUpClose.OnClicked:Add(self, OnClickCloseButton)
end

function WBP_Common_Popup_Small:Destruct()
    self.WBP_ComBtn_Commit.OnClicked:Remove(self, OnClickCommitButton)
    self.WBP_ComBtn_Cancel.OnClicked:Remove(self, OnClickCancelButton)
    self.WBP_Btn_SmallPopUpClose.OnClicked:Remove(self, OnClickCloseButton)
end

---@param Owner UObject
---@param CallBack function
function WBP_Common_Popup_Small:BindCommitCallBack(Owner, CallBack)
    self.CommitCallBacks[Owner] = CallBack
end

---@param Owner UObject
---@param CallBack function
function WBP_Common_Popup_Small:UnBindCommitCallBack(Owner, CallBack)
    self.CommitCallBacks[Owner] = nil
end

---@param Owner UObject
---@param CallBack function
function WBP_Common_Popup_Small:BindCancelCallBack(Owner, CallBack)
    self.CancelCallBacks[Owner] = CallBack
end

---@param Owner UObject
---@param CallBack function
function WBP_Common_Popup_Small:UnBindCancelCallBack(Owner, CallBack)
    self.CancelCallBacks[Owner] = nil
end

---@param TitleKey string
function WBP_Common_Popup_Small:SetTitle(TitleKey)
    if TitleKey then
        local Title = ConstText.GetConstText(TitleKey)
        self.TextTitle:SetText(Title)
    end
end

---@param OwnerWidget UWidget
function WBP_Common_Popup_Small:SetOwnerWidget(OwnerWidget)
    self.OwnerWidget = OwnerWidget
end

---@param bShow boolean
function WBP_Common_Popup_Small:ShowCloseButton(bShow)
    if bShow then
        self.WBP_Btn_SmallPopUpClose:SetVisibility(UE.ESlateVisibility.Visible)
    else
        self.WBP_Btn_SmallPopUpClose:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

---需要父Window调用播放，建议在OnShow调用
function WBP_Common_Popup_Small:PlayInAnim()
    self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end

return WBP_Common_Popup_Small
