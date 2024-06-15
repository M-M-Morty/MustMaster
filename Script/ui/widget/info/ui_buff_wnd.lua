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

local TIMER_DURATION = 4

---@class WBP_Buff_Wnd: WBP_HUD_BuffTips_C
---@field BuffVM SkillBuffVM
local WBP_Buff_Wnd = Class(UIWindowBase)

---@param self WBP_Buff_Wnd
local function OnBtnBgClicked(self)
    local BuffVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.SkillBuffVM.UniqueName)
    BuffVM:CloseBuffWnd()
end

---@param self WBP_Buff_Wnd
local function InitWidget(self)
    self.Btn_ClickToExit.OnClicked:Add(self, OnBtnBgClicked)
end

---@param self WBP_Buff_Wnd
local function BuildWidgetProxy(self)
    ---@type UListViewProxy
    self.BuffListProxy = WidgetProxys:CreateWidgetProxy(self.List_Buff)
end

---@param self WBP_Buff_Wnd
local function InitViewModel(self)
    if not self.BuffVM then
        ---@type SkillBuffVM
        self.BuffVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.SkillBuffVM.UniqueName)
    end
    -- if self.BuffVM then
    --     ViewModelBinder:BindViewModel(self.OnBuffChangedField, self.BuffVM.ArrBuffField, ViewModelBinder.BindWayToWidget)
    -- end
end

function WBP_Buff_Wnd:Initialize(Initializer)
end

function WBP_Buff_Wnd:PreConstruct(IsDesignTime)
end

function WBP_Buff_Wnd:OnConstruct()
    InitWidget(self)
    BuildWidgetProxy(self)
    InitViewModel(self)
end

--function WBP_Buff_Wnd:Tick(MyGeometry, InDeltaTime)
--end

function WBP_Buff_Wnd:OnShow()
    -- for i = 1, self.BuffVM.ArrBuffField:GetItemNum() do
    --     self.BuffListProxy:AddItem(self.BuffVM.ArrBuffField:)
    -- end
    self.BuffListProxy:SetListItems(self.BuffVM.ArrBuffField:GetFieldValue())
    self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    if not self.TimerHandle then
        ---@type FTimerHandle
        self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.DelayClose}, TIMER_DURATION, false)
    end
end

function WBP_Buff_Wnd:DelayClose()
    G.log:debug("zys", "buff wnd auto close")
    local BuffVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.SkillBuffVM.UniqueName)
    BuffVM:CloseBuffWnd()
end

function WBP_Buff_Wnd:OnHide()
    if self.TimerHandle then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.TimerHandle)
        self.TimerHandle = nil
    end
end

return WBP_Buff_Wnd
