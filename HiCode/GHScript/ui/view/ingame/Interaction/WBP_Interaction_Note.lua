--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local StringUtil = require('CP0032305_GH.Script.common.utils.string_utl')
local ConstText = require("CP0032305_GH.Script.common.text_const")
local NoteTable = require("common.data.note_data").data
local G = require("G")

---@class WBP_Interaction_Note : WBP_Interaction_Note_C

---@type WBP_Interaction_Note_C
local WBP_Interaction_Note = Class(UIWindowBase)

---@param self WBP_Interaction_Note
local function OnClickCloseButton(self)
    self:PlayAnimation(self.DX_Out, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

---@param self WBP_Interaction_Note
---@param Title string
---@param Content string
local function SetNoteText(self, Title, Content)
    self.Txt_NoteTitle:SetText(Title)
    --- 首行缩进
    self.Txt_NoteContent:SetText("\t\t" .. Content)
end

---@param self WBP_Interaction_Note
---@param NoteID integer
---@param NoteConfig NoteDataConfig
local function RefreshContent(self, NoteID, NoteConfig)
    if not NoteConfig then
        G.log:warn("ghgame", "Error! Cannot find note data, NoteID=%s", tostring(NoteID))
        return
    end

    local Content = NoteConfig.Content
    if not Content or #Content < 2 then
        G.log:warn("ghgame", "Error! Note data format is not as expected, NoteID=%s", tostring(NoteID))
        return
    end

    local TitleKey = Content[1]
    local ContentKey = Content[2]
    local TitleText = ConstText.GetConstText(TitleKey)
    local ContentText = ConstText.GetConstText(ContentKey)
    SetNoteText(self, TitleText, ContentText)
end

function WBP_Interaction_Note:Construct()
    self.WBP_Common_TopContent.CommonButton_Close.OnClicked:Add(self, OnClickCloseButton)
end

function WBP_Interaction_Note:Destruct()
    self.WBP_Common_TopContent.CommonButton_Close.OnClicked:Remove(self, OnClickCloseButton)
end

function WBP_Interaction_Note:OnShow()
    SetNoteText(self, "", "")
    self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

---@param Animation UWidgetAnimation
function WBP_Interaction_Note:OnAnimationFinished(Animation)
    local AnimName = Animation:GetName()
    if StringUtil:StartsWith(AnimName, 'DX_Out') then
        self:CloseMyself()
    end
end

---@param NoteID integer
function WBP_Interaction_Note:UpdateParams(NoteID)
    G.log:debug("ghgame", "WBP_Interaction_Note:UpdateParams, NoteID=%s", tostring(NoteID))
    if NoteID == nil then
        G.log:warn("ghgame", "Error! NoteID parameter invalid")
        return
    end

    ---@type NoteDataConfig
    local NoteConfig = NoteTable[NoteID]
    RefreshContent(self, NoteID, NoteConfig)
end

return WBP_Interaction_Note
