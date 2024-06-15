--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"

local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local physics_materia_react_data = require("common.data.physics_materia_react_data")
local Loader = require("actors.client.AsyncLoaderManager")

---@type BP_PhysicsMaterialEffectComponent_C
local PhysicsMaterialComponent = Component(ComponentBase)
local decorator = PhysicsMaterialComponent.decorator

function PhysicsMaterialComponent:Start()
    Super(PhysicsMaterialComponent).Start(self)
    self.NiagaraSystem = nil
end


decorator.message_receiver()
function PhysicsMaterialComponent:OnHitEvent(CurHit)
    if not self.actor:IsServer() then        
        local PhysMaterial = CurHit.PhysMaterial
        --G.log:debug( "PhysMaterial", "PhysicsMaterialComponent OnHitEvent %s  %s", G.GetDisplayName(CurHit.Component:GetOwner()) , tostring(PhysMaterial))
        if PhysMaterial and PhysMaterial:IsValid() then            
            if PhysMaterial.SurfaceType ~= 0 then
                local ReactData = physics_materia_react_data.data[PhysMaterial.SurfaceType]                                
                --G.log:debug( "PhysMaterial", "PhysMaterial is valid, %s  %s %s %s", tostring(PhysMaterial.SurfaceType), ReactData.name, NiagaraAssetPath, WwiseAssetPath)                
                self:PlayNiagara(ReactData.niagara_path, CurHit.ImpactPoint)                
                self:PlayWwiseEvent(ReactData.wwise_path)                
            end
        end
    end
end

function PhysicsMaterialComponent:PlayNiagara(NiagaraAssetPath, ImpactPoint)
    if NiagaraAssetPath then
        function OnNiagaraLoaded(NiagaraObject)
            --G.log:debug( "PhysMaterial", "OnNiagaraLoaded %s ", tostring(NiagaraObject)) 
            self.NiagaraSystem = NiagaraObject
            local NiagaraObject = UE.UNiagaraFunctionLibrary.SpawnSystemAtLocation(self.actor, self.NiagaraSystem, ImpactPoint)
        end
        Loader:AsyncLoadAsset(NiagaraAssetPath, OnNiagaraLoaded)
    end
end

function PhysicsMaterialComponent:PlayWwiseEvent(WwiseAssetPath)
    if WwiseAssetPath then            
        function OnWwiseLoaded(AkEvent)      
            local SourceActor =  self.actor.SourceActor                  
            G.log:debug( "PhysMaterial", "OnWwiseLoaded %s  %s ", tostring(SourceActor), tostring(AkEvent)) 
            if SourceActor and SourceActor:IsValid() then
                local AkComponent = UE.UAkGameplayStatics.GetAkComponent(SourceActor.Mesh)
                if AkComponent and AkComponent:IsValid() then
                    AkComponent:PostAkEvent(AkEvent)
                end
            end                        
        end
        Loader:AsyncLoadAsset(WwiseAssetPath, OnWwiseLoaded)
    end
end

function PhysicsMaterialComponent:Stop()
    Super(PhysicsMaterialComponent).Stop(self)
    self.NiagaraSystem = nil
end

return PhysicsMaterialComponent
