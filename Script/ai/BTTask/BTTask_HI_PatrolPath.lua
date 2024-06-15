require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_PatrolPath = Class(BTTask_Base)


-- to config
local PatrolPath = {
	{-650.0, 20.0, 150.0},
	{-440.0, 840.0, 150.0}
}


function BTTask_PatrolPath:Execute(Controller, Pawn)

    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local PatrolIndex = BB:GetValueAsInt("PatrolIndex")

    local Patrol = PatrolPath[PatrolIndex + 1]

    local Location = UE.FVector()
    Location:Set(Patrol[1], Patrol[2], Patrol[3])
    BB:SetValueAsVector("MoveToLocation", Location)

    G.log:info("yj", "BTTask_PatrolPath %s - %s", PatrolIndex, Location)

    PatrolIndex = BB:SetValueAsInt("PatrolIndex", (PatrolIndex + 1) % #PatrolPath)

    return ai_utils.BTTask_Succeeded
end

return BTTask_PatrolPath
