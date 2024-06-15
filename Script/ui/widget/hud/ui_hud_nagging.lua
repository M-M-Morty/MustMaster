--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
local utils = require('common.utils')

local DEFAULT_DURATION = 5          -- 默认间隔
local TIMER_INTERVAL = 0.1          -- tiemr的时间间隔

---@type WBP_HUD_Nagging_C
local WBP_HUD_Nagging = Class(UIWindowBase)

--function WBP_HUD_Nagging:Initialize(Initializer)
--end

--function WBP_HUD_Nagging:PreConstruct(IsDesignTime)
--end

function WBP_HUD_Nagging:OnConstruct()
    self.MsgContent = {}
    self.CurMsgIndex = 1
end

function WBP_HUD_Nagging:TimerLoop()
    local Item = self.MsgContent[self.CurMsgIndex]
    if Item then
        if not Item.PassTime then
            Item.PassTime = 0
        end
        if not Item.Duration then
            Item.Duration = DEFAULT_DURATION
        end
        Item.PassTime = Item.PassTime + TIMER_INTERVAL
        if Item.PassTime > Item.Duration then
            self:DisplayNextMsg()
        end
    end
end

function WBP_HUD_Nagging:OnShow()
    ---@type FTimerHandle
    self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.TimerLoop}, TIMER_INTERVAL, true)

    self.bWillClose = false
    self:StopAnimationsAndLatentActions()
    -- self:DestroyAkComp()
    self:InitAkComp()
    self.RichText_Content:SetText("")
    self:PlayAnimation(self.DX_in, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function WBP_HUD_Nagging:OnHide()
    G.log:debug('zys', "WBP_HUD_Nagging:OnHide()")
    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.TimerHandle)
    self:DestroyAkComp()
    self.MsgContent = {}
    self.CurMsgIndex = 0
end

function WBP_HUD_Nagging:Close(bForceClose, bNoAnim)
    G.log:debug('zys', table.concat({"WBP_HUD_Nagging:Close()", tostring(bForceClose), tostring(bNoAnim)}))
    if bForceClose then
        if self.AkComp then
            self.AkComp:Stop()
        end
        self.MsgContent = {}
        self.CurMsgIndex = 1
        if bNoAnim then
            -- 2024/2/29 解决Sequence播放时HideAllUI导致PlayAnim中断而Sequence结束后继续播的问题
            self.MsgContent = {}
            self.CurMsgIndex = 1
            self:CloseMyself()            
        else
            local PlayAnimProxy = UE.UWidgetAnimationPlayCallbackProxy.CreatePlayAnimationProxyObject(UE.NewObject(UE.UUMGSequencePlayer), self, self.DX_end, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
            PlayAnimProxy.Finished:Add(self, function()
                G.log:debug('zys', "WBP_HUD_Nagging:Close()proxy")
                self.MsgContent = {}
                self.CurMsgIndex = 1
                self:CloseMyself()
            end)
        end
    else
        self.bWillClose = true
    end
end

function WBP_HUD_Nagging:OnDXOut()
    -- self:CloseMyself()
end

---`public`
---@param MsgInfo string
function WBP_HUD_Nagging:SetMsg(MsgContent)
    if self.AkComp then
        self.AkComp:Stop()
    end
    self.MsgContent = {}
    self.MsgContent = TableUtil:ShallowCopy(MsgContent)
    self.MsgContent = MsgContent
    self.CurMsgIndex = 0
    self:DisplayNextMsg()
end

function WBP_HUD_Nagging:SetContent(content, name)
    self.RichText_Content:SetText(content)
end

function WBP_HUD_Nagging:PlayOutAnim()
    self:PlayAnimation(self.DX_end, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function WBP_HUD_Nagging:PlayInAnim()
    self:PlayAnimation(self.DX_in, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function WBP_HUD_Nagging:DisplayNextMsg()
    self.CurMsgIndex = self.CurMsgIndex + 1
    if self.CurMsgIndex > #self.MsgContent or self.bWillClose then
        -- self:PlayAnimation(self.DX_end, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
        local PlayAnimProxy = UE.UWidgetAnimationPlayCallbackProxy.CreatePlayAnimationProxyObject(UE.NewObject(UE.UUMGSequencePlayer), self, self.DX_end, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
        PlayAnimProxy.Finished:Add(self, function()
            self.MsgContent = {}
            self.CurMsgIndex = 1
            self:CloseMyself()
            G.log:debug('zys', "WBP_HUD_Nagging:DisplayNextMsg()proxy")
        end)
        return
    end

    self.RichText_Content:SetText(self.MsgContent[self.CurMsgIndex].TalkContent)
    self.MsgContent[self.CurMsgIndex].PassTime = 0
    
    G.log:debug('zys',table.concat({'WBP_HUD_Nagging:DisplayNextMsg()', self.MsgContent[self.CurMsgIndex].Duration, self.MsgContent[self.CurMsgIndex].TalkName, self.MsgContent[self.CurMsgIndex].TalkContent, self.MsgContent[self.CurMsgIndex].Audio}))
    local Path = self.MsgContent[self.CurMsgIndex].Audio
    if Path then
        local Asset = UE.UObject.Load(Path)
        -- self:PostAkEvent(Asset, Path)
        if Asset then
            self:PlayAkEvent(Asset, Path)
        else
            G.log:debug("zys][nagging", "failed to load ak asset on nagging !!!")
        end
    end

    -- 2023.11.27晚在云桌面aozigu试的delay有问题先换回tick, 然后再排查
    -- utils.DoDelay(UIManager.GameWorld, self.MsgContent[self.CurMsgIndex].Duration, function()
    --     self:DisplayNextMsg()
    -- end)

end

function WBP_HUD_Nagging:OnPostCompleted(Name)
    G.log:debug('zys', 'WBP_HUD_Nagging:OnPostCompleted(Name)' .. Name)
end


return WBP_HUD_Nagging
