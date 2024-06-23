--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local MissionActUtils = require("CP0032305_GH.Script.mission.mission_act_utils")
local PathUtil = require("CP0032305_GH.Script.common.utils.path_util")
local TipsUtil = require("CP0032305_GH.Script.common.utils.tips_util")

local LEFT_COUNT = 3
local RIGHT_COUNT = 1
local NEW_MISSION_ACT_KEY = "Toast_Get_New_MissionAct"
local MOUSE_WHEEL_INTERVAL = 200
local CARD_LIST_WIDGET_PREFIX = "WBP_Task_CaseList_"
local TARGET_CARD_LIST_WIDGET_PREFIX = "WBP_Task_CaseListTarget_"

---@type CurrencyData[]
local CurrencyDatas = {
    {ExcelID = 990010, bShowAddButton = true},
}

---@class WBP_Task_FirmHomePage : WBP_Task_FirmHomePage_C
---@field CurrentMissionActs MissionActData[]
---@field Events RandomEventData[]
---@field OfficialNewsWidgets WBP_Task_OfficialNews_List[]
---@field DragDelta float
---@field MouseWheelTime float
---@field OldShowID integer
---@field CurrentShowID integer
---@field CurrentPressCase WBP_Task_CaseList
---@field CurrentHoverCase WBP_Task_CaseList
---@field BorderDragPressDownTime integer
---@field BorderDragDownAndMove boolean
---@field CurrentPlayingAnim UWidgetAnimation

---@type WBP_Task_FirmHomePage
local WBP_Task_FirmHomePage = Class(UIWindowBase)

--local MAT_PARAM_NO_HIDE = 0
--local MAT_PARAM_HIDE = 1.6
--local MAT_PARAM = 23

-----@param self WBP_Task_FirmHomePage
--local function ShowUpShadow(self)
--    local EffectMaterial = self.Reta_ListHidden:GetEffectMaterial()
--    EffectMaterial:SetScalarParameterValue("Power1", MAT_PARAM_NO_HIDE)
--    EffectMaterial:SetScalarParameterValue("Power2", MAT_PARAM_HIDE)
--    EffectMaterial:SetScalarParameterValue("progress", MAT_PARAM)
--end
--
-----@param self WBP_Task_FirmHomePage
--local function ShowDownShadow(self)
--    local EffectMaterial = self.Reta_ListHidden:GetEffectMaterial()
--    EffectMaterial:SetScalarParameterValue("Power1", MAT_PARAM_HIDE)
--    EffectMaterial:SetScalarParameterValue("Power2", MAT_PARAM_NO_HIDE)
--    EffectMaterial:SetScalarParameterValue("progress", MAT_PARAM)
--end
--
-----@param self WBP_Task_FirmHomePage
--local function ShowBothShadow(self)
--    local EffectMaterial = self.Reta_ListHidden:GetEffectMaterial()
--    EffectMaterial:SetScalarParameterValue("Power1", MAT_PARAM_HIDE)
--    EffectMaterial:SetScalarParameterValue("Power2", MAT_PARAM_HIDE)
--    EffectMaterial:SetScalarParameterValue("progress", MAT_PARAM)
--end
--
-----@param self WBP_Task_FirmHomePage
--local function ShowNoShadow(self)
--    local EffectMaterial = self.Reta_ListHidden:GetEffectMaterial()
--    EffectMaterial:SetScalarParameterValue("Power1", MAT_PARAM_NO_HIDE)
--    EffectMaterial:SetScalarParameterValue("Power2", MAT_PARAM_NO_HIDE)
--    EffectMaterial:SetScalarParameterValue("progress", MAT_PARAM)
--end

-----@param self WBP_Task_FirmHomePage
-----@param OffsetInitems float
-----@param DistanceRemaining float
--local function OnListViewScrolled(self, OffsetInitems, _)
--    local CurrentFirst = math.ceil(OffsetInitems)
--    local Total = self.List_OfficialNews:GetNumItems()
--    local RemainHeight = 0
--    local NotShowLastOne = false
--    for i = CurrentFirst, Total do
--        ---这里index居然从0开始的。。。
--        local ItemObject = self.List_OfficialNews:GetItemAt(i - 1)
--        if self.List_OfficialNews:BP_IsItemVisible(ItemObject) then
--            local Widget = self.OfficialNewsWidgets[i]
--            local WidgetGeometry = Widget:GetCachedGeometry()
--            local ListLocalSize = UE.USlateBlueprintLibrary.GetLocalSize(WidgetGeometry)
--            if i == CurrentFirst then
--                RemainHeight = RemainHeight + ListLocalSize.Y * (CurrentFirst - OffsetInitems)
--            else
--                RemainHeight = RemainHeight + ListLocalSize.Y
--            end
--        else
--            NotShowLastOne = true
--            break
--        end
--    end
--    local ListGeometry = self.List_OfficialNews:GetCachedGeometry()
--    local ListLocalSize = UE.USlateBlueprintLibrary.GetLocalSize(ListGeometry)
--    if NotShowLastOne then
--        if OffsetInitems <= 0.1 then
--            ShowDownShadow(self)
--        else
--            ShowBothShadow(self)
--        end
--    else
--        if ListLocalSize.Y > RemainHeight or (RemainHeight - ListLocalSize.Y > 0 and RemainHeight - ListLocalSize.Y < 2) then
--            if OffsetInitems <= 0.1 then
--                ShowNoShadow(self)
--            else
--                ShowUpShadow(self)
--            end
--        else
--            if OffsetInitems <= 0.1 then
--                ShowDownShadow(self)
--            else
--                ShowBothShadow(self)
--            end
--        end
--    end
--end

---@param self WBP_Task_FirmHomePage
local function SetCurrencyType(self)
    self.WBP_Common_Currency:SetCurrencyDatas(CurrencyDatas)
end

---@param self WBP_Task_FirmHomePage
local function OnClickCloseButton(self)
    UIManager:CloseUI(self, true)
end

---@param self WBP_Task_FirmHomePage
local function OnClickCaseWall(self)
    UIManager:OpenUI(UIDef.UIInfo.UI_Task_CaseWall)
end

---@param self WBP_Task_FirmHomePage
---@param MissionActID integer
---@param State integer
local function OnActStateChanged(self, MissionActID, State)
    ---@type EMissionActState
    local EMissionActState = Enum.EMissionActState
    if State == EMissionActState.RewardReceived then
        local RewardWidget = UIManager:OpenUI(UIDef.UIInfo.UI_Task_PlotReview)
        RewardWidget:ShowReward(MissionActID)
        self:RefreshMissions()
    else
        if self.CurrentShowID == MissionActID then
            ---@type WBP_Task_FirmDetail
            local WBP_Task_FirmDetail = self.WBP_Task_FirmDetail
            WBP_Task_FirmDetail:SetTaskActID(self.CurrentShowID)
        end
        if State == EMissionActState.Start then
            TipsUtil.ShowCommonTips(NEW_MISSION_ACT_KEY)
        end
    end
end

---@param self WBP_Task_FirmHomePage
---@param ActID integer
---@return integer
local function GetIndex(self, ActID)
    local Index = 1
    for i, v in ipairs(self.CurrentMissionActs) do
        if v.MissionActID == ActID then
            Index = i
            break
        end
    end
    return Index
end

---@param self WBP_Task_FirmHomePage
---@param Delta float
local function ChangeCurrentByDelta(self, Delta)
    if Delta < 0 then
        local Index = GetIndex(self, self.CurrentShowID)
        if Index and Index < #self.CurrentMissionActs then
            self:OnClickMission(self.CurrentMissionActs[Index + 1].MissionActID)
        end
    else
        local Index = GetIndex(self, self.CurrentShowID)
        if Index and Index > 1 then
            self:OnClickMission(self.CurrentMissionActs[Index - 1].MissionActID)
        end
    end
end

---@param self WBP_Task_FirmHomePage
---@param MouseEvent FPointerEvent
local function CheckPressDownOnAct(self, MouseEvent)
    local MouseAbsolutePos = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(MouseEvent)
    for i = 1, LEFT_COUNT + 1 + RIGHT_COUNT do
        if i ~= LEFT_COUNT + 1 then
            ---@type WBP_Task_CaseList
            local WBP_TaskCaseList = self[CARD_LIST_WIDGET_PREFIX..i]
            if WBP_TaskCaseList:IsVisible() then
                local ChildWidgetGeometry = WBP_TaskCaseList:GetCachedGeometry()
                local MouseLocalPos = UE.USlateBlueprintLibrary.AbsoluteToLocal(ChildWidgetGeometry, MouseAbsolutePos)
                local ChildWidgetLocalSize = UE.USlateBlueprintLibrary.GetLocalSize(ChildWidgetGeometry)
                if ChildWidgetLocalSize.X > 0 and ChildWidgetLocalSize.Y > 0 and MouseLocalPos.X > 0 and MouseLocalPos.X < ChildWidgetLocalSize.X
                        and MouseLocalPos.Y > 0 and MouseLocalPos.Y < ChildWidgetLocalSize.Y then
                    self.CurrentPressCase = WBP_TaskCaseList
                    WBP_TaskCaseList.WBP_Btn_PhotoThumbnail:Button_OnPressed()
                    break
                end
            end
        end
    end
end


---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
function WBP_Task_FirmHomePage:OnBorderMouseDown(MyGeometry, MouseEvent)
    self.DragDelta = 0
    self.BorderDragPressDownTime = UE.UHiUtilsFunctionLibrary.GetNowTimestampMs()
    self.BorderDragDownAndMove = false
    CheckPressDownOnAct(self, MouseEvent)
    return UE.UWidgetBlueprintLibrary.Handled()
end

---@param self WBP_Task_FirmHomePage
local function BorderMouseUp(self)
    if self.CurrentPressCase then
        self.CurrentPressCase.WBP_Btn_PhotoThumbnail:Button_OnReleased()
        if self.BorderDragPressDownTime and self.BorderDragPressDownTime ~= 0 then
            local now = UE.UHiUtilsFunctionLibrary.GetNowTimestampMs()
            if not self.BorderDragDownAndMove then
                self:OnClickMission(self.CurrentPressCase.MissionActID)
            end
        end
    end
    if self.bNeedBounceBack then
        self:PlayAnimation(self.DX_BounceBack, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    end
    self.bNeedBounceBack = false
    self.DragDelta = 0
    self.BorderDragPressDownTime = 0
    self.BorderDragDownAndMove = false
    self.CurrentPressCase = nil
end

---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
function WBP_Task_FirmHomePage:OnBorderMouseUp(MyGeometry, MouseEvent)
    BorderMouseUp(self)
    return UE.UWidgetBlueprintLibrary.Handled()
end

---@param self WBP_Task_FirmHomePage
---@param MouseEvent FPointerEvent
local function CheckHoverOnAct(self, MouseEvent)
    local OldHoverCase = self.CurrentHoverCase
    self.CurrentHoverCase = nil
    local MouseAbsolutePos = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(MouseEvent)
    for i = 1, LEFT_COUNT + 1 + RIGHT_COUNT do
        if i ~= LEFT_COUNT + 1 then
            ---@type WBP_Task_CaseList
            local WBP_TaskCaseList = self[CARD_LIST_WIDGET_PREFIX..i]
            if WBP_TaskCaseList:IsVisible() then
                local ChildWidgetGeometry = WBP_TaskCaseList:GetCachedGeometry()
                local MouseLocalPos = UE.USlateBlueprintLibrary.AbsoluteToLocal(ChildWidgetGeometry, MouseAbsolutePos)
                local ChildWidgetLocalSize = UE.USlateBlueprintLibrary.GetLocalSize(ChildWidgetGeometry)
                if ChildWidgetLocalSize.X > 0 and ChildWidgetLocalSize.Y > 0 and MouseLocalPos.X > 0 and MouseLocalPos.X < ChildWidgetLocalSize.X
                        and MouseLocalPos.Y > 0 and MouseLocalPos.Y < ChildWidgetLocalSize.Y then
                    self.CurrentHoverCase = WBP_TaskCaseList
                    break
                end
            end
        end
    end
    if OldHoverCase ~= self.CurrentHoverCase then
        if self.CurrentHoverCase then
            self.CurrentHoverCase.WBP_Btn_PhotoThumbnail:Button_OnHovered()
        end
        if OldHoverCase then
            OldHoverCase.WBP_Btn_PhotoThumbnail:Button_OnUnhovered()
        end
    end
end

---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
function WBP_Task_FirmHomePage:OnBorderMouseMove(MyGeometry, MouseEvent)
    if self.BorderDragPressDownTime and self.BorderDragPressDownTime ~= 0 then
        local MoveDelta = UE.UKismetInputLibrary.PointerEvent_GetCursorDelta(MouseEvent)
        self.DragDelta = self.DragDelta + MoveDelta.X
        local CurrentShowIndex = GetIndex(self, self.CurrentShowID)
        if CurrentShowIndex == 1 and self.DragDelta > self.DragLength then
            self:SetBounceBackFirmDetailOffset(self.DragDelta)
            self.bNeedBounceBack = true
        elseif CurrentShowIndex == #self.CurrentMissionActs and self.DragDelta < -self.DragLength then
            self:SetBounceBackFirmDetailOffset(self.DragDelta)
            self.bNeedBounceBack = true
        else
            if self.DragDelta > self.DragLength or self.DragDelta < -self.DragLength then
                self.BorderDragDownAndMove = true
                ChangeCurrentByDelta(self, self.DragDelta)
                BorderMouseUp(self)
            end
        end
    else
        if self.CurrentPlayingAnim == nil then
            CheckHoverOnAct(self, MouseEvent)
        end
    end
    return UE.UWidgetBlueprintLibrary.Handled()
end

function WBP_Task_FirmHomePage:OnConstruct()
    self.WBP_Common_TopContent.CommonButton_Close.OnClicked:Add(self, OnClickCloseButton)
    self.WBP_Btn_CaseWall.OnClicked:Add(self, OnClickCaseWall)
    --self.List_OfficialNews.BP_OnListViewScrolled:Add(self, OnListViewScrolled)
    self.BorderDrag.OnMouseButtonDownEvent:Bind(self, self.OnBorderMouseDown)
    self.BorderDrag.OnMouseButtonUpEvent:Bind(self, self.OnBorderMouseUp)
    self.BorderDrag.OnMouseMoveEvent:Bind(self, self.OnBorderMouseMove)

    self.Events = MissionActUtils.RandomEvent()
    ---@type TaskActVM
    local TaskActVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskActVM.UniqueName)
    TaskActVM:RegOnActStateChangeCallBack(self, OnActStateChanged)
    self.BorderDragPressDownTime = 0
end

function WBP_Task_FirmHomePage:OnDestruct()
    self.WBP_Common_TopContent.CommonButton_Close.OnClicked:Remove(self, OnClickCloseButton)
    self.WBP_Btn_CaseWall.OnClicked:Remove(self, OnClickCaseWall)
    --self.List_OfficialNews.BP_OnListViewScrolled:Remove(self, OnListViewScrolled)
    self.BorderDrag.OnMouseButtonDownEvent:Unbind()
    self.BorderDrag.OnMouseButtonUpEvent:Unbind()
    self.BorderDrag.OnMouseMoveEvent:Unbind()
    ---@type TaskActVM
    local TaskActVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskActVM.UniqueName)
    TaskActVM:UnRegOnActStateChangeCallBack(self, OnActStateChanged)
end

---@param self WBP_Task_FirmHomePage
---@param WidgetIndex integer
---@param DataIndex integer
---@param CaseListWidgetPrefix string
---@param Visibility ESlateVisibility
local function ShowCaseByIndex(self, WidgetIndex, DataIndex, CaseListWidgetPrefix, Visibility)
    ---@type WBP_Task_CaseList
    local WBP_Task_CaseList = self[CaseListWidgetPrefix..WidgetIndex]
    if DataIndex > 0 and DataIndex <= #self.CurrentMissionActs then
        WBP_Task_CaseList:SetVisibility(Visibility)
        WBP_Task_CaseList:SetTaskActID(self.CurrentMissionActs[DataIndex].MissionActID)
        WBP_Task_CaseList:SetOwnerWidget(self)
    else
        WBP_Task_CaseList:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

---@param self WBP_Task_FirmHomePage
---@param AnimIndex integer
local function RefreshTargetList(self, AnimIndex)
    local ShowIndex = GetIndex(self, self.OldShowID)
    ---@type WBP_Task_FirmDetail
    local WBP_Task_FirmDetail = self.WBP_Task_FirmDetail_Target
    WBP_Task_FirmDetail:SetTaskActID(self.CurrentShowID)
    for i = 1, LEFT_COUNT + 1 + RIGHT_COUNT do
        local Index = ShowIndex - LEFT_COUNT + i - 1
        if AnimIndex <= LEFT_COUNT then
            Index = Index - AnimIndex
        else
            Index = Index + 1
        end
        ShowCaseByIndex(self, i, Index, TARGET_CARD_LIST_WIDGET_PREFIX, UE.ESlateVisibility.HitTestInvisible)
    end
end

---@param self WBP_Task_FirmHomePage
local function RefreshAndPlayAnim(self)
    local OldIndex = GetIndex(self, self.OldShowID)
    local NewIndex = GetIndex(self, self.CurrentShowID)

    local AnimIndex = LEFT_COUNT - (OldIndex - NewIndex) + 1

    RefreshTargetList(self, AnimIndex)
    self.Canvas_CaseList:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    self.Canvas_CaseTarget:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    ---@type UWidgetAnimation
    local Anim = self["DX_Case"..AnimIndex.."Pressed"]
    self:PlayAnimation(Anim, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    self.CurrentPlayingAnim = Anim
end

---@param self WBP_Task_FirmHomePage
local function OnlyRefreshUI(self)
    local ShowIndex = GetIndex(self, self.CurrentShowID)
    ---@type WBP_Task_FirmDetail
    local WBP_Task_FirmDetail = self.WBP_Task_FirmDetail
    WBP_Task_FirmDetail:SetTaskActID(self.CurrentShowID)
    for i = 1, LEFT_COUNT + 1 + RIGHT_COUNT do
        local Index = ShowIndex - LEFT_COUNT + i - 1
        ShowCaseByIndex(self, i, Index, CARD_LIST_WIDGET_PREFIX, UE.ESlateVisibility.HitTestInvisible)
        if i == LEFT_COUNT + 1 then
            self[CARD_LIST_WIDGET_PREFIX..i]:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        end
    end
end

---Called when an animation has either played all the way through or is stopped
---@param Animation UWidgetAnimation
---@return void
function WBP_Task_FirmHomePage:OnAnimationFinished(Animation)
    if Animation == self.DX_Case1Pressed or Animation == self.DX_Case2Pressed or Animation == self.DX_Case3Pressed or Animation == self.DX_Case5Pressed then
        self.CurrentPlayingAnim = nil
        OnlyRefreshUI(self)
        self:PlayAnimation(self.DX_CaseResume, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
        self.Canvas_CaseList:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Canvas_CaseTarget:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

---@param self WBP_Task_FirmHomePage
local function Refresh(self)
    if self.OldShowID == self.CurrentShowID then
        OnlyRefreshUI(self)
    else
        RefreshAndPlayAnim(self)
    end
end

---@param self WBP_Task_FirmHomePage
local function RefreshEvents(self)
    local Path = PathUtil.getFullPathString(self.TaskNewsObject)
    local NewsObjectClass = LoadObject(Path)
    local InListItems = UE.TArray(NewsObjectClass)
    for Index, Event in ipairs(self.Events) do
        ---@type BP_TaskOfficialNew_C
        local NewsObject = NewObject(NewsObjectClass)
        NewsObject.OwnerWidget = self
        NewsObject.Index = Index
        NewsObject.IconKey = Event.IconKey
        NewsObject.TitleKey = Event.TitleKey
        NewsObject.ContentKey = Event.ContentKey
        InListItems:Add(NewsObject)
    end
    self.OfficialNewsWidgets = {}
    self.List_OfficialNews:BP_SetListItems(InListItems)

    -----@param self WBP_Task_FirmHomePage
    --local SetShadow = function(self)
    --    OnListViewScrolled(self, self.List_OfficialNews:GetScrollOffset())
    --end
    --UE.UKismetSystemLibrary.K2_SetTimerForNextTickDelegate({ self, SetShadow })
end

function WBP_Task_FirmHomePage:RefreshMissions()
    ---@type TaskActVM
    local TaskActVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskActVM.UniqueName)
    self.CurrentMissionActs = TaskActVM:GetCurrentMainMissionActs()
    if #self.CurrentMissionActs == 0 then
        self.Canvas_CaseList:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.WBP_Task_FirmDetail:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Canvas_EmptyState:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.Canvas_CaseList:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.WBP_Task_FirmDetail:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Canvas_EmptyState:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.CurrentShowID = self.CurrentMissionActs[1].MissionActID
        self.OldShowID = self.CurrentShowID
        Refresh(self)
    end
end

function WBP_Task_FirmHomePage:OnShow()
    SetCurrencyType(self)
    self:RefreshMissions()
    RefreshEvents(self)
    self.MouseWheelTime = UE.UHiUtilsFunctionLibrary.GetNowTimestampMs()
    self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    self:PlayAnimation(self.DX_Loop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1, false)
    ---@type WBP_Common_Currency
    local WBP_Common_Currency = self.WBP_Common_Currency
    WBP_Common_Currency:PlayInAnim()
end

---@param MissionActID integer
function WBP_Task_FirmHomePage:OnClickMission(MissionActID)
    self.OldShowID = self.CurrentShowID
    self.CurrentShowID = MissionActID
    Refresh(self)
end

---@param Index integer
---@param Widget WBP_Task_OfficialNews_List
function WBP_Task_FirmHomePage:SetOfficialWidgets(Index, Widget)
    self.OfficialNewsWidgets[Index] = Widget
end

---Called when the mouse wheel is spun. This event is bubbled.
---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
---@return FEventReply
function WBP_Task_FirmHomePage:OnMouseWheel(MyGeometry, MouseEvent)
    -----List_OfficialNews这个控件上滚轮不触发任务幕列表滑动(废弃)
    --local MouseAbsolutePos = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(MouseEvent)
    --local ListGeometry = self.List_OfficialNews:GetCachedGeometry()
    --local MouseLocalPos = UE.USlateBlueprintLibrary.AbsoluteToLocal(ListGeometry, MouseAbsolutePos)
    --local ListLocalSize = UE.USlateBlueprintLibrary.GetLocalSize(ListGeometry)
    --if MouseLocalPos.X > 0 and MouseLocalPos.X < ListLocalSize.X
    --    and MouseLocalPos.Y > 0 and MouseLocalPos.Y < ListLocalSize.Y then
    --    return UE.UWidgetBlueprintLibrary.Handled()
    --end

    local now = UE.UHiUtilsFunctionLibrary.GetNowTimestampMs()
    if now - self.MouseWheelTime > MOUSE_WHEEL_INTERVAL then
        local Delta = UE.UKismetInputLibrary.PointerEvent_GetWheelDelta(MouseEvent)
        ChangeCurrentByDelta(self, Delta)
        self.MouseWheelTime = now
    end

    return UE.UWidgetBlueprintLibrary.Handled()
end

---The system will use this event to notify a widget that the cursor has left it. This event is NOT bubbled.
---@param MouseEvent FPointerEvent
---@return void
function WBP_Task_FirmHomePage:OnMouseLeave(MouseEvent)
    BorderMouseUp(self)
end

---Called when an animation is started.
---@param Animation UWidgetAnimation
---@return void
function WBP_Task_FirmHomePage:OnAnimationStarted(Animation)
    if Animation == self.DX_Out then
        local DisplayedNewsWidget = self.List_OfficialNews:GetDisplayedEntryWidgets()
        for i = 1, DisplayedNewsWidget:Length() do
            local NewsWidget = DisplayedNewsWidget:Get(i)
            NewsWidget:PlayAnimation(NewsWidget.DX_MsgOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
        end
        ---@type WBP_Common_Currency
        local WBP_Common_Currency = self.WBP_Common_Currency
        WBP_Common_Currency:PlayOutAnim()
    end
end

return WBP_Task_FirmHomePage
