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

---@class WBP_MiniGames_AudioGames_MusicalSelection_Item_C
local UIMusicSelectionItem = Class(UIWindowBase)

function UIMusicSelectionItem:OnConstruct()
    self:InitWidget()
    self:BuildWidgetProxy()
    self:InitViewModel()
end

function UIMusicSelectionItem:InitWidget()
    self.WBP_Btn_SongList_Item.OnClicked:Add(self, self.SongButton_OnClicked)
    self.WBP_Btn_SongList_Item.OnPressed:Add(self, self.SongButton_OnPressed)
    self.WBP_Btn_SongList_Item.OnReleased:Add(self, self.SongButton_OnReleased)
end

function UIMusicSelectionItem:BuildWidgetProxy()
    ---@type UIWidgetField
    self.CurSelectedItemField = self:CreateUserWidgetField(self.SelectedThisItem)
end

function UIMusicSelectionItem:InitViewModel()
    ---@type MusicGameVM
    self.MusicGameVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.MusicGameVM.UniqueName)
    ViewModelBinder:BindViewModel(self.CurSelectedItemField, self.MusicGameVM.CurrentSelectSongField,
        ViewModelBinder.BindWayToWidget)
end

function UIMusicSelectionItem:SongButton_OnPressed()
    if self.MusicGameVM then
        self.MusicGameVM:SetSongItemPressed(1)
    end
end

function UIMusicSelectionItem:SongButton_OnReleased()
    if self.MusicGameVM then
        self.MusicGameVM:SetSongItemPressed(0)
    end
end

function UIMusicSelectionItem:SongButton_OnClicked()
    if self.MusicGameVM then
        self.MusicGameVM:UpdateSelectSong(self.GameId)
    end
    self.MusicGameVM:UpdateSelectedItem(self.ThisItemIndex)
    self:SetButtonClickedState()
end

function UIMusicSelectionItem:EnableBtn()
    self.WBP_Btn_SongList_Item:SetHoverAnimationTime(0.05)
    self.WBP_Btn_SongList_Item:SetPressAnimationTime(0.05)
end

function UIMusicSelectionItem:DisableBtn()
    self.WBP_Btn_SongList_Item:SetHoverAnimationTime(0)
    self.WBP_Btn_SongList_Item:SetPressAnimationTime(0)
end

function UIMusicSelectionItem:SelectedThisItem(ItemId)
    if ItemId == self.ThisItemIndex then
        self:SetButtonClickedState()
    else
        self:SetButtonUnClickedState()
    end
end

function UIMusicSelectionItem:SetButtonClickedState()
    self:DisableBtn()
    self.Img_SelectedBG:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function UIMusicSelectionItem:SetButtonUnClickedState()
    self.Img_SelectedBG:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function UIMusicSelectionItem:SetSongItemData(Name, Score, SongID, Index)
    self.ThisItemIndex = Index
    self:UpdateSongItemData(Name, Score, SongID)
end

function UIMusicSelectionItem:ClearThisItem()
    self.Txt_MusicName:SetText(nil)
    self.Txt_Fraction:SetText(nil)
    self.ScoreBox:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function UIMusicSelectionItem:UpdateSongItemData(Name, Score, SongID)
    self.GameId = SongID
    self.Txt_MusicName:SetText(Name)
    if not Score then
        Score = -1
    end
    if Score > 0 then
        self.Txt_Fraction:SetText(Score)
        self.ScoreBox:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.ScoreBox:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function UIMusicSelectionItem:GetThisSongItemIndex()
    if not self.ThisItemIndex then
        return
    end
    return self.ThisItemIndex
end

function UIMusicSelectionItem:ShowThisSongItem()
    if self:IsVisible() == UE.ESlateVisibility.SelfHitTestInvisible or self:IsVisible() == UE.ESlateVisibility.IsVisible then
        return
    end
    self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function UIMusicSelectionItem:HideThisSongItem()
    if self:IsVisible() == UE.ESlateVisibility.Collapsed or self:IsVisible() == false then
        return
    end
    self:SetVisibility(UE.ESlateVisibility.Collapsed)
end

return UIMusicSelectionItem
