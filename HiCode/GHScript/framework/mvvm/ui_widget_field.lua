--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

---@class UIWidgetField
local UIWidgetField = Class()

UIWidgetField.Field_Getter = nil                    ---@type function
UIWidgetField.Field_Setter = nil                    ---@type function
UIWidgetField.Field_Notifier = nil                  ---@type function
UIWidgetField.UsedByUserWidget = nil

function UIWidgetField:ctor(InWidgetProxy)
    self.tbDelegates = {}
    self.WidgetProxy = InWidgetProxy
end

---@return UWidgetProxy
function UIWidgetField:GetWidgetProxy()
    return self.WidgetProxy
end

function UIWidgetField:GetDebugName()
    return UE.UKismetSystemLibrary.GetDisplayName(self.WidgetProxy.UMGWidget)
end

---@param ViewModelField ViewmodelField
---@param fnCall function
function UIWidgetField:AddFieldhangedDelegate(ViewModelField, fnCall)
    self.tbDelegates[ViewModelField] = fnCall
end

---@param ViewModelField ViewmodelField
function UIWidgetField:RemoveFieldChangedDelegate(ViewModelField)
    self.tbDelegates[ViewModelField] = nil
end

function UIWidgetField:BroadcastFieldChanged(...)
    for ViewModelField, fnCall in pairs(self.tbDelegates) do
        fnCall(ViewModelField, ...)
    end
end

return UIWidgetField
