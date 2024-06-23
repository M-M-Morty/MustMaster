--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local UIWidgetListItemBase = require('CP0032305_GH.Script.framework.ui.ui_widget_listitem_base')

---@type WBP_GMPanel_TabItem_C
local GMPanelTabItem = Class(UIWidgetListItemBase)

--function GMPanelTabItem:Initialize(Initializer)
--end

--function GMPanelTabItem:PreConstruct(IsDesignTime)
--end

function GMPanelTabItem:OnConstruct()
    self.TabButton.OnClicked:Add(self, self.TabButton_OnClicked)

    ---@type UTextBlockProxy
    self.TabTextProxy = WidgetProxys:CreateWidgetProxy(self.TabText)
end

---@param ListItemObject UICommonItemObj_C
function GMPanelTabItem:OnListItemObjectSet(ListItemObject)
    ---@type ViewModelInterface
    local InItemValue = ListItemObject.ItemValue
    if InItemValue:IsViewModel() then
        self.ItemVM = InItemValue
        self.fnClickTabButton = self.ItemVM.fnClickTabButton
        ViewModelBinder:BindViewModel(self.TabTextProxy.TextField, self.ItemVM.ItemText, ViewModelBinder.BindWayToWidget)
    elseif InItemValue:IsViewModelField() then
        self.ItemVMField = InItemValue
        self.ItemVMFieldValue = InItemValue:GetFieldValue()
        self.fnClickTabButton = self.ItemVMFieldValue.fnClickTabButton
        self.TabText:SetText(self.ItemVMFieldValue.ItemText)
    end
end

function GMPanelTabItem:TabButton_OnClicked()
    if self.fnClickTabButton then
        self.fnClickTabButton()
    end
end

--function GMPanelTabItem:Tick(MyGeometry, InDeltaTime)
--end

return GMPanelTabItem
