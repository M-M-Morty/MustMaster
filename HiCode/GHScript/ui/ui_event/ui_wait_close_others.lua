--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
local UIWaitEventBase = require('CP0032305_GH.Script.ui.ui_event.ui_wait_event_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIEventDef = require('CP0032305_GH.Script.ui.ui_event.ui_event_def')

---@class UIWaitCloseOtherUI
local UIWaitCloseOtherUI = Class(UIWaitEventBase)

function UIWaitCloseOtherUI:ctor(UIObj)
    Super(UIWaitCloseOtherUI).ctor(self, UIObj)
    self.tbWaitCloseUI = {}
    self.tbShowedUI = {}

    self.fnNotification = function(OwnerUIObj, CloseUIObj)
        local UIName = CloseUIObj:GetUIName()
        local RemovedCount = TableUtil:ArrayRemoveValue(self.tbShowedUI, UIName)
        if #self.tbShowedUI == 0 then
            self:SetUnActive()
            self:ContainerTriggerWait()
        elseif RemovedCount > 0 then
            self:ContainerTriggerWait()
        end
    end
end

function UIWaitCloseOtherUI:AddWaitOtherUI(tbOtherUI)
    if not tbOtherUI then
        return
    end
    for _, UIName in pairs(tbOtherUI) do
        if not TableUtil:Contains(self.tbWaitCloseUI, UIName) then
            table.insert(self.tbWaitCloseUI, UIName)
        end
    end
end

function UIWaitCloseOtherUI:IsWaitBlockedImpl()
    return #self.tbShowedUI > 0
end

function UIWaitCloseOtherUI:OnActive()
    if self.UIObj and #self.tbWaitCloseUI > 0 then
        for _, UIName in pairs(self.tbWaitCloseUI) do
            local ShowedUI = UIManager:GetUIInstanceIfVisible(UIName)
            if ShowedUI then
                table.insert(self.tbShowedUI, UIName)
            end
        end

        if #self.tbShowedUI > 0 then
            UIManager.UINotifier:BindNotification(UIEventDef.UIHide, self.UIObj, self.fnNotification)
        else
            self:ContainerTriggerWait()
        end
    end
end

function UIWaitCloseOtherUI:OnUnActive()
    if self.UIObj then
        UIManager.UINotifier:UnbindNotification(self.UIObj, self.fnNotification)
    end
end

function UIWaitCloseOtherUI:OnReleaseEvent()
    self.tbWaitCloseUI = {}
    self.tbShowedUI = {}
end

return UIWaitCloseOtherUI
