--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local UICommonUtil = require('CP0032305_GH.Script.framework.ui.ui_common_utl')
local LinkListUtil = require('CP0032305_GH.Script.common.utils.linklist_utl')

local DEBUG_LIST_ENABLE = false


---@class ViewModelBindingHandler
local ViewModelBindingHandler = Class()

---@param InWidgetField UIWidgetField
---@param InViewModelField ViewmodelField
function ViewModelBindingHandler:ctor(InWidgetField, InViewModelField)
    self.WidgetField = InWidgetField
    self.ViewModelField = InViewModelField

    self.WidgetFieldNode = LinkListUtil.NodeClass.new()
    self.WidgetFieldNode.HandlerRef = self

    self.UserWidgetNode = LinkListUtil.NodeClass.new()
    self.UserWidgetNode.HandlerRef = self

    self.VMFieldNode = LinkListUtil.NodeClass.new()
    self.VMFieldNode.HandlerRef = self

    self.ViewModelNode = LinkListUtil.NodeClass.new()
    self.ViewModelNode.HandlerRef = self

    if DEBUG_LIST_ENABLE then
        self.DebugNode = LinkListUtil.NodeClass.new()
        self.DebugNode.HandlerRef = self
    end
end

function ViewModelBindingHandler:ReleaseHandler()
    if self.WidgetField and self.ViewModelField then
        self.WidgetField:RemoveFieldChangedDelegate(self.ViewModelField)
        self.ViewModelField:RemoveValueChangedDelegate(self.WidgetField)

        self.WidgetField = nil
        self.ViewModelField = nil
    end

    self.WidgetFieldNode:RemoveFromContainer()
    self.UserWidgetNode:RemoveFromContainer()
    self.VMFieldNode:RemoveFromContainer()
    self.ViewModelNode:RemoveFromContainer()

    if DEBUG_LIST_ENABLE then
        self.DebugNode:RemoveFromContainer()
    end
end


local function EnsureVMBinderList(obj)
    if not obj.__VMBinderList__ then
        obj.__VMBinderList__ = LinkListUtil:CreateList()
    end
    return obj.__VMBinderList__
end

local function GetVMBinderList(obj)
    return obj.__VMBinderList__
end

---@class ViewModelBindingContainer
local ViewModelBindingContainer = Class()
function ViewModelBindingContainer:ctor()
    if DEBUG_LIST_ENABLE then
        self.DebugHandlerList = LinkListUtil:CreateList()
    end
end

---@param Handler ViewModelBindingHandler
function ViewModelBindingContainer:AddVMBindingHandler(Handler)
    local WidgetField = Handler.WidgetField
    if WidgetField then
        EnsureVMBinderList(WidgetField):AddTail(Handler.WidgetFieldNode)
        
        local UserWidget = WidgetField.UsedByUserWidget    
        if UserWidget then
            EnsureVMBinderList(UserWidget):AddTail(Handler.UserWidgetNode)
        end
    end

    local VMField = Handler.ViewModelField
    if VMField then
        EnsureVMBinderList(VMField):AddTail(Handler.VMFieldNode)

        local ViewModelObj = VMField:GetViewModel()
        EnsureVMBinderList(ViewModelObj):AddTail(Handler.ViewModelNode)
    end

    if DEBUG_LIST_ENABLE then
        self.DebugHandlerList:AddTail(Handler.DebugNode)
    end
end

function ViewModelBindingContainer:UnBindByUI(UserWidget)
    if UserWidget then
        local VMBinderList = GetVMBinderList(UserWidget)
        if VMBinderList and VMBinderList:GetSize() > 0 then
            for Node in VMBinderList:Nodes_Iterator() do
                Node.HandlerRef:ReleaseHandler()
            end
        end
    end
end

function ViewModelBindingContainer:UnBindByViewModel(ViewModelObj)
    if ViewModelObj then
        local VMBinderList = GetVMBinderList(ViewModelObj)
        if VMBinderList and VMBinderList:GetSize() > 0 then
            for Node in VMBinderList:Nodes_Iterator() do
                Node.HandlerRef:ReleaseHandler()
            end
        end
    end
end

---@param WidgetField UIWidgetField
function ViewModelBindingContainer:UnBindByWidgetField(WidgetField)
    if WidgetField then
        local VMBinderList = GetVMBinderList(WidgetField)
        if VMBinderList and VMBinderList:GetSize() > 0 then
            for Node in VMBinderList:Nodes_Iterator() do
                Node.HandlerRef:ReleaseHandler()
            end
        end
    end
end

---@param ViewModelField ViewmodelField
function ViewModelBindingContainer:UnBindByViewModelField(ViewModelField)
    if ViewModelField then
        local VMBinderList = GetVMBinderList(ViewModelField)
        if VMBinderList and VMBinderList:GetSize() > 0 then
            for Node in VMBinderList:Nodes_Iterator() do
                Node.HandlerRef:ReleaseHandler()
            end
        end
    end
end


---@class ViewModelBinder
local ViewModelBinder = Class()
ViewModelBinder.tbViewModelBindingContainer = ViewModelBindingContainer.new()

-- ViewModel数据的绑定方式
ViewModelBinder.BindWayToWidget       = 1     -- VM -> UIWidget
ViewModelBinder.BindWayToVM           = 2     -- UIWidget -> VM
ViewModelBinder.NotifyUI              = 3     -- VM -> UIObj

---@param WidgetField UIWidgetField
---@param ViewModelField ViewmodelField
function ViewModelBinder:BindViewModel(WidgetField, ViewModelField, BindWay)
    if not WidgetField or not ViewModelField or not ViewModelField:IsViewModelField() then
        return
    end

    local WidgetProxy = WidgetField:GetWidgetProxy()
    if BindWay == ViewModelBinder.BindWayToVM then
        if not WidgetField.Field_Getter then
            G.log:warn('gh_ui', 'BindViewModel Fail. WidgetField: %s missing Getter', WidgetField:GetDebugName())
            return
        end
        -- init ViewModel field value from Widget
        ViewModelField:SetFieldValue(WidgetField.Field_Getter(WidgetProxy))
    end
    if BindWay == ViewModelBinder.BindWayToWidget then
        if not WidgetField.Field_Setter then
            G.log:warn('gh_ui', 'BindViewModel Fail. WidgetField: %s missing Setter', WidgetField:GetDebugName())
            return
        end
        -- init widget field value from ViewModel
        WidgetField.Field_Setter(WidgetProxy, ViewModelField:GetFieldValue())
    end

    if BindWay == ViewModelBinder.BindWayToVM then
        WidgetField:AddFieldhangedDelegate(ViewModelField, function(InViewModelField, InValue, ...)
            InViewModelField:SetFieldValue(InValue, ...)
        end)
    end
    if BindWay == ViewModelBinder.BindWayToWidget then
        ViewModelField:AddValueChangedDelegate(WidgetField, function(InWidgetProxy, Value, ...)
            WidgetField.Field_Setter(InWidgetProxy, Value, ...)
        end)
    end
    if BindWay == ViewModelBinder.NotifyUI then
        if not WidgetField.Field_Notifier then
            G.log:warn('gh_ui', 'BindViewModel Fail. WidgetField: %s missing Notifier', WidgetField:GetDebugName())
            return
        end
        ViewModelField:AddValueChangedDelegate(WidgetField, function(InWidgetProxy, ...)
            WidgetField.Field_Notifier(InWidgetProxy, ...)
        end)
    end

    if not WidgetField.UsedByUserWidget then
        WidgetField.UsedByUserWidget = UICommonUtil:GetOwnerUserWidget(WidgetProxy:GetUMGWidget())
        if not WidgetField.UsedByUserWidget then
            G.log:warn('gh_ui', 'BindViewModel Error. WidgetField: %s has no UsedByUserWidget', WidgetField:GetDebugName())
        end
    end

    local NewHandler = ViewModelBindingHandler.new(WidgetField, ViewModelField)
    self.tbViewModelBindingContainer:AddVMBindingHandler(NewHandler)
end

function ViewModelBinder:UnBindByUI(UIObj, bIncludeAll)
    -- 清除在此UI下的Handler
    local tbUserWidgets = {UIObj}
    if bIncludeAll then
        UIObj:GetAllOwnUserWidget(tbUserWidgets)
    end

    for _, UserWidget in pairs(tbUserWidgets) do
        self.tbViewModelBindingContainer:UnBindByUI(UserWidget)
    end
end

function ViewModelBinder:UnBindByViewModel(ViewModelObj)
    self.tbViewModelBindingContainer:UnBindByViewModel(ViewModelObj)
end

---@param WidgetField UIWidgetField
function ViewModelBinder:UnBindByWidgetField(WidgetField)
    self.tbViewModelBindingContainer:UnBindByWidgetField(WidgetField)
end

---@param ViewModelField ViewmodelField
function ViewModelBinder:UnBindByViewModelField(ViewModelField)
    self.tbViewModelBindingContainer:UnBindByViewModelField(ViewModelField)
end

return ViewModelBinder
