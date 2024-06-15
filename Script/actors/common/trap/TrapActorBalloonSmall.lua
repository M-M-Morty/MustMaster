require "UnLua"

local G = require("G")

local TrapActorBase = require("actors.common.trap.TrapActorBase")
-- local TrapActorPlayAkAudio = require("actors.common.trap.TrapActorPlayAkAudio")

local TrapActorBalloonSmall = Class(TrapActorBase)

local ServerFPS = 10
local ClientFPS = 30

function TrapActorBalloonSmall:OverlapByOtherActor(OtherActor)
    --[[
    Super(TrapActorBalloonSmall).OverlapByOtherActor(self, OtherActor)
    
    if not OtherActor.CharIdentity or OtherActor.CharIdentity ~= Enum.Enum_CharIdentity.Player then
        return
    end
    
    -- G.log:error("yj", "TrapActorBalloonSmall %s OverlapByOtherActor[%s]", G.GetDisplayName(self), G.GetDisplayName(OtherActor))

    self:Multicast_BeginFly()
    ]]--
end

function TrapActorBalloonSmall:ActiveByFlowGraph(OtherActor)
    if not self:CanActive() then
        return false
    end

    self:RealActive(OtherActor)
    return true
end

function TrapActorBalloonSmall:RealActive(OtherActor)
    self:Multicast_BeginFly()
end

function TrapActorBalloonSmall:CanActive()
    return true
end

function TrapActorBalloonSmall:Multicast_BeginFly_RPC()
    if self:IsServer() then
        if self.DollClass then
            self.DollActor = GameAPI.SpawnActor(self:GetWorld(), self.DollClass, self:GetTransform(), UE.FActorSpawnParameters(), {})
        end
        if self.SafeAreaClass then
            GameAPI.SpawnActor(self:GetWorld(), self.SafeAreaClass, self:GetTransform(), UE.FActorSpawnParameters(), {})
        end

        if self.FlyAnimation then
            utils.DoDelay(self, self.FlyAnimation:GetPlayLength() + 2, function() self:FlyAnimationOver() end)
        end
    else
        -- 播放Fly动画
        if self.FlyAnimation then
            UE.USkeletalMeshComponent.PlayAnimation(self.SkeletalMesh, self.FlyAnimation, false)
            utils.DoDelay(self, self.FlyAnimation:GetPlayLength() + 2, function()  UE.USkeletalMeshComponent.PlayAnimation(self.SkeletalMesh, self.InitAnimation, true) end)
        end
    end
end

function TrapActorBalloonSmall:FlyAnimationOver()
    self:SetActorHiddenInGame(true)
    self.HiddenInGame = true;
end

function TrapActorBalloonSmall:ReceiveEndPlay()
    Super(TrapActorBalloonSmall).ReceiveEndPlay(self)
    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.FlyTimerHandler)
    if self.DollActor then
        self.DollActor:K2_DestroyActor()
    end
end

return TrapActorBalloonSmall
