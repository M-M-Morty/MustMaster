--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require("G")
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UICommonUtil = require('CP0032305_GH.Script.framework.ui.ui_common_utl')
local UIWidgetBase = require('CP0032305_GH.Script.framework.ui.ui_widget_base')
local UIEventContainer = require('CP0032305_GH.Script.ui.ui_event.ui_wait_event_container')
local UIEventDef = require('CP0032305_GH.Script.ui.ui_event.ui_event_def')
local UIWaitCloseOtherUI = require('CP0032305_GH.Script.ui.ui_event.ui_wait_close_others')
local UIWaitAnimation = require('CP0032305_GH.Script.ui.ui_event.ui_wait_animation')
local UIWaitController = require('CP0032305_GH.Script.ui.ui_event.ui_wait_controller')
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')

local ComAK_Second_Open     = 'Second_Open'     -- 音效表Key值
local ComAK_Second_Close    = 'Second_Close'    -- 音效表Key值
local ComAK_Third_Open      = 'Third_Open'      -- 音效表Key值
local ComAK_Third_Close     = 'Third_Close'     -- 音效表Key值

local WindowState =
{
    Undefined = -1,
    Hidden    = 0,
    Showing   = 1,
    Showed    = 2,
    Hidding   = 3,
}



---@class UIWindowBase : UIWidgetBase
local UIWindowBase = Class(UIWidgetBase)
UIWindowBase.CurrentWindowState = WindowState.Undefined
UIWindowBase.bIsFocused = false
UIWindowBase.tbSecondaryPage = {}
--function UIWindowBase:Initialize(Initializer)
--end

--function UIWindowBase:PreConstruct(IsDesignTime)
--end

-- call by UIWidgetBase:Construct
-- function UIWindowBase:OnConstruct()
-- end

-- call by UIWidgetBase:Destruct
-- function UIWindowBase:OnDestruct()
-- end

--function UIWindowBase:Tick(MyGeometry, InDeltaTime)
--end


-- function UIWindowBase:OnReturnAction()

--     print('UIWindowBase:OnReturnAction',self.UIInfo.UIName)
-- end


-- function UIWindowBase:OnKeyDown(MyGeometry, InKeyEvent)
--     local Key = UE.UKismetInputLibrary.GetKey(InKeyEvent)
-- end

function UIWindowBase:GetUIName()
    return self.UIInfo and self.UIInfo.UIName or ''
end

function UIWindowBase:IsWindowStateHidden()
    if self.CurrentWindowState == WindowState.Showing or self.CurrentWindowState == WindowState.Showed then
        return false
    end
    return true
end

function UIWindowBase:CallOnCreate()
    G.log:debug('gh_ui', 'UIWindowBase:CallOnCreate %s', self.UIInfo.UIName)

    self:SetVisibility(UE.ESlateVisibility.Hidden)
    self.CurrentWindowState = WindowState.Hidden
    self.bDestroyUIAfterHiding = false
    self.WaitShowEvents = UIEventContainer.new()
    self.WaitHideEvents = UIEventContainer.new()

    if self.OnCreate then
        self:OnCreate()
    end
    UIManager.UINotifier:UINotify(UIEventDef.UICreate, self)
end

function UIWindowBase:StopAllAnimationAndDelayAction()
    local fnCall
    fnCall = function(Widget)
        if Widget.EntryWidgetPool then -- UListViewBase
            local activeWidgets = Widget.EntryWidgetPool.ActiveWidgets:ToTable()
            for _, ActiveWidget in pairs(activeWidgets) do
                UICommonUtil:ForeachInWidget(ActiveWidget, fnCall)
            end
            local inactiveWidgets = Widget.EntryWidgetPool.InactiveWidgets:ToTable()
            for _, InActiveWidget in pairs(inactiveWidgets) do
                UICommonUtil:ForeachInWidget(InActiveWidget, fnCall)
            end
        end

        if Widget.StopAnimationsAndLatentActions then
            Widget:StopAnimationsAndLatentActions()
        end
    end
    UICommonUtil:ForeachInWidget(self, fnCall)
end

function UIWindowBase:BeginShow()
    if self.CurrentWindowState == WindowState.Hidding or self.CurrentWindowState == WindowState.Hidden then
        self.bDestroyUIAfterHiding = false
        self.WaitHideEvents:StopWait()

        -- 正在关闭过程中打开UI，立刻调用一次CallOnHide，与接下来的CallOnShow对应
        if self.CurrentWindowState == WindowState.Hidding then
            self:CallOnHide()
        end
        UIManager:CloseDestroyingUIImmediately(self.UIInfo.UIName) -- Destroy标记下的废弃UI，立刻关闭保证视觉正确
        self.CurrentWindowState = WindowState.Showing

        G.log:debug('gh_ui', 'UIWindowBase:BeginShow %s', self.UIInfo.UIName)

        -- 等待自动关闭的UI关闭
        self:AddShowWaitCloseUIEvent(self.UIInfo.AutoCloseUI)
        self:AddShowWaitControllerEvent()
        self.WaitShowEvents:WaitAllEvents(self, self.WaitShowComplete, true)

        -- 关闭自动关闭的UI关闭
        if self.UIInfo.AutoCloseUI then
            for _, UIName in pairs(self.UIInfo.AutoCloseUI) do
                UIManager:CloseUIByName(UIName)
            end
        end
    end
end

function UIWindowBase:WaitShowComplete()
    self:CallOnShow()
end

function UIWindowBase:CallOnShow()
    G.log:debug('gh_ui', 'UIWindowBase:CallOnShow %s', self.UIInfo.UIName)

    self.CurrentWindowState = WindowState.Showed
    self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.WaitShowEvents:ClearWaitEvent()

    if self.ShowMouseNode then
        UIManager:AddShowMouseNode(self.ShowMouseNode)
    end
    UIManager:UpdatePlayerInputMode()
    if self.HideLayerNode then
        UIManager:AddHideLayerNode(self.HideLayerNode)
    elseif self.UIInfo.PageLevel == Enum.Enum_UILevel.SecondaryPage then
        UIManager:HideAllHUD()
    end

    UIManager.UINotifier:UINotify(UIEventDef.UIShow, self)

    self:PlayAkEventOnShow()

    if self.OnShow then
        self:OnShow()
    end
end

function UIWindowBase:HideImmediately()
    self:CallOnHide()
end

function UIWindowBase:BeginHide(DestroyUI)
    DestroyUI = DestroyUI and true or false
    if self.CurrentWindowState == WindowState.Showing or self.CurrentWindowState == WindowState.Showed then
        self.WaitShowEvents:StopWait()

        -- 正在打开的过程中关闭UI，立刻调用一次CallOnShow，与接下来的CallOnHide对应
        if self.CurrentWindowState == WindowState.Showing then
            self:CallOnShow()
        end

        self.CurrentWindowState = WindowState.Hidding
        self.bDestroyUIAfterHiding = DestroyUI

        G.log:debug('gh_ui', 'UIWindowBase:BeginHide %s, %s, %s', self.UIInfo.UIName, tostring(self.CurrentWindowState),
            tostring(DestroyUI))

        self:WaitDefaultHiddenAnimaition()
        self.WaitHideEvents:WaitAllEvents(self, self.WaitHideComplete, true)

        self:PlayAkEventOnHide()
    elseif self.CurrentWindowState == WindowState.Hidding then
        G.log:debug('gh_ui', 'UIWindowBase:BeginHide %s, %s, %s', self.UIInfo.UIName, tostring(self.CurrentWindowState),
            tostring(DestroyUI))
        self.bDestroyUIAfterHiding = DestroyUI
    elseif self.CurrentWindowState == WindowState.Hidden then
        if DestroyUI then
            G.log:debug('gh_ui', 'UIWindowBase:BeginHide %s, %s, %s', self.UIInfo.UIName,
                tostring(self.CurrentWindowState), tostring(DestroyUI))
            UIManager:CloseUIImmediately(self, DestroyUI)
        end
    end
end

function UIWindowBase:AddShowWaitControllerEvent()
    local WaitEventObj = UIWaitController.new(self)
    self.WaitShowEvents:AddWaitEvent(WaitEventObj)
end

function UIWindowBase:WaitDefaultHiddenAnimaition()
    -- 默认等待DX_Out动画播放完成
    if self.DX_out then
        local WaitAnimObj = UIWaitAnimation.new(self)
        WaitAnimObj:SetWaitAnimation(self.DX_out)
        self.WaitHideEvents:AddWaitEvent(WaitAnimObj)
    end
end

function UIWindowBase:WaitHideComplete()
    UIManager:CloseUIImmediately(self, self.bDestroyUIAfterHiding)
end

function UIWindowBase:AddtbSecondaryPage(tb)
    self.tbSecondaryPage = tb
    TableUtil:ArrayRemoveValue(self.tbSecondaryPage, self.UIInfo)
end

function UIWindowBase:Skip2OtherSecondaryPage(Info, ...)
    table.insert(self.tbSecondaryPage, self.UIInfo)
    local ins = UIManager:OpenUI(Info, ...)
    ins:AddtbSecondaryPage(self.tbSecondaryPage)
    self:CloseMyself(false)
end

function UIWindowBase:CallOnHide()
    if self.CurrentWindowState ~= WindowState.Hidden then
        self.CurrentWindowState = WindowState.Hidden

        G.log:debug('gh_ui', 'UIWindowBase:CallOnHide %s', self.UIInfo.UIName)
        self:SetVisibility(UE.ESlateVisibility.Hidden)
        self.WaitHideEvents:ClearWaitEvent()
        self:StopAllAnimationAndDelayAction()

        if self.ShowMouseNode then
            UIManager:RemoveShowMouseNode(self.ShowMouseNode)
        end
        UIManager:UpdatePlayerInputMode()
        if self.HideLayerNode then
            UIManager:RemoveHideLayerNode(self.HideLayerNode)
        elseif self.UIInfo.PageLevel == Enum.Enum_UILevel.SecondaryPage then
            UIManager:RecoverShowAllHUD()
        end

        UIManager.UINotifier:UINotify(UIEventDef.UIHide, self)
        if self.OnHide then
            self:OnHide()
        end
    end
end

function UIWindowBase:CallOnDestroy()
    if self.CurrentWindowState ~= WindowState.Undefined then
        G.log:debug('gh_ui', 'UIWindowBase:CallOnDestroy %s', self.UIInfo.UIName)

        self.CurrentWindowState = WindowState.Undefined

        UIManager.UINotifier:UINotify(UIEventDef.UIDestroy, self)
        if self.OnDestroy then
            self:OnDestroy()
        end
    end
end

function UIWindowBase:CallUpdateParams(...)
    if self.UpdateParams then
        self:UpdateParams(...)
    end
end

---@param UIInfo UIInfoClass
function UIWindowBase:SetUIInfo(UIInfo)
    self.UIInfo = UIInfo
    if UIInfo.ReleaseMouse then
        self.ShowMouseNode = UICommonUtil:CreateShowMouseNode(self, UIInfo.InputUIOnly)
    end
    if UIInfo.HideOtherLayer then
        local tbHideLayer = {}
        local tbHideLayerWhiteList = UIInfo.HideLayerWhiteList or {}
        for _, LayerName in pairs(UIDef.UILayer) do
            if LayerName ~= UIDef.UILayer[UIInfo.UILayerIdent + 1] and not TableUtil:Contains(tbHideLayerWhiteList, LayerName) then
                table.insert(tbHideLayer, LayerName)
            end
        end
        if #tbHideLayer > 0 then
            self.HideLayerNode = UICommonUtil:CreateHideLayerNode(self, tbHideLayer)
        end
    end
end

function UIWindowBase:AddShowWaitEvent(tbWaitEvent)
    if tbWaitEvent then
        for _, WaitEventObj in pairs(tbWaitEvent) do
            self.WaitShowEvents:AddWaitEvent(WaitEventObj)
        end
    end
end

function UIWindowBase:CleanupShowWaitEvent()
    self.WaitShowEvents:StopWait()
    self.WaitShowEvents:ClearWaitEvent()
end

function UIWindowBase:AddHideWaitEvent(tbWaitEvent)
    if tbWaitEvent then
        for _, WaitEventObj in pairs(tbWaitEvent) do
            self.WaitHideEvents:AddWaitEvent(WaitEventObj)
        end
    end
end

function UIWindowBase:CleanupHideWaitEvent()
    self.WaitHideEvents:StopWait()
    self.WaitHideEvents:ClearWaitEvent()
end

function UIWindowBase:ShowMyself(...)
    self:CallUpdateParams(...)
    self:BeginShow()
end

function UIWindowBase:AddShowWaitCloseUIEvent(tbOtherUIName)
    if tbOtherUIName then
        local WaitEventObj = UIWaitCloseOtherUI.new(self)
        WaitEventObj:AddWaitOtherUI(tbOtherUIName)
        self.WaitShowEvents:AddWaitEvent(WaitEventObj)
    end
end

function UIWindowBase:AddCloseWaitAniamtionEvent(tbAnimationObj)
    if tbAnimationObj then
        for _, AnimationObj in pairs(tbAnimationObj) do
            local WaitAnimObj = UIWaitAnimation.new(self)
            WaitAnimObj:SetWaitAnimation(AnimationObj)
            self.WaitHideEvents:AddWaitEvent(WaitAnimObj)
        end
    end
end

function UIWindowBase:CloseMyself(...)

    UIManager:CloseUI(self, ...)
end

function UIWindowBase:OnReturn(...)
    self:CloseMyself(...)
end

---@public
function UIWindowBase:PlayAkEventOnShow()
    if self.UIInfo.OpenAkEvent then
        local Valid = UE.UKismetSystemLibrary.IsValid(self.UIInfo.OpenAkEvent)
        if Valid then
            UE.UAkGameplayStatics.PostEvent(self.UIInfo.OpenAkEvent, UE.UGameplayStatics.GetPlayerPawn(self, 0), nil, nil, true)
            return
        end
    end
    
    if self.UIInfo.PageLevel == Enum.Enum_UILevel.SecondaryPage then
        
        local Valid, Event = self:BaseLoadAkEventByName(ComAK_Second_Open)
        if Valid then
            UE.UAkGameplayStatics.PostEvent(Event, UE.UGameplayStatics.GetPlayerPawn(self, 0), nil, nil, true)
        end
    elseif self.UIInfo.PageLevel == Enum.Enum_UILevel.ThreeLevelPage then
        local Valid, Event = self:BaseLoadAkEventByName(ComAK_Third_Open)
        if Valid then
            UE.UAkGameplayStatics.PostEvent(Event, UE.UGameplayStatics.GetPlayerPawn(self, 0), nil, nil, true)
        end
    end
end

---@public
function UIWindowBase:PlayAkEventOnHide()
    if self.UIInfo.CloseAkEvent then
        local Valid = UE.UKismetSystemLibrary.IsValid(self.UIInfo.OpenAkEvent)
        if Valid then
            UE.UAkGameplayStatics.PostEvent(self.UIInfo.OpenAkEvent, UE.UGameplayStatics.GetPlayerPawn(self, 0), nil, nil, true)
            return
        end
    end

    if self.UIInfo.PageLevel ==  Enum.Enum_UILevel.SecondaryPage then
        local Valid, AkEvent = self:BaseLoadAkEventByName(ComAK_Second_Close)
        if Valid then
            UE.UAkGameplayStatics.PostEvent(AkEvent, UE.UGameplayStatics.GetPlayerPawn(self, 0), nil, nil, true)
        end
    elseif self.UIInfo.PageLevel ==  Enum.Enum_UILevel.ThreeLevelPage then
        local Valid, AkEvent = self:BaseLoadAkEventByName(ComAK_Third_Close)
        if Valid then
            UE.UAkGameplayStatics.PostEvent(AkEvent, UE.UGameplayStatics.GetPlayerPawn(self, 0), nil, nil, true)
        end
    end
end

---@public [Tool]
---@param Name string
function UIWindowBase:BaseLoadAkEventByName(Name)
    local FunctionLib = FunctionUtil:GlobalUClass('GH_FunctionLib')
    if FunctionLib then
        local bExit, Row = FunctionLib.GetComAkEventPathByRowName(Name)
        if bExit and Row and Row.AkEvent then
            local Valid = UE.UKismetSystemLibrary.IsValid(Row.AkEvent)
            if Valid then
                return true, Row.AkEvent
            end
        end
    end
    return false, nil
end

return UIWindowBase
