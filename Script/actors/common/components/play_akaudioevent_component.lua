--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR PanZiBin
-- @DATE ${date} ${time}
--

local G = require("G")
local utils = require("common.utils")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
---@type BP_PlayAkAudioEventComponent_C
local BP_PlayAkAudioEventComponent = Component(ComponentBase)
local decorator = BP_PlayAkAudioEventComponent.decorator


decorator.message_receiver()
function BP_PlayAkAudioEventComponent:PlayAkAudioEvent(AkEvent, bFollow, PlayMode)
    self:Multicast_AkEvent(AkEvent, bFollow, PlayMode)
end

function BP_PlayAkAudioEventComponent:Multicast_AkEvent_RPC(AkEvent, bFollow, PlayMode)
    if not self.actor:IsClient() then
        return
    end

    if not AkEvent then
        return
    end
    
    if PlayMode == Enum.Enum_AkAudioPlayMode.Queue then
        -- 排队模式
        local AkElement = NewObject(self.UD_FAkElement_Class)
        AkElement.AkEvent = AkEvent
        AkElement.bFollow = bFollow
        AkElement.Actor = self.actor
        self:PushToQueueForPlay(AkElement)

    elseif PlayMode == Enum.Enum_AkAudioPlayMode.Parallel then
        -- 并行模式
        utils.PlayAkEvent(AkEvent, bFollow, self.actor:K2_GetActorLocation(), self.actor, nil)

    elseif PlayMode == Enum.Enum_AkAudioPlayMode.Cover then
        -- 覆盖模式
        UE.UAkGameplayStatics.StopActor(self.actor)
        self.AkEventQueue:Clear()
        utils.PlayAkEvent(AkEvent, bFollow, self.actor:K2_GetActorLocation(), self.actor, nil)
    end
end

function BP_PlayAkAudioEventComponent:PushToQueueForPlay(AkElement)
    self.AkEventQueue:Add(AkElement)
    if self.AkEventQueue:Length() == 1 then
        utils.PlayAkEvent(AkElement.AkEvent, AkElement.bFollow, AkElement.Actor:K2_GetActorLocation(), AkElement.Actor, {self, self.AkEventEndCallback})
    end
end

function BP_PlayAkAudioEventComponent:AkEventEndCallback(CallbackType, CallbackInfo)
    self.AkEventQueue:Remove(1)
    if self.AkEventQueue:Length() == 0 then
        return
    end

    local AkElement = self.AkEventQueue:Get(1)
    utils.PlayAkEvent(AkElement.AkEvent, AkElement.bFollow, AkElement.Actor:K2_GetActorLocation(), AkElement.Actor, {self, self.AkEventEndCallback})
end

decorator.message_receiver()
function BP_PlayAkAudioEventComponent:PlayAkEventWithSwitch(AkEvent, AkSwitch, bOnPlayer)
    self:Multicast_PlayAkEventWithSwitch(AkEvent, AkSwitch, bOnPlayer)
end

function BP_PlayAkAudioEventComponent:Multicast_PlayAkEventWithSwitch_RPC(AkEvent, AkSwitch, bOnPlayer)
    if not self.actor:IsClient() then
        return
    end

    local PlayerController = nil
    if bOnPlayer then
        local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
        PlayerController = Player:GetController()
    else
        PlayerController = self.actor:GetController()
    end

    if not PlayerController then
    end

    if not UE.UAkGameplayStatics.IsEventPlayingOnActor(AkEvent, PlayerController) then
        -- G.log:error("yj", "BP_PlayAkAudioEventComponent:PlayStartBattleMusic.%s Actor.%s", G.GetDisplayName(AkEvent), G.GetDisplayName(self.actor), PlayerController)
        UE.UAkGameplayStatics.PostEvent(AkEvent, PlayerController, 0, nil)
    end

    if AkSwitch then
        -- G.log:error("yj", "BP_PlayAkAudioEventComponent:PlayStartBattleMusic Idx.%s Switch.%s Actor.%s", Idx, G.GetDisplayName(AkSwitch), PlayerController)
        UE.UAkGameplayStatics.SetSwitch(AkSwitch, PlayerController, "None", "None")
    end
end

return BP_PlayAkAudioEventComponent
