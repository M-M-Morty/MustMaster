require "UnLua"

local G = require("G")

local TrapActorBase = require("actors.common.trap.TrapActorBase")
-- local TrapActorPlayAkAudio = require("actors.common.trap.TrapActorPlayAkAudio")
local TrapActorBalloonBig = Class(TrapActorBase)

function TrapActorBalloonBig:OverlapByOtherActor(OtherActor)
    Super(TrapActorBalloonBig).OverlapByOtherActor(self, OtherActor)

    if not OtherActor.CharIdentity or OtherActor.CharIdentity ~= Enum.Enum_CharIdentity.Avatar then   --暂定玩家触碰才有所反映
        return
    end
    
    self:RealActive(OtherActor)
end

function TrapActorBalloonBig:ActiveByFlowGraph(OtherActor)
    if not self:CanActive() then
        return false
    end

    self:RealActive(OtherActor)
    return true
end

function TrapActorBalloonBig:RealActive(OtherActor)
    self:PlayAkEventByBalloon(OtherActor)
    self.AkSwitch = false
end

function TrapActorBalloonBig:CanActive()
    return self.AkSwitch
end

function TrapActorBalloonBig:PlayAkEventByBalloon(OtherActor)
    -- G.log:error("yj", "TrapActorBalloonBig %s OverlapByOtherActor[%s]", G.GetDisplayName(self), G.GetDisplayName(OtherActor))
    local idx = math.random(1, self.Events:Length())
    OtherActor:SendMessage("PlayAkAudioEvent", self.Events[idx], true, Enum.Enum_AkAudioPlayMode.Cover)
    UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.AkCDCallback}, self.AkCD, false)
end

function TrapActorBalloonBig:AkCDCallback()
    self.AkSwitch = true
end

function TrapActorBalloonBig:ReplaceEmoji()
    -- self.StaticMesh:SetStaticMesh(self.ReplaceStaticMesh)
    self.SkeletalMesh:SetVisibility(false)
    self.StaticMesh:SetVisibility(true)
end

return TrapActorBalloonBig
