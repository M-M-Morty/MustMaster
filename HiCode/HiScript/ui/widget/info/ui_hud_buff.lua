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

---@class WBP_HUD_Buff: WBP_HUD_Buff_C
---@field BuffVM SkillBuffVM
---@field 
local WBP_HUD_Buff = Class(UIWindowBase)

---@param self WBP_HUD_Buff
local function InitWidget(self)
end

---@param self WBP_HUD_Buff
local function BuildWidgetProxy(self)
    ---@type UListViewProxy
    self.BuffListProxy = WidgetProxys:CreateWidgetProxy(self.List_Buff)
    -- ---@type UIWidgetField
    -- self.OnBuffChangedField = self:CreateUserWidgetField(self.OnBuffChanged)
end

---@param self WBP_HUD_Buff
local function InitViewModel(self)
    if not self.BuffVM then
        ---@type SkillBuffVM
        self.BuffVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.SkillBuffVM.UniqueName)
    end
    if self.BuffVM then
        ViewModelBinder:BindViewModel(self.BuffListProxy.ListField, self.BuffVM.ArrBuffField, ViewModelBinder.BindWayToWidget)
    end
end

--function WBP_HUD_Buff:Initialize(Initializer)
--end

--function WBP_HUD_Buff:PreConstruct(IsDesignTime)
--end

function WBP_HUD_Buff:OnConstruct()
    self.BuffVM = nil
    InitWidget(self)
    BuildWidgetProxy(self)
    InitViewModel(self)
end

--function WBP_HUD_Buff:Tick(MyGeometry, InDeltaTime)
--end

function WBP_HUD_Buff:OnShow()
end

function WBP_HUD_Buff:OnHide()
end

return WBP_HUD_Buff
