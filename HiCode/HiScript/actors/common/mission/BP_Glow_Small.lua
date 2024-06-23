local G = require("G")
local Actor = require("common.actor")
local MissionParamTable = require("common.data.event_param_data").data

---@type BP_Glow_Small_C
local GlowSmall = Class(Actor)

function GlowSmall:Initialize(Initializer)
    Super(GlowSmall).Initialize(self, Initializer)
    self.MissionType = 0
    self.MissionState = 0
    self.DestroyTimer = nil
end

function GlowSmall:ReceiveBeginPlay()
    Super(GlowSmall).ReceiveBeginPlay(self)
    -- 创建的时候先隐藏，后面玩家触发了trigger再显示
    self:SetActorHiddenInGame(true)
    -- todo: 目前使用临时资源，暂停特效播放做效果
    UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.DoPause}, 1, false)

    self.DisplaySphere = self:AddComponentByClass(UE.USphereComponent, false, UE.FTransform.Identity, false)
    self.DisplaySphere.OnComponentBeginOverlap:Add(self, self.OnDisplaySphereBeginOverlap)
    self.DisplaySphere.OnComponentEndOverlap:Add(self, self.OnDisplaySphereEndOverlap)
    self.DisplaySphere:SetCollisionProfileName("TrapActor", true)
    self.DisplaySphere:SetSphereRadius(MissionParamTable.MISSION_EVENT_TRACKING_PARTICLE_FADEOUT_RANGE.FloatValue, true)
end

function GlowSmall:DoPause()
    self.Niagara:SetPaused(true)
end

function GlowSmall:FadeOut(bFadeOut)
    if bFadeOut then
        if self.DestroyTimer == nil then
            self.Niagara:SetPaused(false)
            self.DestroyTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.DoDestroy}, MissionParamTable.MISSION_EVENT_TRACKING_PARTICLE_FADEOUT_TIME.FloatValue, false)
        end
    else
        self:K2_DestroyActor()
    end
end

function GlowSmall:DoDestroy()
    self:K2_DestroyActor()
end

function GlowSmall:ReceiveEndPlay()
    Super(GlowSmall).ReceiveEndPlay(self)
end

-- client
function GlowSmall:OnDisplaySphereBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if OtherActor.IsPlayer ~= nil and OtherActor:IsPlayer() then
        -- 只有客户端主玩家触发才生效
        local MainPlayerActor = G.GetPlayerCharacter(self, 0)
        if OtherActor == MainPlayerActor then
            self:SetActorHiddenInGame(false)
        end
    end
end

-- client
function GlowSmall:OnDisplaySphereEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    if OtherActor.IsPlayer ~= nil and OtherActor:IsPlayer() then
        -- 只有客户端主玩家触发才生效
        local MainPlayerActor = G.GetPlayerCharacter(self, 0)
        if OtherActor == MainPlayerActor then
            self:SetActorHiddenInGame(true)
        end
    end
end

function GlowSmall:GetBillboardComponent()
    return self.BillboardComponent
end

function GlowSmall:MarkMissionIcon(MissionType, MissionState)
    if MissionType and MissionState then
        self.MissionType = MissionType
        self.MissionState = MissionState
    end
    if self.MissionType == nil or self.MissionState == nil then
        G.log:error("GlowSmall", "MarkMissionIcon error, MissionType=%s, MissionState=%s", self.MissionType, self.MissionState)
        return
    end
    self.BillboardComponent:MarkTracked(self.MissionType, self.MissionState)
end

function GlowSmall:UnmarkMissionIcon()
    return self.BillboardComponent:UnMarkTracked()
end

return GlowSmall
