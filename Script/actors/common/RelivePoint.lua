require "UnLua"

local G = require("G")
local MsgCode = require("common.consts").MsgCode
local Actor = require("common.actor")

local RelivePoint = Class(Actor)

function RelivePoint:ReceiveBeginPlay()
    self.Overridden.ReceiveBeginPlay(self)

    self.__TAG__ = string.format("RelivePoint(actor: %s, server: %s)", G.GetObjectName(self), self:IsServer())

    if self:IsServer() then
        self:InitCollisionComponent()
    end
end

function RelivePoint:InitCollisionComponent()
    local CollisionComp = self:AddComponentByClass(UE.USphereComponent, false, UE.FTransform.Identity, false)
    CollisionComp.OnComponentBeginOverlap:Add(self, self.OnBeginOverlap)
    CollisionComp:SetCollisionProfileName("TrapActor", true)
    CollisionComp:SetSphereRadius(self.Radius, true)
    CollisionComp:SetGenerateOverlapEvents(true)
end

function RelivePoint:OnBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if not OtherActor.IsAvatar or not OtherActor:IsAvatar() then
        return
    end

    G.log:debug(self.__TAG__, "OnBeginOverlap avatar: %s", G.GetObjectName(OtherActor))
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self:GetWorld(), 0)
    PlayerController:SendMessage(MsgCode.ReliveAllPlayers, self, false)
end

return RelivePoint
