require "UnLua"
local utils = require("common.utils")

local G = require("G")

local Notify_PlayLevelSequence = Class()

function Notify_PlayLevelSequence:Received_Notify(MeshComp, Animation, EventReference)
    local Owner = MeshComp:GetOwner()
    if not Owner:IsClient() then
        return true
    end

    if self.LevelSequence then
        local Settings = UE.FMovieSceneSequencePlaybackSettings()
        local SequencePlayer, SequenceActor = UE.UHiLevelSequencePlayer.CreateHiLevelSequencePlayer(Owner, self.LevelSequence, Settings)

        if self.bBindPlayer then
            local BindingActors = UE.TArray(UE.AActor)
            BindingActors:Add(G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0))
            SequenceActor:SetBindingByTag(self.BindPlayerTag, BindingActors)
        end

        --sequence里对参与者的操作应尽量避免和当前蒙太奇冲突
        --否则出现各种错误，这里不保修 -- by周磊
        if self.bBindPlayer then
            local BindingActors = UE.TArray(UE.AActor)
            BindingActors:Add(MeshComp:GetOwner())
            SequenceActor:SetBindingByTag(self.BindActorTag, BindingActors)
        end
        SequencePlayer:Play()
    end

    return true
end


return Notify_PlayLevelSequence
