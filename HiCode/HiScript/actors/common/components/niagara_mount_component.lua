require "UnLua"

local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

local NiagaraMountComponent = Component(ComponentBase)

local decorator = NiagaraMountComponent.decorator


function NiagaraMountComponent:ReceiveBeginPlay()
    Super(NiagaraMountComponent).ReceiveBeginPlay(self)
    if self.actor:IsServer() then
        return
    end

    -- G.log:error("yj", "NiagaraMountComponent:ReceiveBeginPlay %s Name.%s %s", self.actor:IsServer(), self.actor:GetDisplayName(), self.actor.SourceActor:GetDisplayName())

    if self.ActiveOnBeginPlay then
        self:Active()
    end
end

decorator.message_receiver()
function NiagaraMountComponent:CreateSplineAndTimeline()
    if self.IsActived then
        return
    end

    self:Active()
end

function NiagaraMountComponent:Active()
    local SourceActor = self.actor.SourceActor
    self.NiagaraComponent = SourceActor.NiagaraSlotComponent:GetNextValidNiagaraComponent()
    self.NiagaraComponent:SetAsset(self.NiagaraAsset)
    self.NiagaraComponent:SetAutoAttachmentParameters(self.actor.Sphere, "", UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.KeepWorld)
    self.NiagaraComponent:ReinitializeSystem()
    self.IsActived = true
end

function NiagaraMountComponent:ReceiveEndPlay()
    Super(NiagaraMountComponent).ReceiveEndPlay(self)
    if self.NiagaraComponent then
        self.NiagaraComponent:SetAsset(nil)
    end
end

return NiagaraMountComponent
