local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local utils = require("common.utils")

local SyncComponent = Component(ComponentBase)
local decorator = SyncComponent.decorator


function SyncComponent:OnParentMontagePlay(AnimInstance, Montage)
    self.Overridden.OnParentMontagePlay(self, AnimInstance, Montage)
    G.log:info_obj(self, "OnParentMontagePlay", "Owner:[%s], Parent:[%s:%s] Montage: %s", 
            G.GetObjectName(self.actor),
            G.GetObjectName(AnimInstance:GetOwningActor()),
            G.GetObjectName(AnimInstance),
            G.GetObjectName(Montage))
end

function SyncComponent:OnMontageStarted(AnimInstance, Montage)
    self.Overridden.OnMontageStarted(self, AnimInstance, Montage)
    local EquipmentComponent = AnimInstance:GetOwningActor():_GetComponent("EquipmentComponent")
    if EquipmentComponent ~= nil then
        --EquipmentComponent:RestoreAttachEquip()
    end
    G.log:info_obj(self, "OnMontageStarted", "Owner:[%s], Parent:[%s:%s] Montage: %s",
            G.GetObjectName(self.actor),
            G.GetObjectName(AnimInstance:GetOwningActor()),
            G.GetObjectName(AnimInstance),
            G.GetObjectName(Montage))
end


return SyncComponent
