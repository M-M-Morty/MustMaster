--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local ViewModelInterface = require('CP0032305_GH.Script.framework.mvvm.viewmodel_interface')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')

---@class ViewmodelField : ViewModelInterface
local ViewmodelField = Class(ViewModelInterface)

ViewmodelField.FieldValue = nil
ViewmodelField.GetFieldValue_Override = nil
ViewmodelField.SetFieldValue_Override = nil

function ViewmodelField:ctor(InViewModel, InFieldValue)
    self.tbDelegates = {}
    self.ViewModel = InViewModel
    self.FieldValue = InFieldValue
end

function ViewmodelField:IsViewModelField()
    return true
end

---@return ViewModelBase
function ViewmodelField:GetViewModel()
    return self.ViewModel
end

function ViewmodelField:GetFieldValue()
    if self.GetFieldValue_Override then
        return self.GetFieldValue_Override(self.ViewModel, self)
    end
    return self:RawGetFieldValue()
end

function ViewmodelField:RawGetFieldValue()
    return self.FieldValue
end

function ViewmodelField:SetFieldValue(InValue)
    if self.SetFieldValue_Override then
        self.SetFieldValue_Override(self.ViewModel, InValue, self)
    else
        self:RawSetFieldValue(InValue)
    end
end

function ViewmodelField:RawSetFieldValue(InValue)
    local CurrentValue = self:GetFieldValue()
    if CurrentValue ~= InValue then
        self.FieldValue = InValue
        self:BroadcastValueChanged()
    end
end

function ViewmodelField:SetOverrideGetter(fnGetter)
    if fnGetter and type(fnGetter) == 'function' then
        self.GetFieldValue_Override = fnGetter
    end
end

function ViewmodelField:SetOverrideSetter(fnSetter)
    if fnSetter and type(fnSetter) == 'function' then
        self.SetFieldValue_Override = fnSetter
    end
end

function ViewmodelField:ReleaseVMObj()
    ViewModelBinder:UnBindByViewModelField(self)
end

---@param WidgetField UIWidgetField
---@param fnCall function
function ViewmodelField:AddValueChangedDelegate(WidgetField, fnCall)
    self.tbDelegates[WidgetField] = fnCall
end

---@param WidgetField UIWidgetField
function ViewmodelField:RemoveValueChangedDelegate(WidgetField)
    self.tbDelegates[WidgetField] = nil
end

function ViewmodelField:BroadcastValueChanged(...)
    for WidgetField, fnCall in pairs(self.tbDelegates) do
        local WidgetProxy = WidgetField:GetWidgetProxy()
        if not WidgetProxy:IsWidgetValid() then
            G.log:warn('gh_ui', 'BroadcastValueChanged UMGWidget InValid.')
            return
        end
        fnCall(WidgetProxy, self:GetFieldValue(), ...)
    end
end

function ViewmodelField:BroadcastNotification(...)
    for WidgetField, fnCall in pairs(self.tbDelegates) do
        local WidgetProxy = WidgetField:GetWidgetProxy()
        if not WidgetProxy:IsWidgetValid() then
            G.log:warn('gh_ui', 'BroadcastNotification UMGWidget InValid.')
            return
        end
        fnCall(WidgetProxy, ...)
    end
end

return ViewmodelField
