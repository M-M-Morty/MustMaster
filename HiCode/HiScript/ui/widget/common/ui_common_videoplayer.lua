--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local DataTableUtils = require("common.utils.data_table_utils")

---@type WBP_Common_Video_Player_C
local UICommonVideoPlayer = Class(UIWindowBase)

function UICommonVideoPlayer:OnConstruct()

    local World = self:GetWorld()
    local AlwaysSpawn = UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn
    self.VideoSoundActor = World:SpawnActor(self.VideoSoundClass, self.Transform, AlwaysSpawn, self, self)

    self.PlayButtonBig.Button.OnClicked:Add(self, self.OnPlayButtonClicked)
    self.PlayButton.Button.OnClicked:Add(self, self.OnPlayButtonClicked)
    self.PauseButton.Button.OnClicked:Add(self, self.OnPauseButtonClicked)

    self.MediaPlayer.OnEndReached:Add(self, self.OnFinished)

    -- self.Slider.OnValueChanged:Add(self, self.OnSliderValueChange)
    self.totalTimeSpan = UE.UKismetMathLibrary.MakeTimespan(0, 0, 0, 0, 0)
    self.mediaArr = {}
    self.Finished = false
end

function UICommonVideoPlayer:OnPlayButtonClicked()
    if self.MediaPlayer:IsPaused() then
        self.MediaPlayer:Play()
        self.WidgetSwitcher:SetActiveWidgetIndex(1)
        UE.UKismetSystemLibrary.K2_UnPauseTimerHandle(self, self.TimerHandle)
    elseif self.Finished and self.PlayList:Num() > 0 then
        self.Finished = false
        self.MediaPlayer:OpenPlaylist(self.PlayList)
        self.PlayButtonBig:SetVisibility(UE.ESlateVisibility.Hidden)
        UE.UKismetSystemLibrary.K2_UnPauseTimerHandle(self, self.TimerHandle)
        self.WidgetSwitcher:SetActiveWidgetIndex(1)
    end
end

function UICommonVideoPlayer:OnPauseButtonClicked()
    if self.MediaPlayer:IsPlaying() then
        self.MediaPlayer:Pause()
        self.WidgetSwitcher:SetActiveWidgetIndex(0)
        UE.UKismetSystemLibrary.K2_PauseTimerHandle(self, self.TimerHandle)
    end
end

function UICommonVideoPlayer:UpdateProgress()
    local playbackTime = self.MediaPlayer:GetTime()
    local totalSeconds = UE.UKismetMathLibrary.GetTotalMilliseconds(self.totalTimeSpan)

    for i = 1, self.MediaPlayer:GetPlaylistIndex() do
        playbackTime = UE.UKismetMathLibrary.Add_TimespanTimespan(playbackTime, self.mediaArr[i].Duration)
    end

    local playSeconds =  UE.UKismetMathLibrary.GetTotalMilliseconds(playbackTime)
    local percent = playSeconds / totalSeconds
    
    self.Slider:SetValue(percent)
    self.ProgressBar:SetPercent(percent)
    
    self.Time:SetText(string.format("%02d:%02d", UE.UKismetMathLibrary.GetMinutes(playbackTime), UE.UKismetMathLibrary.GetSeconds(playbackTime)))
end

function UICommonVideoPlayer:OnFinished()
    if self.MediaPlayer:GetPlaylistIndex() == self.PlayList:Num() - 1 then
        self.Finished = true
        self.PlayButtonBig:SetVisibility(UE.ESlateVisibility.Visible)
        self.WidgetSwitcher:SetActiveWidgetIndex(0)
        UE.UKismetSystemLibrary.K2_PauseTimerHandle(self, self.TimerHandle)
        self.Time:SetText(string.format("%d:%d", UE.UKismetMathLibrary.GetMinutes(self.totalTimeSpan), UE.UKismetMathLibrary.GetSeconds(self.totalTimeSpan)))
    end
end

function UICommonVideoPlayer:OnSliderValueChange()
    UE.UKismetSystemLibrary.K2_PauseTimerHandle(self, self.TimerHandle)
    local percent = self.Slider:GetValue()
    self.ProgressBar:SetPercent(percent)
    local playbackTime = UE.UKismetMathLibrary.GetSeconds(self.VideoPlayer:GetTime())
    self.VideoPlayer:Seek(UE.UKismetMathLibrary.Multiply_TimespanFloat(self.VideoPlayer:GetDuration(), percent))
    playbackTime = UE.UKismetMathLibrary.GetSeconds(self.VideoPlayer:GetTime())
end

-- MediaKeyArr为DT_Media中的RowName的table eg: {'Speaker', 'TVLast3', 'Speaker'})
function UICommonVideoPlayer:PlayVideos(MediaKeyArr)
    if next(MediaKeyArr) == nil then
        return
    end
    self:ClearPlaylist()

    for idx, mKey in pairs(MediaKeyArr)  do
        local video = DataTableUtils.GetMediaDataByDataTableID(mKey)
        if video then
            local Source = UE.UMediaSource.Load(video.MediaSource)
            self.PlayList:Add(Source)
            self.totalTimeSpan = UE.UKismetMathLibrary.Add_TimespanTimespan(self.totalTimeSpan, video.Duration)
            self.mediaArr[idx] = video
        end
    end

    self.MediaPlayer:OpenPlaylist(self.PlayList)

    self.PlayButtonBig:SetVisibility(UE.ESlateVisibility.Hidden)
    self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, UICommonVideoPlayer.UpdateProgress}, 0.1, true)
    self.WidgetSwitcher:SetActiveWidgetIndex(1)
    self.Duration:SetText(string.format("/%02d:%02d", UE.UKismetMathLibrary.GetMinutes(self.totalTimeSpan), UE.UKismetMathLibrary.GetSeconds(self.totalTimeSpan)))
end

function UICommonVideoPlayer:OnDestruct()
    self.VideoSoundActor:K2_DestroyActor()
    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.TimerHandle)

    self.PlayButtonBig.Button.OnClicked:Remove(self, self.OnPlayButtonClicked)
    self.PlayButton.Button.OnClicked:Remove(self, self.OnPlayButtonClicked)
    self.PauseButton.Button.OnClicked:Remove(self, self.OnPauseButtonClicked)
    self.MediaPlayer.OnEndReached:Remove(self, self.OnFinished)

    self:ClearPlaylist()
end

function UICommonVideoPlayer:ClearPlaylist()
    while self.PlayList:Num() > 0 do
        self.PlayList:RemoveAt(0)
    end
end

return UICommonVideoPlayer
