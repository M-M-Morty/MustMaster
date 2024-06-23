--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require("G")
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local MissionActUtils = require("CP0032305_GH.Script.mission.mission_act_utils")
local PicConst = require("CP0032305_GH.Script.common.pic_const")
local ConstText = require("CP0032305_GH.Script.common.text_const")
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local PathUtil = require("CP0032305_GH.Script.common.utils.path_util")

---@class WBP_Task_PlotReview : WBP_Task_PlotReview_C
---@field MissionActID integer
---@field bSummary boolean
---@field TileView_PropProxy UTileViewProxy
---@field ActExportData MissionActExportData
---@field CurrentSelectedMissionID integer
---@field NodeDialogueInfo table<integer, table<integer, MissionNodeDialogueData>>
---@field Nodes table<WBP_Task_PlotReview_DialogueContent, boolean>
---@field LastNodeWidget WBP_Task_TaskNode

---@type WBP_Task_PlotReview
local WBP_Task_PlotReview = Class(UIWindowBase)

local MAT_PARAM_NO_HIDE = 0
local MAT_PARAM_HIDE = 1.6
local MAT_PARAM = 23

---@param self WBP_Task_PlotReview
---@param RetainerBox URetainerBox
local function ShowUpShadow(self, RetainerBox)
    local EffectMaterial = RetainerBox:GetEffectMaterial()
    EffectMaterial:SetScalarParameterValue("Power1", MAT_PARAM_NO_HIDE)
    EffectMaterial:SetScalarParameterValue("Power2", MAT_PARAM_HIDE)
    EffectMaterial:SetScalarParameterValue("progress", MAT_PARAM)
end

---@param self WBP_Task_PlotReview
---@param RetainerBox URetainerBox
local function ShowDownShadow(self, RetainerBox)
    local EffectMaterial = RetainerBox:GetEffectMaterial()
    EffectMaterial:SetScalarParameterValue("Power1", MAT_PARAM_HIDE)
    EffectMaterial:SetScalarParameterValue("Power2", MAT_PARAM_NO_HIDE)
    EffectMaterial:SetScalarParameterValue("progress", MAT_PARAM)
end

---@param self WBP_Task_PlotReview
---@param RetainerBox URetainerBox
local function ShowBothShadow(self, RetainerBox)
    local EffectMaterial = RetainerBox:GetEffectMaterial()
    EffectMaterial:SetScalarParameterValue("Power1", MAT_PARAM_HIDE)
    EffectMaterial:SetScalarParameterValue("Power2", MAT_PARAM_HIDE)
    EffectMaterial:SetScalarParameterValue("progress", MAT_PARAM)
end

---@param self WBP_Task_PlotReview
---@param RetainerBox URetainerBox
local function ShowNoShadow(self, RetainerBox)
    local EffectMaterial = RetainerBox:GetEffectMaterial()
    EffectMaterial:SetScalarParameterValue("Power1", MAT_PARAM_NO_HIDE)
    EffectMaterial:SetScalarParameterValue("Power2", MAT_PARAM_NO_HIDE)
    EffectMaterial:SetScalarParameterValue("progress", MAT_PARAM)
end

---@param self WBP_Task_PlotReview
local function OnClickCloseButton(self)
    UIManager:CloseUI(self, true)
end

---@param self WBP_Task_PlotReview
local function RefreshPhoto(self)
    ---@type WBP_Task_Photo
    local WBP_Task_Photo = self.WBP_Task_Photo
    local MissionActConfig = self.MissionActConfig
    WBP_Task_Photo:SetOnlyPhoto(MissionActConfig.ActPic)
end

---@param self WBP_Task_PlotReview
local function RefreshActDetail(self)
    self.Switch_CaseContent:SetActiveWidgetIndex(1)
    local MissionActConfig = self.MissionActConfig
    local NpcConfig = MissionActUtils.GetNpcConfig(MissionActConfig.ActNpc)
    if NpcConfig then
        self.Txt_NpcName:SetText(NpcConfig.name)
        PicConst.SetImageBrush(self.Img_Photo, NpcConfig.icon_ref)
    else
        G.log:warn("WBP_Task_PlotReview", "npc config nil! ID: %d", MissionActConfig.ActNpc)
    end
    self.Txt_Title:SetText(MissionActConfig.Name)
    self.Txt_Description:SetText(MissionActConfig.Descript)
    self.Txt_Conclusion:SetText(ConstText.GetConstText(MissionActConfig.Mission_Act_Conclusion))
end

---@param self WBP_Task_PlotReview
local function RefreshReward(self)
    self.Tile_RewardList:SetVisibility(UE.ESlateVisibility.Visible)
    self.Txt_DistributeRewards:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

    local Items = {}
    if self.MissionActConfig then
        local Mission_Act_Reward = self.MissionActConfig.Mission_Act_Reward
        if Mission_Act_Reward then
            for ItemID, Count in pairs(Mission_Act_Reward) do
                local Item = {}
                Item.ID = ItemID
                Item.Number = Count
                table.insert(Items, Item)
            end
        end
    end
    self.TileView_PropProxy:SetListItems(Items)
end

---@param self WBP_Task_PlotReview
local function HiddenReward(self)
    self.Tile_RewardList:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Txt_DistributeRewards:SetVisibility(UE.ESlateVisibility.Collapsed)
end

---@param self WBP_Task_PlotReview
---@param bShow boolean
local function ShowContinue(self, bShow)
    if bShow then
        self.WBP_Btn_ClickToContinue:SetVisibility(UE.ESlateVisibility.Visible)
        self.ButtonBg:SetVisibility(UE.ESlateVisibility.Visible)
        self.WBP_Common_TopContent.CommonButton_Close:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.WBP_Btn_ClickToContinue:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.ButtonBg:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.WBP_Common_TopContent.CommonButton_Close:SetVisibility(UE.ESlateVisibility.Visible)
    end
end

---@param self WBP_Task_PlotReview
---@param bShow boolean
---@param Index integer
local function ShowLeftButton(self, bShow, Index)
    if bShow then
        self.WBP_Btn_View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.SwitcherButtonContent:SetActiveWidgetIndex(Index)
    else
        self.WBP_Btn_View:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

---@param self WBP_Task_PlotReview
---@param OffsetInitems float
local function OnListTaskNodeScrolled(self, OffsetInitems, _)
    if OffsetInitems == 0.0 then
        for _, v in pairs(self.ShadowTimers) do
            UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, v)
        end
        self.ShadowTimers = {}
        ShowDownShadow(self, self.RetaTaskNodeContent)
    elseif self.LastNodeWidget then
        ---@param self WBP_Task_PlotReview
        local SetShadow = function(self)
            if self.LastNodeWidget then
                local ListAbsolutePos = UE.USlateBlueprintLibrary.LocalToAbsolute(self.List_TaskNodeContent:GetCachedGeometry(), UE.FVector2D(0, 0))
                local ListAbsoluteSize = UE.USlateBlueprintLibrary.GetAbsoluteSize(self.List_TaskNodeContent:GetCachedGeometry())
                local LastWidgetAbsolutePos = UE.USlateBlueprintLibrary.LocalToAbsolute(self.LastNodeWidget:GetCachedGeometry(), UE.FVector2D(0, 0))
                --local LocalLastWidgetPos = UE.USlateBlueprintLibrary.AbsoluteToLocal(self.List_TaskNodeContent:GetCachedGeometry(), AbsoluteLastWidgetPos)
                local LastWidgetAbsoluteSize = UE.USlateBlueprintLibrary.GetAbsoluteSize(self.LastNodeWidget:GetCachedGeometry())
                local delta = LastWidgetAbsolutePos.Y + LastWidgetAbsoluteSize.Y - ListAbsolutePos.Y - ListAbsoluteSize.Y
                if LastWidgetAbsoluteSize.X > 0 and LastWidgetAbsoluteSize.Y > 0 and delta <= 1 then
                    ShowUpShadow(self, self.RetaTaskNodeContent)
                else
                    ShowBothShadow(self, self.RetaTaskNodeContent)
                end
            else
                ShowBothShadow(self, self.RetaTaskNodeContent)
            end
        end
        local ShadowTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, SetShadow }, 0.1, false)
        table.insert(self.ShadowTimers, ShadowTimer)
    else
        for _, v in pairs(self.ShadowTimers) do
            UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, v)
        end
        self.ShadowTimers = {}
        ShowBothShadow(self, self.RetaTaskNodeContent)
    end
end

---@param self WBP_Task_PlotReview
local function ShowLeftSummary(self)
    self.Switcher_PreviewLeft:SetActiveWidgetIndex(1)
    local NpcComments = MissionActUtils.GetMissionCompleteNpcComments(self.MissionActID)

    local Path = PathUtil.getFullPathString(self.NpcCommentClass)
    local NpcCommentClass = LoadObject(Path)
    local InListItems = UE.TArray(NpcCommentClass)
    for _, Comment in ipairs(NpcComments) do
        ---@type BP_NpcComment_C
        local NpcCommentObject = NewObject(NpcCommentClass)
        NpcCommentObject.NpcID = Comment.NpcID
        NpcCommentObject.NpcName = Comment.NpcName
        NpcCommentObject.NpcIconKey = Comment.NpcIconKey
        NpcCommentObject.CommentKey = Comment.CommentKey
        InListItems:Add(NpcCommentObject)
    end
    self.List_NPCComment:BP_SetListItems(InListItems)
end

---@param self WBP_Task_PlotReview
---@param OffsetInitems float
local function OnListPreviewScrolled(self, OffsetInitems, _)
    if self.NewListPreviewWidget == nil then
        ShowDownShadow(self, self.Reta_Summary)
        return
    end
    local ListGeometry = self.List_SubList:GetCachedGeometry()
    local ListLocalSize = UE.USlateBlueprintLibrary.GetLocalSize(ListGeometry)

    local ItemGeometry = self.NewListPreviewWidget:GetCachedGeometry()
    local ItemLocalSize = UE.USlateBlueprintLibrary.GetLocalSize(ItemGeometry)

    local Total = self.List_SubList:GetNumItems()


    if ItemLocalSize.Y * Total <= ListLocalSize.Y then
        ShowNoShadow(self, self.Reta_Summary)
        return
    end

    if OffsetInitems * ItemLocalSize.Y + ListLocalSize.Y >= ItemLocalSize.Y * Total then
        ShowUpShadow(self, self.Reta_Summary)
        return
    end

    if OffsetInitems <= 0.1 then
        ShowDownShadow(self, self.Reta_Summary)
        return
    end
    ShowBothShadow(self, self.Reta_Summary)
end

---@param self WBP_Task_PlotReview
local function ShowLeftRecord(self)
    self.Switcher_PreviewLeft:SetActiveWidgetIndex(0)
    local Path = PathUtil.getFullPathString(self.TaskPreviewClass)
    local TaskPreviewClass = LoadObject(Path)
    local InListItems = UE.TArray(TaskPreviewClass)
    for i, v in ipairs(self.ActExportData.Missions) do
        ---@type BP_TaskPreviewItem_C
        local TaskPreviewObject = NewObject(TaskPreviewClass)
        TaskPreviewObject.MissionID = v.MissionID
        TaskPreviewObject.OwnerWidget = self
        if i == 1 then
            self.CurrentSelectedMissionID = v.MissionID
        end
        InListItems:Add(TaskPreviewObject)
    end
    self.List_SubList:BP_SetListItems(InListItems)
    self.List_SubList:SetSelectedIndex(0)
    local SetShadow = function()
        OnListPreviewScrolled(self, self.List_SubList:GetScrollOffset())
    end
    UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, SetShadow }, 0.2, false)
end

---@param self WBP_Task_PlotReview
local function ShowRightRecord(self)
    self.Switch_CaseContent:SetActiveWidgetIndex(0)
    local TaskNodePath = PathUtil.getFullPathString(self.TaskNodeClass)
    local TaskNodeClass = LoadObject(TaskNodePath)
    local TaskNodeInListItems = UE.TArray(TaskNodeClass)
    ---@type MissionExportData
    local MissionData = nil
    for i, v in ipairs(self.ActExportData.Missions) do
        if v.MissionID == self.CurrentSelectedMissionID then
            MissionData = v
        end
    end
    if MissionData then
        for _, v in ipairs(MissionData.Nodes) do
            ---@type BP_TaskNodeItem_C
            local TaskNodeObject = NewObject(TaskNodeClass)
            TaskNodeObject.Type = v.Type
            TaskNodeObject.MissionEventID = v.MissionEventID
            TaskNodeObject.DialogueID = v.DialogueID
            TaskNodeObject.MissionActID = self.MissionActID
            TaskNodeObject.OwnerWidget = self
            TaskNodeInListItems:Add(TaskNodeObject)
        end
    end

    self.List_TaskNodeContent:BP_SetListItems(TaskNodeInListItems)
    self.List_TaskNodeContent:SetScrollbarVisibility(UE.ESlateVisibility.Collapsed)

    ---@param self WBP_Task_PlotReview
    local SetShadow = function(self)
        OnListTaskNodeScrolled(self, self.List_TaskNodeContent:GetScrollOffset())
        self.List_TaskNodeContent:RequestRefresh()
    end
    UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, SetShadow }, 0.1, false)
end

---@param self WBP_Task_PlotReview
---@param NodeID integer
local function GetNode(self, NodeID)
    for v, _ in pairs(self.Nodes) do
        if v.NodeSessionData and v.NodeSessionData.ID == NodeID then
            return v
        end
    end
    return nil
end

function WBP_Task_PlotReview:OnAkStartCompleted()
    if self.PlayingID and self.PlayingID > 0 then
        for v, _ in pairs(self.Nodes) do
            if v.NodeSessionData and v.NodeSessionData.ID == self.PlayingNodeID then
                v:AudioStateChanged(true)
            end
        end
    end
end

---@param self WBP_Task_PlotReview
---@param SelectedNode WBP_Task_PlotReview_DialogueContent
local function PlayAkEvent(self, SelectedNode)
    local Asset = UE.UObject.Load(SelectedNode.NodeSessionData.AudioPath)
    if Asset then
        self:PlayAkEvent(Asset, SelectedNode.NodeSessionData.ID)
    end
end

---@param NodeID integer
---@return void
function WBP_Task_PlotReview:OnAkEventFinish(NodeID)
    self.PlayingID = 0
    self.PlayingNodeID = 0
    for v, _ in pairs(self.Nodes) do
        if v.NodeSessionData and v.NodeSessionData.ID == NodeID then
            v:AudioStateChanged(false)
        end
    end
    if self.PeedingPlayNode then
        PlayAkEvent(self, self.PeedingPlayNode)
        self.PeedingPlayNode = nil
    end
end

---@param SelectedID integer
function WBP_Task_PlotReview:OnSelectChosenNodeItem(SelectedID)
    local OldSelectedID = self.SelectedID
    self.SelectedID = SelectedID
    for Node, _ in pairs(self.Nodes) do
        Node:OnSelectedChanged(SelectedID)
    end
    local bStop = false
    if self.PlayingID and self.PlayingID > 0 then
        bStop = true
        self:StopAkEvent()
    end
    if SelectedID == nil then
        return
    end
    local SelectedNode = GetNode(self, SelectedID)
    if SelectedNode == nil then
        return
    end
    local AudioPath = SelectedNode.NodeSessionData.AudioPath
    if AudioPath and AudioPath ~= "" then
        if self.SelectedID == OldSelectedID then
            if not bStop then
                PlayAkEvent(self, SelectedNode)
            end
        else
            if not bStop then
                PlayAkEvent(self, SelectedNode)
            else
                self.PeedingPlayNode = SelectedNode
            end
        end
    end
end

---@param self WBP_Task_PlotReview
local function SetDetailState(self)
    if self.bSummary then
        ShowLeftSummary(self)
        RefreshActDetail(self)
        ShowLeftButton(self, true, 1)
    else
        self.ActExportData = MissionActUtils.GetMissionActExportData(self.MissionActID)
        ShowLeftRecord(self)
        ShowRightRecord(self)
        ShowLeftButton(self, true, 0)
    end
end

---@param self WBP_Task_PlotReview
local function ChangeDetailState(self)
    self:OnSelectChosenNodeItem(nil)
    self:PlayAnimation(self.DX_PreviewSwitch, 0, 1,  UE.EUMGSequencePlayMode.Forward, 1, false)
    self.bSummary = not self.bSummary
    SetDetailState(self)
end

function WBP_Task_PlotReview:BuildWidgetProxy()
    ---@type UTileViewProxy
    self.TileView_PropProxy = WidgetProxys:CreateWidgetProxy(self.Tile_RewardList)
end

---@param self WBP_Task_PlotReview
---@param CurrentOffset float
local function OnDetailScrolled(self, CurrentOffset)
    if CurrentOffset == 0.0 then
        ShowDownShadow(self, self.RetaTaskDetail)
    elseif math.abs(CurrentOffset - self.ScrollBoxTaskDetail:GetScrollOffsetOfEnd()) < 1 then
        ShowUpShadow(self, self.RetaTaskDetail)
    else
        ShowBothShadow(self, self.RetaTaskDetail)
    end
end

---@param self WBP_Task_PlotReview
---@param Widget UUserWidget
local function OnListPreviewGenerated(self, Widget)
    self.NewListPreviewWidget = Widget
end

---@param self WBP_Task_PlotReview
---@param Widget WBP_Task_TaskNode
local function OnListTaskNodeGenerated(self, Widget)
    local Index = self.List_TaskNodeContent:GetIndexForItem(Widget.ListItemObject)
    local Total = self.List_TaskNodeContent:GetNumItems()
    if Index == Total - 1 then
        self.LastNodeWidget = Widget
    end
end

---@param self WBP_Task_PlotReview
---@param Widget WBP_Task_TaskNode
local function OnListTaskNodeReleased(self, Widget)
    local Index = self.List_TaskNodeContent:GetIndexForItem(Widget.ListItemObject)
    local Total = self.List_TaskNodeContent:GetNumItems()
    if Index == Total - 1 then
        self.LastNodeWidget = nil
    end
end

function WBP_Task_PlotReview:OnConstruct()
    self.WBP_Common_TopContent.CommonButton_Close.OnClicked:Add(self, OnClickCloseButton)
    self.WBP_Btn_View.OnClicked:Add(self, ChangeDetailState)
    self.WBP_Btn_ClickToContinue.OnClicked:Add(self, OnClickCloseButton)
    self.ButtonBg.OnClicked:Add(self, OnClickCloseButton)
    self.List_SubList.BP_OnListViewScrolled:Add(self, OnListPreviewScrolled)
    self.List_SubList.BP_OnEntryGenerated:Add(self, OnListPreviewGenerated)
    self.List_TaskNodeContent.BP_OnListViewScrolled:Add(self, OnListTaskNodeScrolled)
    self.List_TaskNodeContent.BP_OnEntryGenerated:Add(self, OnListTaskNodeGenerated)
    self.List_TaskNodeContent.BP_OnEntryReleased:Add(self, OnListTaskNodeReleased)
    self.ScrollBoxTaskDetail.OnUserScrolled:Add(self, OnDetailScrolled)
    self:BuildWidgetProxy()
    self.Nodes = {}
    self.ShadowTimers = {}
end

function WBP_Task_PlotReview:OnDestruct()
    self.WBP_Common_TopContent.CommonButton_Close.OnClicked:Remove(self, OnClickCloseButton)
    self.WBP_Btn_View.OnClicked:Remove(self, ChangeDetailState)
    self.WBP_Btn_ClickToContinue.OnClicked:Remove(self, OnClickCloseButton)
    self.ButtonBg.OnClicked:Remove(self, OnClickCloseButton)
    self.List_SubList.BP_OnListViewScrolled:Remove(self, OnListPreviewScrolled)
    self.List_SubList.BP_OnEntryGenerated:Remove(self, OnListPreviewGenerated)
    self.List_TaskNodeContent.BP_OnListViewScrolled:Remove(self, OnListTaskNodeScrolled)
    self.List_TaskNodeContent.BP_OnEntryGenerated:Remove(self, OnListTaskNodeGenerated)
    self.List_TaskNodeContent.BP_OnEntryReleased:Remove(self, OnListTaskNodeReleased)
    self.ScrollBoxTaskDetail.OnUserScrolled:Remove(self, OnDetailScrolled)
end

function WBP_Task_PlotReview:OnShow()
    self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end

function WBP_Task_PlotReview:OnHide()
    self:OnSelectChosenNodeItem(nil)
end

---@param Item BP_TaskPreviewItem_C
function WBP_Task_PlotReview:OnClickListItem(Item)
    local Index = self.List_SubList:GetIndexForItem(Item)
    self.List_SubList:SetSelectedIndex(Index)
    self.CurrentSelectedMissionID = Item.MissionID
    ShowRightRecord(self)
    self:PlayAnimation(self.DX_TaskNodeSwitch, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    self:OnSelectChosenNodeItem(nil)
end

---@param self WBP_Task_PlotReview
local function PrepareConfig(self)
    local MissionActID = self.MissionActID
    if MissionActID == nil then
        G.log:error("WBP_Task_PlotReview", "PrepareConfig MissionActID nil")
        return false
    end

    self.MissionActConfig = MissionActUtils.GetMissionActConfig(MissionActID)
    if self.MissionActConfig == nil then
        G.log:error("WBP_Task_PlotReview", "PrepareConfig MissionActID cannot find MissionActConfig! %d", MissionActID)
        return false
    end
    return true
end

---@param MissionActID integer
function WBP_Task_PlotReview:ShowReward(MissionActID)
    self.MissionActID = MissionActID
    if not PrepareConfig(self) then
        return
    end
    RefreshActDetail(self)
    RefreshPhoto(self)
    RefreshReward(self)
    ShowContinue(self, true)
    ShowLeftSummary(self)
    ShowLeftButton(self, false)
end

---@param MissionActID integer
function WBP_Task_PlotReview:ShowSummary(MissionActID)
    self.MissionActID = MissionActID
    if not PrepareConfig(self) then
        return
    end
    RefreshPhoto(self)
    ShowContinue(self, false)
    HiddenReward(self)
    self.bSummary = true
    SetDetailState(self)
end

function WBP_Task_PlotReview:GetMissionNodeDialogueData(MissionActID, MissionEventID, DialogueID)
    if self.NodeDialogueInfo == nil then
        self.NodeDialogueInfo = {}
    end
    if self.NodeDialogueInfo[MissionActID] == nil then
        self.NodeDialogueInfo[MissionActID] = {}
    end
    if self.NodeDialogueInfo[MissionActID][MissionEventID] == nil then
        self.NodeDialogueInfo[MissionActID][MissionEventID] = {}
    end
    if self.NodeDialogueInfo[MissionActID][MissionEventID][DialogueID] == nil then
        --self.NodeDialogueInfo[MissionActID][MissionEventID][DialogueID] = MissionActUtils.MockMissionNodeDialogueData(MissionActID, DialogueID)
        self.NodeDialogueInfo[MissionActID][MissionEventID][DialogueID] = MissionActUtils.GetMissionNodeDialogueData(MissionActID, DialogueID)
    end
    return self.NodeDialogueInfo[MissionActID][MissionEventID][DialogueID]
end

---@param Node WBP_Task_PlotReview_DialogueContent
function WBP_Task_PlotReview:RegNode(Node)
    self.Nodes[Node] = Node
end

---@param Node WBP_Task_PlotReview_DialogueContent
function WBP_Task_PlotReview:UnRegNode(Node)
    self.Nodes[Node] = nil
end

return WBP_Task_PlotReview
