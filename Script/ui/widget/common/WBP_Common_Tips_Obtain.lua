--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR CuiZhiyuan
-- @DATE ${date} ${time}
--
local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local InputDef = require('CP0032305_GH.Script.common.input_define')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UICommonUtil = require('CP0032305_GH.Script.framework.ui.ui_common_utl')
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
---@type WBP_Common_Tips_Obtain_C
local WBP_Common_Tips_Obtain = Class(ViewModelBaseClass)

--function WBP_Common_Tips_Obtain:Initialize(Initializer)
--end

--function WBP_Common_Tips_Obtain:PreConstruct(IsDesignTime)
--end

 function WBP_Common_Tips_Obtain:OnConstruct()
 end

 function WBP_Common_Tips_Obtain:SetText(ObjectInfo)
    self.Text_CallingCard:SetText(ObjectInfo)
 end

--function WBP_Common_Tips_Obtain:Tick(MyGeometry, InDeltaTime)
--end

return WBP_Common_Tips_Obtain
