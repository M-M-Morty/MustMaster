--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

-- 所有自定义UUserWidget的基类

local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWidgetField = require('CP0032305_GH.Script.framework.mvvm.ui_widget_field')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
local UICommonUtil = require('CP0032305_GH.Script.framework.ui.ui_common_utl')

---@class UIWidgetBase : UWidget
---@field tbWidgetField table
---@field tbNotificationField table
local UIWidgetBase = Class(WidgetProxys.UWidgetProxy)   -- Widget自己也是一个UWidgetProxy
UIWidgetBase.bIsUserWidget = true

function UIWidgetBase:Initialize(Initializer)
    self.UMGWidget = self
    self.tbNotificationField = {}
    self.tbOwnUserWidget = {}

    self:OnInitialize(Initializer)
end

function UIWidgetBase:OnInitialize(Initializer)
end

--function UIWidgetBase:PreConstruct(IsDesignTime)
--end

function UIWidgetBase:GetWidgetClass()
    return self:GetClass().Object
end

function UIWidgetBase:OnConstruct()
end

function UIWidgetBase:Construct()
    self.Overridden.Construct(self)

    UICommonUtil:AddToOwnerUserWidget(self)

    self:OnConstruct()
end

function UIWidgetBase:OnDestruct()
end

function UIWidgetBase:Destruct()
    self:OnDestruct()
    ViewModelBinder:UnBindByUI(self, false)
    UICommonUtil:RemoveFromOwnerUserWidget(self)
    self.Overridden.Destruct(self)
end

--function UIWidgetBase:Tick(MyGeometry, InDeltaTime)
--end

function UIWidgetBase:AddOwnUserWidget(SubUIObj)
    table.insert(self.tbOwnUserWidget, SubUIObj)
end

function UIWidgetBase:RemoveOwnUserWidget(SubUIObj)
    TableUtil:ArrayRemoveValue(self.tbOwnUserWidget, SubUIObj)
end

function UIWidgetBase:GetAllOwnUserWidget(tbUserWidgets)
    for _, UserWidget in pairs(self.tbOwnUserWidget) do
        table.insert(tbUserWidgets, UserWidget)
        UserWidget:GetAllOwnUserWidget(tbUserWidgets)
    end
end

function UIWidgetBase:CreateUserWidgetField(fnSetter, fnGetter)

    local WidgetField = UIWidgetField.new(self)
    WidgetField.Field_Getter = fnGetter
    WidgetField.Field_Setter = fnSetter
    WidgetField.UsedByUserWidget = self

    return WidgetField
end

function UIWidgetBase:CreateNotificationField(fnNotificationDelegate)
    if not fnNotificationDelegate then
        return
    end

    local ValueExist = TableUtil:FindIf(self.tbNotificationField, function(ValueInTable)
        if ValueInTable.Field_Notifier == fnNotificationDelegate then
            return true
        end
    end)

    if not ValueExist then
        local WidgetField = UIWidgetField.new(self)
        WidgetField.Field_Notifier = fnNotificationDelegate
        WidgetField.UsedByUserWidget = self

        table.insert(self.tbNotificationField, WidgetField)
        return WidgetField
    end
end

---@return UIWidgetField
function UIWidgetBase:GetNotificationField(fnNotificationDelegate)
    if not fnNotificationDelegate then
        return
    end

    return TableUtil:FindIf(self.tbNotificationField, function(ValueInTable)
        if ValueInTable.Field_Notifier == fnNotificationDelegate then
            return true
        end
    end)
end

function UIWidgetBase:GetAllNotificationField()
    return self.tbNotificationField
end

return UIWidgetBase
