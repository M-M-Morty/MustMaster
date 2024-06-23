require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_TurnToLocation = Class(BTTask_Base)


-- 转向固定目标点
-- 根据Montage.PlayLength和PlayRate计算出播放时长
-- 根据播放时长和夹角大小计算出转向速度
function BTTask_TurnToLocation:Execute(Controller, Pawn)

    local AIControl = Pawn:GetAIServerComponent()
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    self.TargetLocation = BB:GetValueAsVector("MoveToLocation")
    if not self.TargetLocation then
        return
    end

    local SelfLocation = Pawn:K2_GetActorLocation()
    SelfLocation.Z = self.TargetLocation.Z
    local Forward = self.TargetLocation - SelfLocation
    Forward.Z = 0

    local SelfRotation = Pawn:K2_GetActorRotation()
    local RotationVector = UE.UKismetMathLibrary.Conv_RotatorToVector(SelfRotation)
    RotationVector.Z = 0

    -- -- for test
    -- Forward.X, Forward.Y, Forward.Z = 0, 1, 0
    -- RotationVector.X, RotationVector.Y, RotationVector.Z = 0, 1, 0

    Forward = UE.UKismetMathLibrary.Normal(Forward)
    RotationVector = UE.UKismetMathLibrary.Normal(RotationVector)

    local CosDelta = UE.UKismetMathLibrary.Dot_VectorVector(Forward, RotationVector)
    local DegreesDelta = UE.UKismetMathLibrary.DegACos(CosDelta)

    if self.TurnMontage then
        self.TotalTurnSeconds = UE.UHiUtilsFunctionLibrary.GetMontagePlayLength(self.TurnMontage) / self.MontagePlayRate
        Pawn.AppearanceComponent:Server_PlayMontage(self.TurnMontage, self.MontagePlayRate)
    else
        self.TotalTurnSeconds = self.MinTurnSeconds
    end

    self.TurnSpeed = DegreesDelta / self.TotalTurnSeconds

    -- G.log:debug("yj", "BTTask_TurnToLocation ##########@@@@@@@@@@@@@@@@ CosDelta.%s DegreesDelta.%s self.TotalTurnSeconds.%s self.TurnSpeed.%s", CosDelta, DegreesDelta, self.TotalTurnSeconds, self.TurnSpeed)
end

function BTTask_TurnToLocation:Tick(Controller, Pawn, DeltaSeconds)

    local AIControl = Pawn:GetAIServerComponent()
    AIControl:SetFocusToPoint(DeltaSeconds, self.TurnSpeed, self.TargetLocation)

    self.TotalTurnSeconds = self.TotalTurnSeconds - DeltaSeconds

    --[[

    local SelfLocation = Pawn:K2_GetActorLocation()
    local Forward = self.TargetLocation - SelfLocation
    Forward.Z = 0
    Forward = UE.UKismetMathLibrary.Normal(Forward)

    local SelfRotation = Pawn:K2_GetActorRotation()
    local RotationVector = UE.UKismetMathLibrary.Conv_RotatorToVector(SelfRotation)
    RotationVector.Z = 0
    RotationVector = UE.UKismetMathLibrary.Normal(RotationVector)

    local CosDelta = UE.UKismetMathLibrary.Dot_VectorVector(Forward, RotationVector)
    local DegreesDelta = UE.UKismetMathLibrary.DegACos(CosDelta)

    G.log:debug("yj", "BTTask_TurnToLocation SelfRotation.%s      Forward.%s       %s     %s", SelfRotation, UE.UKismetMathLibrary.Conv_VectorToRotator(Forward), self.TotalTurnSeconds, DegreesDelta)

    local VRotation = UE.UKismetMathLibrary.Conv_RotatorToVector(SelfRotation)

    local ActorsToIgnore = UE.TArray(UE.AActor)
    local HitResult = UE.FHitResult()

    TargetLocation = SelfLocation + VRotation * 1000
    UE.UKismetSystemLibrary.LineTraceSingle(Pawn:GetWorld(), SelfLocation, TargetLocation, UE.ETraceTypeQuery.WorldStatic, true, ActorsToIgnore, 3, HitResult, true)

    TargetLocation = self.TargetLocation
    TargetLocation.Z = SelfLocation.Z
    UE.UKismetSystemLibrary.LineTraceSingle(Pawn:GetWorld(), SelfLocation, self.TargetLocation, UE.ETraceTypeQuery.WorldStatic, true, ActorsToIgnore, 3, HitResult, true)

    -- if self.TotalTurnSeconds < 0 then
    -- if self.TotalTurnSeconds < 0 or DegreesDelta < 10 then

    ]]

    if self.TotalTurnSeconds < 0 or UE.UHiCollisionLibrary.CheckInDirectionBySection(self.TargetLocation, SelfLocation, VRotation, 85, 95) then

        if self.TurnMontage then
            Pawn.AppearanceComponent:Server_StopMontage()
        end

        return ai_utils.BTTask_Succeeded
    end
end


return BTTask_TurnToLocation
