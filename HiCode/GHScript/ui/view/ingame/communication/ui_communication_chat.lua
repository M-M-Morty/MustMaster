--
-- @COMPANY GHGame
-- @AUTHOR xuminjie
--

local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UICommonUtil = require('CP0032305_GH.Script.framework.ui.ui_common_utl')
local InputDef = require('CP0032305_GH.Script.common.input_define')

---@type WBP_Communication_NPCChat_C
local UICommunicationNPCChat = Class(UIWindowBase)

--function UICommunicationNPCChat:Initialize(Initializer)
--end

--function UICommunicationNPCChat:PreConstruct(IsDesignTime)
--end


function UICommunicationNPCChat:OnConstruct()
    self:InitWidget()
    self.ChatWidget.Button_Next.OnClicked:Add(self, self.OnNextBtnClick)
    UIManager:RegisterPressedKeyDelegate(self, self.OnPressKeyEvent)
end

function UICommunicationNPCChat:OnDestruct()
    UIManager:UnRegisterPressedKeyDelegate(self)
end

function UICommunicationNPCChat:InitWidget()
end

function UICommunicationNPCChat:OnOpenDialogWidget()
    self.ChatWidget:InitWidget()
end

function UICommunicationNPCChat:OnCloseDialogWidget()
    local Player = UE.UGameplayStatics.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
    if Player and Player.PlayerUIInteractComponent and Player.PlayerUIInteractComponent.CheckAwake then
        Player.PlayerUIInteractComponent:CheckAwake()
    end
    self.ChatWidget:HideWidget()
    self:CloseMyself(true)
end

function UICommunicationNPCChat:OnShow()

    self.CurNextDelay = -1

    local MsgCenter = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    if MsgCenter then
        MsgCenter:HideNagging()
    end
end

function UICommunicationNPCChat:OnHide()
    local DialogueVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.DialogueVM.UniqueName)
    DialogueVM:ResetDialogUIContext()
end

function UICommunicationNPCChat:OnPressKeyEvent(KeyName)
    if KeyName == InputDef.Keys.SpaceBar then
        self.ChatWidget:OnChatNext()
        return true
    end
end

function UICommunicationNPCChat:OnNextBtnClick()
    self.ChatWidget:OnChatNext()
end

return UICommunicationNPCChat
