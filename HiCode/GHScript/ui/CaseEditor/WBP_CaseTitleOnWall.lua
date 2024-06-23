--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@class WBP_CaseTitleOnWall : WBP_CaseTitleOnWall_C
---@field ID integer
---@field bIsCaseTitleOnWall boolean
---@field OwnerWidget UUserWidget

---@type WBP_CaseTitleOnWall_C
local WBP_CaseTitleOnWall = UnLua.Class()

local WidgetUtil = require("CP0032305_GH.Script.common.utils.widget_util")

function WBP_CaseTitleOnWall:Construct()
    self.bIsCaseTitleOnWall = true
end

---@param ListItemObject BP_CaseEditorBoardItem_C
function WBP_CaseTitleOnWall:SetDataByObject(ListItemObject)
    self:SetData(ListItemObject.ID, ListItemObject.Name, ListItemObject.Content)
end

---@param CaseTitleOnWall WBP_CaseTitleOnWall
function WBP_CaseTitleOnWall:Copy(CaseTitleOnWall)
    self.ID = CaseTitleOnWall.ID
    self.WBP_Task_Chapter.Txt_ChapterDigit:SetText(CaseTitleOnWall.WBP_Task_Chapter.Txt_ChapterDigit:GetText())
    self.WBP_Task_Chapter.Txt_ChapterContent:SetText(CaseTitleOnWall.WBP_Task_Chapter.Txt_ChapterContent:GetText())
end

---@param OwnerWidget UUserWidget
function WBP_CaseTitleOnWall:SetOwnerWidget(OwnerWidget)
    self.OwnerWidget = OwnerWidget
end

---@param ID integer
---@param Name string
---@param Content string
function WBP_CaseTitleOnWall:SetData(ID, Name, Content)
    self.ID = ID
    self.WBP_Task_Chapter.Txt_ChapterDigit:SetText(Name)
    self.WBP_Task_Chapter.Txt_ChapterContent:SetText(Content)
end

---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
function WBP_CaseTitleOnWall:OnMouseButtonDownLuaImpl(MyGeometry, MouseEvent)

    local AbsolutePos = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(MouseEvent)
    local LocalPos = UE.USlateBlueprintLibrary.AbsoluteToLocal(self.WBP_Task_Chapter:GetCachedGeometry(), AbsolutePos)
    local Size = UE.USlateBlueprintLibrary.GetLocalSize(self.WBP_Task_Chapter:GetCachedGeometry())
    self.TouchX = LocalPos.X
    self.TouchY = LocalPos.Y
    self.OffsetX = (Size.X / 2 - LocalPos.X) / Size.X
    self.OffsetY = (Size.Y / 2 - LocalPos.Y) / Size.Y
end

---@param MyGeometry FGeometry
---@param PointerEvent FPointerEvent
---@return UUserWidget, FVector2D @DragWidget, Offset
function WBP_CaseTitleOnWall:OnDragDetectedLuaImpl(MyGeometry, PointerEvent)
    if self.OwnerWidget.OwnerWidget then
        self.OwnerWidget:SetRenderOpacity(0.1)
        self.OwnerWidget.OwnerWidget.DragListTitleItem = self.OwnerWidget
        self.OwnerWidget.OwnerWidget.DragCollapsedTitleItem = nil
    else
        self:SetVisibility(UE.ESlateVisibility.Hidden)
        self.OwnerWidget.DragCollapsedTitleItem = self
        self.OwnerWidget.DragListTitleItem = nil
    end

    ---@type WBP_CaseTitleOnWall
    local DragWidget = WidgetUtil.CreateWidget(self, self.CaseTitleOnWallClass)
    DragWidget:Copy(self)
    DragWidget.WBP_Task_Chapter:SetRenderTransformAngle(self.WBP_Task_Chapter.RenderTransform.Angle)

    return DragWidget, UE.FVector2D(self.OffsetX, self.OffsetY)
end

---Called when a mouse button is double clicked.  Override this in derived classes.
---@param InMyGeometry FGeometry
---@param InMouseEvent FPointerEvent
---@return FEventReply
function WBP_CaseTitleOnWall:OnMouseButtonDoubleClick(InMyGeometry, InMouseEvent)
    if not self.OwnerWidget.OwnerWidget then
        self.OwnerWidget:OnClickTitleWidget(self)
        if self.ImageChoose:IsVisible() then
            self.ImageChoose:SetVisibility(UE.ESlateVisibility.Collapsed)
        else
            self.ImageChoose:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        end
    end
    return UE.UWidgetBlueprintLibrary.Handled()
end

function WBP_CaseTitleOnWall:UnSelect()
    self.ImageChoose:SetVisibility(UE.ESlateVisibility.Collapsed)
end

return WBP_CaseTitleOnWall
