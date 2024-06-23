require "UnLua"


local G = require("G")

local Actor = require("common.actor")
local utils = require("common.utils")

-- 回旋斧
local CircleRoundAxe = Class(Actor)


function CircleRoundAxe:Initialize(...)
    Super(CircleRoundAxe).Initialize(self, ...)

    self.bInThrow = false
    self.Instigator = nil
    self.CRSpeed = 720 * 2
end

function CircleRoundAxe:ReceiveBeginPlay()
    Super(CircleRoundAxe).ReceiveBeginPlay(self)
end

function CircleRoundAxe:ReceiveTick(DeltaSeconds)
    if self.bInThrow then
        self:AxeCircleRound(DeltaSeconds)

        if self:IsServer() and self.OpenTargetFollow then
            self:FollowTarget()
        end
    end
end

function CircleRoundAxe:OnArriveFarthest()
    -- 到达最远端，开始回旋跟随目标
    self.OpenTargetFollow = true
end

function CircleRoundAxe:Multicast_OnThrow_RPC()
    self.bInThrow = true
    self:K2_SetActorRotation(UE.FRotator(60, 0, 0), true)
end

function CircleRoundAxe:Multicast_OnThrowEnd_RPC()
    self.bInThrow = false
end

function CircleRoundAxe:SetCollisionEnabled(NewType)
    utils.SetActorCollisionEnabled(self, NewType)
end

function CircleRoundAxe:AxeCircleRound(DeltaSeconds)
    local OldRotation = self:K2_GetActorRotation()
    local NewRotaion = OldRotation
    NewRotaion.Roll = OldRotation.Roll + self.CRSpeed * DeltaSeconds

    -- G.log:debug("yj", "CircleRoundAxe:CircleRound OldRotation.%s NewRotaion.%s DeltaRotator.%s", OldRotation, NewRotaion, self.CRSpeed * DeltaSeconds)
    self:K2_SetActorRotation(NewRotaion, true)
end

function CircleRoundAxe:Multicast_SetRotation_RPC(Rotation)
    self:K2_SetActorRotation(Rotation, true)
end

function CircleRoundAxe:FollowTarget()
    local NewPoints = UE.TArray(UE.FVector)
    local PointsNum = self.InteractionComponent.ThrowSpline.Spline:GetNumberOfSplinePoints()
    for i = 1, PointsNum do
        local NewLocation = self.InteractionComponent.ThrowSpline.Spline:GetLocationAtSplinePoint(i - 1, UE.ESplineCoordinateSpace.World)
        if i == 1 then
            NewLocation = self.Instigator:K2_GetActorLocation()
        end
        NewPoints:Add(NewLocation)
    end

    self.InteractionComponent.ThrowSpline.Spline:SetSplinePoints(NewPoints, UE.ESplineCoordinateSpace.World)
end

return RegisterActor(CircleRoundAxe)
