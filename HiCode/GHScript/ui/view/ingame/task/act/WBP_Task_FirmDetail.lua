--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local MissionActUtils = require("CP0032305_GH.Script.mission.mission_act_utils")
local PicConst = require("CP0032305_GH.Script.common.pic_const")
local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")
local TipsUtil = require("CP0032305_GH.Script.common.utils.tips_util")

---@class WBP_Task_FirmDetail : WBP_Task_FirmDetail_C
---@field MissionActID integer
---@field State EMissionActState
---@field MissionActConfig MissionActConfig

---@type WBP_Task_FirmDetail
local WBP_Task_FirmDetail = UnLua.Class()

local MAT_PARAM_NO_HIDE = 0
local MAT_PARAM_HIDE = 1.6
local CURRENCY_NOT_ENOUGH_KEY = "Toast_Currency_Not_Enough"

---@param self WBP_Task_FirmDetail
local function ShowUpShadow(self)
    local EffectMaterial = self.Reta_DescriptionHidden:GetEffectMaterial()
    EffectMaterial:SetScalarParameterValue("Power1", MAT_PARAM_NO_HIDE)
    EffectMaterial:SetScalarParameterValue("Power2", MAT_PARAM_HIDE)
end

---@param self WBP_Task_FirmDetail
local function ShowDownShadow(self)
    local EffectMaterial = self.Reta_DescriptionHidden:GetEffectMaterial()
    EffectMaterial:SetScalarParameterValue("Power1", MAT_PARAM_HIDE)
    EffectMaterial:SetScalarParameterValue("Power2", MAT_PARAM_NO_HIDE)
end

---@param self WBP_Task_FirmDetail
local function ShowBothShadow(self)
    local EffectMaterial = self.Reta_DescriptionHidden:GetEffectMaterial()
    EffectMaterial:SetScalarParameterValue("Power1", MAT_PARAM_HIDE)
    EffectMaterial:SetScalarParameterValue("Power2", MAT_PARAM_HIDE)
end

---@param self WBP_Task_FirmDetail
local function CurrencyEnough(self)
    local ItemManager = ItemUtil.GetItemManager(self)
    if #self.MissionActConfig.OpenCost == 2 then
        local CostExcelID = self.MissionActConfig.OpenCost[1]
        local Count = ItemManager:GetItemCountByExcelID(CostExcelID)
        local Cost = self.MissionActConfig.OpenCost[2]
        return Count >= Cost
    end
    return true
end

---@param self WBP_Task_FirmDetail
local function OnClickConfirm(self)
    ---@type EMissionActState
    local EMissionActState = Enum.EMissionActState
    if self.State == EMissionActState.Initialize then
        if CurrencyEnough(self) then
            ---@type TaskActVM
            local TaskActVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskActVM.UniqueName)
            TaskActVM.MissionSystemModule:Server_AcceptMissionAct(self.MissionActID)
            G.log:info("WBP_Task_FirmDetail", "Request AcceptMissionAct %d", self.MissionActID)
            self:PlayAnimation(self.DX_Receive, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
        else
            TipsUtil.ShowCommonTips(CURRENCY_NOT_ENOUGH_KEY)
        end
    elseif self.State == EMissionActState.Complete then
        ---@type TaskActVM
        local TaskActVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskActVM.UniqueName)
        TaskActVM.MissionSystemModule:Server_ReceiveMissionActRewards(self.MissionActID)
        G.log:info("WBP_Task_FirmDetail", "Request ReceiveMissionActRewards %d", self.MissionActID)
    end
end

---@param self WBP_Task_FirmDetail
---@param Offset float
local function OnUserScrolled(self, Offset)
    if Offset == 0.0 then
        ShowDownShadow(self)
    elseif math.abs(Offset - self.ScrollBox_Description:GetScrollOffsetOfEnd()) < 1 then
        ShowUpShadow(self)
    else
        ShowBothShadow(self)
    end
end

function WBP_Task_FirmDetail:Construct()
    self.ScrollBox_Description.OnUserScrolled:Add(self, OnUserScrolled)
    self.WBP_Btn_Receiving.OnClicked:Add(self, OnClickConfirm)
end

function WBP_Task_FirmDetail:Destruct()
    self.ScrollBox_Description.OnUserScrolled:Remove(self, OnUserScrolled)
    self.WBP_Btn_Receiving.OnClicked:Remove(self, OnClickConfirm)
end

---@param self WBP_Task_FirmDetail
local function RefreshMissionActDetail(self)
    ---@type WBP_Task_Photo
    local WBP_Task_Photo = self.WBP_Task_Photo
    local MissionActConfig = self.MissionActConfig
    WBP_Task_Photo:SetOnlyPhoto(MissionActConfig.ActPic)

    self.Txt_Title:SetText(MissionActConfig.Name)
    self.Txt_Description:SetText(MissionActConfig.Descript)

    local Callback = function()
        OnUserScrolled(self, self.ScrollBox_Description:GetScrollOffset())
        if self.ScrollBox_Description:GetScrollOffsetOfEnd() == 0 then
            self.ScrollBox_Description:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        else
            self.ScrollBox_Description:SetVisibility(UE.ESlateVisibility.Visible)
        end
    end
    UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, Callback }, 0.2, false)
end

---@param self WBP_Task_FirmDetail
local function RefreshNpcDetail(self)
    local NpcConfig = MissionActUtils.GetNpcConfig(self.MissionActConfig.ActNpc)
    if NpcConfig then
        self.Txt_NpcName:SetText(NpcConfig.name)
        PicConst.SetImageBrush(self.Img_Photo, NpcConfig.icon_ref)
    else
        G.log:warn("WBP_Task_FirmDetail", "RefreshNpcDetail npc config nil! ID: %d", self.MissionActConfig.ActNpc)
    end
end

---@param self WBP_Task_FirmDetail
local function RefreshMissionState(self)
    ---@type EMissionActState
    local EMissionActState = Enum.EMissionActState
    if self.State == EMissionActState.Complete or self.State == EMissionActState.RewardReceived then
        self.Canvas_Completed:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.Canvas_Completed:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

---@param self WBP_Task_FirmDetail
local function RefreshCommitButton(self)
    ---@type EMissionActState
    local EMissionActState = Enum.EMissionActState
    if self.State == EMissionActState.Initialize then
        self.Switch_ReceivingState:SetActiveWidgetIndex(0)
        self.WBP_Btn_Receiving:SetIsEnabled(true)
        local Cost = 0
        if #self.MissionActConfig.OpenCost == 2 then
            Cost = self.MissionActConfig.OpenCost[2]
            local CostExcelID = self.MissionActConfig.OpenCost[1]
            local ItemConfig = ItemUtil.GetItemConfigByExcelID(CostExcelID)
            self.ImgCostItem:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            PicConst.SetImageBrush(self.ImgCostItem, ItemConfig.mini_icon_reference)
            if CurrencyEnough(self) then
                self.WidgetSwitcherCostNum:SetActiveWidgetIndex(0)
            else
                self.WidgetSwitcherCostNum:SetActiveWidgetIndex(1)
            end
        else
            self.ImgCostItem:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
        self.TxtCostNum1:SetText(Cost)
        self.TxtCostNum2:SetText(Cost)
    elseif self.State == EMissionActState.Start then
        self.Switch_ReceivingState:SetActiveWidgetIndex(1)
        self.WBP_Btn_Receiving:SetIsEnabled(false)
    elseif self.State == EMissionActState.Complete then
        self.Switch_ReceivingState:SetActiveWidgetIndex(2)
        self.WBP_Btn_Receiving:SetIsEnabled(true)
    end
end

---@param MissionActID integer
function WBP_Task_FirmDetail:SetTaskActID(MissionActID)
    if MissionActID == nil then
        G.log:error("WBP_Task_FirmDetail", "SetTaskActID MissionActID nil")
        self:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    ---@type TaskActVM
    local TaskActVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskActVM.UniqueName)
    local MissionActData = TaskActVM:GetMissionAct(MissionActID)
    if MissionActData == nil then
        G.log:error("WBP_Task_FirmDetail", "SetTaskActID MissionActID cannot find MissionActData! %d", MissionActID)
        self:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    self.MissionActID = MissionActID
    self.State = MissionActData.State

    self.MissionActConfig = MissionActUtils.GetMissionActConfig(MissionActID)
    if self.MissionActConfig == nil then
        G.log:error("WBP_Task_FirmDetail", "SetTaskActID MissionActID cannot find MissionActConfig! %d", MissionActID)
        self:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end

    RefreshMissionActDetail(self)
    RefreshNpcDetail(self)
    RefreshMissionState(self)
    RefreshCommitButton(self)
end

return WBP_Task_FirmDetail
