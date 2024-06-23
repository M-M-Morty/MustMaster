
local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWidgetBase = require('CP0032305_GH.Script.framework.ui.ui_widget_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local GameData = require("common.data.game_const_data").data

local MusicKeyItem = Class(UIWidgetBase)

function MusicKeyItem:OnConstruct()
    self.WBP_MiniGames_AudioGames_NoteBtn.Switch_TrackNote:SetActiveWidgetIndex(0)
    self.WBP_MiniGames_AudioGames_NoteBtn_1.Switch_TrackNote:SetActiveWidgetIndex(0)
end

function MusicKeyItem:UpdatePosition()
    
end

function MusicKeyItem:Init(item,index)
    self.perfectTime = item.perfectTime
    self.keyPosition = item.keyPosition
    self.index = index
    self.judgeType = nil
    self.keyType = item.keyType
    self.bDown = false
    self.bcomplete = false
    self.endTime = item.perfectTime + GameData.MUSIC_GAME_SPEED.IntValue
    self.Switch_LongPress:SetActiveWidgetIndex(1)
end

function MusicKeyItem:IsIdle()
    return self.bcomplete
end


function MusicKeyItem:EndAction()
    self:SetVisibility(UE.ESlateVisibility.Collapsed)

end

function MusicKeyItem:MoveEnd()
    self:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function MusicKeyItem:PlayMove()
    local speed = 1000 / GameData.MUSIC_GAME_SPEED.IntValue
    self.movePauseTime = self.movePauseTime or 0
    self:PlayAnimation(self.move, self.movePauseTime, 1, UE.EUMGSequencePlayMode.Forward, speed, true)
end


function MusicKeyItem:StopAnimation()
    self.movePauseTime = self:PauseAnimation(self.move)
end


function MusicKeyItem:MissAction()
    self.Switch_LongPress:SetActiveWidgetIndex(0)
    self.WBP_MiniGames_AudioGames_NoteBtn_1.Switch_TrackNote:SetActiveWidgetIndex(2)
    self.WBP_MiniGames_AudioGames_NoteBtn.Switch_TrackNote:SetActiveWidgetIndex(2)
end


function MusicKeyItem:UpdatePos(curTime)
    local t = self.endTime - curTime 
    local allTime = self.endTime - self.perfectTime
    local progress = math.abs(1 - (t / allTime))
    local x = self.startOffset * (1 - progress) + self.endOffset * progress

    local slot = self.WBP_MiniGames_AudioGames_NoteBtn_1.Slot
    local position = slot:GetPosition()
    slot:SetPosition(UE.FVector2D(x, position.Y))
end


return MusicKeyItem
