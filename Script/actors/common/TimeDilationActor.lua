require "UnLua"

local G = require("G")

local Actor = require("common.actor")

local TimeDilationActor = Class(Actor)

function TimeDilationActor:StartWitchTime(TimeDilation, SourceActor)
    self:SendMessage("StartWitchTime", TimeDilation, SourceActor)
    local GameState = UE.UGameplayStatics.GetGameState(self)
    local OutActor = nil
    local LevelSequencerPlayer = UE.ULevelSequencePlayer.CreateLevelSequencePlayer(self, GameState.WitchTimePostProcess, UE.FMovieSceneSequencePlaybackSettings(), OutActor)
    self.SequencePlayer = LevelSequencerPlayer
    self.RemoveTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.StopSequencePlayer}, TimeDilation.TimeDilationDuration, false)
    LevelSequencerPlayer:Play()
end

function TimeDilationActor:StopWitchTime()
    self:SendMessage("StopWitchTime")
    if self.RemoveTimer then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.RemoveTimer)
        self.RemoveTimer = nil
    end
    if self.SequencePlayer then
        self.SequencePlayer:Stop()
        self.SequencePlayer = nil
    end
end

function TimeDilationActor:AddCustomTimeDilationObject(Owner, Object)
    self:SendMessage("AddCustomTimeDilationObject", Owner, Object)
end

function TimeDilationActor:RemoveCustomTimeDilationObject(Owner, Object)
    self:SendMessage("RemoveCustomTimeDilationObject", Owner, Object)
end
             
function TimeDilationActor:IgnoreTimeDilation(Object, Ignore)
    self:SendMessage("IgnoreTimeDilation", Object, Ignore)
end

function TimeDilationActor:StopSequencePlayer()
    self.RemoveTimer = nil
    if self.SequencePlayer then
        self.SequencePlayer:Stop()
        self.SequencePlayer = nil
    end
end


return TimeDilationActor
