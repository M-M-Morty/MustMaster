require "UnLua"

local G = require("G")

local LevelSequenceBase = require("actors.common.sequence.level_sequence_base")

local LSBossLikaduoChujue = Class(LevelSequenceBase)


function LSBossLikaduoChujue:TryPlayMessagePopSequence()
	if self:IsClient() then
		return
	end

    local Player = G.GetPlayerCharacter(UE.UHiUtilsFunctionLibrary.GetGWorld(), 0)
    Player:SendMessage("TryPlayMessagePopSequence")
end

return LSBossLikaduoChujue
