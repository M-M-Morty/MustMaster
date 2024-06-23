--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local UICommonUtil = require('CP0032305_GH.Script.framework.ui.ui_common_utl')
local UINotifierClass = require('CP0032305_GH.Script.ui.ui_notifier')
local UIEventDef = require('CP0032305_GH.Script.ui.ui_event.ui_event_def')
--local UIManagerLauncher = require('CP0032305_GH.Script.Blueprints.Components.ui_manager_launcher')
local UIManager = {}
local LAYER_ZORDER = 100
UIManager.bInited = false
UIManager.tbCreatedUI = {}
UIManager.GameWorld = nil ---@type UWorld
UIManager.IngameLayerManager = nil ---@type WBP_Ingame_LayerManager_C
UIManager.UINotifier = nil ---@type UINotifier
UIManager.tb3DUIComponent = {}
UIManager.tbHideHUD = {}
---@class OverridenInputMode
local tbOverridenInputMode =
{
    UIOnly = 'InputMode_UIOnly',
    UIAndGame = 'InputMode_UIAndGame',
    GameOnly = 'InputMode_GameOnly',
}
UIManager.OverridenInputMode = tbOverridenInputMode

-- 支持PlayAsClent多Player的情况
-- 需要设定UnLua EnvLocatorClass=LuaEnvLocator_ByGameInstance
function UIManager:InitManager(WorldContext)
    if self.bInited then
        G.log:warn('gh_ui', 'UIManager can not Init twice.')
        return
    end
    if not WorldContext then
        G.log:error('gh_ui', 'InitManager Fail. WorldContext is nil')
        return
    end
    self:ResetData()

    self.GameWorld = WorldContext:GetWorld()
    if not self.GameWorld then
        G.log:error('gh_ui', 'InitManager Fail. GameWorld is nil')
    end
    local UIWindowStackManager = require('CP0032305_GH.Script.framework.ui.ui_window_stack_manager')
    self.UIWindowStackManager = UIWindowStackManager
    self:UpdatePlayerInputMode()
    UIManager.UINotifier:BindNotification(UIEventDef.LoadPlayerController,self,self.DefaultOpenUI)
    -- UIManager.UINotifier:BindNotification(UIEventDef.LoadPlayerController,self,self.InitUIIMC)
    self.ClassResArray = {}
    self.bInited = true
end

function UIManager:InitUIIMC()
--     local UEPlayerController = UE.UGameplayStatics.GetPlayerController(self.GameWorld, 0)
--     if not UEPlayerController then
--         G.log:error('gh_ui', 'InitUIIMCDefault Fail. UEPlayerController is nil')
--         return
--     end
--     local EnhancedInputLocalPlayerSubsystem = UE.USubsystemBlueprintLibrary.GetLocalPlayerSubsystem(UEPlayerController,
--     UE.UEnhancedInputLocalPlayerSubsystem)
--     if not EnhancedInputLocalPlayerSubsystem then
--         G.log:error('gh_ui', 'InitUIIMCDefault Fail. EnhancedInputLocalPlayerSubsystem is nil')
--         return
--     end
--     local IMC = self.IngameLayerManager.IMC
--     if not EnhancedInputLocalPlayerSubsystem:HasMappingContext(IMC) then
--         if IMC then
--             EnhancedInputLocalPlayerSubsystem:AddMappingContext(IMC, 150, UE.FModifyContextOptions())
--         end
--     end
end

function UIManager:UninitManager()
    if self.bInited then
        self.bInited = false
        local tbCurrentUI = TableUtil:ShallowCopy(self.tbCreatedUI)
        for _, wnd in pairs(tbCurrentUI) do
            UIManager:CloseUIImmediately(wnd, true)
        end
        self:CloseAllDestroyingUIImmediately()

        if self.IngameLayerManager and self.IngameLayerManager:IsValid() then
            self.IngameLayerManager:RemoveFromViewport()
        end

        local CurrentUIGameWorld = self.GameWorld
        self:ResetData()
        self:UpdatePlayerInputMode(CurrentUIGameWorld)
    end
end

function UIManager:ResetData()
    self.GameWorld = nil
    self.IngameLayerManager = nil
    self.tbCreatedUI = {}
    self.tbDestroyingUI = {}

    self.tbShowMouseNode = {}
    self.InputUIOnlyRefCount = 0

    self.tbUseUIImcNode = {}
    self.tbIMCs = {}
    self.AppointedInputMode = ''
    self.bUpdateInputModeFlag = true

    if self.UINotifier then
        self.UINotifier:CleanAllNotification()
    else
        self.UINotifier = UINotifierClass.new()
    end
end

function UIManager:OpenIngameLayerManager()
    if not self.GameWorld then
        G.log:error('gh_ui', 'OpenIngameLayerManager Fail. GameWorld is nil')
        return
    end
    if self.IngameLayerManager then
        return
    end

    local WidgetClassPath = '/Game/CP0032305_GH/UI/UMG/Ingame/WBP_Ingame_LayerManager.WBP_Ingame_LayerManager_C'
    local IngameLayerManagerUI = self:CreateWidgetInternal(WidgetClassPath)
    if IngameLayerManagerUI then
        IngameLayerManagerUI:AddToViewport(LAYER_ZORDER)
        self.IngameLayerManager = IngameLayerManagerUI
        -- self:DefaultOpenUI()
    end
end

function UIManager:DefaultOpenUI()
    for _, Info in pairs(UIDef.UIInfo) do
        if Info.DefaultOpen then
            self:OpenUI(Info)
        end
    end
end

---@param bVisible boolean
function UIManager:SetIngameLayerManagerVisibility(bVisible)
    if self.IngameLayerManager then
        local Visibility = bVisible and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Hidden
        self.IngameLayerManager:SetVisibility(Visibility)
    end
end

---@param InputMode string
function UIManager:SetOverridenInputMode(InputMode, bShowMouseCursor)
    if self.AppointedInputMode ~= InputMode then
        self.AppointedInputMode = InputMode
        self.bUpdateInputModeFlag = true
        if InputMode == '' then
            self.bShowMouseCursor = nil
        else
            self.bShowMouseCursor = bShowMouseCursor
        end
    end
    self:UpdatePlayerInputMode()
end

function UIManager:ClassRes(key)
    if not self.ClassResArray[key] or not self.ClassResArray[key]:IsValid() then
        self.ClassResArray[key] = self.IngameLayerManager:GlobalUClass(key)
    end
    return self.ClassResArray[key]
end

local function GetOrCreateUIInstance(UIManagerInst, UIInfo)
    if not UIInfo.UIName then
        return
    end
    if not UIManagerInst.IngameLayerManager then
        return
    end

    local UIInstance = UIManagerInst:GetUIInstance(UIInfo.UIName) ---@type UWidget
    if not UIInstance then
        UIInstance = UIManagerInst:CreateWidgetInternal(UIInfo.WidgetClassPath)
        if UIInstance then
            table.insert(UIManagerInst.tbCreatedUI, UIInstance)

            UIInstance:SetUIInfo(UIInfo)
            UIManagerInst.IngameLayerManager:AddWidgetToLayer(UIInstance) -- Widget Construct
            UIInstance:CallOnCreate()
        end
    end
    return UIInstance
end

---@param UIInfo UIInfoClass
---@return UIWindowBase
function UIManager:OpenUI(UIInfo, ...)
    local UIInstance = GetOrCreateUIInstance(self, UIInfo)
    if UIInstance then
        self.UIWindowStackManager:Push(UIInfo)
        UIInstance:CallUpdateParams(...)
        UIInstance:BeginShow()
        return UIInstance
    end
end

function UIManager:OpenLGUI(LGUIInfo, ...)
    local world = G.GameInstance:GetWorld()
    if not self.LGUIManager then
        local LGUIManagerClass = UE.UClass.Load("/Game/Blueprints/UI/LGUIManager.LGUIManager".."_C")
        self.LGUIManager = world:SpawnActor(LGUIManagerClass, nil, UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, nil)
        self.LGUIManager:Init()
    end
    local actorComponent = self.LGUIManager:OpenLGUI(LGUIInfo, ...)

    return actorComponent
end

function UIManager:CloseLGUI(LGUIInstance)
    if self.LGUIManager then
        self.LGUIManager:CloseLGUI(LGUIInstance)
    end
end

---@return UIWindowBase
function UIManager:CreateUIByName(UIName)
    local UIInfo = UIDef.UIInfo[UIName]
    if UIInfo then
        return GetOrCreateUIInstance(self, UIInfo)
    end
end

-- 常用功能的简便封装
function UIManager:CloseOtherAndOpenUI(UIName, tbOtherUIName, ...)
    local UIInst = self:CreateUIByName(UIName)
    if UIInst then
        tbOtherUIName = tbOtherUIName or {}

        UIInst:AddShowWaitCloseUIEvent(tbOtherUIName)
        UIInst:ShowMyself(...)

        for _, UIName in pairs(tbOtherUIName) do
            self:CloseUIByName(UIName)
        end
    end
end

---@param UIInstance UWidget
---@param DestroyUI boolean
function UIManager:CloseUI(UIInstance, DestroyUI)
    if not UIInstance or not UIInstance:IsValid() then
        return
    end

    DestroyUI = DestroyUI or UIInstance.UIInfo.DestroyClose
    if DestroyUI then
        TableUtil:ArrayRemoveValue(self.tbCreatedUI, UIInstance)
        table.insert(self.tbDestroyingUI, UIInstance)
    end
    self.UIWindowStackManager:RemoveInfo(UIInstance.UIInfo)
    UIInstance:BeginHide(DestroyUI)
end

function UIManager:CloseAllThirdPagesStack()
    self.UIWindowStackManager:ClearAllThirdPagesStack()
end

function UIManager:CloseUIByName(UIName, DestroyUI)
    local UIInstance = self:GetUIInstance(UIName)
    if UIInstance then
        self:CloseUI(UIInstance, DestroyUI)
    end
end

function UIManager:CloseUIImmediately(UIInstance, DestroyUI)
    if not UIInstance or not UIInstance:IsValid() then
        return
    end

    DestroyUI = DestroyUI or UIInstance.UIInfo.DestroyClose
    UIInstance:HideImmediately()

    if DestroyUI then
        UIInstance:CallOnDestroy()
        UIInstance:RemoveFromParent()
        TableUtil:ArrayRemoveValue(self.tbCreatedUI, UIInstance)
        TableUtil:ArrayRemoveValue(self.tbDestroyingUI, UIInstance)
    end
end

function UIManager:CloseDestroyingUIImmediately(UIName)
    TableUtil:ArrayRemoveIf(self.tbDestroyingUI, function(UIInstance)
        if UIInstance:GetUIName() == UIName then
            if UIInstance:IsValid() then
                UIInstance:HideImmediately()
                UIInstance:CallOnDestroy()
                UIInstance:RemoveFromParent()
                return true
            else
                return false
            end
        end
    end)
end

function UIManager:CloseAllDestroyingUIImmediately()
    for _, wnd in pairs(self.tbDestroyingUI) do
        wnd:HideImmediately()
        wnd:CallOnDestroy()
        wnd:RemoveFromParent()
    end
    self.tbDestroyingUI = {}
end

function UIManager:UpdatePlayerInputMode(CurrentUIGameWorld)
    if not self.bUpdateInputModeFlag then
        return
    end
    self.bUpdateInputModeFlag = false

    local WorldContext = CurrentUIGameWorld or self.GameWorld
    if not WorldContext then
        return
    end

    local UEPlayerController = UE.UGameplayStatics.GetPlayerController(WorldContext, 0)
    if not UEPlayerController then
        return
    end

    if self.AppointedInputMode == self.OverridenInputMode.GameOnly then
        if self.bShowMouseCursor then
            UEPlayerController.bShowMouseCursor = self.bShowMouseCursor
        else
            UEPlayerController.bShowMouseCursor = false
        end
        UE.UWidgetBlueprintLibrary.SetInputMode_GameOnly(UEPlayerController)
        return
    elseif self.AppointedInputMode == self.OverridenInputMode.UIAndGame then
        if self.bShowMouseCursor then
            UEPlayerController.bShowMouseCursor = self.bShowMouseCursor
        else
            UEPlayerController.bShowMouseCursor = false
        end
        UE.UWidgetBlueprintLibrary.SetInputMode_GameAndUIEx(UEPlayerController, self.IngameLayerManager,
            UE.EMouseLockMode.DoNotLock, true, true)
        return
    elseif self.AppointedInputMode == self.OverridenInputMode.UIOnly then
        if self.bShowMouseCursor then
            UEPlayerController.bShowMouseCursor = self.bShowMouseCursor
        else
            UEPlayerController.bShowMouseCursor = false
        end
        UE.UWidgetBlueprintLibrary.SetInputMode_UIOnlyEx(UEPlayerController, self.IngameLayerManager,
            UE.EMouseLockMode.DoNotLock, true)
        return
    end

    if #self.tbShowMouseNode > 0 then
        UEPlayerController.bShowMouseCursor = true
        if self.InputUIOnlyRefCount > 0 then
            UE.UWidgetBlueprintLibrary.SetInputMode_UIOnlyEx(UEPlayerController, self.IngameLayerManager,
                UE.EMouseLockMode.DoNotLock, true)
        else
            UE.UWidgetBlueprintLibrary.SetInputMode_GameAndUIEx(UEPlayerController, self.IngameLayerManager,
                UE.EMouseLockMode.DoNotLock, true, true)
        end
    else
        UEPlayerController.bShowMouseCursor = false
        UE.UWidgetBlueprintLibrary.SetInputMode_GameOnly(UEPlayerController)
    end
end

---@param ShowMouseNode UIShowMouseNode
function UIManager:ContainsShowMouseNode(ShowMouseNode)
    return TableUtil:Contains(self.tbShowMouseNode, ShowMouseNode)
end

---@param ShowMouseNode UIShowMouseNode
function UIManager:AddShowMouseNode(ShowMouseNode)
    if not TableUtil:Contains(self.tbShowMouseNode, ShowMouseNode) then
        table.insert(self.tbShowMouseNode, ShowMouseNode)
        if ShowMouseNode.InputUIOnly then
            self.InputUIOnlyRefCount = self.InputUIOnlyRefCount + 1
        end
        self.bUpdateInputModeFlag = true
    end
end

---@param ShowMouseNode UIShowMouseNode
function UIManager:RemoveShowMouseNode(ShowMouseNode)
    local RemovedCount = TableUtil:ArrayRemoveIf(self.tbShowMouseNode, function(NodeInTable)
        if NodeInTable == ShowMouseNode then
            if NodeInTable.InputUIOnly then
                self.InputUIOnlyRefCount = self.InputUIOnlyRefCount - 1
            end
            return true
        end
    end)
    self.InputUIOnlyRefCount = math.max(self.InputUIOnlyRefCount, 0)
    if RemovedCount > 0 then
        self.bUpdateInputModeFlag = true
    end
end

---@param UIHideLayerNode UIHideLayerNode
function UIManager:AddHideLayerNode(UIHideLayerNode)
    if self.IngameLayerManager and UIHideLayerNode then
        self.IngameLayerManager:AddHideLayerNode(UIHideLayerNode)
    end
end

---@param UIHideLayerNode UIHideLayerNode
function UIManager:RemoveHideLayerNode(UIHideLayerNode)
    if self.IngameLayerManager and UIHideLayerNode then
        self.IngameLayerManager:RemoveHideLayerNode(UIHideLayerNode)
    end
end

---@param tbLayerNames table
function UIManager:SetOtherLayerHiddenExcept(tbLayerNames)
    local LayerRealNames = {}
    for Index, LayerId in pairs(tbLayerNames) do
        LayerRealNames[Index] = UIDef.UILayer[LayerId + 1]
    end
    if self.IngameLayerManager then
        local tbHideLayer = {}
        for LayerId, LayerName in pairs(UIDef.UILayer) do
            if not TableUtil:Contains(LayerRealNames, LayerName) then
                table.insert(tbHideLayer, LayerName)
            end
        end
        if #tbHideLayer > 0 then
            local HiddenLayerContext = UICommonUtil:CreateHideLayerNode(nil, tbHideLayer)
            self:AddHideLayerNode(HiddenLayerContext)
            return HiddenLayerContext
        end
    end
    return {}
end

function UIManager:ResetHiddenLayerContext(HiddenLayerContext)
    self:RemoveHideLayerNode(HiddenLayerContext)
end

function UIManager:CreateWidgetInternal(WidgetClassPath)
    if not self.GameWorld then
        return
    end

    if UE.UKismetSystemLibrary.IsServer(self.GameWorld) then
        return
    end

    local WidgetClass = UE.UClass.Load(WidgetClassPath)
    if WidgetClass then
        local WidgetInstance = UE.UWidgetBlueprintLibrary.Create(self.GameWorld, WidgetClass)
        if WidgetInstance then
            return WidgetInstance
        end
    else
        G.log:warn('gh_ui', 'CreateWidget Fail. Cannot load widget %s', WidgetClassPath)
    end
end

---@return UWidget
function UIManager:GetUIInstance(UIName)
    local FoundedUI = TableUtil:FindIf(self.tbCreatedUI, function(UIInstance)
        if UIInstance.UIInfo.UIName == UIName then
            return true
        end
    end)
    return FoundedUI
end

function UIManager:GetUIInstanceIfVisible(UIName)
    local UIInstance = self:GetUIInstance(UIName)
    if UIInstance and not UIInstance:IsWindowStateHidden() then
        return UIInstance
    end
end

function UIManager:RegisterPressedKeyDelegate(UIObj, fnDelegate)
    if self.IngameLayerManager then
        self.IngameLayerManager:RegisterPressedKeyDelegate(UIObj, fnDelegate)
    end
end

function UIManager:UnRegisterPressedKeyDelegate(UIObj)
    if self.IngameLayerManager then
        self.IngameLayerManager:UnRegisterPressedKeyDelegate(UIObj)
    end
end

function UIManager:RegisterReleasedKeyDelegate(UIObj, fnDelegate)
    if self.IngameLayerManager then
        self.IngameLayerManager:RegisterReleasedKeyDelegate(UIObj, fnDelegate)
    end
end

function UIManager:UnRegisterReleasedKeyDelegate(UIObj)
    if self.IngameLayerManager then
        self.IngameLayerManager:UnRegisterReleasedKeyDelegate(UIObj)
    end
end

function UIManager:DispatchActionTriggered(ActionName, ActionValue, ElapsedSeconds, TriggeredSeconds, InputAction)
end

function UIManager:DispatchActionStarted(ActionName, ActionValue, ElapsedSeconds, TriggeredSeconds, InputAction)
    if self.IngameLayerManager then
        self.IngameLayerManager:DispatchPressedKeyAction(ActionName, ActionValue, ElapsedSeconds, TriggeredSeconds,
            InputAction)
    end
end

function UIManager:DispatchActionCompleted(ActionName, ActionValue, ElapsedSeconds, TriggeredSeconds, InputAction)
    if self.IngameLayerManager then
        self.IngameLayerManager:DispatchReleasedKeyAction(ActionName, ActionValue, ElapsedSeconds, TriggeredSeconds,
            InputAction)
    end
end

function UIManager:DispatchActionCanceled(ActionName, ActionValue, ElapsedSeconds, TriggeredSeconds, InputAction)
end

function UIManager:Add3DUIComponent(component)
    if component then
        table.insert(self.tb3DUIComponent, component)
    end
end

function UIManager:Remove3DUIComponent(component)
    TableUtil:ArrayRemoveValue(self.tb3DUIComponent, component)
end

function UIManager:HideAll3DUIComponent()
    for _, component in pairs(self.tb3DUIComponent) do
        if component and UE.UKismetSystemLibrary.IsValid(component) then
                component:HiddenComponent()
            else
                self:Remove3DUIComponent(component)
        end
    end
end

function UIManager:RecoverShowAll3DUIComponent()
    for _, component in pairs(self.tb3DUIComponent) do
        if component and UE.UKismetSystemLibrary.IsValid(component) then
            component:ShowComponent()
        else
            self:Remove3DUIComponent(component)
        end
    end
end

function UIManager:HideAllHUD()
    if self.bHideAllHUD then
        return
    end
    self.tbHideHUD = {}
    for _, UI in pairs(self.tbCreatedUI) do
        if UI.UIInfo.PageLevel == Enum.Enum_UILevel.FirstPage then
            if not UI:IsWindowStateHidden() then
                table.insert(self.tbHideHUD, UI)
                UI:BeginHide()
            end
        end
    end
    self:HideAll3DUIComponent()
    self.bHideAllHUD = true
end

function UIManager:RecoverShowAllHUD()
    if not self.bHideAllHUD then
        return
    end
    for _, UI in pairs(self.tbHideHUD) do
        if self:GetUIInstance(UI.UIInfo.UIName) then
            UI:BeginShow()
        end
    end
    self.tbHideHUD = {}
    self:RecoverShowAll3DUIComponent()
    self.bHideAllHUD = false
end

function UIManager:GetStackManager()
    return UIManager.UIWindowStackManager
end
return UIManager
