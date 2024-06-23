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

---@class WBP_Task_CaseList : WBP_Task_CaseList_C
---@field OwnerWidget WBP_Task_FirmHomePage
---@field MissionActID integer
---@field State integer
---@field MissionActConfig MissionActConfig

---@type WBP_Task_CaseList
local WBP_Task_CaseList = UnLua.Class()

---@param self WBP_Task_CaseList
local function RefreshState(self)
    ---@type EMissionActState
    local EMissionActState = Enum.EMissionActState
    if self.State == EMissionActState.Initialize then
        self.Switch_StateTip:SetVisibility(UE.ESlateVisibility.Collapsed)
    elseif self.State == EMissionActState.Start then
        self.Switch_StateTip:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Switch_StateTip:SetActiveWidgetIndex(0)
    elseif self.State == EMissionActState.Complete then
        self.Switch_StateTip:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Switch_StateTip:SetActiveWidgetIndex(1)
        self.WBP_Common_RedDot:ShowGift()
    end
end

---@param OwnerWidget WBP_Task_FirmHomePage
function WBP_Task_CaseList:SetOwnerWidget(OwnerWidget)
    self.OwnerWidget = OwnerWidget
end

---@param MissionActID integer
function WBP_Task_CaseList:SetTaskActID(MissionActID)
    if MissionActID == nil then
        G.log:info("WBP_Task_CaseList", "SetTaskActID MissionActID nil")
        self:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    ---@type TaskActVM
    local TaskActVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskActVM.UniqueName)
    local MissionActData = TaskActVM:GetMissionAct(MissionActID)
    if MissionActData == nil then
        G.log:error("WBP_Task_CaseList", "SetTaskActID MissionActID cannot find MissionActData! %d", MissionActID)
        self:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    self.MissionActID = MissionActID
    self.State = MissionActData.State

    self.MissionActConfig = MissionActUtils.GetMissionActConfig(MissionActID)
    if self.MissionActConfig == nil then
        G.log:error("WBP_Task_CaseList", "SetTaskActID MissionActID cannot find MissionActConfig! %d", MissionActID)
        self:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end

    local NpcConfig = MissionActUtils.GetNpcConfig(self.MissionActConfig.ActNpc)
    if NpcConfig then
        PicConst.SetImageBrush(self.Img_Photo, NpcConfig.icon_ref)
    else
        G.log:warn("WBP_Task_CaseList", "NpcConfig nil! MissionActID:%d, NpcID:%d", MissionActID, self.MissionActConfig.ActNpc)
    end

    RefreshState(self)

    self.Txt_PhotoThumbnailName:SetText(self.MissionActConfig.Name)
end

return WBP_Task_CaseList
