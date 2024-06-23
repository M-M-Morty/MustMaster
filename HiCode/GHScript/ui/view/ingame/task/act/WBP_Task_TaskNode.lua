--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
---@class WBP_Task_TaskNode : WBP_Task_TaskNode_C
---@field ListItemObject BP_TaskNodeItem_C

---@type WBP_Task_TaskNode
local WBP_Task_TaskNode = UnLua.Class()

local G = require("G")
local MissionActUtils = require("CP0032305_GH.Script.mission.mission_act_utils")
local DialogueObjectModule = require("mission.dialogue_object")
local WidgetUtil = require("CP0032305_GH.Script.common.utils.widget_util")

---@class TaskNodeStepData
---@field OwnerWidget WBP_Task_TaskNode
---@field Type integer
---@field NpcID integer
---@field Content string
---@field ChooseIndex integer
---@field Choices string[]
---@field bSelected boolean
---@field AudioPath string
---@field IDs integer[]

---@param self WBP_Task_TaskNode
---@param bSelected boolean
local function RefreshSteps(self, bSelected)
    local ListItemObject = self.ListItemObject
    local DialogueData = ListItemObject.OwnerWidget:GetMissionNodeDialogueData(ListItemObject.MissionActID, ListItemObject.MissionEventID, ListItemObject.DialogueID)
    for Index, Step in ipairs(DialogueData.Steps) do
        ---@type TaskNodeStepData
        local TaskStepData = {}
        TaskStepData.OwnerWidget = self
        TaskStepData.Type = Step.Type
        TaskStepData.bSelected = bSelected
        TaskStepData.IDs = {}
        for _, v in pairs(Step.IDs) do
            table.insert(TaskStepData.IDs, v)
        end
        if Step.Type == DialogueObjectModule.DialogueType.TALK then
            if Step.NpcID then
                TaskStepData.NpcID = Step.NpcID
            end
            TaskStepData.Content = Step.Content
            TaskStepData.AudioPath = Step.AudioPath
        elseif Step.Type == DialogueObjectModule.DialogueType.INTERACT then
            TaskStepData.ChooseIndex = Step.ChooseIndex
            TaskStepData.Choices = {}
            if Step.Choices and #Step.Choices > 0 then
                for _, Choice in pairs(Step.Choices) do
                    table.insert(TaskStepData.Choices, Choice)
                end
            end
        end
        ---@type WBP_Task_PlotReview_SessionRecord
        local ChildWidget = nil
        local ChildrenWidget = self.VerticalBox_TaskNode:GetAllChildren()
        if Index <= ChildrenWidget:Length() then
            ChildWidget = ChildrenWidget:GetRef(Index)
        else
            ---@type WBP_Task_PlotReview_SessionRecord
            ChildWidget = WidgetUtil.CreateWidget(self, self.NodeClass)
            self.VerticalBox_TaskNode:AddChildToVerticalBox(ChildWidget)
        end
        ChildWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        ChildWidget:SetData(TaskStepData)
    end

    if #DialogueData.Steps < self.VerticalBox_TaskNode:GetAllChildren():Length() then
        for i = #DialogueData.Steps + 1, self.VerticalBox_TaskNode:GetAllChildren():Length() do
            local ChildWidget = self.VerticalBox_TaskNode:GetChildAt(i - 1)
            ChildWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

---@param self WBP_Task_TaskNode
---@param bSelected boolean
local function Refresh(self, bSelected)
    local Index = self.ListItemObject.OwnerWidget.List_TaskNodeContent:GetIndexForItem(self.ListItemObject)
    if Index == 0 then
        self.SizeBox_TaskDescription:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        local MissionID = self.ListItemObject.OwnerWidget.CurrentSelectedMissionID
        local MissionConfig = MissionActUtils.GetMissionConfig(MissionID)
        if MissionConfig == nil then
            G.log:warn("WBP_Task_TaskNode", "MissionConfig nil! MissionID: %d", MissionID)
        else
            self.Txt_TaskDescription:SetText(MissionConfig.Descript)
        end
    else
        self.SizeBox_TaskDescription:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    local ListItemObject = self.ListItemObject
    local EventDiscriptionConfig = MissionActUtils.GetEventDescriptionConfig(ListItemObject.MissionEventID)
    if EventDiscriptionConfig == nil then
        G.log:warn("WBP_Task_TaskNode", "EventDiscriptionConfig nil! MissionEventID: %d", ListItemObject.MissionEventID)
    else
        local content = EventDiscriptionConfig.review_content
        if content == nil or content == "" then
            content = EventDiscriptionConfig.content
        end
        self.Txt_TaskNode:SetText(content)
    end
    if ListItemObject.Type == MissionActUtils.TaskNodeShowType.Normal then
        self.VerticalBox_TaskNode:SetVisibility(UE.ESlateVisibility.Collapsed)
    elseif ListItemObject.Type == MissionActUtils.TaskNodeShowType.DialogueSelf or ListItemObject.Type == MissionActUtils.TaskNodeShowType.DialogueNpc then
        self.VerticalBox_TaskNode:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        RefreshSteps(self, bSelected)
    end
end

---Called when this entry is assigned a new item object to represent by the owning list view
---@param ListItemObject BP_TaskNodeItem_C
---@return void
function WBP_Task_TaskNode:OnListItemObjectSet(ListItemObject)
    self.ListItemObject = ListItemObject
    Refresh(self, false)
end

---@param SelectedID integer
function WBP_Task_TaskNode:OnSelectChosenItem(SelectedID)
    self.ListItemObject.OwnerWidget:OnSelectChosenNodeItem(SelectedID)
end

return WBP_Task_TaskNode
