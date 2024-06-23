require "UnLua"

local G = require("G")

local Actor = require("common.actor")

local TimelineBase = Class(Actor)


function TimelineBase:ReceiveBeginPlay()
end

function TimelineBase:ReceiveTick(DeltaSeconds)
end

function TimelineBase:RegisterTimelineUpdateCallback(CallbackOwner, CallbackFunc)
    self.TimelineUpdateCallbackOwner = CallbackOwner
    self.TimelineUpdateCallbackFunc = CallbackFunc
end

function TimelineBase:RegisterTimelineEndCallback(CallbackOwner, CallbackFunc)
    self.TimelineEndCallbackOwner = CallbackOwner
    self.TimelineEndCallbackFunc = CallbackFunc
end

function TimelineBase:OnTimelineUpdate(Value)
    if self.TimelineUpdateCallbackFunc then
        self.TimelineUpdateCallbackFunc(self.TimelineUpdateCallbackOwner, Value)
    end
end

function TimelineBase:OnTimelineEnd()
    if self.TimelineEndCallbackFunc then
        self.TimelineEndCallbackFunc(self.TimelineEndCallbackOwner)
    end
end

function TimelineBase:ReceiveDestroyed()
end

return RegisterActor(TimelineBase)
