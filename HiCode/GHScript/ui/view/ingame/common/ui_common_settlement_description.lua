--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UICommonUtil = require('CP0032305_GH.Script.framework.ui.ui_common_utl')
local InputDef = require('CP0032305_GH.Script.common.input_define')
local UIWidgetBase = require('CP0032305_GH.Script.framework.ui.ui_widget_base')

---@class WBP_Common_MiniGames_SettlementPopUp_Description_C
local UICommonSettlementDescription = Class(UIWidgetBase)

--function UICommonSettlementDescription:Initialize(Initializer)
--end

--function UICommonSettlementDescription:PreConstruct(IsDesignTime)
--end

-- function UICommonSettlementDescription:Construct()
-- end

--function UICommonSettlementDescription:Tick(MyGeometry, InDeltaTime)
--end

function UICommonSettlementDescription:OnConstruct()
    self:BuildWidgetProxy()
end

function UICommonSettlementDescription:BuildWidgetProxy()
    ---@type UTileViewProxy
    self.List_DescriptionProxy = WidgetProxys:CreateWidgetProxy(self.List_Description)
end

function UICommonSettlementDescription:SetListData(listValues)
    self.List_DescriptionProxy:SetListItems(listValues)
end

return UICommonSettlementDescription
