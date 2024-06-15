require "UnLua"
local utils = require("common.utils")
local G = require("G")

local NotifyState_ReplaceMaterial = Class()

function NotifyState_ReplaceMaterial:Received_NotifyBegin(MeshComp, Animation, TotalDuration, EventReference)
    local Owner = MeshComp:GetOwner()
    if not Owner:IsClient() then
    	return true
    end

    self.OldMaterial = UE.UMeshComponent.GetMaterial(MeshComp, self.Idx)
    UE.UMeshComponent.SetMaterial(MeshComp, self.Idx, self.NewMaterial)

    -- G.log:error("yj", "NotifyState_ReplaceMaterial:Received_NotifyBegin Old.%s New.%s", G.GetDisplayName(self.OldMaterial), G.GetDisplayName(self.NewMaterial))

    return true
end

function NotifyState_ReplaceMaterial:Received_NotifyEnd(MeshComp, Animation, EventReference)
    local Owner = MeshComp:GetOwner()
    if not Owner:IsClient() then
    	return true
    end

    UE.UMeshComponent.SetMaterial(MeshComp, self.Idx, self.OldMaterial)

    -- G.log:error("yj", "NotifyState_ReplaceMaterial:Received_NotifyEnd Old.%s New.%s", G.GetDisplayName(self.OldMaterial), G.GetDisplayName(self.NewMaterial))

    return true
end

return NotifyState_ReplaceMaterial
