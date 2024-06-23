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
local Json = require("rapidjson")
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local WidgetUtil = require("CP0032305_GH.Script.common.utils.widget_util")

---@class WBP_Task_CaseWall : WBP_Task_CaseWall_C
---@field CurrentFileData CaseEditorResult
---@field MissionActRecords FMissionActRecord[]
---@field MaxX float
---@field BorderBgPressDownTime integer
---@field BorderBgDownAndMove boolean
---@field ButtonDownPhotoOnWall WBP_Task_PhotoOnWall

---@type WBP_Task_CaseWall
local WBP_Task_CaseWall = Class(UIWindowBase)

local LINE_POS_PARAM = 6
local SIZE_BOX_PARAM = 34
local SIZE_SCREEN_PARAM = 1080
local SIZE_Y_COUNT = 3
local ADD_X = 500
local CLICK_INTERVAL_BUTTON = 200
local CLICK_INTERVAL_CANCEL = 500
local SHOW_NAV_PARAM = 2
local DRAG_SCALE = UE.FVector2D(0.95, 0.95)
local NORMAL_SCALE = UE.FVector2D(1, 1)
local FOCUS_X = 0.8
local FOCUS_Y = 0.5

---@param self WBP_CaseEditor
---@return CaseEditorResult
local function LoadFile(self)
    local Directory = UE.UKismetSystemLibrary.GetProjectContentDirectory()..MissionActUtils.MISSION_RELATE_PATH..MissionActUtils.DEFAULT_JSON_FILE
    local File = UE.UHiEdRuntime.LoadFileToString(Directory)
    if File:len() == 0 then
        return {}
    end
    return Json.decode(File)
end

---@param self WBP_Task_CaseWall
local function OnClickCloseButton(self)
    UIManager:CloseUI(self, true)
end

---@param self WBP_Task_CaseWall
local function RefreshDragPanelPosByCaseCanvasPos(self)
    ---@type UCanvasPanelSlot
    local Slot = self.CanvasPanelCase.Slot
    local Pos = Slot:GetPosition()

    ---@type UCanvasPanelSlot
    local ImageSlot = self.ImageTouchBox.Slot
    ImageSlot:SetPosition(UE.FVector2D(-Pos.X * SIZE_BOX_PARAM / SIZE_SCREEN_PARAM, -Pos.Y * SIZE_BOX_PARAM / SIZE_SCREEN_PARAM))
end

---@param self WBP_Task_CaseWall
local function RefreshCaseCanvasPosByDragPanelPos(self)
    ---@type UCanvasPanelSlot
    local Slot = self.ImageTouchBox.Slot
    local Pos = Slot:GetPosition()

    ---@type UCanvasPanelSlot
    local CanvasSlot = self.CanvasPanelCase.Slot
    CanvasSlot:SetPosition(UE.FVector2D(-Pos.X * SIZE_SCREEN_PARAM / SIZE_BOX_PARAM, -Pos.Y * SIZE_SCREEN_PARAM / SIZE_BOX_PARAM))
end

---@param self WBP_Task_CaseWall
local function OnClickNavButton(self)
    self.Switch_Navigation:SetActiveWidgetIndex(1)
    RefreshDragPanelPosByCaseCanvasPos(self)
end

---@param self WBP_Task_CaseWall
local function CancelDrag(self)
    self.Switch_Navigation:SetActiveWidgetIndex(0)
end

---@param self WBP_Task_CaseWall
---@param ID integer
---@param bIsBoard boolean
---@return CasePosData
local function GetPos(self, ID, bIsBoard)
    local AllPos = self.CurrentFileData.AllCasePos
    if bIsBoard then
        AllPos = self.CurrentFileData.AllBoardPos
    end
    if AllPos == nil then
        return false
    end
    for _, v in ipairs(AllPos) do
        if ID == v.ID then
            return v
        end
    end
    return nil
end

---@param self WBP_Task_CaseWall
---@param Pos FVector2D
---@param CardWidget WBP_Task_PhotoOnWall
local function CreateThumbtack(self, Pos, CardWidget)
    ---@type WBP_Task_Thumbtack_C
    local ThumbtackWidget = WidgetUtil.CreateWidget(self, self.ThumbtackClass)
    self.CanvasPanelCase:AddChild(ThumbtackWidget)
    ---@type UCanvasPanelSlot
    local ThumbtackSlot = ThumbtackWidget.Slot
    ThumbtackSlot:SetPosition(Pos)
    ThumbtackWidget.Img_Thumbtack01:SetRenderTransformAngle(CardWidget.WBP_Task_Photo:GetRenderTransformAngle())
end

---@param self WBP_Task_CaseWall
---@param CardWidget WBP_Task_PhotoOnWall
---@param NextWidget WBP_Task_PhotoOnWall
local function DrawLine(self, CardWidget, NextWidget)
    ---@type UCanvasPanelSlot
    local Slot1 = CardWidget.Slot
    local Position1 = Slot1:GetPosition()
    ---@type UCanvasPanelSlot
    local Slot2 = NextWidget.Slot
    local Position2 = Slot2:GetPosition()

    ---@type WBP_Task_CaseWall_RedLine
    local RedLineWidget = WidgetUtil.CreateWidget(self, self.RedLineClass)
    self.CanvasPanelCase:AddChild(RedLineWidget)

    local ThumbtackSlotCenterPos = CardWidget:GetThumbtackSlotCenterPos()
    local ThumbtackLocalPos = UE.FVector2D(Position1.X + ThumbtackSlotCenterPos.X, Position1.Y + ThumbtackSlotCenterPos.Y)

    local NextThumbtackSlotCenterPos = NextWidget:GetThumbtackSlotCenterPos()
    local NextThumbtackLocalPos = UE.FVector2D(Position2.X + NextThumbtackSlotCenterPos.X, Position2.Y + NextThumbtackSlotCenterPos.Y)

    local DeltaY = NextThumbtackLocalPos.Y - ThumbtackLocalPos.Y
    local DeltaX = NextThumbtackLocalPos.X - ThumbtackLocalPos.X
    local angle = math.atan(DeltaY, DeltaX)
    local Length = math.sqrt(DeltaY* DeltaY + DeltaX * DeltaX)
    RedLineWidget:SetParam(angle, Length)

    ---@type UCanvasPanelSlot
    local Slot = RedLineWidget.Slot
    local Pos = UE.FVector2D(ThumbtackLocalPos.X + LINE_POS_PARAM, ThumbtackLocalPos.Y)
    Slot:SetPosition(Pos)
    Slot:SetAutoSize(true)

    CreateThumbtack(self, ThumbtackLocalPos, CardWidget)
    CreateThumbtack(self, NextThumbtackLocalPos, NextWidget)
end

local function ClearLines(self)
    local ChildrenWidgets = self.CanvasPanelCase:GetAllChildren()
    for i = 1, ChildrenWidgets:Length() do
        ---@type WBP_Task_CaseWall_RedLine
        local ChildWidget = ChildrenWidgets:GetRef(i)
        if ChildWidget.bRedLine or ChildWidget.bIsThumbtack then
            ChildWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
            ChildWidget:RemoveFromParent()
        end
    end
end

---@param self WBP_Task_CaseWall
local function RefreshLine(self)
    local ChildrenWidgets = self.CanvasPanelCase:GetAllChildren()
    if ChildrenWidgets:Length() > 0 then
        if self.RefreshLineWidgetIndex == nil then
            self.RefreshLineWidgetIndex = 1
        end
        local ChildWidget = ChildrenWidgets:GetRef(self.RefreshLineWidgetIndex)
        local bDraw = false
        if ChildWidget.bIsCaseCardOnWall then
            local MissionActID = ChildWidget.ID
            local NextMissionActIDs = MissionActUtils.GetNextActIDs(MissionActID)
            if NextMissionActIDs and #NextMissionActIDs > 0 then
                for _, NextMissionActID in ipairs(NextMissionActIDs) do
                    local NextWidget = nil
                    for j = 1, ChildrenWidgets:Length() do
                        local tempWidget = ChildrenWidgets:GetRef(j)
                        if tempWidget.bIsCaseCardOnWall and tempWidget.ID == NextMissionActID then
                            NextWidget = tempWidget
                            break
                        end
                    end
                    if NextWidget then
                        ---@type UCanvasPanelSlot
                        local Slot1 = ChildWidget.Slot
                        ---@type UCanvasPanelSlot
                        local Slot2 = NextWidget.Slot
                        if Slot1:GetPosition().X <= Slot2:GetPosition().X then
                            DrawLine(self, ChildWidget, NextWidget)
                        else
                            DrawLine(self, NextWidget, ChildWidget)
                        end
                        bDraw = true
                    end
                end
            end
        end
        self.RefreshLineWidgetIndex = self.RefreshLineWidgetIndex + 1
        if self.RefreshLineWidgetIndex > ChildrenWidgets:Length() then
            self.RefreshLineWidgetIndex = nil
            return
        end
        if not bDraw then
            RefreshLine(self)
        else
            local CallBack = function()
                RefreshLine(self)
            end
            UE.UKismetSystemLibrary.K2_SetTimerForNextTickDelegate({self, CallBack})
        end
    end
end

---@param self WBP_Task_CaseWall
local function StartRefreshLines(self)
    ClearLines(self)
    RefreshLine(self)
end

---@param self WBP_Task_CaseWall
local function RefreshChapters(self)
    for ID, _ in pairs(self.LabelIDs) do
        local CasePosData = GetPos(self, ID, true)
        ---@type WBP_Task_ChapterOnWall
        local ChapterOnWallWidget = WidgetUtil.CreateWidget(self, self.ChapterClass)
        self.CanvasPanelCase:AddChild(ChapterOnWallWidget)
        ---@type UCanvasPanelSlot
        local Slot = ChapterOnWallWidget.Slot
        Slot:SetPosition(UE.FVector2D(CasePosData.PositionX, CasePosData.PositionY))
        Slot:SetAutoSize(true)
        ---@type WBP_Task_Chapter
        local WBP_Task_Chapter = ChapterOnWallWidget.WBP_Task_Chapter
        WBP_Task_Chapter:SetRenderTransformAngle(CasePosData.Rotation)
        WBP_Task_Chapter:SetID(ID)
        if self.MaxX == nil or self.MaxX < CasePosData.PositionX then
            self.MaxX = CasePosData.PositionX
        end
    end
end

---@param self WBP_Task_CaseWall
local function RefreshCanvasSize(self)
    ---@type UCanvasPanelSlot
    local CanvasSlot = self.CanvasPanelCase.Slot
    local Size = CanvasSlot:GetSize()
    CanvasSlot:SetSize(UE.FVector2D(self.MaxX, Size.Y))
end

---@param self WBP_Task_CaseWall
local function PlayChildWidgetAnim(self, AnimName)
    local ChildrenWidgets = self.CanvasPanelCase:GetAllChildren()
    for i = 1, ChildrenWidgets:Length() do
        local ChildWidget = ChildrenWidgets:GetRef(i)
        if ChildWidget.IsChapterOnWall then
            if ChildWidget.WBP_Task_Chapter[AnimName] then
                ChildWidget.WBP_Task_Chapter:PlayAnimation(ChildWidget.WBP_Task_Chapter[AnimName], 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
            end
        end
        if ChildWidget.bIsCaseCardOnWall then
            if ChildWidget.WBP_Task_Photo[AnimName] then
                ChildWidget.WBP_Task_Photo:PlayAnimation(ChildWidget.WBP_Task_Photo[AnimName], 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
            end
        end
    end
end

---@param self WBP_Task_CaseWall
local function FocusLastReceiveRewardMissionAct(self)
    ---@type TaskActVM
    local TaskActVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskActVM.UniqueName)
    local LastReceiveRewardMissionActID = TaskActVM:GetLastReceiveRewardMissionActID()
    if LastReceiveRewardMissionActID and LastReceiveRewardMissionActID > 0 then
        local Pos = GetPos(self, LastReceiveRewardMissionActID, false)
        local ChildrenWidgets = self.CanvasPanelCase:GetAllChildren()
        local CardSize = nil
        for i = 1, ChildrenWidgets:Length() do
            ---@type WBP_Task_PhotoOnWall
            local ChildWidget = ChildrenWidgets:GetRef(i)
            if ChildWidget.bIsCaseCardOnWall then
                CardSize = UE.USlateBlueprintLibrary.GetLocalSize(ChildWidget.WBP_Task_Photo:GetCachedGeometry())

                break
            end
        end
        local FocusLocalPos = UE.FVector2D(Pos.PositionX + CardSize.X / 2, Pos.PositionY - SIZE_SCREEN_PARAM)

        local ViewportSize = UE.UWidgetLayoutLibrary.GetViewportSize(self)
        local ViewportScale = UE.UWidgetLayoutLibrary.GetViewportScale(self)
        local ScreenSize = UE.FVector2D(ViewportSize.X / ViewportScale, ViewportSize.Y / ViewportScale)
        local FocusPos = UE.FVector2D(ScreenSize.X * FOCUS_X, ScreenSize.Y * FOCUS_Y)

        local DeltaPos = UE.FVector2D(FocusPos.X - FocusLocalPos.X, FocusPos.Y - FocusLocalPos.Y)
        ---@type UCanvasPanelSlot
        local CanvasSlot = self.CanvasPanelCase.Slot
        CanvasSlot:SetPosition(DeltaPos)
    end
end

---@param self WBP_Task_CaseWall
local function InitTouchPanel(self)
    local ViewportSize = UE.UWidgetLayoutLibrary.GetViewportSize(self)
    local ViewportScale = UE.UWidgetLayoutLibrary.GetViewportScale(self)
    local ScreenSize = UE.FVector2D(ViewportSize.X / ViewportScale, ViewportSize.Y / ViewportScale)
    local BoxX = SIZE_BOX_PARAM * ScreenSize.X / ScreenSize.Y
    ---@type UCanvasPanelSlot
    local TouchBoxSlot = self.ImageTouchBox.Slot
    TouchBoxSlot:SetSize(UE.FVector2D(BoxX, SIZE_BOX_PARAM))

    ---@type UCanvasPanelSlot
    local TouchBgSlot = self.Img_NavigationBG_Expand.Slot

    if self.MaxX + ADD_X < ScreenSize.X * SHOW_NAV_PARAM then
        self.Switch_Navigation:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.Switch_Navigation:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        local MaxPosX = (self.MaxX + ADD_X) * SIZE_BOX_PARAM / SIZE_SCREEN_PARAM
        TouchBgSlot:SetSize(UE.FVector2D(MaxPosX, SIZE_BOX_PARAM * SIZE_Y_COUNT))
    end
end

local function RefreshPhotosFinish(self)
    RefreshChapters(self)
    RefreshCanvasSize(self)
    PlayChildWidgetAnim(self, "DX_In")

    local CallBack = function()
        StartRefreshLines(self)
        FocusLastReceiveRewardMissionAct(self)
        InitTouchPanel(self)
        self.CanvasPanelCase.Slot:SetPosition(UE.FVector2D(0.0))
    end
    UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, CallBack}, 0.1, false)
end

local function RefreshPhoto(self)
    local MissionActRecord = self.MissionActRecords[self.RefreshIndex]
    local MissionActID = MissionActRecord.MissionActID
    local CasePosData = GetPos(self, MissionActID, false)
    local MissionActConfig = MissionActUtils.GetMissionActConfig(MissionActID)
    if MissionActConfig == nil then
        G.log:warn("WBP_Task_CaseWall", "RefreshPhotos failed! Invalid act ID: %d", ID)
        return
    end
    local MissionBoard_Label = MissionActConfig.MissionBoard_Label
    if MissionBoard_Label and MissionBoard_Label > 0 then
        self.LabelIDs[MissionBoard_Label] = true
    end
    ---@type WBP_Task_PhotoOnWall
    local PhotoOnWallWidget = WidgetUtil.CreateWidget(self, self.PhotoClass)
    PhotoOnWallWidget:SetData(self, MissionActID, MissionActRecord.State)
    self.CanvasPanelCase:AddChild(PhotoOnWallWidget)
    ---@type UCanvasPanelSlot
    local Slot = PhotoOnWallWidget.Slot
    Slot:SetPosition(UE.FVector2D(CasePosData.PositionX, CasePosData.PositionY))
    Slot:SetAutoSize(true)
    ---@type WBP_Task_Photo
    local WBP_Task_Photo = PhotoOnWallWidget.WBP_Task_Photo
    WBP_Task_Photo:SetRenderTransformAngle(CasePosData.Rotation)
    WBP_Task_Photo:SetMissionActID(MissionActID)
    if self.MaxX == nil or self.MaxX < CasePosData.PositionX then
        self.MaxX = CasePosData.PositionX
    end
end

---@param self WBP_Task_CaseWall
local function RefreshPhotos(self)
    if self.RefreshIndex == nil then
        self.RefreshIndex = 1
    end
    if #self.MissionActRecords > 0 then
        RefreshPhoto(self)
        self.RefreshIndex = self.RefreshIndex + 1
    end

    if self.RefreshIndex > #self.MissionActRecords then
        self.RefreshIndex = nil
        RefreshPhotosFinish(self)
        return
    end
    local CallBack = function()
        RefreshPhotos(self)
    end
    UE.UKismetSystemLibrary.K2_SetTimerForNextTickDelegate({self, CallBack})
end

local function StartLoadCase(self)
    RefreshPhotos(self)
end

function WBP_Task_CaseWall:OnShow()
    self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    self:PlayAnimation(self.DX_Loop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1, false)
    self.MaxX = 0
    ---@type TaskActVM
    local TaskActVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskActVM.UniqueName)
    self.MissionActRecords = TaskActVM:GetCaseWallMissionActs()
    self.LabelIDs = {}
    StartLoadCase(self)
end


---Called when an animation is started.
---@param Animation UWidgetAnimation
---@return void
function WBP_Task_CaseWall:OnAnimationStarted(Animation)
    if Animation == self.DX_Out then
        PlayChildWidgetAnim(self, "DX_Out")
    end
end

---@param self WBP_Task_CaseWall
---@param MouseEvent FPointerEvent
local function CheckPressDownOnCard(self, MouseEvent)
    local MouseAbsolutePos = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(MouseEvent)
    local ChildrenWidgets = self.CanvasPanelCase:GetAllChildren()
    for i = 1, ChildrenWidgets:Length() do
        ---@type WBP_Task_PhotoOnWall
        local ChildWidget = ChildrenWidgets:GetRef(i)
        if ChildWidget.bIsCaseCardOnWall then
            local ChildWidgetGeometry = ChildWidget:GetCachedGeometry()
            local MouseLocalPos = UE.USlateBlueprintLibrary.AbsoluteToLocal(ChildWidgetGeometry, MouseAbsolutePos)
            local ChildWidgetLocalSize = UE.USlateBlueprintLibrary.GetLocalSize(ChildWidgetGeometry)
            if ChildWidgetLocalSize.X > 0 and ChildWidgetLocalSize.Y > 0 and MouseLocalPos.X > 0 and MouseLocalPos.X < ChildWidgetLocalSize.X
                    and MouseLocalPos.Y > 0 and MouseLocalPos.Y < ChildWidgetLocalSize.Y then
                self.ButtonDownPhotoOnWall = ChildWidget
                ChildWidget:OnButtonDown()
                break
            end
        end
    end
end

---@param self WBP_Task_CaseWall
---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
---@return FEventReply
local function OnBorderBgMouseDown(self, MyGeometry, MouseEvent)
    self.BorderBgPressDownTime = UE.UHiUtilsFunctionLibrary.GetNowTimestampMs()
    self.BorderBgDownAndMove = false
    CheckPressDownOnCard(self, MouseEvent)
    return UE.UWidgetBlueprintLibrary.Handled()
end

---@param self WBP_Task_CaseWall
---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
---@return FEventReply
local function OnBorderBgMouseUp(self, MyGeometry, MouseEvent)
    local now = UE.UHiUtilsFunctionLibrary.GetNowTimestampMs()
    if self.BorderBgPressDownTime and now - self.BorderBgPressDownTime < CLICK_INTERVAL_BUTTON and not self.BorderBgDownAndMove then
        if self.ButtonDownPhotoOnWall then
            self.ButtonDownPhotoOnWall:OnButtonUp(true)
            self.ButtonDownPhotoOnWall = nil
        end
    else
        if self.ButtonDownPhotoOnWall then
            self.ButtonDownPhotoOnWall:OnButtonUp(false)
            self.ButtonDownPhotoOnWall = nil
        end
    end
    if self.BorderBgPressDownTime and now - self.BorderBgPressDownTime < CLICK_INTERVAL_CANCEL and not self.BorderBgDownAndMove then
        CancelDrag(self)
    end
    self.BorderBgPressDownTime = nil
    self.BorderBgDownAndMove = false
    return UE.UWidgetBlueprintLibrary.Handled()
end

---@param self WBP_Task_CaseWall
---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
---@return FEventReply
local function OnBorderBgMove(self, MyGeometry, MouseEvent)
    if self.BorderBgPressDownTime then
        local MoveDelta = UE.UKismetInputLibrary.PointerEvent_GetCursorDelta(MouseEvent)
        if math.floor(math.abs(MoveDelta.X)) > 0 or math.floor(math.abs(MoveDelta.Y)) > 0 then
            self.BorderBgDownAndMove = true
        end
        ---@type UCanvasPanelSlot
        local Slot = self.CanvasPanelCase.Slot
        local Position = Slot:GetPosition()
        local ViewportSize = UE.UWidgetLayoutLibrary.GetViewportSize(self)
        local ViewportScale = UE.UWidgetLayoutLibrary.GetViewportScale(self)
        local ScreenSize = UE.FVector2D(ViewportSize.X / ViewportScale, ViewportSize.Y / ViewportScale)
        local X = math.min(0, math.max(-(self.MaxX + ADD_X) + ScreenSize.X, Position.X + MoveDelta.X))
        local Y = math.min(SIZE_SCREEN_PARAM, math.max(-SIZE_SCREEN_PARAM, Position.Y + MoveDelta.Y))
        Slot:SetPosition(UE.FVector2D(X, Y))
        --StartRefreshLines(self)
        if self.Switch_Navigation:IsVisible() then
            RefreshDragPanelPosByCaseCanvasPos(self)
        end
    end
    if self.BorderDragPress then
        self.BorderDragPress = false
    end
    self.ImageTouchBox:SetRenderScale(NORMAL_SCALE)
    return UE.UWidgetBlueprintLibrary.Handled()
end


---@param self WBP_Task_CaseWall
---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
---@return FEventReply
local function OnBorderDragMouseDown(self, MyGeometry, MouseEvent)
    local AbsolutePos = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(MouseEvent)
    local ImageGeometry = self.ImageTouchBox:GetCachedGeometry()
    local LocalPos = UE.USlateBlueprintLibrary.AbsoluteToLocal(ImageGeometry, AbsolutePos)
    ---@type UCanvasPanelSlot
    local Slot = self.ImageTouchBox.Slot
    local Size = Slot:GetSize()
    if LocalPos.X > 0 and LocalPos.X < Size.X and LocalPos.Y > 0 and LocalPos.Y < Size.Y then
        self.BorderDragPress = true
    end
    return UE.UWidgetBlueprintLibrary.Handled()
end

---@param self WBP_Task_CaseWall
---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
---@return FEventReply
local function OnBorderDragMouseUp(self, MyGeometry, MouseEvent)
    self.BorderDragPress = false
    return UE.UWidgetBlueprintLibrary.Handled()
end

---@param self WBP_Task_CaseWall
---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
---@return FEventReply
local function OnBorderDragMove(self, MyGeometry, MouseEvent)
    local AbsolutePos = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(MouseEvent)
    local ImageGeometry = self.ImageTouchBox:GetCachedGeometry()
    local LocalPos = UE.USlateBlueprintLibrary.AbsoluteToLocal(ImageGeometry, AbsolutePos)
    ---@type UCanvasPanelSlot
    local Slot = self.ImageTouchBox.Slot
    local Size = Slot:GetSize()
    if LocalPos.X > 0 and LocalPos.X < Size.X and LocalPos.Y > 0 and LocalPos.Y < Size.Y then
        self.ImageTouchBox:SetRenderScale(DRAG_SCALE)
    else
        self.ImageTouchBox:SetRenderScale(NORMAL_SCALE)
    end
    if self.BorderDragPress then
        local MoveDelta = UE.UKismetInputLibrary.PointerEvent_GetCursorDelta(MouseEvent)
        ---@type UCanvasPanelSlot
        local Slot = self.ImageTouchBox.Slot
        local Position = Slot:GetPosition()
        local Size = Slot:GetSize()

        ---@type UCanvasPanelSlot
        local BgSlot = self.Img_NavigationBG_Expand.Slot
        local BgSize = BgSlot:GetSize()

        local X = math.min(BgSize.X - Size.X, math.max(0, Position.X + MoveDelta.X))
        local Y = math.min(Size.Y, math.max(-Size.Y, Position.Y + MoveDelta.Y))
        Slot:SetPosition(UE.FVector2D(X, Y))

        RefreshCaseCanvasPosByDragPanelPos(self)
        --StartRefreshLines(self)
    end
    return UE.UWidgetBlueprintLibrary.Handled()
end

function WBP_Task_CaseWall:OnConstruct()
    self.WBP_Common_TopContent.CommonButton_Close.OnClicked:Add(self, OnClickCloseButton)
    self.WBP_Btn_Navigation_Normal.OnClicked:Add(self, OnClickNavButton)
    self.BorderBg.OnMouseButtonDownEvent:Bind(self, OnBorderBgMouseDown)
    self.BorderBg.OnMouseButtonUpEvent:Bind(self, OnBorderBgMouseUp)
    self.BorderBg.OnMouseMoveEvent:Bind(self, OnBorderBgMove)
    self.BorderDrag.OnMouseButtonDownEvent:Bind(self, OnBorderDragMouseDown)
    self.BorderDrag.OnMouseButtonUpEvent:Bind(self, OnBorderDragMouseUp)
    self.BorderDrag.OnMouseMoveEvent:Bind(self, OnBorderDragMove)
    self.CurrentFileData = LoadFile(self)
end

function WBP_Task_CaseWall:OnDestruct()
    self.WBP_Common_TopContent.CommonButton_Close.OnClicked:Remove(self, OnClickCloseButton)
    self.WBP_Btn_Navigation_Normal.OnClicked:Remove(self, OnClickNavButton)
    self.BorderBg.OnMouseButtonDownEvent:Unbind()
    self.BorderBg.OnMouseButtonUpEvent:Unbind()
    self.BorderBg.OnMouseMoveEvent:Unbind()
    self.BorderDrag.OnMouseButtonDownEvent:Unbind()
    self.BorderDrag.OnMouseButtonUpEvent:Unbind()
    self.BorderDrag.OnMouseMoveEvent:Unbind()
end

function WBP_Task_CaseWall:OnClickCasePhoto()
    CancelDrag(self)
end

---The system will use this event to notify a widget that the cursor has left it. This event is NOT bubbled.
---@param MouseEvent FPointerEvent
---@return void
function WBP_Task_CaseWall:OnMouseLeave(MouseEvent)
    self.BorderDragPress = false
    OnBorderBgMouseUp(self, self:GetCachedGeometry(), MouseEvent)
end

return WBP_Task_CaseWall
