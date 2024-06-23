require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_CallMovePlatform = Class(BTTask_Base)


function BTTask_CallMovePlatform:Execute(Controller, Pawn)

	if Pawn.MovePlatformActor ~= nil then
		return ai_utils.BTTask_Failed
	end

	local MovePlatformActor = GameAPI.SpawnActor(Pawn:GetWorld(), Pawn.MovePlatformActorClass, Pawn:GetTransform(),  UE.FActorSpawnParameters(), {})

	G.log:debug("yj", "BTTask_CallMovePlatform %s", G.GetDisplayName(MovePlatformActor))

	Pawn:SendMessage("OnMovePlatformActorCreate", MovePlatformActor)

	return ai_utils.BTTask_Succeeded
end


return BTTask_CallMovePlatform
