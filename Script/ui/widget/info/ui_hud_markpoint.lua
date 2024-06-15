--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require('G')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local mission_widget_test = require('CP0032305_GH.Script.system_simulator.mission_system.mission_widget_test')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local InputDef = require('CP0032305_GH.Script.common.input_define')
local UIWidgetBase = require('CP0032305_GH.Script.framework.ui.ui_widget_base')

local TIMER_INTERVAL = 1

---@type WBP_HUD_MarkPoints_C
local M = Class(UIWidgetBase)

local function InitUI(self)
    G.log:debug("zys", "throw mark init")
    local vm = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.ThrowSkillVM.UniqueName)
    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.TimerHandle)

    self.OnCanShowChangedField = self:CreateUserWidgetField(self.OnCanShowChanged)
    ViewModelBinder:BindViewModel(self.OnCanShowChangedField, vm.CanThrowPointShowField, ViewModelBinder.BindWayToWidget)
    self.inited = true
end

--function M:Initialize(Initializer)
--end

--function M:PreConstruct(IsDesignTime)
--end

function M:OnConstruct()
    self.Img_MarkPoints:SetVisibility(UE.ESlateVisibility.Hidden)
    self.CacheInfo = {
        bShow = false, -- 当前的显示状态
        bCanShow = false, -- 可显示(需瓦利抛投技能可用)
    }

    ---@type FTimerHandle
    self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.TimerLoop}, TIMER_INTERVAL, false)
end

function M:TimerLoop()
    local vm = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.ThrowSkillVM.UniqueName)
    if vm and not self.inited then
        InitUI(self)
    end
end

-- function M:Tick(MyGeometry, InDeltaTime)
-- end

---`brief`仅显示, 显示互动点和播放动效
function M:SetPointVisible(bShow)
    self:StopAnimationsAndLatentActions()
    if self.CacheInfo.bCanShow then
        if bShow == true then
            self.Img_MarkPoints:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
        else
            local PlayAnimProxy = UE.UWidgetAnimationPlayCallbackProxy.CreatePlayAnimationProxyObject(UE.NewObject(UE.UUMGSequencePlayer), self, self.DX_Out, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
            PlayAnimProxy.Finished:Add(self, function()
                self.Img_MarkPoints:SetVisibility(UE.ESlateVisibility.Hidden)
            end)
        end
        -- -- 动效需求记录上一次状态，故此处二次开发新增Cache
        -- if (bShow == true) and (self.CacheInfo.bShow == true) then
        -- elseif (bShow == true) and (self.CacheInfo.bShow == false) then
        --     self.Img_MarkPoints:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        --     self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
        -- elseif (bShow == false) and (self.CacheInfo.bShow == true) then
        --     local PlayAnimProxy = UE.UWidgetAnimationPlayCallbackProxy.CreatePlayAnimationProxyObject(UE.NewObject(UE.UUMGSequencePlayer), self, self.DX_Out, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
        --     PlayAnimProxy.Finished:Add(self, function()
        --         self.Img_MarkPoints:SetVisibility(UE.ESlateVisibility.Hidden)
        --     end)
        -- elseif (bShow == false) and (self.CacheInfo.bShow == false) then
        -- end
    else
        self.Img_MarkPoints:SetVisibility(UE.ESlateVisibility.Hidden)
    end
    -- 不可以显示的时候也要接收消息, 以便在可显示的时候恢复状态
    self.CacheInfo.bShow = bShow
end

function M:OnCanShowChanged(Data)
    if not Data then
        self:SetPointVisible(false)
    end
    self.CacheInfo.bCanShow = Data
    -- 当允许显示时将此怪互动点的显示置为上次的状态(CD中标记通知, 则CD后需要恢复)
    if Data then
        self:SetPointVisible(self.CacheInfo.bShow)
    end
end

return M
