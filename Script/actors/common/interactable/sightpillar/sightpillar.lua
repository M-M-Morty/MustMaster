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

require "UnLua"
local ActorBase = require("actors.common.interactable.base.base_item")

local M = Class(ActorBase)

function M:Initialize(...)
    Super(M).Initialize(self, ...)
end

function M:ReceiveBeginPlay()
    Super(M).ReceiveBeginPlay(self)
    for ind=0,Enum.E_SightType.GetMaxValue() do
        self:LogInfo("zsf", "[sightpillarlogic_lua] ReceiveTick %s %s", Enum.E_SightType.GetDisplayNameTextByValue(ind), Enum.E_SightType.GetDisplayNameTextByValue(self.eSightType))
    end
end

function M:GetHeight()
    local Min = UE.FVector()
    local Max = UE.FVector()
    self.Billboard:GetLocalBounds(Min, Max)
    return (Max - Min).z * self.BillboardScale
end

function M:ReceiveEndPlay()
    Super(M).ReceiveEndPlay(self)
end

function M:SetAppear()
    --self.Pattern_Persistent:SetAsset(self.PatternAppear, true)
    self.Pattern_Persistent:SetHiddenInGame(false)
    self.Pattern_Persistent:SetVisibility(true)
    --self.Pattern_Persistent:SetActive(true)
    local World = self:GetWorld()
    utils.DoDelay(World, 1.0,
        function()
            self.Pillars_Persistent:SetAsset(self.PillarPersistent, true)
            self.Pillars_Persistent:SetActive(true)
        end)
end

function M:SetOK(bOk, bComplete)
    if not self.bFront and not bOk then
        self.BillboardRoot:SetHiddenInGame(false)
    else
        self.BillboardRoot:SetHiddenInGame(true)
    end
    self.Billboard:SetHiddenInGame(bOk)
    self.Billboard:SetVisibility(not bOk)
    local EffectPersistent
    if bComplete then
        EffectPersistent = self.mapType2EffectDeath:FindRef(self.eSightType)
        self.Pattern_Death:SetAsset(self.PatternDeath, true)
        self.Pattern_Death:SetHiddenInGame(false)
        self.Pattern_Death:SetVisibility(true)
        self.Pattern_Death:SetActive(true)
        self.Pillars_Persistent:SetAsset(self.PillarDeath, true)
        self.Pillars_Persistent:SetActive(true)
        self.BillboardRoot:SetHiddenInGame(true)
    else
        EffectPersistent = self.mapType2EffectPersistent:FindRef(self.eSightType)
    end
    self.Pattern_Persistent:SetAsset(EffectPersistent, true)
    self.Pattern_Persistent:SetHiddenInGame(not bOk)
    self.Pattern_Persistent:SetVisibility(bOk)
    self.Pattern_Persistent:SetActive(bOk)
end

function M:GetPlayerLocation()
    local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
    if Player then
        return Player:K2_GetActorLocation()
    end
end

function M:GetXRollAndZYaw()
    local PlayerLocation = self:GetPlayerLocation()
    local ActorLocation = self:K2_GetActorLocation()
    local ForwardV = PlayerLocation - ActorLocation
    local Rotator = UE.UKismetMathLibrary.MakeRotationFromAxes(ForwardV,UE.FVector(0.0,0.0,0.0), UE.FVector(0.0,0.0,0.0))
    return Rotator
end

function M:ReceiveTick(DeltaSeconds)
    Super(M).ReceiveTick(self, DeltaSeconds)
    if not self:IsClient() and not UE.UKismetSystemLibrary.IsStandalone(self) then
        return
    end
    local PlayerLocation = self:GetPlayerLocation()
    if not PlayerLocation then
        return
    end

    local SelfRotator = self.Billboard:K2_GetComponentRotation()
    local Rotator = self:GetXRollAndZYaw()
    --local PlayerForwarV = self:GetPlayerForwardV()
    --local Billboard_ForwardV = self.Billboard:GetUpVector()
    --local CosDelta = UE.UKismetMathLibrary.Dot_VectorVector(PlayerForwarV, Billboard_ForwardV)
    --local DegreesDelta = UE.UKismetMathLibrary.DegACos(CosDelta)
    local NewRotator = UE.UKismetMathLibrary.MakeRotator(SelfRotator.Roll, SelfRotator.Pitch, Rotator.Yaw+90.0)
    self.Billboard:K2_SetWorldRotation(NewRotator, false, UE.FHitResult(), false)
end

return M
