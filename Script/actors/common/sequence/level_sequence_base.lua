require "UnLua"

local G = require("G")
local Actor = require("common.actor")
local utils = require("common.utils")

local LevelSequenceBase = Class(Actor)


function LevelSequenceBase:PlayAkEvent(AkEvent, PlayMode)
	if not self:IsClient() then
		return
	end

    local Player = G.GetPlayerCharacter(self, 0)
    Player:SendMessage("PlayAkAudioEvent", AkEvent, true, PlayMode or Enum.Enum_AkAudioPlayMode.Parallel)
end

function LevelSequenceBase:PlayMonologue(MonologueID)
	if not self:IsClient() then
		return
	end

	if MonologueID == 0 then
		return
	end

    local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
    Player:SendMessage("StartMonologue", MonologueID)
end

return LevelSequenceBase
