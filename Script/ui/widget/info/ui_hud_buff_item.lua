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
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local InputDef = require('CP0032305_GH.Script.common.input_define')
local UIWidgetListItemBase = require('CP0032305_GH.Script.framework.ui.ui_widget_listitem_base')

---@class WBP_HUD_Buff_Item: WBP_HUD_Buff_Item_C
local WBP_HUD_Buff_Item = Class(UIWidgetListItemBase)

---@param self WBP_HUD_Buff_Item
local function OnBtnBuffIconClicked(self)
    local BuffVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.SkillBuffVM.UniqueName)
    BuffVM:OpenBuffWnd()
end

--function WBP_HUD_Buff_Item:Initialize(Initializer)
--end

--function WBP_HUD_Buff_Item:PreConstruct(IsDesignTime)
--end

function WBP_HUD_Buff_Item:OnConstruct()
    self.WBP_Icon_Buff.OnClicked:Add(self, OnBtnBuffIconClicked)
end

--function WBP_HUD_Buff_Item:Tick(MyGeometry, InDeltaTime)
--end

---@param ListItemObject UICommonItemObj_C
function WBP_HUD_Buff_Item:OnListItemObjectSet(ListItemObject)
    local ItemValue = ListItemObject.ItemValue.FieldValue
    local BuffVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.SkillBuffVM.UniqueName)
end

return WBP_HUD_Buff_Item
