require "UnLua"
local utils = require("common.utils")

local G = require("G")

local NotifyState_PlayNiagara = Class()

function NotifyState_PlayNiagara:Received_NotifyBegin(MeshComp, Animation, TotalDuration, EventReference)

    self.Overridden.Received_NotifyBegin(self, MeshComp, Animation, TotalDuration, EventReference)

    local actor = MeshComp:GetOwner()

    if actor and actor.SendMessage then

        local NiagaraComp = self:GetSpawnedEffect()

        if not NiagaraComp then
            return NiagaraComp
        end

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

    return true
end


return NotifyState_PlayNiagara