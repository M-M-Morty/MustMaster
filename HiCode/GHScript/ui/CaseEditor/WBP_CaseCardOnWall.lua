--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
---@class WBP_CaseCardOnWall : WBP_CaseCardOnWall_C
---@field OwnerWidget UUserWidget
---@field ID integer
---@field bIsCaseCardOnWall boolean

---@type WBP_CaseCardOnWall_C
local WBP_CaseCardOnWall = UnLua.Class()

local WidgetUtil = require("CP0032305_GH.Script.common.utils.widget_util")

function WBP_CaseCardOnWall:Construct()
    self.bIsCaseCardOnWall = true
end

---@param ListItemObject BP_CaseEditorCaseItem_C
function WBP_CaseCardOnWall:SetDataByObject(ListItemObject)
    self:SetData(ListItemObject.ID)
end

---@param ID integer
---@param Name string
---@param IconKey string
function WBP_CaseCardOnWall:SetData(ID)
    self.ID = ID
    self.TextCaseID:SetText(ID)
    self.WBP_Task_Photo:SetMissionActID(ID, true)
end

---@param CaseCardOnWall WBP_CaseCardOnWall
function WBP_CaseCardOnWall:Copy(CaseCardOnWall)
    self.ID = CaseCardOnWall.ID
    self.TextCaseID:SetText(self.ID)
    self.WBP_Task_Photo:SetMissionActID(CaseCardOnWall.WBP_Task_Photo.MissionActID, CaseCardOnWall.WBP_Task_Photo.bIgnoreState)
end

---@param OwnerWidget UUserWidget
function WBP_CaseCardOnWall:SetOwnerWidget(OwnerWidget)
    self.OwnerWidget = OwnerWidget
end

---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
function WBP_CaseCardOnWall:OnMouseButtonDownLuaImpl(MyGeometry, MouseEvent)

    local AbsolutePos = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(MouseEvent)
    local LocalPos = UE.USlateBlueprintLibrary.AbsoluteToLocal(self.WBP_Task_Photo:GetCachedGeometry(), AbsolutePos)
    local Size = UE.USlateBlueprintLibrary.GetLocalSize(self.WBP_Task_Photo:GetCachedGeometry())
    self.TouchX = LocalPos.X
    self.TouchY = LocalPos.Y
    self.OffsetX = (Size.X / 2 - LocalPos.X) / Size.X
    self.OffsetY = (Size.Y / 2 - LocalPos.Y) / Size.Y
end

---@param MyGeometry FGeometry
---@param PointerEvent FPointerEvent
---@return UUserWidget, FVector2D @DragWidget, Offset
function WBP_CaseCardOnWall:OnDragDetectedLuaImpl(MyGeometry, PointerEvent)
    if self.OwnerWidget.OwnerWidget then
        self.OwnerWidget:SetRenderOpacity(0.1)
        self.OwnerWidget.OwnerWidget.DragListItem = self.OwnerWidget
        self.OwnerWidget.OwnerWidget.DragCollapsedItem = nil
    else
        self:SetVisibility(UE.ESlateVisibility.Hidden)
        self.OwnerWidget.DragCollapsedItem = self
        self.OwnerWidget.DragListItem = nil
    end

    local DragWidget = WidgetUtil.CreateWidget(self, self.CaseCardOnWallClass)
    DragWidget:Copy(self)
    DragWidget.WBP_Task_Photo:SetRenderTransformAngle(self.WBP_Task_Photo.RenderTransform.Angle)

    return DragWidget, UE.FVector2D(self.OffsetX, self.OffsetY)
end

---Called when a mouse button is double clicked.  Override this in derived classes.
---@param InMyGeometry FGeometry
---@param InMouseEvent FPointerEvent
---@return FEventReply
function WBP_CaseCardOnWall:OnMouseButtonDoubleClick(InMyGeometry, InMouseEvent)
    if not self.OwnerWidget.OwnerWidget then
        self.OwnerWidget:OnClickCaseWidget(self)
        if self.ImageChoose:IsVisible() then
            self.ImageChoose:SetVisibility(UE.ESlateVisibility.Collapsed)
        else
            self.ImageChoose:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        end
    end
    return UE.UWidgetBlueprintLibrary.Handled()
end

function WBP_CaseCardOnWall:UnSelect()
    self.ImageChoose:SetVisibility(UE.ESlateVisibility.Collapsed)
end

---@return FVector2D
function WBP_CaseCardOnWall:GetThumbtackSlotCenterPos()
    ---@type WBP_Task_Photo
    local WBP_Task_Photo = self.WBP_Task_Photo
    return WBP_Task_Photo:GetThumbtackSlotCenterPos()
end

return WBP_CaseCardOnWall
