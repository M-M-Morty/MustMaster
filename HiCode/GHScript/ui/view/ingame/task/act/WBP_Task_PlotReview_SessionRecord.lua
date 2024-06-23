--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
---@class WBP_Task_PlotReview_SessionRecord : WBP_Task_PlotReview_SessionRecord_C
---@field NodeData TaskNodeStepData
---@field bExpand boolean
---@field SelectedType integer
---@field SelectedContent string

---@type WBP_Task_PlotReview_SessionRecord
local WBP_Task_PlotReview_SessionRecord = UnLua.Class()

local G = require("G")
local DialogueObjectModule = require("mission.dialogue_object")
local MissionActUtils = require("CP0032305_GH.Script.mission.mission_act_utils")
local WidgetUtil = require("CP0032305_GH.Script.common.utils.widget_util")

local DEFAULT_PADDING = UE.FMargin()
DEFAULT_PADDING.Bottom = 6
DEFAULT_PADDING.Left = 0
DEFAULT_PADDING.Right = 0
DEFAULT_PADDING.Top = 0

---@class TaskNodeSessionData
---@field OwnerWidget WBP_Task_PlotReview_SessionRecord
---@field Content string
---@field Type integer
---@field bChosen boolean
---@field bSelected boolean
---@field AudioPath string
---@field ID integer

---@param self WBP_Task_PlotReview_SessionRecord
---@return WBP_Task_PlotReview
local function GetOwnerWidget(self)
    return self.NodeData.OwnerWidget.ListItemObject.OwnerWidget
end

---@param self WBP_Task_PlotReview_SessionRecord
local function RefreshPlayerIcon(self)
    ---todo 主角头像没有接口，所以没写逻辑
    local TempIcon = UE.UObject.Load('/Game/CP0032305_GH/UI/UI_Common/Texture/NoAtlas/Hero_Avatar/T_Common_Img_wali_01.T_Common_Img_wali_01')
    self.WBP_Firm_Visitor_Item:SetIconByTexture(TempIcon)
end

---@param self WBP_Task_PlotReview_SessionRecord
---@param Index integer
---@param TaskStepSessionObject TaskNodeSessionData
local function AddChildWidget(self, Index, TaskStepSessionObject)
    ---@type WBP_Task_PlotReview_DialogueContent
    local Widget = nil
    if Index <= self.VerticalBox_SessionRecord:GetAllChildren():Length() then
        Widget = self.VerticalBox_SessionRecord:GetChildAt(Index - 1)
    else
        Widget = WidgetUtil.CreateWidget(self, self.NodeClass)
        self.VerticalBox_SessionRecord:AddChildToVerticalBox(Widget)
    end
    ---@type UVerticalBoxSlot
    local Slot = Widget.Slot
    Slot:SetPadding(DEFAULT_PADDING)
    Widget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    Widget:SetData(TaskStepSessionObject)
    GetOwnerWidget(self):RegNode(Widget)
end

---@param self WBP_Task_PlotReview_SessionRecord
---@param bExpand boolean
local function Refresh(self, bExpand)
    local NodeData = self.NodeData
    self.bExpand = bExpand
    local Index = 1
    if NodeData.Type == DialogueObjectModule.DialogueType.TALK then
        if NodeData.NpcID and NodeData.NpcID > 0 then
            local NpcConfig = MissionActUtils.GetNpcConfig(NodeData.NpcID)
            if NpcConfig then
                self.WBP_Firm_Visitor_Item:SetIconByPicKey(NpcConfig.icon_ref)
            else
                G.log:warn("WBP_Task_PlotReview_SessionRecord", "npc config nil! %d", NodeData.NpcID)
            end
        else
            RefreshPlayerIcon(self)
        end
        ---@type TaskNodeSessionData
        local TaskStepSessionObject = {}
        TaskStepSessionObject.Content = NodeData.Content
        TaskStepSessionObject.Type = MissionActUtils.TaskReviewDisplayType.Normal
        TaskStepSessionObject.OwnerWidget = self
        TaskStepSessionObject.AudioPath = NodeData.AudioPath
        TaskStepSessionObject.ID = NodeData.IDs[1]

        AddChildWidget(self, Index, TaskStepSessionObject)
        Index = Index + 1

    elseif NodeData.Type == DialogueObjectModule.DialogueType.INTERACT then
        RefreshPlayerIcon(self)
        ---@type TaskNodeSessionData
        local TaskStepSessionObject = {}
        TaskStepSessionObject.Content = NodeData.Choices[NodeData.ChooseIndex]
        TaskStepSessionObject.Type = MissionActUtils.TaskReviewDisplayType.Chosen
        TaskStepSessionObject.OwnerWidget = self
        TaskStepSessionObject.ID = NodeData.IDs[1]
        AddChildWidget(self, Index, TaskStepSessionObject)
        Index = Index + 1
        if self.bExpand then
            for i = 1, #NodeData.Choices do
                ---@type TaskNodeSessionData
                local TaskStepSessionObject = {}
                local Choice = NodeData.Choices[i]
                TaskStepSessionObject.Content = Choice
                TaskStepSessionObject.Type = MissionActUtils.TaskReviewDisplayType.Option
                if i == NodeData.ChooseIndex then
                    TaskStepSessionObject.bChosen = true
                end
                TaskStepSessionObject.OwnerWidget = self
                TaskStepSessionObject.ID = NodeData.IDs[i + 1]
                AddChildWidget(self, Index, TaskStepSessionObject)
                Index = Index + 1
            end
        end
    end
    if Index <= self.VerticalBox_SessionRecord:GetAllChildren():Length() then
        for i = Index, self.VerticalBox_SessionRecord:GetAllChildren():Length() do
            local Widget = self.VerticalBox_SessionRecord:GetChildAt(i - 1)
            Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
            GetOwnerWidget(self):UnRegNode(Widget)
        end
    end
end

---@param NodeData TaskNodeStepData
function WBP_Task_PlotReview_SessionRecord:SetData(NodeData)
    self.NodeData = NodeData
    Refresh(self, false)
end

---@param TaskStepSessionData TaskNodeSessionData
function WBP_Task_PlotReview_SessionRecord:OnSelectChosenItem(TaskStepSessionData)
    if TaskStepSessionData.Type == MissionActUtils.TaskReviewDisplayType.Chosen then
        self.bExpand = not self.bExpand
    end
    self.NodeData.OwnerWidget:OnSelectChosenItem(TaskStepSessionData.ID)

    local CallBack = function()
        Refresh(self, self.bExpand)
    end
    UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, CallBack}, 0.1, false)
end

return WBP_Task_PlotReview_SessionRecord
