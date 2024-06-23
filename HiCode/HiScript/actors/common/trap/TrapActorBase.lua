require "UnLua"

local G = require("G")

local Actor = require("common.actor")

local TrapActorBase = Class(Actor)

function TrapActorBase:ReceiveBeginPlay()
    Super(TrapActorBase).ReceiveBeginPlay(self)

    G.log:debug("yj", "TrapActorBase:ReceiveBeginPlay %s.%s IsClient.%s", self, self:GetDisplayName(), self:IsClient())

    self:SetActorHiddenInGame(self.HiddenInGame)
end

function TrapActorBase:OnRep_HiddenInGame()
    self:SetActorHiddenInGame(self.HiddenInGame)
end

function TrapActorBase:ReceiveEndPlay()
    Super(TrapActorBase).ReceiveEndPlay(self)
end

function TrapActorBase:OnActorBeginOverlap(OtherActor)
    -- Run On Server

    if self:IsClient() then
        return;
    end

    --[[
    self:DelCheckOutTimer(OtherActor)
    if not self:IsOverlappingActor(OtherActor) then
        self:AddCheckInTimer(OtherActor)
        return
    end
    self:DelCheckInTimer(OtherActor)
    ]]--
    self.InnerActors:Add(OtherActor)

    OtherActor:SendMessage("OnEnterTrap", self)

    -- G.log:debug("yj", "TrapActorBase OnActorBeginOverlap OtherActor.%s, InnerActors Length.%s", OtherActor:GetDisplayName(), self.InnerActors:Length())

    self:OverlapByOtherActor(OtherActor)
    self:Real_OnActorBeginOverlap(OtherActor)
end

function TrapActorBase:OnActorEndOverlap(OtherActor)
    if self:IsClient() then
        return;
    end

    -- Run On Server
    --[[
    self:DelCheckInTimer(OtherActor)
    if self:IsOverlappingActor(OtherActor) then
        self:AddCheckOutTimer(OtherActor)
        return
    end
    self:DelCheckOutTimer(OtherActor)
    ]]--

    self.InnerActors:Remove(OtherActor)
    OtherActor:SendMessage("OnLeaveTrap", self)

    -- G.log:debug("yj", "TrapActorBase OnActorEndOverlap OtherActor.%s, InnerActors Length.%s", OtherActor:GetDisplayName(), self.InnerActors:Length())

    self:Real_OnActorEndOverlap(OtherActor)
end

function TrapActorBase:OverlapByOtherActor(OtherActor)
end

function TrapActorBase:Real_OnActorBeginOverlap(OtherActor)
end

function TrapActorBase:Real_OnActorEndOverlap(OtherActor)
end

--[[
function TrapActorBase:AddCheckInTimer(OtherActor)
    local TimerHandler = self.CheckInTimerMap:Find(OtherActor)
    if TimerHandler then
        return
    end

    TimerHandler = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, function() self:OnActorBeginOverlap(OtherActor) end}, 0.5, true)
    self.CheckInTimerMap:Add(OtherActor, TimerHandler)
end

function TrapActorBase:DelCheckInTimer(OtherActor)
    local TimerHandler = self.CheckInTimerMap:Find(OtherActor)
    if not TimerHandler then
        return
    end

    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, TimerHandler)
    self.CheckInTimerMap:Remove(OtherActor)
end

function TrapActorBase:AddCheckOutTimer(OtherActor)
    local TimerHandler = self.CheckOutTimerMap:Find(OtherActor)
    if TimerHandler then
        return
    end

    TimerHandler = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, function() self:OnActorEndOverlap(OtherActor) end}, 0.5, true)
    self.CheckOutTimerMap:Add(OtherActor, TimerHandler)
end

function TrapActorBase:DelCheckOutTimer(OtherActor)
    local TimerHandler = self.CheckOutTimerMap:Find(OtherActor)
    if not TimerHandler then
        return
    end

    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, TimerHandler)
    self.CheckOutTimerMap:Remove(OtherActor)
end
]]-- 

function TrapActorBase:ReceiveEndPlay()
    Super(TrapActorBase).ReceiveEndPlay(self)
end

return TrapActorBase
