--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

-- 自定义的ListViewItem的基类

local UIWidgetBase = require('CP0032305_GH.Script.framework.ui.ui_widget_base')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')

---@class UIWidgetListItemBase : UIWidgetBase
local UIWidgetListItemBase = Class(UIWidgetBase)

--function UIWidgetListItemBase:Initialize(Initializer)
--end

--function UIWidgetListItemBase:PreConstruct(IsDesignTime)
--end

-- call by UIWidgetBase:Construct
-- function UIWidgetListItemBase:OnConstruct()
-- end

-- call by UIWidgetBase:Destruct
-- function UIWidgetListItemBase:OnDestruct()
-- end

function UIWidgetListItemBase:OnEntryReleased()
end

function UIWidgetListItemBase:BP_OnEntryReleased()
    self:OnEntryReleased()
    self:StopAnimationsAndLatentActions()
    ViewModelBinder:UnBindByUI(self, true)
    self.Overridden.BP_OnEntryReleased(self)
end

--function UIWidgetListItemBase:Tick(MyGeometry, InDeltaTime)
--end

function UIWidgetListItemBase:OnListItemObjectSet(ListItemObject)
end

--function UIWidgetListItemBase:Tick(MyGeometry, InDeltaTime)
--end

return UIWidgetListItemBase
