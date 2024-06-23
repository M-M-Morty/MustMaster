--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require("G")
local Actor = require("common.actor")
local MissionParamTable = require("common.data.event_param_data").data

---@type MissionTargetParticle_C
local MissionTargetParticle = Class(Actor)

function MissionTargetParticle:Initialize(Initializer)
    Super(MissionTargetParticle).Initialize(self, Initializer)
    self.DestroyTimer = nil
    self.bOpenTrigger = false
end

function MissionTargetParticle:ReceiveBeginPlay()
    Super(MissionTargetParticle).ReceiveBeginPlay(self)
    -- todo: 目前使用临时资源，暂停特效播放做效果
    UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.DoPause}, 1, false)
    if self.bOpenTrigger then
        self.DisplaySphere = self:AddComponentByClass(UE.USphereComponent, false, UE.FTransform.Identity, false)
        self.DisplaySphere.OnComponentBeginOverlap:Add(self, self.OnDisplaySphereBeginOverlap)
        self.DisplaySphere.OnComponentEndOverlap:Add(self, self.OnDisplaySphereEndOverlap)
        self.DisplaySphere:SetCollisionProfileName("TrapActor", true)
        self.DisplaySphere:SetSphereRadius(MissionParamTable.MISSION_EVENT_TRACKING_PARTICLE_FADEOUT_RANGE.FloatValue, true)
    end
end

function MissionTargetParticle:DoPause()
    self.Niagara:SetPaused(true)
end

function MissionTargetParticle:FadeOut(bFadeOut)
    if bFadeOut then
        if self.DestroyTimer == nil then
            self.Niagara:SetPaused(false)
            self.DestroyTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.DoDestroy}, MissionParamTable.MISSION_EVENT_TRACKING_PARTICLE_FADEOUT_TIME.FloatValue, false)
        end
    else
        self:K2_DestroyActor()
    end
end

function MissionTargetParticle:DoDestroy()
    self:K2_DestroyActor()
end

function MissionTargetParticle:ReceiveEndPlay()
    Super(MissionTargetParticle).ReceiveEndPlay(self)
end

-- client
function MissionTargetParticle:OnDisplaySphereBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if OtherActor.IsPlayer ~= nil and OtherActor:IsPlayer() then
        -- 只有客户端主玩家触发才生效
        local MainPlayerActor = G.GetPlayerCharacter(self, 0)
        if OtherActor == MainPlayerActor then
            self:SetActorHiddenInGame(true)
        end
    end
end

-- client
function MissionTargetParticle:OnDisplaySphereEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    if OtherActor.IsPlayer ~= nil and OtherActor:IsPlayer() then
        -- 只有客户端主玩家触发才生效
        local MainPlayerActor = G.GetPlayerCharacter(self, 0)
        if OtherActor == MainPlayerActor then
            self:SetActorHiddenInGame(false)
        end
    end
end

return MissionTargetParticle
