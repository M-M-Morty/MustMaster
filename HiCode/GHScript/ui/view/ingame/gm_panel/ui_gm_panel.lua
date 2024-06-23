--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')

---@type WBP_GMPanel_C
local UIGMPanel = Class(UIWindowBase)

--function UIGMPanel:Initialize(Initializer)
--end

--function UIGMPanel:PreConstruct(IsDesignTime)
--end

function UIGMPanel:OnConstruct()
    self:InitWidget()
    self:BuildWidgetProxy()
    self:InitViewModel()
end

function UIGMPanel:OnDestruct()
    self.GMPanelVM:ReleaseVMObj()
end

function UIGMPanel:InitWidget()
    self.CurrentTabFrame = nil

    self.ToggleButton.OnClicked:Add(self, self.ToggleButton_OnClicked)
    self.TabListView:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function UIGMPanel:BuildWidgetProxy()

    ---@type UWidgetSwitcherProxy
    self.ToggleSwitcherProxy = WidgetProxys:CreateWidgetProxy(self.ToggleSwitcher)
    
    ---@type UListViewProxy
    self.TabListViewProxy = WidgetProxys:CreateWidgetProxy(self.TabListView)
end

function UIGMPanel:InitViewModel()
    local VMDemoClass = require('Script.ui.viewmodel.ui_gm_panel_vm')
    self.GMPanelVM = VMDemoClass.new()

    ViewModelBinder:BindViewModel(self.ToggleSwitcherProxy.IndexField, self.GMPanelVM.ToggleSwitcherIndex, ViewModelBinder.BindWayToWidget)
    ViewModelBinder:BindViewModel(self.TabListViewProxy.ListField, self.GMPanelVM.TabListData, ViewModelBinder.BindWayToWidget)
end

function UIGMPanel:ToggleButton_OnClicked()
    local CurrentIndex = self.GMPanelVM.ToggleSwitcherIndex:GetFieldValue()
    if CurrentIndex == 0 then
        self.GMPanelVM.ToggleSwitcherIndex:SetFieldValue(1)
        self.TabListView:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

        if self.CurrentTabFrame and self.CurrentTabFrame:IsValid() then
            self.CurrentTabFrame:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        end
    else
        self.GMPanelVM.ToggleSwitcherIndex:SetFieldValue(0)
        self.TabListView:SetVisibility(UE.ESlateVisibility.Collapsed)

        if self.CurrentTabFrame and self.CurrentTabFrame:IsValid() then
            self.CurrentTabFrame:SetVisibility(UE.ESlateVisibility.Hidden)
        end
    end
end

function UIGMPanel:FillTabFrame(WidgetPath)

    if self.CurrentTabFrame and self.CurrentTabFrame:IsValid() then
        self.CurrentTabFrame:RemoveFromParent()
    end
    self.CurrentTabFrame = nil

    local NewWidget = UIManager:CreateWidgetInternal(WidgetPath)
    if NewWidget then
        self.CurrentTabFrame = NewWidget
        local CanvasSlot = self.TabFrame:AddChildToCanvas(NewWidget)

        local Anchors = UE.FAnchors()
        Anchors.Minimum = UE.FVector2D(0, 0)
        Anchors.Maximum = UE.FVector2D(1, 1)
        CanvasSlot:SetAnchors(Anchors)

        CanvasSlot:SetOffsets(UE.FMargin())
    end

    return self.CurrentTabFrame
end

--function UIGMPanel:Tick(MyGeometry, InDeltaTime)
--end

return UIGMPanel
