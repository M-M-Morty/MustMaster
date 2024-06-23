--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
local UIWaitEventBase = require('CP0032305_GH.Script.ui.ui_event.ui_wait_event_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIEventDef = require('CP0032305_GH.Script.ui.ui_event.ui_event_def')

---@class UIWaitController
local UIWaitController = Class(UIWaitEventBase)

function UIWaitController:ctor(UIObj)
    Super(UIWaitController).ctor(self, UIObj)

    self.fnNotification = function()
        self:ContainerTriggerWait()
    end
end
function UIWaitController:IsWaitBlockedImpl()
    local controller = UE.UGameplayStatics.GetPlayerController(self.UIObj, 0)
    if controller and UE.UKismetSystemLibrary.IsValid(controller) then
        return false
    else
        return true
    end
end

function UIWaitController:OnActive()
    local controller = UE.UGameplayStatics.GetPlayerController(self.UIObj, 0)
    if controller and UE.UKismetSystemLibrary.IsValid(controller) then
        self:ContainerTriggerWait()
    else
        UIManager.UINotifier:BindNotification(UIEventDef.LoadPlayerController, self.UIObj, self.fnNotification)
    end
end

function UIWaitController:OnUnActive()
    if self.UIObj then
        UIManager.UINotifier:UnbindNotification(self.UIObj, self.fnNotification)
    end
end

function UIWaitController:OnReleaseEvent()

end

return UIWaitController
