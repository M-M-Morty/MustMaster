--
-- @COMPANY GHGame
-- @AUTHOR xuminjie
--

local G = require('G')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local UIWidgetListItemBase = require('CP0032305_GH.Script.framework.ui.ui_widget_listitem_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')


---@type WBP_Guide_SelectionItem_C
local WBP_Guide_SelectionItem = Class(UIWidgetListItemBase)

--function WBP_Guide_SelectionItem:Initialize(Initializer)
--end

--function WBP_Guide_SelectionItem:PreConstruct(IsDesignTime)
--end

-- function WBP_Guide_SelectionItem:OnConstruct()
-- end

function WBP_Guide_SelectionItem:OnListItemObjectSet(data)
    self.Image_Circle_Selected:SetVisibility(data.ItemValue == true and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

--function WBP_Guide_SelectionItem:Tick(MyGeometry, InDeltaTime)
--end

return WBP_Guide_SelectionItem
