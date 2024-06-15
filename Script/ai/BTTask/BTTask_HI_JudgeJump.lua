require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_JudgeJump = Class(BTTask_Base)


function BTTask_JudgeJump:Execute(Controller, Pawn)

    -- G.log:debug("yj", "BTTask_JudgeJump %s", Pawn.AppearanceComponent:IsMoving())

    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local Target = BB:GetValueAsObject("TargetActor")
    local MoveToLocation = BB:GetValueAsObject("MoveToLocation")

    MoveToLocation = MoveToLocation or Target:K2_GetActorLocation()

    local SelfLocation = Pawn:K2_GetActorLocation()
    local Dis = UE.UKismetMathLibrary.Vector_Distance(SelfLocation, MoveToLocation)
    local ZDis = math.abs(SelfLocation.Z - MoveToLocation.Z)

    -- G.log:debug("yj", "############### BTTask_JudgeJump %s - %s = %s < %s - %s", SelfLocation.Z, MoveToLocation.Z, ZDis, self.ZDis, ZDis < self.ZDis)
    if ZDis < self.ZDis then
        return ai_utils.BTTask_Succeeded
    end

    if Pawn:IsValid() and Pawn.AppearanceComponent:IsMoving() then

        local StartPos = SelfLocation
        local ActorForward = Pawn:GetActorForwardVector()
        local EndPos = StartPos + ActorForward * self.ForwardDis
        local HitResult = UE.FHitResult()

        local ignore = UE.TArray(UE.AActor)
        local player = G.GetPlayerCharacter(Pawn:GetWorld(), 0)
        ignore:Add(player)

        local isHit = UE.UKismetSystemLibrary.SphereTraceSingle(Pawn, StartPos, EndPos, 20.0, UE.ETraceTypeQuery.TraceTypeQuery1, false, ignore, 
            UE.EDrawDebugTrace.ForOneFrame, HitResult, true, UE.FLinearColor(), UE.FLinearColor(), 5.0)

        if isHit then
            local Rotator = UE.FVector()
            Rotator.Z = self.JumpHeight
            local SweepResult = UE.FHitResult()
            Pawn:K2_AddActorLocalOffset(Rotator, false, SweepResult, false)

            Pawn.Velocity = Pawn:GetActorForwardVector()

            Pawn:Jump()
            utils.DoDelay(Pawn, 1.0, 
                function() 
                    Pawn.Velocity = nil
                    Pawn:StopJumping() 
                end)
        end
    end

    return ai_utils.BTTask_Succeeded
end

function BTTask_JudgeJump:Tick(Controller, Pawn, DeltaSeconds)
    local Scal = 100
    if Pawn.Velocity ~= nil then
        G.log:debug("yj", "BTTask_JudgeJump Velocity -> %s", Pawn.Velocity * Scal)
        Pawn.CharacterMovement:RequestDirectMove(Pawn.Velocity * Scal, true)
    end
end


return BTTask_JudgeJump
