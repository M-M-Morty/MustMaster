require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_Speak = Class(BTTask_Base)

function BTTask_Speak:Execute(Controller, Pawn)
    Pawn:SendMessage("PlayAkAudioEvent", self.Event, self.Follow, self.PlayMode)
    return ai_utils.BTTask_Succeeded
end


return BTTask_Speak
