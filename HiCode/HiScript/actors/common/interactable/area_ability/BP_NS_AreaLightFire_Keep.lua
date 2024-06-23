--
-- DESCRIPTION
--
-- @COMPANY tencent
-- @AUTHOR dougzhang
-- @DATE 2023/04/19
--

---@type BP_SightPillar_C
local G = require("G")
local os = require("os")
local table = require("table")
local MutableActorOperations = require("actor_management.mutable_actor_operations")
local utils = require("common.utils")

require "UnLua"
local ActorBase = require("actors.common.interactable.base.base_item")

local M = Class(ActorBase)

function M:Initialize(...)
    Super(M).Initialize(self, ...)
    self.OverlapActorIds = {}
end

function M:ReceiveBeginPlay()
    Super(M).ReceiveBeginPlay(self)
    self.RootSphere.OnComponentBeginOverlap:Add(self, self.OnBeginOverlap_RootSphere)
    self.RootSphere.OnComponentEndOverlap:Add(self, self.OnEndOverlap_RootSphere)
end

function M:ReceiveEndPlay()
    self.RootSphere.OnComponentBeginOverlap:Remove(self, self.OnBeginOverlap_RootSphere)
    self.RootSphere.OnComponentEndOverlap:Remove(self, self.OnEndOverlap_RootSphere)
    Super(M).ReceiveEndPlay(self)
end

function M:ReceiveDestroyedEnd()
    for ind=1,#self.OverlapActorIds do
        local EditorId = self.OverlapActorIds[ind]
        local EditorActor = self:GetEditorActor(EditorId)
        self:LogInfo("zsf", "ReceiveDestroyed %s %s %s", G.GetDisplayName(EditorActor), G.GetDisplayName(self), self.iAreaAbility)
        if EditorActor and self.iAreaAbility then
            local ProcessFunctionName = "ResponseAreaAbility_"..Enum.E_AreaAbility.GetDisplayNameTextByValue(self.iAreaAbility)
            if EditorActor[ProcessFunctionName] then
                EditorActor[ProcessFunctionName](EditorActor, false)
            end
        end
    end
end

function M:ReceiveDestroyed()
    --self:ReceiveDestroyedEnd()
    self.Overridden.ReceiveDestroyed(self)
end

function M:Multicast_UseOtherDelay_RPC(delayTime)
    if self:HasAuthority() then
        utils.DoDelay(self:GetWorld(), delayTime, function()
            self:K2_DestroyActor()
        end)
    else
        local delayTime = delayTime-1.0
        delayTime = delayTime > 0 and delayTime or 0.0
        utils.DoDelay(self:GetWorld(), delayTime, function()
            HiAudioFunctionLibrary.PlayAKAudio("Scn_Skills_Light_Loop_Stop", self)
        end)
    end
end

function M:OnBeginOverlap_RootSphere(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    self:LogInfo("zsf", "OnBeginOverlap_Sphere %s %s", G.GetDisplayName(OtherActor), self.iAreaAbility)
    --if OtherActor.UseAreaAbility then
    --    OtherActor:UseAreaAbility(self.eAreaAbility, true)
    --    if OtherActor.GetEditorID then
    --        table.insert(self.OverlapActorIds, OtherActor:GetEditorID())
    --    end
    --end
end

function M:OnEndOverlap_RootSphere(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    --self:ReceiveDestroyedEnd()
end

function M:ReceiveTick(DeltaSeconds)
    Super(M).ReceiveTick(self, DeltaSeconds)
end

---@param PlayerAtor AActor
function M:AreaAbility_Fly2Player(PlayerAtor)
    self.bFly2Player = true
    if not self:HasAuthority() then
        self.NS_AreaLightFire_Keep:SetVisibility(true)
        self.NS_AreaLightFire_Keep:SetActive(true, true)
        self.NS_absorb:SetActive(false, false)
        self.NS_absorb:SetVisibility(false)
    end
    Super(M).AreaAbility_Fly2Player(self, PlayerAtor)
end

function M:DoAreaAbility_Fly2Player_OnComponentHit_Other(HitComponent, OtherActor, OtherComp, NormalImpulse, Hit)
    local bBlockingHit, bInitialOverlap, Time, Distance, Location, ImpactPoint,
        Normal, ImpactNormal, PhysMat, HitActor, HitComponent, HitBoneName, BoneName,
        HitItem, ElementIndex, FaceIndex, TraceStart, TraceEnd = UE.UGameplayStatics.BreakHitResult(Hit)
    if not self:HasAuthority() then
        self:LogInfo("zsf", "DoAreaAbility_Fly2Player_OnComponentHit_Other %s %s", G.GetDisplayName(OtherActor), ImpactPoint)
        self.NS_AreaLightFire_Keep:SetVisibility(false)
        self.NS_AreaLightFire_Keep:SetActive(false, false)
        if self.NS_absorb then
            local PlayerAtor = G.GetPlayerCharacter(self:GetWorld(), 0)
            local CurrentFloor = UE.FFindFloorResult()
            PlayerAtor.CharacterMovement:K2_FindFloor(ImpactPoint, CurrentFloor)
            --CurrentFloor.bBlockingHit and CurrentFloor.bWalkableFloor and CurrentFloor.FloorDist <= MAX_FLOOR_DIS, CurrentFloor.FloorDist, CurrentFloor.HitResult

            if true then
                self.NS_TengManLight_Close:SetActive(true, true)
                self.NS_absorb:SetActive(false, false)
            else
                self.NS_TengManLight_Close:SetActive(false, false)
                self.NS_absorb:SetActive(true, true)
                self.NS_absorb:SetVisibility(true)
            end
        end
        HiAudioFunctionLibrary.PlayAKAudio("Scn_Skills_Light_Impt", self)
        HiAudioFunctionLibrary.PlayAKAudio("Scn_Skills_Light_Loop", self)
    end
    self:K2_SetActorLocation(ImpactPoint, false, nil, true)
    self.RootSphere:SetSphereRadius(300.0, true)
end

function M:AreaAbility_Fly2Player_OnComponentHit(HitComponent, OtherActor, OtherComp, NormalImpulse, Hit)
    local ServerPlayerActor = self:GetPlayerActor(OtherActor)
    if not ServerPlayerActor then
        return
    end
    if not self:HasAuthority() then
        self.NS_AreaLightFire_Keep_End:SetVisibility(false)
        self.NS_AreaLightFire_Keep_End:SetActive(false, false)
        self.NS_AreaLightFire_Keep:SetVisibility(false)
        self.NS_AreaLightFire_Keep:SetActive(false, false)
        self.NS_absorb:SetVisibility(false)
        self.NS_absorb:SetActive(false, false)
        HiAudioFunctionLibrary.PlayAKAudio("Scn_Skills_Light_Impt", self)
    end
    Super(M).AreaAbility_Fly2Player_OnComponentHit(self, HitComponent, OtherActor, OtherComp, NormalImpulse, Hit)
    -- 可以无限吸收
    --if self.vFly2PlayerStart then
    --    self.RootSphere:SetSphereRadius(50.0, true)
    --    self.RootSphere:SetCollisionProfileName('Interacted_ItemTrigger', true)
    --    self:K2_SetActorLocation(self.vFly2PlayerStart, false, nil, true)
    --end
    local EditorId = self:GetEditorID()
    if EditorId  then
        MutableActorOperations.UnloadMutableActor(EditorId)
    else
        self:K2_DestroyActor()
    end
end

return M
