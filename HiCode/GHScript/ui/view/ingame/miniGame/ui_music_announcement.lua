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

local GameStartEvent = "Play_MusicGame_UI_GameStart"

---@class WBP_MiniGames_AudioGames_MusicAnnouncement_C
local UIMusicAnnouncement = Class(UIWindowBase)

function UIMusicAnnouncement:OnConstruct()
    self:InitViewModel()
end

function UIMusicAnnouncement:OnShow()
    self:PlayInAnimation()
    self:SetItemData()
    self:PlayAKEventByName(GameStartEvent)
    self:WaitInteract(2.0)
end

function UIMusicAnnouncement:InitViewModel()
    ---@type MusicGameVM
    self.MusicGameVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.MusicGameVM.UniqueName)
end

function UIMusicAnnouncement:SetItemData()
    self.SongData = self.MusicGameVM:GetCurSongData()
    local PlayerName
    self.Txt_MusicName:SetText(self.SongData.Name)
    self.Txt_Performer:SetText(self.SongData.Performer)
    self.Txt_PlayerName:SetText(PlayerName)
end

function UIMusicAnnouncement:InteractWaitEnd()
    self:OnClosePopUpWindow()
end

function UIMusicAnnouncement:OnClosePopUpWindow()
    UIManager:OpenUI(UIDef.UIInfo.UI_MiniGames_AudioGames_PerformanceInterface, self.SongData)
    self:CloseWindow()
end

function UIMusicAnnouncement:PlayInAnimation()
    self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end

function UIMusicAnnouncement:CloseWindow()
    self:CloseMyself(true)
end

function UIMusicAnnouncement:PlayAKEventByName(AKname)
    local FunctionLib = FunctionUtil:GlobalUClass('GH_FunctionLib')
    if FunctionLib then
        local bExit, Row = FunctionLib.GetTapAkEventPathByRowName(AKname)
        if bExit then
            self.AKEvent = UE.UObject.Load(tostring(Row.AKEvent))
            UE.UAkGameplayStatics.PostEvent(self.AKEvent, UE.UGameplayStatics.GetPlayerPawn(self, 0), nil, nil, true)
        end
    end
end

return UIMusicAnnouncement
