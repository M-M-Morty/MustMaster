--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local TipsUtil = require("CP0032305_GH.Script.common.utils.tips_util")
local MissionActUtil = require("CP0032305_GH.Script.mission.mission_act_utils")
local TaskActType = MissionActUtil.TaskActType

---@class WBP_Task_PhotoOnWall : WBP_Task_PhotoOnWall_C
---@field bIsCaseCardOnWall boolean
---@field OwnerWidget WBP_Task_CaseWall
---@field ID integer
---@field State EMissionActState

---@type WBP_Task_PhotoOnWall
local WBP_Task_PhotoOnWall = UnLua.Class()

local MAINSTORY_CASEBOARD_NOTFINISH = "MAINSTORY_CASEBOARD_NOTFINISH"

function WBP_Task_PhotoOnWall:OnButtonDown()
    if self.WBP_Task_Photo.bNotComplete then
        return
    end
    self.WBP_Task_Photo:PlayAnimation(self.WBP_Task_Photo.DX_PressDown, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end

function WBP_Task_PhotoOnWall:OnButtonUp(bClick)
    if self.WBP_Task_Photo.bNotComplete then
        if bClick then
            TipsUtil.ShowCommonTips(MAINSTORY_CASEBOARD_NOTFINISH)
        end
        return
    end
    self.WBP_Task_Photo:PlayAnimation(self.WBP_Task_Photo.DX_PressUp, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)

    if bClick then
        local CallBack = function()
            self:ClickPhoto()
        end
        UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, CallBack}, self.WBP_Task_Photo.DX_PressUp:GetEndTime(), false)
    end
end

function WBP_Task_PhotoOnWall:ClickPhoto()
    ---@type EMissionActState
    local EMissionActState = Enum.EMissionActState
    local MissionActConfig = MissionActUtil.GetMissionActConfig(self.ID)
    if self.State == EMissionActState.RewardReceived or (MissionActConfig.Type == TaskActType.Side and self.State == EMissionActState.Complete) then
        ---@type WBP_Task_PlotReview
        local Widget = UIManager:OpenUI(UIDef.UIInfo.UI_Task_PlotReview)
        Widget:ShowSummary(self.ID)
    end
end

function WBP_Task_PhotoOnWall:Construct()
    self.bIsCaseCardOnWall = true
end

---@return FVector2D
function WBP_Task_PhotoOnWall:GetThumbtackSlotCenterPos()
    ---@type WBP_Task_Photo
    local WBP_Task_Photo = self.WBP_Task_Photo
    return WBP_Task_Photo:GetThumbtackSlotCenterPos()
end

---@param OwnerWidget WBP_Task_CaseWall
---@param ID integer
---@param State EMissionActState
function WBP_Task_PhotoOnWall:SetData(OwnerWidget, ID, State)
    self.OwnerWidget = OwnerWidget
    self.ID = ID
    self.State = State
end

return WBP_Task_PhotoOnWall
