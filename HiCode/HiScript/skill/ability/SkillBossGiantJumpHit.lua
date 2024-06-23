require "UnLua"

local G = require("G")
local utils = require("common.utils")

local SkillBossGiantJumpHit = Class()


function SkillBossGiantJumpHit:K2_ActivateAbility()
    self:K2_CommitAbility()
    local Montage = self:GetMontage()

    local UserData = self:GetCurrentUserData()
    local TargetActorTransform = UserData.SkillTargetTransform
    local TargetLocation = UE.FVector()
    UE.UKismetMathLibrary.BreakTransform(TargetActorTransform, TargetLocation, UE.FRotator(), UE.FVector())
    local Actor = self:GetAvatarActorFromActorInfo()
    local SrcLocation = Actor:K2_GetActorLocation()
    G.log:info("px", "SkillBossGiantJumpHit:ActivateAbility src %s target %s", SrcLocation, TargetLocation)
    local Direction = UE.UKismetMathLibrary.Subtract_VectorVector(TargetLocation, SrcLocation)
    local Distance = UE.UKismetMathLibrary.Vector_Distance2D(TargetLocation, SrcLocation)
    if Distance < self.JumpXYMinDistance then
        if Distance <= 1e-6 then
            Direction = UE.UKismetMathLibrary.MakeVector(1, 0, 0)
        else
            Direction = UE.UKismetMathLibrary.MakeVector(Direction.X, Direction.Y, 0)
            UE.UKismetMathLibrary.Vector_Normalize(Direction)
        end
        Direction = UE.UKismetMathLibrary.Multiply_VectorFloat(Direction, self.JumpXYMinDistance - Distance)
        TargetLocation = UE.UKismetMathLibrary.Add_VectorVector(TargetLocation, Direction)
        Distance = self.JumpXYMinDistance
    end
    local MoveTime = Distance / self.JumpXYSpeed

    local proxy = UE.UAbilityTask_PlayMontageAndWait.CreatePlayMontageAndWaitProxy(self, "", Montage)
    proxy.OnCompleted:Add(self, self.OnCompleted)
    proxy.OnBlendOut:Add(self, self.OnBlendOut)
    proxy.OnInterrupted:Add(self, self.OnInterrupted)
    proxy.OnCancelled:Add(self, self.OnCancelled)
    proxy:ReadyForActivation()

    local Move = UE.UAbilityTask_MoveToLocation.MoveToLocation(self, "", TargetLocation, MoveTime)
    G.log:info("px", "SkillBossGiantJumpHit:ActivateAbility move time %s target %s", MoveTime, TargetLocation)
    Move.OnTargetLocationReached:Add(self, self.OnDelayFinish)
    Move:ReadyForActivation()

    self:HandleCalc()
end

function SkillBossGiantJumpHit:OnCompleted()
    G.log:info("px", "SkillBossGiantJumpHit:OnCompleted")
    self:K2_EndAbility()
end

function SkillBossGiantJumpHit:OnBlendOut()
    G.log:info("px", "SkillBossGiantJumpHit:OnBlendOut")
    self:K2_EndAbility()
end

function SkillBossGiantJumpHit:OnInterrupted()
    G.log:info("px", "SkillBossGiantJumpHit:OnInterrupted")
    self:K2_EndAbility()
end

function SkillBossGiantJumpHit:OnCancelled()
    G.log:info("px", "SkillBossGiantJumpHit:OnCancelled")
    self:K2_EndAbility()
end

function SkillBossGiantJumpHit:OnDelayFinish()
    G.log:info("px", "SkillBossGiantJumpHit:OnDelayFinish")
    self:MontageJumpToSection("LoopEnd")
end


return SkillBossGiantJumpHit
