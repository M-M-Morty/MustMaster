--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')

local StopEvent = "Stop"
local SongChoingEvent = "Play_MusicGame_UI_SongChoing"
local SongChosenEvent = "Play_MusicGame_UI_SongChosen"

---@class WBP_MiniGames_AudioGames_MusicalSelection_C
local UIMusicSelection = Class(UIWindowBase)

function UIMusicSelection:OnConstruct()
    self:InitWidget()
    self:BuildWidgetProxy()
    self:InitViewModel()

    self:InitData()
    self:InitSongList()
end

function UIMusicSelection:UpdateParams(tbData)
    local CurSong = self:GetCurrentSelectedSong()
    local CurItem = self:GetCurrentSelectedItem()
    if self.MusicGameVM then
        self.MusicGameVM:ResetData()
        self.MusicGameVM:SetCurRawData(tbData)
    end
    self:InitData()
    self:InitSongList()
    self:SaveOldSelectedInList(CurSong, CurItem)
end

function UIMusicSelection:OnShow()
    local enter = self:OnLockPlayer()
    self:OnSongItemShow(1, self.AllItemCount - 4)
    if enter then
        self:SetSelectionCamera()
        self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    else
        self:OnUnLockPlayer()
        self:OnExitMusicGame()
        self:OnClosePopUpWindow()
    end
end

function UIMusicSelection:InitWidget()
    self.WBP_Common_TopContent.CommonButton_Close.OnClicked:Add(self, self.ButtonClose_OnClicked)
    self.WBP_Btn_StartPlaying.OnClicked:Add(self, self.StartPlaying_OnClicked)
end

function UIMusicSelection:BuildWidgetProxy()
    ---@type UIWidgetField
    self.CurSelectedItemField = self:CreateUserWidgetField(self.UpdateSongListData) -- logical List Id
    ---@type UIWidgetField
    self.ItemOnClickedField = self:CreateUserWidgetField(self.SetItemUnClicked)     -- BP Item Id
end

function UIMusicSelection:InitViewModel()
    ---@type MusicGameVM
    self.MusicGameVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.MusicGameVM.UniqueName)
    if self.MusicGameVM then
        ViewModelBinder:BindViewModel(self.CurSelectedItemField, self.MusicGameVM.CurrentSelectSongField,
            ViewModelBinder.BindWayToWidget)
        ViewModelBinder:BindViewModel(self.ItemOnClickedField, self.MusicGameVM.CurrentSelectedItemField,
            ViewModelBinder.BindWayToWidget)
    end
end

function UIMusicSelection:SaveOldSelectedInList(CurSong, CurItem)
    if self.MusicGameVM:GetFirstOpen() == 0 and CurItem and CurSong then
        self:InitListDataById(CurItem, CurSong)
    end
end

function UIMusicSelection:InitListDataById(CurItemIdx, CurSong)
    self:UpdateSongListData(CurSong)
    self:SetItemUnClicked(CurItemIdx)
    self:OnSelectItemById(CurItemIdx)
end

function UIMusicSelection:UpdateSongListData(SongId)
    self.SelectSongId = SongId
    self.MusicGameVM:SetCurSongData(self.SelectSongId)

    local SongDatas, SongIndexList = self:GetAllSongListData()
    local CurSongId = SongIndexList[self.SelectSongId]
    local SongData = SongDatas[CurSongId]
    local SongName = SongData.songName

    self:PlayMusicAKEventByName(StopEvent)
    self:PlayMusicAKEventByName(SongName)
    self:PlayTapAKEventByName(SongChosenEvent)
end

function UIMusicSelection:SetItemUnClicked(TargetIndex)
    self.TargetIndex = TargetIndex
    if not self.AllItemCount then
        local curItem = self:GetCurrentItemByIndex(TargetIndex)
        curItem:SetButtonClickedState()
        return
    end
    self:UpdateSongItemList(self.SelectSongId)
    local StartIndex, EndIndex = self:GetItemShowRange()
    self:OnSongItemShow(StartIndex, EndIndex)
    self:EnableOtherBtn(TargetIndex)

    self:OnPlayAnimation(self.SelectSongId)
    for i = 1, self.AllItemCount, 1 do
        local curItem = self:GetCurrentItemByIndex(i)
        local thisSongItemIndex = curItem:GetThisSongItemIndex()
        if thisSongItemIndex ~= TargetIndex then
            curItem:SetButtonUnClickedState()
        end
    end
end

function UIMusicSelection:OnLockPlayer()
    local GameState = UE.UGameplayStatics.GetGameState(self:GetWorld())
    if GameState then
        if not GameState:PlayerStartAimingMode(Enum.E_AimingModeType.MaduKe) then
            return
        end
        return true
    end
end

function UIMusicSelection:OnUnLockPlayer()
    local GameState = UE.UGameplayStatics.GetGameState(G.GameInstance:GetWorld())
    if GameState then
        GameState:PlayerStopAimingMode(Enum.E_AimingModeType.MaduKe)
    end
end

function UIMusicSelection:OnScroll(Value)
    self:PlayTapAKEventByName(SongChoingEvent)
    if Value < 0 then
        self:SelectPrevItem()
    else
        self:SelectNextItem()
    end
end

function UIMusicSelection:OnMouseWheel(MyGeometry, MouseEvent)
    local Delta = UE.UKismetInputLibrary.PointerEvent_GetWheelDelta(MouseEvent)
    self:OnScroll(Delta)
    return UE.UWidgetBlueprintLibrary.Handled()
end

function UIMusicSelection:SetMouseMove()
    if self.isMove then
        local Delta = self.updatePosY - self.lastPosY
        if math.abs(Delta) > 30 then
            self.lastPosY = self.updatePosY
            self:UpdateSongItemList(self.SelectSongId)
            self:OnMove(Delta)
        end
    end
end

function UIMusicSelection:OnMove(Delta)
    if not self.DuraCount then
        self.DuraCount = 0
    end
    self.DuraCount = self.DuraCount + 1
    if not self.prevCount then
        self.prevCount = 0
    end
    if not self.nextCount then
        self.nextCount = 0
    end
    if Delta > 0 then
        self.nextCount = self.nextCount + 1
    else
        self.prevCount = self.prevCount + 1
    end
    if not self.AverageMove then
        self.AverageMove = 0
    end
    if Delta == 0 then
        return
    end
    self.AverageMove = self.AverageMove + math.abs(Delta)
    if self.DuraCount % 3 == 0 then
        local DirctCount = self.nextCount > self.prevCount and 1 or -1
        self.AverageMove = (self.AverageMove / 3) * DirctCount
        self:OnScroll(self.AverageMove)

        self.DuraCount = 0
        self.AverageMove = 0
        self.nextCount = 0
        self.prevCount = 0
    end
end

function UIMusicSelection:Tick(MyGeometry, InDeltaTime)
    self:OnSongItemPressed()
    if self.isSelected then
        local MousePosition = UE.UWidgetLayoutLibrary.GetMousePositionOnViewport(self)
        self.isMove = true
        self.updatePosY = MousePosition.Y
        self:SetMouseMove()
    end
end

function UIMusicSelection:OnSongItemPressed()
    if self.MusicGameVM then
        if self.MusicGameVM:GetSongItemPressed() == -1 then
            return
        end
        if self.MusicGameVM:GetSongItemPressed() == 1 then
            self.MusicGameVM:SetSongItemPressed(-1)
            self.isSelected = true
            self.DuraCount = 0
            local MousePosition = UE.UWidgetLayoutLibrary.GetMousePositionOnViewport(self)
            self.lastPosY = MousePosition.Y
        else
            self.MusicGameVM:SetSongItemPressed(-1)
            self.isSelected = false
            self.DuraCount = 0
            local MousePosition = UE.UWidgetLayoutLibrary.GetMousePositionOnViewport(self)
            self.updatePosY = MousePosition.Y
        end
    end
end

function UIMusicSelection:OnMouseMove(MyGeometry, MouseEvent)
    if self.isSelected then
        local AbsolutePos = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(MouseEvent)
        local LocalPos = UE.USlateBlueprintLibrary.AbsoluteToLocal(MyGeometry, AbsolutePos)
        self.isMove = true
        self.updatePosY = LocalPos.Y
        self:SetMouseMove()
    end
    return UE.UWidgetBlueprintLibrary.Handled()
end

function UIMusicSelection:OnMouseLeave(MouseEvent)
    self.isSelected = false
    self.DuraCount = 0
end

function UIMusicSelection:OnMouseButtonUp(MyGeometry, MouseEvent)
    self.isSelected = false
    self.DuraCount = 0

    local AbsolutePos = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(MouseEvent)
    local LocalPos = UE.USlateBlueprintLibrary.AbsoluteToLocal(MyGeometry, AbsolutePos)
    self.updatePosY = LocalPos.Y

    return UE.UWidgetBlueprintLibrary.Handled()
end

function UIMusicSelection:OnMouseButtonDown(MyGeometry, MouseEvent)
    self.isSelected = true
    self.DuraCount = 0

    local AbsolutePos = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(MouseEvent)
    local LocalPos = UE.USlateBlueprintLibrary.AbsoluteToLocal(MyGeometry, AbsolutePos)
    self.lastPosY = LocalPos.Y
    return UE.UWidgetBlueprintLibrary.Handled()
end

function UIMusicSelection:SelectPrevItem()
    local CurSelectedItem = self:GetCurrentSelectedItem()
    local CurSelectedSong = self:GetCurrentSelectedSong()
    local targetItemIndex = (CurSelectedItem + 1) % self.AllItemCount == 0 and self.AllItemCount or (CurSelectedItem + 1) % self.AllItemCount
    local targetSongIndex = CurSelectedSong + 1
    if targetSongIndex <= self.MaxSongNum then
        self:OnSelectItemById(targetItemIndex)
    end
end

function UIMusicSelection:SelectNextItem()
    local CurSelectedItem = self:GetCurrentSelectedItem()
    local CurSelectedSong = self:GetCurrentSelectedSong()
    local targetItemIndex = (CurSelectedItem - 1) % self.AllItemCount == 0 and self.AllItemCount or (CurSelectedItem - 1) % self.AllItemCount
    local targetSongIndex = CurSelectedSong - 1
    if targetSongIndex > 0 then
        self:OnSelectItemById(targetItemIndex)
    end
end

function UIMusicSelection:OnSelectItemById(ItemIndex)
    local curItem = self:GetCurrentItemByIndex(ItemIndex)
    curItem:SongButton_OnClicked()
end

function UIMusicSelection:EnableOtherBtn(ItemIndex)
    for i = 1, self.AllItemCount, 1 do
        local curItem = self:GetCurrentItemByIndex(i)
        if ItemIndex ~= i then
            curItem:EnableBtn()
        end
    end
end

function UIMusicSelection:StartPlaying_OnClicked()
    self:OnClosePopUpWindow()
    UIManager:OpenUI(UIDef.UIInfo.UI_MiniGames_AudioGames_MusicAnnouncement)
end

function UIMusicSelection:ButtonClose_OnClicked()
    self:OnExitMusicGame()
    self:OnUnLockPlayer()
    self:OnClosePopUpWindow()
end

function UIMusicSelection:OnReturn()
    self:ButtonClose_OnClicked()
end

function UIMusicSelection:OnClosePopUpWindow()
    self.MusicGameVM:SetFirstOpen(1)
    self:CloseMyself(true)
end

function UIMusicSelection:InitData()
    self:InitListData()

    -- MouseMove
    self.lastPosY = 0
    self.updatePosY = 0
    -- Animation
    self.MaxRollTime = 3.6
    self.RollDuraion = 0.15

    -- Selection Part
    self.SongBuffer = 7
    self.MidIndex = math.ceil(self.SongBuffer / 2)
    self.DiffNum = self.MidIndex - 1
    self.factor = 0
    self.SongHead = 1
    self.SongTail = 1
    self.BufferHead = 1
    self.BufferTail = 1
end

function UIMusicSelection:InitListData()
    local MaxChildItemNum = self.Canvas_SongListItem:GetChildrenCount()
    self.AllItemCount = MaxChildItemNum
    -- self.MaxSongNum = 1
end

function UIMusicSelection:GetAllSongListData()
    if self.MusicGameVM then
        local SongDatas = self.MusicGameVM:GetCurSongIndexListData()
        local SongIndexList = self.MusicGameVM:GetCurSongIndexSortList()
        self.MaxSongNum = self.MusicGameVM:GetMaxSongNum()
        return SongDatas, SongIndexList
    end
end

function UIMusicSelection:ClearSongList()
    for i = 1, self.AllItemCount, 1 do
        local curItem = self:GetCurrentItemByIndex(i)
        curItem:ClearThisItem()
    end
end

function UIMusicSelection:InitSongList()
    self:ClearSongList()

    local SongDatas, SongIndexList = self:GetAllSongListData()
    for i, v in pairs(SongIndexList) do
        if i <= 24 then
            local SongData = SongDatas[tonumber(v)]
            local SongName = SongData.songName        
            local MaxSocre = self:GetMaxScoreById(v)
            local curItem = self:GetCurrentItemByIndex(i) -- BP Item Id
            curItem:SetSongItemData(SongName, MaxSocre, i, i)
        end
    end
end

function UIMusicSelection:GetCurrentItemByIndex(index)
    local ItemNamePrefix = "WBP_MusicalSelection_Item_"
    local ItemName
    if index < 10 then
        ItemName = ItemNamePrefix .. "0" .. tostring(index)
    else
        ItemName = ItemNamePrefix .. tostring(index)
    end
    ---@type WBP_MiniGames_AudioGames_MusicalSelection_Item_C
    local curItem = self[ItemName]
    return curItem
end

function UIMusicSelection:GetSongListFlagData(selectedSong)
    if selectedSong < self.MidIndex then
        self.SongHead = 1
        self.SongTail = selectedSong + self.DiffNum
    else
        self.SongHead = selectedSong - self.DiffNum
        self.SongTail = selectedSong + self.DiffNum
    end
    if self.SongTail > self.MaxSongNum then
        self.SongTail = self.MaxSongNum
    end
    if self.SongHead < 1 then
        self.SongHead = 1
    end
    self.factor = math.floor(self.SongTail / self.AllItemCount)
    self.BufferHead = self.SongHead % self.AllItemCount == 0 and self.AllItemCount or self.SongHead % self.AllItemCount
    self.BufferTail = self.SongTail % self.AllItemCount == 0 and self.AllItemCount or self.SongTail % self.AllItemCount
end

function UIMusicSelection:UpdateSongItemList(selectedSong)
    if not self.MaxSongNum or not selectedSong then
        return
    end
    self:GetSongListFlagData(selectedSong)
    -- if self.BufferHead == self.SongHead then
    --     return
    -- end
    if self.SongTail >= self.AllItemCount then
        local SongDatas, SongIndexList = self:GetAllSongListData()
        local EndSongIndex
        if self.BufferHead < 1 then
            EndSongIndex = self.AllItemCount
        else
            if self.MaxSongNum - self.AllItemCount > self.AllItemCount - self.SongBuffer then
                EndSongIndex = self.AllItemCount - self.SongBuffer
            else
                EndSongIndex = self.MaxSongNum - self.AllItemCount
            end
        end
        for i = 1, EndSongIndex do
            local songIndex = self.AllItemCount + i * self.factor -- logical list id
            local SongID = SongIndexList[songIndex] -- real song Id
            local SongData = SongDatas[SongID]
            local SongName = SongData.songName
            local MaxSocre = SongData.maxScore
            local curItem = self:GetCurrentItemByIndex(i)
            curItem:UpdateSongItemData(SongName, MaxSocre, songIndex)
        end
    else
        self:InitSongList()
    end
end

function UIMusicSelection:GetItemShowRange()
    local StartIndex = self.BufferHead
    local EndIndex = self.BufferTail
    if self.MaxSongNum < self.SongBuffer then
        EndIndex = self.BufferTail
    end
    if self.SelectSongId < self.MidIndex then
        StartIndex = self.BufferHead
    end
    if self.factor > 0 then
        StartIndex = self.BufferHead
    end
    if self.SongHead > self.SongTail - (self.SongBuffer - 1) then
        EndIndex = self.BufferTail
    end
    return StartIndex, EndIndex
end

function UIMusicSelection:OnSongItemShow(StartIndex, EndIndex)
    if not StartIndex or not EndIndex then
        return
    end
    for i = 1, self.AllItemCount, 1 do
        local curItem = self:GetCurrentItemByIndex(i)
        if curItem then
            curItem:HideThisSongItem()
        end
    end
    if StartIndex > EndIndex then
        self:ShowItem(StartIndex, self.AllItemCount)
        self:ShowItem(1, EndIndex)
    else
        self:ShowItem(StartIndex, EndIndex)
    end
end

function UIMusicSelection:ShowItem(StartIndex, EndIndex)
    for i = StartIndex, EndIndex, 1 do
        local curItem = self:GetCurrentItemByIndex(i)
        if curItem then
            curItem:ShowThisSongItem()
        end
    end
end

function UIMusicSelection:OnPlayAnimation(SongId)
    local LastSelectedItem = self:GetLastSelectedItem()
    local CurSelectedItem = self:GetCurrentSelectedItem()
    local CurSelectedSong = SongId
    local LastSelectedSong = self:GetLastSelectedSong()
    if LastSelectedItem == CurSelectedItem or not LastSelectedItem or not CurSelectedItem then
        return
    end
    self:SplitixAnimationByIndex(LastSelectedSong, CurSelectedSong, LastSelectedItem, CurSelectedItem)
end

function UIMusicSelection:SplitixAnimationByIndex(LastSelectedSong, CurSelectedSong, LastSelectedItem, CurSelectedItem)
    local StartIndex = CurSelectedSong % (self.AllItemCount + 1)
    local LastIndex = LastSelectedSong % (self.AllItemCount + 1)
    local StartFactor = math.floor(CurSelectedSong / (self.AllItemCount + 2))
    local EndFactor = math.floor(LastSelectedSong / (self.AllItemCount + 2))
    if LastIndex == 0 then
        LastSelectedItem = self.AllItemCount + 1
    end
    if StartIndex == 0 then
        CurSelectedItem = self.AllItemCount + 1
    end
    if StartFactor == EndFactor then
        if LastSelectedSong < CurSelectedSong then
            self:SetAnimationPlayTime_Reverse(CurSelectedItem, LastSelectedItem)
        else
            self:SetAnimationPlayTime_Forward(CurSelectedItem, LastSelectedItem)
        end
    elseif EndFactor < StartFactor then
        self:SetAnimationPlayTime_Reverse(self.AllItemCount + 1, LastSelectedItem)
        self:SetAnimationPlayTime_Reverse(CurSelectedItem, 1)
    else
        if StartIndex == 0 then
            CurSelectedItem = 1
        end
        self:SetAnimationPlayTime_Forward(1, LastSelectedItem)
        self:SetAnimationPlayTime_Forward(CurSelectedItem, self.AllItemCount + 1)
    end
end

function UIMusicSelection:SetAnimationPlayTime_Forward(ItemCur, ItemLast)
    local RollStartTime, RollEndTime = self:CalculateAnimationPlayTime(ItemCur, ItemLast)
    self:OnPlayRollAnimation_Forward(RollStartTime, RollEndTime)
end

function UIMusicSelection:SetAnimationPlayTime_Reverse(ItemCur, ItemLast)
    local RollStartTime, RollEndTime = self:CalculateAnimationPlayTime(ItemCur, ItemLast)
    self:OnPlayRollAnimation_Reverse(RollStartTime, RollEndTime)
end

function UIMusicSelection:CalculateAnimationPlayTime(ItemCur, ItemLast)
    local RollStartTime
    local RollEndTime
    local MaxTime = self.MaxRollTime
    local Duration = self.RollDuraion
    if ItemLast > ItemCur then
        RollStartTime = MaxTime - (ItemCur - 1) * Duration
        RollEndTime = MaxTime - (ItemLast - 1) * Duration
        RollEndTime = RollEndTime < 0.01 and 0 or RollEndTime
    else
        RollStartTime = (ItemCur - 1) * Duration
        RollEndTime = (ItemLast - 1) * Duration
        RollEndTime = RollEndTime < 0.01 and 0 or RollEndTime
    end
    if (ItemCur == 1 and ItemLast == self.AllItemCount + 1) or (ItemLast == self.AllItemCount + 1 and ItemCur == 1) then
        RollStartTime = RollEndTime
    end
    if RollStartTime > RollEndTime then
        local tempStart = RollStartTime
        RollStartTime = RollEndTime
        RollEndTime = tempStart
    end
    return RollStartTime, RollEndTime
end

function UIMusicSelection:OnPlayRollAnimation_Forward(RollStartTime, RollEndTime)
    if RollStartTime == RollEndTime then
        return
    end

    self:StopRollAnimtion()
    self:PlayAnimationTimeRange(self.DX_SongListRoll, RollStartTime, RollEndTime, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end

function UIMusicSelection:OnPlayRollAnimation_Reverse(RollStartTime, RollEndTime)
    if RollStartTime == RollEndTime then
        return
    end

    self:StopRollAnimtion()
    self:PlayAnimationTimeRange(self.DX_SongListRollReverse, RollStartTime, RollEndTime, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end

function UIMusicSelection:StopRollAnimtion()
    self:StopAnimation(self.DX_SongListRoll)
    self:StopAnimation(self.DX_SongListRollReverse)
end

function UIMusicSelection:PlayTapAKEventByName(AKname)
    local FunctionLib = FunctionUtil:GlobalUClass('GH_FunctionLib')
    if FunctionLib then
        local bExit, Row = FunctionLib.GetTapAkEventPathByRowName(AKname)
        if bExit then
            self.AKEvent = UE.UObject.Load(tostring(Row.AKEvent))
            UE.UAkGameplayStatics.PostEvent(self.AKEvent, UE.UGameplayStatics.GetPlayerPawn(self, 0), nil, nil, true)
        end
    end
end

function UIMusicSelection:PlayMusicAKEventByName(AKname)
    local FunctionLib = FunctionUtil:GlobalUClass('GH_FunctionLib')
    if FunctionLib then
        local bExit, Row = FunctionLib.GetMusicAkEventPathByRowName(AKname)
        if bExit then
            self.AKEvent = UE.UObject.Load(tostring(Row.Sound))
            UE.UAkGameplayStatics.PostEvent(self.AKEvent, UE.UGameplayStatics.GetPlayerPawn(self, 0), nil, nil, true)
        end
    end
end

function UIMusicSelection:GetMaxScoreById(Id)
    if self.MusicGameVM then
        return self.MusicGameVM:GetMaxScore(Id)
    end
end

function UIMusicSelection:GetLastSelectedItem()
    if self.MusicGameVM then
        return self.MusicGameVM:GetLastSelectedItem()
    end
end

function UIMusicSelection:GetCurrentSelectedItem()
    if self.MusicGameVM then
        return self.MusicGameVM:GetCurrentSelectItem()
    end
end

function UIMusicSelection:GetLastSelectedSong()
    if self.MusicGameVM then
        return self.MusicGameVM:GetLastSelectedSong()
    end
end

function UIMusicSelection:GetCurrentSelectedSong()
    if self.MusicGameVM then
        return self.MusicGameVM:GetCurrentSelectSong()
    end
end

return UIMusicSelection
