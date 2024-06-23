--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
---@class WBP_Task_PlotReview_DialogueContent : WBP_Task_PlotReview_DialogueContent_C
---@field NodeSessionData TaskNodeSessionData

local MissionActUtils = require("CP0032305_GH.Script.mission.mission_act_utils")

---@type WBP_Task_PlotReview_DialogueContent
local WBP_Task_PlotReview_DialogueContent = UnLua.Class()

local SELECT_TXT_OPACITY = 1
local UNSELECT_TXT_OPACITY = 0.6

---@param self WBP_Task_PlotReview_DialogueContent
---@return WBP_Task_PlotReview
local function GetOwnerWidget(self)
    return self.NodeSessionData.OwnerWidget.NodeData.OwnerWidget.ListItemObject.OwnerWidget
end

---@param self WBP_Task_PlotReview_DialogueContent
---@param bSelected boolean
local function SetSelected(self, bSelected)
    if bSelected then
        self.Img_DialogueContent_Selected:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Txt_DialogueContent:SetRenderOpacity(SELECT_TXT_OPACITY)
    else
        self.Img_DialogueContent_Selected:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Txt_DialogueContent:SetRenderOpacity(UNSELECT_TXT_OPACITY)
    end
end

---@param SelectedID integer
function WBP_Task_PlotReview_DialogueContent:OnSelectedChanged(SelectedID)
    if SelectedID == self.NodeSessionData.ID then
        SetSelected(self, true)
    else
        SetSelected(self, false)
    end
end

---@param bPlaying boolean
function WBP_Task_PlotReview_DialogueContent:AudioStateChanged(bPlaying)
    self.Switch_PlayIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if bPlaying then
        self.Switch_PlayIcon:SetActiveWidgetIndex(1)
        self:PlayAnimation(self.DX_PlayingLoop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1, false)
    else
        self.Switch_PlayIcon:SetActiveWidgetIndex(0)
        self:StopAnimation(self.DX_PlayingLoop)
    end
end

---Called when this entry is assigned a new item object to represent by the owning list view
---@param NodeSessionData TaskNodeSessionData
---@return void
function WBP_Task_PlotReview_DialogueContent:SetData(NodeSessionData)
    self.NodeSessionData = NodeSessionData
    self.Txt_DialogueContent:SetText(NodeSessionData.Content)
    if NodeSessionData.Type == MissionActUtils.TaskReviewDisplayType.Normal then
        self.Switch_DialogueState:SetVisibility(UE.ESlateVisibility.Collapsed)
    elseif NodeSessionData.Type == MissionActUtils.TaskReviewDisplayType.Chosen then
        self.Switch_DialogueState:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        if NodeSessionData.OwnerWidget.bExpand then
            self.Switch_DialogueState:SetActiveWidgetIndex(0)
        else
            self.Switch_DialogueState:SetActiveWidgetIndex(1)
        end
    elseif NodeSessionData.Type == MissionActUtils.TaskReviewDisplayType.Option then
        if NodeSessionData.bChosen then
            self.Switch_DialogueState:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.Switch_DialogueState:SetActiveWidgetIndex(2)
        else
            self.Switch_DialogueState:SetVisibility(UE.ESlateVisibility.Hidden)
        end
    end
    if GetOwnerWidget(self).SelectedID == NodeSessionData.ID then
        SetSelected(self, true)
    else
        SetSelected(self, false)
    end
    self.Img_DialogueContent_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
    if NodeSessionData.AudioPath and NodeSessionData.AudioPath ~= "" then
        self.Switch_PlayIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        if GetOwnerWidget(self).PlayingNodeID == NodeSessionData.ID then
            self.Switch_PlayIcon:SetActiveWidgetIndex(1)
        else
            self.Switch_PlayIcon:SetActiveWidgetIndex(0)
        end
    else
        self.Switch_PlayIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

---@param self WBP_Task_PlotReview_DialogueContent
local function OnClickButton(self)
    self.NodeSessionData.OwnerWidget:OnSelectChosenItem(self.NodeSessionData)
end

---@param self WBP_Task_PlotReview_DialogueContent
local function OnHoveredButton(self)
    self.Img_DialogueContent_Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

---@param self WBP_Task_PlotReview_DialogueContent
local function OnUnhoverdButton(self)
    self.Img_DialogueContent_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function WBP_Task_PlotReview_DialogueContent:Construct()
    self.Btn_DialogueContent.OnClicked:Add(self, OnClickButton)
    self.Btn_DialogueContent.OnHovered:Add(self, OnHoveredButton)
    self.Btn_DialogueContent.OnUnhovered:Add(self, OnUnhoverdButton)
end

function WBP_Task_PlotReview_DialogueContent:Destruct()
    self.Btn_DialogueContent.OnClicked:Remove(self, OnClickButton)
    self.Btn_DialogueContent.OnHovered:Remove(self, OnHoveredButton)
    self.Btn_DialogueContent.OnUnhovered:Remove(self, OnUnhoverdButton)
end

return WBP_Task_PlotReview_DialogueContent
