--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
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

---@class WBP_Situation_Chat: WBP_Situation_Chat_C
local WBP_Situation_Chat = Class(UIWindowBase)

---@param self WBP_Situation_Chat
local function OnTypeWriterFinished(self)
    self.ShowInfo.TypeWriterFinished = true
    self.WBP_TypeWriter:UnregisterFinishedEvent('OnPlayFinished')
    if self.ChatInfo.FnFinishCB then
        self.ChatInfo.FnFinishCB()
    end
    
    if not self.ChatInfo.bNotShowNext then
        self.Image_Next:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self:PlayAnimation(self.DX_biaoshi_Loop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    end
end

--function WBP_Situation_Chat:Initialize(Initializer)
--end

--function WBP_Situation_Chat:PreConstruct(IsDesignTime)
--end

function WBP_Situation_Chat:OnConstruct()
    self:BindToAnimationFinished(self.DX_Talk_in, {self, self.OnDxInEnd})

    self.Button_Next.OnClicked:Add(self, self.OnBtnClick)
    UIManager:RegisterPressedKeyDelegate(self, self.OnPressed)
end

function WBP_Situation_Chat:OnDestruct()
    UIManager:UnRegisterPressedKeyDelegate(self)
end

--function WBP_Situation_Chat:Tick(MyGeometry, InDeltaTime)
--end

function WBP_Situation_Chat:OnShow()
    self.ShowInfo = {}
    self.ShowInfo.Inited = false
    self.ShowInfo.AnimPlayed = false

    self.Image_Next:SetVisibility(UE.ESlateVisibility.Hidden)
    self.WBP_TypeWriter:SetText('')
    self:InitAkComp()
    if not self.ShowInfo.Inited then
        self:PlayAnimation(self.DX_Talk_in, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false) 
    end
end

function WBP_Situation_Chat:OnHide()
    self.ShowInfo.Inited = false
    self.ShowInfo.AnimPlayed = false
    pcall(self.DestroyAkComp, self)
end

---`public`推送一个对话并设置完成的回调
---@param Name string
---@param Job string
---@param Content string
---@param FnValidClickCB function<void()> 有效点击的回调, 即播完后的点击的回调
---@param FnFinishCB function<void()> 播完的回调
---@param bNotShowNext boolean 不显示"下一个动画"
function WBP_Situation_Chat:DisplaySituationChat(Name, Job, Content, FnValidClickCB, FnFinishCB, bNotShowNext)
    G.log:debug('zys', 'DisplaySituationChat name:' .. tostring(Name) .. ', job:' .. tostring(Job) .. ', content:' .. tostring(Content) .. ', FnValidClickCB:' .. tostring(FnValidClickCB) .. ', FnFinishCB:' .. tostring(FnFinishCB) .. ', bNotShowNext:' .. tostring(bNotShowNext))
    if Content == "" then
        Content = " "
    end
    self.ChatInfo = {
        Name = Name,
        Job = Job,
        Content = Content,
        FnValidClickCB = FnValidClickCB,
        FnFinishCB = FnFinishCB,
        bNotShowNext = bNotShowNext,
    }
    if Name then
        self.Text_Target:SetText(Name)
    else
        self.Text_Target:SetText('')
    end
    if Content then
        self.ShowInfo.TypeWriterFinished = false
        local PlayTypeWriter = function(this)
            this.Image_Next:SetVisibility(UE.ESlateVisibility.Hidden)
            this.WBP_TypeWriter:SetText(Content)
            this.WBP_TypeWriter:RegisterFinishedEvent('OnPlayFinished', function()
                OnTypeWriterFinished(this)
            end)
        end
        if not self.ShowInfo.AnimPlayed then
            self.ShowInfo.BeginDelegate = PlayTypeWriter
        else
            PlayTypeWriter(self)
        end
    else
        self.SetTextContent:SetTest('')
    end
end

function WBP_Situation_Chat:OnBtnClick()
    if not self.ShowInfo.AnimPlayed then
        return
    end
    if self.WBP_TypeWriter:IsPlaying() then
        self.WBP_TypeWriter:FinishPlayTyping()
        -- self:PauseAnimation(self.DX_biaoshi_Loop)
    else
        self:PauseAnimation(self.DX_biaoshi_Loop)
        self.Image_Next:SetVisibility(UE.ESlateVisibility.Hidden)
        if self.ChatInfo.FnValidClickCB then
            self.ChatInfo.FnValidClickCB()
        end
    end
end

function WBP_Situation_Chat:OnPressed(KeyName, bFromGame, ActionValue)
    if KeyName == InputDef.Keys.SpaceBar then
        self:OnBtnClick()
        return true
    end
end

function WBP_Situation_Chat:OnDxInEnd()
    self.ShowInfo.AnimPlayed = true
    if self.ShowInfo.BeginDelegate then
        self.ShowInfo.BeginDelegate(self)
    end
end

return WBP_Situation_Chat
