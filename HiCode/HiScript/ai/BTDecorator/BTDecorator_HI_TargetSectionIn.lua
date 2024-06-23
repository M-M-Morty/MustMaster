require "UnLua"

local G = require("G")
local os = require("os")

local BTDecorator_TargetSectionIn = Class()


-- /** 
--  * 判断Target相较于Origin的方位是否在给定的范围内（以Origin正前方右侧朝向为初始，沿Z轴逆时针旋转）
--  *
--  * @param StartAngle - 范围初始值（角度），取值[0, 360]
--  * @param EndAngle - 范围结束值（角度），取值[0, 360]
--  * @return true - 在范围内，false - 在范围外
--  */
function BTDecorator_TargetSectionIn:PerformConditionCheckAI(Actor)
    local Controller = UE.UAIBlueprintHelperLibrary.GetAIController(Actor)
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
	local Target = BB:GetValueAsObject("TargetActor")
	if not Target then
		return false
	end

	local Pawn = Actor:GetInstigator()
	local SelfLocation = Pawn:K2_GetActorLocation()
	local SelfRotation = Pawn:K2_GetActorRotation()
	local TargetLocation = Target:K2_GetActorLocation()

	-- local ret = false
 --    ret = UE.UHiCollisionLibrary.CheckInDirectionBySection(UE.FVector(1, 0, 0), UE.FVector(0, 0, 0), UE.FVector(0, 1, 0), self.StartAngle, self.EndAngle)
 --    G.log:debug("yj", "BTDecorator_TargetSectionIn %s", ret)
 --    ret = UE.UHiCollisionLibrary.CheckInDirectionBySection(UE.FVector(1, 1, 0), UE.FVector(0, 0, 0), UE.FVector(0, 1, 0), self.StartAngle, self.EndAngle)
 --    G.log:debug("yj", "BTDecorator_TargetSectionIn %s", ret)
 --    ret = UE.UHiCollisionLibrary.CheckInDirectionBySection(UE.FVector(0, 1, 0), UE.FVector(0, 0, 0), UE.FVector(0, 1, 0), self.StartAngle, self.EndAngle)
 --    G.log:debug("yj", "BTDecorator_TargetSectionIn %s", ret)
 --    ret = UE.UHiCollisionLibrary.CheckInDirectionBySection(UE.FVector(-1, 1, 0), UE.FVector(0, 0, 0), UE.FVector(0, 1, 0), self.StartAngle, self.EndAngle)
 --    G.log:debug("yj", "BTDecorator_TargetSectionIn %s", ret)
 --    ret = UE.UHiCollisionLibrary.CheckInDirectionBySection(UE.FVector(-1, 0, 0), UE.FVector(0, 0, 0), UE.FVector(0, 1, 0), self.StartAngle, self.EndAngle)
 --    G.log:debug("yj", "BTDecorator_TargetSectionIn %s", ret)
 --    ret = UE.UHiCollisionLibrary.CheckInDirectionBySection(UE.FVector(-1, -1, 0), UE.FVector(0, 0, 0), UE.FVector(0, 1, 0), self.StartAngle, self.EndAngle)
 --    G.log:debug("yj", "BTDecorator_TargetSectionIn %s", ret)
 --    ret = UE.UHiCollisionLibrary.CheckInDirectionBySection(UE.FVector(0, -1, 0), UE.FVector(0, 0, 0), UE.FVector(0, 1, 0), self.StartAngle, self.EndAngle)
 --    G.log:debug("yj", "BTDecorator_TargetSectionIn %s", ret)
 --    ret = UE.UHiCollisionLibrary.CheckInDirectionBySection(UE.FVector(1, -1, 0), UE.FVector(0, 0, 0), UE.FVector(0, 1, 0), self.StartAngle, self.EndAngle)
    -- G.log:debug("yj", "BTDecorator_TargetSectionIn %s", ret)
    -- return true

    -- local VRotation = UE.UKismetMathLibrary.Conv_RotatorToVector(SelfRotation)
    local Forward = Pawn:GetActorForwardVector()
    -- G.log:debug("yj", "BTDecorator_TargetSectionIn $$$$$$$$$$$$$$$ %s - %s - %s", UE.UKismetMathLibrary.Normal(Forward), UE.UKismetMathLibrary.Normal(VRotation), self.DrawDebugTraceType)

    if self.DrawDebugTraceType ~= 0 then
	    local RedColor = UE.FLinearColor(1, 0, 0)
	    local ActorsToIgnore = UE.TArray(UE.AActor)
	    local HitResult = UE.FHitResult()
	    UE.UKismetSystemLibrary.LineTraceSingle(Pawn:GetWorld(), SelfLocation, TargetLocation, UE.ETraceTypeQuery.WorldStatic, true, ActorsToIgnore, self.DrawDebugTraceType, HitResult, true)
	    UE.UKismetSystemLibrary.LineTraceSingle(Pawn:GetWorld(), SelfLocation, SelfLocation + Forward * 1000, UE.ETraceTypeQuery.WorldStatic, true, ActorsToIgnore, self.DrawDebugTraceType, HitResult, true)

	    -- RotateAngleAxis默认是沿着Axis顺时针转，取负代表逆时针转，加90度代表从右正方逆时针转
	    local StartForward = UE.UKismetMathLibrary.RotateAngleAxis(Forward, -self.StartAngle + 90, UE.FVector(0, 0, 1))  -- 从右正方沿着Z轴逆时针转StartAngle度
	    UE.UKismetSystemLibrary.LineTraceSingle(Pawn:GetWorld(), SelfLocation, SelfLocation + StartForward * 1000, UE.ETraceTypeQuery.WorldStatic, true, ActorsToIgnore, self.DrawDebugTraceType, HitResult, true, RedColor, RedColor)

	    local EndForward = UE.UKismetMathLibrary.RotateAngleAxis(Forward, -self.EndAngle + 90, UE.FVector(0, 0, 1))  -- 从右正方沿着Z轴逆时针转EndAngle度
	    UE.UKismetSystemLibrary.LineTraceSingle(Pawn:GetWorld(), SelfLocation, SelfLocation + EndForward * 1000, UE.ETraceTypeQuery.WorldStatic, true, ActorsToIgnore, self.DrawDebugTraceType, HitResult, true, RedColor, RedColor)
	end

    return UE.UHiCollisionLibrary.CheckInDirectionBySection(TargetLocation, SelfLocation, Forward, self.StartAngle, self.EndAngle)
end


return BTDecorator_TargetSectionIn
