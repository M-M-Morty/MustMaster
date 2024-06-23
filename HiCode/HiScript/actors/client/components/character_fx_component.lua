require "UnLua"
local G = require("G")

---@class BP_FxEffector_Character
local Component = require("common.component")
local ComponentBase = require("common.componentbase")
local CharacterFxComponent = Component(ComponentBase)

local Loader = require("actors.client.AsyncLoaderManager")
local LightningFxPath = "/Game/Effect/Character/Mahonin/Common/PS_Mahonin_Common_LightingRun01.PS_Mahonin_Common_LightingRun01"
local LightningManageBpPath = '/Game/Blueprints/Effect/BP_Fx_BeamEffect_Follower.BP_Fx_BeamEffect_Follower_C'

function CharacterFxComponent:Start()
    Super(CharacterFxComponent).Start(self)
    -- Todo: Use GAS or BP to control this switch
    self.IsEnableSprintLightning = false
    if not self.actor:HasAuthority() then
        self.MeshComponent = self.actor:GetComponentByClass(UE.UMeshComponent)
        self.LocomotionComponent = self.actor:GetComponentByClass(UE.UHiLocomotionComponent)
        assert(self.MeshComponent ~= nil, "Missing [MeshComponent] for [CharacterFxComponent]")
        assert(self.LocomotionComponent ~= nil, "Missing [HiLocomotionComponent] for [CharacterFxComponent]")
        self.LocomotionComponent.OnGaitChangedDelegate:Add(self, self.OnGaitChanged)
        ------------------------- Sprint Lightning -------------------------------
        if self.IsEnableSprintLightning then
            self.SprintLightningTimer = nil
            self.PreLightningTime = -1.0        -- invalid time
            self.BeamEffect = nil        
            function OnBeamNiagaraLoaded(NiagaraObject)
                self.BeamEffect = NiagaraObject
            end
            Loader:AsyncLoadAsset(LightningFxPath, OnBeamNiagaraLoaded)
        end
    end
end

function CharacterFxComponent:Stop()
    Super(CharacterFxComponent).Stop(self)
    if not self.actor:HasAuthority() then
        self.LocomotionComponent.OnGaitChangedDelegate:Remove(self, self.OnGaitChanged)
    end
end

function CharacterFxComponent:OnGaitChanged()
    if not self.IsEnableSprintLightning then
        return
    end
    if (self.LocomotionComponent.Gait == UE.EHiGait.Sprinting) then
        local CurrentTime = self:GetWorld():GetTimeSeconds()
        -- if self.BeamEffect ~= nil and CurrentTime - self.PreLightningTime > self.SprintLightningInterval then
        if self.BeamEffect ~= nil then
            self.PreLightningTime = CurrentTime
            self:StartSprintLightningFx()
        end
    else
        self:StopSprintLightningFx()
    end
end

------------------------- Sprint Lightning -------------------------------

function CharacterFxComponent:StartSprintLightningFx()
    self:StopSprintLightningFx()
    self.SprintLightningSpawnTime = self:GetWorld():GetTimeSeconds()
    self.SprintLightningSpawnPhase = 1      -- Array starts from 1 ...
    if self.SprintLightningSpawnPhase <= self.BeamTriggerSettings:Length() then
        self.SprintLightningTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.TickSprintLightningFx}, 0.05, true)
    end
end

function CharacterFxComponent:StopSprintLightningFx()
    if self.SprintLightningTimer ~= nil then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.SprintLightningTimer)
        self.SprintLightningTimer = nil
    end
end

function CharacterFxComponent:TickSprintLightningFx()
    local CurrentTime = self:GetWorld():GetTimeSeconds()
    local BeamSetting = self.BeamTriggerSettings[self.SprintLightningSpawnPhase]
    if CurrentTime - self.SprintLightningSpawnTime > BeamSetting.Time then
        self:SpawnBeamFx(BeamSetting.BeamStartBone, BeamSetting.BeamEndBone)
        self.SprintLightningSpawnPhase = self.SprintLightningSpawnPhase + 1
        if self.SprintLightningSpawnPhase >= self.BeamTriggerSettings:Length() then
            self:StopSprintLightningFx()
        end
    end
end

function CharacterFxComponent:SpawnBeamFx(BeamStartBone, BeamEndBone)
    local NiagaraObject = UE.UNiagaraFunctionLibrary.SpawnSystemAttached(self.BeamEffect, self.MeshComponent, BeamStartBone)
    local LightningFxBlueprintClass = UE.UClass.Load(LightningManageBpPath)
    local LightningManageComponent = self.actor:AddComponentByClass(LightningFxBlueprintClass, false, UE.FTransform.Identity, false)
    assert(LightningManageComponent ~= nil, "Missing [BP_Fx_BeamEffect_Follower]")
    LightningManageComponent:InitialEffectParameters(self.MeshComponent, NiagaraObject, BeamEndBone)
end


return CharacterFxComponent