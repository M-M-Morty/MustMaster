require "UnLua"

local G = require("G")

local Notify_ChangeMaterial = Class()

--G.log:debug("hycoldrain", "Notify_ChangeMaterial")

function Notify_ChangeMaterial:Received_NotifyBegin(MeshComp, Animation, TotalDuration, EventReference)
    if not self.constructed then
        self:CreateModifiers()
        self.constructed = true
    end
    local actor = MeshComp:GetOwner()
     --G.log:debug("hycoldrain", "MaterialMgrComponent Notify_ChangeMaterial Received_NotifyBegin+++++++++++++ %s %s %s %s %s %s", tostring(actor:IsServer()), tostring(actor), tostring(self), tostring(Animation), tostring(Animation:GetName()), tostring(self.DynamicMaterial))
    local MaterialInstance = UE.UKismetMaterialLibrary.CreateDynamicMaterialInstance(self, self.DynamicMaterial)
    actor:SendMessage("SetOwnerMaterialInstance", MaterialInstance)
    actor:SendMessage("ChangeEquipMaterial", MaterialInstance)
    self:ExecuteModifiers(MeshComp, Animation)
    return true
end

function Notify_ChangeMaterial:Received_NotifyEnd(MeshComp, Animation, EventReference)    
    --G.log:debug("hycoldrain", "Notify_ChangeMaterial Received_NotifyEnd+++++++++++++%s    %s   ",  tostring(self), tostring(Animation))
    local actor = MeshComp:GetOwner()
    actor:SendMessage("ResetMaterials")
    actor:SendMessage("ResetEquipMaterial")
    return true
end

return Notify_ChangeMaterial