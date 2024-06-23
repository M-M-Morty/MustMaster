--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local MiniGameBase = require('CP0032305_GH.Script.ui.view.ingame.miniGame.mini_game_panel')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local GameData = require("common.data.game_const_data").data
local json = require("thirdparty.json")
local MusicGameDefine = require('CP0032305_GH.Script.viewmodel.ingame.mini_game.music_game_define')

local PasueEvent = "Pause"
local Resume = "Resume"

local KeyType = {
    Short = 2,
    Long = 1,
}
local JudgeType = {
    Perfect = 3,
    Good = 2,
    bad = 1,
    Miss = 0,
}
local KeyState = {
    Down = "Down",
    Up = "Up",
}
local UIMusicGame = Class(MiniGameBase)

function UIMusicGame:OnConstruct()
    self:InitWidget()
    self:ResetData()
end

function UIMusicGame:InitWidget()
    self.QuitText = "ITEM_MINIGAME_SCQUIT_TEXT"
    self.TitleText = "ITEM_USE_TITILE"
    self.WBP_Common_MiniGames_TopContent_Secondary.WBP_Btn_Suspend.OnClicked:Add(self, self.Pause)
    self.WBP_MiniGames_AudioGames_LetterBtn_06.Txt_Letter:SetText("K")
    self.WBP_MiniGames_AudioGames_LetterBtn_05.Txt_Letter:SetText("J")
    self.WBP_MiniGames_AudioGames_LetterBtn_04.Txt_Letter:SetText("H")
    self.WBP_MiniGames_AudioGames_LetterBtn_03.Txt_Letter:SetText("D")
    self.WBP_MiniGames_AudioGames_LetterBtn_02.Txt_Letter:SetText("S")
    self.WBP_MiniGames_AudioGames_LetterBtn_01.Txt_Letter:SetText("A")
    self.WBP_Common_MiniGames_TopContent_Secondary.WBP_Btn_Guide:SetVisibility(UE.ESlateVisibility.Collapsed)

    self.WBP_MiniGames_AudioGames_LetterBtn_01.WBP_Btn_Letter.OnPressed:Add(self, self.MusicKeyDown1)
    self.WBP_MiniGames_AudioGames_LetterBtn_01.WBP_Btn_Letter.OnReleased:Add(self, self.MusicKeyup1)

    self.WBP_MiniGames_AudioGames_LetterBtn_02.WBP_Btn_Letter.OnPressed:Add(self, self.MusicKeyDown2)
    self.WBP_MiniGames_AudioGames_LetterBtn_02.WBP_Btn_Letter.OnReleased:Add(self, self.MusicKeyup2)

    self.WBP_MiniGames_AudioGames_LetterBtn_03.WBP_Btn_Letter.OnPressed:Add(self, self.MusicKeyDown3)
    self.WBP_MiniGames_AudioGames_LetterBtn_03.WBP_Btn_Letter.OnReleased:Add(self, self.MusicKeyup3)
    
    self.WBP_MiniGames_AudioGames_LetterBtn_04.WBP_Btn_Letter.OnPressed:Add(self, self.MusicKeyDown4)
    self.WBP_MiniGames_AudioGames_LetterBtn_04.WBP_Btn_Letter.OnReleased:Add(self, self.MusicKeyup4)

    self.WBP_MiniGames_AudioGames_LetterBtn_05.WBP_Btn_Letter.OnPressed:Add(self, self.MusicKeyDown5)
    self.WBP_MiniGames_AudioGames_LetterBtn_05.WBP_Btn_Letter.OnReleased:Add(self, self.MusicKeyup5)

    self.WBP_MiniGames_AudioGames_LetterBtn_06.WBP_Btn_Letter.OnPressed:Add(self, self.MusicKeyDown6)
    self.WBP_MiniGames_AudioGames_LetterBtn_06.WBP_Btn_Letter.OnReleased:Add(self, self.MusicKeyup6)
end

function UIMusicGame:UpdateParams(SongData,bSelectMode)
    local MusicGameVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.MusicGameVM.UniqueName)
    if bSelectMode == "true" then
        SongData = tonumber(SongData)
        MusicGameVM:SetCurSongData(SongData)
        SongData = MusicGameVM:GetCurSongData()
    end
    if SongData == nil then
        G.log:warn("xmj SongData is nil ")
        return
    end
    MusicGameVM:SetMusicGameMode(bSelectMode)
    self:ResetData()
    self:GameStart(SongData)
end

function UIMusicGame:ResetData()
    self.curSongData = nil
    self.bStart = false
    self.downTime = GameData.MUSIC_GAME_SPEED.IntValue
    self.curTime = 0
    self.curIndex = 1
    self.perfectNum = 0
    self.goodNum = 0
    self.badNum = 0
    self.missNum = 0
    self.combo = 0
    self.perfectScore = 0
    self.goodScore = 0
    self.comboScore = 0
    self.curScore = 0
    self.maxCombo = 0
    self.ArrayKey1 = {}
    self.ArrayKey2 = {}
    self.ArrayKey3 = {}
    self.ArrayKey4 = {}
    self.ArrayKey5 = {}
    self.ArrayKey6 = {}
    self.LineDataPositionTime = {0,0,0,0,0,0}
    local MusicGameVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.MusicGameVM.UniqueName)
    local bMode = MusicGameVM:GetMusicGameMode()
    if bMode == false then
        self.WBP_Common_MiniGames_TopContent_Secondary.VertBox_Accuracy:SetVisibility(UE.ESlateVisibility.Hidden)
    else
        self.WBP_Common_MiniGames_TopContent_Secondary.VertBox_Accuracy:SetVisibility(UE.ESlateVisibility.Visible)
    end
end

function UIMusicGame:GameStart(SongData)
    self.bStart = true
    self.songID = SongData.SongId
    self.curSongData = SongData.Keys
    self.temainTime = SongData.Time
    if #self.curSongData == 0 then
        G.log:warn("xmj", "GameStart SongData is null")
        return
    end
    self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    self.perfectScore = GameData.MUSIC_GAME_ACCURACY_GRADE.IntValue / #self.curSongData
    self.goodScore = GameData.MUSIC_GAME_ACCURACY_GRADE.IntValue / #self.curSongData * GameData.MUSIC_GAME_GOOD_GRADE.FloatValue
    self.badScore = GameData.MUSIC_GAME_ACCURACY_GRADE.IntValue / #self.curSongData * GameData.MUSIC_GAME_BAD_GRADE.FloatValue
    local num = #self.curSongData * (#self.curSongData + 1) / 2  
    self.comboScore = GameData.MUSIC_GAME_GOMBO_GRADE.IntValue / num
    self:MusicStart(SongData.Id)
    local GameState = UE.UGameplayStatics.GetGameState(self:GetWorld())
    if GameState then
        GameState:PlayerStartAimingMode(Enum.E_AimingModeType.MaduKe)
    end
    self:PlayAKEventByName(SongData.Name)

    self:OnCloseMusicGameCamera()
    self:OnPlaySequence()
end

function UIMusicGame:OnPlaySequence()
    local Setting = UE.FMovieSceneSequencePlaybackSettings()
    Setting.LoopCount.Value = -1
    local LevelSequencerPlayer, SequenceActor = UE.ULevelSequencePlayer.CreateLevelSequencePlayer(self:GetWorld(), self.LevelSequence, Setting) -- 创建 LevelSequencePlayer
    self.SequencePlayer = LevelSequencerPlayer

    local BindingActors = UE.TArray(UE.AActor)
    BindingActors:Add(UE.UGameplayStatics.GetPlayerCharacter(self:GetWorld(), 0))
    local SequenceBindingTag = "Player" -- Sequence 中的 Tag
    SequenceActor:SetBindingByTag(SequenceBindingTag, BindingActors)

    if not UE.UKismetSystemLibrary.IsServer(SequenceActor) then
        self.SequencePlayer:Play()
    end
end

function UIMusicGame:ClearSequencePlayer()
    self.RemoveTimer = nil
    if self.SequencePlayer then
        self.SequencePlayer:Stop()
        self.SequencePlayer = nil
    end
end

function UIMusicGame:PauseSequencePlayer()
    self.SequencePlayer:Pause()
end

function UIMusicGame:ContinueSequencePlayer()
    self.SequencePlayer:Play()
end

function UIMusicGame:PlayAKEventByName(AKname)

    local FunctionLib = FunctionUtil:GlobalUClass('GH_FunctionLib')
    if FunctionLib then
        local bExit, Row = FunctionLib.GetMusicAkEventPathByRowName(AKname)
        if bExit then
            self.AKEvent = UE.UObject.Load(tostring(Row.Sound))
            UE.UAkGameplayStatics.PostEvent(self.AKEvent, UE.UGameplayStatics.GetPlayerPawn(self, 0), nil, nil, true)
        end
    end
    
end

function UIMusicGame:MusicStart(id)

end

function UIMusicGame:JudgeDownKey(id)
    local widget = self:FindKey(id)
    if widget == nil then
        local ins = self["WBP_MiniGames_AudioGames_LetterBtn_0"..id]
        ins:PlayAnimation(ins.DX_ClickMiss, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
        return
    end
    self.LineDataPositionTime[id] = self.curTime
    self:JudgeKey(widget, KeyState.Down)
end

function UIMusicGame:JudgeUpKey(id)
    local widget = self:FindKey(id)
    if widget == nil then
        return
    end
    self:JudgeKey(widget, KeyState.Up)
end

function UIMusicGame:FindKey(id)
    local num = #self["ArrayKey" .. id]
    local item = nil
    G.log:warn("xmj", "FindKeyPoision %s", tostring(id))
    for i = 1, num do
        item = self["ArrayKey" .. id][i]
        if item.bcomplete == false then
            if item.perfectTime - self.curTime < GameData.MUSIC_GAME_BAD_TIME.IntValue then
                G.log:warn("xmj", "FindKeyPoision %s", tostring(item.index))
                return item
            end
        end
    end
end

function UIMusicGame:JudegNote(diff)
    if diff < GameData.MUSIC_GAME_PERFECT_TIME.IntValue then
        return JudgeType.Perfect
    elseif diff < GameData.MUSIC_GAME_GOOD_TIME.IntValue then
        return JudgeType.Good
    elseif diff < GameData.MUSIC_GAME_BAD_TIME.IntValue then
        return JudgeType.bad
    else
        return JudgeType.Miss
    end
end

function UIMusicGame:JudegShortKey(widget, diff)
    local t = self:JudegNote(diff)
    self:Notetext(t)
    self:PlayShortDX(widget, t)
    self:KeyComplete(widget)
end

function UIMusicGame:JudegLongKey(widget, diff, tKey)
    if tKey == KeyState.Down then
        if widget.bDown == true then
            return
        end
        local t = self:JudegNote(diff)
        self:PlayLongDownDX(widget, t)
        widget.judgeType = t
        widget.bDown = true
        if t == JudgeType.Perfect or t == JudgeType.Good then
            return
        end
        if widget.judgeType == JudgeType.Miss then
            widget:MissAction()
        elseif widget.judgeType == JudgeType.bad then
            widget:MissAction()
        end
        self:Notetext(widget.judgeType)
    end
    if tKey == KeyState.Up and widget.bDown then
        local t = math.abs(self.curTime - widget.endTime)
        
        if t > GameData.MUSIC_GAME_BAD_TIME.IntValue then
            if widget.judgeType == JudgeType.bad then
                return 
            end
            widget.judgeType = JudgeType.Miss
            widget:MissAction()
        elseif t > GameData.MUSIC_GAME_GOOD_TIME.IntValue then
            widget.judgeType = JudgeType.bad
            widget:MissAction()
        elseif widget.judgeType == JudgeType.Perfect or widget.judgeType == JudgeType.Good then
            self:Notetext(widget.judgeType)
            self:KeyComplete(widget)
            self:PlayLongDX(widget, widget.judgeType)
        end

    end
end

function UIMusicGame:JudgeKey(widget, tKey)
    if widget == nil then
        G.log:warn("xmj", "JudgeKey widget is nil")
        return
    end
    if widget.bcomplete then
        return
    end
    local time = self.curTime
    local diff = math.abs(time - widget.perfectTime)
    if widget.keyType == KeyType.Short and tKey == KeyState.Down then
        self:JudegShortKey(widget, diff)
    elseif widget.keyType == KeyType.Long then
        self:JudegLongKey(widget, diff, tKey)
    end
end

function UIMusicGame:KeyComplete(widget)
    local idx = widget.index
    widget.bcomplete = true
    self.curSongData[idx].bcomplete = true
    if widget.EndAction then
        widget:EndAction()
    end
    local ins = self["WBP_MiniGames_AudioGames_LetterBtn_0" .. widget.keyPosition]
    ins:PlayAnimation(ins.DX_PressedLoopStop, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)

    self:RemoveByWidget(widget)
end

function UIMusicGame:RemoveByWidget(widget)
    TableUtil:ArrayRemoveValue(self["ArrayKey" .. widget.keyPosition], widget)
end

function UIMusicGame:JudegCombo(t)
    if t == JudgeType.Miss or t == JudgeType.bad then
        self.combo = 0
        self.WBP_Common_MiniGames_DoubleHit.Canvas_DoubleHit:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.combo = self.combo + 1
        self.curScore = self.curScore + self.comboScore * self.combo
        self:UpdateScore()
    end
    self.maxCombo = math.max(self.maxCombo, self.combo)
    self:ShowCombo()
end

function UIMusicGame:ShowCombo()
    local doubleHit = self.WBP_Common_MiniGames_DoubleHit
    if self.combo > 3 then
        doubleHit.Canvas_DoubleHit:SetVisibility(UE.ESlateVisibility.Visible)
        doubleHit.Txt_DoubleHit_Digit:SetText(self.combo)
        doubleHit:PlayAnimation(doubleHit.DX_DoubleHit, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    else
        doubleHit.Canvas_DoubleHit:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end

function UIMusicGame:PlayShortDX(widget, t)
    local ins = self["WBP_MiniGames_AudioGames_LetterBtn_0" .. widget.keyPosition]
    self:PlayCilckDX(ins,t)
end

function UIMusicGame:PlayLongDX(widget, t)
    local ins = self["WBP_MiniGames_AudioGames_LetterBtn_0" .. widget.keyPosition]
    if widget.bcomplete then
        self:PlayCilckDX(ins,t)
    else
        ins:PlayAnimation(ins.DX_PressedLoop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1, false)
    end
end


function UIMusicGame:PlayLongDownDX(widget, t)
    local ins = self["WBP_MiniGames_AudioGames_LetterBtn_0" .. widget.keyPosition]
    if widget.bDown == false then
        self:PlayCilckDX(ins,t)
        ins:PlayAnimation(ins.DX_PressedLoop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1, false)
    end
end


function UIMusicGame:PlayCilckDX(ins, t)
    if t == JudgeType.Perfect then
        ins:PlayAnimation(ins.DX_ClickPerfect, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    elseif t == JudgeType.Good then
        ins:PlayAnimation(ins.DX_ClickGood, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    elseif t == JudgeType.bad then
        ins:PlayAnimation(ins.DX_ClickBad, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    elseif t == JudgeType.Miss then
        ins:PlayAnimation(ins.DX_ClickMiss, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    end

end


function UIMusicGame:Notetext(t)
    self:ShowNotetext(t)
    self:UpdateNoteData(t)
    self:JudegCombo(t)
end

function UIMusicGame:ShowNotetext(t)
    G.log:warn("xmj", "ShowNotetext %s", tostring(t))
    self.Switch_Evaluate:SetVisibility(UE.ESlateVisibility.Visible)
    self.Switch_Evaluate:SetActiveWidgetIndex(t)
    if t == JudgeType.Perfect then
        self:PlayAnimation(self.DX_EvaluatePerfect, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    elseif t == JudgeType.Good then
        self:PlayAnimation(self.DX_EvaluateGood, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    elseif t == JudgeType.bad then
        self:PlayAnimation(self.DX_EvaluateBad, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    elseif t == JudgeType.Miss then
        self:PlayAnimation(self.DX_EvaluateMiss, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    end
end

function UIMusicGame:Tick(MyGeometry, InDeltaTime)
    if self.bPause then
        return
    end
    if self.bStart then
        self.curTime = self.curTime + InDeltaTime * 1000
        self.temainTime = self.temainTime - InDeltaTime * 1000
        self:UpdateKey()
        if self.temainTime < 0 then
            self.bStart = false
            self:GameEnd()
        end
    end
end

function UIMusicGame:UpdateKey()
    self:UpdateSongData()
    self:UpdateKeyState()
end

function UIMusicGame:UpdateSongData()
    local tbWidget = {}
    local minPositon = 100000
    local maxPositon = 0
    local widget
    for i = self.curIndex, #self.curSongData do
        local item = self.curSongData[i]
        if math.abs(self.curTime - item.perfectTime + self.downTime) < 100 then
            self.curIndex = i + 1
            if item.keyType == KeyType.Short then
                widget = self:CreateOrGetShortKeyWidget(item, i)
            elseif item.keyType == KeyType.Long then
                widget = self:CreateOrGetLongKeyWidget(item, i)
            end
            table.insert(tbWidget, widget)
            if item.keyPosition < minPositon then
                minPositon = item.keyPosition
            end
            if item.keyPosition > maxPositon then
                maxPositon = item.keyPosition
            end
        end
        if item.perfectTime - self.downTime - self.curTime > 100 then
            break
        end
    end

    if 1 > #tbWidget then
        -- local lineWidget = self:CreateOrGetLineWidget()
        -- lineWidget:Init(minPositon, maxPositon)
    end
end

function UIMusicGame:CreateOrGetLineWidget()
    for i = 1, self.lineItemArray:Length() do
        local widget = self.lineItemArray:Get(i)
        if widget:IsIdle() then
            return widget
        end
    end
    local newWidget = UE.NewObject(UIManager:ClassRes("MusicKeyItem"), self)
    self.lineItemArray:Add(newWidget)
    return newWidget
end

function UIMusicGame:CreateOrGetShortKeyWidget(item, idx)
    -- for i = 1, self.KeyItemArray:Length() do
    --     local widget = self.KeyItemArray:Get(i)
    --     if widget:IsIdle() and widget.keyType == KeyType.Short then
    --         print("xmjCreateOrGetShortKeyWidget"..idx)
    --         return widget
    --     end
    -- end
    local newWidget = UE.NewObject(UIManager:ClassRes("MusicKeyItem"), self)
    self.KeyItemArray:Add(newWidget)
    self:InitShortKeyItem(newWidget, item, idx)
    return newWidget
end

function UIMusicGame:InitShortKeyItem(widget, item, index)
    widget:Init(item, index)
    local keyPos = item.keyPosition
    table.insert(self["ArrayKey" .. keyPos], widget)
    local NewSlot = self["Canvas_Track_Note_0" .. keyPos]:AddChildToCanvas(widget)
    NewSlot:SetAutoSize(true)
    NewSlot:SetAlignment(UE.FVector2D(0.5, 0.5))
    widget:SetVisibility(UE.ESlateVisibility.Visible)
end

function UIMusicGame:CreateOrGetLongKeyWidget(item, idx)
    return self:InitLongKeyItem(item, idx)
end

function UIMusicGame:InitLongKeyItem(item, index)
    local keyPos = item.keyPosition
    local widgetTrack = UE.UWidgetBlueprintLibrary.Create(self, UIManager:ClassRes("SongTrack" .. keyPos))
    table.insert(self["ArrayKey" .. keyPos], widgetTrack)
    widgetTrack:Init(item, index)
    self.SongTrackItemArray:Add(widgetTrack)
    local NewSlot = self["Canvas_Track_LongPress_0" .. keyPos]:AddChildToCanvas(widgetTrack)
    NewSlot:SetAutoSize(true)
    NewSlot:SetAlignment(UE.FVector2D(0, 0))
    widgetTrack:PlayMove()
    widgetTrack:SetVisibility(UE.ESlateVisibility.Visible)
    return widgetTrack
end

function UIMusicGame:UpdateKeyState()
    for i = 1, 6 do
        local num = #self["ArrayKey" .. i]
        for j = 1, num do
            local widget = self["ArrayKey" .. i][j]
            if widget ~= nil then
                self:UpdateKeyItemPos(widget)
                self:UpdateKeyItemState(widget)
                if widget.UpdatePos then
                    widget:UpdatePos(self.curTime)
                end
            end
        end
    end

    for i = 1, 5 do 
        self["WBP_MiniGames_AudioGames_NoteLine_0"..i]:SetVisibility(UE.ESlateVisibility.Hidden)
    end

    for i = 1, 5 do 
        for j = 6, i + 1, -1 do
            if self:JudegLine(i,j) then
                return
            end
        end
    end
end

function UIMusicGame:JudegLine(minPositon,maxPositon)
    local minTime = self.LineDataPositionTime[minPositon]
    local maxTime = self.LineDataPositionTime[maxPositon]
    if self.curTime - minTime > GameData.MUSIC_GAME_BAD_TIME.IntValue then
        return false
    end
    if self.curTime - maxTime > GameData.MUSIC_GAME_BAD_TIME.IntValue then
        return false
    end
    if math.abs(minTime - maxTime) < GameData.MUSIC_GAME_BAD_TIME.IntValue then
        if (minTime + maxTime) == 0 then
            return false
        end
        for i = minPositon, maxPositon - 1 do
            self["WBP_MiniGames_AudioGames_NoteLine_0"..i]:SetVisibility(UE.ESlateVisibility.Visible)
        end
        return true
    end
    return false
end

function UIMusicGame:UpdateKeyItemPos(widget)
    if widget.keyType == KeyType.Long then
        return
    end

    local SlotSize = self["Canvas_Track_Note_0" .. widget.keyPosition].Slot:GetSize()
    local precent = (widget.perfectTime - self.curTime) / self.downTime
    local targetPos
    if widget.keyPosition < 4 then
        targetPos = UE.FVector2D(SlotSize.X * precent, SlotSize.Y * (1 - precent))
    else
        targetPos = UE.FVector2D(SlotSize.X * (1 - precent), SlotSize.Y * (1 - precent))
    end
    if precent < 0 then
        widget:SetVisibility(UE.ESlateVisibility.Hidden)
    end
    widget.Slot:SetPosition(targetPos)
end

function UIMusicGame:UpdateKeyItemState(widget)
    if widget.bcomplete then
        return
    end

    if widget.keyType == KeyType.Short then
        if self.curTime - widget.perfectTime > GameData.MUSIC_GAME_BAD_TIME.IntValue then
            local type = JudgeType.Miss
            widget:MissAction()
            self:Notetext(type)
            self:KeyComplete(widget)
        end
    end
    if widget.keyType == KeyType.Long then
        if widget.bDown then
            if self.curTime > widget.endTime then
                self:KeyComplete(widget)
                if widget.judgeType == JudgeType.bad then
                    return
                end
                self:Notetext(widget.judgeType)
                self:PlayLongDX(widget,widget.judgeType)
            end
            if self.curTime - widget.endTime > GameData.MUSIC_GAME_BAD_TIME.IntValue then
                local type = widget.judgeType
                widget:MissAction()
                self:Notetext(type)
                self:KeyComplete(widget)
            end
        elseif widget.judgeType == nil then
            if self.curTime - widget.perfectTime > GameData.MUSIC_GAME_BAD_TIME.IntValue then
                local type = JudgeType.Miss
                widget.judgeType = JudgeType.Miss
                widget:MissAction()
                self:Notetext(type)
            end
        elseif self.curTime - widget.endTime > GameData.MUSIC_GAME_BAD_TIME.IntValue then
            self:KeyComplete(widget)
        end
    end
end

function UIMusicGame:GameEnd()
    ---@type MusicGameVM
    local MusicGameVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.MusicGameVM.UniqueName)
    local AllCount = self.perfectNum + self.goodNum + self.badNum + self.missNum 
    local score = 0
    if AllCount == 0 then
        score = 0
    else
        score = (self.perfectNum + self.goodNum) / (self.perfectNum + self.goodNum + self.badNum + self.missNum)        
    end
    MusicGameVM:SetAccuracy(math.floor(score*100))
    if self.combo < 4 then
        self.combo = 0
    end
    MusicGameVM:SetCombo(self.maxCombo)

    MusicGameVM:SetSongEvaluateData(self.badNum, MusicGameDefine.EvaluateType.Bad)
    MusicGameVM:SetSongEvaluateData(self.perfectNum, MusicGameDefine.EvaluateType.Perfect)
    MusicGameVM:SetSongEvaluateData(self.goodNum, MusicGameDefine.EvaluateType.Good)
    MusicGameVM:SetSongEvaluateData(self.missNum, MusicGameDefine.EvaluateType.Miss)
    MusicGameVM:SetCurScore(math.floor(self.curScore + 0.5))
    UIManager:OpenUI(UIDef.UIInfo.UI_MiniGames_AudioGames_MusicSettlement)
    local Param = {
        Score = math.floor(self.curScore + 0.5),
        ID = self.songID
    }
    local data = json.encode(Param)
    local PlayerState = UE.UGameplayStatics.GetPlayerState(self:GetWorld(), 0)
    PlayerState:LogicComplete(Enum.E_MiniGame.MusicGame, data)
    self:_Close()
end

function UIMusicGame:HideByKey(ArrayKey)
    for _, value in pairs(ArrayKey) do
        value:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end

function UIMusicGame:OnGameKeyHide()
    self:HideByKey(self.ArrayKey1)
    self:HideByKey(self.ArrayKey2)
    self:HideByKey(self.ArrayKey3)
    self:HideByKey(self.ArrayKey4)
    self:HideByKey(self.ArrayKey5)
    self:HideByKey(self.ArrayKey6)
    self.Canvas_MusicGame:SetVisibility(UE.ESlateVisibility.Hidden)
end

function UIMusicGame:_Close()
    self:OnGameKeyHide()
    self:ClearSequencePlayer()
    self:CloseMyself(true)
end

function UIMusicGame:Pause()
    self.bPause = true
    for i = 1, 6 do
        local num = #self["ArrayKey" .. i]
        for j = 1, num do
            local widget = self["ArrayKey" .. i][j]
            if widget.StopAnimation then
                widget:StopAnimation()
            end
        end
    end
    self:PauseSequencePlayer()
    self:PlayAKEventByName(PasueEvent)
    UIManager:OpenUI(UIDef.UIInfo.UI_Common_MiniGames_PausePopup, self.ReStart, self.Continue, self.Exit, self)
end

function UIMusicGame:GetCurrentSelectedItem()
    ---@type MusicGameVM
    local MusicGameVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.MusicGameVM.UniqueName)
    return MusicGameVM:GetCurrentSelectItem()
end

function UIMusicGame:GetCurrentSelectedSong()
    ---@type MusicGameVM
    local MusicGameVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.MusicGameVM.UniqueName)
    return MusicGameVM:GetCurrentSelectSong()
end

function UIMusicGame:ReStart()
    ---@type MusicGameVM
    local MusicGameVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.MusicGameVM.UniqueName)

    MusicGameVM:SetFirstOpen(0)
    self:CloseMyself(true)
    self:OnGameKeyHide()
    self:ClearSequencePlayer()
    local GameMode = self.MusicGameVM:GetMusicGameMode()
    if GameMode then
        local curRawData = self.MusicGameVM:GetCurRawData()
        UIManager:OpenUI(UIDef.UIInfo.UI_MiniGames_AudioGames_MusicalSelection, curRawData)
    end
end

function UIMusicGame:Continue()
    self.bPause = false
    for i = 1, 6 do
        local num = #self["ArrayKey" .. i]
        for j = 1, num do
            local widget = self["ArrayKey" .. i][j]
            if widget.PlayMove then
                widget:PlayMove()
            end
        end
    end
    self:ContinueSequencePlayer()
    self:PlayAKEventByName(Resume)
end

function UIMusicGame:OnUnLockPlayer()
    local GameState = UE.UGameplayStatics.GetGameState(self:GetWorld())
    if GameState then
        GameState:PlayerStopAimingMode(Enum.E_AimingModeType.MaduKe)
    end
end

function UIMusicGame:Exit()
    local MusicGameVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.MusicGameVM.UniqueName)
    MusicGameVM:SetFirstOpen(1)

    self:OnCloseMusicGameCamera()
    self:OnUnLockPlayer()
    self:_Close()
end

function UIMusicGame:UpdateNoteData(type)
    if type == JudgeType.Perfect then
        self.perfectNum = self.perfectNum + 1
        self.curScore = self.curScore + self.perfectScore
    elseif type == JudgeType.Good then
        self.goodNum = self.goodNum + 1
        self.curScore = self.curScore + self.goodScore
    elseif type == JudgeType.bad then
        self.badNum = self.badNum + 1
        self.curScore = self.curScore + self.badScore
    elseif type == JudgeType.Miss then
        self.missNum = self.missNum + 1
    end
    self:UpdateScore()
    self:UpdateAccuracyScore()
end

function UIMusicGame:UpdateScore()
    local score = math.floor(self.curScore)
    self.WBP_Common_MiniGames_TopContent_Secondary.Txt_AccuracyDigit:SetText(score)
end

function UIMusicGame:UpdateAccuracyScore()
    local AllCount = self.perfectNum + self.goodNum + self.badNum + self.missNum 
    if AllCount == 0 then
        return
    end
    local score = (self.perfectNum + self.goodNum) / (self.perfectNum + self.goodNum + self.badNum + self.missNum)
    self.WBP_Common_MiniGames_TopContent_Secondary.Txt_Percentage:SetText(math.floor(score * 100))
end

function UIMusicGame:MusicKeyDown1()
    self:JudgeDownKey(1)
end

function UIMusicGame:MusicKeyup1()
    self:JudgeUpKey(1)
end

function UIMusicGame:MusicKeyDown2()
    self:JudgeDownKey(2)
end

function UIMusicGame:MusicKeyup2()
    self:JudgeUpKey(2)
end

function UIMusicGame:MusicKeyDown3()
    self:JudgeDownKey(3)
end

function UIMusicGame:MusicKeyup3()
    self:JudgeUpKey(3)
end

function UIMusicGame:MusicKeyDown4()
    self:JudgeDownKey(4)
end

function UIMusicGame:MusicKeyup4()
    self:JudgeUpKey(4)
end

function UIMusicGame:MusicKeyDown5()
    self:JudgeDownKey(5)
end

function UIMusicGame:MusicKeyup5()
    self:JudgeUpKey(5)
end

function UIMusicGame:MusicKeyDown6()
    self:JudgeDownKey(6)
end

function UIMusicGame:MusicKeyup6()
    self:JudgeUpKey(6)
end

function UIMusicGame:OnReturn()
    self:Pause()
end

return UIMusicGame
