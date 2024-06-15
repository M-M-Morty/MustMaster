--
-- DESCRIPTION
--

---@type BP_LevelSequenceTrigger_C

require "UnLua"
local G = require("G")
local Actor = require("common.actor")
local LevelSequenceTrigger = Class(Actor)

local decorator = LevelSequenceTrigger.decorator

function LevelSequenceTrigger:OnLevelSequencePlay(PlayerActor, DisableJump, DisableSpecAnim)
    G.log:info_obj(self, 'LevelSequenceTrigger', "OnLevelSequencePlay %s %s, %s", PlayerActor, DisableJump, DisableSpecAnim)
    PlayerActor:SendMessage("OnLevelSequencePlay", DisableJump, DisableSpecAnim)
end

function LevelSequenceTrigger:OnLevelSequenceFinished(PlayerActor)
    G.log:info_obj(self, 'LevelSequenceTrigger', "OnLevelSequenceFinished %s", PlayerActor)
    PlayerActor:SendMessage("OnLevelSequenceFinished")
end

return LevelSequenceTrigger
