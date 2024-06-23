--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

---@class UIShowMouseNode
local UIShowMouseNode = Class()

function UIShowMouseNode:ctor(UIObj, InInputUIOnly)
    self.UIObj = UIObj
    self.InputUIOnly = InInputUIOnly
end

---@class UIHideLayerNode
---@field UIObj UWidget
---@field HideLayers table
local UIHideLayerNode = Class()

function UIHideLayerNode:ctor(UIObj, InHideLayers)
    self.UIObj = UIObj
    self.HideLayers = InHideLayers
end

---@class UIAdditionalIMCNode
---@field UIObj UWidget
local UIAdditionalIMCNode = Class()

function UIAdditionalIMCNode:ctor(UIObj, path)
    self.UIObj = UIObj
    self.IMCPath = path
end

local UICommonUtil = {}

function UICommonUtil:ConvRootObjToRootWidget(RootObj)
    if RootObj then
        if RootObj.WidgetTree then -- UUserWidget
            local TreeRoot = RootObj.WidgetTree.RootWidget
            if TreeRoot and TreeRoot.GetAllChildren then
                return TreeRoot
            end
        elseif RootObj.GetAllChildren then
            return RootObj
        end
    end
end

function UICommonUtil:GetWidgetHasChild(RootObj, tbAllWidget)
    local RootWidget = self:ConvRootObjToRootWidget(RootObj)
    if RootWidget then
        local Children = RootWidget:GetAllChildren()
        local ChildNum = Children:Length()
        if ChildNum > 0 then
            table.insert(tbAllWidget, RootWidget)
        end
        for _, ChildWidget in pairs(Children) do
            UICommonUtil:GetWidgetHasChild(ChildWidget, tbAllWidget)
        end
    end
end

function UICommonUtil:GetChildWidgetBy(RootObj, tbOutWidget, fnChecker)
    local RootWidget = self:ConvRootObjToRootWidget(RootObj)
    if RootWidget then
        local Children = RootWidget:GetAllChildren()
        for _, ChildWidget in pairs(Children) do
            if fnChecker(ChildWidget) then
                table.insert(tbOutWidget, ChildWidget)
            end
            UICommonUtil:GetChildWidgetBy(ChildWidget, tbOutWidget, fnChecker)
        end
    end
end

function UICommonUtil:ForeachInWidget(RootObj, fnCall)
    if not RootObj or not fnCall then
        return
    end
    
    if RootObj then
        fnCall(RootObj)
    end

    local RootWidget = self:ConvRootObjToRootWidget(RootObj)
    if RootWidget then
        local Children = RootWidget:GetAllChildren():ToTable()
        for _, ChildWidget in pairs(Children) do
            UICommonUtil:ForeachInWidget(ChildWidget, fnCall)
        end
    end
end

function UICommonUtil:GetOwnerUserWidget(Widget)
    if not Widget or not UE.UKismetSystemLibrary.IsValid(Widget) then
        return
    end

    local OuterObj = UE.UKismetSystemLibrary.GetOuterObject(Widget)
    if not OuterObj then
        return
    end

    if UE.UGameplayStatics.ObjectIsA(OuterObj, UE.UWidgetTree) then
        OuterObj = UE.UKismetSystemLibrary.GetOuterObject(OuterObj)
    end
    if not OuterObj then
        return
    end

    if OuterObj.bIsUserWidget then
        return OuterObj
    else
        -- 是一个UserWidget但是没有绑定脚本，继续找这个UserWidget的OwnerUserWidget
        if UE.UGameplayStatics.ObjectIsA(OuterObj, UE.UUserWidget) then
            return self:GetOwnerUserWidget(OuterObj)
        end
    end
end

function UICommonUtil:AddToOwnerUserWidget(UIObj)
    if not UIObj then
        return
    end

    local OwnerWidget = self:GetOwnerUserWidget(UIObj)
    if OwnerWidget and OwnerWidget ~= UIObj then
        OwnerWidget:AddOwnUserWidget(UIObj)
        UIObj.OwnerUserWidgetObj = OwnerWidget
    end
end

function UICommonUtil:RemoveFromOwnerUserWidget(UIObj)
    if UIObj and UIObj.OwnerUserWidgetObj then
        UIObj.OwnerUserWidgetObj:RemoveOwnUserWidget(UIObj)
    end
end

---@return UIShowMouseNode
function UICommonUtil:CreateShowMouseNode(UIObj, InputUIOnly)
    return UIShowMouseNode.new(UIObj, InputUIOnly)
end

---@return UIHideLayerNode
function UICommonUtil:CreateHideLayerNode(UIObj, tbHideLayer)
    return UIHideLayerNode.new(UIObj, tbHideLayer)
end

---@return UIAdditionalIMCNode
function UICommonUtil:CreateAdditionalIMCNode(UIObj, IMCPath)
    if not IMCPath then
        return nil
    end
    local obj = UE.UObject.Load(IMCPath)
    if not obj then
        return nil
    end 
    return UIAdditionalIMCNode.new(UIObj, IMCPath)
end

return UICommonUtil
