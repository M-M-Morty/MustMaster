--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local InputDef = require('CP0032305_GH.Script.common.input_define')
local UICommonUtil = require('CP0032305_GH.Script.framework.ui.ui_common_utl')
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local UIEventDef = require('CP0032305_GH.Script.ui.ui_event.ui_event_def')

local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')

---@type WBP_Ingame_LayerManager_C
local IngameLayerManager = Class(UIWindowBase)

--function IngameLayerManager:Initialize(Initializer)
--end

--function IngameLayerManager:PreConstruct(IsDesignTime)
--end

function IngameLayerManager:OnConstruct()
    self.UEPlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.AltShowMouseNode = UICommonUtil:CreateShowMouseNode(self, true)
    self.CaptureMouseButton.OnClicked:Add(self, self.CaptureMouseButton_OnClicked)

    self.tbPressedKeyDelegate = {}
    self.tbReleasedKeyDelegate = {}

    self:RegisterPressedKeyDelegate(self, self.OnPressKeyEvent)
    self:RegisterReleasedKeyDelegate(self, self.OnReleaseKeyEvent)

    self.tbHideLayerNode = {}
    self.tbLayerData = {}
    for _, LayerName in pairs(UIDef.UILayer) do
        if self[LayerName] then
            self.tbLayerData[LayerName] = { HideRefCount = 0 }
        end
    end
end

---用于屏蔽3DUI输入模式时第一次先捕获全屏按钮，todo 捕获游戏外鼠标回到游戏
function IngameLayerManager:StartShowLGUI()
    self:UnRegisterPressedKeyDelegate(self)
    self:UnRegisterReleasedKeyDelegate(self)
    self.CaptureMouseButton:SetVisibility(UE.ESlateVisibility.Hidden)
end

function IngameLayerManager:StopShowLGUI()
    self:RegisterPressedKeyDelegate(self, self.OnPressKeyEvent)
    self:RegisterReleasedKeyDelegate(self, self.OnReleaseKeyEvent)
    self.CaptureMouseButton:SetVisibility(UE.ESlateVisibility.Visible)
end

function IngameLayerManager:OnDestruct()
end

-- function IngameLayerManager:Tick(MyGeometry, InDeltaTime)
-- end

function IngameLayerManager:OneSecondEvent()
    ViewModelCollection:TickUniqueViewModels()
end

function IngameLayerManager:GlobalUClass(key)
    local obj = self:ClassRes(key)
    local classPath = UE.UKismetSystemLibrary.BreakSoftObjectPath(obj.ClassPath)
    return UE.UClass.Load(classPath .. "_C")
end

function IngameLayerManager:UIClassPath(UIName)
    local obj = self:ClassRes(UIName)
    return UE.UKismetSystemLibrary.BreakSoftObjectPath(obj.ClassPath)
end

function IngameLayerManager:OnPressKeyEvent(KeyName, bFromGame)
    -- if InputDef.Keys.LeftAlt == KeyName then
    if InputDef.Actions.ReleaseMouseAction == KeyName then
        if bFromGame then
            -- 鼠标脱锁，焦点置于本窗口，此刻按键消息由此窗口接管
            self:SetGameReleaseMouse(true)
        end
        return true
    end
end

function IngameLayerManager:OnReleaseKeyEvent(KeyName, bFromGame)
    -- if InputDef.Keys.LeftAlt == KeyName then
    if not bFromGame and InputDef:IsAction(KeyName, InputDef.Actions.ReleaseMouseAction) then
        -- 从UI来的释放消息
        self:SetGameReleaseMouse(false)
        return true
    end
end

function IngameLayerManager:CaptureMouseButton_OnClicked()
    self:SetGameReleaseMouse(false)
end

function IngameLayerManager:SetGameReleaseMouse(bReleaseMouse)
    if bReleaseMouse then
        UIManager:AddShowMouseNode(self.AltShowMouseNode)
    else
        UIManager:RemoveShowMouseNode(self.AltShowMouseNode)
    end
    -- IngameLayerManager中修改InputMode强行刷新，可以修正一些PIE运行时的输入异常状态，比如按Win键脱锁后点回游戏
    UIManager.bUpdateInputModeFlag = true
    UIManager:UpdatePlayerInputMode()
end

---@param WidgetInstance UWidget
function IngameLayerManager:AddWidgetToLayer(WidgetInstance)
    if not WidgetInstance then
        return
    end

    local LayerName = UIDef.UILayer[WidgetInstance.UIInfo.UILayerIdent + 1] or ''
    local targetLayer = self[LayerName] --- @type UCanvasPanel
    if not targetLayer then
        G.log:warn('gh_ui', 'AddWidgetToLayer Fail. Layer %s not exist')
    end

    local CanvasSlot = targetLayer:AddChildToCanvas(WidgetInstance)

    local Anchors = UE.FAnchors()
    Anchors.Minimum = UE.FVector2D(0, 0)
    Anchors.Maximum = UE.FVector2D(1, 1)
    CanvasSlot:SetAnchors(Anchors)

    CanvasSlot:SetOffsets(UE.FMargin())

    local ZOrder = WidgetInstance.UIInfo.ZOrder or 0
    CanvasSlot:SetZOrder(ZOrder)
end

function IngameLayerManager:UpdateLayerVisibility()
    for LayerName, LayerData in pairs(self.tbLayerData) do
        ---@type UCanvasPanel
        local LayerWidget = self[LayerName]
        if LayerWidget then
            if LayerData.HideRefCount > 0 then
                UIManager.UINotifier:UINotify(UIEventDef["Hidden"..LayerName], self)
                LayerWidget:SetVisibility(UE.ESlateVisibility.Hidden)
            else
                UIManager.UINotifier:UINotify(UIEventDef["Visible"..LayerName], self)
                LayerWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            end
        end
    end
end

---@param UIHideLayerNode UIHideLayerNode
function IngameLayerManager:AddHideLayerNode(UIHideLayerNode)
    if UIHideLayerNode and UIHideLayerNode.HideLayers then
        if not TableUtil:Contains(self.tbHideLayerNode, UIHideLayerNode) then
            table.insert(self.tbHideLayerNode, UIHideLayerNode)

            for _, LayerName in pairs(UIHideLayerNode.HideLayers) do
                local LayerData = self.tbLayerData[LayerName]
                if LayerData then
                    LayerData.HideRefCount = LayerData.HideRefCount + 1
                end
            end
        end
        self:UpdateLayerVisibility()
    end
end

---@param UIHideLayerNode UIHideLayerNode
function IngameLayerManager:RemoveHideLayerNode(UIHideLayerNode)
    if UIHideLayerNode and UIHideLayerNode.HideLayers then
        TableUtil:ArrayRemoveIf(self.tbHideLayerNode, function(NodeInTable)
            if NodeInTable == UIHideLayerNode then
                for _, LayerName in pairs(UIHideLayerNode.HideLayers) do
                    local LayerData = self.tbLayerData[LayerName]
                    if LayerData then
                        LayerData.HideRefCount = LayerData.HideRefCount - 1
                        LayerData.HideRefCount = math.max(LayerData.HideRefCount, 0)
                    end
                end
                return true
            end
        end)
        self:UpdateLayerVisibility()
    end
end

---@param MyGeometry FGeometry
---@param InKeyEvent FKeyEvent
---@return FEventReply
function IngameLayerManager:OnKeyDown(MyGeometry, InKeyEvent)
    local Key = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    return self:HandlePressedKey(Key.KeyName, false)
end

---@param MyGeometry FGeometry
---@param InKeyEvent FKeyEvent
---@return FEventReply
function IngameLayerManager:OnKeyUp(MyGeometry, InKeyEvent)
    local Key = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    return self:HandleReleasedKey(Key.KeyName, false)
end

function IngameLayerManager:RegisterPressedKeyDelegate(UIObj, fnDelegate)
    local Founded = TableUtil:FindIf(self.tbPressedKeyDelegate, function(Elem)
        return Elem[1] == UIObj and Elem[2] == fnDelegate
    end)

    if not Founded then
        table.insert(self.tbPressedKeyDelegate, { UIObj, fnDelegate })
    end
end

function IngameLayerManager:UnRegisterPressedKeyDelegate(UIObj)
    TableUtil:ArrayRemoveIf(self.tbPressedKeyDelegate, function(Elem)
        return Elem[1] == UIObj
    end)
end

function IngameLayerManager:RegisterReleasedKeyDelegate(UIObj, fnDelegate)
    table.insert(self.tbReleasedKeyDelegate, { UIObj, fnDelegate })
end

function IngameLayerManager:UnRegisterReleasedKeyDelegate(UIObj)
    TableUtil:ArrayRemoveIf(self.tbReleasedKeyDelegate, function(Elem)
        return Elem[1] == UIObj
    end)
end

-- function IngameLayerManager:OnReturnAction()
--     print("IngameLayerManager:OnReturnAction")
-- end

function IngameLayerManager:HandlePressedKey(KeyName, bFromGame, ActionValue)
    G.log:debug("xaelpeng", "IngameLayerManager:HandlePressedKey %s %s %s", KeyName, bFromGame, ActionValue)
    local bHandled = false
    for i, v in ipairs(self.tbPressedKeyDelegate) do
        ---@type UWidget
        local UIObj = v[1]
        local fnDelegate = v[2]
        if UIObj:IsVisible() then
            if fnDelegate(UIObj, KeyName, bFromGame, ActionValue) then
                bHandled = true
            end
        end
    end
    return bHandled and UE.UWidgetBlueprintLibrary.Handled() or UE.UWidgetBlueprintLibrary.Unhandled()
end

function IngameLayerManager:HandleReleasedKey(KeyName, bFromGame, ActionValue)
    G.log:debug("xaelpeng", "IngameLayerManager:HandleReleasedKey %s %s %s", KeyName, bFromGame, ActionValue)
    local bHandled = false
    if KeyName == "L" then
        local topIns = UIManager:GetStackManager() 
        local top = topIns:TopInstance()
        if top then
            if top.UIInfo.PageLevel ~=  Enum.Enum_UILevel.FirstPage then 
                top:OnReturn(true)
            end
        end
    end

    for i, v in ipairs(self.tbReleasedKeyDelegate) do
        ---@type UWidget
        local UIObj = v[1]
        local fnDelegate = v[2]
        if UIObj:IsVisible() then
            if fnDelegate(UIObj, KeyName, bFromGame, ActionValue) then
                bHandled = true
            end
        end
    end
    return bHandled and UE.UWidgetBlueprintLibrary.Handled() or UE.UWidgetBlueprintLibrary.Unhandled()
end

function IngameLayerManager:DispatchPressedKeyAction(ActionName, ActionValue, ElapsedSeconds, TriggeredSeconds,
                                                     InputAction)
    self:HandlePressedKey(ActionName, true, ActionValue)
end

function IngameLayerManager:DispatchReleasedKeyAction(ActionName, ActionValue, ElapsedSeconds, TriggeredSeconds,
                                                      InputAction)
    self:HandleReleasedKey(ActionName, true, ActionValue)
end

-- Key Bindings
-- 临时绑定呼出PreviewAnimationUI
-- local BindKey = UnLua.Input.BindKey
-- local AutoBindKeys =
-- {
--     InputDef.Keys.L,
-- }

-- for _, KeyName in ipairs(AutoBindKeys) do
--     G.log:debug("xaelpeng", "BindKey %s", KeyName)
--     BindKey(IngameLayerManager, KeyName, 'Pressed', function(self, Key)
--         self:HandlePressedKey(Key.KeyName, true)
--     end)

--     BindKey(IngameLayerManager, KeyName, 'Released', function(self, Key)
--         self:HandleReleasedKey(Key.KeyName, true)
--     end)
-- end




return IngameLayerManager
