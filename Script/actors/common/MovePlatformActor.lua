require "UnLua"

local G = require("G")
local t = require("t")

local Actor = require("common.actor")

local MovePlatformActor = Class(Actor)


function MovePlatformActor:Initialize(...)
    Super(MovePlatformActor).Initialize(self, ...)
end

function MovePlatformActor:ReceiveBeginPlay()
    Super(MovePlatformActor).ReceiveBeginPlay(self)
    t.MovePlatformActor = self
end

function MovePlatformActor:ReceiveDestroyed()
end

return RegisterActor(MovePlatformActor)
