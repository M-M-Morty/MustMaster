require "UnLua"

local G = require("G")

local TriggerEvent = Class()

function TriggerEvent:ctor(InTriggerVolume, InActor)
    self.TriggerVolume = InTriggerVolume
    self.OverlapedActor = InActor   
end

function TriggerEvent:ActorBeginOverlapEvent()
    --G.log:debug("hycoldrain", "TriggerEvent:ActorBeginOverlapEvent..SendMessage.%s", G.GetDisplayName(self.TriggerVolume))
    self.TriggerVolume:SendMessage("OnPlayerEnterTrigger", self.OverlapedActor)
end

function TriggerEvent:ActorEndOverlapEvent()
    --G.log:debug("hycoldrain", "TriggerEvent:ActorEndOverlapEvent..SendMessage.%s", G.GetDisplayName(self.TriggerVolume))
    self.TriggerVolume:SendMessage("OnPlayerLeaveTrigger", self.OverlapedActor)          
end


return TriggerEvent