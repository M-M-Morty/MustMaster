require "UnLua"
local utils = require("common.utils")

local G = require("G")

local Notify_PlayNiagara = Class()

function Notify_PlayNiagara:Received_Notify(MeshComp, Animation, EventReference)

    local result = self.Overridden.Received_Notify(self, MeshComp, Animation, EventReference)
    local actor = MeshComp:GetOwner()

    if actor and actor.SendMessage then

        local NiagaraComp = self:GetSpawnedEffect()

        if not NiagaraComp then
            return result
        end

        G.log:debug("devin", "Notify_PlayNiagara:OnPlayNiagara")

        local TimeDilationActor = HiBlueprintFunctionLibrary.GetTimeDilationActor(NiagaraComp)

        if TimeDilationActor then
            TimeDilationActor:AddCustomTimeDilationObject(actor, NiagaraComp)
        end

        local OnSystemFinished = function(Notify, NiagaraComp)
        	if TimeDilationActor then
            	TimeDilationActor:RemoveCustomTimeDilationObject(actor, NiagaraComp)
            end
        end

        NiagaraComp.OnSystemFinished:Add(self, OnSystemFinished)
    end

    return result
end


return Notify_PlayNiagara