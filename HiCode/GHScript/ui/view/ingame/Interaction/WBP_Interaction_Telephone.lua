--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@class PhoneCardConfig
---@field picture_ID string
---@field mini_picture_ID string
---@field dialogue_ID integer

---@class CardMoveData
---@field CardWidget WBP_Interaction_CallingCard
---@field BeginAngle float
---@field TargetAngle float

local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")
local PicConst = require("CP0032305_GH.Script.common.pic_const")
local PhoneCardTable = require("common.data.phone_card_data").data
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local UICommonUtil = require('CP0032305_GH.Script.framework.ui.ui_common_utl')

---@class WBP_Interaction_Telephone : WBP_Interaction_Telephone_C
---@field EnterIndex integer
---@field DragIndex integer
---@field UsingExcelID integer
---@field CurrentWaitingCardCount integer
---@field HideLayerNode UIHideLayerNode
---@field CardInsertStart boolean
---@field MoveCardDatas CardMoveData[]
---@field TempHideCard WBP_Interaction_CallingCard
---@field AkEvents table<string, UAkAudioEvent>

---@type WBP_Interaction_Telephone_C
local WBP_Interaction_Telephone = Class(UIWindowBase)

local MAX_CARD = 4
local USE_ITME_DELAY = 1.5

local CardInsertSoundKey = "Spur_Itm_Nathan_Phonecard_In"
local CardInsertFinishSoundKey = "Spur_Itm_Nathan_Phone_Ring"
local CallFinishSoundKey = "Spur_Itm_Nathan_Phone_Buzz_End"
local CardBgSounds = {}
CardBgSounds[2] = "Spur_AMB_Nathan_Phonecard2"
CardBgSounds[3] = "Spur_AMB_Nathan_Phonecard3"
CardBgSounds[4] = "Spur_AMB_Nathan_Phonecard4"

local ENTER_AK_STATE = "Map_Music_Underground"
local EXIT_AK_STATE = "Map_Music_Onground"

---@param self WBP_Interaction_Telephone
---@param SoundKey string
---@return UAkAudioEvent
local function GetAudio(self, SoundKey)
    local DataTableUtils = require("common.utils.data_table_utils")
    local AudioData = DataTableUtils.GetDataTableRow(DataTableUtils.AKAudioResourceTable, SoundKey)
    if AudioData ~= nil then
        if not AudioData.AKEvent:IsNull() then
            return AudioData.AKEvent:LoadSynchronous()
        end
    end
end

-------@param self WBP_Interaction_Telephone
-------@param SoundKey string
-------@return UAkAudioEvent
--local function GetAudio(self, SoundKey)
--    if not self.DefaultAk:IsNull() then
--        return self.DefaultAk:LoadSynchronous()
--    end
--end

-----@param self WBP_Interaction_Telephone
-----@param AkEvent UAkAudioEvent
-----@param SoundKey string
--local function PlayAudio(self, AkEvent, SoundKey)
--    local controller = UE.UGameplayStatics.GetPlayerController(self, 0)
--    local CallBack = function(self, CallbackType, CallbackInfo)
--        print("PlayAudio CallBack", CallbackType, CallbackInfo, SoundKey)
--        if CallbackType == 0 then
--            self:OnAkEventFinish(SoundKey)
--        end
--    end
--    print("PlayAudio", AkEvent, SoundKey)
--    local ExternalSources = UE.TArray(UE.FAkExternalSourceInfo)
--    local PostEventAsync = UE.UPostEventAsync.PostEventAsync(controller, AkEvent, controller, 1, { self, CallBack }, ExternalSources)
--    local OnComplete = function(self, PlayingID)
--        print("PlayAudio OnComplete", PlayingID, SoundKey)
--        self.PlayingID = PlayingID
--    end
--    PostEventAsync.Completed:Add(self, OnComplete)
--end

-----@param self WBP_Interaction_Telephone
--local function StopAudio(self)
--    UE.UAkGameplayStatics.ExecuteActionOnPlayingID(UE.AkActionOnEventType.Stop, self.PlayingID)
--end

---@param self WBP_Interaction_Telephone
local function StopSound(self)
    self:StopAkEvent()
    --StopAudio(self)
end

---@param self WBP_Interaction_Telephone
---@param SoundKey string
local function PlaySound(self, SoundKey)
    print("WBP_Interaction_Telephone PlaySound", SoundKey)
    local AkEvent = GetAudio(self, SoundKey)
    self:PlayAkEvent(AkEvent, SoundKey)
    --local function Play()
    --    PlayAudio(self, AkEvent, SoundKey)
    --end
    --coroutine.resume(coroutine.create(Play))
end

---@param AkStateKey string
local function SetAkState(AkStateKey)
    local EdUtils = require("common.utils.ed_utils")
    local Path = EdUtils:GetUE5ObjectPath(AkStateKey)
    local AkStateValue = UE.UObject.Load(Path)
    UE.UAkGameplayStatics.SetState(AkStateValue, "", "")
end

---@param self WBP_Interaction_Telephone
---@param CardWidget WBP_Interaction_CallingCard
---@param TargetAngle float
local function AddMoveCardData(self, CardWidget, TargetAngle)
    ---@type CardMoveData
    local MoveCardData = {}
    MoveCardData.CardWidget = CardWidget
    MoveCardData.BeginAngle = CardWidget:GetRenderTransformAngle()
    MoveCardData.TargetAngle = TargetAngle
    table.insert(self.MoveCardDatas, MoveCardData)
end

---@param self WBP_Interaction_Telephone
local function PrepareCardMoveData(self)
    ---@type WBP_Interaction_CallingCard[]
    local Cards = {}
    for i = 1, MAX_CARD do
        ---@type WBP_Interaction_CallingCard
        local CardWidget = self["WBP_Interaction_CallingCard0"..i]
        if CardWidget:IsWaitingUse() then
            table.insert(Cards, CardWidget)
        end
    end
    self.MoveCardDatas = {}
    if #Cards == 1 then
        AddMoveCardData(self, Cards[1], self.Angle3:Get(2))
    elseif #Cards == 2 then
        AddMoveCardData(self, Cards[1], self.Angle4:Get(2))
        AddMoveCardData(self, Cards[2], self.Angle4:Get(3))
    elseif #Cards == 3 then
        for i= 1, 3 do
            AddMoveCardData(self, Cards[i], self.Angle3:Get(i))
        end
    elseif #Cards == 4 then
        for i= 1, 4 do
            AddMoveCardData(self, Cards[i], self.Angle4:Get(i))
        end
    end
end

---@param self WBP_Interaction_Telephone
---@param DeltaValue double
local function MoveCardsByDeltaValue(self, DeltaValue)
    for i, CardMoveData in ipairs(self.MoveCardDatas) do
        local CardWidget = CardMoveData.CardWidget
        local Angle = CardMoveData.BeginAngle + (CardMoveData.TargetAngle - CardMoveData.BeginAngle) * DeltaValue
        CardWidget:SetRenderTransformAngle(Angle)
    end
end

---@param self WBP_Interaction_Telephone
local function StartCardMove(self)
    PrepareCardMoveData(self)
    local GameTime = UE.UKismetSystemLibrary.GetGameTimeInSeconds(self)
    self.MoveStartTime = GameTime
    local CallBack = function()
        local GameTime = UE.UKismetSystemLibrary.GetGameTimeInSeconds(self)
        if GameTime - self.MoveStartTime > self.CardMoveTime then
            UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.MoveCardHandle)
        else
            local CurveValue = self.CardMoveCurve:GetFloatValue((GameTime - self.MoveStartTime) / self.CardMoveTime)
            MoveCardsByDeltaValue(self, CurveValue)
        end
    end
    self.MoveCardHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, CallBack }, self.MoveDeltaTime, true, 0, 0)
end

---@param self WBP_Interaction_Telephone
local function InsertCardFinish(self)
    self.DX_Drag:SetVisibility(UE.ESlateVisibility.Collapsed)
    PlaySound(self, CardInsertFinishSoundKey)
    local CallBack = function()
        self:UseItem()
    end
    UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, CallBack }, USE_ITME_DELAY, false)
end

---@param SoundKey string
function WBP_Interaction_Telephone:OnAkEventFinish(SoundKey)
    print("WBP_Interaction_Telephone OnAkEventFinish", SoundKey)
    if SoundKey == CardInsertSoundKey then
        InsertCardFinish(self)
    end
end

---@param self WBP_Interaction_Telephone
local function OnClickCloseButton(self)
    local OnAnimFinish = function()
        UIManager:CloseUI(self, true)
    end
    self.WBP_Interaction_Secondary:PlayTitleOutAnim(OnAnimFinish)
    for i = 1, MAX_CARD do
        ---@type WBP_Interaction_CallingCard
        local CardWidget = self["WBP_Interaction_CallingCard0"..i]
        if CardWidget:IsWaitingUse() then
            CardWidget:PlayOutAnim()
        end
    end
end

---@param CardWidget WBP_Interaction_CallingCard
local function GetCardPos(CardWidget)
    ---@type UCanvasPanelSlot
    local Slot = CardWidget.Slot
    return Slot:GetPosition(), CardWidget:GetRenderTransformAngle()
end

---@param CardWidget WBP_Interaction_CallingCard
---@param Pos FVector
local function SetCardPos(CardWidget, Pos)
    ---@type UCanvasPanelSlot
    local Slot = CardWidget.Slot
    Slot:SetPosition(UE.FVector2D(Pos.X, Pos.Y))
    CardWidget:SetRenderTransformAngle(Pos.Z)
end

---@param CardWidget WBP_Interaction_CallingCard
---@param ZOrder integer
local function SetCardZOrder(CardWidget, ZOrder)
    ---@type UCanvasPanelSlot
    local Slot = CardWidget.Slot
    Slot:SetZOrder(ZOrder)
end

---@param self WBP_Interaction_Telephone
local function ResetCardZOrder(self)
    for i = 1, MAX_CARD do
        ---@type WBP_Interaction_CallingCard
        local CardWidget = self["WBP_Interaction_CallingCard0"..i]
        SetCardZOrder(CardWidget, i)
    end
end

---@param self WBP_Interaction_Telephone
---@param bUsed boolean
local function OnCardRelease(self, bUsed)
    if self.DragIndex ~= nil then
        ---@type WBP_Interaction_CallingCard
        local DragWidget = self["WBP_Interaction_CallingCard0"..self.DragIndex]
        DragWidget:EndDrag(bUsed)
        ResetCardZOrder(self)
        StartCardMove(self)
    end
    self.DX_Trigger:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.DragIndex = nil
end

---@param self WBP_Interaction_Telephone
---@param MyGeometry FGeometry
local function CheckTrigger(self, MyGeometry)
    local ButtonGeometry = self.Btn_Trigger:GetCachedGeometry()
    local AbsoluteButtonPos = UE.USlateBlueprintLibrary.LocalToAbsolute(ButtonGeometry, UE.FVector2D(0, 0))
    local LocalButtonPos = UE.USlateBlueprintLibrary.AbsoluteToLocal(MyGeometry, AbsoluteButtonPos)
    local ButtonLocalSize = UE.USlateBlueprintLibrary.GetLocalSize(ButtonGeometry)

    local TargetPosMinX = LocalButtonPos.X
    local TargetPosMaxX = LocalButtonPos.X + ButtonLocalSize.X
    local TargetPosMinY = LocalButtonPos.Y
    local TargetPosMaxY = LocalButtonPos.Y + ButtonLocalSize.Y

    ---@type WBP_Interaction_CallingCard
    local DragWidget = self["WBP_Interaction_CallingCard0"..self.DragIndex]
    local DragGeometry = DragWidget:GetCachedGeometry()
    local AbsoluteDragPos = UE.USlateBlueprintLibrary.LocalToAbsolute(DragGeometry, UE.FVector2D(0, 0))
    local LocalDragPos = UE.USlateBlueprintLibrary.AbsoluteToLocal(MyGeometry, AbsoluteDragPos)
    local DragLocalSize = UE.USlateBlueprintLibrary.GetLocalSize(DragGeometry)

    local CardMinX = LocalDragPos.X
    local CardMaxX = LocalDragPos.X + DragLocalSize.X
    local CardMinY = LocalDragPos.Y
    local CardMaxY = LocalDragPos.Y + DragLocalSize.Y

    ---这里默认目标区域比卡片大
    if ((CardMinX >= TargetPosMinX and CardMinX <= TargetPosMaxX) or (CardMaxX >= TargetPosMinX and CardMaxX <= TargetPosMaxX))
            and ((CardMinY >= TargetPosMinY and CardMinY <= TargetPosMaxY) or (CardMaxY >= TargetPosMinY and CardMaxY <= TargetPosMaxY))  then
        return true
    end
    return false
end

---@param self WBP_Interaction_Telephone
local function CardInsert(self)
    self.CardInsertStart = true
    ---@type WBP_Interaction_CallingCard
    local CardWidget = self["WBP_Interaction_CallingCard0"..self.DragIndex]
    CardWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.TempHideCard = CardWidget
    PicConst.SetImageBrush(self.Img_InsertCard, CardWidget.DXImageKey)
    local ItemExcelID = CardWidget.ItemExcelID
    self.UsingExcelID = ItemExcelID
    self.UsingIndex = CardWidget.Index
    print("CardInsert", self.UsingExcelID, self.UsingIndex)
    self:PlayAnimation(self.DX_CardInsert, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    PlaySound(self, CardInsertSoundKey)
end

---@param self WBP_Interaction_Telephone
local function MouseUpOrLeave(self)
    local bUsed = false
    if self.DragIndex ~= nil and self.DragIndex > 0 then
        local MyGeometry = self:GetCachedGeometry()
        if CheckTrigger(self, MyGeometry)then
            bUsed = true
            CardInsert(self, self.DragIndex)
            StartCardMove(self)
        end
        ---@type WBP_Interaction_CallingCard
        local DragWidget = self["WBP_Interaction_CallingCard0"..self.DragIndex]
        DragWidget:SetRenderTranslation(UE.FVector2D(0, 0))
    end

    self.EnterIndex = nil
    self.StartDragPos = nil
    OnCardRelease(self, bUsed)
end

---The system will use this event to notify a widget that the cursor has left it. This event is NOT bubbled.
---@param MouseEvent FPointerEvent
---@return void
function WBP_Interaction_Telephone:OnMouseLeave(MouseEvent)
    MouseUpOrLeave(self)
end

---The system calls this method to notify the widget that a mouse moved within it. This event is bubbled.
---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
---@return FEventReply
function WBP_Interaction_Telephone:OnMouseMove(MyGeometry, MouseEvent)
    if self.DragIndex == nil or self.StartDragPos == nil then
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    local AbsolutePos = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(MouseEvent)
    local LocalPos = UE.USlateBlueprintLibrary.AbsoluteToLocal(MyGeometry, AbsolutePos)
    local DeltaX = LocalPos.X - self.StartDragPos.X
    local DeltaY = LocalPos.Y - self.StartDragPos.Y
    ---@type WBP_Interaction_CallingCard
    local DragWidget = self["WBP_Interaction_CallingCard0"..self.DragIndex]
    DragWidget:SetRenderTranslation(UE.FVector2D(DeltaX, DeltaY))

    if CheckTrigger(self, MyGeometry)then
        self.DX_Trigger:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.DX_Trigger:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    return UE.UWidgetBlueprintLibrary.Handled()
end

---The system calls this method to notify the widget that a mouse button was release within it. This event is bubbled.
---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
---@return FEventReply
function WBP_Interaction_Telephone:OnMouseButtonUp(MyGeometry, MouseEvent)
    MouseUpOrLeave(self)
    return UE.UWidgetBlueprintLibrary.Handled()
end

---The system calls this method to notify the widget that a mouse button was pressed within it. This event is bubbled.
---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
---@return FEventReply
function WBP_Interaction_Telephone:OnMouseButtonDown(MyGeometry, MouseEvent)
    if self.EnterIndex ~= nil and self.EnterIndex > 0 then
        self.DragIndex = self.EnterIndex
        local AbsolutePos = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(MouseEvent)
        local LocalPos = UE.USlateBlueprintLibrary.AbsoluteToLocal(MyGeometry, AbsolutePos)
        self.StartDragPos = LocalPos
        ---@type WBP_Interaction_CallingCard
        local DragWidget = self["WBP_Interaction_CallingCard0"..self.DragIndex]
        DragWidget:BeginDrag()
        SetCardZOrder(DragWidget, 5)
        StartCardMove(self)
        self.DX_Drag:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
    return UE.UWidgetBlueprintLibrary.Handled()
end

---@param self WBP_Interaction_Telephone
local function ResetCards(self)
    self.EnterIndex = nil
    self.DragIndex = nil
    self.UsingExcelID = nil
    self.UsingIndex = nil
    self.CardInsertStart = false
    local PhoneCards = ItemUtil.GetAllPhoneCards(self)
    local Count = math.min(#PhoneCards, MAX_CARD)
    self.CurrentWaitingCardCount = Count
    self:SetCardCount(Count)
    for i = 1, MAX_CARD do
        if i <= #PhoneCards then
            ---@type WBP_Interaction_CallingCard
            local CardWidget = self["WBP_Interaction_CallingCard0"..i]
            CardWidget:SetData(self, i, PhoneCards[i].ExcelID)
        end
    end
end

---@param self WBP_Interaction_Telephone
local function TelephoneBegin(self)
    local ItemConfig = ItemUtil.GetItemConfigByExcelID(self.UsingExcelID)
    ---@type PhoneCardConfig
    local PhoneCardConfig = PhoneCardTable[tonumber(ItemConfig.task_item_details[1])]
    self.WBP_Interaction_Secondary:SetBottomDialog(UIDef.UIInfo.UI_InteractionTelephone, PhoneCardConfig.dialogue_ID)
    self:PlayAnimation(self.DX_WaveIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    if CardBgSounds[self.UsingIndex] then
        PlaySound(self, CardBgSounds[self.UsingIndex])
    end
end

---@param self WBP_Interaction_Telephone
local function OnUseItem(self, ExcelID, Count, Time)
    if ExcelID == self.UsingExcelID then
        TelephoneBegin(self)
        self.UsingExcelID = nil
        self.UsingIndex = nil
    end
end

function WBP_Interaction_Telephone:Construct()
    self.WBP_Interaction_Secondary.WBP_Common_TopContent.CommonButton_Close.OnClicked:Add(self, OnClickCloseButton)
    local ItemManager = ItemUtil.GetItemManager(self)
    ItemManager:RegUseItemCallBack(self, OnUseItem)
end

function WBP_Interaction_Telephone:Destruct()
    self.WBP_Interaction_Secondary.WBP_Common_TopContent.CommonButton_Close.OnClicked:Remove(self, OnClickCloseButton)
    local ItemManager = ItemUtil.GetItemManager(self)
    ItemManager:UnRegUseItemCallBack(self, OnUseItem)
end

function WBP_Interaction_Telephone:OnShow()
    SetAkState(ENTER_AK_STATE)
    ResetCards(self)
    self.WBP_Interaction_Secondary:PlayTitleInAnim()
    self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    self:PlayAnimation(self.DX_Loop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1, false)
    self.DX_Drag:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.DX_Trigger:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function WBP_Interaction_Telephone:OnHide()
    SetAkState(EXIT_AK_STATE)
    self.WBP_Interaction_Secondary:ResetDialogUIContext()
    if self.MoveCardHandle then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.MoveCardHandle)
    end
    StopSound(self)
    self.WBP_Interaction_Secondary:OnCloseDialogWidget()
end

---@param Index integer
function WBP_Interaction_Telephone:OnMouseEnterCard(Index)
    self.EnterIndex = Index
end

---@param Index integer
function WBP_Interaction_Telephone:OnMouseLeaveCard(Index)
    self.EnterIndex = nil
end

function WBP_Interaction_Telephone:UseItem()
    print("WBP_Interaction_Telephone:UseItem", self.UsingExcelID)
    local ItemManager = ItemUtil.GetItemManager(self)
    ItemManager:Server_UseItemByExcelID(self.UsingExcelID, 1, 0)
end

function WBP_Interaction_Telephone:OnOpenDialogWidget()
    self.WBP_Interaction_Secondary:OnOpenDialogWidget()
end

function WBP_Interaction_Telephone:OnCloseDialogWidget()
    StopSound(self)
    PlaySound(self, CallFinishSoundKey)
    self.WBP_Interaction_Secondary:OnCloseDialogWidget()
    self:PlayAnimation(self.DX_WaveOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    self:PlayAnimation(self.DX_CardInsertOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    local CallBack = function()
        self.CardInsertStart = false
        self.TempHideCard:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        StartCardMove(self)
    end
    UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, CallBack }, self.DX_CardInsertOut:GetEndTime(), false)
end

return WBP_Interaction_Telephone
