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
local MusicGameDefine = require('CP0032305_GH.Script.viewmodel.ingame.mini_game.music_game_define')


---@class WBP_MiniGames_AudioGames_MusicSettlement_C
local UIMusicSettlement = Class(UIWindowBase)

function UIMusicSettlement:OnConstruct()
    self:InitWidget()
    self:BuildWidgetProxy()
    self:InitViewModel()
end

function UIMusicSettlement:UpdateParams()
    self.MusicGameVM:GetRewardsData()
end

function UIMusicSettlement:OnShow()
    self:SetSettlementCamera()
    self:SetWindowData()
    self.WBP_SettlementPopUp:PlayInAnimation()
end

function UIMusicSettlement:InitWidget()
    ---@type WBP_Common_MiniGames_SettlementPopUp_C
    self.WBP_SettlementPopUp = self.WBP_Common_MiniGames_SettlementPopUp
    self.WBP_SettlementPopUp:SetBtnExitOnClick(self, self.Back2Hud_OnClicked)
    self.WBP_SettlementPopUp:SetBtnPlayAgainOnClick(self, self.PlayAgain_OnClicked)
end

function UIMusicSettlement:BuildWidgetProxy()
end

function UIMusicSettlement:InitViewModel()
    ---@type MusicGameVM
    self.MusicGameVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.MusicGameVM.UniqueName)
end

function UIMusicSettlement:Back2Hud_OnClicked()
    self:OnExitMusicGame()
    self:OnUnLockPlayer()
    self.WBP_SettlementPopUp:PlayOutAnimation()
    self.MusicGameVM:SetFirstOpen(1)
    self:CloseMyself(true)
end

function UIMusicSettlement:OnReturn()
    self:Back2Hud_OnClicked()
end

function UIMusicSettlement:PlayAgain_OnClicked()
    self.WBP_SettlementPopUp:PlayOutAnimation()
    self:CloseMyself(true)
    self.MusicGameVM:SetFirstOpen(0)

    local curRawData = self.MusicGameVM:GetCurRawData()
    UIManager:OpenUI(UIDef.UIInfo.UI_MiniGames_AudioGames_MusicalSelection, curRawData)
end

function UIMusicSettlement:OnUnLockPlayer()
    local GameState = UE.UGameplayStatics.GetGameState(self:GetWorld())
    if GameState then
        GameState:PlayerStopAimingMode(Enum.E_AimingModeType.MaduKe)
    end
end

function UIMusicSettlement:SetWindowData()
    local SongData = self.MusicGameVM:GetCurSongData()
    local GameMode = self.MusicGameVM:GetMusicGameMode()

    self:SetEvaluateListData(SongData)
    if GameMode then
        self:SetSettlementData_GameMode(SongData)
    else
        self:SetSettlementData_EnjoyMode()
    end
end

function UIMusicSettlement:SetSettlementData_EnjoyMode()
    local GameEndText = self.MusicGameVM:GetTextByIndex("MusicGame_TEXT_1011")
    self.WBP_SettlementPopUp:SetScoreText(GameEndText)
end

function UIMusicSettlement:SetSettlementData_GameMode(SongData)
    local GameScore = self.MusicGameVM:GetCurSocre()
    if not SongData.MaxScore then
        SongData.MaxScore = 0
    end
    if GameScore > SongData.MaxScore then
        self.WBP_SettlementPopUp:SetSideTagVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.WBP_SettlementPopUp:SetSideTagVisibility(UE.ESlateVisibility.Collapsed)
    end
    self.WBP_SettlementPopUp:SetScoreText(GameScore)
end

function UIMusicSettlement:SetEvaluateListData(SongData)
    local DescriptionList = self.MusicGameVM:GetMusicDescriptionData()
    local EvaluateList = self.MusicGameVM:GetMusicEvaluate()
    local RewardList = self.MusicGameVM:GetSongRewards()

    self.WBP_SettlementPopUp:SetCloseBtnVisibility(UE.ESlateVisibility.Collapsed)
    self.WBP_SettlementPopUp:SetMusicNameText(SongData.Name)
    self.WBP_SettlementPopUp:SetPanelListData(DescriptionList, EvaluateList, RewardList)
end

function UIMusicSettlement:GetCurrentSelectedItem()
    if self.MusicGameVM then
        return self.MusicGameVM:GetCurrentSelectItem()
    end
end

function UIMusicSettlement:GetCurrentSelectedSong()
    if self.MusicGameVM then
        return self.MusicGameVM:GetCurrentSelectSong()
    end
end

return UIMusicSettlement
