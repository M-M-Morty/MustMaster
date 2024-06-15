--
-- DESCRIPTION
--
-- @COMPANY tencent
-- @AUTHOR dougzhang
-- @DATE 2023/04/19
--

---@type BP_SightPillar_C
local math = require("math")
local G = require("G")
local os = require("os")
local table = require("table")

require "UnLua"
local ActorBase = require("actors.common.interactable.base.interacted_item")

local M = Class(ActorBase)

function M:Initialize(...)
    Super(M).Initialize(self, ...)
    self.OldRotator = nil
    self.NewRotator = self.OldRotator
    self.dAngle = 90.0
end

function M:ReceiveBeginPlay()
    Super(M).ReceiveBeginPlay(self)
    self.OldRotator = self.RootSphere:K2_GetComponentRotation()
    self.NewRotator = self.OldRotator
end

function M:CanHit()
    return true
end

function M:Server_ReceiveDamage(PlayerActor, Damage, InteractLocation, bAttack)
    --local SelfRotator = self.RootSphere:K2_GetComponentRotation()
    --local NewRotator = UE.UKismetMathLibrary.MakeRotator(SelfRotator.Roll, SelfRotator.Pitch, SelfRotator.Yaw+self.dAngle)
    --self.RootSphere:K2_SetWorldRotation(NewRotator, false, UE.FHitResult(), false)
    if self.NewRotator ~= nil and not self:IsRotating(self.NewRotator, false) then
        self.NewRotator.Yaw = self.NewRotator.Yaw + self.dAngle
    end
end

function M:Multicast_ReceiveDamage_RPC(PlayerActor, InteractLocation, bAttack)
end

function M:IsFaithClock()
   return true
end

function M:ReceiveEndPlay()
    Super(M).ReceiveEndPlay(self)
end


function M:IsRotating(NewRotator, isTick)
    local SelfRotator = self.RootSphere:K2_GetComponentRotation()
    local NotRotating = UE.UKismetMathLibrary.EqualEqual_RotatorRotator(SelfRotator, NewRotator, 0.1)
    if not isTick then
        G.log:debug("zsf", "IsRotating %s %s %s %s %s", NotRotating, SelfRotator.Yaw, NewRotator, self.NewRotator, self:IsServer())
    end

    return not NotRotating
end


function M:ReceiveTick(DeltaSeconds)
    if not self:IsServer() and not UE.UKismetSystemLibrary.IsStandalone(self) then
        return
    end
    if self.OldRotator == nil then
        return
    end
    local SelfRotator = self.RootSphere:K2_GetComponentRotation()
    local LerpRotator = UE.UKismetMathLibrary.RLerp(SelfRotator, self.NewRotator, 0.2, true)
    --G.log:debug("zsf", "ReceiveTick %s %s %s", LerpRotator, self.NewRotator, SelfRotator.Yaw, UE.UKismetMathLibrary.EqualEqual_RotatorRotator(self.OldRotator, LerpRotator, 0.1) )
    if not UE.UKismetMathLibrary.EqualEqual_RotatorRotator(self.OldRotator, LerpRotator, 0.1) then
        local NewRotator = UE.UKismetMathLibrary.MakeRotator(SelfRotator.Roll, SelfRotator.Pitch, LerpRotator.Yaw)
        self.RootSphere:K2_SetWorldRotation(NewRotator, false, UE.FHitResult(), false)
        self.OldRotator = LerpRotator
    else
        self.RootSphere:K2_SetWorldRotation(self.NewRotator, false, UE.FHitResult(), false)
    end
end

return M
