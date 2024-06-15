require "UnLua"

local G = require("G")
local Actor = require("common.actor")

local LevelQWL = Class(Actor)


function LevelQWL:ReceiveBeginPlay()
    Super(LevelQWL).ReceiveBeginPlay(self)
    -- G.log:error("yj", "LevelQWL:ReceiveBeginPlay")
end

function LevelQWL:ReceiveTick(DeltaSeconds)
    Super(LevelQWL).ReceiveTick(self, DeltaSeconds)
    -- G.log:error("yj", "LevelQWL:ReceiveTick")
end

function LevelQWL:ReceiveEndPlay()
    Super(LevelQWL).ReceiveEndPlay(self)
    -- G.log:error("yj", "LevelQWL:ReceiveEndPlay")
end

return LevelQWL
