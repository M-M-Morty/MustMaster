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
local UIWidgetBase = require('CP0032305_GH.Script.framework.ui.ui_widget_base')

---@class WBP_Communication_ChatWidget: WBP_Communication_ChatWidget_C
---@field Sound string WwiseEvent资源
---@field Skip number 可以跳过的秒数, 传空则不可用跳过, 倒计时到0则可跳过了
---@field bTypeWriterFinished boolean
local UICommunicationNPCChatWidget = Class(UIWidgetBase)

--function UICommunicationNPCChatWidget:Initialize(Initializer)
--end

--function UICommunicationNPCChatWidget:PreConstruct(IsDesignTime)
--end

function UICommunicationNPCChatWidget:OnConstruct()
    self:BuildWidgetProxy()
    self:InitViewModel()
    self.Inited = false
    self.AnimPlayed = false
end

function UICommunicationNPCChatWidget:OnDX_in_End()
    self.AnimPlayed = true
    if self.BeginDelegate then
        self:BeginDelegate()
    end
end

---`public`外部需要调用这个
function UICommunicationNPCChatWidget:InitWidget()
    self.Image_Next:SetVisibility(UE.ESlateVisibility.Hidden)
    self.CurNextDelay = -1
    self.WBP_TypeWriter:SetText('')
    self:InitAkComp()

    if not self.Inited then
        self:PlayAnimation(self.DX_Talk_in, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false) 
    end
    self.Inited = true
end

---`public`外部需要调用这个
function UICommunicationNPCChatWidget:HideWidget()
    self.Inited = false
    self.AnimPlayed = false
    -- self.WBP_TypeWriter:ResetWidget()
    pcall(self.DestroyAkComp, self)
end

function UICommunicationNPCChatWidget:Tick(MyGeometry, InDeltaTime)
    if self.Skip and self.Skip > 0 then
        self.Skip = self.Skip - InDeltaTime
        if self.Skip <= 0 or not self.bSoundPlaying then
            self.Skip = 0
            self:OnTypeWriterOrSoundFinished()
        end
    end
end

function UICommunicationNPCChatWidget:BuildWidgetProxy()
    ---@type UTextBlockProxy
    self.Text_TargetProxy = WidgetProxys:CreateWidgetProxy(self.Text_Target)
    self.Text_ContentField = self:CreateUserWidgetField(self.SetTextContent)
    self.OnStateChangedField = self:CreateUserWidgetField(self.OnDialogueStateChanged)
    self.OnNextDelayChangedField = self:CreateUserWidgetField(self.OnNextDelayChanged)
    self.OnSoundChangedField = self:CreateUserWidgetField(self.OnSoundChanged)
end

function UICommunicationNPCChatWidget:InitViewModel()
    ---@type DialogueVM
    self.DialogueVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.DialogueVM.UniqueName)
    
    ViewModelBinder:BindViewModel(self.Text_TargetProxy.TextField, self.DialogueVM.DialogTitleField, ViewModelBinder.BindWayToWidget)
    ViewModelBinder:BindViewModel(self.Text_ContentField, self.DialogueVM.DialogContentField, ViewModelBinder.BindWayToWidget)
    ViewModelBinder:BindViewModel(self.OnStateChangedField, self.DialogueVM.bNextActionShowField, ViewModelBinder.BindWayToWidget)
    ViewModelBinder:BindViewModel(self.OnNextDelayChangedField, self.DialogueVM.NextIconDelayField, ViewModelBinder.BindWayToWidget)
    ViewModelBinder:BindViewModel(self.OnSoundChangedField, self.DialogueVM.DialogueSoundField, ViewModelBinder.BindWayToWidget)
end

---`public`当用户点击时
function UICommunicationNPCChatWidget:OnChatNext()
    if not self.AnimPlayed then
        return
    end
    if self.WBP_TypeWriter:IsPlaying() then
        self.WBP_TypeWriter:FinishPlayTyping()
    elseif self.Skip and self.Skip <= 0 then
        if self.AkComp then
            self.AkComp:Stop()
        end
        self:PauseAnimation(self.DX_biaoshi_Loop)
        if not self.DialogueVM then
            self.DialogueVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.DialogueVM.UniqueName)
        end
        self.DialogueVM:NextDialogueStep(0)
    end
end

function UICommunicationNPCChatWidget:OnNextDelayChangedField(Time)
    self.CurNextDelay = Time
end

function UICommunicationNPCChatWidget:SetTextContent(InText)
    self.bTypeWriterFinished = false
    if not self.AnimPlayed then
        self:PlayAnimation(self.DX_Talk_in, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
        self.BeginDelegate = function()
            self.Image_Next:SetVisibility(UE.ESlateVisibility.Hidden)
            self.WBP_TypeWriter:SetText(InText)
            self.CurNextDelay = self.DialogueVM.NextIconDelayField:GetFieldValue()
            self.WBP_TypeWriter:RegisterFinishedEvent('OnPlayFinished', function()
                self:OnTypeWriterFinished()
            end)
        end
    else
        self.Image_Next:SetVisibility(UE.ESlateVisibility.Hidden) 
        self.WBP_TypeWriter:SetText(InText)
        self.CurNextDelay = self.DialogueVM.NextIconDelayField:GetFieldValue()
        self.WBP_TypeWriter:RegisterFinishedEvent('OnPlayFinished', function()
            self:OnTypeWriterFinished()
        end)
    end
end

function UICommunicationNPCChatWidget:OnDialogueStateChanged(data)
    if data then
        self.Button_Next:SetVisibility(UE.ESlateVisibility.Visible)
        self.Image_Next:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.Button_Next:SetVisibility(UE.ESlateVisibility.Hidden)
        self.Image_Next:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end

---`private`
function UICommunicationNPCChatWidget:OnTypeWriterFinished()
    self.bTypeWriterFinished = true
    self.WBP_TypeWriter:UnregisterFinishedEvent('OnPlayFinished')
    self:OnTypeWriterOrSoundFinished()
end

---`private`
function UICommunicationNPCChatWidget:OnSoundChanged(Data)
    if not Data then
        return
    end
    self.bSoundPlaying = false
    self.SoundPath = ''
    if not Data.Asset then
        -- 如果没有声音资源则仅处理打字机
        self.Skip = 0
        G.log:debug('zys', 'UICommunicationNPCChatWidget:OnSoundChanged(Data) 没有声音')
        return
    else
        -- 播放声音
        self.SoundPath = Data.Asset
        local Asset = UE.UObject.Load(Data.Asset)
        if Asset then
            self:PostAkEvent(Asset, self.SoundPath)
        else
            self.Skip = 0
            return
        end
    end
    if not Data.Skip then -- 如果Skip为空则不可跳过
        G.log:debug('zys', 'UICommunicationNPCChatWidget:OnSoundChanged(Data) 不能跳过')
        self.Skip = nil
    else
        self.Skip = Data.Skip -- 开始计时
        local LogStr = 'UICommunicationNPCChatWidget:OnSoundChanged(Data) 开始计时' .. self.Skip
        G.log:debug('zys', LogStr)
    end
end

---`private`当打字机或者声音播放完毕后都调用此方法, 两个都播放完成后则播放箭头动画, 此后若点击界面则切换下一句
function UICommunicationNPCChatWidget:OnTypeWriterOrSoundFinished()
    G.log:debug('zys', 'UICommunicationNPCChatWidget:OnTypeWriterOrSoundFinished()')
    if self.Skip and self.Skip <= 0 and self.bTypeWriterFinished then
        self.Image_Next:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self:PlayAnimation(self.DX_biaoshi_Loop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    end
end

---`private`播放完毕的回调
function UICommunicationNPCChatWidget:OnPostCompleted(SoundName)
    G.log:debug('zys',table.concat({'UICommunicationNPCChatWidget:OnPostCompleted()  ', tostring(self.SoundPath == SoundName), ', self.Skip: ', self.Skip}))
    if self.SoundPath == SoundName and self.Skip == nil then
        self.Skip = 0
        self:OnTypeWriterOrSoundFinished()
    end
end

return UICommunicationNPCChatWidget
