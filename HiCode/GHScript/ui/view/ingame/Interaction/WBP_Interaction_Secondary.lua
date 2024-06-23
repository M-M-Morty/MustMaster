--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
---@class WBP_Interaction_Secondary : WBP_Interaction_Secondary_C
---@field TitleOutCallback function
---@field MonoLogueIndex integer
---@field MonoLogueContents table

---@type WBP_Interaction_Secondary_C
local WBP_Interaction_Secondary = UnLua.Class()

local G = require("G")
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local MonologueUtils = require("common.utils.monologue_utils")
local DialogueObjectModule = require("mission.dialogue_object")

--function M:Initialize(Initializer)
--end

--function M:PreConstruct(IsDesignTime)
--end

local DEFAULT_SECONDS = 5

function WBP_Interaction_Secondary:OnNextBtnClick()
    self.ChatWidget:OnChatNext()
end

function WBP_Interaction_Secondary:Construct()
    self.ChatWidget.Button_Next.OnClicked:Add(self, self.OnNextBtnClick)
end

function WBP_Interaction_Secondary:Destruct()

end

function WBP_Interaction_Secondary:PlayTitleInAnim()
    self:PlayAnimation(self.DX_TopTitleIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end

function WBP_Interaction_Secondary:PlayTitleOutAnim(CallBack)
    self:PlayAnimation(self.DX_TopTitleOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    if CallBack then
        self.TitleOutCallback = CallBack
    end
end

function WBP_Interaction_Secondary:PlayBottonOutAnim()
    self:PlayAnimation(self.DX_MaskOut,  0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    self:PlayAnimation(self.DX_BottomTextOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end

function WBP_Interaction_Secondary:OnAnimationFinished(Animation)
    if Animation == self.DX_TopTitleOut then
        if self.TitleOutCallback then
            self.TitleOutCallback()
        end
    end
end

---@param Content string
function WBP_Interaction_Secondary:SetTopContent(Content)
    self.Text_TopContent:SetText(Content)
end

---@param self WBP_Interaction_Secondary
---@param Content string
local function ShowBottomAndSetBottomText(self, Content)
    self.Switcher_Bottom:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Switcher_Bottom:SetActiveWidgetIndex(0)
    self.Text_Content:SetText(Content)
    self:PlayAnimation(self.DX_BottomTextIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end

---@param Content string
function WBP_Interaction_Secondary:SetSimpleBottomContent(Content)
    ShowBottomAndSetBottomText(self, Content)
    self:PlayAnimation(self.DX_MaskIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end

---@param MonoLogueID integer
function WBP_Interaction_Secondary:SetSimpleBottomContentByMonoLogueID(MonoLogueID)
    local Contents = MonologueUtils.GenerateMonologueData(MonoLogueID)
    if #Contents < 1 then
        G.log:error("WBP_Interaction_Secondary", "SetSimpleBottomContentByMonoLogueID MonoLogueID has no contents! %d", MonoLogueID)
    end
    local Content = Contents[1].TalkContent
    self:SetSimpleBottomContent(Content)
end

function WBP_Interaction_Secondary:HideSimpleBottomContent()
    self:PlayAnimation(self.DX_MaskOut,  0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    local CallBack = function()
        self.Switcher_Bottom:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    self:PlayAnimation(self.DX_BottomTextOut,  0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, CallBack }, self.DX_BottomTextOut:GetEndTime(), false)
end

---@param self WBP_Interaction_Secondary
local function PlayNextMonoLogue(self)
    if self.MonoLogueIndex == 1 then
        self:PlayAnimation(self.DX_MaskIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    elseif self.MonoLogueIndex > #self.MonoLogueContents then
        self:HideSimpleBottomContent()
    end
    if self.MonoLogueIndex >= 1 and self.MonoLogueIndex <= #self.MonoLogueContents then
        local ContentData = self.MonoLogueContents[self.MonoLogueIndex]
        ShowBottomAndSetBottomText(self, ContentData.TalkContent)
        self.MonoLogueIndex = self.MonoLogueIndex + 1
        local Duration = DEFAULT_SECONDS
        if ContentData.Duration ~= nil and ContentData.Duration > 0 then
            Duration = ContentData.Duration
        end
        UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, PlayNextMonoLogue }, Duration, false)
    end
end

---@param MonoLogueID integer
function WBP_Interaction_Secondary:SetBottomMonoLogue(MonoLogueID)
    local Contents = MonologueUtils.GenerateMonologueData(MonoLogueID)
    if #Contents < 1 then
        G.log:error("WBP_Interaction_Secondary", "SetBottomMonoLogue MonoLogueID has no contents! %d", MonoLogueID)
    end
    self.MonoLogueIndex = 1
    self.MonoLogueContents = Contents
    PlayNextMonoLogue(self)
end

local function MockDialogueObject()
    local DialogueObject = DialogueObjectModule.Dialogue.new()
    local PreStep = nil
    for i = 1, 3 do
        local DialogueStep = DialogueObjectModule.DialogueStep.new(DialogueObjectModule.DialogueType.TALK)
        DialogueStep.TalkerName = "TestName"
        DialogueStep.Content = "Test Content"
        if PreStep == nil then
            DialogueObject.EntryStep = DialogueStep
        else
            PreStep.tbNextStep[1] = DialogueStep
        end
        PreStep = DialogueStep
    end
    local DialogueStep = DialogueObjectModule.DialogueStep.new(DialogueObjectModule.DialogueType.FINISHED)
    PreStep.tbNextStep[1] = DialogueStep
    return DialogueObject
end

function WBP_Interaction_Secondary:SetBottomDialog(InDialogUIContext, DialogueID)
    local DialogueObject = DialogueObjectModule.Dialogue.new(DialogueID)
    --local DialogueObject = MockDialogueObject()

    self.Switcher_Bottom:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Switcher_Bottom:SetActiveWidgetIndex(1)

    local DialogueVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.DialogueVM.UniqueName)
    DialogueVM:SetDialogUIContext(InDialogUIContext)
    DialogueVM:OpenDialogInstance(DialogueObject)
end

function WBP_Interaction_Secondary:ResetDialogUIContext()
    local DialogueVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.DialogueVM.UniqueName)
    DialogueVM:ResetDialogUIContext()
end

--function M:Tick(MyGeometry, InDeltaTime)
--end

function WBP_Interaction_Secondary:OnOpenDialogWidget()
    self.ChatWidget:InitWidget()
end

function WBP_Interaction_Secondary:OnCloseDialogWidget()
    self.ChatWidget:HideWidget()
    self.Switcher_Bottom:SetVisibility(UE.ESlateVisibility.Collapsed)
end

return WBP_Interaction_Secondary
