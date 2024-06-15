
local G = require("G")
check_table = require("common.data.state_conflict_data")


local NotifyConditionalNiagara = Class()

function NotifyConditionalNiagara:Received_Notify(MeshComp, Animation, EventReference)
    local Owner = MeshComp:GetOwner()
    if Owner and UE.UKismetSystemLibrary.IsValid(Owner) then
        local CI = self.NegativeFX
        if Owner.BuffComponent and Owner.BuffComponent:HasBuff(self.Buff) then
            CI = self.PositiveFX
        end

        local NiagaraComp = nil
        if self.bAttached then
            NiagaraComp = UE.UNiagaraFunctionLibrary.SpawnSystemAttached(CI.NiagaraSystem, MeshComp, CI.SocketName, CI.LocationOffset,
                    CI.RotationOffset, UE.EAttachLocation.KeepRelativeOffset, true)
        else
            local SocketTransform = MeshComp:GetSocketTransform(self.SocketName)

            NiagaraComp = UE.UNiagaraFunctionLibrary.SpawnSystemAtLocation(MeshComp:GetWorld(), CI.NiagaraSystem,
                    UE.UKismetMathLibrary.TransformLocation(SocketTransform, CI.LocationOffset), UE.UKismetMathLibrary.TransformRotation(SocketTransform, CI.RotationOffset), UE.FVector(1.0, 1.0, 1.0), true)
        end

        if NiagaraComp then
            NiagaraComp.bAbsoluteScale = CI.bAbsoluteScale
            NiagaraComp.RelativeScale3D = CI.Scale
        end
    end
end

return NotifyConditionalNiagara
