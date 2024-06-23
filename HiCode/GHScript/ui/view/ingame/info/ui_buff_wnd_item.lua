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

local TIMER_INTERVAL = 0.1             -- timer的时间间隔

---@class WBP_Buff_Wnd_Item: WBP_HUD_BuffTips_Item_C
local WBP_Buff_Wnd_Item = Class(UIWidgetListItemBase)

---@param self WBP_Buff_Wnd_Item
local function ResetUI(self)
    self.ItemBuffInfo = {}
end

---@param self WBP_Buff_Wnd_Item
---@param bValid boolean
local function SetItemValid(self, bValid)
    self.Txt_BuffName:SetRenderOpacity(bValid and 1 or 0.6)
    self.Txt_DebuffName:SetRenderOpacity(bValid and 1 or 0.6)
    self.Txt_BuffIllustrate:SetRenderOpacity(bValid and 1 or 0.6)
    self.Txt_BuffState:SetRenderOpacity(bValid and 1 or 0.6)
    self.Icon_Buff:SetRenderOpacity(bValid and 1 or 0.6)

    self.Img_BuffTipsBG:SetRenderOpacity(bValid and 1 or 0.5)
    self.Img_DebuffTipsBG:SetRenderOpacity(bValid and 1 or 0.5)
end

---@param self WBP_Buff_Wnd_Item
---@param bBuff boolean
local function SetBuffDebuff(self, bBuff)
    self.Switch_BuffState:SetActiveWidgetIndex(bBuff and (0) or 1)
end

---@param self WBP_Buff_Wnd_Item
---@param Name string
local function SetBuffName(self, Name)
    self.Txt_BuffName:SetText(Name)
    self.Txt_DebuffName:SetText(Name)
end

--function WBP_Buff_Wnd_Item:Initialize(Initializer)
--end

--function WBP_Buff_Wnd_Item:PreConstruct(IsDesignTime)
--end

function WBP_Buff_Wnd_Item:OnConstruct()
    ResetUI(self)
    ---@type FTimerHandle
    self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.TimerLoop}, TIMER_INTERVAL, true)
end

--function WBP_Buff_Wnd_Item:Tick(MyGeometry, InDeltaTime)
--end

function WBP_Buff_Wnd_Item:OnDestruct()
    ResetUI(self)
    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.TimerHandle)
end

---@param ListItemObject UICommonItemObj_C
function WBP_Buff_Wnd_Item:OnListItemObjectSet(ListItemObject)
    local ItemValue = ListItemObject.ItemValue:GetFieldValue()
    self.ItemValue = ItemValue
    SetBuffName(self, ItemValue.Name)
    self.Txt_BuffIllustrate:SetText(ItemValue.Desc)
    ResetUI(self)
    SetBuffDebuff(self, true)
    SetItemValid(self,true)
    local SuperSkillTag = UE.UHiGASLibrary.RequestGameplayTag(ItemValue.TagName)
    local Player = UE.UGameplayStatics.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
    if UE.UKismetSystemLibrary.IsValid(Player) and Player.BuffComponent and Player.BuffComponent:HasBuff(SuperSkillTag) then
        self.ItemBuffInfo.Remaining = Player.BuffComponent:GetBuffRemainingAndDuration(SuperSkillTag)
    else
        G.log:debug("zys", "failed to init buff remaining and duration !!!")
        self.ItemBuffInfo.Remaining = 5
    end
    self.Txt_BuffState:SetText(tonumber(string.format('%.1f', self.ItemBuffInfo.Remaining)) .. '秒')
end

function WBP_Buff_Wnd_Item:TimerLoop()
    if self.ItemBuffInfo and self.ItemBuffInfo.Remaining then
        local SuperSkillTag = UE.UHiGASLibrary.RequestGameplayTag(self.ItemValue.TagName)
        local Player = UE.UGameplayStatics.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
        if UE.UKismetSystemLibrary.IsValid(Player) and Player.BuffComponent and Player.BuffComponent:HasBuff(SuperSkillTag) then
            self.ItemBuffInfo.Remaining = Player.BuffComponent:GetBuffRemainingAndDuration(SuperSkillTag)
        end
        self.Txt_BuffState:SetText(tonumber(string.format('%.1f', self.ItemBuffInfo.Remaining)) .. '秒')
        if self.ItemBuffInfo.Remaining <= 0.05 then
            self.Txt_BuffState:SetText('已失效')
            SetItemValid(self, false)
        end
    end
end

return WBP_Buff_Wnd_Item
