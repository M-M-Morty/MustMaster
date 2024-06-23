--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
---@class WBP_CaseEditor : WBP_CaseEditor_C
---@field OptionFiles string[]
---@field CurrentOption string
---@field CurrentFileData CaseEditorResult
---@field AllCaseDatas CaseDatas
---@field DragListItem WBP_CaseCard
---@field DragCollapsedItem WBP_CaseCardOnWall
---@field CurrentChooseCaseWidget WBP_CaseCardOnWall
---@field bDragging boolean
---@field CurrentChooseTitleWidget WBP_CaseTitleOnWall
---@field DragListTitleItem WBP_CaseTitle
---@field DragCollapsedTitleItem WBP_CaseTitleOnWall
---@field bDraggingAll boolean
---@field Owner BP_CaseEditorBox_C

---@type WBP_CaseEditor
local WBP_CaseEditor = UnLua.Class()

local G = require("G")
local PathUtil = require("CP0032305_GH.Script.common.utils.path_util")
local WidgetUtil = require("CP0032305_GH.Script.common.utils.widget_util")
local MissionActUtils = require("CP0032305_GH.Script.mission.mission_act_utils")
local Json = require("rapidjson")

local BIG_Z_ORDER = 10
local BIGGER_Z_ORDER = 11
local LINE_POS_PARAM = 6
local SIZE_SCREEN_PARAM = 1080

local function GetMissionRelateRootPath()
    return UE.UKismetSystemLibrary.GetProjectContentDirectory() .. MissionActUtils.MISSION_RELATE_PATH
end

---@param self WBP_CaseEditor
---@return CaseEditorResult
local function LoadFile(self)
    if self.CurrentOption == nil then
        return
    end
    local Directory = GetMissionRelateRootPath()
    local File = UE.UHiEdRuntime.LoadFileToString(Directory.. self.CurrentOption)
    if File:len() == 0 then
        return {}
    end
    return Json.decode(File)
end

---@param FilePath string
---@param Content string
local function SaveStringToFile(FilePath, Content)
    local File = UE.File()
    if not File:Open(FilePath, "w+") then
        G.log:warn("WBP_CaseEditor", "SaveStringToFile err %s", FilePath)
    end
    File:Write(Content)
    File:Close()
end

---@param self WBP_CaseEditor
local function SaveFile(self)
    if self.CurrentOption == nil then
        return
    end
    local Directory = GetMissionRelateRootPath()
    local FilePath = Directory..self.CurrentOption
    local FileString = Json.encode(self.CurrentFileData, {pretty = true})
    SaveStringToFile(FilePath, FileString)
end

---@param self WBP_CaseEditor
local function OnClickCloseButton(self)
    self.Owner.WBPCaseEditor = nil
    self:RemoveFromParent()
end

---@param self WBP_CaseEditor
local function OnClickConfirm(self)
    SaveFile(self)
end

---@param self WBP_CaseEditor
local function OnClickReset(self)
    ---@type UCanvasPanelSlot
    local Slot = self.CanvasPanelCase.Slot
    Slot:SetPosition(UE.FVector2D(0, 0))
end

---@param self WBP_CaseEditor
local function OnClickCreate(self)
    local Path = PathUtil.getFullPathString(self.CreateFileWidgetClass)
    local WBPClass = LoadObject(Path)
    local CreateFileWidget = NewObject(WBPClass, self)
    CreateFileWidget:AddToViewport(100)
    CreateFileWidget:SetCaseEditorWidget(self)
end

---@param self WBP_CaseEditor
---@param Item string
---@return UWidget
local function OnGenerateItemWidget(self, Item)
    local Path = PathUtil.getFullPathString(self.CaseSelectFileClass)
    local WBPClass = LoadObject(Path)
    ---@type WBP_CaseSelectFile_C
    local WBP_CaseSelectFile = NewObject(WBPClass, self)

    local CallBack = function()
        WBP_CaseSelectFile.TextFileName:SetText(Item)
    end
    UE.UKismetSystemLibrary.K2_SetTimerForNextTickDelegate({ self, CallBack })
    return WBP_CaseSelectFile
end

---@param self WBP_CaseEditor
---@param ID integer
---@param bIsBoard boolean
local function CaseHasPos(self, ID, bIsBoard)
    local AllPos = self.CurrentFileData.AllCasePos
    if bIsBoard then
        AllPos = self.CurrentFileData.AllBoardPos
    end
    if AllPos == nil then
        return false
    end
    for _, v in ipairs(AllPos) do
        if ID == v.ID then
            return true
        end
    end
    return false
end

---@param self WBP_CaseEditor
---@param ID integer
---@param bIsBoard boolean
local function RemoveCasePos(self, ID, bIsBoard)
    local AllPos = self.CurrentFileData.AllCasePos
    if bIsBoard then
        AllPos = self.CurrentFileData.AllBoardPos
    end
    if AllPos == nil then
        return
    end
    local FindIndex = nil
    for Index, v in ipairs(AllPos) do
        if ID == v.ID then
            FindIndex = Index
            break
        end
    end
    if FindIndex then
        if bIsBoard then
            table.remove(self.CurrentFileData.AllBoardPos, FindIndex)
        else
            table.remove(self.CurrentFileData.AllCasePos, FindIndex)
        end
    end
    return
end

---@param self WBP_CaseEditor
---@param CaseID integer
---@param X float
---@param Y float
---@param Rotation float
---@param bIsBoard boolean
local function EditCasePos(self, CaseID, X, Y, Rotation, bIsBoard)
    local AllPos = nil
    if bIsBoard then
        if self.CurrentFileData.AllBoardPos == nil then
            self.CurrentFileData.AllBoardPos = {}
        end
        AllPos = self.CurrentFileData.AllBoardPos
    else
        if self.CurrentFileData.AllCasePos == nil then
            self.CurrentFileData.AllCasePos = {}
        end
        AllPos = self.CurrentFileData.AllCasePos
    end

    ---@type CasePosData
    local Data = {}
    Data.ID = CaseID
    local FoundIndex = #AllPos + 1
    for i, v in ipairs(AllPos) do
        if CaseID == v.ID then
            Data = v
            FoundIndex = i
            break
        end
    end
    if X ~= nil then
        Data.PositionX = X
    end
    if Y ~= nil then
        Data.PositionY = Y
    end
    if Rotation ~= nil then
        Data.Rotation = Rotation
    end
    if bIsBoard then
        self.CurrentFileData.AllBoardPos[FoundIndex] = Data
    else
        self.CurrentFileData.AllCasePos[FoundIndex] = Data
    end
end

---@param self WBP_CaseEditor
---@param Pos FVector2D
---@param CardWidget WBP_CaseCardOnWall
local function CreateThumbtack(self, Pos, CardWidget)
    ---@type WBP_Task_Thumbtack_C
    local ThumbtackWidget = WidgetUtil.CreateWidget(self, self.ThumbtackClass)
    self.CanvasPanelCase:AddChild(ThumbtackWidget)
    ---@type UCanvasPanelSlot
    local ThumbtackSlot = ThumbtackWidget.Slot
    ThumbtackSlot:SetPosition(Pos)
    ThumbtackWidget.Img_Thumbtack01:SetRenderTransformAngle(CardWidget.WBP_Task_Photo:GetRenderTransformAngle())
end

---@param self WBP_CaseEditor
---@param CardWidget WBP_CaseCardOnWall
---@param NextWidget WBP_CaseCardOnWall
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

---@param self WBP_CaseEditor
local function ClearAll(self)
    local ChildrenWidgets = self.CanvasPanelCase:GetAllChildren()
    for i = 1, ChildrenWidgets:Length() do
        local ChildWidget = ChildrenWidgets:GetRef(i)
        if ChildWidget.bIsCaseCardOnWall or ChildWidget.bIsCaseTitleOnWall or ChildWidget.bRedLine or ChildWidget.bIsThumbtack then
            ChildWidget:RemoveFromParent()
        end
    end
end

---@param self WBP_CaseEditor
local function RefreshLines(self)
    local ChildrenWidgets = self.CanvasPanelCase:GetAllChildren()
    for i = 1, ChildrenWidgets:Length() do
        ---@type WBP_Task_CaseWall_RedLine
        local ChildWidget = ChildrenWidgets:GetRef(i)
        if ChildWidget.bRedLine or ChildWidget.bIsThumbtack then
            ChildWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
            ChildWidget:RemoveFromParent()
        end
    end
    ChildrenWidgets = self.CanvasPanelCase:GetAllChildren()
    for i = 1, ChildrenWidgets:Length() do
        local ChildWidget = ChildrenWidgets:GetRef(i)
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
                    end
                end
            end
        end
    end
end

---@param self WBP_CaseEditor
local function RefreshBottomDatas(self)
    local CaseItemPath = PathUtil.getFullPathString(self.CaseItemClass)
    local CaseItemClass = LoadObject(CaseItemPath)
    local CaseInListItems = UE.TArray(CaseItemClass)
    for _, Case in ipairs(self.AllCaseDatas.Cases) do
        if not CaseHasPos(self, Case.ID) then
            ---@type BP_CaseEditorCaseItem_C
            local CaseItemObject = NewObject(CaseItemClass)
            CaseItemObject.OwnerWidget = self
            CaseItemObject.ID = Case.ID
            if Case.BeforeMission then
                for _, v in ipairs(Case.BeforeMission) do
                    CaseItemObject.BeforeMission:Add(v)
                end
            end
            if Case.NextMission then
                for _, v in ipairs(Case.NextMission) do
                    CaseItemObject.NextMission:Add(v)
                end
            end
            CaseInListItems:Add(CaseItemObject)
        end
    end
    self.ListCase:BP_SetListItems(CaseInListItems)

    local BoardItemPath = PathUtil.getFullPathString(self.BoardItemClass)
    local BoardItemClass = LoadObject(BoardItemPath)
    local BoardInListItems = UE.TArray(BoardItemClass)
    for _, Board in ipairs(self.AllCaseDatas.Boards) do
        if not CaseHasPos(self, Board.ID, true) then
            ---@type BP_CaseEditorBoardItem_C
            local BoardItemObject = NewObject(BoardItemClass)
            BoardItemObject.ID = Board.ID
            BoardItemObject.Name = Board.Name
            BoardItemObject.Content = Board.Content
            BoardItemObject.OwnerWidget = self
            BoardInListItems:Add(BoardItemObject)
        end
    end
    self.ListBoard:BP_SetListItems(BoardInListItems)
end

---@param self WBP_CaseEditor
local function RefreshFileDatas(self)
    local CaseEditorResult = self.CurrentFileData
    if CaseEditorResult then
        local AllCasePos = CaseEditorResult.AllCasePos
        if AllCasePos then
            for _, CasePos in pairs(AllCasePos) do
                if CasePos.ID then
                    local NewCardOnWall = WidgetUtil.CreateWidget(self, self.CaseCardOnWallClass)

                    NewCardOnWall.ID = CasePos.ID
                    NewCardOnWall.TextCaseID:SetText(CasePos.ID)
                    NewCardOnWall.WBP_Task_Photo:SetMissionActID(CasePos.ID, true)
                    NewCardOnWall:SetOwnerWidget(self)
                    
                    self.CanvasPanelCase:AddChild(NewCardOnWall)
                    ---@type UCanvasPanelSlot
                    local Slot = NewCardOnWall.Slot
                    Slot:SetAutoSize(true)
                    Slot:SetPosition(UE.FVector2D(CasePos.PositionX, CasePos.PositionY))
                    NewCardOnWall.WBP_Task_Photo:SetRenderTransformAngle(CasePos.Rotation)
                end
            end
        end
        local AllBoardPos = CaseEditorResult.AllBoardPos
        if AllBoardPos then
            for _, BoardPos in pairs(AllBoardPos) do
                if BoardPos.ID then
                    ---@type WBP_CaseTitleOnWall
                    local NewTitleOnWall = WidgetUtil.CreateWidget(self, self.CaseTitleOnWallClass)
                    NewTitleOnWall.ID = BoardPos.ID
                    NewTitleOnWall.WBP_Task_Chapter:SetID(BoardPos.ID)
                    NewTitleOnWall:SetOwnerWidget(self)

                    self.CanvasPanelCase:AddChild(NewTitleOnWall)
                    ---@type UCanvasPanelSlot
                    local Slot = NewTitleOnWall.Slot
                    Slot:SetAutoSize(true)
                    Slot:SetPosition(UE.FVector2D(BoardPos.PositionX, BoardPos.PositionY))
                    NewTitleOnWall.WBP_Task_Chapter:SetRenderTransformAngle(BoardPos.Rotation)
                end
            end
        end
    end
end

---@param self WBP_CaseEditor
local function RefreshAll(self)
    RefreshBottomDatas(self)
    RefreshFileDatas(self)

    local CallBack = function()
        RefreshLines(self)
    end
    UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, CallBack}, 0.1, false)
end

---@param self WBP_CaseEditor
---@param SelectedItem string
---@param SelectionType ESelectInfo
local function OnSelectedChanged(self, SelectedItem, SelectionType)
    if self.CurrentOption ~= SelectedItem then
        self.CurrentOption = SelectedItem
        self.CurrentFileData = LoadFile(self)
        ClearAll(self)
        RefreshAll(self)
    end
end

---@param self WBP_CaseEditor
local function InitOptionFiles(self)
    self.OptionFiles = {}
    self.ComboBoxTop:ClearOptions()
    local Directory = GetMissionRelateRootPath()
    local JsonArray = UE.UHiEdRuntime.FindFilesRecursive(Directory, "*.json", true, false)
    for Ind = 1, JsonArray:Length() do
        local JsonFilePath = JsonArray:Get(Ind)
        local relative_path = JsonFilePath:sub(Directory:len() + 1)
        table.insert(self.OptionFiles, relative_path)
        self.ComboBoxTop:AddOption(relative_path)
    end
    if #self.OptionFiles > 0 then
        self.TextEmpty:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.CurrentOption = self.OptionFiles[1]
        self.ComboBoxTop:SetSelectedOption(self.CurrentOption)
    else
        self.TextEmpty:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
end

---@param self WBP_CaseEditor
---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
local function OnBorderMouseButtonDown(self, MyGeometry, MouseEvent)
    self.bDragging = true
    return UE.UWidgetBlueprintLibrary.Handled()
end

---@param self WBP_CaseEditor
---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
local function OnBorderMouseButtonUp(self, MyGeometry, MouseEvent)
    self.bDragging = false
    local CallBack = function()
        RefreshLines(self)
    end
    UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, CallBack}, 0.1, false)
    return UE.UWidgetBlueprintLibrary.Handled()
end

---@param self WBP_CaseEditor
---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
local function OnBorderMouseMove(self, MyGeometry, MouseEvent)
    if self.bDragging then
        local MoveDelta = UE.UKismetInputLibrary.PointerEvent_GetCursorDelta(MouseEvent)
        local Delta = MoveDelta.X / 2
        if math.abs(MoveDelta.Y) > math.abs(MoveDelta.X) then
            Delta = -MoveDelta.Y / 2
        end
        if self.CurrentChooseCaseWidget then
            local Angle = self.CurrentChooseCaseWidget.WBP_Task_Photo.RenderTransform.Angle
            Angle = Angle - Delta
            self.CurrentChooseCaseWidget.WBP_Task_Photo:SetRenderTransformAngle(Angle)
            EditCasePos(self, self.CurrentChooseCaseWidget.ID, nil, nil, Angle)
        elseif self.CurrentChooseTitleWidget then
            local Angle = self.CurrentChooseTitleWidget.WBP_Task_Chapter.RenderTransform.Angle
            Angle = Angle - Delta
            self.CurrentChooseTitleWidget.WBP_Task_Chapter:SetRenderTransformAngle(Angle)
            EditCasePos(self, self.CurrentChooseTitleWidget.ID, nil, nil, Angle, true)
        end
    end
    return UE.UWidgetBlueprintLibrary.Handled()
end

---@param self WBP_CaseEditor
---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
local function OnBorderAllMouseDown(self, MyGeometry, MouseEvent)
    self.bDraggingAll = true
    return UE.UWidgetBlueprintLibrary.Handled()
end

---@param self WBP_CaseEditor
---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
local function OnBorderAllMouseUp(self, MyGeometry, MouseEvent)
    self.bDraggingAll = false
    return UE.UWidgetBlueprintLibrary.Handled()
end

---@param self WBP_CaseEditor
---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
local function OnBorderAllMouseMove(self, MyGeometry, MouseEvent)
    if self.bDraggingAll then
        local MoveDelta = UE.UKismetInputLibrary.PointerEvent_GetCursorDelta(MouseEvent)
        ---@type UCanvasPanelSlot
        local Slot = self.CanvasPanelCase.Slot
        local Position = Slot:GetPosition()
        local X = math.min(0, Position.X + MoveDelta.X)
        local Y = math.min(SIZE_SCREEN_PARAM, math.max(-SIZE_SCREEN_PARAM, Position.Y + MoveDelta.Y))
        Slot:SetPosition(UE.FVector2D(X, Y))
        RefreshLines(self)
    end
    return UE.UWidgetBlueprintLibrary.Handled()
end

---The system will use this event to notify a widget that the cursor has left it. This event is NOT bubbled.
---@param MouseEvent FPointerEvent
---@return void
function WBP_CaseEditor:OnMouseLeave(MouseEvent)
    self.bDraggingAll = false
end

---@param Owner BP_CaseEditorBox
function WBP_CaseEditor:SetOwnerTrigger(Owner)
    self.Owner = Owner
end

function WBP_CaseEditor:Construct()
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    PlayerController.bShowMouseCursor = true
    UE.UWidgetBlueprintLibrary.SetInputMode_UIOnlyEx(PlayerController, self, UE.EMouseLockMode.DoNotLock, true)

    self.ButtonClose.OnClicked:Add(self, OnClickCloseButton)
    self.ButtonConfirm.OnClicked:Add(self, OnClickConfirm)
    self.ButtonReset.OnClicked:Add(self, OnClickReset)
    self.ButtonCreate.OnClicked:Add(self, OnClickCreate)
    self.ComboBoxTop.OnSelectionChanged:Add(self, OnSelectedChanged)
    self.ComboBoxTop.OnGenerateWidgetEvent:Bind(self, OnGenerateItemWidget)
    self.BorderDrag.OnMouseButtonDownEvent:Bind(self, OnBorderMouseButtonDown)
    self.BorderDrag.OnMouseButtonUpEvent:Bind(self, OnBorderMouseButtonUp)
    self.BorderDrag.OnMouseMoveEvent:Bind(self, OnBorderMouseMove)
    self.BorderDragAll.OnMouseButtonDownEvent:Bind(self, OnBorderAllMouseDown)
    self.BorderDragAll.OnMouseButtonUpEvent:Bind(self, OnBorderAllMouseUp)
    self.BorderDragAll.OnMouseMoveEvent:Bind(self, OnBorderAllMouseMove)

    self.AllCaseDatas = MissionActUtils.GetAllCaseDatas()

    InitOptionFiles(self)
    self.CurrentFileData = LoadFile(self)
    RefreshAll(self)
    self:PlayAnimation(self.Anim_Drag, 0, 0, UE.EUMGSequencePlayMode.Forward, 1, false)
end

function WBP_CaseEditor:Destruct()
    self.ButtonClose.OnClicked:Remove(self, OnClickCloseButton)
    self.ButtonConfirm.OnClicked:Remove(self, OnClickConfirm)
    self.ButtonReset.OnClicked:Remove(self, OnClickReset)
    self.ButtonCreate.OnClicked:Remove(self, OnClickCreate)
    self.ComboBoxTop.OnSelectionChanged:Remove(self, OnSelectedChanged)
    self.ComboBoxTop.OnGenerateWidgetEvent:Unbind()
    self.BorderDrag.OnMouseButtonDownEvent:Unbind()
    self.BorderDrag.OnMouseButtonUpEvent:Unbind()
    self.BorderDrag.OnMouseMoveEvent:Unbind()
    self.BorderDragAll.OnMouseButtonDownEvent:Bind(self, OnBorderAllMouseDown)
    self.BorderDragAll.OnMouseButtonUpEvent:Bind(self, OnBorderAllMouseUp)
    self.BorderDragAll.OnMouseMoveEvent:Bind(self, OnBorderAllMouseMove)
end

---@param self WBP_CaseEditor
---@param Operation UDragDropOperation
local function OnDropCard(self, Operation)
    ---@type WBP_CaseCardOnWall
    local DragVisual = Operation.DefaultDragVisual

    local AbsolutePosListCase = UE.USlateBlueprintLibrary.LocalToAbsolute(self.ListCase:GetCachedGeometry(), UE.FVector2D(0, 0))
    local AbsolutePosDrag = UE.USlateBlueprintLibrary.LocalToAbsolute(DragVisual:GetCachedGeometry(), UE.FVector2D(0, 0))
    local AbsoluteSizeDrag = UE.USlateBlueprintLibrary.GetAbsoluteSize(DragVisual:GetCachedGeometry())

    ---拖到list上
    if AbsolutePosDrag.X + AbsoluteSizeDrag.X / 2 > AbsolutePosListCase.X and AbsolutePosDrag.Y + AbsoluteSizeDrag.Y / 2 > AbsolutePosListCase.Y then
        if self.DragListItem then
            self.DragListItem:SetRenderOpacity(1)
            self.DragListItem = nil
        end
        if self.DragCollapsedItem then
            RemoveCasePos(self, self.DragCollapsedItem.ID)
            self.DragCollapsedItem:RemoveFromParent()
            RefreshBottomDatas(self)
            self.DragCollapsedItem = nil
        end
    else ---没有拖到list上
    if self.DragListItem then
        local LocalPos = UE.USlateBlueprintLibrary.AbsoluteToLocal(self.CanvasPanelCase:GetCachedGeometry(), AbsolutePosDrag)
        ---@type WBP_CaseCardOnWall
        local NewCardOnWall = WidgetUtil.CreateWidget(self, self.CaseCardOnWallClass)
        NewCardOnWall:Copy(DragVisual)
        NewCardOnWall:SetOwnerWidget(self)
        self.CanvasPanelCase:AddChild(NewCardOnWall)
        ---@type UCanvasPanelSlot
        local Slot = NewCardOnWall.Slot
        Slot:SetPosition(LocalPos)
        Slot:SetAutoSize(true)
        EditCasePos(self, DragVisual.ID, LocalPos.X, LocalPos.Y,0)
        self.DragListItem:SetRenderOpacity(1)
        self.DragListItem = nil
        RefreshBottomDatas(self)
    end
        if self.DragCollapsedItem then
            local LocalPos = UE.USlateBlueprintLibrary.AbsoluteToLocal(self.CanvasPanelCase:GetCachedGeometry(), AbsolutePosDrag)
            ---@type UCanvasPanelSlot
            local Slot = self.DragCollapsedItem.Slot
            Slot:SetPosition(LocalPos)
            EditCasePos(self, DragVisual.ID, LocalPos.X, LocalPos.Y)
            self.DragCollapsedItem:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.DragCollapsedItem = nil
        end
    end
end

---@param self WBP_CaseEditor
---@param Operation UDragDropOperation
local function OnDropTitle(self, Operation)
    ---@type WBP_CaseTitleOnWall
    local DragVisual = Operation.DefaultDragVisual

    local AbsolutePosListCase = UE.USlateBlueprintLibrary.LocalToAbsolute(self.ListBoard:GetCachedGeometry(), UE.FVector2D(0, 0))
    local AbsolutePosDrag = UE.USlateBlueprintLibrary.LocalToAbsolute(DragVisual:GetCachedGeometry(), UE.FVector2D(0, 0))
    local AbsoluteSizeDrag = UE.USlateBlueprintLibrary.GetAbsoluteSize(DragVisual:GetCachedGeometry())

    ---拖到list上
    if AbsolutePosDrag.Y + AbsoluteSizeDrag.Y / 2 > AbsolutePosListCase.Y then
        if self.DragListTitleItem then
            self.DragListTitleItem:SetRenderOpacity(1)
            self.DragListTitleItem = nil
        end
        if self.DragCollapsedTitleItem then
            RemoveCasePos(self, self.DragCollapsedTitleItem.ID, true)
            self.DragCollapsedTitleItem:RemoveFromParent()
            RefreshBottomDatas(self)
            self.DragCollapsedTitleItem = nil
        end
    else ---没有拖到list上
    if self.DragListTitleItem then
        local LocalPos = UE.USlateBlueprintLibrary.AbsoluteToLocal(self.CanvasPanelCase:GetCachedGeometry(), AbsolutePosDrag)
        ---@type WBP_CaseTitleOnWall
        local NewCardOnWall = WidgetUtil.CreateWidget(self, self.CaseTitleOnWallClass)
        NewCardOnWall:Copy(DragVisual)
        NewCardOnWall:SetOwnerWidget(self)
        self.CanvasPanelCase:AddChild(NewCardOnWall)
        ---@type UCanvasPanelSlot
        local Slot = NewCardOnWall.Slot
        Slot:SetPosition(LocalPos)
        Slot:SetAutoSize(true)
        EditCasePos(self, DragVisual.ID, LocalPos.X, LocalPos.Y, 0, true)
        self.DragListTitleItem:SetRenderOpacity(1)
        self.DragListTitleItem = nil
        RefreshBottomDatas(self)
    end
        if self.DragCollapsedTitleItem then
            local LocalPos = UE.USlateBlueprintLibrary.AbsoluteToLocal(self.CanvasPanelCase:GetCachedGeometry(), AbsolutePosDrag)
            ---@type UCanvasPanelSlot
            local Slot = self.DragCollapsedTitleItem.Slot
            Slot:SetPosition(LocalPos)
            EditCasePos(self, DragVisual.ID, LocalPos.X, LocalPos.Y, nil, true)
            self.DragCollapsedTitleItem:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.DragCollapsedTitleItem = nil
        end
    end
end

---Called when the user is dropping something onto a widget.  Ends the drag and drop operation, even if no widget handles this.
---@param MyGeometry FGeometry
---@param PointerEvent FPointerEvent
---@param Operation UDragDropOperation
---@return boolean
function WBP_CaseEditor:OnDrop(MyGeometry, PointerEvent, Operation)
    if Operation.DefaultDragVisual.bIsCaseCardOnWall then
        OnDropCard(self, Operation)

        local CallBack = function()
            RefreshLines(self)
        end
        UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, CallBack}, 0.1, false)
        return true
    end
    if Operation.DefaultDragVisual.bIsCaseTitleOnWall then
        OnDropTitle(self, Operation)
        return true
    end

    return false
end

---Called during drag and drop when the drag leaves the widget.
---@param PointerEvent FPointerEvent
---@param Operation UDragDropOperation
---@return void
function WBP_CaseEditor:OnDragLeave(PointerEvent, Operation)
    if Operation.DefaultDragVisual.bIsCaseCardOnWall then
        if self.DragListItem then
            self.DragListItem:SetRenderOpacity(1)
            self.DragListItem = nil
        end
        if self.DragCollapsedItem then
            self.DragCollapsedItem:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.DragCollapsedItem = nil
        end
    end
    if Operation.DefaultDragVisual.bIsCaseTitleOnWall then
        if self.DragListTitleItem then
            self.DragListTitleItem:SetRenderOpacity(1)
            self.DragListTitleItem = nil
        end
        if self.DragCollapsedTitleItem then
            self.DragCollapsedTitleItem:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.DragCollapsedTitleItem = nil
        end
    end
end


---@param CaseWidget WBP_CaseCardOnWall
function WBP_CaseEditor:OnClickCaseWidget(CaseWidget)
    if self.CurrentChooseCaseWidget == CaseWidget then
        ---@type UCanvasPanelSlot
        local BorderSlot = self.BorderDrag.Slot
        BorderSlot:SetZOrder(0)
        ---@type UCanvasPanelSlot
        local CaseSlot = self.CurrentChooseCaseWidget.Slot
        CaseSlot:SetZOrder(0)

        self.BorderDrag:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.CurrentChooseCaseWidget = nil
    else
        if self.CurrentChooseCaseWidget then
            self.CurrentChooseCaseWidget:UnSelect()
            self.CurrentChooseCaseWidget = nil
        end
        if self.CurrentChooseTitleWidget then
            self.CurrentChooseTitleWidget:UnSelect()
            self.CurrentChooseCaseWidget = nil
        end
        self.CurrentChooseCaseWidget = CaseWidget
        ---@type UCanvasPanelSlot
        local BorderSlot = self.BorderDrag.Slot
        BorderSlot:SetZOrder(BIG_Z_ORDER)
        ---@type UCanvasPanelSlot
        local CaseSlot = self.CanvasPanelCase.Slot
        CaseSlot:SetZOrder(BIGGER_Z_ORDER)
        self.BorderDrag:SetVisibility(UE.ESlateVisibility.Visible)
    end
end

---@param TitleWidget WBP_CaseTitleOnWall
function WBP_CaseEditor:OnClickTitleWidget(TitleWidget)
    if self.CurrentChooseTitleWidget == TitleWidget then
        ---@type UCanvasPanelSlot
        local BorderSlot = self.BorderDrag.Slot
        BorderSlot:SetZOrder(0)
        ---@type UCanvasPanelSlot
        local CaseSlot = self.CurrentChooseTitleWidget.Slot
        CaseSlot:SetZOrder(0)

        self.BorderDrag:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.CurrentChooseTitleWidget = nil
    else
        if self.CurrentChooseCaseWidget then
            self.CurrentChooseCaseWidget:UnSelect()
            self.CurrentChooseCaseWidget = nil
        end
        if self.CurrentChooseTitleWidget then
            self.CurrentChooseTitleWidget:UnSelect()
            self.CurrentChooseCaseWidget = nil
        end
        self.CurrentChooseTitleWidget = TitleWidget
        ---@type UCanvasPanelSlot
        local BorderSlot = self.BorderDrag.Slot
        BorderSlot:SetZOrder(BIG_Z_ORDER)
        ---@type UCanvasPanelSlot
        local CaseSlot = self.CanvasPanelCase.Slot
        CaseSlot:SetZOrder(BIGGER_Z_ORDER)
        self.BorderDrag:SetVisibility(UE.ESlateVisibility.Visible)
    end
end

function WBP_CaseEditor:OnAddFile()
    InitOptionFiles(self)
    self.CurrentFileData = LoadFile(self)
    RefreshAll(self)
end

return WBP_CaseEditor
