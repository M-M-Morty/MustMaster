--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local M = Component(ComponentBase)


function M:InitItem(VM)
    self.ChannelId = VM.ChannelId

    self.MissionState = VM.WS_MissionState.FieldValue                 --任务的状态
    self:SetUITextActor(self.missionTitle, VM.Text_MissionInfo:GetFieldValue())
    self:SetUITextActor(self.missionInfo, VM.Text_MissionTitle:GetFieldValue())
    self:SetUITextActor(self.missionBtnText, VM.Text_MissionStateInfo:GetFieldValue())


    self:SetActorActive(self.missionAcceptItem, false)
    self:SetActorActive(self.missionStopItem, false)

    self:SetActorActive(self.missionItem, true)

    -- if self.WS_MissionState == 0 then
    --     self.MissionItem:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    --     self:SetUITextActor(self.missionInfo, VM.Text_MissionTitle:GetFieldValue())
    --     self:SetUITextActor(self.missionTitle, VM.Text_MissionInfo:GetFieldValue())
    -- elseif self.WS_MissionState == 2 then
    --     self.TimeItem:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

    --     self:SetUITextActor(self.NameText, VM.WS_MissionState:GetFieldValue())
    --     self:SetUITextActor(self.NameText, VM.Text_MissionStateInfo:GetFieldValue())
    --     self:SetUITextActor(self.NameText, VM.Text_MissionInfo:GetFieldValue())
    -- else
    --     self.TimeItem:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

    --     self:SetUITextActor(self.NameText, VM.WS_MissionState:GetFieldValue())
    --     self:SetUITextActor(self.NameText, VM.Text_MissionStateInfo:GetFieldValue())
    --     self:SetUITextActor(self.NameText, VM.Text_MissionInfo:GetFieldValue())
    -- end
end

return M
