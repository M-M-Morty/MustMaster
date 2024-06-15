require "UnLua"
local utils = require("common.utils")

local G = require("G")

local Notify_ReplaceMaterial = Class()

function Notify_ReplaceMaterial:Received_Notify(MeshComp, Animation, EventReference)
    local Owner = MeshComp:GetOwner()
    if not Owner:IsClient() then
        return true
    end

    local Idx, NewMaterial = self.Idx, self.NewMaterial
    utils.DoDelay(MeshComp, self.Delay, function()
        -- G.log:error("yj", "Notify_ReplaceMaterial:Received_Notify New.%s", G.GetDisplayName(self.NewMaterial))
        UE.UMeshComponent.SetMaterial(MeshComp, Idx, NewMaterial)
    end)

    return true
end


return Notify_ReplaceMaterial