require "UnLua"
local G = require("G")


local LoaderTrackInstance = {}

function LoaderTrackInstance:AddLoader(Transform)
    local World = G.GameInstance:GetWorld()
   
    if World ~= nil then
        
        local Actor = World:SpawnActor(UE.AStaticMeshActor, Transform)
        
        local WPSSC  = Actor:AddComponentByClass(UE.UWorldPartitionStreamingSourceComponent, false, UE.FTransform.Identity, false)
        WPSSC.TargetGrid = "Small"
        WPSSC.Priority = 0
        --Actor:SetActorLabel("Loader")

        G.log:info("[lz]","-----LoaderTrackInstance:AddLoader--[%s]-[%s]-----", self.Actor, WPSSC)
        return Actor
    end
end
return LoaderTrackInstance
