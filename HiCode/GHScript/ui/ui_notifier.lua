--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')

---@class UINotifierVM : ViewModelBase
local UINotifierVM = Class(ViewModelBaseClass)

function UINotifierVM:ctor()
    Super(UINotifierVM).ctor(self)
end

function UINotifierVM:OnReleaseViewModel()
end


---@class UINotifier
local UINotifierClass = Class()

function UINotifierClass:ctor()
    self.NotifierVM = UINotifierVM.new()
    self.tbNotificationField = {}
end

---@param Inst UINotifier
---@return ViewmodelField
local function FindOrAddNotificationField(Inst, NotificationName)
    local NotificationField = Inst.tbNotificationField[NotificationName]
    if not NotificationField then
        NotificationField = Inst.NotifierVM:CreateVMField()
        Inst.tbNotificationField[NotificationName] = NotificationField
    end
    return NotificationField
end

---@param NotificationName string
---@param UIObj UIWidgetBase
---@param fnDelegate function
---@return boolean
function UINotifierClass:BindNotification(NotificationName, UIObj, fnDelegate)
    if not NotificationName or
        not UIObj or not UIObj.CreateNotificationField or
        not fnDelegate or NotificationName == '' then
        return false
    end

    local NotificationField = FindOrAddNotificationField(self, NotificationName)
    if NotificationField then
        local UIWidgetField = UIObj:GetNotificationField(fnDelegate)
        if not UIWidgetField then
            UIWidgetField = UIObj:CreateNotificationField(fnDelegate)
        end
        if UIWidgetField then
            ViewModelBinder:BindViewModel(UIWidgetField, NotificationField, ViewModelBinder.NotifyUI)
        end
    end
end

---@param UIObj UIWidgetBase
---@param fnDelegate function
function UINotifierClass:UnbindNotification(UIObj, fnDelegate)
    if not UIObj or not UIObj.GetNotificationField or not fnDelegate then
        return
    end

    local WidgetField = UIObj:GetNotificationField(fnDelegate)
    if WidgetField then
        ViewModelBinder:UnBindByWidgetField(WidgetField)
    end
end

---@param UIObj UIWidgetBase
function UINotifierClass:UnbindAllNotification(UIObj)
    local tbWidgetField = UIObj:GetAllNotificationField()
    if tbWidgetField then
        for _, WidgetField in pairs(tbWidgetField) do
            ViewModelBinder:UnBindByWidgetField(WidgetField)
        end
    end
end

---@param NotificationName string
function UINotifierClass:UINotify(NotificationName, ...)
    local NotificationField = self.tbNotificationField[NotificationName]
    if NotificationField then
        NotificationField:BroadcastNotification(...)
    end
end

function UINotifierClass:CleanAllNotification()
    self.NotifierVM:ReleaseVMObj()
    self.tbNotificationField = {}
end

return UINotifierClass
