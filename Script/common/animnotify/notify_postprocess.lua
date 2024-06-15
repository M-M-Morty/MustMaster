require "UnLua"

local G = require("G")

local LevelSequencerPlayer = nil

local Notify_PostProcess = Class()

function Notify_PostProcess:Received_NotifyBegin(MeshComp, Animation, TotalDuration, EventReference)            
    local actor = MeshComp:GetOwner()
    if self:ShouldAffect(actor) then
        local PostProcessComponent = self:TryGetPostProcessComponent(actor)        
        if not PostProcessComponent then       
            PostProcessComponent = NewObject(UE.UPostProcessComponent, actor)            
            UE.UHiUtilsFunctionLibrary.RegisterComponent(PostProcessComponent)            
        end   

        PostProcessComponent.Settings.WeightedBlendables = self.PostProcessMaterials
        PostProcessComponent.bEnabled = true
        PostProcessComponent:Activate()    
        
        if not LevelSequencerPlayer then
            local OutActor = nil
            LevelSequencerPlayer = UE.ULevelSequencePlayer.CreateLevelSequencePlayer(actor:GetWorld(), self.LevelSequence, UE.FMovieSceneSequencePlaybackSettings(), OutActor)
        end
        LevelSequencerPlayer:Play()            
        
    end
    return true
end

function Notify_PostProcess:Received_NotifyEnd(MeshComp, Animation, EventReference)        
    local actor = MeshComp:GetOwner()
    if self.StopOnEnd and self:ShouldAffect(actor) then
        local PostProcessComponent = self:TryGetPostProcessComponent(actor)
        if PostProcessComponent then
            PostProcessComponent.Settings.WeightedBlendables.Array:Clear()
            PostProcessComponent.bEnabled = false
            PostProcessComponent:Deactivate()       
        end

       if LevelSequencerPlayer:IsValid() then
           LevelSequencerPlayer:StopAtCurrentTime()
           LevelSequencerPlayer = nil
       end
    end
    return true
end

function Notify_PostProcess:ShouldAffect(actor)
    if self.AffectAll then
        return true
    end

    if GameAPI.IsPlayer(actor) then
        return true
    end

    return false
end

return Notify_PostProcess