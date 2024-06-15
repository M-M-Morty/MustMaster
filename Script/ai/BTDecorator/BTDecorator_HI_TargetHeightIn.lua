require "UnLua"

local G = require("G")
local utils = require("common.utils")
local os = require("os")

local BTDecorator_TargetHeightIn = Class()

-- 判断Target和Self的胶囊体底部位置的高度差
-- Targeth是目标（玩家）胶囊体底部位置的坐标
-- Selfh是自身（怪物）胶囊体底部位置的坐标
-- Deltah= Targeth - Selfh
-- DeltahMax是手填的参数
-- DeltahMin是手填的参数
-- Deltah∈(DeltahMin,DeltahMax)时返回true，BOSS可以发动攻击

function BTDecorator_TargetHeightIn:PerformConditionCheckAI(Controller, Pawn)
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
	local Target = BB:GetValueAsObject("TargetActor")

	-- local SelfLocation = Pawn:K2_GetActorLocation()
	-- local TargetLocation = Target:K2_GetActorLocation()
	local SelfLocation = utils.GetActorLocation_Down(Pawn)
	local TargetLocation = utils.GetActorLocation_Down(Target)

	-- G.log:debug("yj", "BTDecorator_TargetHeightIn@@@@@@@@@@@@@@@@ %s - %s", SelfLocation, TargetLocation)
    if self.DrawDebugTraceType ~= 0 then
	    local ActorsToIgnore = UE.TArray(UE.AActor)
	    local HitResult = UE.FHitResult()
	    UE.UKismetSystemLibrary.LineTraceSingle(Pawn:GetWorld(), SelfLocation, TargetLocation, UE.ETraceTypeQuery.WorldStatic, true, ActorsToIgnore, self.DrawDebugTraceType, HitResult, true)

    	-- UE.UKismetSystemLibrary.DrawDebugLine(self, SelfLocation, TargetLocation, UE.FLinearColor.White, 2)
	end

    return self:CheckInHeight(TargetLocation, SelfLocation, self.DeltaMax, self.DeltaMin)
end

function BTDecorator_TargetHeightIn:CheckInHeight(TargetPos, Origin, UpHeight, DownHeight)
	local HeightDelta = TargetPos.Z - Origin.Z;

-- TargetPos.Z 和 Origin.Z 是怪物的目标和怪物的胶囊体底部位置的Z坐标

	if HeightDelta < DownHeight or HeightDelta > UpHeight then
		return false
	end

	return true
end


return BTDecorator_TargetHeightIn
