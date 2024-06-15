require "UnLua"

local G = require("G")
local os = require("os")

local BTDecorator_TargetSectionInZ = Class()

-- /** 
--  * 判断Target相较于Origin的方位是否在给定的范围内（以ZNormal为初始，沿右手轴向顺时针旋转）
--  *
--  * @param StartAngle - 范围初始值（角度），取值[0, 180]
--  * @param EndAngle - 范围结束值（角度），取值[0, 180]
--  * @return true - 在范围内，false - 在范围外
--  */
function BTDecorator_TargetSectionInZ:PerformConditionCheckAI(Controller, Pawn)
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
	local Target = BB:GetValueAsObject("TargetActor")
	if not Target then
		return false
	end

	local SelfLocation = Pawn:K2_GetActorLocation()
	local SelfRotation = Pawn:K2_GetActorRotation()
	local TargetLocation = Target:K2_GetActorLocation()

    -- local VRotation = UE.UKismetMathLibrary.Conv_RotatorToVector(SelfRotation)
    local Forward = Pawn:GetActorForwardVector()
    -- G.log:debug("yj", "BTDecorator_TargetSectionInZ $$$$$$$$$$$$$$$ %s - %s - %s", UE.UKismetMathLibrary.Normal(Forward), UE.UKismetMathLibrary.Normal(VRotation), self.DrawDebugTraceType)

	local ZNormal = UE.FVector(0, 0, 1)
	local SelfToTarget = TargetLocation - SelfLocation
	local SelfToTargetNormal = UE.UKismetMathLibrary.Normal(SelfToTarget)
	local RightForwad = UE.UKismetMathLibrary.Cross_VectorVector(ZNormal, Forward)
	if UE.UHiCollisionLibrary.CheckInDirectionBySection(TargetLocation, SelfLocation, Forward, 90, 270) then
		RightForwad = UE.UKismetMathLibrary.Cross_VectorVector(Forward, ZNormal)
	end
	local RightForwadNormal = UE.UKismetMathLibrary.Normal(RightForwad)
	local Dot = UE.UKismetMathLibrary.Dot_VectorVector(RightForwadNormal, SelfToTargetNormal)

	-- SelfToTarget在右方向的投影向量
	local RightAxisProjectionOfSelfToTarget = RightForwadNormal * (SelfToTarget * Dot):Size()

	-- SelfToTarget在Forward平面的投影向量
	local ForwardPlaneProjectOfSelfToTarget = SelfToTarget - RightAxisProjectionOfSelfToTarget

    if self.DrawDebugTraceType ~= 0 then
	    local ActorsToIgnore = UE.TArray(UE.AActor)
	    local HitResult = UE.FHitResult()
		local YellowColor = UE.FLinearColor(1, 1, 0)
	    UE.UKismetSystemLibrary.LineTraceSingle(Pawn:GetWorld(), SelfLocation, SelfLocation + Forward * 200, UE.ETraceTypeQuery.WorldStatic, true, ActorsToIgnore, self.DrawDebugTraceType, HitResult, true)
	    UE.UKismetSystemLibrary.LineTraceSingle(Pawn:GetWorld(), SelfLocation, SelfLocation + ZNormal * 200, UE.ETraceTypeQuery.WorldStatic, true, ActorsToIgnore, self.DrawDebugTraceType, HitResult, true)

	    -- UE.UKismetSystemLibrary.LineTraceSingle(Pawn:GetWorld(), SelfLocation, SelfLocation + SelfToTarget, UE.ETraceTypeQuery.WorldStatic, true, ActorsToIgnore, self.DrawDebugTraceType, HitResult, true, YellowColor, YellowColor)
	    -- UE.UKismetSystemLibrary.LineTraceSingle(Pawn:GetWorld(), SelfLocation, SelfLocation + RightAxisProjectionOfSelfToTarget, UE.ETraceTypeQuery.WorldStatic, true, ActorsToIgnore, self.DrawDebugTraceType, HitResult, true, YellowColor, YellowColor)
	    UE.UKismetSystemLibrary.LineTraceSingle(Pawn:GetWorld(), SelfLocation, SelfLocation + ForwardPlaneProjectOfSelfToTarget, UE.ETraceTypeQuery.WorldStatic, true, ActorsToIgnore, self.DrawDebugTraceType, HitResult, true, YellowColor, YellowColor)
	    -- G.log:debug("yj", "Dot.%s TargetLocation[%s]   RightAxisProjectionOfSelfToTarget[%s]   ForwardPlaneProjectOfSelfToTarget[%s]", Dot, TargetLocation, RightAxisProjectionOfSelfToTarget, ForwardPlaneProjectOfSelfToTarget)

		-- local StartForward = UE.UKismetMathLibrary.RotateAngleAxis(Forward, -self.StartAngle, UE.FVector(0, 1, 0))
		-- for i = 1, 360 do
		--     local TmpForward = UE.UKismetMathLibrary.RotateAngleAxis(StartForward, i, UE.FVector(0, 0, 1))
		--     UE.UKismetSystemLibrary.LineTraceSingle(Pawn:GetWorld(), SelfLocation, SelfLocation + TmpForward * 1000, UE.ETraceTypeQuery.WorldStatic, true, ActorsToIgnore, self.DrawDebugTraceType, HitResult, true)
		-- end

		-- local EndForward = UE.UKismetMathLibrary.RotateAngleAxis(Forward, self.EndAngle, UE.FVector(0, 1, 0))
		-- for i = 1, 360 do
		--     local TmpForward = UE.UKismetMathLibrary.RotateAngleAxis(EndForward, i, UE.FVector(0, 0, 1))
		--     UE.UKismetSystemLibrary.LineTraceSingle(Pawn:GetWorld(), SelfLocation, SelfLocation + TmpForward * 1000, UE.ETraceTypeQuery.WorldStatic, true, ActorsToIgnore, self.DrawDebugTraceType, HitResult, true)
		-- end

	    local RedColor = UE.FLinearColor(1, 0, 0)
		local StartForward = UE.UKismetMathLibrary.RotateAngleAxis(ZNormal, self.StartAngle, UE.UKismetMathLibrary.Cross_VectorVector(ZNormal, Forward))
	    UE.UKismetSystemLibrary.LineTraceSingle(Pawn:GetWorld(), SelfLocation, SelfLocation + StartForward * 1000, UE.ETraceTypeQuery.WorldStatic, true, ActorsToIgnore, self.DrawDebugTraceType, HitResult, true, RedColor, RedColor)

		local EndForward = UE.UKismetMathLibrary.RotateAngleAxis(ZNormal, self.EndAngle, UE.UKismetMathLibrary.Cross_VectorVector(ZNormal, Forward))
	    UE.UKismetSystemLibrary.LineTraceSingle(Pawn:GetWorld(), SelfLocation, SelfLocation + EndForward * 1000, UE.ETraceTypeQuery.WorldStatic, true, ActorsToIgnore, self.DrawDebugTraceType, HitResult, true, RedColor, RedColor)
	end

    Dot = UE.UKismetMathLibrary.Dot_VectorVector(UE.UKismetMathLibrary.Normal(Forward), UE.UKismetMathLibrary.Normal(ForwardPlaneProjectOfSelfToTarget))
    if Dot < 0 then
    	-- ForwardPlaneProjectOfSelfToTarget和ForwardNormal夹角的cos值小于0，说明Target在self背后
    	return false
    end

    -- 再用ZNormal和ForwardPlaneProjectOfSelfToTarget夹角的cos值来做比较
    Dot = UE.UKismetMathLibrary.Dot_VectorVector(ZNormal, UE.UKismetMathLibrary.Normal(ForwardPlaneProjectOfSelfToTarget))
    local StartRadians = UE.UKismetMathLibrary.DegreesToRadians(self.StartAngle)
    local EndRadians = UE.UKismetMathLibrary.DegreesToRadians(self.EndAngle)

    local StartCos = UE.UKismetMathLibrary.Cos(StartRadians)
    local EndCos = UE.UKismetMathLibrary.Cos(EndRadians)
	
	-- cos值越小，角度越大
	local ret = (Dot < StartCos or math.abs(Dot - StartCos) < 0.00001) and (Dot > EndCos or math.abs(Dot - EndCos) < 0.00001)
	-- G.log:debug("yj", "Dot(%s, %s) = %s StartCos(%s) = %s EndCos(%s) = %s result.%s ", ZNormal, UE.UKismetMathLibrary.Normal(ForwardPlaneProjectOfSelfToTarget), Dot, self.StartAngle, StartCos, self.EndAngle, EndCos, ret)
	return ret
end


return BTDecorator_TargetSectionInZ
