require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_Debug = Class(BTTask_Base)


function BTTask_Debug:Execute(Controller, Pawn)

	-- if nil == Pawn.LastLocation then
	--     Pawn.LastLocation = UE.FVector()
	--     Pawn.LastLocation.Set(0, 0, 0)
	-- end

 --    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
 --    local ObserveIndex = BB:GetValueAsInt("ObserveIndex")
 --    local Location = BB:GetValueAsVector("MoveToLocation")

 --    local CurLocation = Pawn:K2_GetActorLocation()
 --    local Dis1 = UE.UKismetMathLibrary.Vector_Distance(CurLocation, Location)
 --    local Dis2 = UE.UKismetMathLibrary.Vector_Distance(Pawn.LastLocation, CurLocation)
 --    G.log:debug("yjj", "BTTask_Debug %s - MoveTo.(%s) - Cur.(%s) - Dis2Target.(%s) Dis2LastLocation.(%s)", ObserveIndex - 1, Location, Pawn:K2_GetActorLocation(), Dis1, Dis2)

 --    Pawn.LastLocation = Pawn:K2_GetActorLocation()

 	G.log:debug("yj", "BTTask_Debug - %s", self.PrintStr)

    return ai_utils.BTTask_Succeeded
end

return BTTask_Debug
